require "test_helper"

class Meteo::BaseWeatherServiceTest < ActiveSupport::TestCase
  include RedisTestHelper

  def setup
    setup_redis
    @weather_service = Meteo::BaseWeatherService.new(40.1234, -74.0000, redis_pool, "base_prefix", 1800)
    @weather_data = { "dummy" => "DATA" }
    @weather_service.stubs(:fetch_weather_data_with).returns(@weather_data)
    @prepared_result = [ [ @weather_data ] ]
    @weather_service.stubs(:prepare_result).with(@weather_data).returns(@prepared_result)
  end

  def teardown
    teardown_redis
  end

  def test_fetch_from_cache_hit
    cached_data = @weather_data.to_json
    redis_pool.with { |redis| redis.set(@weather_service.send(:cache_key), cached_data) }

    result = @weather_service.send(:fetch_from_cache)
    assert result.cache_hit
    assert_equal @prepared_result, result.data
  end

  def test_fetch_from_cache_miss
    redis_pool.with { |redis| redis.del(@weather_service.send(:cache_key)) }
    result = @weather_service.send(:fetch_from_cache)
    assert_not result.cache_hit
  end

  def test_fetch_from_service
    result = @weather_service.send(:fetch_from_service)
    cached_data = redis_pool.with { |redis| redis.get(@weather_service.send(:cache_key)) }
    assert_equal @prepared_result, result.data
    assert_equal @weather_data.to_json, cached_data
  end

  def test_fetch_service_failure_fallback
    @weather_service.expects(:fetch_weather_data_with).raises(StandardError.new("Service failed")).times(2)
    @weather_service.expects(:handle_service_failure).twice
    result = @weather_service.send(:fetch_from_service)
    assert_nil result.data
    assert_equal "Service failed", result.error
  end
end
