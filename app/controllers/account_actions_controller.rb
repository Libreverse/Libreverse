# frozen_string_literal: true

class AccountActionsController < ApplicationController
  include ZipKit::RailsStreaming # Restored ZipKit for streaming web downloads
  require "zip" # Keep for any legacy functionality if needed

  # Use new authentication - require authenticated users (no guests)
  before_action :require_authenticated_user

  # GET /account/export
  def export
    zip_kit_stream(filename: "libreverse_export.zip") do |zip|
      # 1) Account XML - force deflated mode for maximum compression
      zip.write_deflated_file("account.xml") do |sink|
        sink << account_json.to_xml(root: "account")
      end

      # 2) Preferences XML - force deflated mode for maximum compression
      prefs = UserPreference::ALLOWED_KEYS.each_with_object({}) do |key, h|
        val = UserPreference.get(current_account.id, key)
        h[key] = val if val.present?
      end
      zip.write_deflated_file("preferences.xml") do |sink|
        sink << prefs.to_xml(root: "preferences")
      end

      # 3) Experiences
      Experience.where(account_id: current_account.id).find_each do |exp|
        # Metadata - force deflated mode for maximum compression
        zip.write_deflated_file("experiences/#{exp.id}/metadata.xml") do |sink|
          sink << exp.as_json(except: %i[account_id]).to_xml(root: "experience")
        end

        # HTML attachment - stream directly without buffering
        # Use deflated mode for maximum compression of HTML content
        if exp.html_file.attached?
          filename = exp.html_file.filename.to_s.presence || "experience_#{exp.id}.html"
          zip.write_deflated_file("experiences/#{exp.id}/#{filename}") do |sink|
            begin
              # Stream the file directly using Active Storage's streaming capabilities
              exp.html_file.download { |chunk| sink << chunk }
            rescue StandardError => e
              Rails.logger.error "[AccountExport] Error streaming html_file for experience #{exp.id}: #{e.message}"
              sink << "Error: Could not export attached file - #{e.message}"
            end
          end
        end
      end
    end
  end

  # DELETE /account
  def destroy
    # Run the close_account internal request via the helper Rodauth adds for
    # each route (see the :internal_request feature). This performs the full
    # workflow inside a transaction and also honours our hooks.
    RodauthMain.close_account(account_id: current_account.id)

    # 3. Log the user out to clear any remaining session/cookies.
    reset_session

    flash[:notice] = "Your account has been deleted. We're sorry to see you go."
    redirect_to root_path
  end

  private

  def account_json
    # Only export non-sensitive account data
    safe_attrs = current_account.as_json(
      except: %i[password_hash created_at updated_at status]
    )

    # Add export metadata
    safe_attrs.merge(
      "exported_at" => Time.current,
      "account_status" => account_status,
      "export_version" => "1.0"
    )
  end

  def account_status
    case current_account.status
    when 1 then "unverified"
    when 2 then "verified"
    when 3 then "closed"
    else "unknown"
    end
  end
end
