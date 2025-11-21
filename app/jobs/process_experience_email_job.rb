# frozen_string_literal: true
# shareable_constant_value: literal

class ProcessExperienceEmailJob < ApplicationJob
  queue_as :default

  def perform(sender_email:, sender_name:, experience_title:, original_message_id:)
    Rails.logger.info "[ProcessExperienceEmailJob] Processing request for: '#{experience_title}' from #{sender_email}"

    # Validate experience title
    if experience_title.blank?
      send_error_response(sender_email, sender_name, "No experience title provided", original_message_id)
      return
    end

    begin
      # Find the experience using our service
      experience = ExperienceDownloadService.find_experience_object_by_title(experience_title)

      if experience.nil?
        send_error_response(
          sender_email,
          sender_name,
          "Experience '#{experience_title}' not found or not available for offline download",
          original_message_id
        )
        return
      end

      # Generate ZIP file
      zip_file = ExperienceDownloadService.generate_zip_file(experience)

      if zip_file.nil?
        send_error_response(
          sender_email,
          sender_name,
          "Failed to generate offline package for '#{experience.title}'",
          original_message_id
        )
        return
      end

      # Prepare experience data for email
      experience_data = {
        title: experience.title,
        author: experience.author,
        description: experience.description,
        url: experience_url(experience),
        id: experience.id
      }

      # Send the ZIP file via email
      ExperiencesMailer.offline_experience(
        sender_email,
        sender_name,
        experience_data,
        {
          original_message_id: original_message_id,
          zip_file: zip_file
        }
      ).deliver_now

      Rails.logger.info "[ProcessExperienceEmailJob] Successfully sent experience '#{experience.title}' to #{sender_email}"
    rescue StandardError => e
      Rails.logger.error "[ProcessExperienceEmailJob] Error processing experience request: #{e.message}"
      send_error_response(
        sender_email,
        sender_name,
        "An error occurred while processing your request: #{e.message}",
        original_message_id
      )
    end
  end

  private

  def send_error_response(sender_email, sender_name, error_message, original_message_id)
    ExperiencesMailer.experience_error(
      sender_email,
      sender_name,
      error_message,
      { original_message_id: original_message_id }
    ).deliver_now
  end

  def experience_url(experience)
    Rails.application.routes.url_helpers.experience_url(
      experience,
      host: LibreverseInstance.instance_domain,
      protocol: LibreverseInstance.force_ssl? ? "https" : "http"
    )
  end
end
