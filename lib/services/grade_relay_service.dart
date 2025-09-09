/// 年級接力賽管理服務
/// 按年級組織接力賽，不分甲乙丙組，所有班級均可參與

import 'dart:convert';
import 'dart:html' as html;
import '../models/student.dart';
import '../models/event.dart' show EventType;
import '../constants/app_constants.dart';
import 'scoring_service.dart';

/// 年級接力賽服務
class GradeRelayService {
  static const String _storageKey = 'grade_relay_results';
  
  /// 接力賽結果資料 - eventCode -> grade -> classId -> RelayTeamResult
  static final Map<String, Map<int, Map<String, RelayTeamResult>>> _relayResults = {};
  
  /// 所有可用年級 (1-6年級)
  static const List<int> availableGrades = [1, 2, 3, 4, 5, 6];
  
  /// 接力賽項目代碼
  static const List<String> relayEvents = ['4x100c', '4x400c', '4x100s', '4x400s'];
  
  /// 初始化服務
  static Future<void> initialize() async {
    await _loadResults();
  }
  
  /// 載入結果
  static Future<void> _loadResults() async {
    try {
      final data = html.window.localStorage[_storageKey];
      if (data != null) {
        final jsonData = json.decode(data);
        _relayResults.clear();
        
        for (final eventCode in jsonData.keys) {
          _relayResults[eventCode] = {};
          final eventData = jsonData[eventCode];
          
          for (final gradeStr in eventData.keys) {
            final grade = int.tryParse(gradeStr) ?? 1;
            _relayResults[eventCode]![grade] = {};
            final gradeData = eventData[gradeStr];
            
            for (final classId in gradeData.keys) {
              _relayResults[eventCode]![grade]![classId] = 
                RelayTeamResult.fromJson(gradeData[classId]);
            }
          }
        }
      }
    } catch (e) {
      print('載入年級接力賽結果失敗：$e');
    }
  }
  
  /// 儲存結果
  static Future<void> _saveResults() async {
    try {
      final jsonData = <String, dynamic>{};
      
      for (final eventCode in _relayResults.keys) {
        jsonData[eventCode] = {};
        
        for (final grade in _relayResults[eventCode]!.keys) {
          jsonData[eventCode][grade.toString()] = {};
          
          for (final classId in _relayResults[eventCode]![grade]!.keys) {
            jsonData[eventCode][grade.toString()][classId] = 
              _relayResults[eventCode]![grade]![classId]!.toJson();
          }
        }
      }
      
      html.window.localStorage[_storageKey] = json.encode(jsonData);
    } catch (e) {
      print('儲存年級接力賽結果失敗：$e');
    }
  }
  
  /// 更新班級成績
  static Future<void> updateClassResult({
    required String eventCode,
    required int grade,
    required String classId,
    required String result,
    List<String>? participants,
  }) async {
    try {
      // 驗證成績格式
      if (!_isValidTimeFormat(result)) {
        throw '成績格式錯誤，請使用 mm:ss.ms 格式';
      }
      
      // 初始化數據結構
      _relayResults.putIfAbsent(eventCode, () => {});
      _relayResults[eventCode]!.putIfAbsent(grade, () => {});
      
      // 創建成績記錄
      final teamResult = RelayTeamResult(
        classId: classId,
        grade: grade,
        eventCode: eventCode,
        result: result,
        participants: participants ?? [],
        timestamp: DateTime.now(),
      );
      
      // 更新結果
      _relayResults[eventCode]![grade]![classId] = teamResult;
      
      // 計算排名和積分
      await _calculateRankingsAndPoints(eventCode, grade);
      
      // 儲存結果
      await _saveResults();
      
      print('✅ 已更新 ${grade}年級 $classId $eventCode 成績：$result');
    } catch (e) {
      print('❌ 更新年級接力賽成績失敗：$e');
      rethrow;
    }
  }
  
  /// 計算排名和積分
  static Future<void> _calculateRankingsAndPoints(String eventCode, int grade) async {
    final gradeResults = _relayResults[eventCode]?[grade];
    if (gradeResults == null || gradeResults.isEmpty) return;
    
    // 按成績排序
    final sortedResults = gradeResults.values.toList();
    sortedResults.sort((a, b) => _compareResults(a.result, b.result));
    
    // 分配排名和積分
    for (int i = 0; i < sortedResults.length; i++) {
      final result = sortedResults[i];
      result.rank = i + 1;
      result.points = AppConstants.calculatePositionPoints(result.rank, EventType.relay);
      
      // 更新到ScoringService - 使用特殊的班級代表ID
      final relayRepresentativeId = '${result.classId}_relay_representative';
      ScoringService.updateStudentScore(
        studentId: relayRepresentativeId,
        eventCode: eventCode,
        finalsRank: result.rank,
        finalsResult: result.result,
      );
    }
  }
  
  /// 獲取年級排名
  static List<RelayTeamResult> getGradeRankings(String eventCode, int grade) {
    final gradeResults = _relayResults[eventCode]?[grade];
    if (gradeResults == null) return [];
    
    final results = gradeResults.values.toList();
    results.sort((a, b) => a.rank.compareTo(b.rank));
    return results;
  }
  
  /// 獲取前三名
  static List<RelayTeamResult> getTopThree(String eventCode, int grade) {
    final rankings = getGradeRankings(eventCode, grade);
    return rankings.take(3).toList();
  }
  
  /// 獲取班級成績
  static RelayTeamResult? getClassResult(String eventCode, int grade, String classId) {
    return _relayResults[eventCode]?[grade]?[classId];
  }
  
  /// 驗證時間格式
  static bool _isValidTimeFormat(String time) {
    final RegExp timePattern = RegExp(r'^\d{1,2}:\d{2}\.\d{2}$');
    return timePattern.hasMatch(time);
  }
  
  /// 比較成績（時間越小越好）
  static int _compareResults(String result1, String result2) {
    final time1 = _parseTimeToMilliseconds(result1);
    final time2 = _parseTimeToMilliseconds(result2);
    return time1.compareTo(time2);
  }
  
  /// 解析時間到毫秒
  static int _parseTimeToMilliseconds(String time) {
    try {
      final parts = time.split(':');
      final minutes = int.parse(parts[0]);
      final secondParts = parts[1].split('.');
      final seconds = int.parse(secondParts[0]);
      final milliseconds = int.parse(secondParts[1]) * 10; // 假設是百分之一秒
      
      return minutes * 60000 + seconds * 1000 + milliseconds;
    } catch (e) {
      return 999999; // 無效時間排在最後
    }
  }
  
  /// 獲取所有結果摘要
  static Map<String, dynamic> getAllResultsSummary() {
    final summary = <String, dynamic>{};
    
    for (final eventCode in relayEvents) {
      summary[eventCode] = {};
      
      for (final grade in availableGrades) {
        final rankings = getGradeRankings(eventCode, grade);
        if (rankings.isNotEmpty) {
          summary[eventCode]['grade_$grade'] = rankings.map((r) => {
            'classId': r.classId,
            'result': r.result,
            'rank': r.rank,
            'points': r.points,
          }).toList();
        }
      }
    }
    
    return summary;
  }
}

/// 年級接力賽團體成績
class RelayTeamResult {
  final String classId;
  final int grade;
  final String eventCode;
  final String result;
  final List<String> participants;
  final DateTime timestamp;
  int rank = 0;
  int points = 0;

  RelayTeamResult({
    required this.classId,
    required this.grade,
    required this.eventCode,
    required this.result,
    this.participants = const [],
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'grade': grade,
      'eventCode': eventCode,
      'result': result,
      'participants': participants,
      'timestamp': timestamp.toIso8601String(),
      'rank': rank,
      'points': points,
    };
  }
  
  factory RelayTeamResult.fromJson(Map<String, dynamic> json) {
    final result = RelayTeamResult(
      classId: json['classId'],
      grade: json['grade'] ?? 1,
      eventCode: json['eventCode'],
      result: json['result'],
      participants: List<String>.from(json['participants'] ?? []),
      timestamp: DateTime.parse(json['timestamp']),
    );
    result.rank = json['rank'] ?? 0;
    result.points = json['points'] ?? 0;
    return result;
  }
}
