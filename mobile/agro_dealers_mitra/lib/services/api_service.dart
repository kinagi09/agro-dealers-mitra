import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../navigation.dart';
import '../screens/login_screen.dart';

class ApiService {
  /// Override at build/run time with:
  ///   flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IP:8000/api
  /// Defaults to the current dev machine's LAN IP so existing workflows
  /// keep working without extra setup.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.41.222.232:8000/api',
  );
  final storage = const FlutterSecureStorage();

  // ---------- AUTH ----------

  Future<Map<String, dynamic>> sendOtp(
    String whatsappNumber, {
    required String purpose,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'whatsapp_number': whatsappNumber, 'purpose': purpose}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyOtp(
    String whatsappNumber,
    String otpCode,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'whatsapp_number': whatsappNumber,
        'otp_code': otpCode,
      }),
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

  Future<Map<String, dynamic>> login(
    String whatsappNumber,
    String otpCode,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'whatsapp_number': whatsappNumber,
        'otp_code': otpCode,
      }),
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

  /// Whether a previous login/register left a session on this device. Used
  /// at app startup to decide between the home screen and the login screen -
  /// access tokens are short-lived, so presence of a refresh token (not the
  /// access token) is the right signal; an actually-expired refresh token is
  /// still handled by the normal _authorizedRequest -> _forceLogout path.
  Future<bool> isLoggedIn() async {
    final refreshToken = await storage.read(key: 'refresh_token');
    return refreshToken != null;
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

  /// Clears the session and bounces the user back to the login screen.
  /// Called whenever a request comes back 401 and the refresh attempt fails.
  Future<void> _forceLogout() async {
    await logout();
    final state = navigatorKey.currentState;
    if (state != null) {
      state.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // ---------- LOCATION DROPDOWNS ----------

  Future<List<dynamic>> getStates() async {
    final response = await http.get(Uri.parse('$baseUrl/states/'));
    final data = await _handleResponse(response);
    return data as List<dynamic>;
  }

  Future<List<dynamic>> getDistricts(int stateId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/districts/?state=$stateId'),
    );
    final data = await _handleResponse(response);
    return data as List<dynamic>;
  }

  Future<List<dynamic>> getTalukas(int districtId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/talukas/?district=$districtId'),
    );
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
    final response = await http.get(
      Uri.parse('$baseUrl/licence-types/?category=$categoryId'),
    );
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

  /// Performs an authenticated request, retrying once after a token refresh
  /// on a 401. If the refresh itself fails, the session is cleared and the
  /// user is sent back to the login screen instead of surfacing a generic
  /// "check your connection" error.
  Future<dynamic> _authorizedRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var response = await request(await _authHeaders());
    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (!refreshed) {
        await _forceLogout();
        throw SessionExpiredException();
      }
      response = await request(await _authHeaders());
    }
    return _handleResponse(response);
  }

  Future<List<dynamic>> getMyLicences() async {
    final data = await _authorizedRequest(
      (headers) => http.get(Uri.parse('$baseUrl/licences/'), headers: headers),
    );
    return data as List<dynamic>;
  }

  Future<List<dynamic>> getMyLicencesByCategory(int categoryId) async {
    final data = await _authorizedRequest(
      (headers) => http.get(
        Uri.parse('$baseUrl/licences/?category=$categoryId'),
        headers: headers,
      ),
    );
    return data as List<dynamic>;
  }

  Future<List<dynamic>> getLicenceEntries(int licenceId) async {
    final data = await _authorizedRequest(
      (headers) => http.get(
        Uri.parse('$baseUrl/licence-entries/?licence=$licenceId'),
        headers: headers,
      ),
    );
    return data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getMyDealerProfile() async {
    final data = await _authorizedRequest(
      (headers) => http.get(Uri.parse('$baseUrl/dealers/'), headers: headers),
    );
    final list = data as List<dynamic>;
    return list.isNotEmpty ? list.first as Map<String, dynamic> : {};
  }

  Future<void> deleteDealer(int dealerId) async {
    await _authorizedRequest(
      (headers) => http.delete(
        Uri.parse('$baseUrl/dealers/$dealerId/'),
        headers: headers,
      ),
    );
  }

  Future<Map<String, dynamic>> getMyNotificationPreference() async {
    final data = await _authorizedRequest(
      (headers) => http.get(
        Uri.parse('$baseUrl/notification-preferences/'),
        headers: headers,
      ),
    );
    final list = data as List<dynamic>;
    return list.isNotEmpty ? list.first as Map<String, dynamic> : {};
  }

  Future<Map<String, dynamic>> updateNotificationPreference({
    required int id,
    required bool pushEnabled,
    required bool whatsappEnabled,
  }) async {
    final body = jsonEncode({
      'push_enabled': pushEnabled,
      'whatsapp_enabled': whatsappEnabled,
    });
    return await _authorizedRequest(
      (headers) => http.patch(
        Uri.parse('$baseUrl/notification-preferences/$id/'),
        headers: headers,
        body: body,
      ),
    );
  }

  Future<void> updateFcmToken({
    required int id,
    required String fcmToken,
  }) async {
    await _authorizedRequest(
      (headers) => http.patch(
        Uri.parse('$baseUrl/notification-preferences/$id/'),
        headers: headers,
        body: jsonEncode({'fcm_token': fcmToken}),
      ),
    );
  }

  Future<Map<String, dynamic>> createLicence({
    required int dealer,
    required int licenceType,
    required String licenceNumber,
    required String issueDate,
    String? expiryDate,
  }) async {
    final body = jsonEncode({
      'dealer': dealer,
      'licence_type': licenceType,
      'licence_number': licenceNumber,
      'issue_date': issueDate,
      'expiry_date': expiryDate,
    });
    return await _authorizedRequest(
      (headers) => http.post(
        Uri.parse('$baseUrl/licences/'),
        headers: headers,
        body: body,
      ),
    );
  }

  Future<Map<String, dynamic>> updateLicence({
    required int licenceId,
    required int licenceType,
    required String licenceNumber,
    required String issueDate,
    String? expiryDate,
  }) async {
    final body = jsonEncode({
      'licence_type': licenceType,
      'licence_number': licenceNumber,
      'issue_date': issueDate,
      'expiry_date': expiryDate,
    });
    return await _authorizedRequest(
      (headers) => http.patch(
        Uri.parse('$baseUrl/licences/$licenceId/'),
        headers: headers,
        body: body,
      ),
    );
  }

  Future<void> deleteLicence(int licenceId) async {
    await _authorizedRequest(
      (headers) => http.delete(
        Uri.parse('$baseUrl/licences/$licenceId/'),
        headers: headers,
      ),
    );
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
    return await _authorizedRequest(
      (headers) => http.post(
        Uri.parse('$baseUrl/licence-entries/'),
        headers: headers,
        body: body,
      ),
    );
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
    return await _authorizedRequest(
      (headers) => http.patch(
        Uri.parse('$baseUrl/licence-entries/$entryId/'),
        headers: headers,
        body: body,
      ),
    );
  }

  Future<void> deleteLicenceEntry(int entryId) async {
    await _authorizedRequest(
      (headers) => http.delete(
        Uri.parse('$baseUrl/licence-entries/$entryId/'),
        headers: headers,
      ),
    );
  }

  Future<List<dynamic>> getMyNotifications() async {
    final data = await _authorizedRequest(
      (headers) =>
          http.get(Uri.parse('$baseUrl/notifications/'), headers: headers),
    );
    return data as List<dynamic>;
  }

  Future<void> markAllNotificationsRead() async {
    await _authorizedRequest(
      (headers) => http.post(
        Uri.parse('$baseUrl/notifications/mark_all_read/'),
        headers: headers,
      ),
    );
  }

  // ---------- SHARED RESPONSE HANDLER ----------

  dynamic _handleResponse(http.Response response) {
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (isSuccess) {
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

/// Thrown when a session can't be refreshed; the user has already been
/// routed to the login screen by the time this is thrown, so callers can
/// generally let it propagate and be ignored by the caught catch-all.
class SessionExpiredException implements Exception {
  @override
  String toString() => 'Session expired';
}
