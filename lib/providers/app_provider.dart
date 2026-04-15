import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AppProvider with ChangeNotifier {
  // ── Services ──────────────────────────────────────────────────────────────────
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // ── Auth / User ───────────────────────────────────────────────────────────────
  UserModel? currentUser;
  bool get isLoggedIn => currentUser != null;

  // ── Loading / Error ───────────────────────────────────────────────────────────
  bool isLoading = false;
  String? error;

  // ── Data State ────────────────────────────────────────────────────────────────
  Map<String, dynamic>? dashboardStats;
  List<dynamic> crops = [];
  List<dynamic> alerts = [];
  List<dynamic> weather = [];
  List<dynamic> products = [];
  List<dynamic> posts = [];

  bool _seedLoaded = false;

  // ── Constructor: listen to Firebase auth changes ──────────────────────────────
  AppProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      currentUser = null;
      _clearData();
      notifyListeners();
      return;
    }

    // Load user profile from Firestore
    final userData = await _firestoreService.getUser(firebaseUser.uid);
    if (userData != null) {
      currentUser = UserModel.fromMap({'uid': firebaseUser.uid, ...userData});
    } else {
      // Fallback: build from Firebase Auth user
      currentUser = UserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? firebaseUser.email!.split('@').first,
        email: firebaseUser.email ?? '',
      );
    }
    notifyListeners();
    _loadAllData();
  }

  void _clearData() {
    dashboardStats = null;
    crops = [];
    alerts = [];
    weather = [];
    products = [];
    posts = [];
    _seedLoaded = false;
  }

  // ── Auth Actions ──────────────────────────────────────────────────────────────

  /// Sign up → saves user in Firestore → auth-state listener fires _onAuthStateChanged
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _authService.signUp(name: name, email: email, password: password);
      isLoading = false;
      notifyListeners();
      return null; // success
    } on FirebaseAuthException catch (e) {
      error = _friendlyAuthError(e.code);
      isLoading = false;
      notifyListeners();
      return error;
    } catch (e) {
      error = 'An unexpected error occurred.';
      isLoading = false;
      notifyListeners();
      return error;
    }
  }

  /// Sign in with email + password
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _authService.signIn(email: email, password: password);
      isLoading = false;
      notifyListeners();
      return null; // success
    } on FirebaseAuthException catch (e) {
      error = _friendlyAuthError(e.code);
      isLoading = false;
      notifyListeners();
      return error;
    } catch (e) {
      error = 'An unexpected error occurred.';
      isLoading = false;
      notifyListeners();
      return error;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// Send a password-reset e-mail
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordReset(email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyAuthError(e.code);
    }
  }

  // ── Data Loading ──────────────────────────────────────────────────────────────

  Future<void> _loadAllData() async {
    if (_seedLoaded) return;
    _seedLoaded = true;

    // Seed marketplace products to Firestore if empty
    await _firestoreService.seedProductsIfEmpty(
        _mockProducts.cast<Map<String, dynamic>>());

    await fetchDashboardStats();
    await fetchAlerts();
    await fetchCrops();
    await fetchWeather();
    await fetchProducts();
    await fetchCommunityPosts();
  }

  Future<void> fetchDashboardStats() async {
    isLoading = true;
    notifyListeners();
    // Derive stats from user farm data; fall back to mock while real data loads
    if (currentUser != null && currentUser!.farm.isNotEmpty) {
      final farm = currentUser!.farm;
      dashboardStats = {
        'sustainability_score': farm['sustainabilityScore'] ?? 78,
        'total_crops': farm['totalCrops'] ?? crops.length,
        'healthy_crops': crops.where((c) =>
            c['health_status'] == 'good' ||
            c['health_status'] == 'excellent').length,
        'alerts_count': alerts.length,
        'total_area_hectares': farm['totalAreaHectares'] ?? 15.5,
        'water_usage_liters': farm['waterUsageLiters'] ?? 12400,
        'carbon_saved_kg': farm['carbonSavedKg'] ?? 320,
      };
    } else {
      dashboardStats = _mockDashboard;
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAlerts() async {
    // Alerts are static / advisory for now; can wire to Firestore later
    alerts = _mockAlerts;
    notifyListeners();
  }

  Future<void> fetchCrops() async {
    if (currentUser == null) {
      crops = _mockCrops;
      notifyListeners();
      return;
    }
    // Subscribe to real-time Firestore crops; convert stream to one-shot list
    try {
      final snap = await _firestoreService
          .cropsStream(currentUser!.uid)
          .first
          .timeout(const Duration(seconds: 6));
      crops = snap.isEmpty ? _mockCrops : snap;
    } catch (_) {
      crops = _mockCrops;
    }
    notifyListeners();
  }

  Future<void> fetchWeather() async {
    weather = _mockWeather;
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    try {
      final snap = await _firestoreService
          .productsStream()
          .first
          .timeout(const Duration(seconds: 6));
      products = snap.isEmpty ? _mockProducts : snap;
    } catch (_) {
      products = _mockProducts;
    }
    notifyListeners();
  }

  Future<void> fetchCommunityPosts() async {
    try {
      final snap = await _firestoreService
          .communityPostsStream()
          .first
          .timeout(const Duration(seconds: 6));
      posts = snap.isEmpty ? _mockPosts : snap;
    } catch (_) {
      posts = _mockPosts;
    }
    notifyListeners();
  }

  // ── Crop CRUD ─────────────────────────────────────────────────────────────────

  Future<void> addCrop(Map<String, dynamic> crop) async {
    if (currentUser == null) return;
    await _firestoreService.addCrop(currentUser!.uid, crop);
    await fetchCrops();
  }

  Future<void> updateCrop(String cropId, Map<String, dynamic> data) async {
    if (currentUser == null) return;
    await _firestoreService.updateCrop(currentUser!.uid, cropId, data);
    await fetchCrops();
  }

  Future<void> deleteCrop(String cropId) async {
    if (currentUser == null) return;
    await _firestoreService.deleteCrop(currentUser!.uid, cropId);
    await fetchCrops();
  }

  // ── Post Interactions ─────────────────────────────────────────────────────────

  Future<void> togglePostLike(dynamic postId) async {
    final idx = posts.indexWhere((p) => p['id'] == postId);
    if (idx == -1) return;
    final post = Map<String, dynamic>.from(posts[idx] as Map);
    final liked = post['liked'] as bool? ?? false;
    final likes = post['likes'] as int? ?? 0;

    // Optimistic local update
    post['liked'] = !liked;
    post['likes'] = liked ? likes - 1 : likes + 1;
    posts[idx] = post;
    notifyListeners();

    // Push to Firestore if post has a real Firestore id (String)
    if (postId is String) {
      try {
        await _firestoreService.togglePostLike(postId, liked, likes);
      } catch (_) {/* silent fallback to local state */}
    }
  }

  Future<void> addCommunityPost(Map<String, dynamic> post) async {
    await _firestoreService.addPost(post);
    await fetchCommunityPosts();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // ── Mock Data (fallback when Firestore is empty) ──────────────────────────────

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
          'id': '1',
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
          'id': '2',
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
          'id': '3',
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
          'id': '4',
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
          'name': 'Organic Fertiliser 50kg',
          'price': 850,
          'original_price': 1050,
          'unit': 'bag',
          'seller_name': 'AgriSupply Co.',
          'category': 'Fertilisers',
          'rating': 4.7,
          'sold': 234,
          'in_stock': true,
          'description':
              'High-quality organic fertiliser rich in nitrogen and potassium.',
        },
        {
          'name': 'Heirloom Rice Seeds 5kg',
          'price': 320,
          'original_price': null,
          'unit': 'pack',
          'seller_name': 'SeedBank PH',
          'category': 'Seeds',
          'rating': 4.9,
          'sold': 88,
          'in_stock': true,
          'description':
              'Traditional Philippine heirloom variety. High germination rate, drought-tolerant.',
        },
        {
          'name': 'Drip Irrigation Kit',
          'price': 2400,
          'original_price': 3200,
          'unit': 'set',
          'seller_name': 'IrrigaTech',
          'category': 'Equipment',
          'rating': 4.5,
          'sold': 45,
          'in_stock': true,
          'description':
              'Complete drip irrigation system for up to 1 hectare. Reduces water use by 60%.',
        },
        {
          'name': 'Compost Activator',
          'price': 180,
          'original_price': null,
          'unit': 'bottle',
          'seller_name': 'GreenGrove',
          'category': 'Fertilisers',
          'rating': 4.3,
          'sold': 312,
          'in_stock': false,
          'description': 'Accelerates compost decomposition by 3x.',
        },
        {
          'name': 'Solar Soil Sensor Kit',
          'price': 1850,
          'original_price': null,
          'unit': 'kit',
          'seller_name': 'FarmTech Solutions',
          'category': 'Equipment',
          'rating': 4.6,
          'sold': 19,
          'in_stock': true,
          'description':
              'Monitor soil moisture, pH, and temperature wirelessly over your field.',
        },
        {
          'name': 'Neem Oil Pesticide 1L',
          'price': 250,
          'original_price': 290,
          'unit': 'bottle',
          'seller_name': 'NaturePest',
          'category': 'Pesticides',
          'rating': 4.8,
          'sold': 567,
          'in_stock': true,
          'description':
              'Cold-pressed neem oil. Organic, safe for beneficial insects.',
        },
      ];

  static List<dynamic> get _mockPosts => [
        {
          'id': '1',
          'author': 'Maria Santos',
          'author_avatar': 'MS',
          'category': 'tip',
          'title': 'Natural Pest Control Using Neem Oil',
          'content':
              'I have been using neem oil spray for three seasons now and it has dramatically reduced pest damage without harming beneficial insects.',
          'likes': 48,
          'comments_count': 12,
          'time': '2 hours ago',
          'liked': false,
        },
        {
          'id': '2',
          'author': 'Juan dela Cruz',
          'author_avatar': 'JC',
          'category': 'question',
          'title': 'Best time to plant corn in Visayas?',
          'content':
              'I am planning to start my corn plantation next month. Is October still a good time considering the rains?',
          'likes': 21,
          'comments_count': 9,
          'time': '5 hours ago',
          'liked': false,
        },
        {
          'id': '3',
          'author': 'Rosa Mendez',
          'author_avatar': 'RM',
          'category': 'success',
          'title': 'First organic certification achieved!',
          'content':
              'After 2 years of transitioning, our 4-hectare farm is now officially certified organic.',
          'likes': 134,
          'comments_count': 37,
          'time': '1 day ago',
          'liked': true,
        },
        {
          'id': '4',
          'author': 'Pedro Reyes',
          'author_avatar': 'PR',
          'category': 'tip',
          'title': 'Water-saving irrigation schedule for dry season',
          'content':
              'During the hot summer months, I switch to early morning drip irrigation to reduce evaporation.',
          'likes': 67,
          'comments_count': 22,
          'time': '2 days ago',
          'liked': false,
        },
      ];
}