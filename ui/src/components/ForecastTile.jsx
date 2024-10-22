import PropTypes from 'prop-types';

function ForecastTile({ forecast, cacheStatus, cacheAge }) {
  return (
    <div>
      <h2 className="text-xl font-semibold mb-2">7-Day Weather Forecast</h2>
      {cacheStatus && (
        <p className="text-sm text-gray-600 mb-4">
          Data retrieved from cache (Age: {cacheAge} seconds)
        </p>
      )}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-7 gap-4">
        {forecast.map((day) => (
          <div key={day.date} className="p-4 border rounded shadow">
            <h3 className="font-semibold">{day.date}</h3>
            <img src={`/images/${day.status}.png`} alt={day.status} className="w-12 h-12 mb-2" />
            <p>Temperature: {day.temperature} &#8451;</p>
            <p>Feels Like: {day.feels_like} &#8451;</p>
            <p>Status: {day.status}</p>
            <p>Humidity: {day.humidity}%</p>
            <p>Wind Speed: {day.wind_speed} m/s</p>
          </div>
        ))}
      </div>
    </div>
  );
}

ForecastTile.propTypes = {
  forecast: PropTypes.arrayOf(PropTypes.shape({
    date: PropTypes.string.isRequired,
    status: PropTypes.string.isRequired,
    temperature: PropTypes.number.isRequired,
    feels_like: PropTypes.number.isRequired,
    humidity: PropTypes.number.isRequired,
    wind_speed: PropTypes.number.isRequired,
  })).isRequired,
  cacheStatus: PropTypes.bool,
  cacheAge: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
};

export default ForecastTile;
