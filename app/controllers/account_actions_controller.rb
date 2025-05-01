# frozen_string_literal: true

class AccountActionsController < ApplicationController
  include ZipKit::RailsStreaming
  before_action :require_logged_in

  # GET /account/export
  def export
    zip_kit_stream do |zip|
      # 1) Account JSON
      zip.write_file "account.json" do |sink|
        sink << JSON.pretty_generate(account_json)
      end

      # 2) Preferences JSON
      prefs = UserPreference::ALLOWED_KEYS.each_with_object({}) do |key, h|
        val = UserPreference.get(current_account.id, key)
        h[key] = val if val.present?
      end
      zip.write_file "preferences.json" do |sink|
        sink << JSON.pretty_generate(prefs)
      end

      # 3) Experiences
      Experience.where(account_id: current_account.id).find_each do |exp|
        # Metadata
        zip.write_file "experiences/#{exp.id}/metadata.json" do |sink|
          sink << JSON.pretty_generate(exp.as_json(except: %i[account_id]))
        end

        # HTML attachment
        if exp.html_file.attached?
          filename = exp.html_file.filename.to_s.presence || "experience_#{exp.id}.html"
          zip.write_file "experiences/#{exp.id}/#{filename}" do |sink|
              data = exp.html_file.download
              sink << data if data
          rescue StandardError => e
              Rails.logger.error "[AccountExport] Error streaming html_file for experience #{exp.id}: #{e.message}"
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

  def require_logged_in
    redirect_to rodauth.login_path unless current_account
  end

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
