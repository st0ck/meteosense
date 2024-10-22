module Geo
  # Represents a standardized address object with attributes such as
  # name, address, latitude, longitude, country, city, and postcode.
  Address = Struct.new(
    :name, :address, :latitude, :longitude, :country, :city, :postcode,
    keyword_init: true
  )
end
