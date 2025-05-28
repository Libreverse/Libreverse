# Todo List

1. □ **Fix bugged search**
2. □ **Imprint for EU**
3. □ **Make `Security.txt` and `.well-known/privacy.txt` dynamic with instance data**
4. □ **Implement Voight-Kampff bot detection**
5. □ **Make moderation system configurable**
6. □ **Add sitemap_generator for automatic sitemaps**
7. □ **Add invisible_captcha for signup protection**
8. □ **Add experience federation through custom activitypub fields**
9. □ **Implement federated authentication for metaverse instances**

    - □ **Set up each instance as an OIDC provider using `rodauth-oauth`**
        - □ Add `gem 'rodauth-oauth'` to the Gemfile
        - □ Run `bundle install` to install the gem
        - □ In `app/models/rodauth_main.rb`, configure Rodauth with:
            - `enable :oidc`
            - `oidc_issuer "https://#{Rails.application.config.x.instance_domain}"`
            - `oauth_application_scopes %w[openid profile email]`
        - □ Set the instance domain in `config/application.rb`:
            - `config.x.instance_domain = ENV['INSTANCE_DOMAIN'] || 'default_domain.com'`
        - □ Generate and run migrations for OIDC tables:
            - `rails g rodauth:oauth:install`
            - `rails db:migrate`
        - □ Verify the discovery endpoint is accessible at `https://your_instance_domain/.well-known/openid-configuration`
    - □ **Implement OIDC client with `omniauth-openid-connect` for dynamic providers**

        - □ Add `gem 'omniauth-openid-connect'` and `gem 'httparty'` to the Gemfile
        - □ Run `bundle install` to install the gems
        - □ Create `config/initializers/omniauth.rb` with dynamic setup:

            ```ruby
            Rails.application.config.middleware.use OmniAuth::Builder do
              provider :openid_connect, name: :dynamic, setup: lambda { |env|
                strategy = env['omniauth.strategy']
                session = env['rack.session']
                strategy.options[:issuer] = "https://#{session[:oidc_domain]}"
                strategy.options[:discovery] = true
                strategy.options[:client_id] = session[:client_id]
                strategy.options[:client_secret] = session[:client_secret]
                strategy.options[:scope] = %w[openid profile email]
                strategy.options[:redirect_uri] = "#{Rails.application.config.x.instance_domain}/auth/dynamic/callback"
              }
            end
            ```

    - □ **Add logic to parse user identifiers and fetch OIDC configurations**

        - □ Create a method in a helper or controller to parse identifiers:

            ```ruby
            def parse_identifier(identifier)
              user, domain = identifier.split('@')
              return user, domain if domain
              nil
            end
            ```

        - □ Implement a method to fetch OIDC configuration:

            ```ruby
            def fetch_oidc_config(domain)
              response = HTTParty.get("https://#{domain}/.well-known/openid-configuration")
              JSON.parse(response.body) if response.success?
            rescue StandardError => e
              nil
            end
            ```

    - □ **Integrate federated login into the authentication flow**

        - □ Update the login view (e.g., `app/views/sessions/new.html.haml`) to include:

            ```haml
            = form_tag federated_login_path, method: :post do
              = text_field_tag :identifier, nil, placeholder: "user@instance.com"
              = submit_tag "Login with Federated ID"
            ```

        - □ Add a route in `config/routes.rb`:

            ```ruby
            post '/federated-login', to: 'federated_login#create'
            ```

        - □ Create `app/controllers/federated_login_controller.rb`:

            ```ruby
            class FederatedLoginController < ApplicationController
              def create
                identifier = params[:identifier]
                user, domain = parse_identifier(identifier)
                unless domain
                  flash[:error] = "Invalid identifier format"
                  return redirect_to login_path
                end
                config = fetch_oidc_config(domain)
                unless config
                  flash[:error] = "Unable to fetch OIDC configuration"
                  return redirect_to login_path
                end
                registration_endpoint = config['registration_endpoint']
                response = HTTParty.post(registration_endpoint, body: {
                  client_name: "YourApp",
                  redirect_uris: ["#{Rails.application.config.x.instance_domain}/auth/dynamic/callback"]
                }.to_json, headers: { 'Content-Type' => 'application/json' })
                if response.success?
                  client_data = JSON.parse(response.body)
                  session[:client_id] = client_data['client_id']
                  session[:client_secret] = client_data['client_secret']
                  session[:oidc_domain] = domain
                  redirect_to '/auth/dynamic'
                else
                  flash[:error] = "Client registration failed"
                  redirect_to login_path
                end
              end
            end
            ```

        - □ Store client credentials in the session (handled in the controller above)
        - □ Redirect to `/auth/dynamic` for OmniAuth authentication (handled in the controller above)
        - □ Handle the OmniAuth callback with Rodauth:
            - Ensure `enable :omniauth` is added to `rodauth_main.rb`
            - Configure Rodauth to process OmniAuth data and create or log in the user
