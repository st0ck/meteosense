module Geo
  module Integrations
    # Implements geosearch functionality using the HERE Maps API to fetch address details.
    class HereMapsService < BaseGeosearchService
      BASE_URL = "https://geocode.search.hereapi.com/v1/geocode".freeze

      # @param request_handler [RequestHandler] the request handler for making requests.
      def initialize(request_handler)
        @request_handler = request_handler
      end

      # Fetches addresses using the HERE Maps API.
      # @param query [String] the partial address to search for.
      # @return [Array<Address>] the list of found addresses.
      def fetch(query)
        params = build_params(query)
        headers = build_headers

        response = @request_handler.make_request(BASE_URL, params: params, headers: headers)
        parse_response(response)
      end

      private

      # Builds the parameters.
      # @param query [String] the partial address to search for.
      # @return [Hash] the parameters for the API request.
      def build_params(query)
        {
          q: URI.encode_www_form_component(query),
          apiKey: ENV["HERE_MAPS_API_KEY"]
        }
      end

      # Builds the headers
      # @return [Hash] the headers for the API request.
      def build_headers
        @headers ||= { Accept: "application/json" }
      end

      # Parses the response from the HERE Maps API.
      # @param response [Net::HTTPResponse] the HTTP response.
      # @return [Array<Address>] the list of found addresses.
      def parse_response(response)
        data = JSON.parse(response.body)
        data["items"].map do |item|
          Address.new(
            name: item["title"],
            address: item["address"]["label"],
            latitude: item["position"]["lat"],
            longitude: item["position"]["lng"],
            country: item["address"]["countryName"],
            city: item["address"]["city"],
            postcode: (item["address"]["postalCode"] || "").split("-").first
          )
        end
      end
    end
  end
end
