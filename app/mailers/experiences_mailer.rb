# Mailer for delivering offline HTML files of experiences via email
class ExperiencesMailer < ApplicationMailer
  include EmailHelper

  # Send an offline experience as a ZIP file
  def offline_experience(recipient_email, recipient_name, experience_data, options = {})
    @recipient_name = recipient_name
    @experience = experience_data
    @instance_domain = LibreverseInstance.instance_domain

    # Use provided ZIP file or generate one
    zip_content = if options[:zip_file]
      # Read the ZIP file content from the provided StringIO object
      options[:zip_file].read
    else
      # Fallback to generating ZIP file (legacy behavior)
      generate_experience_zip(@experience)
    end

  # Attach the ZIP file
  zip_filename = "#{normalized_filename(@experience[:title])}.zip"
    attachments[zip_filename] = {
      mime_type: "application/zip",
      content: zip_content
    }

    # Set up response headers
    headers = {
      to: recipient_email,
      subject: "📦 Offline Experience ZIP: #{@experience[:title]}"
    }

    # Add In-Reply-To header if we have original message ID
    if options[:original_message_id].present?
      headers["In-Reply-To"] = options[:original_message_id]
      headers["References"] = options[:original_message_id]
    end

    mail(headers)
  end

  # Send error response for invalid experience requests
  def experience_error(recipient_email, recipient_name, error_message, options = {})
    @recipient_name = recipient_name
    @error_message = error_message
    @instance_domain = LibreverseInstance.instance_domain

    headers = {
      to: recipient_email,
      subject: "❌ Experience Request Error"
    }

    if options[:original_message_id].present?
      headers["In-Reply-To"] = options[:original_message_id]
      headers["References"] = options[:original_message_id]
    end

    mail(headers)
  end

  private

  # Generate a ZIP file containing the experience
  # NOTE: This method uses rubyzip (not zip_kit) because email attachments need to be
  # fully buffered in memory before being attached to the email. zip_kit is designed
  # for streaming and doesn't work well with email attachment workflows.
  def generate_experience_zip(experience)
    require "zip"
    Zip.default_compression = Zlib::BEST_COMPRESSION

    # Create ZIP in memory
    zip_buffer = Zip::OutputStream.write_buffer do |zip|
      # Add the main HTML file
      html_content = generate_offline_html(experience)
  zip.put_next_entry("#{normalized_filename(experience[:title])}.html")
      zip.write(html_content)

      # Add a README file
      readme_content = generate_readme(experience)
      zip.put_next_entry("README.txt")
      zip.write(readme_content)

      # Add metadata file
      metadata_content = generate_metadata_json(experience)
      zip.put_next_entry("metadata.json")
      zip.write(metadata_content)
    end

    zip_buffer.string
  end

  # Generate README file for the ZIP
  def generate_readme(experience)
    <<~README
          LibreVerse Offline Experience
          ============================

          Title: #{experience[:title]}
          Author: #{experience[:author] || 'Unknown'}
          Downloaded: #{Time.current.strftime('%Y-%m-%d at %H:%M %Z')}
          Original URL: #{experience[:url]}

          CONTENTS:
          ---------
      - #{normalized_filename(experience[:title])}.html - The main experience file
          - README.txt - This file
          - metadata.json - Technical metadata

          HOW TO VIEW:
          ------------
          1. Open the HTML file in any web browser
          2. The experience will work completely offline
          3. Share the ZIP file to pass along the experience

          ABOUT LIBREVERSE:
          -----------------
          LibreVerse believes in making knowledge accessible everywhere.
          This offline experience was delivered via email because email works
          on every device, in every country, across every platform.

          Visit #{LibreverseInstance.instance_domain} for more experiences.
          Email search@#{LibreverseInstance.instance_domain} to find more content.
    README
  end

  # Generate metadata JSON
  def generate_metadata_json(experience)
    metadata = {
      title: experience[:title],
      author: experience[:author],
      url: experience[:url],
      downloaded_at: Time.current.iso8601,
      format_version: "1.0",
      source: "LibreVerse Email Service",
      instance: LibreverseInstance.instance_domain
    }

    JSON.pretty_generate(metadata)
  end

  # Generate a complete offline HTML file for an experience
  def generate_offline_html(experience)
    # This would render the experience as a complete, standalone HTML file
    # For now, let's create a basic structure
    <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>#{html_escape(experience[:title])}</title>
            <style>
              #{inline_email_css('~/stylesheets/offline.scss')}
            </style>
          </head>
          <body>
            <header>
              <h1>#{html_escape(experience[:title])}</h1>
              #{experience[:author] ? "<p>By: #{html_escape(experience[:author])}</p>" : ''}
              <p><small>Downloaded from #{@instance_domain}</small></p>
            </header>
          #{'  '}
            <main>
              #{experience[:content] || '<p>Content not available</p>'}
            </main>
          #{'  '}
            <footer>
              <hr>
              <p><small>
                This offline experience was generated by LibreVerse email services.<br>
                Original URL: <a href="#{experience[:url]}">#{experience[:url]}</a><br>
                Generated: #{Time.current.strftime('%Y-%m-%d at %H:%M %Z')}
              </small></p>
            </footer>
          </body>
          </html>
    HTML
  end

  def normalized_filename(title)
    base = sanitize_filename(title)
    base.downcase.gsub(/[^a-z0-9_.-]/, "_")
  end

  # Sanitize filename for attachment
  def sanitize_filename(title)
    title.gsub(/[^0-9A-Za-z.-]/, "_").gsub(/_+/, "_").strip.truncate(50)
  end

  # Simple HTML escaping
  def html_escape(text)
    CGI.escapeHTML(text.to_s)
  end
end
