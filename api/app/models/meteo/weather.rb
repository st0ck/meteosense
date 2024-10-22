module Meteo
  # Represents a standardized weather data object with attributes such as temperature, feels_like, weather status, etc.
  Weather = Struct.new(
    :temperature, :feels_like, :status, :humidity, :wind_speed, :date, :max_temp, :min_temp,
    keyword_init: true
  )
end
