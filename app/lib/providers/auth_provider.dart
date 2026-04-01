import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _username;
  String? _role;
  bool _isLoading = true;

  bool get isAuthenticated => _isAuthenticated;
  String? get username => _username;
  String? get role => _role;
  bool get isLoading => _isLoading;

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      try {
        final response = await ApiClient.dio.get('/auth/me');
        _isAuthenticated = true;
        _username = response.data['username'];
        _role = response.data['role'];
      } catch (e) {
        await prefs.remove('token');
        _isAuthenticated = false;
      }
    } else {
      _isAuthenticated = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      final formData = FormData.fromMap({
        'username': username,
        'password': password,
      });
      final response = await ApiClient.dio.post('/auth/login', data: formData);
      final token = response.data['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      
      await checkAuth();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _isAuthenticated = false;
    _username = null;
    _role = null;
    notifyListeners();
  }
}
