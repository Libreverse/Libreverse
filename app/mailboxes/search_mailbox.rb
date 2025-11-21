# frozen_string_literal: true
# shareable_constant_value: literal

class SearchMailbox < ApplicationMailbox
  def process
    # Only process if email bot is enabled
    return unless LibreverseInstance.email_bot_enabled?

    # Extract sender information
    sender_email = mail.from.first
    sender_name = mail.sender&.display_name || sender_email

    # Extract search query from email
    query = extract_search_query

    # Parse options from email body
    options = extract_search_options

    Rails.logger.info "[SearchMailbox] Processing email from #{sender_email} with query: '#{query}'"

    # Queue the search processing job
    ProcessSearchEmailJob.perform_later(
      sender_email: sender_email,
      sender_name: sender_name,
      query: query,
      options: options,
      original_message_id: mail.message_id
    )
  end

  private

  def extract_search_query
    # Try subject first, then body
    subject_query = mail.subject&.strip
    return subject_query if subject_query.present? && !subject_query.match?(/^(re:|fwd?:)/i)

    # Extract query from email body
    body_text = extract_body_text
    lines = body_text.split("\n").map(&:strip).reject(&:blank?)

    # Look for lines that aren't commands (don't start with --)
    query_lines = lines.reject { |line| line.start_with?("--") }
    query_lines.first&.strip
  end

  def extract_search_options
    options = {
      federated: false,
      limit: 20,
      format: :links # :links or :attachment
    }

    body_text = extract_body_text
    lines = body_text.split("\n").map(&:strip)

    # Parse command lines (starting with --)
    lines.each do |line|
      next unless line.start_with?("--")

      line = line[2..].strip # Remove --
      key, value = line.split(":", 2).map(&:strip)

      case key&.downcase
      when "federated"
        options[:federated] = %w[true yes 1].include?(value&.downcase)
      when "limit"
        limit = value&.to_i
        options[:limit] = limit.positive? && limit <= 100 ? limit : 20
      when "format"
        options[:format] = value&.downcase == "attachment" ? :attachment : :links
      end
    end

    options
  end

  def extract_body_text
    if mail.multipart?
      # Try to get text/plain part
      text_part = mail.text_part
      return text_part.body.decoded if text_part

      # Fallback to first part
      mail.parts.first&.body&.decoded || ""
    else
      mail.body.decoded
    end
  rescue StandardError => e
    Rails.logger.error "[SearchMailbox] Error extracting email body: #{e.message}"
    ""
  end
end
