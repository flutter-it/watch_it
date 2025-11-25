/// List of 50 top world cities with their coordinates
class TopCity {
  final String name;
  final double latitude;
  final double longitude;
  final String country;

  const TopCity(this.name, this.latitude, this.longitude, this.country);
}

const List<TopCity> topCities = [
  // Europe
  TopCity('London', 51.5074, -0.1278, 'UK'),
  TopCity('Paris', 48.8566, 2.3522, 'France'),
  TopCity('Berlin', 52.5200, 13.4050, 'Germany'),
  TopCity('Madrid', 40.4168, -3.7038, 'Spain'),
  TopCity('Rome', 41.9028, 12.4964, 'Italy'),
  TopCity('Amsterdam', 52.3676, 4.9041, 'Netherlands'),
  TopCity('Vienna', 48.2082, 16.3738, 'Austria'),
  TopCity('Prague', 50.0755, 14.4378, 'Czech Republic'),
  TopCity('Stockholm', 59.3293, 18.0686, 'Sweden'),
  TopCity('Athens', 37.9838, 23.7275, 'Greece'),

  // North America
  TopCity('New York', 40.7128, -74.0060, 'USA'),
  TopCity('Los Angeles', 34.0522, -118.2437, 'USA'),
  TopCity('Chicago', 41.8781, -87.6298, 'USA'),
  TopCity('Toronto', 43.6532, -79.3832, 'Canada'),
  TopCity('Mexico City', 19.4326, -99.1332, 'Mexico'),
  TopCity('Miami', 25.7617, -80.1918, 'USA'),
  TopCity('San Francisco', 37.7749, -122.4194, 'USA'),
  TopCity('Vancouver', 49.2827, -123.1207, 'Canada'),
  TopCity('Houston', 29.7604, -95.3698, 'USA'),
  TopCity('Seattle', 47.6062, -122.3321, 'USA'),

  // Asia
  TopCity('Tokyo', 35.6762, 139.6503, 'Japan'),
  TopCity('Beijing', 39.9042, 116.4074, 'China'),
  TopCity('Shanghai', 31.2304, 121.4737, 'China'),
  TopCity('Hong Kong', 22.3193, 114.1694, 'Hong Kong'),
  TopCity('Singapore', 1.3521, 103.8198, 'Singapore'),
  TopCity('Seoul', 37.5665, 126.9780, 'South Korea'),
  TopCity('Mumbai', 19.0760, 72.8777, 'India'),
  TopCity('Delhi', 28.7041, 77.1025, 'India'),
  TopCity('Bangkok', 13.7563, 100.5018, 'Thailand'),
  TopCity('Dubai', 25.2048, 55.2708, 'UAE'),

  // South America
  TopCity('São Paulo', -23.5505, -46.6333, 'Brazil'),
  TopCity('Buenos Aires', -34.6037, -58.3816, 'Argentina'),
  TopCity('Rio de Janeiro', -22.9068, -43.1729, 'Brazil'),
  TopCity('Lima', -12.0464, -77.0428, 'Peru'),
  TopCity('Bogotá', 4.7110, -74.0721, 'Colombia'),

  // Africa
  TopCity('Cairo', 30.0444, 31.2357, 'Egypt'),
  TopCity('Lagos', 6.5244, 3.3792, 'Nigeria'),
  TopCity('Cape Town', -33.9249, 18.4241, 'South Africa'),
  TopCity('Nairobi', -1.2921, 36.8219, 'Kenya'),
  TopCity('Casablanca', 33.5731, -7.5898, 'Morocco'),

  // Oceania
  TopCity('Sydney', -33.8688, 151.2093, 'Australia'),
  TopCity('Melbourne', -37.8136, 144.9631, 'Australia'),
  TopCity('Auckland', -36.8509, 174.7645, 'New Zealand'),
  TopCity('Brisbane', -27.4698, 153.0251, 'Australia'),
  TopCity('Perth', -31.9505, 115.8605, 'Australia'),

  // Middle East
  TopCity('Istanbul', 41.0082, 28.9784, 'Turkey'),
  TopCity('Tel Aviv', 32.0853, 34.7818, 'Israel'),
  TopCity('Riyadh', 24.7136, 46.6753, 'Saudi Arabia'),

  // Russia
  TopCity('Moscow', 55.7558, 37.6173, 'Russia'),
  TopCity('Saint Petersburg', 59.9311, 30.3609, 'Russia'),
];

/// WMO Weather interpretation codes mapping
/// https://open-meteo.com/en/docs
class WmoWeatherCode {
  final int code;
  final String description;
  final String icon;

  const WmoWeatherCode(this.code, this.description, this.icon);

  static WmoWeatherCode fromCode(int code) {
    return _weatherCodes[code] ?? WmoWeatherCode(code, 'Unknown', '❓');
  }
}

const Map<int, WmoWeatherCode> _weatherCodes = {
  0: WmoWeatherCode(0, 'Clear sky', '☀️'),
  1: WmoWeatherCode(1, 'Mainly clear', '🌤️'),
  2: WmoWeatherCode(2, 'Partly cloudy', '⛅'),
  3: WmoWeatherCode(3, 'Overcast', '☁️'),
  45: WmoWeatherCode(45, 'Fog', '🌫️'),
  48: WmoWeatherCode(48, 'Depositing rime fog', '🌫️'),
  51: WmoWeatherCode(51, 'Light drizzle', '🌧️'),
  53: WmoWeatherCode(53, 'Moderate drizzle', '🌧️'),
  55: WmoWeatherCode(55, 'Dense drizzle', '🌧️'),
  56: WmoWeatherCode(56, 'Light freezing drizzle', '🌧️'),
  57: WmoWeatherCode(57, 'Dense freezing drizzle', '🌧️'),
  61: WmoWeatherCode(61, 'Slight rain', '🌧️'),
  63: WmoWeatherCode(63, 'Moderate rain', '🌧️'),
  65: WmoWeatherCode(65, 'Heavy rain', '🌧️'),
  66: WmoWeatherCode(66, 'Light freezing rain', '🌧️'),
  67: WmoWeatherCode(67, 'Heavy freezing rain', '🌧️'),
  71: WmoWeatherCode(71, 'Slight snow fall', '🌨️'),
  73: WmoWeatherCode(73, 'Moderate snow fall', '🌨️'),
  75: WmoWeatherCode(75, 'Heavy snow fall', '🌨️'),
  77: WmoWeatherCode(77, 'Snow grains', '🌨️'),
  80: WmoWeatherCode(80, 'Slight rain showers', '🌦️'),
  81: WmoWeatherCode(81, 'Moderate rain showers', '🌦️'),
  82: WmoWeatherCode(82, 'Violent rain showers', '🌦️'),
  85: WmoWeatherCode(85, 'Slight snow showers', '🌨️'),
  86: WmoWeatherCode(86, 'Heavy snow showers', '🌨️'),
  95: WmoWeatherCode(95, 'Thunderstorm', '⛈️'),
  96: WmoWeatherCode(96, 'Thunderstorm with slight hail', '⛈️'),
  99: WmoWeatherCode(99, 'Thunderstorm with heavy hail', '⛈️'),
};

/// Open-Meteo API response model
class OpenMeteoResponse {
  final List<OpenMeteoLocationWeather> locations;

  OpenMeteoResponse({required this.locations});

  /// Parse response when querying multiple locations
  /// The response contains arrays for latitude, longitude, and current weather data
  factory OpenMeteoResponse.fromJson(List<dynamic> jsonList) {
    return OpenMeteoResponse(
      locations: jsonList
          .map((json) =>
              OpenMeteoLocationWeather.fromJson(json as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OpenMeteoLocationWeather {
  final double latitude;
  final double longitude;
  final double elevation;
  final OpenMeteoCurrentWeather current;

  OpenMeteoLocationWeather({
    required this.latitude,
    required this.longitude,
    required this.elevation,
    required this.current,
  });

  factory OpenMeteoLocationWeather.fromJson(Map<String, dynamic> json) {
    return OpenMeteoLocationWeather(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      elevation: (json['elevation'] as num?)?.toDouble() ?? 0.0,
      current: OpenMeteoCurrentWeather.fromJson(
          json['current'] as Map<String, dynamic>),
    );
  }
}

class OpenMeteoCurrentWeather {
  final double temperature;
  final double windSpeed;
  final int weatherCode;
  final double? rain;
  final int? humidity;

  OpenMeteoCurrentWeather({
    required this.temperature,
    required this.windSpeed,
    required this.weatherCode,
    this.rain,
    this.humidity,
  });

  factory OpenMeteoCurrentWeather.fromJson(Map<String, dynamic> json) {
    return OpenMeteoCurrentWeather(
      temperature: (json['temperature_2m'] as num).toDouble(),
      windSpeed: (json['wind_speed_10m'] as num).toDouble(),
      weatherCode: json['weather_code'] as int,
      rain: (json['rain'] as num?)?.toDouble(),
      humidity: json['relative_humidity_2m'] as int?,
    );
  }

  WmoWeatherCode get weather => WmoWeatherCode.fromCode(weatherCode);
}
