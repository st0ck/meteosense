require "test_helper"

class AddressLookupServiceTest < ActiveSupport::TestCase
  include RedisTestHelper

  def setup
    setup_redis
    @mock_request_handler = mock("RequestHandler")

    RequestHandler.stubs(:new).returns(@mock_request_handler)
    Geo::Integrations::MapboxService.any_instance.stubs(:fetch).with(any_parameters).returns([ address.to_h ])
    Geo::Integrations::HereMapsService.any_instance.stubs(:fetch).with(any_parameters).returns([ address.to_h ])

    @query = "825 Milwaukee Ave"
    @options = { session_id: "test-session-id" }

    @lookup_service = Geo::AddressLookupService.new
    @services = @lookup_service.send(:services).map(&:class)
    @unavailable_service_keys = @services.map do |klass|
      name = klass.to_s
      @lookup_service.send(:unavailable_key, name)
    end
    @search_cache_key = @lookup_service.send(:cache_key, @query)
    @fetched_data = [ address.to_h.stringify_keys ]
  end

  def teardown
    teardown_redis
  end

  def address
    @address ||= Geo::Address.new(
      name: "825 Milwaukee Ave, Glenview, IL 60025-3715, United States",
      address: "825 Milwaukee Ave, Glenview, IL 60025-3715, United States",
      latitude: 42.07103,
      longitude: -87.85347,
      country: "United States",
      city: "Glenview",
      postcode: "60025-3715"
    )
  end

  def test_search_returns_cached_results
    cached_results = @fetched_data
    Redis.any_instance.stubs(:get).with(@search_cache_key).returns(cached_results.to_json)

    results = @lookup_service.search(query: @query, options: @options)
    assert_equal cached_results, results
  end

  def test_search_calls_first_service_if_no_cache
    @services.first.any_instance.stubs(:fetch).returns(@fetched_data)

    results = @lookup_service.search(query: @query, options: @options)
    assert_equal @fetched_data.count, results.count
    assert_same_elements @fetched_data, results
  end

  def test_caches_successful_service_fetch
    @services.first.any_instance.stubs(:fetch).returns(@fetched_data)

    redis_pool.with do |redis|
      assert_not redis.get(@search_cache_key)
      results = @lookup_service.search(query: @query, options: @options)
      assert redis.get(@search_cache_key)
    end
  end

  def test_does_not_set_unavailable_service_key_if_services_work
    @services.first.any_instance.stubs(:fetch).returns(@fetched_data)

    results = @lookup_service.search(query: @query, options: @options)
    redis_pool.with do |redis|
      @unavailable_service_keys.each do |service_key|
        assert_not redis.get(service_key)
      end
    end
  end

  def test_fallback_to_next_service_on_first_service_failure
    @services.first.any_instance.stubs(:fetch).raises(StandardError, "Service failure")
    @services[1].any_instance.stubs(:fetch).returns(@fetched_data)

    results = @lookup_service.search(query: @query, options: @options)
    assert_equal @fetched_data.count, results.count
    assert_same_elements @fetched_data, results
  end

  def test_no_results_if_all_services_fail
    @services.map do |service_class|
      service_class.any_instance.stubs(:fetch).raises(StandardError, "Service failure")
    end

    results = @lookup_service.search(query: @query, options: @options)
    assert_empty results
  end

  def test_set_unavailable_service_key_if_failed_services
    @services.map do |service_class|
      service_class.any_instance.stubs(:fetch).raises(StandardError, "Service failure")
    end

    results = @lookup_service.search(query: @query, options: @options)
    redis_pool.with do |redis|
      @unavailable_service_keys.each do |unavailable_service_key|
        assert redis.get(unavailable_service_key)
        assert redis.ttl(unavailable_service_key) <= 5.minutes.to_i
      end
    end
  end
end
