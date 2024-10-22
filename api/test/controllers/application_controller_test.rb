require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  class TestController < ApplicationController
    def test_bad_request
      params.require(:required_param)

      render(
        json: {
          data: { all_good: true },
          errors: nil
        },
        status: :ok
      )
    end

    def test_internal_server_error
      raise "Syntetic Error"
    end
  end

  test "response for parameter missing happy path" do
    with_routing do |set|
      set.draw do
        get "test_bad_request", to: "application_controller_test/test#test_bad_request"
      end

      get "/test_bad_request", params: { required_param: { data: "test" } }
      assert_response :ok
      response_data = JSON.parse(response.body)
      assert_nil response_data["errors"]
      assert response_data["data"]["all_good"]
    end
  end

  test "response for parameter missing error" do
    with_routing do |set|
      set.draw do
        get "test_bad_request", to: "application_controller_test/test#test_bad_request"
      end

      get "/test_bad_request", as: :json
      assert_response :bad_request
      response_data = JSON.parse(response.body)
      assert response_data["errors"].is_a?(Array)
      assert_equal response_data["errors"][0]["code"], "bad_request"
      assert_equal response_data["errors"][0]["message"], "param is missing or the value is empty: required_param"
    end
  end

  test "response for internal server error" do
    with_routing do |set|
      set.draw do
        get(
          "test_internal_server_error",
          to: "application_controller_test/test#test_internal_server_error"
        )
      end

      get "/test_internal_server_error"
      assert_response :internal_server_error
      response_data = JSON.parse(response.body)
      assert response_data["errors"].is_a?(Array)
      assert_equal response_data["errors"][0]["code"], "internal_server_error"
      assert_equal response_data["errors"][0]["message"], "An unexpected error occurred. Please try again later."
    end
  end
end
