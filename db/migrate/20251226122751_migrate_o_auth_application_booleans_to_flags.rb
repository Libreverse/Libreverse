# frozen_string_literal: true
# shareable_constant_value: literal

class MigrateOAuthApplicationBooleansToFlags < ActiveRecord::Migration[8.1]
  def up
    # Migrate existing boolean data to flags bit field
    # Bit positions: 1=backchannel_logout_session_required, 2=frontchannel_logout_session_required, 3=require_pushed_authorization_requests, 4=tls_client_certificate_bound_access_tokens

    OauthApplication.find_each do |app|
      flags = 0
      flags |= 1 if app.backchannel_logout_session_required?
      flags |= 2 if app.frontchannel_logout_session_required?
      flags |= 4 if app.require_pushed_authorization_requests?
      flags |= 8 if app.tls_client_certificate_bound_access_tokens?

      app.update_columns(flags: flags)
    end
  end

  def down
    # Revert by setting all flags to 0
    OauthApplication.update_all(flags: 0)
  end
end
