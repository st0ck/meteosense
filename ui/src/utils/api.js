import axios from 'axios';

export const getAddressSuggestions = async (query, sessionId) => {
  return axios.get("/api/v1/address/search", { params: { q: query, session_id: sessionId } });
};

export const getCurrentWeather = async (latitude, longitude) => {
  return axios.post("/api/v1/meteo/current_weather", { lat: latitude, lon: longitude });
};

export const getDailyWeatherForecast = async (latitude, longitude) => {
  return axios.post("/api/v1/meteo/daily_weather_forecast", { lat: latitude, lon: longitude });
};
