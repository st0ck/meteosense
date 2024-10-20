require "test_helper"

class Api::V1::Address::SearchControllerTest < ActionDispatch::IntegrationTest
  def setup
    @query = "825 Milwaukee Ave"
    @session_id = "test-session-id"
    @valid_params = { q: @query, session_id: @session_id }
  end

  def test_should_return_success_response_with_valid_parameters
    Geo::AddressLookupService.any_instance.stubs(:search).returns([ {
      name: "825 Milwaukee Ave, Glenview, IL 60025-3715, United States",
      address: "825 Milwaukee Ave, Glenview, IL 60025-3715, United States",
      latitude: 42.07103,
      longitude: -87.85347,
      country: "United States",
      city: "Glenview",
      postcode: "60025-3715"
    } ])
    Geo::AddressLookupService.any_instance.stubs(:error).returns(nil)

    get api_v1_address_search_index_url, params: @valid_params

    assert_response :success
    response_body = JSON.parse(response.body)
    assert_not_nil response_body["data"]
    assert_nil response_body["errors"]
  end

  def test_should_return_success_response_with_valid_parameters_when_nothing_found
    Geo::AddressLookupService.any_instance.stubs(:search).returns(nil)
    Geo::AddressLookupService.any_instance.stubs(:error).returns(nil)

    get api_v1_address_search_index_url, params: @valid_params

    assert_response :success
    response_body = JSON.parse(response.body)
    assert_not_nil response_body["data"]
    assert_nil response_body["errors"]
  end

  def test_should_handle_internal_server_error
    Geo::AddressLookupService.any_instance.stubs(:search).raises(StandardError, "Something went wrong")

    get api_v1_address_search_index_url, params: @valid_params

    assert_response :internal_server_error
    response_body = JSON.parse(response.body)
    assert_nil response_body["data"]
    assert_not_nil response_body["errors"]
    assert_match /An unexpected error occurred/, response_body["errors"][0]["message"]
  end

  def test_should_handle_too_many_requests_error
    retry_after = 5
    Geo::AddressLookupService.any_instance.stubs(:search).raises(Errors::TooManyRequests.new(retry_after: retry_after))

    get api_v1_address_search_index_url, params: @valid_params

    assert_response :too_many_requests
    assert_equal retry_after, response.headers["Retry-After"]
    response_body = JSON.parse(response.body)
    assert_nil response_body["data"]
    assert_not_nil response_body["errors"]
    assert_match /Too Many Requests/, response_body["errors"][0]["message"]
  end

  def test_should_return_bad_request_if_parameter_is_missing
    get api_v1_address_search_index_url, params: { session_id: @session_id }

    assert_response :bad_request
    response_body = JSON.parse(response.body)
    assert_nil response_body["data"]
    assert_not_nil response_body["errors"]
    assert_equal "param is missing or the value is empty: q", response_body["errors"][0]["message"]
  end
end
