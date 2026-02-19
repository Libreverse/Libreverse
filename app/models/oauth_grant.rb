# typed: strict
# frozen_string_literal: true
# shareable_constant_value: literal

# == Schema Information
#
# Table name: oauth_grants
#
#  id                     :bigint           not null, primary key
#  access_type            :string(255)      default("offline"), not null
#  acr                    :string(255)      not null
#  certificate_thumbprint :string(255)      not null
#  claims                 :string(255)      not null
#  claims_locales         :string(255)      not null
#  code                   :string(255)      not null
#  code_challenge         :string(255)      not null
#  code_challenge_method  :string(255)      not null
#  dpop_jkt               :string(255)      not null
#  dpop_jwk               :string(255)      not null
#  expires_in             :datetime         not null
#  last_polled_at         :datetime         not null
#  nonce                  :string(255)      not null
#  redirect_uri           :string(255)      not null
#  refresh_token          :string(255)      not null
#  resource               :string(255)      not null
#  revoked_at             :datetime         not null
#  scopes                 :string(255)      not null
#  token                  :string(255)      not null
#  type                   :string(255)
#  user_code              :string(255)      not null
#  created_at             :datetime         not null
#  account_id             :bigint           not null
#  oauth_application_id   :bigint           not null
#
# Indexes
#
#  fk_rails_3e095b0b7e                                  (account_id)
#  index_oauth_grants_on_oauth_application_id_and_code  (oauth_application_id,code) UNIQUE
#  index_oauth_grants_on_refresh_token                  (refresh_token) UNIQUE
#  index_oauth_grants_on_token                          (token) UNIQUE
#  index_oauth_grants_on_user_code                      (user_code) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (oauth_application_id => oauth_applications.id)
#
class OauthGrant < ApplicationRecord
  validates :account_id, :access_type, :acr, :certificate_thumbprint, :claims,
            :claims_locales, :code, :code_challenge, :code_challenge_method,
            :dpop_jkt, :dpop_jwk, :expires_in, :last_polled_at, :nonce,
            :oauth_application_id, :redirect_uri, :refresh_token, :resource,
            :revoked_at, :scopes, :token, :user_code, presence: true

  validates :access_type, :acr, :certificate_thumbprint, :claims,
            :claims_locales, :code, :code_challenge, :code_challenge_method,
            :dpop_jkt, :dpop_jwk, :nonce, :redirect_uri, :refresh_token,
            :resource, :scopes, :token, :type, :user_code,
            length: { maximum: 255 }, allow_blank: true
end
