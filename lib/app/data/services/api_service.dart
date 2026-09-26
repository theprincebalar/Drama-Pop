import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/series_model.dart';
import 'unlock_service.dart';

class ApiService {
  static const String liveBaseUrl = 'https://dramapop-api.genxappstudio.cloud/api';
  static const String fallbackBaseUrl = 'https://genxappstudio.cloud/dramapop/api';
  static const String localBaseUrl = 'http://10.0.2.2:5000/api';

  static const String clientApiKey = 'dramapop_app_k98234jdf092348sec';
  static const String clientHmacSecret = 'dramapop_hmac_secret_key_prod_2026';

  static String get baseUrl => liveBaseUrl;

  static List<SeriesModel> _catalogCache = [];

  // Cryptographic Request Signing & API Key Authentication
  static Map<String, String> _buildSecureHeaders(String path, {String method = 'GET'}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanPath = path.startsWith('/api') ? path : '/api$path';
    final payloadToSign = '${method.toUpperCase()}:$cleanPath:$timestamp';
    final hmacSha256 = Hmac(sha256, utf8.encode(clientHmacSecret));
    final signature = hmacSha256.convert(utf8.encode(payloadToSign)).toString();

    return {
      'Accept': 'application/json',
      'Accept-Encoding': 'gzip',
      'User-Agent': 'DramaPop-App/1.0',
      'X-DramaPop-Key': clientApiKey,
      'X-DramaPop-Timestamp': timestamp.toString(),
      'X-DramaPop-Signature': signature,
    };
  }

  static const Set<String> _excludedBrokenSeriesIds = {'57', '2020', '2118', '2119'};

  static List<SeriesModel> get cachedCatalog => _catalogCache;

  // Fallback curated cover pool for instant synchronous render on Frame 0
  static final List<SeriesModel> defaultRotatingPool = [
    SeriesModel(
      id: '6',
      title: 'Sold My Special Service',
      description: 'Billionaire romance story',
      coverUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&auto=format&fit=crop&q=80',
      genres: ['Billionaire', 'Romance'],
      episodesCount: 82,
    ),
    SeriesModel(
      id: '7',
      title: 'The Hidden Heiress',
      description: 'Revenge drama story',
      coverUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600&auto=format&fit=crop&q=80',
      genres: ['Revenge', 'Drama'],
      episodesCount: 65,
    ),
    SeriesModel(
      id: '8',
      title: 'CEO Secret Bride',
      description: 'Contract marriage',
      coverUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&auto=format&fit=crop&q=80',
      genres: ['CEO', 'Romance'],
      episodesCount: 55,
    ),
    SeriesModel(
      id: '9',
      title: 'Alpha Vow',
      description: 'Werewolf romance',
      coverUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600&auto=format&fit=crop&q=80',
      genres: ['Werewolf', 'Romance'],
      episodesCount: 60,
    ),
    SeriesModel(
      id: '10',
      title: 'Reborn Madam',
      description: 'Rebirth and revenge',
      coverUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=600&auto=format&fit=crop&q=80',
      genres: ['Revenge', 'Drama'],
      episodesCount: 70,
    ),
    SeriesModel(
      id: '11',
      title: 'Double Life of CEO',
      description: 'Urban billionaire',
      coverUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600&auto=format&fit=crop&q=80',
      genres: ['Billionaire', 'CEO'],
      episodesCount: 45,
    ),
    SeriesModel(
      id: '12',
      title: 'Flash Marriage to Richest Man',
      description: 'Sweet romance',
      coverUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=600&auto=format&fit=crop&q=80',
      genres: ['Romance', 'Billionaire'],
      episodesCount: 50,
    ),
    SeriesModel(
      id: '13',
      title: 'Tempting the Cold CEO',
      description: 'Dominant romance',
      coverUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=600&auto=format&fit=crop&q=80',
      genres: ['CEO', 'Romance'],
      episodesCount: 52,
    ),
  ];

  // Synchronously picks random dramas for instant, zero-delay paywall wheel rendering
  static List<SeriesModel> getRandomRotatingDramas({int count = 8}) {
    final pool = _catalogCache.isNotEmpty ? _catalogCache : defaultRotatingPool;
    final shuffled = List<SeriesModel>.from(pool)..shuffle();
    return shuffled.take(count).toList();
  }

  // Load the full verified catalog from assets immediately
  static Future<List<SeriesModel>> loadBundledCatalog() async {
    if (_catalogCache.isNotEmpty) return _catalogCache;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/catalog.json');
      final list = json.decode(jsonStr) as List? ?? [];
      _catalogCache = list
          .map((item) => SeriesModel.fromJson(Map<String, dynamic>.from(item)))
          .where((s) => !_excludedBrokenSeriesIds.contains(s.id) && s.episodesCount > 0 && s.status != 'Hidden' && s.status != 'hidden')
          .toList();
      debugPrint(' Loaded ${_catalogCache.length} verified series from catalog asset.');
    } catch (e) {
      debugPrint('Error loading bundled catalog: $e');
    }
    return _catalogCache;
  }

  // Fast Progressive Paginated Fetch with instant offline fallback
  static Future<List<SeriesModel>> getSeries({String? genre, String? search, int page = 1, int limit = 24}) async {
    // 1. Try Live Network API with Cryptographic Signing
    try {
      var url = '$baseUrl/series?page=$page&limit=$limit';
      if (genre != null && genre != 'All') {
        url += '&genre=${Uri.encodeComponent(genre)}';
      }
      if (search != null && search.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(search)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _buildSecureHeaders('/series'),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['series'] ?? data['data']) as List? ?? [];
        if (list.isNotEmpty) {
          final result = list
              .map((item) => SeriesModel.fromJson(Map<String, dynamic>.from(item)))
              .where((s) => !_excludedBrokenSeriesIds.contains(s.id) && s.episodesCount > 0)
              .toList();
          return result;
        }
      }
    } catch (e) {
      debugPrint('API getSeries network fallback: $e');
    }

    // 2. Offline / Instant Bundled Fallback (All 379 series)
    final catalog = await loadBundledCatalog();
    var filtered = catalog;

    if (genre != null && genre != 'All') {
      final gLower = genre.toLowerCase();
      filtered = filtered.where((s) {
        final matchGenre = s.genres.any((g) => g.toLowerCase().contains(gLower));
        final matchTitle = s.title.toLowerCase().contains(gLower);
        return matchGenre || matchTitle;
      }).toList();
    }

    if (search != null && search.trim().isNotEmpty) {
      final qLower = search.trim().toLowerCase();
      filtered = filtered.where((s) {
        return s.title.toLowerCase().contains(qLower) ||
               s.description.toLowerCase().contains(qLower) ||
               s.genres.any((g) => g.toLowerCase().contains(qLower));
      }).toList();
    }

    final startIndex = (page - 1) * limit;
    if (startIndex >= filtered.length) return [];
    final endIndex = (startIndex + limit).clamp(0, filtered.length);
    return filtered.sublist(startIndex, endIndex);
  }

  // Fetch full episode streams for a specific drama on demand
  static Future<SeriesModel?> getSeriesById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/series/$id'),
        headers: _buildSecureHeaders('/series/$id'),
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final item = data['data'] ?? data;
        if (item != null) {
          return SeriesModel.fromJson(Map<String, dynamic>.from(item));
        }
      }
    } catch (e) {
      debugPrint('API Error (getSeriesById): $e');
    }

    final catalog = await loadBundledCatalog();
    return catalog.firstWhere((s) => s.id == id, orElse: () => catalog.isNotEmpty ? catalog.first : _getFallbackDrama());
  }

  // Submit user issue/content report to backend
  static Future<bool> submitReport({
    required String seriesId,
    String? seriesTitle,
    int? episodeNumber,
    required String reason,
    String? description,
    String? deviceInfo,
  }) async {
    try {
      final payload = json.encode({
        'seriesId': seriesId,
        'seriesTitle': seriesTitle,
        'episodeNumber': episodeNumber,
        'reason': reason,
        'description': description ?? '',
        'deviceInfo': deviceInfo ?? 'DramaPop Mobile Client',
      });

      final response = await http.post(
        Uri.parse('$baseUrl/reports'),
        headers: {
          ..._buildSecureHeaders('/reports', method: 'POST'),
          'Content-Type': 'application/json',
        },
        body: payload,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Report submitted successfully for Series $seriesId (Ep $episodeNumber)');
        return true;
      }
    } catch (e) {
      debugPrint('Error submitting report to API: $e');
    }
    // Return true for user feedback experience even if network fails (optimistic UX)
    return true;
  }

  // Fetch dynamic coin packages configured in Admin Panel
  static Future<List<CoinPackage>> getCoinPackages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/coin-packages'),
        headers: _buildSecureHeaders('/coin-packages'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['packages'] ?? data['data']) as List? ?? [];
        if (list.isNotEmpty) {
          return list.map((item) {
            final m = Map<String, dynamic>.from(item);
            return CoinPackage(
              id: m['id']?.toString() ?? 'coins_100',
              coins: (m['coins'] as num?)?.toInt() ?? 100,
              bonusCoins: (m['bonusCoins'] as num?)?.toInt() ?? 0,
              price: (m['price'] as num?)?.toDouble() ?? 0.99,
              priceFormatted: m['priceFormatted']?.toString() ?? '\$0.99',
              isPopular: m['isPopular'] == true,
              isBestValue: m['isBestValue'] == true,
              rcProductId: m['rcProductId']?.toString() ?? 'dramapop_${m['id'] ?? 'coins'}',
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Note loading coin packages from API: $e');
    }
    return [];
  }

  // Fetch Global App Settings (In-App Review, Config) configured in Admin Panel
  static Future<Map<String, dynamic>?> getAppSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/app-settings'),
        headers: _buildSecureHeaders('/app-settings'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] != null ? Map<String, dynamic>.from(data['data']) : Map<String, dynamic>.from(data);
      }
    } catch (e) {
      debugPrint('Note loading app settings from API: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> syncCoinBalance({
    required String deviceId,
    required int currentCoins,
    int? purchasedCoins,
    int? usedCoins,
  }) async {
    try {
      final url = '$baseUrl/user/sync-coins';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          ..._buildSecureHeaders('/user/sync-coins', method: 'POST'),
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'deviceId': deviceId,
          'currentCoins': currentCoins,
          'purchasedCoins': purchasedCoins ?? 0,
          'usedCoins': usedCoins ?? 0,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Sync coin balance note: $e');
    }
    return null;
  }

  static SeriesModel _getFallbackDrama() {
    return SeriesModel(
      id: '6',
      title: 'After I Sold My Special Service to a Billionaire',
      description: 'Elizabeth disguises herself to deal with a date, leading to an accidental meeting with the richest billionaire.',
      coverUrl: 'https://dramapop-admin.genxappstudio.cloud/covers/6.webp',
      genres: ['Billionaire', 'Romance', 'CEO'],
      episodesCount: 82,
      views: 4115472,
      rating: 4.9,
    );
  }
}