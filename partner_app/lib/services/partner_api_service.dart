import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/partner_order_model.dart';

class PartnerApiService {
  static final PartnerApiService _instance = PartnerApiService._internal();
  factory PartnerApiService() => _instance;
  PartnerApiService._internal();

  String? _authToken;
  Map<String, dynamic>? _profile;

  String? get authToken => _authToken;
  Map<String, dynamic>? get profile => _profile;
  bool get isLoggedIn => _authToken != null && _profile != null;

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
}
