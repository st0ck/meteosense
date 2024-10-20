require "test_helper"

class Meteo::Integrations::OpenweatherServiceTest < ActiveSupport::TestCase
  def setup
    @lat = 40.7128
    @lon = -74.0060
    @request_handler = mock()
    @response = mock()
  end

  def test_fetch_current_weather
    current_weather_data = {
      "main" => {
        "temp" => 25.5,
        "feels_like" => 27.0,
        "temp_max" => 30.0,
        "temp_min" => 20.0,
        "humidity" => 80
      },
      "weather" => [ { "icon" => "01d" } ],
      "wind" => { "speed" => 5.5 },
      "dt" => Time.now.to_i
    }
    @response.stubs(:body).returns(current_weather_data.to_json)
    @request_handler.stubs(:make_request).returns(@response)

    openweather_service = Meteo::Integrations::OpenweatherService.new(@lat, @lon, @request_handler)
    result = openweather_service.fetch_current_weather

    assert_equal 25.5, result[:temperature]
    assert_equal 27.0, result[:feels_like]
    assert_equal "clear", result[:status]
    assert_equal 80, result[:humidity]
    assert_equal 5.5, result[:wind_speed]
    assert_instance_of Date, result[:date]
    assert_equal 30.0, result[:max_temp]
    assert_equal 20.0, result[:min_temp]
  end

  def test_fetch_7_day_forecast
    forecast_data = {
      "daily" => [
        {
          "dt" => Time.now.to_i,
          "temp" => { "day" => 25.0, "min" => 20.0, "max" => 30.0 },
          "feels_like" => { "day" => 26.0 },
          "weather" => [ { "icon" => "03d" } ],
          "humidity" => 70,
          "wind_speed" => 5.0
        },
        {
          "dt" => Time.now.to_i + 86400,
          "temp" => { "day" => -15.0, "min" => -20.0, "max" => -10.0 },
          "feels_like" => { "day" => -18.0 },
          "weather" => [ { "icon" => "13d" } ],
          "humidity" => 90,
          "wind_speed" => 20.0
        }
      ]
    }
    @response.stubs(:body).returns(forecast_data.to_json)
    @request_handler.stubs(:make_request).returns(@response)

    openweather_service = Meteo::Integrations::OpenweatherService.new(@lat, @lon, @request_handler)
    result = openweather_service.fetch_7_day_forecast

    assert_equal 25.0, result[0][:temperature]
    assert_equal 26.0, result[0][:feels_like]
    assert_equal "cloudy", result[0][:status]
    assert_equal 70, result[0][:humidity]
    assert_equal 5.0, result[0][:wind_speed]
    assert_instance_of Date, result[0][:date]
    assert_equal 30.0, result[0][:max_temp]
    assert_equal 20.0, result[0][:min_temp]

    assert_equal -15.0, result[1][:temperature]
    assert_equal -18.0, result[1][:feels_like]
    assert_equal "snowy", result[1][:status]
    assert_equal 90, result[1][:humidity]
    assert_equal 20.0, result[1][:wind_speed]
    assert_instance_of Date, result[1][:date]
    assert_equal -10.0, result[1][:max_temp]
    assert_equal -20.0, result[1][:min_temp]
  end
end
