require "test_helper"

class Meteo::DailyForecastServiceTest < ActiveSupport::TestCase
  include RedisTestHelper

  def setup
    setup_redis
    @lat = 40.7128
    @lon = -74.0060
    @daily_forecast_service = Meteo::DailyForecastService.new(@lat, @lon, redis_pool)
    @data = [
      {
        "temperature" => 20.0,
        "feels_like" => 21.0,
        "status" => "Rainy",
        "humidity" => 70,
        "wind_speed" => 15.0,
        "date" => "2024-10-19",
        "max_temp" => 22.0,
        "min_temp" => 18.0
      },
      {
        "temperature" => 22.0,
        "feels_like" => 23.0,
        "status" => "Clear",
        "humidity" => 55,
        "wind_speed" => 8.0,
        "date" => "2024-10-20",
        "max_temp" => 25.0,
        "min_temp" => 19.0
      }
    ]
  end

  def test_prepare_result_with_valid_data
    expected_weather_objects = @data.map { |data| Meteo::Weather.new(data) }
    result = @daily_forecast_service.send(:prepare_result, @data)
    assert_equal expected_weather_objects, result
  end

  def test_prepare_result_with_empty_data_returns_empty_array
    result = @daily_forecast_service.send(:prepare_result, [])
    assert_equal [], result
  end

  def test_fetch_weather_data_with_service
    service = mock("service")
    service.expects(:fetch_7_day_forecast).returns(@data)
    result = @daily_forecast_service.send(:fetch_weather_data_with, service)
    assert_equal @data, result
  end
end
