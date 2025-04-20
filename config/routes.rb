# frozen_string_literal: true

Rails.application.routes.draw do
  resources :search_new, only: [ :index ]
  get "search_new/index"
  get "search" => "search#index"
  post "search" => "search#create"
  root "homepage#index"
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

  # Legacy JSON API routes (commented out, replaced by XML-RPC)
  # namespace :api do
  #   get "preferences/is_dismissed", to: "preferences#is_dismissed"
  #   post "preferences/dismiss", to: "preferences#dismiss"
  # end

  # Routes available only if authenticated via Rodauth
  constraints Rodauth::Rails.authenticate do
    get "dashboard", to: "dashboard#index"
    resources :experiences do
      member do
        get "display"
      end
    end
    # Account actions (export & delete)
    get "account/export", to: "account_actions#export", as: :account_export
    delete "account", to: "account_actions#destroy", as: :account_destroy
  end
end
