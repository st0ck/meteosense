Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "api/v1/up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      namespace :address do
        resources :search, only: %i[index]
      end

      namespace :meteo do
        resources :current_weather, only: %i[create]
        resources :daily_weather_forecast, only: %i[create]
      end
    end
  end
end
