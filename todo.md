# Todo List

1. ✓ **Implement federated authentication for metaverse instances**

    - ✓ **Set up each instance as an OIDC provider using `rodauth-oauth`**
        - ✓ Add `gem 'rodauth-oauth'` to the Gemfile
        - ✓ Run `bundle install` to install the gem
        - ✓ In `app/models/rodauth_main.rb`, configure Rodauth with:
            - ✓ `enable :oidc`
            - ✓ `oidc_issuer "https://#{Rails.application.config.x.instance_domain}"`
            - ✓ `oauth_application_scopes %w[openid profile email]`
        - ✓ Set the instance domain in `config/application.rb`:
            - ✓ `config.x.instance_domain = ENV['INSTANCE_DOMAIN'] || 'default_domain.com'`
        - ✓ Generate and run migrations for OIDC tables:
            - ✓ `rails g rodauth:oauth:install`
            - ✓ `rails db:migrate`
        - □ Verify the discovery endpoint is accessible at `https://your_instance_domain/.well-known/openid-configuration`
    - ✓ **Implement OIDC client with `gitlab-omniauth-openid-connect` for dynamic providers**

        - ✓ Add `gem 'gitlab-omniauth-openid-connect'` and `gem 'httparty'` to the Gemfile
        - ✓ Run `bundle install` to install the gems
        - ✓ Create `config/initializers/omniauth.rb` with dynamic setup for username-based authentication

    - ✓ **Add logic to parse user identifiers and fetch OIDC configurations**

        - ✓ Create helper methods in `app/helpers/federated_auth_helper.rb` to parse username@instance identifiers
        - ✓ Implement methods to fetch OIDC configuration and register dynamic clients

    - ✓ **Integrate federated login into the authentication flow**

        - ✓ Update the login view to include federated login form
        - ✓ Add routes in `config/routes.rb` for federated authentication
        - ✓ Create `app/controllers/federated_login_controller.rb` with username-aware authentication
        - ✓ Store client credentials in the session
        - ✓ Redirect to `/auth/dynamic` for OmniAuth authentication
        - ✓ Handle the OmniAuth callback with proper username handling:
            - ✓ Added `enable :omniauth` to `rodauth_main.rb`
            - ✓ Created federated account handling that preserves usernames
            - ✓ Added database fields for federated authentication (provider, provider_uid, federated_id)

**Implementation Notes:**

- ✓ The system properly handles usernames instead of emails
- ✓ Federated identifiers use the format `username@instance.com`
- ✓ Local usernames are created as `username@instance.com` for federated users
- ✓ Added proper database indexes for efficient federated user lookups
- ✓ Implemented comprehensive error handling and logging
- ✓ Used gitlab-omniauth-openid-connect for better Ruby 3.4 compatibility
