import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://10.15.175.232:8000/api';
  final storage = const FlutterSecureStorage();

  // ---------- AUTH ----------

  Future<Map<String, dynamic>> sendOtp(String whatsappNumber, {required String purpose}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'whatsapp_number': whatsappNumber, 'purpose': purpose}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyOtp(String whatsappNumber, String otpCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'whatsapp_number': whatsappNumber, 'otp_code': otpCode}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> registerDealer({
    required String whatsappNumber,
    required String name,
    required String shopName,
    required String address,
    required int taluka,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'whatsapp_number': whatsappNumber,
        'name': name,
        'shop_name': shopName,
        'address': address,
        'taluka': taluka,
      }),
    );
    final data = await _handleResponse(response);
    await _storeTokens(data);
    return data;
  }

  Future<Map<String, dynamic>> login(String whatsappNumber, String otpCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'whatsapp_number': whatsappNumber, 'otp_code': otpCode}),
    );
    final data = await _handleResponse(response);
    await _storeTokens(data);
    return data;
  }

  Future<void> _storeTokens(Map<String, dynamic> data) async {
    await storage.write(key: 'access_token', value: data['access']);
    await storage.write(key: 'refresh_token', value: data['refresh']);
    await storage.write(key: 'dealer_id', value: data['dealer_id'].toString());
  }

  Future<String?> getAccessToken() async {
    return storage.read(key: 'access_token');
  }

  Future<int?> getDealerId() async {
    final value = await storage.read(key: 'dealer_id');
    return value != null ? int.tryParse(value) : null;
  }

  Future<bool> _refreshAccessToken() async {
    final refreshToken = await storage.read(key: 'refresh_token');
    if (refreshToken == null) return false;
    final response = await http.post(
      Uri.parse('$baseUrl/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await storage.write(key: 'access_token', value: data['access']);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await storage.deleteAll();
  }

  // ---------- LOCATION DROPDOWNS ----------

  Future<List<dynamic>> getStates() async {
    final response = await http.get(Uri.parse('$baseUrl/states/'));
    final data = await _handleResponse(response);
    return data as List<dynamic>;
  }

  Future<List<dynamic>> getDistricts(int stateId) async {
    final response = await http.get(Uri.parse('$baseUrl/districts/?state=$stateId'));
    final data = await _handleResponse(response);
    return data as List<dynamic>;
  }

  Future<List<dynamic>> getTalukas(int districtId) async {
    final response = await http.get(Uri.parse('$baseUrl/talukas/?district=$districtId'));
    final data = await _handleResponse(response);
    return data as List<dynamic>;
  }

  // ---------- LICENCE DROPDOWNS ----------

  Future<List<dynamic>> getLicenceCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/licence-categories/'));
    final data = await _handleResponse(response);
    return data as List<dynamic>;
  }

  Future<List<dynamic>> getLicenceTypes(int categoryId) async {
    final response = await http.get(Uri.parse('$baseUrl/licence-types/?category=$categoryId'));
    final data = await _handleResponse(response);
    return data as List<dynamic>;
  }

  Future<List<dynamic>> getFertilizerTypes() async {
    final response = await http.get(Uri.parse('$baseUrl/fertilizer-types/'));
    final data = await _handleResponse(response);
    return data as List<dynamic>;
  }

  // ---------- AUTHENTICATED REQUESTS ----------

  Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getMyLicences() async {
    var response = await http.get(
      Uri.parse('$baseUrl/licences/'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        response = await http.get(
          Uri.parse('$baseUrl/licences/'),
          headers: await _authHeaders(),
        );
      }
    }
    final data = await _handleResponse(response);
    return data as List<dynamic>;
  }

  Future<List<dynamic>> getMyLicencesByCategory(int categoryId) async {
    var response = await http.get(
      Uri.parse('$baseUrl/licences/?category=$categoryId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        response = await http.get(
          Uri.parse('$baseUrl/licences/?category=$categoryId'),
          headers: await _authHeaders(),
        );
      }
    }
    final data = await _handleResponse(response);
    return data as List<dynamic>;
  }

  Future<List<dynamic>> getLicenceEntries(int licenceId) async {
    var response = await http.get(
      Uri.parse('$baseUrl/licence-entries/?licence=$licenceId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        response = await http.get(
          Uri.parse('$baseUrl/licence-entries/?licence=$licenceId'),
          headers: await _authHeaders(),
        );
      }
    }
    final data = await _handleResponse(response);
    return data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getMyDealerProfile() async {
    var response = await http.get(
      Uri.parse('$baseUrl/dealers/'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        response = await http.get(
          Uri.parse('$baseUrl/dealers/'),
          headers: await _authHeaders(),
        );
      }
    }
    final data = await _handleResponse(response);
    final list = data as List<dynamic>;
    return list.isNotEmpty ? list.first as Map<String, dynamic> : {};
  }

  Future<Map<String, dynamic>> createLicence({
    required int dealer,
    required int licenceType,
    required String licenceNumber,
    required String issueDate,
    required String expiryDate,
  }) async {
    final body = jsonEncode({
      'dealer': dealer,
      'licence_type': licenceType,
      'licence_number': licenceNumber,
      'issue_date': issueDate,
      'expiry_date': expiryDate,
    });
    var response = await http.post(
      Uri.parse('$baseUrl/licences/'),
      headers: await _authHeaders(),
      body: body,
    );
    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        response = await http.post(
          Uri.parse('$baseUrl/licences/'),
          headers: await _authHeaders(),
          body: body,
        );
      }
    }
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateLicence({
    required int licenceId,
    required int licenceType,
    required String licenceNumber,
    required String issueDate,
    required String expiryDate,
  }) async {
    final body = jsonEncode({
      'licence_type': licenceType,
      'licence_number': licenceNumber,
      'issue_date': issueDate,
      'expiry_date': expiryDate,
    });
    var response = await http.patch(
      Uri.parse('$baseUrl/licences/$licenceId/'),
      headers: await _authHeaders(),
      body: body,
    );
    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        response = await http.patch(
          Uri.parse('$baseUrl/licences/$licenceId/'),
          headers: await _authHeaders(),
          body: body,
        );
      }
    }
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createLicenceEntry({
    required int licence,
    String sourceType = '',
    required String companyName,
    List<int>? fertilizerType,
    required String validUpto,
  }) async {
    final body = jsonEncode({
      'licence': licence,
      'source_type': sourceType,
      'company_name': companyName,
      'fertilizer_type': fertilizerType ?? [],
      'valid_upto': validUpto,
    });
    var response = await http.post(
      Uri.parse('$baseUrl/licence-entries/'),
      headers: await _authHeaders(),
      body: body,
    );
    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        response = await http.post(
          Uri.parse('$baseUrl/licence-entries/'),
          headers: await _authHeaders(),
          body: body,
        );
      }
    }
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateLicenceEntry({
    required int entryId,
    String sourceType = '',
    required String companyName,
    List<int>? fertilizerType,
    required String validUpto,
  }) async {
    final body = jsonEncode({
      'source_type': sourceType,
      'company_name': companyName,
      'fertilizer_type': fertilizerType ?? [],
      'valid_upto': validUpto,
    });
    var response = await http.patch(
      Uri.parse('$baseUrl/licence-entries/$entryId/'),
      headers: await _authHeaders(),
      body: body,
    );
    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        response = await http.patch(
          Uri.parse('$baseUrl/licence-entries/$entryId/'),
          headers: await _authHeaders(),
          body: body,
        );
      }
    }
    return _handleResponse(response);
  }

  // ---------- SHARED RESPONSE HANDLER ----------

  dynamic _handleResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    } else {
      throw ApiException(decoded);
    }
  }
}

class ApiException implements Exception {
  final dynamic errorData;
  ApiException(this.errorData);

  @override
  String toString() => errorData.toString();
}