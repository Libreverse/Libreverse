# typed: strict
# frozen_string_literal: true
# shareable_constant_value: literal

# == Schema Information
#
# Table name: oauth_grants
#
#  id                     :bigint           not null, primary key
#  access_type            :string(255)      default("offline"), not null
#  acr                    :string(255)
#  certificate_thumbprint :string(255)
#  claims                 :string(255)
#  claims_locales         :string(255)
#  code                   :string(255)
#  code_challenge         :string(255)
#  code_challenge_method  :string(255)
#  dpop_jkt               :string(255)
#  dpop_jwk               :string(255)
#  expires_in             :datetime         not null
#  last_polled_at         :datetime
#  nonce                  :string(255)
#  redirect_uri           :string(255)
#  refresh_token          :string(255)
#  resource               :string(255)
#  revoked_at             :datetime
#  scopes                 :string(255)      not null
#  token                  :string(255)
#  type                   :string(255)
#  user_code              :string(255)
#  created_at             :datetime         not null
#  account_id             :bigint
#  oauth_application_id   :bigint
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
end
