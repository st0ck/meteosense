module Meteo
  # Handles the process of fetching 7-day forecast.
  class DailyForecastService < BaseWeatherService
    CACHE_EXPIRATION = 6.hours
    CACHE_PREFIX = "daily_forecast".freeze

    def initialize(lat, lon, redis_pool)
      super(lat, lon, redis_pool, CACHE_PREFIX, CACHE_EXPIRATION)
    end

    private

    # Prepares the result data for 7-day forecast.
    # @param data [Hash] the raw forecast data.
    # @return [Meteo::Weather] the prepared forecast data.
    def prepare_result(data)
      data.map { |weather| Meteo::Weather.new(weather) }
    end

    # Fetches 7-day forecast data with the given service.
    # @param service [Object] the weather service to use for fetching 7-day forecast.
    # @return [Hash] the forecast data.
    def fetch_weather_data_with(service)
      service.fetch_7_day_forecast
    end
  end
end
