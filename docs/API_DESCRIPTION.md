# Meteosense API Overview

The Meteosense API provides weather and address-related services via REST endpoints. The API offers three endpoints:

1. **Current Weather Forecast**
   - **URL**: `/api/v1/meteo/current_weather`
   - **Method**: GET
   - **Description**: Retrieves current weather data for a specified latitude and longitude, including temperature, humidity, wind speed, and weather conditions.
   - **Parameters**:
     - `lat` (float, required): Latitude of the location.
     - `lon` (float, required): Longitude of the location.

2. **Daily Weather Forecast (7-day)**
   - **URL**: `/api/v1/meteo/daily_weather_forecast`
   - **Method**: GET
   - **Description**: Provides a 7-day weather forecast for a specified latitude and longitude, including temperature, humidity, wind speed, and weather conditions.
   - **Parameters**:
     - `lat` (float, required): Latitude of the location.
     - `lon` (float, required): Longitude of the location.

3. **Address Search Service**
   - **URL**: `/api/v1/address/search`
   - **Method**: GET
   - **Description**: Searches for geolocation-based addresses based on a provided query, utilizing multiple geospatial services for reliability.
   - **Parameters**:
     - `q` (string, required): The partial address or query to search.
     - `session_id` (string, required): Session ID for tracking the request.
