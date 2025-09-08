/// 裁判系統相關數據模型
/// 包含計分表、學生成績記錄等

import '../models/student.dart';
import '../constants/app_constants.dart';

/// 比賽階段
enum CompetitionStage {
  preliminary('初賽'),
  finals('決賽'),
  results('成績'),
  podium('三甲');

  const CompetitionStage(this.displayName);
  final String displayName;
}

/// 裁判計分表
class RefereeScoreSheet {
  final String id;
  final Division? division; // null表示總表
  final Gender gender;
  final DateTime createdAt;
  final List<StudentEventRecord> studentRecords;
  final String notes;
  final bool isCompleted;

  const RefereeScoreSheet({
    required this.id,
    required this.division,
    required this.gender,
    required this.createdAt,
    required this.studentRecords,
    this.notes = '',
    this.isCompleted = false,
  });

  /// 創建副本
  RefereeScoreSheet copyWith({
    String? id,
    Division? division,
    Gender? gender,
    DateTime? createdAt,
    List<StudentEventRecord>? studentRecords,
    String? notes,
    bool? isCompleted,
  }) {
    return RefereeScoreSheet(
      id: id ?? this.id,
      division: division ?? this.division,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      studentRecords: studentRecords ?? this.studentRecords,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// 轉換為JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'division': division?.index,
      'gender': gender.index,
      'createdAt': createdAt.toIso8601String(),
      'studentRecords': studentRecords.map((r) => r.toJson()).toList(),
      'notes': notes,
      'isCompleted': isCompleted,
    };
  }

  /// 從JSON創建
  factory RefereeScoreSheet.fromJson(Map<String, dynamic> json) {
    return RefereeScoreSheet(
      id: json['id'],
      division: json['division'] != null ? Division.values[json['division']] : null,
      gender: Gender.values[json['gender']],
      createdAt: DateTime.parse(json['createdAt']),
      studentRecords: (json['studentRecords'] as List)
          .map((r) => StudentEventRecord.fromJson(r))
          .toList(),
      notes: json['notes'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  /// 獲取特定學生的記錄
  StudentEventRecord? getStudentRecord(String studentId) {
    try {
      return studentRecords.firstWhere((r) => r.studentId == studentId);
    } catch (e) {
      return null;
    }
  }

  /// 獲取特定項目的所有結果
  List<EventResult> getEventResults(String eventCode) {
    return studentRecords
        .map((record) => record.eventResults[eventCode])
        .where((result) => result != null)
        .cast<EventResult>()
        .toList();
  }

  /// 計算項目排名
  List<RankedResult> calculateEventRanking(String eventCode, CompetitionStage stage) {
    final results = studentRecords
        .map((record) {
          final result = stage == CompetitionStage.preliminary 
              ? record.eventResults[eventCode]?.preliminaryResult
              : record.eventResults[eventCode]?.finalsResult;
          
          if (result == null) return null;
          
          return RankedResult(
            studentRecord: record,
            eventResult: result,
            eventCode: eventCode,
          );
        })
        .where((r) => r != null)
        .cast<RankedResult>()
        .toList();

    // 按成績排序 (時間越短越好，距離/高度越遠越好)
    results.sort((a, b) {
      final aResult = a.eventResult;
      final bResult = b.eventResult;
      
      // DNF/DQ排在最後
      if (aResult.isDNF || aResult.isDQ) return 1;
      if (bResult.isDNF || bResult.isDQ) return -1;
      
      // 比較成績
      if (aResult.timeResult != null && bResult.timeResult != null) {
        return aResult.timeResult!.compareTo(bResult.timeResult!); // 時間越短越好
      } else if (aResult.distanceResult != null && bResult.distanceResult != null) {
        return bResult.distanceResult!.compareTo(aResult.distanceResult!); // 距離越遠越好
      } else if (aResult.heightResult != null && bResult.heightResult != null) {
        return bResult.heightResult!.compareTo(aResult.heightResult!); // 高度越高越好
      }
      
      return 0;
    });

    // 分配名次
    for (int i = 0; i < results.length; i++) {
      if (!results[i].eventResult.isDNF && !results[i].eventResult.isDQ) {
        results[i] = results[i].copyWith(position: i + 1);
      }
    }

    return results;
  }

  /// 獲取決賽名單
  List<RankedResult> getFinalists(String eventCode) {
    final preliminaryRanking = calculateEventRanking(eventCode, CompetitionStage.preliminary);
    return preliminaryRanking
        .where((r) => !r.eventResult.isDNF && !r.eventResult.isDQ)
        .take(AppConstants.finalsQualifiers)
        .toList();
  }

  /// 獲取三甲名單
  List<RankedResult> getPodium(String eventCode) {
    final finalsRanking = calculateEventRanking(eventCode, CompetitionStage.finals);
    return finalsRanking
        .where((r) => !r.eventResult.isDNF && !r.eventResult.isDQ)
        .take(AppConstants.podiumPositions)
        .toList();
  }
}

/// 學生項目成績記錄
class StudentEventRecord {
  final String studentId;
  final String studentName;
  final String classId;
  final String studentNumber;
  final bool isStaff;
  final Map<String, EventCompetitionRecord> eventResults; // 項目代碼 -> 比賽記錄
  
  /// 學生編號
  String get studentCode => '$classId${studentNumber.padLeft(2, '0')}';

  /// 總分（包含工作人員獎勵分）
  int get totalPoints {
    int total = 0;
    
    // 工作人員獎勵分
    total += AppConstants.calculateStaffBonus(isStaff);
    
    // 各項目得分
    for (final record in eventResults.values) {
      total += record.totalPoints;
    }
    
    return total;
  }

  const StudentEventRecord({
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.studentNumber,
    required this.isStaff,
    required this.eventResults,
  });

  /// 創建副本
  StudentEventRecord copyWith({
    String? studentId,
    String? studentName,
    String? classId,
    String? studentNumber,
    bool? isStaff,
    Map<String, EventCompetitionRecord>? eventResults,
  }) {
    return StudentEventRecord(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      studentNumber: studentNumber ?? this.studentNumber,
      isStaff: isStaff ?? this.isStaff,
      eventResults: eventResults ?? this.eventResults,
    );
  }

  /// 轉換為JSON
  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'studentNumber': studentNumber,
      'isStaff': isStaff,
      'eventResults': eventResults.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  /// 從JSON創建
  factory StudentEventRecord.fromJson(Map<String, dynamic> json) {
    return StudentEventRecord(
      studentId: json['studentId'],
      studentName: json['studentName'],
      classId: json['classId'],
      studentNumber: json['studentNumber'],
      isStaff: json['isStaff'] ?? false,
      eventResults: (json['eventResults'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, EventCompetitionRecord.fromJson(v)),
      ),
    );
  }
}

/// 項目比賽記錄（包含初賽和決賽）
class EventCompetitionRecord {
  final String eventCode;
  final EventResult? preliminaryResult; // 初賽成績
  final EventResult? finalsResult;      // 決賽成績
  final bool isDirectFinals;            // 是否直接決賽

  /// 總分
  int get totalPoints {
    int total = 0;
    
    // 初賽分數
    if (preliminaryResult != null) {
      total += preliminaryResult!.points;
    }
    
    // 決賽分數
    if (finalsResult != null) {
      total += finalsResult!.points;
    }
    
    return total;
  }

  /// 最佳成績
  EventResult? get bestResult {
    if (finalsResult != null) return finalsResult;
    return preliminaryResult;
  }

  const EventCompetitionRecord({
    required this.eventCode,
    this.preliminaryResult,
    this.finalsResult,
    this.isDirectFinals = false,
  });

  /// 創建副本
  EventCompetitionRecord copyWith({
    String? eventCode,
    EventResult? preliminaryResult,
    EventResult? finalsResult,
    bool? isDirectFinals,
  }) {
    return EventCompetitionRecord(
      eventCode: eventCode ?? this.eventCode,
      preliminaryResult: preliminaryResult ?? this.preliminaryResult,
      finalsResult: finalsResult ?? this.finalsResult,
      isDirectFinals: isDirectFinals ?? this.isDirectFinals,
    );
  }

  /// 轉換為JSON
  Map<String, dynamic> toJson() {
    return {
      'eventCode': eventCode,
      'preliminaryResult': preliminaryResult?.toJson(),
      'finalsResult': finalsResult?.toJson(),
      'isDirectFinals': isDirectFinals,
    };
  }

  /// 從JSON創建
  factory EventCompetitionRecord.fromJson(Map<String, dynamic> json) {
    return EventCompetitionRecord(
      eventCode: json['eventCode'],
      preliminaryResult: json['preliminaryResult'] != null
          ? EventResult.fromJson(json['preliminaryResult'])
          : null,
      finalsResult: json['finalsResult'] != null
          ? EventResult.fromJson(json['finalsResult'])
          : null,
      isDirectFinals: json['isDirectFinals'] ?? false,
    );
  }
}

/// 項目成績結果
class EventResult {
  final String eventCode;
  final double? timeResult;     // 時間成績（秒）
  final double? distanceResult; // 距離成績（米）
  final double? heightResult;   // 高度成績（米）
  final int position;           // 名次
  final int points;             // 得分
  final bool isRecordBreaker;   // 是否破紀錄
  final bool isDNF;             // Did Not Finish
  final bool isDQ;              // Disqualified
  final bool isABS;             // Absent
  final String notes;           // 備註

  const EventResult({
    required this.eventCode,
    this.timeResult,
    this.distanceResult,
    this.heightResult,
    this.position = 0,
    this.points = 0,
    this.isRecordBreaker = false,
    this.isDNF = false,
    this.isDQ = false,
    this.isABS = false,
    this.notes = '',
  });

  /// 格式化顯示成績
  String get formattedResult {
    if (isABS) return 'ABS';
    if (isDNF) return 'DNF';
    if (isDQ) return 'DQ';
    
    if (timeResult != null) {
      return '${timeResult!.toStringAsFixed(2)}s';
    } else if (distanceResult != null) {
      return '${distanceResult!.toStringAsFixed(2)}m';
    } else if (heightResult != null) {
      return '${heightResult!.toStringAsFixed(2)}m';
    }
    
    return '--';
  }

  /// 創建副本
  EventResult copyWith({
    String? eventCode,
    double? timeResult,
    double? distanceResult,
    double? heightResult,
    int? position,
    int? points,
    bool? isRecordBreaker,
    bool? isDNF,
    bool? isDQ,
    bool? isABS,
    String? notes,
  }) {
    return EventResult(
      eventCode: eventCode ?? this.eventCode,
      timeResult: timeResult ?? this.timeResult,
      distanceResult: distanceResult ?? this.distanceResult,
      heightResult: heightResult ?? this.heightResult,
      position: position ?? this.position,
      points: points ?? this.points,
      isRecordBreaker: isRecordBreaker ?? this.isRecordBreaker,
      isDNF: isDNF ?? this.isDNF,
      isDQ: isDQ ?? this.isDQ,
      isABS: isABS ?? this.isABS,
      notes: notes ?? this.notes,
    );
  }

  /// 轉換為JSON
  Map<String, dynamic> toJson() {
    return {
      'eventCode': eventCode,
      'timeResult': timeResult,
      'distanceResult': distanceResult,
      'heightResult': heightResult,
      'position': position,
      'points': points,
      'isRecordBreaker': isRecordBreaker,
      'isDNF': isDNF,
      'isDQ': isDQ,
      'isABS': isABS,
      'notes': notes,
    };
  }

  /// 從JSON創建
  factory EventResult.fromJson(Map<String, dynamic> json) {
    return EventResult(
      eventCode: json['eventCode'],
      timeResult: json['timeResult']?.toDouble(),
      distanceResult: json['distanceResult']?.toDouble(),
      heightResult: json['heightResult']?.toDouble(),
      position: json['position'] ?? 0,
      points: json['points'] ?? 0,
      isRecordBreaker: json['isRecordBreaker'] ?? false,
      isDNF: json['isDNF'] ?? false,
      isDQ: json['isDQ'] ?? false,
      isABS: json['isABS'] ?? false,
      notes: json['notes'] ?? '',
    );
  }
}

/// 排名結果
class RankedResult {
  final StudentEventRecord studentRecord;
  final EventResult eventResult;
  final String eventCode;
  final int position;

  const RankedResult({
    required this.studentRecord,
    required this.eventResult,
    required this.eventCode,
    this.position = 0,
  });

  /// 創建副本
  RankedResult copyWith({
    StudentEventRecord? studentRecord,
    EventResult? eventResult,
    String? eventCode,
    int? position,
  }) {
    return RankedResult(
      studentRecord: studentRecord ?? this.studentRecord,
      eventResult: eventResult ?? this.eventResult,
      eventCode: eventCode ?? this.eventCode,
      position: position ?? this.position,
    );
  }
}

/// 決賽參賽者
class Finalist {
  final String studentId;
  final String studentName;
  final String studentCode;
  final bool isStaff;
  final double preliminaryResult;
  final String preliminaryResultFormatted;
  final int preliminaryRank;

  const Finalist({
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.isStaff,
    required this.preliminaryResult,
    required this.preliminaryResultFormatted,
    required this.preliminaryRank,
  });

  /// 轉換為JSON
  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentCode': studentCode,
      'isStaff': isStaff,
      'preliminaryResult': preliminaryResult,
      'preliminaryResultFormatted': preliminaryResultFormatted,
      'preliminaryRank': preliminaryRank,
    };
  }

  /// 從JSON創建
  factory Finalist.fromJson(Map<String, dynamic> json) {
    return Finalist(
      studentId: json['studentId'],
      studentName: json['studentName'],
      studentCode: json['studentCode'],
      isStaff: json['isStaff'] ?? false,
      preliminaryResult: (json['preliminaryResult'] ?? 0.0).toDouble(),
      preliminaryResultFormatted: json['preliminaryResultFormatted'] ?? '',
      preliminaryRank: json['preliminaryRank'] ?? 0,
    );
  }
}

/// 三甲名單參賽者
class PodiumWinner {
  final String studentId;
  final String studentName;
  final String studentCode;
  final String? className;      // 班別（個人項目）或隊伍信息（接力項目）
  final bool isStaff;
  final double result;
  final String finalResult;
  final int points;
  final int rank;               // 排名（支持並列）
  final String? tieBreakingReason; // 並列名次的比較說明
  final bool submittedToAwards; // 是否已提交頒獎組
  final bool archived;          // 是否已存檔

  const PodiumWinner({
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    this.className,
    required this.isStaff,
    required this.result,
    required this.finalResult,
    required this.points,
    this.rank = 1,
    this.tieBreakingReason,
    this.submittedToAwards = false,
    this.archived = false,
  });

  /// 轉換為JSON
  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentCode': studentCode,
      'className': className,
      'isStaff': isStaff,
      'result': result,
      'finalResult': finalResult,
      'points': points,
      'rank': rank,
      'tieBreakingReason': tieBreakingReason,
      'submittedToAwards': submittedToAwards,
      'archived': archived,
    };
  }

  /// 從JSON創建
  factory PodiumWinner.fromJson(Map<String, dynamic> json) {
    return PodiumWinner(
      studentId: json['studentId'],
      studentName: json['studentName'],
      studentCode: json['studentCode'],
      className: json['className'],
      isStaff: json['isStaff'] ?? false,
      result: (json['result'] ?? 0.0).toDouble(),
      finalResult: json['finalResult'] ?? '',
      points: json['points'] ?? 0,
      rank: json['rank'] ?? 1,
      tieBreakingReason: json['tieBreakingReason'],
      submittedToAwards: json['submittedToAwards'] ?? false,
      archived: json['archived'] ?? false,
    );
  }
} 