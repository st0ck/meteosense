module Meteo
  # Handles the process of fetching current weather and 7-day forecasts from multiple services.
  # Uses OpenWeatherService and WeatherbitService for data.
  class BaseWeatherService
    H3_RESOLUTION = 8
    SERVICE_UNAVAILABLE_TIMEOUT = 5.minutes

    attr_reader :error, :lat, :lon, :cache_prefix, :cache_expiration

    # Initializes the BaseWeatherService with Redis connection pool.
    # @param lat [Float] the latitude for the weather query.
    # @param lon [Float] the longitude for the weather query.
    # @param redis_pool [ConnectionPool] the Redis connection pool to be used for caching.
    # @param cache_prefix [String] the prefix to use for cache keys.
    # @param cache_expiration [Integer] the cache expiration time in seconds.
    def initialize(lat, lon, redis_pool, cache_prefix, cache_expiration)
      @error = nil
      @lat = lat
      @lon = lon
      @redis_pool = redis_pool
      @cache_prefix = cache_prefix
      @cache_expiration = cache_expiration
    end

    # Fetches current weather by the given latitude and longitude.
    # @return [BaseResult] the weather data.
    def fetch
      cached_weather_data = fetch_from_cache
      return cached_weather_data if cached_weather_data.cache_hit

      fetch_from_service
    end

    private

    # Prepares the result data.
    # @param data [Hash] the raw weather data.
    # @raise [NotImplementedError] if the method is not implemented in the subclass.
    def prepare_result(data)
      raise NotImplementedError, "The prepare_result method must be implemented in subclasses"
    end

    # Fetches weather data with the given service.
    # @param service [Object] the weather service to use for fetching data.
    # @raise [NotImplementedError] if the method is not implemented in the subclass.
    def fetch_weather_data_with(service)
      raise NotImplementedError, "The fetch_weather_data_with method must be implemented in subclasses"
    end

    # Fetches weather data from the cache if available.
    # @return [BaseResult] the cached weather data or nil if no cache is found.
    def fetch_from_cache
      cached_value = @redis_pool.with { |redis| redis.get(cache_key) }
      return BaseResult.new unless cached_value

      data = prepare_result(JSON.parse(cached_value))
      age = calculate_cache_age
      BaseResult.new(data: data, cache_hit: true, cache_age: age)
    end

    # Fetches weather data from the weather services and caches the result.
    # @return [BaseResult] the weather data.
    def fetch_from_service
      weather_data = fetch_weather_data

      if weather_data
        cache_results(weather_data)
        return BaseResult.new(data: prepare_result(weather_data))
      end

      BaseResult.new(error: error)
    end

    # Calculates the age of the cached data based on the TTL (Time-To-Live) of the cache key.
    # @return [Integer, NilClass] The age of the cached data in seconds, or nil if the TTL is not available
    #                             (e.g., the key has expired or does not exist).
    def calculate_cache_age
      ttl = @redis_pool.with { |redis| redis.ttl(cache_key) }
      ttl > 0 ? (@cache_expiration - ttl) : nil
    end

    # Caches the results of the weather query.
    # @param weather_data [Hash] the results to be cached.
    def cache_results(weather_data)
      @redis_pool.with do |redis|
        redis.set(cache_key, weather_data.to_json, ex: @cache_expiration)
      end
    end

    # Generates a cache key for the given latitude and longitude.
    # @return [String] the cache key.
    def cache_key
      @cache_key ||= "#{@cache_prefix}:#{H3.from_geo_coordinates([ lat, lon ], H3_RESOLUTION)}"
    end

    # Performs the weather data fetch with fallback mechanism for multiple services.
    # @return [Hash, nil] the weather data including current and forecasted information.
    def fetch_weather_data
      execute_with_fallback(services) do |service|
        fetch_weather_data_with(service)
      end
    end

    # Executes the given block with each service until one succeeds, implementing a fallback mechanism.
    # Tracks service availability statuses.
    # @param services [Enumerator] an enumerator of services to attempt.
    # @yield [service] the current service to be executed. Should return truthy value in case of success.
    # @return [Hash, nil] the result of the successful service call or an empty hash if all services fail.
    def execute_with_fallback(services)
      services.each do |service|
        service_class_name = service.class.to_s

        is_service_unavailable = @redis_pool.with do |redis|
          redis.get(unavailable_key(service_class_name)).present?
        end

        next if is_service_unavailable

        begin
          return yield service
        rescue StandardError => ex
          handle_service_failure(service_class_name)
          log_error(service_class_name, ex)
          @error = ex.message
        end
      end
      nil
    end

    # Provides an enumerator for available weather services lazily initializing them.
    # @return [Enumerator] an enumerator for the weather services.
    def services
      request_handler = RequestHandler.new

      Enumerator.new do |yielder|
        yielder << Meteo::Integrations::OpenweatherService.new(lat, lon, request_handler)
        yielder << Meteo::Integrations::WeatherbitService.new(lat, lon, request_handler)
      end
    end

    # Builds the unavailable key for a given service name.
    # @param service_name [String] the service name.
    # @return [String] the unavailable key for Redis.
    def unavailable_key(service_name)
      "#{@cache_prefix}:#{service_name}_unavailable"
    end

    # Handles failure of the service by setting a flag in Redis.
    # @param service_name [String] the name of the service that failed.
    def handle_service_failure(service_name)
      @redis_pool.with do |redis|
        redis.set(unavailable_key(service_name), true, ex: SERVICE_UNAVAILABLE_TIMEOUT)
      end
    end

    # Logs error information for debugging purposes.
    # @param service_name [String] the name of the service that failed.
    # @param error [StandardError] the error that occurred.
    def log_error(service_name, error)
      Rails.logger.error("Service #{service_name} failed with error: #{error.message}")
      Rails.logger.error(error.backtrace.join("\n"))
    end
  end
end
