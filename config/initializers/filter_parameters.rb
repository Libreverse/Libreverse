# frozen_string_literal: true
# shareable_constant_value: literal

# Filter Sensitive Parameters from Logs
# See ActiveSupport::ParameterFilter documentation for supported patterns.
# Credentials and authentication: secret, token, _key, crypt, salt, certificate, otp, ssn
# Personal identifying information: name, username, email, address, phone, birth, gender, national
# Financial information: card, account, iban, bank, tax, income
# Health information: health, medical, insurance
# Session and security related: csrf, xsrf, session, cookie, auth
# Other sensitive fields: social, verification, answer, key, secret_question
Rails.application.config.filter_parameters += %i[
  passw
  secret
  token
  _key
  crypt
  salt
  certificate
  otp
  ssn
  name
  username
  email
  address
  phone
  birth
  gender
  national
  card
  account
  iban
  bank
  tax
  income
  health
  medical
  insurance
  csrf
  xsrf
  session
  cookie
  auth
  social
  verification
  answer
  key
  secret_question
]
