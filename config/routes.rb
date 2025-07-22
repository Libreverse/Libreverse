# frozen_string_literal: true

Rails.application.routes.draw do
  post "/graphql", to: "graphql#execute"
  resources :search_new, only: [ :index ]
  get "search_new/index"
  get "search" => "search#index"
  post "search" => "search#create"
  root "homepage#index"
  get "terms", to: "terms#index"
  get "settings", to: "settings#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Mount ActionCable for real-time features
  mount ActionCable.server => "/cable"

  # Analytics proxy routes for privacy-focused tracking
  get "umami/script.js", to: "proxy#umami_script"

  # Mount Action Mailbox for email bot functionality
  mount ActionMailbox::Engine => "/rails/action_mailbox"

  # Authentication routes (/login, /create-account, etc.) are automatically handled by Rodauth
  # See app/misc/rodauth_app.rb and run `rails rodauth:routes` to view all available routes

  # Federated authentication routes
  get "/federated-login", to: "federated_login#new"
  post "/federated-login", to: "federated_login#create"
  get "/auth/federated/callback", to: "federated_login#callback"
  get "/auth/failure", to: "federated_login#failure"

  # XML-RPC API endpoint
  namespace :api do
    post "xmlrpc", to: "xmlrpc#endpoint"
    post "grpc", to: "grpc#endpoint"
    get "json/:method", to: "json#endpoint"
    post "json/:method", to: "json#endpoint"
    post "json", to: "json#endpoint" # For method specified in body
  end

  # Routes available only if authenticated via Rodauth
  constraints Rodauth::Rails.authenticate do
    get "dashboard", to: "dashboard#index"
    resources :experiences do
      member do
        get "display"
        patch "approve"
      end
    end
    # Account actions (export & delete)
    get "account/export", to: "account_actions#export", as: :account_export
    delete "account", to: "account_actions#destroy", as: :account_destroy
  end

  # ===== Admin Namespace =====
  namespace :admin do
    # Dashboard
    resources :dashboard, only: [ :index ]
    root to: "dashboard#index"

    resources :experiences, only: [ :index ] do
      member do
        patch :approve # Route for PATCH /admin/experiences/:id/approve
      end
      collection do
        post :add_examples
        post :restore_examples
        delete :delete_examples
      end
    end

    # Instance settings management
    resources :instance_settings

    # Federation management
    get "federation", to: "federation#index"
    post "federation/block_domain", to: "federation#block_domain"
    delete "federation/unblock_domain/:domain", to: "federation#unblock_domain", as: :unblock_domain
    post "federation/generate_actors", to: "federation#generate_actors"
    get "federation/federated_experiences", to: "federation#federated_experiences"

    # Litestream management
    get "litestream", to: "litestream#index", as: "litestream_overview"
    get "litestream/databases", to: "litestream#databases"
    get "litestream/generations", to: "litestream#generations"
    get "litestream/snapshots", to: "litestream#snapshots"
    post "litestream/verify", to: "litestream#verify"

    # Mount Litestream dashboard (requires authentication)
    mount Litestream::Engine, at: "/litestream/dashboard"
  end

  get ".well-known/security.txt", to: "well_known#security_txt", format: false
  get ".well-known/privacy.txt", to: "well_known#privacy_txt", format: false
  get ".well-known/libreverse", to: "federation#libreverse_discovery", format: false
  get "robots.txt", to: "robots#show", format: false
  get "sitemap.xml", to: "sitemap#show", format: false

  # ActivityPub federation endpoints
  get "/api/activitypub/experiences", to: "federation#experiences_collection"
  get "/api/activitypub/search", to: "federation#search"
  post "/api/activitypub/announce", to: "federation#announce"
  post "/api/activitypub/announce", to: "federation#announce"

  # Consent routes using Turbo Streams
  get  "consent/screen", to: "consent#screen", as: :consent_screen
  post "consent/accept", to: "consent#accept"
  post "consent/decline", to: "consent#decline"

  # Policies (Privacy & Cookies)
  get "privacy", to: "policies#privacy", as: :privacy_policy
  get "cookies", to: "policies#cookies", as: :cookie_policy

  # Mount Federails engine at root for ActivityPub federation
  mount Federails::Engine => "/"
end
