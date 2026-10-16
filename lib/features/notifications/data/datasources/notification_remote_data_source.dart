import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../domain/entities/app_notification.dart';

abstract class NotificationRemoteDataSource {
  Future<List<AppNotification>> getNotifications();
  Future<AppNotification?> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
  Future<void> clearAll();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  String get baseUrl => dotenv.env['API_BASE_URL']!;

  NotificationRemoteDataSourceImpl({
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
  Future<List<AppNotification>> getNotifications() async {
    final response = await client.get(
      Uri.parse('$baseUrl/notifications'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final list = (json['data'] as List? ?? [])
          .map((item) => AppNotification.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
      return list;
    } else {
      throw Exception('Failed to load notifications from server: ${response.statusCode}');
    }
  }

  @override
  Future<AppNotification?> markAsRead(String id) async {
    final response = await client.patch(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['data'] != null) {
        return AppNotification.fromMap(Map<String, dynamic>.from(json['data'] as Map));
      }
      return null;
    } else {
      throw Exception('Failed to mark notification as read');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    final response = await client.post(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications as read');
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/notifications/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete notification');
    }
  }

  @override
  Future<void> clearAll() async {
    final response = await client.delete(
      Uri.parse('$baseUrl/notifications'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to clear notifications');
    }
  }
}
