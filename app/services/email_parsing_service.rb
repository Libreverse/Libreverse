# Service to parse incoming emails and extract the relevant content
class EmailParsingService
  def self.extract_search_query(email_body, email_subject = nil)
    # Clean up the email body by removing common email artifacts
    cleaned_body = clean_email_content(email_body)

    # Use the first non-empty line as the search query
    query = cleaned_body.split("\n").first&.strip

    # Fallback to subject if body is empty or just contains email artifacts
    query = email_subject&.strip if query.blank? || is_email_artifact?(query)

    # Remove common email prefixes from subject
    query = query.gsub(/^(re:|fwd?:|subject:)\s*/i, "").strip if query

    query.presence || "general search"
  end

  def self.extract_experience_title(email_body, email_subject = nil)
    # Clean up the email body
    cleaned_body = clean_email_content(email_body)

    # Use the first meaningful line as the experience title
    title = cleaned_body.split("\n").first&.strip

    # Fallback to subject if body doesn't contain a clear title
    title = email_subject&.strip if title.blank? || is_email_artifact?(title)

    # Remove common email prefixes and experience request language
    if title
      title = title.gsub(/^(re:|fwd?:|subject:|get|download|send|please)\s*/i, "").strip
      title = title.gsub(/\s*(experience|zip|file|offline)\s*$/i, "").strip
    end

    title.presence
  end

  def self.parse_search_options(email_content)
    options = {}

    # Look for command flags in the email
    options[:federated] = true if email_content.match?(/--federated:\s*true/i)

    if (match = email_content.match(/--limit:\s*(\d+)/i))
      limit = match[1].to_i
      options[:limit] = [ limit, 100 ].min # Cap at 100
    end

    options[:format] = "attachment" if email_content.match?(/--format:\s*attachment/i)

    options
  end

  class << self
    private

    def clean_email_content(content)
      return "" if content.blank?

      # Remove common email signatures and footers
      cleaned = content.dup

      # Remove everything after common signature markers
      signature_markers = [
        /^--\s*$/,
        /^Sent from my/i,
        /^Get Outlook for/i,
        /^Sent via/i,
        /^This email was sent/i
      ]

      signature_markers.each do |marker|
        if (match_index = cleaned.match(marker))
          cleaned = cleaned[0...match_index.begin(0)]
        end
      end

      # Remove quoted email content (lines starting with >)
      lines = cleaned.split("\n")
      lines = lines.take_while { |line| !line.match?(/^>\s*/) }

      # Remove empty lines and common email artifacts
      lines = lines.reject { |line| email_artifact?(line) }

      lines.join("\n").strip
    end

    def email_artifact?(line)
      return true if line.blank?

      # Common email artifacts to ignore
      artifacts = [
        /^sent from my/i,
        /^get outlook/i,
        /^sent via/i,
        /^this email/i,
        /^original message/i,
        /^from:/i,
        /^to:/i,
        /^subject:/i,
        /^date:/i,
        /^cc:/i,
        /^bcc:/i,
        /^\s*--+\s*$/,
        /^\s*=+\s*$/,
        /^\s*_+\s*$/
      ]

      artifacts.any? { |pattern| line.match?(pattern) }
    end
  end
end
