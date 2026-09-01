Rails.application.routes.draw do
  devise_for :users, path: "auth", skip: [ :registrations ]
  resources :users do
    member do
      patch :lock
      patch :unlock
      post :resend_invitation
      post :impersonate
    end
  end
  post "stop_impersonating", to: "users#stop_impersonating", as: :stop_impersonating
  resources :guards do
    member do
      post :close
      get  :pdf
      get  :preview
      post :confirm_pdf
    end
  end
  resources :guard_setups
  resources :priest_setups

  resources :services do
    member do
      get   :pdf
      post  :complete
      patch :move
    end
  end
  resources :health_facilities
  resources :churches
  resources :headquarters

  namespace :doc do
    resources :headquarters, only: %i[ index show ]
    resources :federacion, only: %i[ index ]
  end
  get "sedes", to: "doc/headquarters#index", as: :sedes
  get "sedes/:id", to: "doc/headquarters#show", as: :sede
  get "federacion", to: "doc/federacion#index", as: :federacion
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Mount Action Cable so Turbo Stream broadcasts can reach connected clients over WebSockets.
  mount ActionCable.server => "/cable"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
