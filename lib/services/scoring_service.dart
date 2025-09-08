/// 積分管理服務
/// 統一管理成績、積分計算和實時更新

import 'dart:convert';
import '../models/student.dart';
import '../models/event.dart' as EventModel;
import '../constants/event_constants.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';
import 'records_service.dart';
import 'realtime_sync_service.dart';

/// 學生成績記錄
class StudentScore {
  final String studentId;
  final String eventCode;
  final String? preliminaryResult;
  final String? finalsResult;
  final int preliminaryRank;
  final int finalsRank;
  final bool isDNF;
  final bool isDQ;
  final bool isABS;
  final bool isRecordBreaker;
  final int participationPoints;
  final int awardPoints;
  final int recordBonus;
  final int totalPoints;
  final DateTime lastUpdated;

  StudentScore({
    required this.studentId,
    required this.eventCode,
    this.preliminaryResult,
    this.finalsResult,
    this.preliminaryRank = 0,
    this.finalsRank = 0,
    this.isDNF = false,
    this.isDQ = false,
    this.isABS = false,
    this.isRecordBreaker = false,
    required this.participationPoints,
    required this.awardPoints,
    required this.recordBonus,
    required this.totalPoints,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'eventCode': eventCode,
      'preliminaryResult': preliminaryResult,
      'finalsResult': finalsResult,
      'preliminaryRank': preliminaryRank,
      'finalsRank': finalsRank,
      'isDNF': isDNF,
      'isDQ': isDQ,
      'isABS': isABS,
      'isRecordBreaker': isRecordBreaker,
      'participationPoints': participationPoints,
      'awardPoints': awardPoints,
      'recordBonus': recordBonus,
      'totalPoints': totalPoints,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory StudentScore.fromJson(Map<String, dynamic> json) {
    return StudentScore(
      studentId: json['studentId'] as String,
      eventCode: json['eventCode'] as String,
      preliminaryResult: json['preliminaryResult'] as String?,
      finalsResult: json['finalsResult'] as String?,
      preliminaryRank: json['preliminaryRank'] as int? ?? 0,
      finalsRank: json['finalsRank'] as int? ?? 0,
      isDNF: json['isDNF'] as bool? ?? false,
      isDQ: json['isDQ'] as bool? ?? false,
      isABS: json['isABS'] as bool? ?? false,
      isRecordBreaker: json['isRecordBreaker'] as bool? ?? false,
      participationPoints: json['participationPoints'] as int,
      awardPoints: json['awardPoints'] as int,
      recordBonus: json['recordBonus'] as int,
      totalPoints: json['totalPoints'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}

/// 積分管理服務
class ScoringService {
  static final Map<String, StudentScore> _studentScores = {};
  
  /// 獲取所有學生成績
  static Map<String, StudentScore> get allScores => Map.from(_studentScores);
  
  /// 獲取學生特定項目的成績
  static StudentScore? getStudentScore(String studentId, String eventCode) {
    final key = '${studentId}_$eventCode';
    return _studentScores[key];
  }
  
  /// 獲取學生的所有成績
  static List<StudentScore> getStudentAllScores(String studentId) {
    return _studentScores.values
        .where((score) => score.studentId == studentId)
        .toList();
  }
  
  /// 獲取項目的所有成績
  static List<StudentScore> getEventScores(String eventCode) {
    return _studentScores.values
        .where((score) => score.eventCode == eventCode)
        .toList();
  }
  
  /// 更新學生成績（從裁判系統調用）
  static Future<void> updateStudentScore({
    required String studentId,
    required String eventCode,
    String? preliminaryResult,
    String? finalsResult,
    int preliminaryRank = 0,
    int finalsRank = 0,
    bool isDNF = false,
    bool isDQ = false,
    bool isABS = false,
    bool isRecordBreaker = false,
    Gender? gender,          // 新增性別參數
    Division? division,      // 新增組別參數
    String? eventName,       // 新增項目名稱參數
  }) async {
    final key = '${studentId}_$eventCode';
    
    // 計算積分，包含標準成績和破紀錄檢查
    final scores = _calculateScores(
      eventCode: eventCode,
      preliminaryRank: preliminaryRank,
      finalsRank: finalsRank,
      hasResult: (preliminaryResult?.isNotEmpty ?? false) || (finalsResult?.isNotEmpty ?? false),
      isDNF: isDNF,
      isDQ: isDQ,
      isABS: isABS,
      isRecordBreaker: isRecordBreaker,
      gender: gender,
      division: division,
      eventName: eventName,
      finalResult: finalsResult,
    );
    
    final studentScore = StudentScore(
      studentId: studentId,
      eventCode: eventCode,
      preliminaryResult: preliminaryResult,
      finalsResult: finalsResult,
      preliminaryRank: preliminaryRank,
      finalsRank: finalsRank,
      isDNF: isDNF,
      isDQ: isDQ,
      isABS: isABS,
      isRecordBreaker: isRecordBreaker,
      participationPoints: scores['participation']!,
      awardPoints: scores['award']!,
      recordBonus: scores['record']!,
      totalPoints: scores['total']!,
      lastUpdated: DateTime.now(),
    );
    
    _studentScores[key] = studentScore;
    
    // 保存到本地存儲
    await _saveScores();
    
    // 實時同步（暫時註釋，需要實現syncData方法）
    // await RealtimeSyncService.syncData('scores', allScores);
    
    print('✅ 已更新學生成績和積分：$studentId - $eventCode (總分：${scores['total']})');
  }
  
  /// 批量更新項目成績排名（當整個項目成績確認時調用）
  static Future<void> updateEventRankings(String eventCode, List<StudentScore> rankedScores) async {
    for (int i = 0; i < rankedScores.length; i++) {
      final score = rankedScores[i];
      final rank = i + 1;
      
      await updateStudentScore(
        studentId: score.studentId,
        eventCode: eventCode,
        preliminaryResult: score.preliminaryResult,
        finalsResult: score.finalsResult,
        preliminaryRank: score.preliminaryRank,
        finalsRank: rank, // 更新決賽排名
        isDNF: score.isDNF,
        isDQ: score.isDQ,
        isABS: score.isABS,
        isRecordBreaker: score.isRecordBreaker,
      );
    }
    
    print('✅ 已批量更新項目排名：$eventCode (${rankedScores.length}人)');
  }
  
  /// 計算學生總積分
  static int getStudentTotalPoints(String studentId) {
    final studentScores = getStudentAllScores(studentId);
    return studentScores.fold(0, (total, score) => total + score.totalPoints);
  }
  
  /// 計算班級總積分
  static int getClassTotalPoints(String classId, List<Student> students) {
    final classStudents = students.where((s) => s.classId == classId).toList();
    int total = 0;
    
    for (final student in classStudents) {
      total += getStudentTotalPoints(student.id);
    }
    
    return total;
  }
  
  /// 私有方法：計算各項積分
  static Map<String, int> _calculateScores({
    required String eventCode,
    required int preliminaryRank,
    required int finalsRank,
    required bool hasResult,
    required bool isDNF,
    required bool isDQ,
    required bool isABS,
    required bool isRecordBreaker,
    Gender? gender,
    Division? division,
    String? eventName,
    String? finalResult,
  }) {
    final event = EventConstants.allEvents.firstWhere(
      (e) => e.code == eventCode,
      orElse: () => throw Exception('Event not found: $eventCode'),
    );
    
    // 參與分
    int participationPoints = 0;
    if (isABS) {
      participationPoints = AppConstants.absentPenalty;
    } else if (isDNF || isDQ) {
      participationPoints = AppConstants.dnfPoints;
    } else if (hasResult) {
      participationPoints = AppConstants.participationPoints;
    }
    
    // 名次分（只有決賽排名才計分）
    int awardPoints = 0;
    if (finalsRank > 0 && finalsRank <= 8 && !isDNF && !isDQ && !isABS) {
      final eventType = event.category == EventCategory.relay ? EventModel.EventType.relay : EventModel.EventType.individual;
      awardPoints = AppConstants.calculatePositionPoints(finalsRank, eventType);
    }
    
    // 破紀錄和標準成績獎勵分
    int recordBonus = 0;
    
    // 如果明確標記為破紀錄
    if (isRecordBreaker) {
      recordBonus += 3; // 破校紀錄+3分
    } 
    // 自動檢查破紀錄和標準成績
    else if (finalResult != null && finalResult.isNotEmpty && 
             gender != null && division != null && eventName != null) {
      try {
        // 檢查是否破校紀錄
        if (RecordsService.breaksRecord(eventName, gender, division, finalResult)) {
          recordBonus += 3; // 破校紀錄+3分
        }
        // 如果沒破紀錄，檢查是否達標準成績
        else if (RecordsService.meetsStandard(eventName, gender, division, finalResult)) {
          recordBonus += 1; // 達標準成績+1分
        }
      } catch (e) {
        // 如果紀錄檢查失敗，使用原有邏輯
        print('紀錄檢查失敗：$e');
      }
    }
    
    // 總分
    int totalPoints = participationPoints + awardPoints + recordBonus;
    
    return {
      'participation': participationPoints,
      'award': awardPoints,
      'record': recordBonus,
      'total': totalPoints,
    };
  }
  
  /// 保存成績到本地存儲
  static Future<void> _saveScores() async {
    final scoresJson = _studentScores.map((key, score) => MapEntry(key, json.encode(score.toJson())));
    await StorageService.saveScores(scoresJson);
  }
  
  /// 從本地存儲載入成績
  static Future<void> loadScores() async {
    try {
      final scoresData = await StorageService.loadScores();
      if (scoresData != null) {
        _studentScores.clear();
        (scoresData as Map<String, String>).forEach((key, value) {
          _studentScores[key] = StudentScore.fromJson(json.decode(value) as Map<String, dynamic>);
        });
        print('✅ 已載入學生成績：${_studentScores.length}條記錄');
      }
    } catch (e) {
      print('❌ 載入學生成績失敗：$e');
    }
  }
  
  /// 清除所有成績
  static Future<void> clearAllScores() async {
    _studentScores.clear();
    // 清除本地存儲中的成績數據
    print('✅ 已清除所有學生成績');
  }
  
  /// 獲取項目統計信息
  static Map<String, dynamic> getEventStats(String eventCode) {
    final eventScores = getEventScores(eventCode);
    final totalParticipants = eventScores.length;
    final finalists = eventScores.where((s) => s.finalsRank > 0).length;
    final medalists = eventScores.where((s) => s.finalsRank > 0 && s.finalsRank <= 3).length;
    
    return {
      'totalParticipants': totalParticipants,
      'finalists': finalists,
      'medalists': medalists,
      'lastUpdated': eventScores.isNotEmpty 
          ? eventScores.map((s) => s.lastUpdated).reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }
}
