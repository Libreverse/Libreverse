# Be sure to restart your server when you modify this file.

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
