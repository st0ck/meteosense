require "test_helper"

class Geo::Integrations::HereMapsServiceTest < ActiveSupport::TestCase
  def setup
    @request_handler = mock()
    @here_maps_service = Geo::Integrations::HereMapsService.new(@request_handler)
    @query = "825 Milwaukee Ave"
  end

  def test_fetch_successful_response
    response = mock()
    response.stubs(:body).returns({
      "items" => [
        {
          "title" => "825 Milwaukee Ave, Glenview, IL 60025-3715, United States",
          "address" => {
            "label" => "825 Milwaukee Ave, Glenview, IL 60025-3715, United States",
            "countryName" => "United States",
            "city" => "Glenview",
            "postalCode" => "60025-3715"
          },
          "position" => { "lat" => 42.07103, "lng" => -87.85347 }
        }
      ]
    }.to_json)
    @request_handler.stubs(:make_request).returns(response)

    results = @here_maps_service.fetch(@query)

    assert_equal 1, results.size
    assert_equal "825 Milwaukee Ave, Glenview, IL 60025-3715, United States", results.first.name
    assert_equal "825 Milwaukee Ave, Glenview, IL 60025-3715, United States", results.first.address
    assert_equal 42.07103, results.first.latitude
    assert_equal -87.85347, results.first.longitude
    assert_equal "United States", results.first.country
    assert_equal "Glenview", results.first.city
    assert_equal "60025", results.first.postcode
  end

  def test_fetch_empty_response
    response = mock()
    response.stubs(:body).returns({ "items" => [] }.to_json)
    @request_handler.stubs(:make_request).returns(response)

    results = @here_maps_service.fetch(@query)

    assert_equal 0, results.size
  end

  def test_fetch_invalid_json_response
    response = mock()
    response.stubs(:body).returns("invalid json")
    @request_handler.stubs(:make_request).returns(response)

    assert_raises(JSON::ParserError) do
      @here_maps_service.fetch(@query)
    end
  end
end
