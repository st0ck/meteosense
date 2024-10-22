module Meteo
  # Handles the process of fetching current weather.
  class CurrentWeatherService < BaseWeatherService
    CACHE_EXPIRATION = 30.minutes
    CACHE_PREFIX = "current_weather".freeze

    def initialize(lat, lon, redis_pool)
      super(lat, lon, redis_pool, CACHE_PREFIX, CACHE_EXPIRATION)
    end

    private

    # Prepares the result data for current weather.
    # @param data [Hash] the raw current weather data.
    # @return [Meteo::Weather] the prepared weather data.
    def prepare_result(data)
      Meteo::Weather.new(data)
    end

    # Fetches current weather data with the given service.
    # @param service [Object] the weather service to use for fetching current weather.
    # @return [Hash] the current weather data.
    def fetch_weather_data_with(service)
      service.fetch_current_weather
    end
  end
end
