# Be sure to restart your server when you modify this file.

# Configure CORS policies for the application
# This allows specific origins to make cross-origin requests

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Only allow specific origins
    origins "libreverse.geor.me", "libreverse.dev", "localhost:3000"

    # Only allow specific resources and methods
    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true,
             max_age: 86_400
  end
end
