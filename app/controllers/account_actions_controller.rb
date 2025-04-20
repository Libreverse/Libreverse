# frozen_string_literal: true

class AccountActionsController < ApplicationController
  before_action :require_logged_in

  # GET /account/export
  def export
    exporter = AccountExporter.new(current_account)
    send_data exporter.generate_zip,
              filename: "libreverse-account-export-#{Time.current.to_i}.zip",
              type: "application/zip"
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
end

# Simple service for packaging account data → ZIP.
require "zip"
class AccountExporter
  def initialize(account)
    @account = account
  end

  def generate_zip
    buffer = Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry "account.json"
      zip.write JSON.pretty_generate(account_json)

      # Preferences
      zip.put_next_entry "preferences.json"
      prefs = UserPreference.where(account_id: @account.id).pluck(:key, :value).to_h
      zip.write JSON.pretty_generate(prefs)

      # Experiences (metadata + HTML attachment)
      @account.experiences.find_each do |experience|
        # Metadata for the experience
        zip.put_next_entry "experiences/#{experience.id}/metadata.json"
        exp_json = experience.as_json(except: %i[account_id])
        zip.write JSON.pretty_generate(exp_json)

        # Attached HTML file (if present)
        if experience.html_file.attached?
          # Use original filename or fallback to a predictable name
          filename = experience.html_file.filename.to_s.presence || "experience_#{experience.id}.html"
          zip.put_next_entry "experiences/#{experience.id}/#{filename}"
          zip.write experience.html_file.download
        end
      end
    end
    buffer.rewind
    buffer.read
  end

  private

  def account_json
    @account.as_json(except: %i[password_hash]).merge("exported_at" => Time.current)
  end
end
