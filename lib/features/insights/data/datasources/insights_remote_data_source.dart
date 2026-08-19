import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/insights_model.dart';

abstract class InsightsRemoteDataSource {
  /// Fetches the insights data from the analytics/insights endpoint.
  /// [period] can be 'weekly', 'monthly', or 'yearly'.
  Future<InsightsDataModel> getInsightsData(String period);
}

class InsightsRemoteDataSourceImpl implements InsightsRemoteDataSource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  String get _baseUrl => dotenv.env['API_BASE_URL']!;

  InsightsRemoteDataSourceImpl({
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
  Future<InsightsDataModel> getInsightsData(String period) async {
    final uri = Uri.parse('$_baseUrl/analytics/insights').replace(
      queryParameters: {'period': period.toLowerCase()},
    );

    final response = await client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return InsightsDataModel.fromJson(json);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please log in again.');
    } else {
      throw Exception(
        'Failed to load insights data. Status: ${response.statusCode}',
      );
    }
  }
}
