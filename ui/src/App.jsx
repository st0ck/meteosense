import { useState, useEffect, useMemo } from "react";
import { v4 as uuidv4 } from 'uuid';
import { getAddressSuggestions, getCurrentWeather, getDailyWeatherForecast } from './utils/api';
import ForecastTile from './components/ForecastTile.jsx'
import CurrentWeather from './components/CurrentWeather.jsx'

function App() {
  const [query, setQuery] = useState("");
  const [suggestions, setSuggestions] = useState([]);
  const [weather, setWeather] = useState(null);
  const [forecast, setForecast] = useState(null);
  const [sessionId, setSessionId] = useState("");
  const [cacheStatus, setCacheStatus] = useState({ weather: null, forecast: null });
  const [cacheAge, setCacheAge] = useState({ weather: null, forecast: null });

  useEffect(() => {
    setSessionId(uuidv4());
  }, []);

  const handleInputChange = async (e) => {
    const value = e.target.value;
    setQuery(value);

    if (value.length > 2) {
      try {
        const response = await getAddressSuggestions(value, sessionId);
        setSuggestions(response.data.data);
      } catch (error) {
        console.error("Error fetching address suggestions: ", error);
        setSuggestions([]);
      }
    } else {
      setSuggestions([]);
    }
  };

  const handleSelectSuggestion = async (suggestion) => {
    setQuery(suggestion.address);
    setSuggestions([]);

    const { latitude, longitude } = suggestion;

    try {
      const [currentWeatherResponse, forecastResponse] = await Promise.all([
        getCurrentWeather(latitude, longitude),
        getDailyWeatherForecast(latitude, longitude)
      ]);

      setWeather(currentWeatherResponse.data.data);
      setForecast(forecastResponse.data.data);
      setCacheStatus({
        weather: currentWeatherResponse.headers['x-cache-hit'] === 'true',
        forecast: forecastResponse.headers['x-cache-hit'] === 'true'
      });
      setCacheAge({
        weather: currentWeatherResponse.headers['x-cache-age'],
        forecast: forecastResponse.headers['x-cache-age']
      });
    } catch (error) {
      console.error("Error fetching weather data: ", error);
    }
  };

  const suggestionsList = useMemo(() => (
    suggestions.length > 0 && (
      <ul className="border rounded mb-4">
        {suggestions.map((suggestion) => (
          <li
            key={suggestion.latitude + suggestion.longitude}
            className="p-2 cursor-pointer hover:bg-gray-100"
            onClick={() => handleSelectSuggestion(suggestion)}
          >
            {suggestion.address}
          </li>
        ))}
      </ul>
    )
  ), [suggestions]);

  return (
    <>
      <div className="container mx-auto p-4">
        <h1 className="text-2xl font-bold mb-4">MeteoSense: Weather Forecasting App</h1>
        <input
          type="text"
          className="w-full p-2 border rounded mb-2"
          placeholder="Enter an address"
          value={query}
          onChange={handleInputChange}
        />
        {suggestionsList}
        {weather && <CurrentWeather weather={weather} cacheStatus={cacheStatus.weather} cacheAge={cacheAge.weather} />}
        {forecast && <ForecastTile forecast={forecast} cacheStatus={cacheStatus.forecast} cacheAge={cacheAge.forecast} />}
      </div>
    </>
  );
}

export default App;
