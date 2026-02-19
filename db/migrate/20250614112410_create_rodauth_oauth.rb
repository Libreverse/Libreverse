# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class CreateRodauthOauth < ActiveRecord::Migration[8.0]
  def change
    create_table :oauth_applications do |t|
      t.bigint :account_id
      t.string :name, null: false
      t.string :description, null: true
      t.string :homepage_url, null: true
      t.string :redirect_uri, null: false
      t.string :client_id, null: false
      t.string :client_secret, null: false
      t.string :registration_access_token, null: true
      t.string :scopes, null: false
      t.datetime :created_at, null: false

      # :oauth_dynamic_client_configuration enabled, extra optional params
      t.string :token_endpoint_auth_method, null: true
      t.string :grant_types, null: true
      t.string :response_types, null: true
      t.string :client_uri, null: true
      t.string :logo_uri, null: true
      t.string :tos_uri, null: true
      t.string :policy_uri, null: true
      t.string :jwks_uri, null: true
      t.string :jwks, null: true
      t.string :contacts, null: true
      t.string :software_id, null: true
      t.string :software_version, null: true

      # :oidc_dynamic_client_configuration enabled, extra optional params
      t.string :sector_identifier_uri, null: true
      t.string :application_type, null: true
      t.string :initiate_login_uri, null: true

      # :oidc enabled
      t.string :subject_type, null: true
      t.string :id_token_signed_response_alg, null: true
      t.string :id_token_encrypted_response_alg, null: true
      t.string :id_token_encrypted_response_enc, null: true
      t.string :userinfo_signed_response_alg, null: true
      t.string :userinfo_encrypted_response_alg, null: true
      t.string :userinfo_encrypted_response_enc, null: true

      # :oauth_jwt_secured_authorization_request
      t.string :request_object_signing_alg, null: true
      t.string :request_object_encryption_alg, null: true
      t.string :request_object_encryption_enc, null: true
      t.string :request_uris, null: true
      t.boolean :require_signed_request_object, null: true
      t.boolean :require_pushed_authorization_requests, null: false, default: false

      # :oauth_dpop
      t.string :dpop_bound_access_tokens, null: true

      # :oauth_tls_client_auth
      t.string :tls_client_auth_subject_dn, null: true
      t.string :tls_client_auth_san_dns, null: true
      t.string :tls_client_auth_san_uri, null: true
      t.string :tls_client_auth_san_ip, null: true
      t.string :tls_client_auth_san_email, null: true
      t.boolean :tls_client_certificate_bound_access_tokens, default: false

      # :oidc_rp_initiated_logout enabled
      t.string :post_logout_redirect_uris, null: false

      # frontchannel logout
      t.string :frontchannel_logout_uri
      t.boolean :frontchannel_logout_session_required, default: false

      # backchannel logout
      t.string :backchannel_logout_uri
      t.boolean :backchannel_logout_session_required, default: false
    end

    add_index :oauth_applications, :client_id, unique: true
    add_index :oauth_applications, :client_secret, unique: true
    add_foreign_key :oauth_applications, :accounts, column: :account_id

    create_table :oauth_grants do |t|
      t.bigint :account_id
      t.bigint :oauth_application_id
      t.string :type, null: true
      t.string :code, null: true
      t.string :token
      t.string :refresh_token
      t.datetime :expires_in, null: false
      t.string :redirect_uri
      t.datetime :revoked_at
      t.string :scopes, null: false
      t.datetime :created_at, null: false
      t.string :access_type, null: false, default: "offline"

      # :oauth_dpop enabled
      t.string :dpop_jwk, null: true

      # :oauth_pkce enabled
      t.string :code_challenge
      t.string :code_challenge_method

      # :oauth_device_code_grant enabled
      t.string :user_code, null: true
      t.datetime :last_polled_at, null: true

      # :oauth_tls_client_auth
      t.string :certificate_thumbprint, null: true

      # :resource_indicators enabled
      t.string :resource

      # :oidc enabled
      t.string :nonce
      t.string :acr
      t.string :claims_locales
      t.string :claims

      # :oauth_dpop enabled
      t.string :dpop_jkt
    end

    add_index :oauth_grants, %i[oauth_application_id code], unique: true
    add_index :oauth_grants, :token, unique: true
    add_index :oauth_grants, :refresh_token, unique: true
    add_index :oauth_grants, :user_code, unique: true
    add_foreign_key :oauth_grants, :accounts, column: :account_id
    add_foreign_key :oauth_grants, :oauth_applications, column: :oauth_application_id

    create_table :oauth_pushed_requests do |t|
      t.bigint :oauth_application_id
      t.string :code, null: false
      t.string :params, null: false
      t.datetime :expires_in, null: false
      # :oauth_dpop
      t.string :dpop_jkt

      t.timestamps
    end

    add_index :oauth_pushed_requests, :code, unique: true
    add_index :oauth_pushed_requests, %i[oauth_application_id code], unique: true
    add_foreign_key :oauth_pushed_requests, :oauth_applications, column: :oauth_application_id

    create_table :oauth_saml_settings do |t|
      t.bigint :oauth_application_id
      t.text :idp_cert, null: true
      t.text :idp_cert_fingerprint, null: true
      t.string :idp_cert_fingerprint_algorithm, null: true
      t.boolean :check_idp_cert_expiration, null: true
      t.text :name_identifier_format, null: true
      t.string :audience, null: true
      t.string :issuer, null: false

      t.timestamps
    end

    add_index :oauth_saml_settings, :issuer, unique: true
    add_foreign_key :oauth_saml_settings, :oauth_applications, column: :oauth_application_id

    create_table :oauth_dpop_proofs do |t|
      t.string :jti, null: false
      t.datetime :first_use, null: false
    end

    add_index :oauth_dpop_proofs, :jti, unique: true
  end
end
