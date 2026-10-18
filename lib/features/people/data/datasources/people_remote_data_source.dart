import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/contact_model.dart';
import '../models/debt_model.dart';
import '../models/debt_with_contact_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class PeopleRemoteDataSource {
  Future<List<ContactModel>> getFavorites();
  Future<List<ContactModel>> getFrequentlyContacted();
  Future<List<ContactModel>> getAllContacts();
  Future<ContactModel> createContact(Map<String, dynamic> data);
  Future<ContactModel> updateContact(String id, Map<String, dynamic> data);
  Future<void> deleteContact(String id);
  Future<ContactModel> getContact(String id);
  Future<DebtModel> createDebt(Map<String, dynamic> data);
  Future<void> recordPayment({
    required String debtId,
    required double amount,
    String? note,
    String? clientId,
  });
  Future<Map<String, dynamic>> getAllDebtsWithStats({String status = 'all'});
}

class PeopleRemoteDataSourceImpl implements PeopleRemoteDataSource {
  final http.Client client;
  final SharedPreferences sharedPreferences;
  final String baseUrl = dotenv.env['API_BASE_URL']! + '/contacts';

  PeopleRemoteDataSourceImpl({
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

  @override
  Future<List<ContactModel>> getFavorites() async {
    final response = await client.get(
      Uri.parse('$baseUrl/favorites'),
      headers: await _headers,
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List)
          .map((json) => ContactModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load favorites');
    }
  }

  @override
  Future<List<ContactModel>> getFrequentlyContacted() async {
    final response = await client.get(
      Uri.parse('$baseUrl/frequent'),
      headers: await _headers,
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List)
          .map((json) => ContactModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load frequent contacts');
    }
  }

  @override
  Future<List<ContactModel>> getAllContacts() async {
    final response = await client.get(
      Uri.parse('$baseUrl?per_page=50'),
      headers: await _headers,
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List)
          .map((json) => ContactModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load all contacts');
    }
  }

  @override
  Future<ContactModel> createContact(Map<String, dynamic> data) async {
    final response = await client.post(
      Uri.parse(baseUrl),
      headers: await _headers,
      body: json.encode(data),
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      return ContactModel.fromJson(responseData['contact']);
    } else {
      throw Exception('Failed to create contact: ${response.body}');
    }
  }

  @override
  Future<ContactModel> updateContact(String id, Map<String, dynamic> data) async {
    final response = await client.put(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers,
      body: json.encode(data),
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return ContactModel.fromJson(responseData['contact']);
    } else {
      throw Exception('Failed to update contact: ${response.body}');
    }
  }

  @override
  Future<void> deleteContact(String id) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers,
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete contact: ${response.body}');
    }
  }

  @override
  Future<ContactModel> getContact(String id) async {
    final response = await client.get(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers,
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ContactModel.fromJson(data['contact']);
    } else {
      throw Exception('Failed to get contact: ${response.body}');
    }
  }

  @override
  Future<DebtModel> createDebt(Map<String, dynamic> data) async {
    final debtUrl = dotenv.env['API_BASE_URL']! + '/debts';
    final response = await client.post(
      Uri.parse(debtUrl),
      headers: await _headers,
      body: json.encode(data),
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      return DebtModel.fromJson(responseData['debt']);
    } else {
      throw Exception('Failed to create debt: ${response.body}');
    }
  }

  @override
  Future<void> recordPayment({
    required String debtId,
    required double amount,
    String? note,
    String? clientId,
  }) async {
    final debtsUrl = dotenv.env['API_BASE_URL']! + '/debts';
    final effectiveClientId = clientId ?? const Uuid().v4(); // unique per request for idempotency
    final response = await client.post(
      Uri.parse('$debtsUrl/$debtId/transactions'),
      headers: await _headers,
      body: json.encode({
        'amount': amount,
        'type': 'PAYMENT', // backend expects uppercase
        'client_id': effectiveClientId, // required UUID for idempotency
        if (note != null && note.isNotEmpty) 'note': note,
      }),
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode != 201 && response.statusCode != 200) {
      final body = json.decode(response.body);
      final msg = body['message'] ?? 'Failed to record payment';
      throw Exception(msg);
    }
  }

  @override
  Future<Map<String, dynamic>> getAllDebtsWithStats({
    String status = 'all',
  }) async {
    final debtsUrl = dotenv.env['API_BASE_URL']! + '/debts';

    // Build query parameters
    final queryParams = <String, String>{'per_page': '100'};

    final uri = Uri.parse(debtsUrl).replace(queryParameters: queryParams);
    final response = await client.get(uri, headers: await _headers).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Debug: print the response structure
      print('API Response keys: ${data.keys}');
      print('Statistics field: ${data['statistics']}');

      // Extract debts and statistics
      final debts = (data['data'] as List)
          .map((json) => DebtWithContactModel.fromJson(json))
          .toList();

      // Handle null statistics with default values
      final stats =
          (data['statistics'] as Map<String, dynamic>?) ??
          {
            'total_debts': 0,
            'pending_count': 0,
            'settled_count': 0,
            'total_pending': 0,
            'total_settled': 0,
            'i_owe_pending': 0,
            'they_owe_me_pending': 0,
            'i_owe_settled': 0,
            'they_owe_me_settled': 0,
          };

      // Client-side filtering by status
      List<DebtWithContactModel> filteredDebts = debts;
      if (status == 'pending') {
        filteredDebts = debts.where((d) => d.isPending).toList();
      } else if (status == 'settled') {
        filteredDebts = debts.where((d) => d.isSettled).toList();
      }

      return {'debts': filteredDebts, 'statistics': stats};
    } else {
      throw Exception('Failed to load debts: ${response.body}');
    }
  }
}
