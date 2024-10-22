require "test_helper"

class Meteo::CurrentWeatherServiceTest < ActiveSupport::TestCase
  include RedisTestHelper

  def setup
    setup_redis
    @current_weather_service = Meteo::CurrentWeatherService.new(40.1234, -74.0000, redis_pool)
  end

  def teardown
    teardown_redis
  end

  def test_prepare_result_with_valid_data
    raw_data = {
      "temperature" => 23.5,
      "feels_like" => 25.0,
      "status" => "Sunny",
      "humidity" => 60,
      "wind_speed" => 10.0,
      "date" => "2024-10-19",
      "max_temp" => 28.0,
      "min_temp" => 18.0
    }
    expected_weather = Meteo::Weather.new(raw_data)
    result = @current_weather_service.send(:prepare_result, raw_data)
    assert_equal expected_weather, result
  end

  def test_fetch_weather_data_with_service
    service = mock("service")
    data = {
      "temperature" => 24.0,
      "feels_like" => 25.5,
      "status" => "Partly Cloudy",
      "humidity" => 58,
      "wind_speed" => 9.0,
      "date" => "2024-10-19",
      "max_temp" => 27.0,
      "min_temp" => 20.0
    }
    service.expects(:fetch_current_weather).with(any_parameters).returns(data)
    result = @current_weather_service.send(:fetch_weather_data_with, service)
    assert_equal(data, result)
  end

  def test_fetch_weather_data_with_service_failure_raises_standard_error
    service = mock("service")
    service.expects(:fetch_current_weather).raises(StandardError.new("Service failed"))
    assert_raises(StandardError) do
      @current_weather_service.send(:fetch_weather_data_with, service)
    end
  end
end
