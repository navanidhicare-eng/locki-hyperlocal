import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/partner_order_model.dart';

class PartnerApiService {
  static final PartnerApiService _instance = PartnerApiService._internal();
  factory PartnerApiService() => _instance;
  PartnerApiService._internal();

  static const String _keyToken = 'locki_partner_token';
  static const String _keyProfile = 'locki_partner_profile';

  String? _authToken;
  Map<String, dynamic>? _profile;

  String? get authToken => _authToken;
  Map<String, dynamic>? get profile => _profile;
  bool get isLoggedIn => _authToken != null && _authToken!.isNotEmpty && _profile != null;

  // Load saved partner session on startup
  Future<void> initAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);
      final profileStr = prefs.getString(_keyProfile);
      if (token != null && token.isNotEmpty && profileStr != null && profileStr.isNotEmpty) {
        _authToken = token;
        _profile = jsonDecode(profileStr);
      }
    } catch (_) {}
  }

  Future<void> _persistAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_authToken != null) {
        await prefs.setString(_keyToken, _authToken!);
      }
      if (_profile != null) {
        await prefs.setString(_keyProfile, jsonEncode(_profile));
      }
    } catch (_) {}
  }

  Future<void> _clearPersistedAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyProfile);
    } catch (_) {}
  }

  // Authenticate partner with Phone/Mobile and Password
  Future<Map<String, dynamic>> loginPartner({
    required String phone,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${PartnerConstants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone.trim(),
          'password': password,
          'role': 'provider',
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        _authToken = data['token'];
        _profile = data['user'];
        await _persistAuth();
        return {'success': true, 'message': 'Login successful!'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed. Please check your credentials.'};
      }
    } catch (e) {
      print('Partner login error: $e');
      return {'success': false, 'message': 'Network connection error: $e'};
    }
  }

  // Register new partner account
  Future<Map<String, dynamic>> registerPartner({
    required String name,
    required String phone,
    required String password,
    required String category,
    String? serviceName,
    String? aadhaarNumber,
    String? vehicleNumber,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${PartnerConstants.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'phone': phone.trim(),
          'password': password,
          'category': category,
          'serviceName': (serviceName != null && serviceName.trim().isNotEmpty) ? serviceName.trim() : 'Service Specialist',
          'aadhaarNumber': aadhaarNumber?.trim() ?? 'PENDING_UPLOAD',
          'vehicleNumber': vehicleNumber?.trim() ?? 'N/A',
          'role': 'provider',
        }),
      );
      final data = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        _authToken = data['token'];
        _profile = data['user'];
        await _persistAuth();
        return {'success': true, 'message': 'Account created successfully!'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registration failed.'};
      }
    } catch (e) {
      print('Partner register error: $e');
      return {'success': false, 'message': 'Network connection error: $e'};
    }
  }

  // Logout partner
  void logout() {
    _authToken = null;
    _profile = null;
    _clearPersistedAuth();
  }

  // Update Partner Profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final res = await http.put(
        Uri.parse('${PartnerConstants.baseUrl}/providers/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode(profileData),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        _profile = data['provider'];
        return {'success': true, 'message': data['message'] ?? 'Profile updated successfully!'};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to update profile'};
    } catch (e) {
      print('Profile update error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Fetch Partner Profile
  Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final res = await http.get(
        Uri.parse('${PartnerConstants.baseUrl}/providers/profile'),
        headers: {
          'Authorization': 'Bearer $_authToken',
        },
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        _profile = data['provider'];
        return _profile;
      }
      return null;
    } catch (e) {
      print('Fetch profile error: $e');
      return null;
    }
  }

  // Fetch Locations (Districts -> Mandals -> Villages) configured in Admin Location Management
  Future<List<dynamic>> fetchLocations() async {
    try {
      final res = await http.get(Uri.parse('${PartnerConstants.baseUrl}/locations'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['locations'] is List) {
          return data['locations'];
        }
      }
    } catch (e) {
      print('Fetch locations error: $e');
    }
    return [];
  }

  // Fetch Service Categories & Subcategories configured in Admin Categories Management
  Future<List<dynamic>> fetchCategories() async {
    try {
      final res = await http.get(Uri.parse('${PartnerConstants.baseUrl}/categories'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['categories'] is List) {
          return data['categories'];
        }
      }
    } catch (e) {
      print('Fetch categories error: $e');
    }
    return [];
  }

  // Toggle online status
  Future<bool?> toggleOnline(bool targetStatus) async {
    if (_authToken == null) return null;
    try {
      final res = await http.post(
        Uri.parse('${PartnerConstants.baseUrl}/providers/toggle-online'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({'isOnline': targetStatus}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (_profile != null) {
          _profile!['isOnline'] = data['isOnline'];
        }
        return data['isOnline'];
      }
    } catch (e) {
      print('Toggle online error: $e');
    }
    return null;
  }

  // Fetch partner orders
  Future<List<PartnerOrder>> fetchPartnerOrders() async {
    if (_authToken == null) return [];
    try {
      final res = await http.get(
        Uri.parse('${PartnerConstants.baseUrl}/providers/my-orders'),
        headers: {
          'Authorization': 'Bearer $_authToken',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['orders'] as List;
        return list.map((o) => PartnerOrder.fromJson(o)).toList();
      }
    } catch (e) {
      print('Fetch partner orders error: $e');
    }
    return [];
  }

  // Update order status (ACCEPT, START with OTP, COMPLETE)
  Future<bool> updateOrderStatus(String orderId, String status, {String? otp}) async {
    if (_authToken == null) return false;
    try {
      final res = await http.patch(
        Uri.parse('${PartnerConstants.baseUrl}/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'status': status,
          if (otp != null) 'otp': otp,
        }),
      );
      if (res.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Update order status error: $e');
    }
    return false;
  }

  // Multi-Business Switcher: Fetch all business profiles for this partner
  Future<Map<String, dynamic>> fetchBusinesses() async {
    try {
      final pId = _profile?['id'] ?? 'prv_76fcc359';
      final res = await http.get(
        Uri.parse('${PartnerConstants.baseUrl}/providers/businesses/public/$pId'),
        headers: {
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          return {
            'activeBusinessId': data['activeBusinessId'],
            'businesses': List<Map<String, dynamic>>.from(data['businesses'] ?? []),
          };
        }
      }
    } catch (e) {
      print('Fetch businesses error: $e');
    }
    return {'activeBusinessId': null, 'businesses': <Map<String, dynamic>>[]};
  }

  // Multi-Business: Request a new business profile (Pending Admin Approval)
  Future<bool> requestNewBusiness(Map<String, dynamic> bizData) async {
    try {
      final pId = _profile?['id'] ?? 'prv_76fcc359';
      final payload = {
        'providerId': pId,
        ...bizData,
      };
      final res = await http.post(
        Uri.parse('${PartnerConstants.baseUrl}/providers/businesses/public/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
    } catch (e) {
      print('Request new business error: $e');
    }
    return false;
  }

  // Multi-Business: Switch active business
  Future<bool> switchActiveBusiness(String businessId) async {
    try {
      final pId = _profile?['id'] ?? 'prv_76fcc359';
      final res = await http.post(
        Uri.parse('${PartnerConstants.baseUrl}/providers/businesses/public/switch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'providerId': pId, 'businessId': businessId}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
    } catch (e) {
      print('Switch active business error: $e');
    }
    return false;
  }

  // Multi-Business: Update business profile details
  Future<bool> updateBusinessProfile(String businessId, Map<String, dynamic> updateData) async {
    try {
      final pId = _profile?['id'] ?? 'prv_76fcc359';
      final payload = {
        'providerId': pId,
        ...updateData,
      };
      final res = await http.put(
        Uri.parse('${PartnerConstants.baseUrl}/providers/businesses/public/$businessId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
    } catch (e) {
      print('Update business profile error: $e');
    }
    return false;
  }

  // Multi-Business: Delete closed business profile
  Future<bool> deleteBusinessProfile(String businessId) async {
    try {
      final pId = _profile?['id'] ?? 'prv_76fcc359';
      final res = await http.delete(
        Uri.parse('${PartnerConstants.baseUrl}/providers/businesses/public/$businessId?providerId=$pId'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
    } catch (e) {
      print('Delete business profile error: $e');
    }
    return false;
  }

  // Rental Inventory: Fetch items posted by this partner
  Future<List<Map<String, dynamic>>> fetchPartnerRentals({String? businessId}) async {
    try {
      final phone = _profile?['phone'] ?? '9010737882';
      String url = '${PartnerConstants.baseUrl}/rentals/user/$phone?role=partner';
      if (businessId != null && businessId.isNotEmpty) {
        url += '&businessId=$businessId';
      }
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      print('Fetch partner rentals error: $e');
    }
    return [];
  }

  // Rental Inventory: Create new rental item
  Future<bool> createRentalItem(Map<String, dynamic> itemData) async {
    try {
      final pId = _profile?['id'] ?? 'prv_76fcc359';
      final phone = _profile?['phone'] ?? '9010737882';
      final name = _profile?['name'] ?? 'Gandepalli Prasad';

      final payload = {
        'postedBy': 'partner',
        'providerId': pId,
        'userName': name,
        'phone': phone,
        'whatsappPhone': phone,
        'listingType': 'store',
        ...itemData,
      };

      final res = await http.post(
        Uri.parse('${PartnerConstants.baseUrl}/rentals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
    } catch (e) {
      print('Create rental item error: $e');
    }
    return false;
  }

  // Rental Inventory: Toggle status available vs rented
  Future<bool> toggleRentalStatus(String rentalId, String targetStatus) async {
    try {
      final res = await http.put(
        Uri.parse('${PartnerConstants.baseUrl}/rentals/$rentalId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': targetStatus}),
      );
      if (res.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Toggle rental status error: $e');
    }
    return false;
  }

  // Rental Inventory: Update rental item details
  Future<bool> updateRentalItem(String rentalId, Map<String, dynamic> updateData) async {
    try {
      final res = await http.put(
        Uri.parse('${PartnerConstants.baseUrl}/rentals/$rentalId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );
      if (res.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Update rental item error: $e');
    }
    return false;
  }

  // Rental Inventory: Delete rental item
  Future<bool> deleteRentalItem(String rentalId) async {
    try {
      final res = await http.delete(
        Uri.parse('${PartnerConstants.baseUrl}/rentals/$rentalId'),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Delete rental item error: $e');
      return false;
    }
  }

  // Shop / Retail Products: Fetch items for this store
  Future<List<Map<String, dynamic>>> fetchPartnerProducts({String? businessId}) async {
    try {
      final phone = _profile?['phone'] ?? '9010737882';
      String url = '${PartnerConstants.baseUrl}/products/user/$phone';
      if (businessId != null && businessId.isNotEmpty) {
        url += '?businessId=$businessId';
      }
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['products'] is List) {
          return List<Map<String, dynamic>>.from(data['products']);
        }
      }
    } catch (e) {
      print('Fetch partner products error: $e');
    }
    return [];
  }

  // Shop / Retail Products: Add product
  Future<Map<String, dynamic>> createShopProduct(Map<String, dynamic> prodData) async {
    try {
      final pId = _profile?['id'] ?? 'prv_76fcc359';
      final phone = _profile?['phone'] ?? '9010737882';

      final payload = {
        'providerId': pId,
        'phone': phone,
        ...prodData,
      };

      final res = await http.post(
        Uri.parse('${PartnerConstants.baseUrl}/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      final data = jsonDecode(res.body);
      return data;
    } catch (e) {
      print('Create shop product error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Shop / Retail Products: Update product
  Future<bool> updateShopProduct(String productId, Map<String, dynamic> updateData) async {
    try {
      final res = await http.put(
        Uri.parse('${PartnerConstants.baseUrl}/products/$productId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Update shop product error: $e');
      return false;
    }
  }

  // Shop / Retail Products: Delete product
  Future<bool> deleteShopProduct(String productId) async {
    try {
      final res = await http.delete(
        Uri.parse('${PartnerConstants.baseUrl}/products/$productId'),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Delete shop product error: $e');
      return false;
    }
  }
}
