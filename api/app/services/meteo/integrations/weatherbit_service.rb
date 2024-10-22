module Meteo
  module Integrations
    # Implements weather fetching from Weatherbit API.
    class WeatherbitService < BaseWeatherServiceInterface
      BASE_URL = "https://api.weatherbit.io/v2.0".freeze

      STATUS_MAPPING = {
        200..233 => "stormy",
        300..302 => "rainy",
        500..522 => "rainy",
        600..623 => "snowy",
        700..751 => "foggy",
        800..800 => "clear",
        801..803 => "partly_cloudy",
        804..804 => "cloudy"
      }.freeze

      # Initializes the WeatherbitService.
      # @param lat [Float] the latitude for the weather query.
      # @param lon [Float] the longitude for the weather query.
      # @param request_handler [RequestHandler] the request handler for making requests.
      def initialize(lat, lon, request_handler)
        @lat = lat
        @lon = lon
        @request_handler = request_handler
        @api_key = ENV["WEATHERBIT_API_KEY"]
      end

      # Fetches current weather for given latitude and longitude.
      # @return [Hash] current weather data containing temperature, description, latitude, and longitude.
      def fetch_current_weather
        uri = URI("#{BASE_URL}/current")
        params = {
          lat: @lat,
          lon: @lon,
          key: @api_key,
          units: "M"
        }

        response = @request_handler.make_request(uri, params: params)
        parse_weather_response(response)
      end

      # Fetches 7-day weather forecast for given latitude and longitude.
      # @return [Array<Hash>] 7-day weather forecast data, each containing date, temperature, and description.
      def fetch_7_day_forecast
        uri = URI("#{BASE_URL}/forecast/daily")
        params = {
          lat: @lat,
          lon: @lon,
          days: 7,
          key: @api_key,
          units: "M"
        }

        response = @request_handler.make_request(uri, params: params)
        parse_forecast_response(response)
      end

      private

      # Parses the response for current weather data.
      # @param response [Net::HTTPResponse] the response object from the HTTP request.
      # @return [Hash] parsed current weather data containing temperature, description, latitude, and longitude.
      def parse_weather_response(response)
        begin
          data = JSON.parse(response.body)
          {
            temperature: data.dig("data", 0, "temp"),
            feels_like: data.dig("data", 0, "app_temp"),
            status: map_status(data.dig("data", 0, "weather", "code")),
            humidity: data.dig("data", 0, "rh"),
            wind_speed: data.dig("data", 0, "wind_spd"),
            date: Date.parse(data.dig("data", 0, "datetime")),
            max_temp: data.dig("data", 0, "max_temp"),
            min_temp: data.dig("data", 0, "min_temp")
          }
        rescue JSON::ParserError => e
          raise "Failed to parse weather response: #{e.message}"
        end
      end

      # Parses the response for 7-day weather forecast.
      # @param response [Net::HTTPResponse] the response object from the HTTP request.
      # @return [Array<Hash>] parsed 7-day weather forecast data, each containing date, temperature, and description.
      def parse_forecast_response(response)
        begin
          data = JSON.parse(response.body)
          data["data"].map do |day|
            {
              date: Date.parse(day["datetime"]),
              temperature: day["temp"],
              feels_like: day["app_max_temp"],
              status: map_status(day.dig("weather", "code")),
              humidity: day["rh"],
              wind_speed: day["wind_spd"],
              max_temp: day["max_temp"],
              min_temp: day["min_temp"]
            }
          end
        rescue JSON::ParserError => ex
          raise "Failed to parse forecast response: #{ex.message}"
        end
      end

      # Maps the status description to a unified status.
      # @param code [Integer] the weather code from the API response.
      # @return [String] the mapped status.
      def map_status(code)
        STATUS_MAPPING.each do |range, status|
          return status if range.include?(code)
        end
        "unknown"
      end
    end
  end
end
