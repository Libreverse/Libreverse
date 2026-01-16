# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# == Schema Information
#
# Table name: oauth_applications
#
#  id                              :bigint           not null, primary key
#  application_type                :string(255)
#  backchannel_logout_uri          :string(255)
#  client_secret                   :string(255)      not null
#  client_uri                      :string(255)
#  contacts                        :string(255)
#  description                     :string(255)
#  dpop_bound_access_tokens        :string(255)
#  flags                           :integer          default(0), not null
#  frontchannel_logout_uri         :string(255)
#  grant_types                     :string(255)
#  homepage_url                    :string(255)
#  id_token_encrypted_response_alg :string(255)
#  id_token_encrypted_response_enc :string(255)
#  id_token_signed_response_alg    :string(255)
#  initiate_login_uri              :string(255)
#  jwks                            :string(255)
#  jwks_uri                        :string(255)
#  logo_uri                        :string(255)
#  name                            :string(255)      not null
#  policy_uri                      :string(255)
#  post_logout_redirect_uris       :string(255)      not null
#  redirect_uri                    :string(255)      not null
#  registration_access_token       :string(255)
#  request_object_encryption_alg   :string(255)
#  request_object_encryption_enc   :string(255)
#  request_object_signing_alg      :string(255)
#  request_uris                    :string(255)
#  require_signed_request_object   :boolean
#  response_types                  :string(255)
#  scopes                          :string(255)      not null
#  sector_identifier_uri           :string(255)
#  software_version                :string(255)
#  subject_type                    :string(255)
#  tls_client_auth_san_dns         :string(255)
#  tls_client_auth_san_email       :string(255)
#  tls_client_auth_san_ip          :string(255)
#  tls_client_auth_san_uri         :string(255)
#  tls_client_auth_subject_dn      :string(255)
#  token_endpoint_auth_method      :string(255)
#  tos_uri                         :string(255)
#  userinfo_encrypted_response_alg :string(255)
#  userinfo_encrypted_response_enc :string(255)
#  userinfo_signed_response_alg    :string(255)
#  created_at                      :datetime         not null
#  account_id                      :bigint
#  client_id                       :string(255)      not null
#  software_id                     :string(255)
#
# Indexes
#
#  fk_rails_211c1cecac                        (account_id)
#  index_oauth_applications_on_client_id      (client_id) UNIQUE
#  index_oauth_applications_on_client_secret  (client_secret) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class OauthApplication < ApplicationRecord
  include FlagShihTzu

  # FlagShihTzu bit field configuration
  # Bit positions: 1=backchannel_logout_session_required, 2=frontchannel_logout_session_required, 3=require_pushed_authorization_requests, 4=tls_client_certificate_bound_access_tokens
  has_flags 1 => :backchannel_logout_session_required,
            2 => :frontchannel_logout_session_required,
            4 => :require_pushed_authorization_requests,
            8 => :tls_client_certificate_bound_access_tokens
end
