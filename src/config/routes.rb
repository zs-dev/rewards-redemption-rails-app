Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get '/rewards', to: 'rewards#index', as: 'rewards_index'
  get '/rewards/:id', to: 'rewards#show', as: 'rewards_show'
  get '/users/:id/balance', to: 'users#balance', as: 'user_balance'
  post '/redeem', to: 'redemptions#redeem', as: 'redeem_redemption'
  get '/users/:user_id/redemptions/history', to: 'redemptions#history', as: 'redemptions_history'
  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
