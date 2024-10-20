function CurrentWeather({ weather, cacheStatus, cacheAge }) {
  return (
    <div className="p-6 border rounded shadow mb-6">
      <h2 className="text-xl font-semibold mb-4">Current Weather</h2>
      {cacheStatus && (
        <p className="text-sm text-gray-600 mb-2">
          Data retrieved from cache (Age: {cacheAge} seconds)
        </p>
      )}
      <div className="flex items-center">
        <img src={`/images/${weather.status}.png`} alt={weather.status} className="w-16 h-16 mr-4" />
        <div>
          <p className="text-lg">Temperature: {weather.temperature} &#8451;</p>
          <p>Feels Like: {weather.feels_like} &#8451;</p>
          <p>Status: {weather.status}</p>
          <p>Humidity: {weather.humidity}%</p>
          <p>Wind Speed: {weather.wind_speed} m/s</p>
        </div>
      </div>
    </div>
  );
}

export default CurrentWeather;
