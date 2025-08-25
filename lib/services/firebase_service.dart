/// Firebase雲端存儲服務
/// 提供完全免費的雲端數據同步和備份

import 'dart:convert';
import 'dart:html' as html;
import '../models/student.dart';
import '../models/referee_models.dart';

/// 簡單的HTTP-based Firebase服務
/// 不需要Firebase SDK，直接使用REST API
class FirebaseService {
  // Firebase項目的URL（用戶需要替換為自己的）
  static String _firebaseUrl = 'https://athletic-meet-system-default-rtdb.firebaseio.com/';
  
  /// 設置Firebase項目URL
  static void setFirebaseUrl(String url) {
    _firebaseUrl = url.endsWith('/') ? url : '$url/';
    html.window.localStorage['firebase_url'] = _firebaseUrl;
  }
  
  /// 從本地存儲獲取Firebase URL
  static String getFirebaseUrl() {
    final saved = html.window.localStorage['firebase_url'];
    if (saved != null && saved.isNotEmpty) {
      _firebaseUrl = saved;
    }
    return _firebaseUrl;
  }
  
  /// 上傳學生數據到雲端
  static Future<bool> uploadStudents(List<Student> students) async {
    try {
      final data = {
        'students': students.map((s) => s.toJson()).toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };
      
      final response = await html.HttpRequest.request(
        '${getFirebaseUrl()}students.json',
        method: 'PUT',
        requestHeaders: {'Content-Type': 'application/json'},
        sendData: json.encode(data),
      );
      
      return response.status == 200;
    } catch (e) {
      print('❌ 上傳學生數據失敗: $e');
      return false;
    }
  }
  
  /// 從雲端下載學生數據
  static Future<List<Student>> downloadStudents() async {
    try {
      final response = await html.HttpRequest.request(
        '${getFirebaseUrl()}students.json',
        method: 'GET',
      );
      
      if (response.status == 200 && response.responseText != null) {
        final data = json.decode(response.responseText!) as Map<String, dynamic>?;
        if (data != null && data['students'] != null) {
          final studentsList = data['students'] as List;
          return studentsList.map((json) => Student.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ 下載學生數據失敗: $e');
      return [];
    }
  }
  
  /// 上傳成績數據到雲端
  static Future<bool> uploadScores(Map<String, String> scores) async {
    try {
      final data = {
        'scores': scores,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      final response = await html.HttpRequest.request(
        '${getFirebaseUrl()}scores.json',
        method: 'PUT',
        requestHeaders: {'Content-Type': 'application/json'},
        sendData: json.encode(data),
      );
      
      return response.status == 200;
    } catch (e) {
      print('❌ 上傳成績數據失敗: $e');
      return false;
    }
  }
  
  /// 從雲端下載成績數據
  static Future<Map<String, String>> downloadScores() async {
    try {
      final response = await html.HttpRequest.request(
        '${getFirebaseUrl()}scores.json',
        method: 'GET',
      );
      
      if (response.status == 200 && response.responseText != null) {
        final data = json.decode(response.responseText!) as Map<String, dynamic>?;
        if (data != null && data['scores'] != null) {
          return Map<String, String>.from(data['scores']);
        }
      }
      return {};
    } catch (e) {
      print('❌ 下載成績數據失敗: $e');
      return {};
    }
  }
  
  /// 上傳所有數據到雲端
  static Future<bool> uploadAllData({
    required List<Student> students,
    required Map<String, String> scores,
    Map<String, List<Finalist>>? finalists,
    Map<String, List<PodiumWinner>>? podium,
  }) async {
    try {
      final allData = {
        'students': students.map((s) => s.toJson()).toList(),
        'scores': scores,
        'finalists': finalists?.map((key, value) =>
            MapEntry(key, value.map((f) => f.toJson()).toList())) ?? {},
        'podium': podium?.map((key, value) =>
            MapEntry(key, value.map((p) => p.toJson()).toList())) ?? {},
        'lastUpdated': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };
      
      final response = await html.HttpRequest.request(
        '${getFirebaseUrl()}athletic_meet_data.json',
        method: 'PUT',
        requestHeaders: {'Content-Type': 'application/json'},
        sendData: json.encode(allData),
      );
      
      return response.status == 200;
    } catch (e) {
      print('❌ 上傳所有數據失敗: $e');
      return false;
    }
  }
  
  /// 從雲端下載所有數據
  static Future<Map<String, dynamic>?> downloadAllData() async {
    try {
      final response = await html.HttpRequest.request(
        '${getFirebaseUrl()}athletic_meet_data.json',
        method: 'GET',
      );
      
      if (response.status == 200 && response.responseText != null) {
        final data = json.decode(response.responseText!) as Map<String, dynamic>?;
        if (data != null) {
          return {
            'students': (data['students'] as List?)?.map((json) => Student.fromJson(json)).toList() ?? <Student>[],
            'scores': Map<String, String>.from(data['scores'] ?? {}),
            'finalists': (data['finalists'] as Map<String, dynamic>?)?.map((key, value) =>
                MapEntry(key, (value as List).map((json) => Finalist.fromJson(json)).toList())) ?? <String, List<Finalist>>{},
            'podium': (data['podium'] as Map<String, dynamic>?)?.map((key, value) =>
                MapEntry(key, (value as List).map((json) => PodiumWinner.fromJson(json)).toList())) ?? <String, List<PodiumWinner>>{},
            'lastUpdated': data['lastUpdated'],
            'version': data['version'],
          };
        }
      }
      return null;
    } catch (e) {
      print('❌ 下載所有數據失敗: $e');
      return null;
    }
  }
  
  /// 測試雲端連接
  static Future<bool> testConnection() async {
    try {
      final response = await html.HttpRequest.request(
        '${getFirebaseUrl()}.json',
        method: 'GET',
      );
      
      return response.status == 200;
    } catch (e) {
      print('❌ 雲端連接測試失敗: $e');
      return false;
    }
  }
  
  /// 獲取雲端數據統計
  static Future<Map<String, dynamic>> getCloudStats() async {
    try {
      final response = await html.HttpRequest.request(
        '${getFirebaseUrl()}athletic_meet_data.json',
        method: 'GET',
      );
      
      if (response.status == 200 && response.responseText != null) {
        final data = json.decode(response.responseText!) as Map<String, dynamic>?;
        if (data != null) {
          return {
            'studentsCount': (data['students'] as List?)?.length ?? 0,
            'scoresCount': (data['scores'] as Map?)?.length ?? 0,
            'lastUpdated': data['lastUpdated'] ?? '從未',
            'version': data['version'] ?? '未知',
            'hasData': data.isNotEmpty,
          };
        }
      }
      
      return {
        'studentsCount': 0,
        'scoresCount': 0,
        'lastUpdated': '從未',
        'version': '未知',
        'hasData': false,
      };
    } catch (e) {
      print('❌ 獲取雲端統計失敗: $e');
      return {
        'studentsCount': 0,
        'scoresCount': 0,
        'lastUpdated': '錯誤',
        'version': '未知',
        'hasData': false,
        'error': e.toString(),
      };
    }
  }
}
