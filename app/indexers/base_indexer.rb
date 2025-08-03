# frozen_string_literal: true

require "capybara"
require "selenium-webdriver"
require "robots"
require "net/http"

# Custom error classes for indexing
class CloudflareBlockError < StandardError; end
class BotProtectionError < StandardError; end
class RobotsDisallowedError < StandardError; end
class RateLimitError < StandardError; end
class ForbiddenAccessError < StandardError; end

# Abstract base class for all indexers
# Provides common functionality and interface for content indexing
class BaseIndexer
  include RateLimitable
  include Cacheable
  include ErrorHandler
  include ProgressTrackable

  attr_reader :config, :indexing_run

  def initialize(config_overrides = {})
    @config = load_config.merge(config_overrides)
    @indexing_run = nil
    @total_items = nil
    setup_capybara
  end

  # Main entry point for indexing
  # Creates an IndexingRun record and processes all items
  def index!(options = {})
    start_indexing_run(options)

    log_info "Starting indexing for #{self.class.name}"

    begin
      items = with_retry { fetch_items }
      total_items(items.size)
      log_info "Found #{items.size} items to process"

      process_items_in_batches(items)

      complete_indexing_run
      log_progress_summary
      log_info "Indexing completed successfully"
    rescue StandardError => e
      fail_indexing_run(e)
      log_error "Indexing failed: #{e.message}"
      raise
    end
  end

  # Abstract methods that subclasses must implement
  def fetch_items
    raise NotImplementedError, "#{self.class} must implement #fetch_items"
  end

  def process_item(item)
    raise NotImplementedError, "#{self.class} must implement #process_item"
  end

  # Platform identifier (e.g., 'decentraland', 'sandbox')
  def platform_name
    self.class.name.demodulize.underscore.gsub("_indexer", "")
  end

  protected

  # Convert platform-specific data to standardized format
  def normalize_content(raw_data)
    {
      source_platform: platform_name,
      external_id: extract_external_id(raw_data),
      content_type: extract_content_type(raw_data),
      title: extract_title(raw_data),
      description: extract_description(raw_data),
      author: extract_author(raw_data),
      metadata: extract_metadata(raw_data),
      coordinates: extract_coordinates(raw_data)
    }
  end

  # Check if existing content should be updated
  def should_update?(existing_content, new_data)
    # Update if metadata has changed or if it's been more than 24 hours
    existing_content.metadata != new_data[:metadata] ||
      existing_content.last_indexed_at < 24.hours.ago
  end

  # Save or update indexed content
  def save_indexed_content(normalized_data)
    existing = IndexedContent.find_by(
      source_platform: normalized_data[:source_platform],
      external_id: normalized_data[:external_id]
    )

    if existing && !should_update?(existing, normalized_data)
      log_debug "Skipping #{normalized_data[:external_id]} - no update needed"
      return existing
    end

    if existing
      existing.update!(normalized_data.merge(last_indexed_at: Time.current))
      log_debug "Updated #{normalized_data[:external_id]}"
      existing
    else
      content = IndexedContent.create!(normalized_data.merge(last_indexed_at: Time.current))
      log_debug "Created #{normalized_data[:external_id]}"
      content
    end
  end

  # Make web requests using Capybara (handles JavaScript, modern web challenges)
  def make_request(url, options = {})
    wait_for_rate_limit
    
    # Check for domain-specific blocks and rate limits
    domain = URI.parse(url).host
    
    if domain_blocked?(domain)
      raise ForbiddenAccessError, "Domain #{domain} is currently blocked due to previous 403 response. Will recheck monthly."
    end
    
    wait_for_domain_rate_limit(domain) if domain_rate_limited?(domain)

    # Check robots.txt before making any request
    raise RobotsDisallowedError, "Access to #{url} is disallowed by robots.txt" unless robots_allowed?(url)

    with_retry do
      log_debug "Making request to: #{url}"

      # Check if this is a JSON API request
      accept_header = options.dig(:headers, "Accept") || default_headers["Accept"]

      if accept_header.include?("application/json")
        # For JSON APIs, use HTTParty with our improved headers
        return make_json_request(url, options)
      end

      # For HTML/general web content, use Capybara
      session = create_browser_session

      begin
        # Visit the URL
        session.visit(url)

        # Check for common blocking scenarios
        raise CloudflareBlockError, "Request blocked by Cloudflare protection" if is_blocked_by_cloudflare?(session)

        raise BotProtectionError, "Request blocked by bot protection" if is_blocked_by_bot_protection?(session)

        # Return the page HTML content wrapped in a response-like object
        create_response_wrapper(session.html)
      ensure
        session&.quit
      end
    end
  end

  def make_json_request(url, options = {})
    log_debug "Making JSON request to: #{url}"

    # Check for domain-specific blocks and rate limits
    domain = URI.parse(url).host
    
    if domain_blocked?(domain)
      raise ForbiddenAccessError, "Domain #{domain} is currently blocked due to previous 403 response. Will recheck monthly."
    end
    
    wait_for_domain_rate_limit(domain) if domain_rate_limited?(domain)

    # Check robots.txt for JSON API requests too
    raise RobotsDisallowedError, "Access to #{url} is disallowed by robots.txt" unless robots_allowed?(url)

    default_options = {
      timeout: timeout_for_request,
      headers: default_headers
    }

    response = HTTParty.get(url, default_options.merge(options))

    # Handle rate limiting responses
    if response.code == 429 || response.code == 503
      handle_rate_limit_response(response, url)
    elsif response.code == 403
      handle_forbidden_response(response, url)
    elsif response.code >= 400
      error_msg = "HTTP #{response.code}: #{response.message || 'Request failed'}"
      error = StandardError.new(error_msg)
      error.define_singleton_method(:response) { response }
      raise error
    end

    response
  end

  def create_response_wrapper(html_content)
    # Create a simple response wrapper that mimics HTTParty's interface
    OpenStruct.new(
      body: html_content,
      parsed_response: html_content,
      code: 200,
      success?: true
    )
  end

  def make_post_request(url, body, options = {})
    # For POST requests, we may need to fall back to HTTParty or implement
    # form submission via Capybara depending on the specific use case
    wait_for_rate_limit
    
    # Check for domain-specific blocks and rate limits
    domain = URI.parse(url).host
    
    if domain_blocked?(domain)
      raise ForbiddenAccessError, "Domain #{domain} is currently blocked due to previous 403 response. Will recheck monthly."
    end
    
    wait_for_domain_rate_limit(domain) if domain_rate_limited?(domain)

    with_retry do
      log_debug "Making POST request to: #{url}"

      default_options = {
        timeout: timeout_for_request,
        headers: default_headers.merge("Content-Type" => "application/json"),
        body: body.is_a?(String) ? body : body.to_json
      }

      response = HTTParty.post(url, default_options.merge(options))

      # Handle rate limiting responses
      if response.code == 429 || response.code == 503
        handle_rate_limit_response(response, url)
      elsif response.code == 403
        handle_forbidden_response(response, url)
      elsif response.code >= 400
        error_msg = "HTTP #{response.code}: #{response.message || 'Request failed'}"
        error = StandardError.new(error_msg)
        error.define_singleton_method(:response) { response }
        raise error
      end

      response
    end
  end

  private

  def load_config
    # Load the indexers configuration with environment-specific overrides
    config_path = Rails.root.join("config/indexers.yml")
    return {} unless File.exist?(config_path)

    all_config = YAML.load_file(config_path)
    base_config = all_config.dig("indexers", platform_name) || {}

    # Apply environment-specific overrides
    env_config = all_config.dig(Rails.env, "indexers", platform_name) || {}

    base_config.deep_merge(env_config)
  rescue StandardError => e
    Rails.logger.error "Failed to load indexer config: #{e.message}"
    {}
  end

  def default_headers
    {
      "User-Agent" => libreverse_user_agent,
      "Accept" => "application/json"
    }
  end

  def libreverse_user_agent
    # Dynamic user agent that includes the instance domain
    # This helps with decentralization - each instance identifies itself uniquely
    instance_domain = extract_instance_domain
    "LibreverseIndexerFor#{instance_domain}/1.0 (+https://#{instance_domain})"
  end

  def extract_instance_domain
    # Try multiple ways to get the instance domain
    domain = nil
    
    # 1. Check environment variables first (most explicit)
    domain = ENV['LIBREVERSE_DOMAIN'] || ENV['DOMAIN'] || ENV['HOST']
    
    # 2. Check Rails application configuration
    if domain.nil?
      begin
        # Try default URL options first
        domain = Rails.application.config.default_url_options&.dig(:host)
        
        # Check Action Mailer configuration
        domain ||= Rails.application.config.action_mailer&.default_url_options&.dig(:host)
        
        # Check routes configuration
        domain ||= Rails.application.routes.default_url_options&.dig(:host)
      rescue StandardError => e
        log_debug "Failed to extract domain from Rails config: #{e.message}"
      end
    end
    
    # 3. Try to detect from server name (development/testing)
    if domain.nil?
      begin
        # In development, Rails.application.config.hosts might contain useful info
        hosts = Rails.application.config.hosts
        if hosts.respond_to?(:to_a) && !hosts.empty?
          # Filter out localhost variants and IP addresses
          candidate = hosts.to_a.find do |host|
            host.is_a?(String) && 
            !host.match?(/^(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\])/) &&
            host.include?('.')
          end
          domain = candidate if candidate
        end
      rescue StandardError => e
        log_debug "Failed to extract domain from hosts config: #{e.message}"
      end
    end
    
    # 4. Development/local fallbacks
    if domain.nil?
      # Check if we're in a known development environment
      if Rails.env.development? || Rails.env.test?
        domain = 'localhost'
      end
    end
    
    # 5. Final fallback
    domain ||= "UnknownInstance"
    
    # Clean up the domain (remove protocol, port, etc.)
    domain = normalize_domain(domain)
    
    # Ensure it's a valid domain-like string
    domain.empty? ? "UnknownInstance" : domain
  end

  def normalize_domain(domain_string)
    return "UnknownInstance" if domain_string.nil? || domain_string.empty?
    
    # Convert to string and clean up
    cleaned = domain_string.to_s.strip
    
    # Remove protocol if present
    cleaned = cleaned.gsub(/^https?:\/\//, '')
    
    # Remove port if present
    cleaned = cleaned.gsub(/:.*$/, '')
    
    # Remove path components if any
    cleaned = cleaned.split('/').first
    
    # Handle IP addresses and localhost variants
    if cleaned.match?(/^(127\.0\.0\.1|0\.0\.0\.0|\[::1\]|::1)$/)
      return "localhost"
    end
    
    # Remove invalid characters, keep only alphanumeric, dots, and hyphens
    cleaned = cleaned.gsub(/[^a-zA-Z0-9.-]/, '')
    
    # Remove leading/trailing dots
    cleaned = cleaned.gsub(/^\.+|\.+$/, '')
    
    # Return localhost if it's empty after cleaning or if it was localhost
    return "localhost" if cleaned.empty? || cleaned == "localhost"
    
    cleaned
  end

  def setup_capybara
    return if @capybara_setup

    driver_name = :"#{platform_name}_chrome"

    Capybara.register_driver driver_name do |app|
      options = Selenium::WebDriver::Chrome::Options.new

      # Be honest about what we are - a legitimate indexer
      options.add_argument("--headless")
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-dev-shm-usage")
      options.add_argument("--disable-gpu")
      options.add_argument("--window-size=1920,1080")

      # Set a proper user agent that identifies this specific instance
      options.add_argument("--user-agent=#{libreverse_user_agent}")

      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end

    Capybara.default_max_wait_time = config.fetch("timeout", 30).to_i
    @capybara_setup = true
    @driver_name = driver_name
  end

  def create_browser_session
    Capybara::Session.new(@driver_name)
  end

  def is_blocked_by_cloudflare?(session)
    page_content = session.html.downcase
    page_content.include?("cloudflare") &&
      (page_content.include?("challenge") || page_content.include?("just a moment"))
  end

  def is_blocked_by_bot_protection?(session)
    page_content = session.html.downcase
    title = session.title.downcase

    # Common bot protection indicators
    page_content.include?("access denied") ||
      page_content.include?("forbidden") ||
      page_content.include?("bot protection") ||
      title.include?("access denied") ||
      (session.status_code && session.status_code == 403)
  rescue StandardError
    false
  end

  def process_items_in_batches(items)
    batch_size = config.fetch("batch_size") { 50 }
    max_items = config.fetch("max_items") { nil }

    # Limit items if max_items is set
    items = items.first(max_items) if max_items

    items.each_slice(batch_size).with_index do |batch, batch_index|
      log_debug "Processing batch #{batch_index + 1} (#{batch.size} items)"
      process_batch(batch)

      # Rate limiting between batches
      sleep_between_batches if rate_limited?
    end
  end

  def process_batch(items)
    items.each do |item|
        normalized_data = normalize_content(process_item(item))
        save_indexed_content(normalized_data)
        update_progress(1)
    rescue StandardError => e
        handle_item_error(e, item)
    end
  end

  def start_indexing_run(options)
    @indexing_run = IndexingRun.create!(
      indexer_class: self.class.name,
      status: :running,
      configuration: @config.merge(options),
      started_at: Time.current
    )
  end

  def complete_indexing_run
    @indexing_run.update!(
      status: :completed,
      completed_at: Time.current
    )
  end

  def fail_indexing_run(error)
    @indexing_run.update!(
      status: :failed,
      completed_at: Time.current,
      error_message: error.message,
      error_details: handle_api_error(error)
    )
  end

  def update_progress(processed_count)
    @indexing_run.update!(items_processed: @indexing_run.items_processed + processed_count)
  end

  def handle_item_error(error, item = nil)
    @indexing_run.update!(items_failed: @indexing_run.items_failed + 1)
    error_details = handle_api_error(error, { item: item.to_s })
    log_error "Failed to process item #{item.inspect}: #{error.class.name} - #{error.message}", error_details
  end

  # Methods that subclasses should override for data extraction
  def extract_external_id(raw_data)
    raw_data["id"] || raw_data[:id] || raw_data["tokenId"] || raw_data[:tokenId]
  end

  def extract_content_type(_raw_data)
    "unknown"
  end

  def extract_title(raw_data)
    raw_data["title"] || raw_data["name"] || raw_data[:title] || raw_data[:name]
  end

  def extract_description(raw_data)
    raw_data["description"] || raw_data[:description]
  end

  def extract_author(raw_data)
    if raw_data["owner"].is_a?(Hash)
      raw_data["owner"]["id"] || raw_data["owner"]["address"]
    else
      raw_data["author"] || raw_data["owner"] || raw_data[:author] || raw_data[:owner]
    end
  end

  def extract_metadata(raw_data)
    # Remove known standard fields and return the rest as metadata
    excluded_keys = %w[id tokenId title name description author owner]
    raw_data.except(*excluded_keys)
  end

  def extract_coordinates(_raw_data)
    nil # Override in subclasses for spatial content
  end

  # Robots.txt compliance checking with caching via marshalling
  def robots_allowed?(url)
      uri = URI.parse(url)
      domain = "#{uri.scheme}://#{uri.host}"
      domain += ":#{uri.port}" if uri.port && ![ 80, 443 ].include?(uri.port)

      robots_parser = get_robots_parser(domain)

      # If we got a fallback parser, it means robots.txt was inaccessible
      # In that case, we should be conservative and disallow access
      if robots_parser.is_a?(FallbackRobotsParser)
        log_info "Robots.txt inaccessible for #{domain} - being conservative and disallowing access"
        return false
      end

      allowed = robots_parser.allowed?(url)

      log_debug "Robots.txt check for #{url}: #{allowed ? 'ALLOWED' : 'DISALLOWED'}"

      unless allowed
        log_warn "Access to #{url} is disallowed by robots.txt"
        # Log the relevant disallow rules if available
        log_debug "Disallowed paths: #{robots_parser.disallowed_paths}" if robots_parser.respond_to?(:disallowed_paths)
      end

      allowed
  rescue StandardError => e
      log_warn "Failed to check robots.txt for #{url}: #{e.message}"
      # If we can't check robots.txt at all, be conservative and disallow
      log_info "Being conservative - disallowing access when robots.txt check fails"
      false
  end

  def get_robots_parser(domain)
    cache_key = "robots_parser_#{domain}"

    # Try to get cached parser
    cached_parser = Rails.cache.read(cache_key)
    if cached_parser
      begin
        # Unmarshal the cached parser
        return Marshal.load(cached_parser) if cached_parser.is_a?(String)

        return cached_parser
      rescue StandardError => e
        log_debug "Failed to unmarshal cached robots parser: #{e.message}"
        # Fall through to create new parser
      end
    end

    # First, check if robots.txt is actually accessible
    robots_url = "#{domain}/robots.txt"
    begin
      uri = URI(robots_url)
      response = Net::HTTP.get_response(uri)

      if response.code.to_i >= 400
        log_warn "Robots.txt returned #{response.code} for #{domain}"
        log_info "Being conservative - will disallow access when robots.txt is inaccessible"
        return create_fallback_robots_parser
      end

      log_debug "Robots.txt accessible for #{domain} (#{response.code})"
    rescue StandardError => e
      log_warn "Failed to fetch robots.txt for #{domain}: #{e.message}"
      log_info "Being conservative - will disallow access when robots.txt fetch fails"
      return create_fallback_robots_parser
    end

    # Create new robots parser only if robots.txt was accessible
    log_debug "Creating new robots parser for #{domain}"
    user_agent = "LibreverseIndexerFor#{extract_instance_domain}"
    robots_parser = Robots.new(user_agent)

    begin
      # Test if the parser works by checking a basic URL
      test_result = robots_parser.allowed?("#{domain}/")
      log_debug "Robots parser test for #{domain}: #{test_result}"

      # Cache the parser using marshalling as suggested
      marshalled_parser = Marshal.dump(robots_parser)
      Rails.cache.write(cache_key, marshalled_parser, expires_in: 24.hours)
      log_debug "Cached robots parser for #{domain}"
    rescue StandardError => e
      log_warn "Failed to create/cache robots parser for #{domain}: #{e.message}"
      log_info "Being conservative - will disallow access when robots parser fails"
      # Return a restrictive fallback parser
      return create_fallback_robots_parser
    end

    robots_parser
  end

  def create_fallback_robots_parser
    # Create a restrictive fallback that disallows everything
    # This is used when we can't fetch or parse robots.txt
    # We're being respectful and conservative - only crawl if we know it's allowed
    FallbackRobotsParser.new
  end

  # Handle rate limiting responses with proper Retry-After support
  def handle_rate_limit_response(response, url)
    retry_after = extract_retry_after(response)
    domain = URI.parse(url).host
    
    log_warn "Rate limited by #{domain}: HTTP #{response.code}"
    log_info "Retry-After: #{retry_after} seconds"
    
    # Store the rate limit information for this domain
    set_domain_rate_limit(domain, retry_after)
    
    # Create a rate limit error that can be handled by retry logic
    error = RateLimitError.new("Rate limited by #{domain}. Retry after #{retry_after} seconds.")
    error.define_singleton_method(:retry_after) { retry_after }
    error.define_singleton_method(:response) { response }
    raise error
  end

  # Handle 403 Forbidden responses with monthly recheck
  def handle_forbidden_response(response, url)
    domain = URI.parse(url).host
    
    log_warn "Access forbidden by #{domain}: HTTP 403"
    log_info "Domain will be blocked for 30 days, then rechecked in case of temporary/accidental block"
    
    # Block the domain for 30 days (monthly recheck)
    set_domain_block(domain, 30.days.to_i)
    
    # Create a forbidden access error
    error = ForbiddenAccessError.new("Access forbidden by #{domain}. Will recheck in 30 days.")
    error.define_singleton_method(:recheck_after) { 30.days.to_i }
    error.define_singleton_method(:response) { response }
    raise error
  end

  def extract_retry_after(response)
    # Check for Retry-After header (can be seconds or HTTP date)
    retry_after_header = response.headers['Retry-After'] || response.headers['retry-after']
    
    if retry_after_header
      # If it's a number, it's seconds
      if retry_after_header.match?(/^\d+$/)
        return retry_after_header.to_i
      else
        # If it's a date, calculate seconds from now
        begin
          retry_time = Time.parse(retry_after_header)
          return [(retry_time - Time.current).to_i, 0].max
        rescue StandardError
          log_warn "Failed to parse Retry-After date: #{retry_after_header}"
        end
      end
    end
    
    # Check for X-RateLimit-Reset (common in APIs)
    reset_header = response.headers['X-RateLimit-Reset'] || response.headers['x-ratelimit-reset']
    if reset_header
      begin
        # Could be Unix timestamp or seconds from now
        reset_time = reset_header.to_i
        
        # If it's a large number, assume it's a Unix timestamp
        if reset_time > Time.current.to_i
          return [reset_time - Time.current.to_i, 0].max
        else
          # Otherwise assume it's seconds from now
          return reset_time
        end
      rescue StandardError
        log_warn "Failed to parse X-RateLimit-Reset: #{reset_header}"
      end
    end
    
    # Default fallback - exponential backoff based on response code
    case response.code
    when 429
      60 # 1 minute for too many requests
    when 503
      30 # 30 seconds for service unavailable
    else
      10 # 10 seconds default
    end
  end

  def set_domain_rate_limit(domain, retry_after_seconds)
    # Store rate limit info in Rails cache with expiration
    cache_key = "rate_limit_#{domain}"
    rate_limit_until = Time.current + retry_after_seconds.seconds
    
    Rails.cache.write(cache_key, rate_limit_until, expires_in: retry_after_seconds.seconds + 60)
    log_debug "Set rate limit for #{domain} until #{rate_limit_until}"
  end

  def domain_rate_limited?(domain)
    cache_key = "rate_limit_#{domain}"
    rate_limit_until = Rails.cache.read(cache_key)
    
    return false unless rate_limit_until
    
    if Time.current < rate_limit_until
      log_debug "Domain #{domain} is rate limited until #{rate_limit_until}"
      true
    else
      # Clean up expired rate limit
      Rails.cache.delete(cache_key)
      false
    end
  end

  def set_domain_block(domain, block_duration_seconds)
    # Store domain block info in Rails cache with long expiration
    cache_key = "domain_blocked_#{domain}"
    blocked_until = Time.current + block_duration_seconds.seconds
    
    Rails.cache.write(cache_key, blocked_until, expires_in: block_duration_seconds.seconds + 1.day)
    log_info "Blocked domain #{domain} until #{blocked_until.strftime('%Y-%m-%d')} (#{block_duration_seconds / 1.day.to_i} days)"
  end

  def domain_blocked?(domain)
    cache_key = "domain_blocked_#{domain}"
    blocked_until = Rails.cache.read(cache_key)
    
    return false unless blocked_until
    
    if Time.current < blocked_until
      days_remaining = ((blocked_until - Time.current) / 1.day).ceil
      log_debug "Domain #{domain} is blocked for #{days_remaining} more days (until #{blocked_until.strftime('%Y-%m-%d')})"
      true
    else
      # Clean up expired block and log that we're rechecking
      Rails.cache.delete(cache_key)
      log_info "Domain block expired for #{domain} - will attempt to recheck access"
      false
    end
  end

  def timeout_for_request
    config.fetch("request_timeout") { 30 }
  end

  def with_retry(max_attempts: 3, delay: 1)
    attempts = 0
    begin
      attempts += 1
      yield
    rescue RateLimitError => e
      # For rate limiting, respect the retry-after time
      if attempts < max_attempts
        log_info "Rate limited, waiting #{e.retry_after} seconds before retry (attempt #{attempts}/#{max_attempts})"
        sleep(e.retry_after)
        retry
      else
        log_error "Max retry attempts reached for rate limiting"
        raise
      end
    rescue StandardError => e
      if attempts < max_attempts && should_retry_error?(e)
        wait_time = delay * (2**(attempts - 1)) # Exponential backoff
        log_warn "Request failed (attempt #{attempts}/#{max_attempts}), retrying in #{wait_time}s: #{e.message}"
        sleep(wait_time)
        retry
      else
        raise
      end
    end
  end

  def should_retry_error?(error)
    # Retry for network errors, timeouts, and temporary server errors
    case error
    when Net::OpenTimeout, Net::ReadTimeout, Timeout::Error
      true
    when Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH
      true
    when StandardError
      # Check if it's an HTTP error we should retry
      if error.respond_to?(:response) && error.response
        code = error.response.code.to_i
        # Retry for 5xx errors (server errors) but not 4xx (client errors)
        code >= 500 && code < 600
      else
        false
      end
    else
      false
    end
  end

  def wait_for_rate_limit
    # Check global rate limiting
    last_request_time = Rails.cache.read("last_request_time_#{platform_name}")
    return unless last_request_time

    min_interval = config.fetch("min_request_interval") { 0.1 } # 100ms default
    elapsed = Time.current - last_request_time
    
    if elapsed < min_interval
      sleep_time = min_interval - elapsed
      log_debug "Rate limiting: sleeping #{sleep_time.round(3)}s"
      sleep(sleep_time)
    end

    Rails.cache.write("last_request_time_#{platform_name}", Time.current, expires_in: 1.minute)
  end

  def rate_limited?
    config.fetch("rate_limited") { true }
  end

  def sleep_between_batches
    batch_delay = config.fetch("batch_delay") { 1.0 }
    log_debug "Sleeping #{batch_delay}s between batches"
    sleep(batch_delay)
  end

  def wait_for_domain_rate_limit(domain)
    cache_key = "rate_limit_#{domain}"
    rate_limit_until = Rails.cache.read(cache_key)
    
    return unless rate_limit_until && Time.current < rate_limit_until
    
    wait_seconds = (rate_limit_until - Time.current).to_i
    log_info "Waiting #{wait_seconds} seconds for #{domain} rate limit to expire"
    
    sleep(wait_seconds)
    Rails.cache.delete(cache_key)
  end

  # Enhanced logging methods with context
  def log_info(message, context = {})
    Rails.logger.info("[INFO] [#{platform_name.upcase}] #{message} #{format_log_context(context)}")
  end

  def log_warn(message, context = {})
    Rails.logger.warn("[WARN] [#{platform_name.upcase}] #{message} #{format_log_context(context)}")
  end

  def log_error(message, context = {})
    Rails.logger.error("[ERROR] [#{platform_name.upcase}] #{message} #{format_log_context(context)}")
  end

  def log_debug(message, context = {})
    Rails.logger.debug("[DEBUG] [#{platform_name.upcase}] #{message} #{format_log_context(context)}")
  end

  def format_log_context(context)
    return "" if context.empty?
    
    base_context = {
      indexer: self.class.name,
      platform: platform_name,
      run_id: @indexing_run&.id
    }
    
    full_context = base_context.merge(context).compact
    "{#{full_context.map { |k, v| "#{k}: #{v.inspect}" }.join(", ")}}"
  end
end

# Fallback robots parser that disallows everything when robots.txt is inaccessible
class FallbackRobotsParser
  def allowed?(_url)
    false # Conservative approach - disallow if we can't verify
  end

  def other_values(_url)
    {}
  end
end
