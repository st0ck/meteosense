module ValidatorHelper
  extend ActiveSupport::Concern

  # Validates that the specified attributes are present in the given data.
  # Raises an error if any required attribute is missing.
  # @param data [Hash] the data containing attributes to validate.
  # @param attributes [Array<Symbol>] the list of attributes to check for presence.
  # @raise [ActionController::ParameterMissing] if any attribute is missing.
  def validate_attributes_presence(data, *attributes)
    attributes.each do |param|
      raise ActionController::ParameterMissing.new(param), "Missing required parameter: #{param}" unless data[param].present?
    end
  end
end
