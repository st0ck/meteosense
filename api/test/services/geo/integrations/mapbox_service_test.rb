require "test_helper"

class Geo::Integrations::MapboxServiceTest < ActiveSupport::TestCase
  def setup
    @request_handler = mock()
    @session_token = "test_session_token"
    @mapbox_service = Geo::Integrations::MapboxService.new(@request_handler, @session_token)
    @query = "825 Milwaukee Ave"
  end

  def test_fetch_successful_response_with_session_token
    response = mock()
    response.stubs(:body).returns({
      "features" => [
        {
          "text" => "Milwaukee Ave",
          "place_name" => "825 Milwaukee Ave, Wheeling, Illinois 60090, United States",
          "geometry" => { "coordinates" => [ -87.910299, 42.144504 ] },
          "context" => [
            { "id" => "country.9053006287256050", "text" => "United States" },
            { "id" => "place.9902190947082220", "text" => "Wheeling" },
            { "id" => "postcode.9418633295906190", "text" => "60090" }
          ]
        }
      ]
    }.to_json)
    @request_handler.stubs(:make_request).returns(response)

    results = @mapbox_service.fetch(@query)

    assert_equal 1, results.size
    assert_equal "Milwaukee Ave", results.first.name
    assert_equal "825 Milwaukee Ave, Wheeling, Illinois 60090, United States", results.first.address
    assert_equal 42.144504, results.first.latitude
    assert_equal -87.910299, results.first.longitude
    assert_equal "United States", results.first.country
    assert_equal "Wheeling", results.first.city
    assert_equal "60090", results.first.postcode
  end

  def test_fetch_successful_response_without_session_token
    @mapbox_service = Geo::Integrations::MapboxService.new(@request_handler, nil)
    response = mock()
    response.stubs(:body).returns({
      "features" => [
        {
          "text" => "Milwaukee Ave",
          "place_name" => "825 Milwaukee Ave, Wheeling, Illinois 60090, United States",
          "geometry" => { "coordinates" => [ -87.910299, 42.144504 ] },
          "context" => [
            { "id" => "country.123", "text" => "United States" },
            { "id" => "place.123", "text" => "Wheeling" },
            { "id" => "postcode.123", "text" => "60090" }
          ]
        }
      ]
    }.to_json)
    @request_handler.stubs(:make_request).returns(response)

    results = @mapbox_service.fetch(@query)

    assert_equal 1, results.size
    assert_equal "Milwaukee Ave", results.first.name
    assert_equal "825 Milwaukee Ave, Wheeling, Illinois 60090, United States", results.first.address
    assert_equal 42.144504, results.first.latitude
    assert_equal -87.910299, results.first.longitude
    assert_equal "United States", results.first.country
    assert_equal "Wheeling", results.first.city
    assert_equal "60090", results.first.postcode
  end

  def test_fetch_empty_response
    response = mock()
    response.stubs(:body).returns({ "features" => [] }.to_json)
    @request_handler.stubs(:make_request).returns(response)

    results = @mapbox_service.fetch(@query)

    assert_equal 0, results.size
  end

  def test_fetch_invalid_json_response
    response = mock()
    response.stubs(:body).returns("invalid json")
    @request_handler.stubs(:make_request).returns(response)

    assert_raises(JSON::ParserError) do
      @mapbox_service.fetch(@query)
    end
  end
end
