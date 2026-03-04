// lib/models/weather_model.dart

class WeatherData {
  final String city;
  final String country;
  final double temperature;
  final double feelsLike;
  final double tempMax;
  final double tempMin;
  final int humidity;
  final double windSpeed;
  final double pressure;
  final double precipitation; // mm/h
  final String condition;
  final String description;
  final String iconCode;
  final DateTime? sunrise;
  final DateTime? sunset;

  WeatherData({
    required this.city,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.tempMax,
    required this.tempMin,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.precipitation,
    required this.condition,
    required this.description,
    required this.iconCode,
    this.sunrise,
    this.sunset,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    // sunrise / sunset come as Unix epoch seconds
    DateTime? sunriseTime;
    DateTime? sunsetTime;
    final sysData = json['sys'] as Map<String, dynamic>?;
    if (sysData != null) {
      if (sysData['sunrise'] != null) {
        sunriseTime = DateTime.fromMillisecondsSinceEpoch(
            (sysData['sunrise'] as int) * 1000);
      }
      if (sysData['sunset'] != null) {
        sunsetTime = DateTime.fromMillisecondsSinceEpoch(
            (sysData['sunset'] as int) * 1000);
      }
    }

    // Precipitation from rain.1h (optional field)
    final rainData = json['rain'] as Map<String, dynamic>?;
    final double precip = (rainData?['1h'] ?? 0).toDouble();

    return WeatherData(
      city: json['name'] ?? 'Unknown',
      country: sysData?['country'] ?? '',
      temperature: (json['main']?['temp'] ?? 0).toDouble(),
      feelsLike: (json['main']?['feels_like'] ?? 0).toDouble(),
      tempMax: (json['main']?['temp_max'] ?? 0).toDouble(),
      tempMin: (json['main']?['temp_min'] ?? 0).toDouble(),
      humidity: (json['main']?['humidity'] ?? 0).toInt(),
      windSpeed: (json['wind']?['speed'] ?? 0).toDouble(),
      pressure: (json['main']?['pressure'] ?? 0).toDouble(),
      precipitation: precip,
      condition: json['weather']?[0]?['main'] ?? 'Clear',
      description: json['weather']?[0]?['description'] ?? '',
      iconCode: json['weather']?[0]?['icon'] ?? '01d',
      sunrise: sunriseTime,
      sunset: sunsetTime,
    );
  }

  String get iconUrl =>
      'https://openweathermap.org/img/wn/$iconCode@2x.png';

  String get tempDisplay => '${temperature.round()}°C';

  String get conditionCapitalized {
    if (description.isEmpty) return condition;
    return description[0].toUpperCase() + description.substring(1);
  }

  String get sunriseDisplay {
    if (sunrise == null) return '--';
    final h = sunrise!.hour.toString().padLeft(2, '0');
    final m = sunrise!.minute.toString().padLeft(2, '0');
    return '$h:$m am';
  }

  String get sunsetDisplay {
    if (sunset == null) return '--';
    var h = sunset!.hour;
    final m = sunset!.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'pm' : 'am';
    if (h > 12) h -= 12;
    return '${h.toString().padLeft(2, '0')}:$m $period';
  }
}
