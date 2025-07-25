# frozen_string_literal: true

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

  # Make HTTP requests with proper error handling and rate limiting
  def make_request(url, options = {})
    wait_for_rate_limit

    with_retry do
      log_debug "Making request to: #{url}"

      default_options = {
        timeout: timeout_for_request,
        headers: default_headers
      }

      response = HTTParty.get(url, default_options.merge(options))

      if response.code >= 400
        error_msg = "HTTP #{response.code}: #{response.message || 'Request failed'}"
        error = StandardError.new(error_msg)
        error.define_singleton_method(:response) { response }
        raise error
      end

      response
    end
  end

  def make_post_request(url, body, options = {})
    wait_for_rate_limit

    with_retry do
      log_debug "Making POST request to: #{url}"

      default_options = {
        timeout: timeout_for_request,
        headers: default_headers.merge("Content-Type" => "application/json"),
        body: body.is_a?(String) ? body : body.to_json
      }

      response = HTTParty.post(url, default_options.merge(options))

      if response.code >= 400
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
      "User-Agent" => "Libreverse Indexer/1.0 (#{platform_name})",
      "Accept" => "application/json"
    }
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
end
