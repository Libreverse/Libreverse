# frozen_string_literal: true

# Filter Sensitive Parameters from Logs
# See ActiveSupport::ParameterFilter documentation for supported patterns.
Rails.application.config.filter_parameters += %i[
  # Credentials and authentication
  passw secret token _key crypt salt certificate otp ssn

  # Personal identifying information
  name username email address phone birth gender national

  # Financial information
  card account iban bank tax income

  # Health information
  health medical insurance

  # Session and security related
  csrf xsrf session cookie auth

  # Other sensitive fields
  social verification answer key secret_question
]
