# frozen_string_literal: true

Rails.application.routes.draw do
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

  # Authentication routes (/login, /create-account, etc.) are automatically handled by Rodauth
  # See app/misc/rodauth_app.rb and run `rails rodauth:routes` to view all available routes

  # XML-RPC API endpoint
  namespace :api do
    post "xmlrpc", to: "xmlrpc#endpoint"
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
    resources :experiences, only: [ :index ] do
      member do
        patch :approve # Route for PATCH /admin/experiences/:id/approve
      end
    end

    # Redirect base /admin path to experiences index for now
    root to: "experiences#index"
  end

  get ".well-known/security.txt", to: "well_known#security_txt", format: false
  get ".well-known/privacy.txt", to: "well_known#privacy_txt", format: false

  # Consent routes using Turbo Streams
  get  "consent/screen", to: "consent#screen", as: :consent_screen
  post "consent/accept", to: "consent#accept"
  post "consent/decline", to: "consent#decline"

  # Policies (Privacy & Cookies)
  get "privacy", to: "policies#privacy", as: :privacy_policy
  get "cookies", to: "policies#cookies", as: :cookie_policy
end
