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
    end
  end
  resources :guard_setups
  resources :priest_setups, only: %i[create destroy]
  resources :priest_assignments, only: %i[index]
  resources :services do
    member do
      get  :pdf
      post :complete
    end
  end
  resources :health_facilities
  resources :churches
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
