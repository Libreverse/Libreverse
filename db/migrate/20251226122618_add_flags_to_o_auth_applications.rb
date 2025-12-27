class AddFlagsToOAuthApplications < ActiveRecord::Migration[8.1]
  def change
    # Add flags column for FlagShihTzu bit field storage
    # Bit positions: 1=backchannel_logout_session_required, 2=frontchannel_logout_session_required, 3=require_pushed_authorization_requests, 4=tls_client_certificate_bound_access_tokens
    add_column :oauth_applications, :flags, :integer, null: false, default: 0
  end
end
