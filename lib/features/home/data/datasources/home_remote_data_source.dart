import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/dashboard_models.dart';

abstract class HomeRemoteDataSource {
  Future<DashboardDataModel> getDashboard();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  String get baseUrl => dotenv.env['API_BASE_URL']!;

  HomeRemoteDataSourceImpl({
    required this.client,
    required this.sharedPreferences,
  });

  Map<String, String> get _headers {
    final token = sharedPreferences.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<DashboardDataModel> getDashboard() async {
    final response = await client.get(
      Uri.parse('$baseUrl/analytics/dashboard'),
      headers: _headers,
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return DashboardDataModel.fromJson(json);
    } else {
      throw Exception('Failed to load dashboard data');
    }
  }
}
