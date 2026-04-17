import 'dart:convert';
import 'package:http/http.dart' as http;

/// Uses Open-Meteo (free, no API key) for real weather data.
/// Defaults to Quezon City, PH if location unavailable.
class WeatherService {
  static const double _defaultLat = 14.6760;
  static const double _defaultLon = 121.0437;
  static const String _locationName = 'Quezon City, PH';

  /// Returns a list of daily weather maps compatible with the existing UI.
  Future<List<Map<String, dynamic>>> fetchWeather({
    double lat = _defaultLat,
    double lon = _defaultLon,
  }) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,'
      'precipitation_sum,wind_speed_10m_max,relative_humidity_2m_max'
      '&current=temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m'
      '&timezone=Asia%2FManila'
      '&forecast_days=7',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Weather API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final daily = data['daily'] as Map<String, dynamic>;
    final currentWeather = data['current'] as Map<String, dynamic>;

    final dates = List<String>.from(daily['time'] as List);
    final codes = List<int>.from(daily['weather_code'] as List);
    final tempMax = List<double>.from(
        (daily['temperature_2m_max'] as List).map((e) => (e as num).toDouble()));
    final tempMin = List<double>.from(
        (daily['temperature_2m_min'] as List).map((e) => (e as num).toDouble()));
    final rain = List<double>.from(
        (daily['precipitation_sum'] as List).map((e) => (e as num).toDouble()));
    final wind = List<double>.from((daily['wind_speed_10m_max'] as List)
        .map((e) => (e as num).toDouble()));
    final humidity = List<int>.from(
        (daily['relative_humidity_2m_max'] as List).map((e) => (e as num).toInt()));

    final currentTemp = (currentWeather['temperature_2m'] as num).toDouble();

    final List<Map<String, dynamic>> result = [];
    for (int i = 0; i < dates.length && i < 7; i++) {
      final code = codes[i];
      final condition = _conditionFromCode(code);
      final icon = _iconFromCode(code);
      final advisory = _advisoryFromCode(code, rain[i]);
      final dateStr = dates[i]; // e.g. "2026-04-15"
      final dt = DateTime.tryParse(dateStr);
      final dayName = dt != null ? _weekdayName(dt.weekday) : '';
      final isToday = i == 0;
      final isTomorrow = i == 1;

      result.add({
        'date': isToday
            ? 'Today'
            : isTomorrow
                ? 'Tomorrow'
                : _formatDate(dateStr),
        'day': dayName,
        'condition': condition,
        'condition_icon': icon,
        'temperature': isToday ? currentTemp.round() : tempMax[i].round(),
        'temperature_high': tempMax[i].round(),
        'temperature_low': tempMin[i].round(),
        'humidity': humidity[i],
        'wind_speed_kmh': wind[i].round(),
        'rainfall_mm': rain[i].round(),
        'advisory': advisory,
        'location': _locationName,
        'fetched_at': DateTime.now().toIso8601String(),
      });
    }
    return result;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _conditionFromCode(int code) {
    if (code == 0) return 'Clear Sky';
    if (code <= 2) return 'Partly Cloudy';
    if (code == 3) return 'Overcast';
    if (code <= 49) return 'Foggy';
    if (code <= 57) return 'Drizzle';
    if (code <= 67) return 'Rainy';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Rain Showers';
    if (code <= 86) return 'Snow Showers';
    if (code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  String _iconFromCode(int code) {
    if (code == 0) return '☀️';
    if (code <= 2) return '⛅';
    if (code == 3) return '☁️';
    if (code <= 49) return '🌫️';
    if (code <= 57) return '🌦️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '❄️';
    if (code <= 82) return '🌦️';
    if (code <= 86) return '🌨️';
    if (code <= 99) return '⛈️';
    return '🌡️';
  }

  String _advisoryFromCode(int code, double rain) {
    if (code == 0 || code <= 2) {
      return 'Excellent conditions for fieldwork, irrigation, and harvesting.';
    }
    if (code == 3) return 'Overcast skies. Good for transplanting seedlings.';
    if (code <= 49) return 'Foggy conditions. Delay spraying activities.';
    if (code <= 57) return 'Light drizzle expected. Postpone fertiliser application.';
    if (code <= 67) {
      return rain > 20
          ? 'Heavy rain expected (${rain.round()}mm). Secure equipment and check drainage.'
          : 'Rain expected (${rain.round()}mm). Delay pesticide and herbicide spraying.';
    }
    if (code <= 82) return 'Rain showers possible. Prepare irrigation drainage systems.';
    if (code <= 99) {
      return 'Severe thunderstorm warning. Secure all equipment and stay indoors.';
    }
    return 'Check local weather updates before farm activities.';
  }

  String _weekdayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1) % 7];
  }

  String _formatDate(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${_weekdayName(dt.weekday)} ${months[dt.month]} ${dt.day}';
  }
}
