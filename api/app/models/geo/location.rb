module Geo
  class Location
    include ActiveModel::Validations

    attr_reader :lat, :lon

    validates :lat, presence: true, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
    validates :lon, presence: true, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

    def initialize(lat:, lon:)
      @lat = lat
      @lon = lon
    end
  end
end
