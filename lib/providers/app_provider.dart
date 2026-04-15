import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AppProvider with ChangeNotifier {
  // Change this to your backend URL when ready
  static const String baseUrl = 'YOUR_BACKEND_URL_HERE/api';

  Map<String, dynamic>? dashboardStats;
  List<dynamic> crops = [];
  List<dynamic> alerts = [];
  List<dynamic> weather = [];
  List<dynamic> products = [];
  List<dynamic> posts = [];

  bool isLoading = false;

  // ── Mock Data ──────────────────────────────────────────────────────────────

  static Map<String, dynamic> get _mockDashboard => {
        'sustainability_score': 78,
        'total_crops': 12,
        'healthy_crops': 9,
        'alerts_count': 3,
        'total_area_hectares': 24.5,
      };

  static List<dynamic> get _mockAlerts => [
        {
          'severity': 'warning',
          'title': 'Low Soil Moisture',
          'message': 'Rice field in Zone A needs irrigation within 24 hours.',
        },
        {
          'severity': 'info',
          'title': 'Harvest Reminder',
          'message': 'Corn in Zone B is ready for harvest this week.',
        },
        {
          'severity': 'critical',
          'title': 'Pest Detected',
          'message': 'Aphid infestation detected in Tomato section.',
        },
      ];

  static List<dynamic> get _mockCrops => [
        {
          'name': 'Rice – Jasmine Variety',
          'type': 'Cereal',
          'health_status': 'good',
          'health_percentage': 82,
          'area_hectares': 6.0,
          'planted_date': '2026-01-15',
          'expected_harvest': '2026-05-10',
          'notes': 'Irrigated twice this week.',
        },
        {
          'name': 'Yellow Corn',
          'type': 'Cereal',
          'health_status': 'excellent',
          'health_percentage': 95,
          'area_hectares': 4.5,
          'planted_date': '2026-02-01',
          'expected_harvest': '2026-04-20',
          'notes': '',
        },
        {
          'name': 'Tomatoes',
          'type': 'Vegetable',
          'health_status': 'fair',
          'health_percentage': 60,
          'area_hectares': 2.0,
          'planted_date': '2026-02-20',
          'expected_harvest': '2026-05-01',
          'notes': 'Monitor for aphids.',
        },
        {
          'name': 'Sweet Potato',
          'type': 'Root Crop',
          'health_status': 'good',
          'health_percentage': 77,
          'area_hectares': 3.0,
          'planted_date': '2026-01-28',
          'expected_harvest': '2026-05-28',
          'notes': '',
        },
      ];

  static List<dynamic> get _mockWeather => [
        {
          'date': 'Mon Apr 14',
          'condition': 'Partly Cloudy',
          'temperature_high': 34,
          'temperature_low': 25,
          'humidity': 72,
          'wind_speed_kmh': 18,
          'rainfall_mm': 0,
          'advisory': 'Good day for fertiliser application. Low rain risk.',
        },
        {
          'date': 'Tue Apr 15',
          'condition': 'Rainy',
          'temperature_high': 29,
          'temperature_low': 23,
          'humidity': 88,
          'wind_speed_kmh': 22,
          'rainfall_mm': 35,
          'advisory': 'Expected heavy rain. Delay any pesticide spraying.',
        },
        {
          'date': 'Wed Apr 16',
          'condition': 'Sunny',
          'temperature_high': 36,
          'temperature_low': 26,
          'humidity': 60,
          'wind_speed_kmh': 12,
          'rainfall_mm': 0,
          'advisory': 'Ideal harvesting conditions. Check soil moisture.',
        },
      ];

  static List<dynamic> get _mockProducts => [
        {
          'name': 'Organic Fertiliser 50kg',
          'price': 850,
          'unit': 'bag',
          'seller_name': 'AgriSupply Co.',
          'image_url': null,
        },
        {
          'name': 'Heirloom Rice Seeds 5kg',
          'price': 320,
          'unit': 'pack',
          'seller_name': 'SeedBank PH',
          'image_url': null,
        },
        {
          'name': 'Drip Irrigation Kit',
          'price': 2400,
          'unit': 'set',
          'seller_name': 'IrrigaTech',
          'image_url': null,
        },
        {
          'name': 'Compost Activator',
          'price': 180,
          'unit': 'bottle',
          'seller_name': 'GreenGrove',
          'image_url': null,
        },
      ];

  static List<dynamic> get _mockPosts => [
        {
          'author': 'Maria Santos',
          'category': 'tip',
          'title': 'Natural Pest Control Using Neem Oil',
          'content':
              'I have been using neem oil spray for three seasons now and it has dramatically reduced pest damage without harming beneficial insects. Mix 5ml neem oil with 1L water and a drop of dish soap.',
          'likes': 48,
          'comments_count': 12,
        },
        {
          'author': 'Juan dela Cruz',
          'category': 'question',
          'title': 'Best time to plant corn in Visayas?',
          'content':
              'I am planning to start my corn plantation next month. Is October still a good time considering the rains? Would love advice from experienced farmers in the region.',
          'likes': 21,
          'comments_count': 9,
        },
        {
          'author': 'Rosa Mendez',
          'category': 'success',
          'title': 'First organic certification achieved!',
          'content':
              'After 2 years of transitioning, our 4-hectare farm is now officially certified organic. Happy to share our journey and the paperwork process for anyone considering the same path.',
          'likes': 134,
          'comments_count': 37,
        },
      ];

  // ── Fetch Methods (try real API first, fall back to mock) ─────────────────

  Future<void> fetchDashboardStats() async {
    isLoading = true;
    notifyListeners();

    try {
      final response =
          await http.get(Uri.parse('$baseUrl/dashboard/stats')).timeout(
                const Duration(seconds: 5),
              );
      if (response.statusCode == 200) {
        dashboardStats = json.decode(response.body);
        isLoading = false;
        notifyListeners();
        return;
      }
    } catch (_) {}

    // Fallback to mock data
    dashboardStats = _mockDashboard;
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAlerts() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/alerts'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        alerts = json.decode(response.body);
        notifyListeners();
        return;
      }
    } catch (_) {}

    alerts = _mockAlerts;
    notifyListeners();
  }

  Future<void> fetchCrops() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/crops'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        crops = json.decode(response.body);
        notifyListeners();
        return;
      }
    } catch (_) {}

    crops = _mockCrops;
    notifyListeners();
  }

  Future<void> fetchWeather() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/weather/forecast'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        weather = json.decode(response.body);
        notifyListeners();
        return;
      }
    } catch (_) {}

    weather = _mockWeather;
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/marketplace/products'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        products = json.decode(response.body);
        notifyListeners();
        return;
      }
    } catch (_) {}

    products = _mockProducts;
    notifyListeners();
  }

  Future<void> fetchCommunityPosts() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/community/posts'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        posts = json.decode(response.body);
        notifyListeners();
        return;
      }
    } catch (_) {}

    posts = _mockPosts;
    notifyListeners();
  }
}