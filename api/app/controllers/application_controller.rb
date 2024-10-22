class ApplicationController < ActionController::API
  include JsonResponseHelper

  rescue_from StandardError, with: :handle_internal_server_error
  rescue_from ActionController::ParameterMissing, with: :handle_missing_parameter_request
end
