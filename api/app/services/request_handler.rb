# Handles HTTP requests, including retry logic for rate limiting, to ensure
# robust communication with external services.
class RequestHandler
  attr_reader :retry_limit

  def initialize(retry_limit = 2)
    @retry_limit = retry_limit
  end

  # Makes an HTTP request and retries if necessary.
  # @param uri [URI] the URI to request.
  # @param params [Hash] optional query parameters to include in the request.
  # @param headers [Hash] optional headers to include in the request.
  # @param retries [Integer] the number of retry attempts allowed.
  # @return [Faraday::Response] the HTTP response.
  def make_request(uri, params: {}, headers: {}, retries: retry_limit)
    response = connection.get(uri.to_s, params, headers)
    handle_response(response, retries)
  end

  private

  # Provides a Faraday connection object with memoization.
  # @return [Faraday::Connection] the Faraday connection.
  def connection
    @connection ||= Faraday.new
  end

  # Handles the HTTP response, retrying if rate limited.
  # @param response [Faraday::Response] the response received from the request.
  # @param retries [Integer] the number of retry attempts left.
  # @return [Faraday::Response] the successful HTTP response.
  def handle_response(response, retries)
    if response.success?
      response
    elsif response.status == 429
      retry_after = response.headers["Retry-After"]&.to_i || random_delay
      raise Errors::TooManyRequests.new(retry_after: retry_after)
    else
      raise "Error fetching data: #{response.body}"
    end
  rescue Errors::TooManyRequests => e
    raise e if retries <= 0
    retry_after = e.retry_after
    sleep(retry_after + random_delay)
    make_request(URI(response.env.url), retries: retries - 1)
  end

  # Generates a random delay.
  # @return [Float] the random delay in seconds.
  def random_delay
    SecureRandom.random_number(0.5..1.5)
  end
end
