import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String phoneNumber, String pin);
  Future<UserModel> register(String name, String phoneNumber, {String? currency});
  Future<void> setLoginPin(String pin);
  Future<UserModel> getUser();
  Future<UserModel> updateProfile({String? name, String? email, String? defaultCurrency});
  Future<UserModel> uploadAvatar(File imageFile);
  Future<UserModel> deleteAvatar();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  final SharedPreferences sharedPreferences;
  
  String get baseUrl => dotenv.env['API_BASE_URL']!;
  static const String tokenKey = 'auth_token';

  AuthRemoteDataSourceImpl({
    required this.client,
    required this.sharedPreferences,
  });

  Map<String, String> get _headers {
    final token = sharedPreferences.getString(tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Parses API error response and returns a clean, user-friendly message.
  String _parseError(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic> && json.containsKey('message')) {
        return json['message'] as String;
      }
      return 'Something went wrong. Please try again.';
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  @override
  Future<UserModel> login(String phoneNumber, String pin) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'phone_number': phoneNumber,
        'pin': pin,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      await sharedPreferences.setString(tokenKey, json['token']);
      return UserModel.fromJson(json['user']);
    } else {
      throw Exception(_parseError(response));
    }
  }

  @override
  Future<UserModel> register(String name, String phoneNumber, {String? currency}) async {
    final body = {
      'name': name,
      'phone_number': phoneNumber,
    };
    if (currency != null) {
      body['currency'] = currency;
    }

    final response = await client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      await sharedPreferences.setString(tokenKey, json['token']);
      return UserModel.fromJson(json['user']);
    } else {
      throw Exception(_parseError(response));
    }
  }

  @override
  Future<void> setLoginPin(String pin) async {
    final response = await client.put(
      Uri.parse('$baseUrl/auth/pin/login'),
      headers: _headers,
      body: jsonEncode({'pin': pin}),
    );

    if (response.statusCode != 200) {
      throw Exception(_parseError(response));
    }
  }

  @override
  Future<UserModel> getUser() async {
    final response = await client.get(
      Uri.parse('$baseUrl/auth/user'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return UserModel.fromJson(json['user']);
    } else {
      throw Exception(_parseError(response));
    }
  }

  @override
  Future<UserModel> updateProfile({String? name, String? email, String? defaultCurrency}) async {
    final Map<String, dynamic> body = {};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (defaultCurrency != null) body['default_currency'] = defaultCurrency;

    final response = await client.put(
      Uri.parse('$baseUrl/auth/user'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return UserModel.fromJson(json['user']);
    } else {
      throw Exception(_parseError(response));
    }
  }

  @override
  Future<UserModel> uploadAvatar(File imageFile) async {
    final token = sharedPreferences.getString(tokenKey);
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/auth/avatar'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    final multipartFile = await http.MultipartFile.fromPath(
      'avatar',
      imageFile.path,
    );
    request.files.add(multipartFile);

    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return UserModel.fromJson(json['user']);
    } else {
      throw Exception(_parseError(response));
    }
  }

  @override
  Future<UserModel> deleteAvatar() async {
    final response = await client.delete(
      Uri.parse('$baseUrl/auth/avatar'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return UserModel.fromJson(json['user']);
    } else {
      throw Exception(_parseError(response));
    }
  }
}

