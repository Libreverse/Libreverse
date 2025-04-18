# frozen_string_literal: true

# Session and Cookies Configuration
# This file contains all session and cookie-related configurations including:
# - Cookie serialization
# - Session security
# - Parameter filtering for logging

# ===== Cookie Serialization =====
# Specify a serializer for the signed and encrypted cookie jars.
# Valid options are:
# - :json (safest, but can only serialize basic data types)
# - :marshal (most compatible, but potentially dangerous)
# - :hybrid (fallback mechanism that reads marshal cookies but writes json cookies)
#
# Using :json is the most secure option as it limits the risk of deserialization attacks
# that could occur with :marshal.
# --- Reverting to JSON serializer ---
Rails.application.config.action_dispatch.cookies_serializer = :json
# Rails.application.config.action_dispatch.cookies_serializer = :marshal
# ----------------------------------

# Use SHA256 for signed cookies for improved security over the default SHA1
Rails.application.config.action_dispatch.signed_cookie_digest = "SHA256"

# Do not allow JavaScript to access cookies for added security
Rails.application.config.action_dispatch.cookies_same_site_protection = :strict

# Use authenticated cookie encryption for improved security
Rails.application.config.action_dispatch.use_authenticated_cookie_encryption = true

# ===== Parameter Filtering =====
# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += %i[
  # Credentials and authentication
  passw
  secret
  token
  _key
  crypt
  salt
  certificate
  otp
  ssn

  # Personal identifying information
  name
  username
  email
  address
  phone
  birth
  gender
  national

  # Financial information
  card
  account
  iban
  bank
  tax
  income

  # Health information
  health
  medical
  insurance

  # Session and security related
  csrf
  xsrf
  session
  cookie
  auth

  # Other sensitive fields
  social
  verification
  answer
  key
  secret_question
]
