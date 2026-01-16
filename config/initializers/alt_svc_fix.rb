# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

# Ensure HTTP/1.1 in development: clear any Alt-Svc hints from responses
# so that clients don't attempt HTTP/2/3 upgrades against localhost.
remove_alt_svc = Class.new do
def initialize(app) = (@app = app)

def call(env)
    status, headers, body = @app.call(env)
    headers.delete("Alt-Svc")
    [ status, headers, body ]
end
end
Rails.application.config.middleware.insert_before 0, remove_alt_svc
