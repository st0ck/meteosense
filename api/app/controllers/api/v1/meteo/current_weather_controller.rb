module Api
  module V1
    module Meteo
      # Handles requests for fetching the current weather for a given geolocation.
      class CurrentWeatherController < ApplicationController
        # Handles the request to get the weather for the specified geolocation and date.
        def create
          with_error_handling do
            return handle_general_error(error: geolocation.errors.to_message) unless geolocation.valid?

            service = ::Meteo::CurrentWeatherService.new(
              search_params[:lat],
              search_params[:lon],
              Rails.application.config.redis_pool
            )

            weather = service.fetch

            response.set_header("X-Cache-Hit", weather.cache_hit ? "true" : "false")
            response.set_header("X-Cache-Age", weather.cache_age.to_s) if weather.cache_hit

            if weather.data.nil? || weather.error
              handle_general_error(error: weather.error || "Service unavailable", status_code: :internal_server_error)
            else
              handle_success_response(data: weather.data)
            end
          end
        end

        private

        def geolocation
          @geolocation = Geo::Location.new(lat: search_params[:lat], lon: search_params[:lon])
        end

        def search_params
          params.require(:current_weather).permit(:lat, :lon)
        end
      end
    end
  end
end
