module Api
  module V1
    module Address
      class SearchController < ApplicationController
        def index
          service = Geo::AddressLookupService.new
          options = { session_id: search_params[:session_id] }
          places = service.search(query: search_params[:q], options: options) || []

          unless service.error
            handle_success_response(data: places)
          else
            handle_general_error(error: service.error, status_code: :internal_server_error)
          end
        rescue Errors::TooManyRequests => ex
          handle_too_many_requests_error(ex)
        rescue ActionController::ParameterMissing => ex
          handle_missing_parameter_request(ex)
        rescue StandardError => ex
          handle_internal_server_error(ex)
        end

        def search_params
          params.permit(:q, :session_id).tap do |parameters|
            raise ActionController::ParameterMissing.new("q") unless parameters[:q].present?
            raise ActionController::ParameterMissing.new("session_id") unless parameters[:session_id].present?
          end
        end
      end
    end
  end
end
