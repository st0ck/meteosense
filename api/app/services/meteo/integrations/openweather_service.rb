module Meteo
  module Integrations
    # Implements weather fetching from OpenWeather API.
    class OpenweatherService < BaseWeatherServiceInterface
      BASE_URL = "https://api.openweathermap.org/data/2.5".freeze

      STATUS_MAPPING = {
        "01d" => "clear",
        "02d" => "partly_cloudy",
        "03d" => "cloudy",
        "04d" => "cloudy",
        "09d" => "rainy",
        "10d" => "rainy",
        "11d" => "stormy",
        "13d" => "snowy",
        "50d" => "foggy",
        "01n" => "clear",
        "02n" => "partly_cloudy",
        "03n" => "cloudy",
        "04n" => "cloudy",
        "09n" => "rainy",
        "10n" => "rainy",
        "11n" => "stormy",
        "13n" => "snowy",
        "50n" => "foggy"
      }.freeze

      # Initializes the OpenweatherService.
      # @param lat [Float] the latitude for the weather query.
      # @param lon [Float] the longitude for the weather query.
      # @param request_handler [RequestHandler] the request handler for making requests.
      def initialize(lat, lon, request_handler)
        @lat = lat
        @lon = lon
        @request_handler = request_handler
        @api_key = ENV["OPENWEATHER_API_KEY"]
      end

      # Fetches current weather for given latitude and longitude.
      # @return [Hash] current weather data containing temperature, description, latitude, and longitude.
      def fetch_current_weather
        uri = URI("#{BASE_URL}/weather")
        params = {
          lat: @lat,
          lon: @lon,
          appid: @api_key,
          units: "metric"
        }

        response = @request_handler.make_request(uri, params: params)
        parse_weather_response(response)
      end

      # Fetches 7-day weather forecast for given latitude and longitude.
      # @return [Array<Hash>] 7-day weather forecast data, each containing date, temperature, and description.
      def fetch_7_day_forecast
        uri = URI("#{BASE_URL}/onecall")
        params = {
          lat: @lat,
          lon: @lon,
          exclude: "current,minutely,hourly,alerts",
          appid: @api_key,
          units: "metric"
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
            temperature: data.dig("main", "temp"),
            feels_like: data.dig("main", "feels_like"),
            status: map_status(data.dig("weather", 0, "icon")),
            humidity: data.dig("main", "humidity"),
            wind_speed: data.dig("wind", "speed"),
            date: Time.at(data["dt"]).to_date,
            max_temp: data.dig("main", "temp_max"),
            min_temp: data.dig("main", "temp_min")
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
          data["daily"].map do |day|
            {
              date: Time.at(day["dt"]).to_date,
              temperature: day.dig("temp", "day"),
              feels_like: day.dig("feels_like", "day"),
              status: map_status(day.dig("weather", 0, "icon")),
              humidity: day["humidity"],
              wind_speed: day["wind_speed"],
              max_temp: day.dig("temp", "max"),
              min_temp: day.dig("temp", "min")
            }
          end
        rescue JSON::ParserError => e
          raise "Failed to parse forecast response: #{e.message}"
        end
      end

      # Maps the status description to a unified status.
      # @param description [String] the description from the API response.
      # @return [String] the mapped status.
      def map_status(description)
        STATUS_MAPPING[description] || "unknown"
      end
    end
  end
end
