require "test_helper"

class RequestHandlerTest < ActiveSupport::TestCase
  def setup
    @request_handler = RequestHandler.new
    @uri = URI("http://example.com")

    # Mocking a sleep call to avoid delays in tests
    @request_handler.stubs(:sleep).with(any_parameters)
  end

  def test_successful_request
    conn = Faraday.new do |f|
      f.adapter :test do |stub|
        stub.get(@uri.to_s) { [ 200, {}, "Success" ] }
      end
    end

    @request_handler.stubs(:connection).returns(conn)

    response = @request_handler.make_request(@uri)
    assert_instance_of Faraday::Response, response
    assert_equal 200, response.status
    assert_equal "Success", response.body
  end

  def test_too_many_requests_with_retry
    retry_attempts = 0
    conn = Faraday.new do |f|
      f.adapter :test do |stub|
        # Retry once and then succeed
        stub.get(@uri.to_s) do
          if retry_attempts < 1
            retry_attempts += 1
            [ 429, { "Retry-After" => "1" }, "" ]
          else
            [ 200, {}, "Success" ]
          end
        end
      end
    end

    @request_handler.stubs(:connection).returns(conn)

    @request_handler.expects(:sleep).times(1)
    response = @request_handler.make_request(@uri)
    assert_instance_of Faraday::Response, response
    assert_equal 200, response.status
    assert_equal "Success", response.body
  end

  def test_too_many_requests_exceeding_retries
    conn = Faraday.new do |f|
      f.adapter :test do |stub|
        stub.get(@uri.to_s) { [ 429, { "Retry-After" => "1" }, "" ] }
      end
    end

    @request_handler.stubs(:connection).returns(conn)
    RequestHandler.any_instance.stubs(:random_delay).returns(0)

    @request_handler.expects(:sleep).times(1)
    assert_raises(Errors::TooManyRequests) do
      @request_handler.make_request(@uri, retries: 1) # Only 1 retry attempt
    end
  end

  def test_handle_response_with_server_error
    conn = Faraday.new do |f|
      f.adapter :test do |stub|
        stub.get(@uri.to_s) { [ 500, {}, "Internal Server Error" ] }
      end
    end

    @request_handler.stubs(:connection).returns(conn)

    assert_raises(RuntimeError, "Error fetching data: Internal Server Error") do
      @request_handler.make_request(@uri)
    end
  end

  def test_random_delay_range
    delay = @request_handler.send(:random_delay)
    assert delay >= 0.5 && delay <= 1.5, "Random delay should be between 0.5 and 1.5 seconds"
  end
end
