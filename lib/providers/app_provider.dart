import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AppProvider with ChangeNotifier {
  static const String baseUrl = 'YOUR_BACKEND_URL_HERE/api';

  // ── Data State ───────────────────────────────────────────────────────────────
  Map<String, dynamic>? dashboardStats;
  List<dynamic> crops = [];
  List<dynamic> alerts = [];
  List<dynamic> weather = [];
  List<dynamic> products = [];
  List<dynamic> posts = [];

  bool isLoading = false;
  String? error;

  // ── Auth State ───────────────────────────────────────────────────────────────
  bool isLoggedIn = false;
  Map<String, dynamic>? currentUser;
  bool _seedLoaded = false;

  void login(String name, String email) {
    currentUser = {'name': name, 'email': email};
    isLoggedIn = true;
    notifyListeners();
    _loadAllData();
  }

  void logout() {
    currentUser = null;
    isLoggedIn = false;
    dashboardStats = null;
    crops = [];
    alerts = [];
    weather = [];
    products = [];
    posts = [];
    _seedLoaded = false;
    notifyListeners();
  }

  Future<void> _loadAllData() async {
    if (_seedLoaded) return;
    _seedLoaded = true;
    await fetchDashboardStats();
    await fetchAlerts();
    await fetchCrops();
    await fetchWeather();
    await fetchProducts();
    await fetchCommunityPosts();
  }

  // ── Mock Data ────────────────────────────────────────────────────────────────
  static Map<String, dynamic> get _mockDashboard => {
        'sustainability_score': 78,
        'total_crops': 4,
        'healthy_crops': 3,
        'alerts_count': 3,
        'total_area_hectares': 15.5,
        'water_usage_liters': 12400,
        'carbon_saved_kg': 320,
      };

  static List<dynamic> get _mockAlerts => [
        {
          'severity': 'critical',
          'title': 'Pest Detected',
          'message': 'Aphid infestation detected in Tomato section.',
          'time': '2 hours ago',
          'icon': 'bug',
        },
        {
          'severity': 'warning',
          'title': 'Low Soil Moisture',
          'message': 'Rice field in Zone A needs irrigation within 24 hours.',
          'time': '5 hours ago',
          'icon': 'water',
        },
        {
          'severity': 'info',
          'title': 'Harvest Reminder',
          'message': 'Yellow Corn in Zone B is ready for harvest this week.',
          'time': '1 day ago',
          'icon': 'calendar',
        },
      ];

  static List<dynamic> get _mockCrops => [
        {
          'id': 1,
          'name': 'Rice – Jasmine Variety',
          'type': 'Cereal',
          'health_status': 'good',
          'health_percentage': 82,
          'area_hectares': 6.0,
          'planted_date': '2026-01-15',
          'expected_harvest': '2026-05-10',
          'notes': 'Irrigated twice this week.',
          'zone': 'Zone A',
          'water_need': 'High',
          'growth_stage': 'Tillering',
        },
        {
          'id': 2,
          'name': 'Yellow Corn',
          'type': 'Cereal',
          'health_status': 'excellent',
          'health_percentage': 95,
          'area_hectares': 4.5,
          'planted_date': '2026-02-01',
          'expected_harvest': '2026-04-20',
          'notes': '',
          'zone': 'Zone B',
          'water_need': 'Medium',
          'growth_stage': 'Maturation',
        },
        {
          'id': 3,
          'name': 'Tomatoes',
          'type': 'Vegetable',
          'health_status': 'fair',
          'health_percentage': 60,
          'area_hectares': 2.0,
          'planted_date': '2026-02-20',
          'expected_harvest': '2026-05-01',
          'notes': 'Monitor for aphids.',
          'zone': 'Zone C',
          'water_need': 'Medium',
          'growth_stage': 'Flowering',
        },
        {
          'id': 4,
          'name': 'Sweet Potato',
          'type': 'Root Crop',
          'health_status': 'good',
          'health_percentage': 77,
          'area_hectares': 3.0,
          'planted_date': '2026-01-28',
          'expected_harvest': '2026-05-28',
          'notes': '',
          'zone': 'Zone D',
          'water_need': 'Low',
          'growth_stage': 'Vine Growth',
        },
      ];

  static List<dynamic> get _mockWeather => [
        {
          'date': 'Today',
          'day': 'Tue',
          'condition': 'Rainy',
          'condition_icon': '🌧️',
          'temperature': 29,
          'temperature_high': 29,
          'temperature_low': 23,
          'humidity': 88,
          'wind_speed_kmh': 22,
          'rainfall_mm': 35,
          'advisory': 'Expected heavy rain. Delay any pesticide spraying.',
        },
        {
          'date': 'Tomorrow',
          'day': 'Wed',
          'condition': 'Sunny',
          'condition_icon': '☀️',
          'temperature': 36,
          'temperature_high': 36,
          'temperature_low': 26,
          'humidity': 60,
          'wind_speed_kmh': 12,
          'rainfall_mm': 0,
          'advisory': 'Ideal harvesting conditions. Check soil moisture.',
        },
        {
          'date': 'Thu Apr 17',
          'day': 'Thu',
          'condition': 'Partly Cloudy',
          'condition_icon': '⛅',
          'temperature': 32,
          'temperature_high': 34,
          'temperature_low': 25,
          'humidity': 72,
          'wind_speed_kmh': 18,
          'rainfall_mm': 0,
          'advisory': 'Good day for fertiliser application. Low rain risk.',
        },
        {
          'date': 'Fri Apr 18',
          'day': 'Fri',
          'condition': 'Thunderstorm',
          'condition_icon': '⛈️',
          'temperature': 27,
          'temperature_high': 28,
          'temperature_low': 22,
          'humidity': 92,
          'wind_speed_kmh': 35,
          'rainfall_mm': 58,
          'advisory': 'Severe weather warning. Secure equipment and crops.',
        },
        {
          'date': 'Sat Apr 19',
          'day': 'Sat',
          'condition': 'Cloudy',
          'condition_icon': '☁️',
          'temperature': 30,
          'temperature_high': 31,
          'temperature_low': 24,
          'humidity': 78,
          'wind_speed_kmh': 14,
          'rainfall_mm': 5,
          'advisory': 'Mild conditions. Light showers possible in the afternoon.',
        },
        {
          'date': 'Sun Apr 20',
          'day': 'Sun',
          'condition': 'Sunny',
          'condition_icon': '☀️',
          'temperature': 35,
          'temperature_high': 37,
          'temperature_low': 26,
          'humidity': 58,
          'wind_speed_kmh': 10,
          'rainfall_mm': 0,
          'advisory': 'Excellent week to plan outdoor farm activities.',
        },
      ];

  static List<dynamic> get _mockProducts => [
        {
          'id': 1,
          'name': 'Organic Fertiliser 50kg',
          'price': 850,
          'original_price': 1050,
          'unit': 'bag',
          'seller_name': 'AgriSupply Co.',
          'category': 'Fertilisers',
          'rating': 4.7,
          'sold': 234,
          'in_stock': true,
          'description': 'High-quality organic fertiliser rich in nitrogen and potassium. Suitable for all crop types.',
        },
        {
          'id': 2,
          'name': 'Heirloom Rice Seeds 5kg',
          'price': 320,
          'original_price': null,
          'unit': 'pack',
          'seller_name': 'SeedBank PH',
          'category': 'Seeds',
          'rating': 4.9,
          'sold': 88,
          'in_stock': true,
          'description': 'Traditional Philippine heirloom variety. High germination rate, drought-tolerant.',
        },
        {
          'id': 3,
          'name': 'Drip Irrigation Kit',
          'price': 2400,
          'original_price': 3200,
          'unit': 'set',
          'seller_name': 'IrrigaTech',
          'category': 'Equipment',
          'rating': 4.5,
          'sold': 45,
          'in_stock': true,
          'description': 'Complete drip irrigation system for up to 1 hectare. Reduces water use by 60%.',
        },
        {
          'id': 4,
          'name': 'Compost Activator',
          'price': 180,
          'original_price': null,
          'unit': 'bottle',
          'seller_name': 'GreenGrove',
          'category': 'Fertilisers',
          'rating': 4.3,
          'sold': 312,
          'in_stock': false,
          'description': 'Accelerates compost decomposition by 3x. Natural microbial formula.',
        },
        {
          'id': 5,
          'name': 'Solar Soil Sensor Kit',
          'price': 1850,
          'original_price': null,
          'unit': 'kit',
          'seller_name': 'FarmTech Solutions',
          'category': 'Equipment',
          'rating': 4.6,
          'sold': 19,
          'in_stock': true,
          'description': 'Monitor soil moisture, pH, and temperature wirelessly over your field.',
        },
        {
          'id': 6,
          'name': 'Neem Oil Pesticide 1L',
          'price': 250,
          'original_price': 290,
          'unit': 'bottle',
          'seller_name': 'NaturePest',
          'category': 'Pesticides',
          'rating': 4.8,
          'sold': 567,
          'in_stock': true,
          'description': 'Cold-pressed neem oil. Organic, safe for beneficial insects. Effective against 200+ pests.',
        },
      ];

  static List<dynamic> get _mockPosts => [
        {
          'id': 1,
          'author': 'Maria Santos',
          'author_avatar': 'MS',
          'category': 'tip',
          'title': 'Natural Pest Control Using Neem Oil',
          'content':
              'I have been using neem oil spray for three seasons now and it has dramatically reduced pest damage without harming beneficial insects. Mix 5ml neem oil with 1L water and a drop of dish soap.',
          'likes': 48,
          'comments_count': 12,
          'time': '2 hours ago',
          'liked': false,
        },
        {
          'id': 2,
          'author': 'Juan dela Cruz',
          'author_avatar': 'JC',
          'category': 'question',
          'title': 'Best time to plant corn in Visayas?',
          'content':
              'I am planning to start my corn plantation next month. Is October still a good time considering the rains? Would love advice from experienced farmers in the region.',
          'likes': 21,
          'comments_count': 9,
          'time': '5 hours ago',
          'liked': false,
        },
        {
          'id': 3,
          'author': 'Rosa Mendez',
          'author_avatar': 'RM',
          'category': 'success',
          'title': 'First organic certification achieved!',
          'content':
              'After 2 years of transitioning, our 4-hectare farm is now officially certified organic. Happy to share our journey and the paperwork process for anyone considering the same path.',
          'likes': 134,
          'comments_count': 37,
          'time': '1 day ago',
          'liked': true,
        },
        {
          'id': 4,
          'author': 'Pedro Reyes',
          'author_avatar': 'PR',
          'category': 'tip',
          'title': 'Water-saving irrigation schedule for dry season',
          'content':
              'During the hot summer months, I switch to early morning (5–7 AM) drip irrigation to reduce evaporation. Paired with mulching, I cut water usage by nearly 40% while maintaining crop health.',
          'likes': 67,
          'comments_count': 22,
          'time': '2 days ago',
          'liked': false,
        },
      ];

  // ── Fetch Methods ────────────────────────────────────────────────────────────
  Future<void> fetchDashboardStats() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/dashboard/stats'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        dashboardStats = json.decode(response.body);
        isLoading = false;
        notifyListeners();
        return;
      }
    } catch (_) {}
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

  void togglePostLike(int postId) {
    final idx = posts.indexWhere((p) => p['id'] == postId);
    if (idx == -1) return;
    final post = Map<String, dynamic>.from(posts[idx] as Map);
    post['liked'] = !(post['liked'] as bool);
    post['likes'] = (post['likes'] as int) + (post['liked'] ? 1 : -1);
    posts[idx] = post;
    notifyListeners();
  }
}