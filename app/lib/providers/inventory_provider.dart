import 'package:flutter/material.dart';
import '../api/api_client.dart';

class InventoryProvider extends ChangeNotifier {
  List<dynamic> items = [];
  List<dynamic> records = [];
  bool isLoading = false;

  Future<void> fetchItems() async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.dio.get('/items/');
      items = res.data['items'];
    } catch (e) {
      debugPrint('Error fetching items: $e');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchRecords() async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.dio.get('/transactions/');
      records = res.data['items'];
    } catch (e) {
      debugPrint('Error fetching records: $e');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> inbound(Map<String, dynamic> data) async {
    try {
      await ApiClient.dio.post('/transactions/inbound', data: data);
      await fetchItems();
      await fetchRecords();
      return true;
    } catch (e) {
      debugPrint('Inbound Error: $e');
      return false;
    }
  }

  Future<bool> outbound(Map<String, dynamic> data) async {
    try {
      await ApiClient.dio.post('/transactions/outbound', data: data);
      await fetchItems();
      await fetchRecords();
      return true;
    } catch (e) {
      debugPrint('Outbound Error: $e');
      return false;
    }
  }
}
