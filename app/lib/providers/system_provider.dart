import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../api/api_client.dart';

class SystemProvider extends ChangeNotifier {
  Map<String, dynamic> settings = {
    'upload': {
      'max_size_mb': 5,
      'allowed_extensions': ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    },
    'access': {'allow_external_ip': false},
    'storage': {'data_path': 'data'},
    'general': {
      'project_name': 'EasyStore',
      'port': 8000,
    },
  };

  bool isLoading = false;

  Future<void> fetchSettings() async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.dio.get('/system/settings');
      settings = res.data;
    } catch (e) {
      debugPrint('Error fetching system settings: $e');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> saveSettings(Map<String, dynamic> newSettings) async {
    try {
      await ApiClient.dio.put('/system/settings', data: newSettings);
      settings = newSettings;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving system settings: $e');
      return false;
    }
  }

  Future<bool> backup() async {
    try {
      final dateStr = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: '保存备份文件',
        fileName: 'easystore_backup_$dateStr.zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (outputFile != null) {
        await ApiClient.dio.download('/system/backup', outputFile);
        return true;
      }
      return false; // User cancelled
    } catch (e) {
      debugPrint('Error downloading backup: $e');
      return false;
    }
  }

  Future<bool> restore(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      await ApiClient.dio.post('/system/restore', data: formData);
      return true;
    } catch (e) {
      debugPrint('Error restoring system: $e');
      return false;
    }
  }
}
