module Meteo
  module Integrations
    # Abstract base class for weather services, enforcing implementation of the fetch methods.
    class BaseWeatherServiceInterface
      # Abstract method for fetching current weather.
      # @return [Weather] the current weather data.
      def fetch_current_weather
        raise NotImplementedError, "The fetch_current_weather method must be implemented in subclasses"
      end

      # Abstract method for fetching 7-day weather forecast.
      # @return [Array<Weather>] the 7-day forecast data.
      def fetch_7_day_forecast
        raise NotImplementedError, "The fetch_7_day_forecast method must be implemented in subclasses"
      end
    end
  end
end
