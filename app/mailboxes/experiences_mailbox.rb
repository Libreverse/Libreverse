# frozen_string_literal: true
# shareable_constant_value: literal

class ExperiencesMailbox < ApplicationMailbox
  def process
    # Only process if email bot is enabled
    return unless LibreverseInstance.email_bot_enabled?

    # Extract sender information
    sender_email = mail.from.first
    sender_name = mail.sender&.display_name || sender_email.split("@").first.humanize

    # Extract experience title from email
    experience_title = extract_experience_title

    Rails.logger.info "[ExperiencesMailbox] Processing email from #{sender_email} for experience: '#{experience_title}'"

    # Queue the experience processing job
    ProcessExperienceEmailJob.perform_later(
      sender_email: sender_email,
      sender_name: sender_name,
      experience_title: experience_title,
      original_message_id: mail.message_id
    )
  end

  private

  def extract_experience_title
    # Try subject first (remove common prefixes)
    subject_title = mail.subject&.strip
    if subject_title.present?
      # Remove common email prefixes and experience request patterns
      cleaned_subject = subject_title
                        .gsub(/^(re:|fwd?:|get\s+experience:?)\s*/i, "")
                        .strip

      return cleaned_subject if cleaned_subject.present?
    end

    # Extract title from email body (first non-empty line)
    body_text = extract_body_text
    lines = body_text.split("\n").map(&:strip).reject(&:blank?)

    # Get first line that looks like a title (not a command or email signature)
    title_line = lines.find do |line|
      !line.start_with?("--") &&
        !line.match?(/^(please|send|get|download|thank|regards|best)/i) &&
        line.length > 3
    end

    title_line&.strip
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
    Rails.logger.error "[ExperiencesMailbox] Error extracting email body: #{e.message}"
    ""
  end
end
