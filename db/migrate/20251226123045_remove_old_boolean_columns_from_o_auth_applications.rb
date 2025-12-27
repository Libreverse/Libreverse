class RemoveOldBooleanColumnsFromOAuthApplications < ActiveRecord::Migration[8.1]
  def change
    # Remove old boolean columns that are now handled by FlagShihTzu flags
    remove_column :oauth_applications, :backchannel_logout_session_required, :boolean
    remove_column :oauth_applications, :frontchannel_logout_session_required, :boolean
    remove_column :oauth_applications, :require_pushed_authorization_requests, :boolean
    remove_column :oauth_applications, :tls_client_certificate_bound_access_tokens, :boolean
  end
end
