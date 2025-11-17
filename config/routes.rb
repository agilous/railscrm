Rails.application.routes.draw do
  devise_for :users

  devise_scope :user do
    match "logout" => "devise/sessions#destroy", as: "logout", via: [ :get, :delete ]
    match "login" => "devise/sessions#new", as: "login", via: [ :get, :post ]
    match "signup" => "devise/registrations#new", as: "signup", via: [ :get, :post ]
    match "dashboard" => "users#dashboard", as: "dashboard", via: :get
    match "admin" => "users#index", as: "admin", via: :get
  end

  # Web-to-Lead functionality
  match "web_to_lead" => "leads#new_web_lead", as: "web_to_lead", via: :get
  match "create_lead" => "leads#create_web_lead", as: "create_lead", via: :post
  match "generate" => "leads#external_form", via: [ :get, :post ]

  # Resource routes
  resources :leads do
    resources :notes
    member do
      get :convert
    end
  end

  resources :users do
    member do
      get :approve
    end
  end

  resources :tasks

  resources :contacts do
    resources :notes
    resources :activities
  end

  resources :accounts
  resources :opportunities
  resources :notes, only: [ :create ]

  # Health check and PWA routes
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root to: "pages#index"
end
