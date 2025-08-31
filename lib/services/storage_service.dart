/// 數據存儲服務
/// 提供本地存儲和雲端同步功能

import 'dart:convert';
import 'dart:html' as html;
import '../models/student.dart';
import '../models/referee_models.dart';
import 'firebase_service.dart';

class StorageService {
  static const String _studentsKey = 'athletic_meet_students';
  static const String _scoresKey = 'athletic_meet_scores';
  static const String _finalistsKey = 'athletic_meet_finalists';
  static const String _podiumKey = 'athletic_meet_podium';
  static const String _lastSyncKey = 'athletic_meet_last_sync';
  
  /// 保存學生數據
  static Future<void> saveStudents(List<Student> students) async {
    try {
      final jsonList = students.map((student) => student.toJson()).toList();
      final jsonString = json.encode(jsonList);
      html.window.localStorage[_studentsKey] = jsonString;
      _updateLastSync();
      print('✅ 已保存 ${students.length} 位學生數據到本地存儲');
    } catch (e) {
      print('❌ 保存學生數據失敗: $e');
    }
  }
  
  /// 讀取學生數據
  static List<Student> loadStudents() {
    try {
      final jsonString = html.window.localStorage[_studentsKey];
      if (jsonString == null || jsonString.isEmpty) {
        print('📭 本地存儲中沒有學生數據');
        return [];
      }
      
      final jsonList = json.decode(jsonString) as List;
      final students = jsonList.map((json) => Student.fromJson(json)).toList();
      print('✅ 從本地存儲讀取 ${students.length} 位學生數據');
      return students;
    } catch (e) {
      print('❌ 讀取學生數據失敗: $e');
      return [];
    }
  }
  
  /// 保存成績數據
  static Future<void> saveScores(Map<String, String> scores) async {
    try {
      final jsonString = json.encode(scores);
      html.window.localStorage[_scoresKey] = jsonString;
      _updateLastSync();
      print('✅ 已保存 ${scores.length} 條成績數據到本地存儲');
    } catch (e) {
      print('❌ 保存成績數據失敗: $e');
    }
  }
  
  /// 讀取成績數據
  static Map<String, String> loadScores() {
    try {
      final jsonString = html.window.localStorage[_scoresKey];
      if (jsonString == null || jsonString.isEmpty) {
        return {};
      }
      
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      final scores = Map<String, String>.from(decoded);
      print('✅ 從本地存儲讀取 ${scores.length} 條成績數據');
      return scores;
    } catch (e) {
      print('❌ 讀取成績數據失敗: $e');
      return {};
    }
  }
  
  /// 保存決賽名單
  static Future<void> saveFinalists(Map<String, List<Finalist>> finalists) async {
    try {
      final jsonMap = <String, List<Map<String, dynamic>>>{};
      finalists.forEach((eventCode, finalistList) {
        jsonMap[eventCode] = finalistList.map((f) => f.toJson()).toList();
      });
      
      final jsonString = json.encode(jsonMap);
      html.window.localStorage[_finalistsKey] = jsonString;
      _updateLastSync();
      print('✅ 已保存決賽名單到本地存儲');
    } catch (e) {
      print('❌ 保存決賽名單失敗: $e');
    }
  }
  
  /// 讀取決賽名單
  static Map<String, List<Finalist>> loadFinalists() {
    try {
      final jsonString = html.window.localStorage[_finalistsKey];
      if (jsonString == null || jsonString.isEmpty) {
        return {};
      }
      
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      final finalists = <String, List<Finalist>>{};
      
      decoded.forEach((eventCode, finalistList) {
        if (finalistList is List) {
          finalists[eventCode] = finalistList
              .map((json) => Finalist.fromJson(json))
              .toList();
        }
      });
      
      print('✅ 從本地存儲讀取決賽名單');
      return finalists;
    } catch (e) {
      print('❌ 讀取決賽名單失敗: $e');
      return {};
    }
  }
  
  /// 保存三甲名單
  static Future<void> savePodiumResults(Map<String, List<PodiumWinner>> podium) async {
    try {
      final jsonMap = <String, List<Map<String, dynamic>>>{};
      podium.forEach((eventCode, winnerList) {
        jsonMap[eventCode] = winnerList.map((w) => w.toJson()).toList();
      });
      
      final jsonString = json.encode(jsonMap);
      html.window.localStorage[_podiumKey] = jsonString;
      _updateLastSync();
      print('✅ 已保存三甲名單到本地存儲');
    } catch (e) {
      print('❌ 保存三甲名單失敗: $e');
    }
  }
  
  /// 讀取三甲名單
  static Map<String, List<PodiumWinner>> loadPodiumResults() {
    try {
      final jsonString = html.window.localStorage[_podiumKey];
      if (jsonString == null || jsonString.isEmpty) {
        return {};
      }
      
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      final podium = <String, List<PodiumWinner>>{};
      
      decoded.forEach((eventCode, winnerList) {
        if (winnerList is List) {
          podium[eventCode] = winnerList
              .map((json) => PodiumWinner.fromJson(json))
              .toList();
        }
      });
      
      print('✅ 從本地存儲讀取三甲名單');
      return podium;
    } catch (e) {
      print('❌ 讀取三甲名單失敗: $e');
      return {};
    }
  }
  
  /// 清除所有數據（包括Firebase）
  static Future<void> clearAllData() async {
    try {
      // 清除本地數據
      html.window.localStorage.remove(_studentsKey);
      html.window.localStorage.remove(_scoresKey);
      html.window.localStorage.remove(_finalistsKey);
      html.window.localStorage.remove(_podiumKey);
      html.window.localStorage.remove(_lastSyncKey);
      
      // 清除Firebase數據
      await _clearFirebaseData();
      
      print('✅ 已清除所有本地和雲端數據');
    } catch (e) {
      print('❌ 清除數據失敗: $e');
    }
  }
  
  /// 清除Firebase數據
  static Future<void> _clearFirebaseData() async {
    try {
      // 測試連接
      final connected = await FirebaseService.testConnection();
      if (!connected) {
        print('⚠️ Firebase未連接，跳過雲端數據清除');
        return;
      }
      
      // 清除各類數據
      await FirebaseService.clearAllData();
      print('✅ 已清除Firebase數據');
    } catch (e) {
      print('❌ 清除Firebase數據失敗: $e');
    }
  }
  
  /// 獲取存儲統計信息
  static Map<String, dynamic> getStorageStats() {
    final students = loadStudents();
    final scores = loadScores();
    final finalists = loadFinalists();
    final podium = loadPodiumResults();
    final lastSync = html.window.localStorage[_lastSyncKey] ?? '從未同步';
    
    return {
      'studentsCount': students.length,
      'scoresCount': scores.length,
      'finalistsCount': finalists.values.fold(0, (sum, list) => sum + list.length),
      'podiumCount': podium.values.fold(0, (sum, list) => sum + list.length),
      'lastSync': lastSync,
      'totalEvents': finalists.length + podium.length,
    };
  }
  
  /// 導出所有數據
  static String exportAllData() {
    final allData = {
      'students': loadStudents().map((s) => s.toJson()).toList(),
      'scores': loadScores(),
      'finalists': loadFinalists().map((key, value) =>
          MapEntry(key, value.map((f) => f.toJson()).toList())),
      'podium': loadPodiumResults().map((key, value) =>
          MapEntry(key, value.map((p) => p.toJson()).toList())),
      'exportTime': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
    
    return json.encode(allData);
  }
  
  /// 導入所有數據
  static Future<bool> importAllData(String jsonData) async {
    try {
      final data = json.decode(jsonData) as Map<String, dynamic>;
      
      // 導入學生數據
      if (data.containsKey('students')) {
        final studentsList = (data['students'] as List)
            .map((json) => Student.fromJson(json))
            .toList();
        await saveStudents(studentsList);
      }
      
      // 導入成績數據
      if (data.containsKey('scores')) {
        final scores = Map<String, String>.from(data['scores']);
        await saveScores(scores);
      }
      
      // 導入決賽名單
      if (data.containsKey('finalists')) {
        final finalistsData = data['finalists'] as Map<String, dynamic>;
        final finalists = <String, List<Finalist>>{};
        finalistsData.forEach((key, value) {
          finalists[key] = (value as List)
              .map((json) => Finalist.fromJson(json))
              .toList();
        });
        await saveFinalists(finalists);
      }
      
      // 導入三甲名單
      if (data.containsKey('podium')) {
        final podiumData = data['podium'] as Map<String, dynamic>;
        final podium = <String, List<PodiumWinner>>{};
        podiumData.forEach((key, value) {
          podium[key] = (value as List)
              .map((json) => PodiumWinner.fromJson(json))
              .toList();
        });
        await savePodiumResults(podium);
      }
      
      print('✅ 數據導入成功');
      return true;
    } catch (e) {
      print('❌ 數據導入失敗: $e');
      return false;
    }
  }
  
  /// 更新最後同步時間
  static void _updateLastSync() {
    final now = DateTime.now();
    final timeString = '${now.year}/${now.month}/${now.day} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    html.window.localStorage[_lastSyncKey] = timeString;
  }
  
  /// 檢查數據是否存在
  static bool hasData() {
    return html.window.localStorage.containsKey(_studentsKey) ||
           html.window.localStorage.containsKey(_scoresKey);
  }
}

