import 'package:flutter/material.dart';
import '../api/api_client.dart';

class DashboardProvider extends ChangeNotifier {
  Map<String, dynamic> stats = {
    'total_items': 0,
    'total_value': 0,
    'low_stock_items': 0,
    'recent_inbound': 0,
    'recent_outbound': 0,
  };

  Map<String, dynamic> trend = {'dates': [], 'inbound': [], 'outbound': []};

  bool isLoading = false;

  Future<void> fetchDashboardData() async {
    isLoading = true;
    notifyListeners();

    try {
      final statsRes = await ApiClient.dio.get('/dashboard/stats');
      stats = statsRes.data;

      final trendRes = await ApiClient.dio.get('/dashboard/trend');
      trend = trendRes.data;
    } catch (e) {
      // Handle error
    }

    isLoading = false;
    notifyListeners();
  }
}
