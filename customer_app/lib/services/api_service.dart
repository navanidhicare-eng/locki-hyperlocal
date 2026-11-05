import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/category_model.dart';
import '../models/service_model.dart';
import '../models/order_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;
  Map<String, dynamic>? currentUser;

  bool get isLoggedIn => _authToken != null;

  // Custom customer login
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier.trim(),
          'password': password.trim(),
          'role': 'customer',
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        _authToken = data['token'];
        currentUser = data['user'];
        return {'success': true, 'message': data['message'], 'user': currentUser};
      }
      return {'success': false, 'message': data['message'] ?? 'Login failed. Please verify credentials.'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: Could not reach server.'};
    }
  }

  // Customer registration
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    String address = 'Hyderabad',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'phone': phone.trim(),
          'email': email.trim().isEmpty ? '${phone.trim()}@customer.loki' : email.trim(),
          'password': password.trim(),
          'role': 'customer',
          'address': address.trim().isEmpty ? 'Hyderabad' : address.trim(),
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 201 && data['success'] == true) {
        _authToken = data['token'];
        currentUser = data['user'];
        return {'success': true, 'message': data['message'], 'user': currentUser};
      }
      return {'success': false, 'message': data['message'] ?? 'Registration failed.'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: Could not reach server.'};
    }
  }

  void logout() {
    _authToken = null;
    currentUser = null;
  }

  // Authenticate demo customer if not logged in
  Future<bool> ensureCustomerAuth() async {
    if (_authToken != null) return true;
    final res = await login(identifier: 'customer@loki.com', password: 'customer123');
    return res['success'] == true;
  }

  // Fetch active promotions & ads from Super Admin backend
  Future<Map<String, dynamic>> fetchPromotions() async {
    try {
      final res = await http.get(Uri.parse('${AppConstants.baseUrl}/promotions?active=true'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['grouped'] != null) {
          return Map<String, dynamic>.from(data['grouped']);
        }
      }
    } catch (e) {
      print('Fetch promotions error: $e');
    }
    return {};
  }

  // Fetch all service categories
  Future<List<ServiceCategory>> fetchCategories() async {
    try {
      final res = await http.get(Uri.parse('${AppConstants.baseUrl}/categories'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['categories'] as List;
        return list.map((c) => ServiceCategory.fromJson(c)).toList();
      }
    } catch (e) {
      print('Fetch categories error: $e');
    }
    return [];
  }

  // Fetch services for category
  Future<List<ServiceItem>> fetchServices({String? categoryId}) async {
    try {
      String url = '${AppConstants.baseUrl}/services';
      if (categoryId != null) {
        url += '?categoryId=$categoryId';
      }
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['services'] as List;
        return list.map((s) => ServiceItem.fromJson(s)).toList();
      }
    } catch (e) {
      print('Fetch services error: $e');
    }
    return [];
  }

  // Place a new booking
  Future<OrderModel?> placeOrder({
    required String serviceId,
    required String customerAddress,
    required String paymentMethod,
    String notes = '',
  }) async {
    await ensureCustomerAuth();
    try {
      final res = await http.post(
        Uri.parse('${AppConstants.baseUrl}/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'serviceId': serviceId,
          'customerAddress': customerAddress,
          'paymentMethod': paymentMethod,
          'notes': notes,
        }),
      );
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return OrderModel.fromJson(data['order']);
      }
    } catch (e) {
      print('Place order error: $e');
    }
    return null;
  }

  // Fetch verified providers in a category (with phone & location)
  Future<List<Map<String, dynamic>>> fetchProvidersByCategory(String categoryId, {String? mandal}) async {
    try {
      String url = '${AppConstants.baseUrl}/providers/by-category/$categoryId';
      if (mandal != null && mandal.isNotEmpty) {
        url += '?mandal=${Uri.encodeComponent(mandal)}';
      }
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['providers'] as List?) ?? [];
        return list.map((p) => p as Map<String, dynamic>).toList();
      }
    } catch (e) {
      print('Fetch providers by category error: $e');
    }
    return [];
  }

  // Quick Service Request (Category -> Sub -> Child -> Problem Description -> Dispatch)
  Future<Map<String, dynamic>?> submitQuickRequest({
    required String categoryId,
    String? subCategoryId,
    String? childTaskId,
    String? childTaskName,
    required String problemDescription,
    required String customerAddress,
    required String customerMandal,
    String? customerPhone,
    String? customerName,
    String? providerId,
    String? paymentMethod,
    double? amount,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConstants.baseUrl}/orders/quick-request'),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'categoryId': categoryId,
          'subCategoryId': subCategoryId,
          'childTaskId': childTaskId,
          'childTaskName': childTaskName,
          'problemDescription': problemDescription,
          'customerAddress': customerAddress,
          'customerMandal': customerMandal,
          'customerPhone': customerPhone ?? currentUser?['phone'] ?? '9010737882',
          'customerName': customerName ?? currentUser?['name'] ?? 'Customer',
          'providerId': providerId,
          'paymentMethod': paymentMethod ?? 'Cash on Service / UPI',
          'amount': amount ?? 299,
        }),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data;
      }
    } catch (e) {
      print('Submit quick request error: $e');
    }
    return null;
  }

  // Fetch customer orders
  Future<List<OrderModel>> fetchMyOrders() async {
    try {
      final phone = currentUser?['phone'] ?? '9010737882';
      final res = await http.get(
        Uri.parse('${AppConstants.baseUrl}/orders/my?phone=${Uri.encodeComponent(phone)}'),
        headers: {
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['orders'] as List?) ?? [];
        return list.map((o) => OrderModel.fromJson(o)).toList();
      }
    } catch (e) {
      print('Fetch my orders error: $e');
    }
    return [];
  }
}
