module Geo
  module Integrations
    # Abstract base class for geosearch services, enforcing implementation of the fetch method by subclasses.
    class BaseGeosearchService
      # Abstract method for fetching addresses.
      # @param query [String] the partial address to search for.
      # @return [Array<Address>] the list of found addresses.
      def fetch(query)
        raise NotImplementedError, "The fetch method must be implemented in subclasses"
      end
    end
  end
end
