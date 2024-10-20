module Geo
  # Manages the process of looking up addresses using different geosearch services.
  # It caches results to optimize repeated searches and reduce API calls.
  # Uses Mapbox by default and falls back to HERE Maps if errors occur.
  class AddressLookupService
    CACHE_PREFIX = "geo:address_lookup".freeze

    attr_reader :error

    def initialize(redis_pool = Rails.application.config.redis_pool)
      @error = nil
      @redis_pool = redis_pool
    end

    # Searches for addresses based on the given query and options.
    # @param query [String] the partial address to search for.
    # @param options [Hash] options that include session_id.
    # @return [Array<Address>] the list of found addresses.
    def search(query:, options:)
      @session_id = options[:session_id]

      cached_results = search_cache(query)
      return cached_results if cached_results.present?

      perform_search(query)
    end

    private

    # Searches the cache for previously queried addresses.
    # @param query [String] the partial address to search for.
    # @return [Array<Address>, nil] cached addresses or nil if not found.
    def search_cache(query)
      cache_key_with_session = cache_key(query)
      cached_value = @redis_pool.with do |redis|
        redis.get(cache_key_with_session)
      end
      return JSON.parse(cached_value) if cached_value.present?

      nil
    end

    # Caches the results of the address search.
    # @param query [String] the partial address that was searched for.
    # @param results [Array<Address>] the results to be cached.
    def cache_results(query, results)
      cache_key_with_session = cache_key(query)
      @redis_pool.with do |redis|
        redis.set(cache_key_with_session, results.to_json, ex: 5.minutes)
      end
    end

    # Generates a cache key for the given query.
    # @param query [String] the partial address.
    # @return [String] the cache key.
    def cache_key(query)
      "#{CACHE_PREFIX}:#{Digest::SHA256.hexdigest(query)}"
    end

    # Builds the unavailable key for a given service name.
    # @param service_name [String] the service name.
    # @return [String] the unavailable key for Redis.
    def unavailable_key(service_name)
      "#{CACHE_PREFIX}:#{service_name}_unavailable"
    end

    # Handles failure of the service by setting a flag in Redis.
    def handle_service_failure(service_name)
      @redis_pool.with do |redis|
        redis.set(unavailable_key(service_name), true, ex: 5.minutes)
      end
    end

    # Performs the search with fallback mechanism for multiple services.
    # @param query [String] the partial address to search for.
    # @return [Array<Address>, nil] the list of found addresses.
    def perform_search(query)
      execute_with_fallback(services) do |service|
        results = service.fetch(query)

        if results.any?
          cache_results(query, results)
          results
        end
      end
    end

    # Executes the given block with each service until one succeeds, implementing a fallback mechanism.
    # Tracks service availablility statuses.
    # @param services [Enumerator] an enumerator of services to attempt.
    # @yield [service] the current service to be executed.
    # @return [Hash] the result of the successful service call or an empty hash if all services fail.
    def execute_with_fallback(services)
      services.each do |service|
        service_key = service.class.to_s

        unavailable_service = @redis_pool.with do |redis|
          redis.get(unavailable_key(service_key)).present?
        end

        next if unavailable_service

        begin
          return yield service
        rescue StandardError
          handle_service_failure(service_key)
        end
      end
      []
    end

    # Provides an enumerator for available geospatial services lazily initializing them.
    # @return [Enumerator] an enumerator for the geospatial services.
    def services
      request_handler = RequestHandler.new

      Enumerator.new do |yielder|
        yielder << Geo::Integrations::MapboxService.new(request_handler, @session_id)
        yielder << Geo::Integrations::HereMapsService.new(request_handler)
      end
    end
  end
end
