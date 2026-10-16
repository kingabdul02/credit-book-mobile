import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/legacy_contact_model.dart';
import '../models/legacy_access_request_model.dart';
import '../models/estate_report_model.dart';

abstract class LegacyRemoteDataSource {
  Future<LegacySettingsModel> getSettings();
  Future<String?> enableLegacyAccess();
  Future<void> disableLegacyAccess();
  Future<List<LegacyContactModel>> getLegacyContacts();
  Future<LegacyContactModel> createLegacyContact(Map<String, dynamic> data);
  Future<LegacyContactModel> updateLegacyContact(String id, Map<String, dynamic> data);
  Future<void> deleteLegacyContact(String id);
  Future<void> resendVerification(String id);
  Future<void> revokeLegacyContact(String id);

  // ── Access Requests ────────────────────────────────────────────
  Future<LegacyAccessRequestModel> submitAccessRequest(Map<String, dynamic> data);
  Future<List<LegacyAccessRequestModel>> getAccessRequests();
  Future<LegacyAccessRequestModel> approveAccessRequest(String id);
  Future<LegacyAccessRequestModel> denyAccessRequest(String id);
  Future<EstateReportModel> getEstateReport(String requestId);
}

class LegacyRemoteDataSourceImpl implements LegacyRemoteDataSource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  String get _base => dotenv.env['API_BASE_URL']!;

  LegacyRemoteDataSourceImpl({
    required this.client,
    required this.sharedPreferences,
  });

  Future<Map<String, String>> get _headers async {
    final token = sharedPreferences.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Helper ─────────────────────────────────────────────────
  void _assertSuccess(http.Response response, {List<int> allowed = const [200, 201]}) {
    if (!allowed.contains(response.statusCode)) {
      final body = json.decode(response.body);
      final msg = body['message'] ?? 'Request failed (${response.statusCode})';
      throw Exception(msg);
    }
  }

  // ── Settings ───────────────────────────────────────────────
  @override
  Future<LegacySettingsModel> getSettings() async {
    final response = await client.get(
      Uri.parse('$_base/legacy/settings'),
      headers: await _headers,
    );
    _assertSuccess(response);
    final body = json.decode(response.body);
    return LegacySettingsModel.fromJson(body['settings'] as Map<String, dynamic>);
  }

  @override
  Future<String?> enableLegacyAccess() async {
    final response = await client.post(
      Uri.parse('$_base/legacy/enable'),
      headers: await _headers,
    );
    _assertSuccess(response);
    final body = json.decode(response.body);
    return body['recovery_code']?.toString();
  }

  @override
  Future<void> disableLegacyAccess() async {
    final response = await client.post(
      Uri.parse('$_base/legacy/disable'),
      headers: await _headers,
    );
    _assertSuccess(response);
  }

  // ── Contacts ───────────────────────────────────────────────
  @override
  Future<List<LegacyContactModel>> getLegacyContacts() async {
    final response = await client.get(
      Uri.parse('$_base/legacy-contacts?per_page=50'),
      headers: await _headers,
    );
    _assertSuccess(response);
    final body = json.decode(response.body);
    final data = body['data'] as List? ?? [];
    return data.map((e) => LegacyContactModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<LegacyContactModel> createLegacyContact(Map<String, dynamic> data) async {
    final response = await client.post(
      Uri.parse('$_base/legacy-contacts'),
      headers: await _headers,
      body: json.encode(data),
    );

    // Auto-enable legacy access and retry if remote API returned legacy access requirement error
    if (response.statusCode == 422 || response.statusCode == 403) {
      try {
        final body = json.decode(response.body);
        final msg = (body['message'] ?? '').toString().toLowerCase();
        if (msg.contains('legacy access must be enabled') || msg.contains('legacy access is not enabled')) {
          await enableLegacyAccess();
          final retryResponse = await client.post(
            Uri.parse('$_base/legacy-contacts'),
            headers: await _headers,
            body: json.encode(data),
          );
          _assertSuccess(retryResponse, allowed: [200, 201]);
          final retryBody = json.decode(retryResponse.body);
          return LegacyContactModel.fromJson(retryBody['contact'] as Map<String, dynamic>);
        }
      } catch (_) {
        // Fall through to standard error handling
      }
    }

    _assertSuccess(response, allowed: [200, 201]);
    final body = json.decode(response.body);
    return LegacyContactModel.fromJson(body['contact'] as Map<String, dynamic>);
  }

  @override
  Future<LegacyContactModel> updateLegacyContact(String id, Map<String, dynamic> data) async {
    final response = await client.patch(
      Uri.parse('$_base/legacy-contacts/$id'),
      headers: await _headers,
      body: json.encode(data),
    );
    _assertSuccess(response);
    final body = json.decode(response.body);
    return LegacyContactModel.fromJson(body['contact'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteLegacyContact(String id) async {
    final response = await client.delete(
      Uri.parse('$_base/legacy-contacts/$id'),
      headers: await _headers,
    );
    _assertSuccess(response);
  }

  @override
  Future<void> resendVerification(String id) async {
    final response = await client.post(
      Uri.parse('$_base/legacy-contacts/$id/resend-verification'),
      headers: await _headers,
    );
    _assertSuccess(response);
  }

  @override
  Future<void> revokeLegacyContact(String id) async {
    final response = await client.post(
      Uri.parse('$_base/legacy-contacts/$id/revoke'),
      headers: await _headers,
    );
    _assertSuccess(response);
  }

  // ── Access Requests ────────────────────────────────────────
  @override
  Future<LegacyAccessRequestModel> submitAccessRequest(Map<String, dynamic> data) async {
    // Save access code/recovery code locally for authorized estate report viewing
    if (data['access_code'] != null && data['access_code'].toString().isNotEmpty) {
      await sharedPreferences.setString('last_nominee_access_code', data['access_code'].toString());
    }
    if (data['recovery_code'] != null && data['recovery_code'].toString().isNotEmpty) {
      await sharedPreferences.setString('last_nominee_recovery_code', data['recovery_code'].toString());
    }

    final response = await client.post(
      Uri.parse('$_base/legacy-access-requests'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(data),
    );
    _assertSuccess(response, allowed: [200, 201]);
    final body = json.decode(response.body);
    return LegacyAccessRequestModel.fromJson(body['access_request'] as Map<String, dynamic>);
  }

  @override
  Future<List<LegacyAccessRequestModel>> getAccessRequests() async {
    final response = await client.get(
      Uri.parse('$_base/legacy-access-requests?per_page=50'),
      headers: await _headers,
    );
    _assertSuccess(response);
    final body = json.decode(response.body);
    final data = body['data'] as List? ?? [];
    return data.map((e) => LegacyAccessRequestModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<LegacyAccessRequestModel> approveAccessRequest(String id) async {
    final response = await client.post(
      Uri.parse('$_base/legacy-access-requests/$id/approve'),
      headers: await _headers,
    );
    _assertSuccess(response);
    final body = json.decode(response.body);
    return LegacyAccessRequestModel.fromJson(body['access_request'] as Map<String, dynamic>);
  }

  @override
  Future<LegacyAccessRequestModel> denyAccessRequest(String id) async {
    final response = await client.post(
      Uri.parse('$_base/legacy-access-requests/$id/deny'),
      headers: await _headers,
    );
    _assertSuccess(response);
    final body = json.decode(response.body);
    return LegacyAccessRequestModel.fromJson(body['access_request'] as Map<String, dynamic>);
  }

  @override
  Future<EstateReportModel> getEstateReport(String requestId) async {
    final headers = await _headers;
    final accessCode = sharedPreferences.getString('last_nominee_access_code');
    final recoveryCode = sharedPreferences.getString('last_nominee_recovery_code');

    if (accessCode != null && accessCode.isNotEmpty) {
      headers['X-Access-Code'] = accessCode;
    }
    if (recoveryCode != null && recoveryCode.isNotEmpty) {
      headers['X-Recovery-Code'] = recoveryCode;
    }

    final response = await client.get(
      Uri.parse('$_base/legacy-access-requests/$requestId/estate-report'),
      headers: headers,
    );
    _assertSuccess(response);
    final body = json.decode(response.body);
    return EstateReportModel.fromJson(body['estate_report'] as Map<String, dynamic>);
  }
}
