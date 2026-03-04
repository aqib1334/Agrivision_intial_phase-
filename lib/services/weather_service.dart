// lib/services/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:practice/models/weather_model.dart';

class WeatherService {
  // ─────────────────────────────────────────────────────────────────────────
  // 🔑 PASTE YOUR OWN API KEY HERE
  //    Get a FREE key at: https://home.openweathermap.org/api_keys
  //    (Free account → log in → copy "Default" key)
  //    ⚠️ New keys take 10–30 minutes to activate after creation!
  // ─────────────────────────────────────────────────────────────────────────
  static const String _apiKey = 'dc0eaec2ac53f153482f737d218feaba';

  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  /// Fetch weather using GPS coordinates (primary)
  static Future<WeatherData?> fetchWeatherByCoords(
      double lat, double lon) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric');
      debugPrint('🌤 Fetching weather by coords: $lat, $lon');
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      debugPrint('🌤 Weather response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return WeatherData.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        debugPrint(
            '❌ Weather API error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Weather coords fetch error: $e');
      return null;
    }
  }

  /// Fetch weather by city name (fallback)
  static Future<WeatherData?> fetchWeatherByCity(String city) async {
    try {
      final uri =
          Uri.parse('$_baseUrl?q=$city&appid=$_apiKey&units=metric');
      debugPrint('🌤 Fetching weather by city: $city');
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      debugPrint('🌤 Weather response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return WeatherData.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        debugPrint(
            '❌ Weather API error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Weather city fetch error: $e');
      return null;
    }
  }
}
