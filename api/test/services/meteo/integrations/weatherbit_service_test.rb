require "test_helper"

class Meteo::Integrations::WeatherbitServiceTest < ActiveSupport::TestCase
  def setup
    @lat = 40.7128
    @lon = -74.0060
    @request_handler = mock()
    @response = mock()
  end

  def test_fetch_current_weather
    current_weather_data = {
      "data" => [ {
        "temp" => 22.5,
        "app_temp" => 23.0,
        "weather" => { "code" => 800 },
        "rh" => 75,
        "wind_spd" => 4.5,
        "datetime" => Time.now.to_s,
        "max_temp" => 28.0,
        "min_temp" => 18.0
      } ]
    }
    @response.stubs(:body).returns(current_weather_data.to_json)
    @request_handler.stubs(:make_request).returns(@response)

    weatherbit_service = Meteo::Integrations::WeatherbitService.new(@lat, @lon, @request_handler)
    result = weatherbit_service.fetch_current_weather

    assert_equal 22.5, result[:temperature]
    assert_equal 23.0, result[:feels_like]
    assert_equal "clear", result[:status]
    assert_equal 75, result[:humidity]
    assert_equal 4.5, result[:wind_speed]
    assert_instance_of Date, result[:date]
    assert_equal 28.0, result[:max_temp]
    assert_equal 18.0, result[:min_temp]
  end

  def test_fetch_7_day_forecast
    forecast_data = {
      "data" => [
        {
          "datetime" => Time.now.to_s,
          "temp" => 24.0,
          "app_max_temp" => 25.0,
          "weather" => { "code" => 801 },
          "rh" => 65,
          "wind_spd" => 4.0,
          "max_temp" => 29.0,
          "min_temp" => 19.0
        },
        {
          "datetime" => (Time.now + 86400).to_s,
          "temp" => 50.0,
          "app_max_temp" => 55.0,
          "weather" => { "code" => 299 },
          "rh" => 20,
          "wind_spd" => 2.0,
          "max_temp" => 55.0,
          "min_temp" => 45.0
        }
      ]
    }
    @response.stubs(:body).returns(forecast_data.to_json)
    @request_handler.stubs(:make_request).returns(@response)

    weatherbit_service = Meteo::Integrations::WeatherbitService.new(@lat, @lon, @request_handler)
    result = weatherbit_service.fetch_7_day_forecast

    assert_equal 24.0, result[0][:temperature]
    assert_equal 25.0, result[0][:feels_like]
    assert_equal "partly_cloudy", result[0][:status]
    assert_equal 65, result[0][:humidity]
    assert_equal 4.0, result[0][:wind_speed]
    assert_instance_of Date, result[0][:date]
    assert_equal 29.0, result[0][:max_temp]
    assert_equal 19.0, result[0][:min_temp]

    assert_equal 50.0, result[1][:temperature]
    assert_equal 55.0, result[1][:feels_like]
    assert_equal "unknown", result[1][:status]
    assert_equal 20, result[1][:humidity]
    assert_equal 2.0, result[1][:wind_speed]
    assert_instance_of Date, result[1][:date]
    assert_equal 55.0, result[1][:max_temp]
    assert_equal 45.0, result[1][:min_temp]
  end
end
