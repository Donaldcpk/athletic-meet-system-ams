import 'student.dart';
import 'event.dart';
import '../constants/app_constants.dart';

/// 比賽成績記錄模型
/// 支援田賽、徑賽和接力項目的成績記錄
class Result {
  final String id;
  final String eventId;
  final String studentId;
  final String? teamId; // 接力或團體項目的隊伍ID
  
  // 成績資料
  final double finalResult; // 最終成績
  final List<AttemptResult> attempts; // 各次嘗試成績（田賽用）
  final int position; // 最終排名
  final int points; // 獲得積分
  
  // 比賽資訊
  final DateTime competitionDate; // 比賽日期
  final String? lane; // 道次（徑賽用）
  final String? group; // 組別（如預賽A組）
  final CompetitionRound round; // 比賽輪次
  
  // 記錄狀態
  final bool isNewRecord; // 是否創新記錄
  final RecordType? recordType; // 記錄類型
  final bool isDisqualified; // 是否被取消資格
  final String? disqualificationReason; // 取消資格原因
  
  // 裁判資訊
  final String judgeId; // 裁判員ID
  final String? judgeName; // 裁判員姓名
  final DateTime recordedTime; // 記錄時間
  final String? notes; // 備註
  
  // 驗證狀態
  final bool isVerified; // 是否已驗證
  final String? verifiedBy; // 驗證人員
  final DateTime? verificationTime; // 驗證時間

  const Result({
    required this.id,
    required this.eventId,
    required this.studentId,
    this.teamId,
    required this.finalResult,
    this.attempts = const [],
    required this.position,
    required this.points,
    required this.competitionDate,
    this.lane,
    this.group,
    this.round = CompetitionRound.finals,
    this.isNewRecord = false,
    this.recordType,
    this.isDisqualified = false,
    this.disqualificationReason,
    required this.judgeId,
    this.judgeName,
    required this.recordedTime,
    this.notes,
    this.isVerified = false,
    this.verifiedBy,
    this.verificationTime,
  });

  /// 從 JSON 創建成績物件
  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      studentId: json['studentId'] as String,
      teamId: json['teamId'] as String?,
      finalResult: (json['finalResult'] as num).toDouble(),
      attempts: (json['attempts'] as List?)
          ?.map((e) => AttemptResult.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      position: json['position'] as int,
      points: json['points'] as int,
      competitionDate: DateTime.parse(json['competitionDate'] as String),
      lane: json['lane'] as String?,
      group: json['group'] as String?,
      round: CompetitionRound.values.byName(json['round'] as String? ?? 'finals'),
      isNewRecord: json['isNewRecord'] as bool? ?? false,
      recordType: json['recordType'] != null 
          ? RecordType.values.byName(json['recordType'] as String)
          : null,
      isDisqualified: json['isDisqualified'] as bool? ?? false,
      disqualificationReason: json['disqualificationReason'] as String?,
      judgeId: json['judgeId'] as String,
      judgeName: json['judgeName'] as String?,
      recordedTime: DateTime.parse(json['recordedTime'] as String),
      notes: json['notes'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      verifiedBy: json['verifiedBy'] as String?,
      verificationTime: json['verificationTime'] != null
          ? DateTime.parse(json['verificationTime'] as String)
          : null,
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'studentId': studentId,
      'teamId': teamId,
      'finalResult': finalResult,
      'attempts': attempts.map((e) => e.toJson()).toList(),
      'position': position,
      'points': points,
      'competitionDate': competitionDate.toIso8601String(),
      'lane': lane,
      'group': group,
      'round': round.name,
      'isNewRecord': isNewRecord,
      'recordType': recordType?.name,
      'isDisqualified': isDisqualified,
      'disqualificationReason': disqualificationReason,
      'judgeId': judgeId,
      'judgeName': judgeName,
      'recordedTime': recordedTime.toIso8601String(),
      'notes': notes,
      'isVerified': isVerified,
      'verifiedBy': verifiedBy,
      'verificationTime': verificationTime?.toIso8601String(),
    };
  }

  /// 複製成績物件並修改指定欄位
  Result copyWith({
    String? id,
    String? eventId,
    String? studentId,
    String? teamId,
    double? finalResult,
    List<AttemptResult>? attempts,
    int? position,
    int? points,
    DateTime? competitionDate,
    String? lane,
    String? group,
    CompetitionRound? round,
    bool? isNewRecord,
    RecordType? recordType,
    bool? isDisqualified,
    String? disqualificationReason,
    String? judgeId,
    String? judgeName,
    DateTime? recordedTime,
    String? notes,
    bool? isVerified,
    String? verifiedBy,
    DateTime? verificationTime,
  }) {
    return Result(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      studentId: studentId ?? this.studentId,
      teamId: teamId ?? this.teamId,
      finalResult: finalResult ?? this.finalResult,
      attempts: attempts ?? this.attempts,
      position: position ?? this.position,
      points: points ?? this.points,
      competitionDate: competitionDate ?? this.competitionDate,
      lane: lane ?? this.lane,
      group: group ?? this.group,
      round: round ?? this.round,
      isNewRecord: isNewRecord ?? this.isNewRecord,
      recordType: recordType ?? this.recordType,
      isDisqualified: isDisqualified ?? this.isDisqualified,
      disqualificationReason: disqualificationReason ?? this.disqualificationReason,
      judgeId: judgeId ?? this.judgeId,
      judgeName: judgeName ?? this.judgeName,
      recordedTime: recordedTime ?? this.recordedTime,
      notes: notes ?? this.notes,
      isVerified: isVerified ?? this.isVerified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verificationTime: verificationTime ?? this.verificationTime,
    );
  }

  /// 獲取最佳成績（田賽用）
  double get bestAttempt {
    if (attempts.isEmpty) return finalResult;
    
    final validAttempts = attempts.where((a) => a.isValid).toList();
    if (validAttempts.isEmpty) return 0.0;
    
    return validAttempts.map((a) => a.result).reduce((a, b) => a > b ? a : b);
  }

  /// 獲取名次顯示文字
  String get positionText {
    if (isDisqualified) return '失格';
    
    switch (position) {
      case 1:
        return '冠軍';
      case 2:
        return '亞軍';
      case 3:
        return '季軍';
      default:
        return '第${position}名';
    }
  }

  /// 計算積分（根據香港中學運動會標準）
  static int calculatePoints(int position, EventType eventType, {bool isRecordBreaker = false}) {
    // 獲取基本積分
    int basePoints = 0;
    
    if (eventType == EventType.relay) {
      // 接力項目積分
      basePoints = AppConstants.relayPointsTable[position] ?? 0;
    } else {
      // 個人項目積分
      basePoints = AppConstants.individualPointsTable[position] ?? 0;
    }
    
    // 破紀錄額外加分
    if (isRecordBreaker) {
      basePoints += AppConstants.recordBonusPoints;
    }
    
    return basePoints;
  }

  /// 計算並列名次的平均積分
  static double calculateTiedPoints(List<int> tiedPositions, EventType eventType) {
    if (tiedPositions.isEmpty) return 0.0;
    
    int totalPoints = 0;
    final pointsTable = eventType == EventType.relay 
        ? AppConstants.relayPointsTable 
        : AppConstants.individualPointsTable;
    
    for (int position in tiedPositions) {
      totalPoints += pointsTable[position] ?? 0;
    }
    
    return totalPoints / tiedPositions.length;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Result &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 單次嘗試結果（田賽用）
class AttemptResult {
  final int attemptNumber; // 第幾次嘗試
  final double result; // 成績
  final bool isValid; // 是否有效
  final String? invalidReason; // 無效原因（犯規等）
  final DateTime recordedTime; // 記錄時間

  const AttemptResult({
    required this.attemptNumber,
    required this.result,
    this.isValid = true,
    this.invalidReason,
    required this.recordedTime,
  });

  factory AttemptResult.fromJson(Map<String, dynamic> json) {
    return AttemptResult(
      attemptNumber: json['attemptNumber'] as int,
      result: (json['result'] as num).toDouble(),
      isValid: json['isValid'] as bool? ?? true,
      invalidReason: json['invalidReason'] as String?,
      recordedTime: DateTime.parse(json['recordedTime'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attemptNumber': attemptNumber,
      'result': result,
      'isValid': isValid,
      'invalidReason': invalidReason,
      'recordedTime': recordedTime.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttemptResult &&
          runtimeType == other.runtimeType &&
          attemptNumber == other.attemptNumber;

  @override
  int get hashCode => attemptNumber.hashCode;
}

/// 比賽輪次枚舉
enum CompetitionRound {
  preliminary('預賽'),
  semifinal('準決賽'),
  finals('決賽'),
  qualifying('資格賽');

  const CompetitionRound(this.displayName);
  final String displayName;
}

/// 記錄類型枚舉
enum RecordType {
  schoolRecord('校內記錄'),
  meetRecord('大會記錄'),
  personalBest('個人最佳');

  const RecordType(this.displayName);
  final String displayName;
}

/// 裁判記錄表格模型
/// 用於裁判在比賽現場記錄成績
class JudgeSheet {
  final String id;
  final String eventId;
  final String eventName;
  final String judgeId;
  final String judgeName;
  final DateTime createdTime;
  
  // 比賽設定
  final Gender gender;
  final Division division;
  final EventCategory category;
  final CompetitionRound round;
  final String? venue;
  
  // 參賽者列表
  final List<ParticipantEntry> participants;
  
  // 表格狀態
  final SheetStatus status;
  final DateTime? completedTime;
  final String? notes;
  final bool isSubmitted;
  final DateTime? submittedTime;

  const JudgeSheet({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.judgeId,
    required this.judgeName,
    required this.createdTime,
    required this.gender,
    required this.division,
    required this.category,
    this.round = CompetitionRound.finals,
    this.venue,
    this.participants = const [],
    this.status = SheetStatus.preparation,
    this.completedTime,
    this.notes,
    this.isSubmitted = false,
    this.submittedTime,
  });

  /// 從 JSON 創建裁判表格物件
  factory JudgeSheet.fromJson(Map<String, dynamic> json) {
    return JudgeSheet(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      eventName: json['eventName'] as String,
      judgeId: json['judgeId'] as String,
      judgeName: json['judgeName'] as String,
      createdTime: DateTime.parse(json['createdTime'] as String),
      gender: Gender.values.byName(json['gender'] as String),
      division: Division.values.byName(json['division'] as String),
      category: EventCategory.values.byName(json['category'] as String),
      round: CompetitionRound.values.byName(json['round'] as String? ?? 'finals'),
      venue: json['venue'] as String?,
      participants: (json['participants'] as List?)
          ?.map((e) => ParticipantEntry.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      status: SheetStatus.values.byName(json['status'] as String? ?? 'preparation'),
      completedTime: json['completedTime'] != null
          ? DateTime.parse(json['completedTime'] as String)
          : null,
      notes: json['notes'] as String?,
      isSubmitted: json['isSubmitted'] as bool? ?? false,
      submittedTime: json['submittedTime'] != null
          ? DateTime.parse(json['submittedTime'] as String)
          : null,
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'eventName': eventName,
      'judgeId': judgeId,
      'judgeName': judgeName,
      'createdTime': createdTime.toIso8601String(),
      'gender': gender.name,
      'division': division.name,
      'category': category.name,
      'round': round.name,
      'venue': venue,
      'participants': participants.map((e) => e.toJson()).toList(),
      'status': status.name,
      'completedTime': completedTime?.toIso8601String(),
      'notes': notes,
      'isSubmitted': isSubmitted,
      'submittedTime': submittedTime?.toIso8601String(),
    };
  }

  /// 複製裁判表格並修改指定欄位
  JudgeSheet copyWith({
    String? id,
    String? eventId,
    String? eventName,
    String? judgeId,
    String? judgeName,
    DateTime? createdTime,
    Gender? gender,
    Division? division,
    EventCategory? category,
    CompetitionRound? round,
    String? venue,
    List<ParticipantEntry>? participants,
    SheetStatus? status,
    DateTime? completedTime,
    String? notes,
    bool? isSubmitted,
    DateTime? submittedTime,
  }) {
    return JudgeSheet(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      judgeId: judgeId ?? this.judgeId,
      judgeName: judgeName ?? this.judgeName,
      createdTime: createdTime ?? this.createdTime,
      gender: gender ?? this.gender,
      division: division ?? this.division,
      category: category ?? this.category,
      round: round ?? this.round,
      venue: venue ?? this.venue,
      participants: participants ?? this.participants,
      status: status ?? this.status,
      completedTime: completedTime ?? this.completedTime,
      notes: notes ?? this.notes,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      submittedTime: submittedTime ?? this.submittedTime,
    );
  }

  /// 獲取完整標題
  String get fullTitle {
    return '$eventName - ${gender.displayName}${division.displayName}';
  }

  /// 檢查是否可以提交
  bool get canSubmit {
    return status == SheetStatus.inProgress &&
           participants.every((p) => p.hasResult) &&
           !isSubmitted;
  }

  /// 獲取進度百分比
  double get progress {
    if (participants.isEmpty) return 0.0;
    final completedCount = participants.where((p) => p.hasResult).length;
    return completedCount / participants.length;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JudgeSheet &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 參賽者記錄條目
class ParticipantEntry {
  final String studentId;
  final String studentName;
  final String classId;
  final String? lane; // 道次
  final int bibNumber; // 號碼布號碼
  
  // 成績記錄
  final double? finalResult;
  final List<AttemptResult> attempts; // 田賽用
  final bool isDisqualified;
  final String? disqualificationReason;
  final String? notes;

  const ParticipantEntry({
    required this.studentId,
    required this.studentName,
    required this.classId,
    this.lane,
    required this.bibNumber,
    this.finalResult,
    this.attempts = const [],
    this.isDisqualified = false,
    this.disqualificationReason,
    this.notes,
  });

  factory ParticipantEntry.fromJson(Map<String, dynamic> json) {
    return ParticipantEntry(
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      classId: json['classId'] as String,
      lane: json['lane'] as String?,
      bibNumber: json['bibNumber'] as int,
      finalResult: json['finalResult'] != null 
          ? (json['finalResult'] as num).toDouble()
          : null,
      attempts: (json['attempts'] as List?)
          ?.map((e) => AttemptResult.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      isDisqualified: json['isDisqualified'] as bool? ?? false,
      disqualificationReason: json['disqualificationReason'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'lane': lane,
      'bibNumber': bibNumber,
      'finalResult': finalResult,
      'attempts': attempts.map((e) => e.toJson()).toList(),
      'isDisqualified': isDisqualified,
      'disqualificationReason': disqualificationReason,
      'notes': notes,
    };
  }

  /// 複製參賽者條目並修改指定欄位
  ParticipantEntry copyWith({
    String? studentId,
    String? studentName,
    String? classId,
    String? lane,
    int? bibNumber,
    double? finalResult,
    List<AttemptResult>? attempts,
    bool? isDisqualified,
    String? disqualificationReason,
    String? notes,
  }) {
    return ParticipantEntry(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      lane: lane ?? this.lane,
      bibNumber: bibNumber ?? this.bibNumber,
      finalResult: finalResult ?? this.finalResult,
      attempts: attempts ?? this.attempts,
      isDisqualified: isDisqualified ?? this.isDisqualified,
      disqualificationReason: disqualificationReason ?? this.disqualificationReason,
      notes: notes ?? this.notes,
    );
  }

  /// 獲取參賽者顯示名稱
  String get displayName => '$classId $studentName (#$bibNumber)';

  /// 檢查是否已有成績
  bool get hasResult => finalResult != null || attempts.isNotEmpty || isDisqualified;

  /// 獲取最佳成績（田賽用）
  double? get bestAttempt {
    if (attempts.isEmpty) return finalResult;
    
    final validAttempts = attempts.where((a) => a.isValid).toList();
    if (validAttempts.isEmpty) return null;
    
    return validAttempts.map((a) => a.result).reduce((a, b) => a > b ? a : b);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticipantEntry &&
          runtimeType == other.runtimeType &&
          studentId == other.studentId;

  @override
  int get hashCode => studentId.hashCode;
}

/// 裁判表格狀態枚舉
enum SheetStatus {
  preparation('準備中'),
  inProgress('進行中'),
  completed('已完成'),
  submitted('已提交');

  const SheetStatus(this.displayName);
  final String displayName;
} 

/// 裁判記錄表數據模型
class RefereeScoreSheet {
  final String id;
  final Division division;
  final Gender gender;
  final DateTime createdAt;
  final List<StudentEventRecord> studentRecords;
  final Map<String, String> notes; // 備註信息
  final bool isCompleted;

  const RefereeScoreSheet({
    required this.id,
    required this.division,
    required this.gender,
    required this.createdAt,
    required this.studentRecords,
    this.notes = const {},
    this.isCompleted = false,
  });

  RefereeScoreSheet copyWith({
    String? id,
    Division? division,
    Gender? gender,
    DateTime? createdAt,
    List<StudentEventRecord>? studentRecords,
    Map<String, String>? notes,
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'division': division.name,
    'gender': gender.name,
    'createdAt': createdAt.toIso8601String(),
    'studentRecords': studentRecords.map((r) => r.toJson()).toList(),
    'notes': notes,
    'isCompleted': isCompleted,
  };

  factory RefereeScoreSheet.fromJson(Map<String, dynamic> json) => RefereeScoreSheet(
    id: json['id'] as String,
    division: Division.values.firstWhere((d) => d.name == json['division']),
    gender: Gender.values.firstWhere((g) => g.name == json['gender']),
    createdAt: DateTime.parse(json['createdAt'] as String),
    studentRecords: (json['studentRecords'] as List)
        .map((r) => StudentEventRecord.fromJson(r as Map<String, dynamic>))
        .toList(),
    notes: Map<String, String>.from(json['notes'] as Map),
    isCompleted: json['isCompleted'] as bool? ?? false,
  );
}

/// 學生項目成績記錄
class StudentEventRecord {
  final String studentId;
  final String studentName;
  final String classId;
  final String studentNumber;
  final bool isStaff;
  final Map<String, EventResult> eventResults; // 項目代碼 -> 成績
  final int totalPoints;

  const StudentEventRecord({
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.studentNumber,
    this.isStaff = false,
    required this.eventResults,
    this.totalPoints = 0,
  });

  StudentEventRecord copyWith({
    String? studentId,
    String? studentName,
    String? classId,
    String? studentNumber,
    bool? isStaff,
    Map<String, EventResult>? eventResults,
    int? totalPoints,
  }) {
    return StudentEventRecord(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      studentNumber: studentNumber ?? this.studentNumber,
      isStaff: isStaff ?? this.isStaff,
      eventResults: eventResults ?? this.eventResults,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'studentName': studentName,
    'classId': classId,
    'studentNumber': studentNumber,
    'isStaff': isStaff,
    'eventResults': eventResults.map((k, v) => MapEntry(k, v.toJson())),
    'totalPoints': totalPoints,
  };

  factory StudentEventRecord.fromJson(Map<String, dynamic> json) => StudentEventRecord(
    studentId: json['studentId'] as String,
    studentName: json['studentName'] as String,
    classId: json['classId'] as String,
    studentNumber: json['studentNumber'] as String,
    isStaff: json['isStaff'] as bool? ?? false,
    eventResults: (json['eventResults'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, EventResult.fromJson(v as Map<String, dynamic>)),
    ),
    totalPoints: json['totalPoints'] as int? ?? 0,
  );
}

/// 單項成績結果
class EventResult {
  final String eventCode;
  final String? timeResult;    // 時間成績（秒）
  final String? distanceResult; // 距離成績（米）
  final String? heightResult;   // 高度成績（米）
  final int? position;         // 名次
  final int points;            // 得分
  final bool isRecordBreaker;  // 是否破紀錄
  final bool isDNF;            // 是否未完成
  final bool isDQ;             // 是否被取消資格
  final String? notes;         // 備註

  const EventResult({
    required this.eventCode,
    this.timeResult,
    this.distanceResult,
    this.heightResult,
    this.position,
    this.points = 0,
    this.isRecordBreaker = false,
    this.isDNF = false,
    this.isDQ = false,
    this.notes,
  });

  EventResult copyWith({
    String? eventCode,
    String? timeResult,
    String? distanceResult,
    String? heightResult,
    int? position,
    int? points,
    bool? isRecordBreaker,
    bool? isDNF,
    bool? isDQ,
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
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'eventCode': eventCode,
    'timeResult': timeResult,
    'distanceResult': distanceResult,
    'heightResult': heightResult,
    'position': position,
    'points': points,
    'isRecordBreaker': isRecordBreaker,
    'isDNF': isDNF,
    'isDQ': isDQ,
    'notes': notes,
  };

  factory EventResult.fromJson(Map<String, dynamic> json) => EventResult(
    eventCode: json['eventCode'] as String,
    timeResult: json['timeResult'] as String?,
    distanceResult: json['distanceResult'] as String?,
    heightResult: json['heightResult'] as String?,
    position: json['position'] as int?,
    points: json['points'] as int? ?? 0,
    isRecordBreaker: json['isRecordBreaker'] as bool? ?? false,
    isDNF: json['isDNF'] as bool? ?? false,
    isDQ: json['isDQ'] as bool? ?? false,
    notes: json['notes'] as String?,
  );

  /// 格式化成績顯示
  String get formattedResult {
    if (isDQ) return 'DQ';
    if (isDNF) return 'DNF';
    
    if (timeResult != null) return '${timeResult}s';
    if (distanceResult != null) return '${distanceResult}m';
    if (heightResult != null) return '${heightResult}m';
    
    return '-';
  }
} 