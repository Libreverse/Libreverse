# frozen_string_literal: true
# shareable_constant_value: literal

json.result do
  json.id @account.id
  json.username @account.username
  json.admin @account.admin?
  json.guest @account.guest?
  json.status @status
end
