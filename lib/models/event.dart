import 'student.dart';

/// 完整的比賽項目模型
/// 支援田賽、徑賽、接力和特殊表演項目
class Event {
  final String id;
  final String name; // 項目名稱
  final String shortName; // 簡稱
  final EventType type; // 項目類型
  final EventCategory category; // 項目分類（田賽/徑賽）
  final Gender gender; // 性別組別
  final List<Division> divisions; // 適用組別
  
  // 比賽設定
  final String unit; // 計量單位（秒/米/次）
  final ResultType resultType; // 成績類型（時間/距離/次數）
  final bool isTimeBased; // 是否基於時間
  final bool isDistanceBased; // 是否基於距離
  final bool isCountBased; // 是否基於次數
  
  // 參賽設定
  final int maxParticipants; // 最大參賽人數（-1表示無限制）
  final int minParticipants; // 最小參賽人數
  final bool isActive; // 是否啟用
  final bool countsForPoints; // 是否計分
  
  // 賽制設定
  final CompetitionFormat format; // 比賽格式
  final int preliminaryRounds; // 預賽輪數
  final int finalRounds; // 決賽輪數
  final int attemptsAllowed; // 允許嘗試次數（田賽用）
  
  // 時間安排
  final DateTime? scheduledDate; // 預定日期
  final DateTime? scheduledTime; // 預定時間
  final String? venue; // 比賽場地
  final Duration estimatedDuration; // 預估持續時間
  
  // 記錄相關
  final EventRecord? schoolRecord; // 校內記錄
  final EventRecord? meetRecord; // 大會記錄
  final String? description; // 項目描述
  final List<String> rules; // 比賽規則

  const Event({
    required this.id,
    required this.name,
    required this.shortName,
    required this.type,
    required this.category,
    required this.gender,
    required this.divisions,
    required this.unit,
    required this.resultType,
    this.isTimeBased = false,
    this.isDistanceBased = false,
    this.isCountBased = false,
    this.maxParticipants = -1,
    this.minParticipants = 1,
    this.isActive = true,
    this.countsForPoints = true,
    this.format = CompetitionFormat.direct,
    this.preliminaryRounds = 0,
    this.finalRounds = 1,
    this.attemptsAllowed = 3,
    this.scheduledDate,
    this.scheduledTime,
    this.venue,
    this.estimatedDuration = const Duration(minutes: 30),
    this.schoolRecord,
    this.meetRecord,
    this.description,
    this.rules = const [],
  });

  /// 從 JSON 創建項目物件
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['shortName'] as String,
      type: EventType.values.byName(json['type'] as String),
      category: EventCategory.values.byName(json['category'] as String),
      gender: Gender.values.byName(json['gender'] as String),
      divisions: (json['divisions'] as List)
          .map((e) => Division.values.byName(e as String))
          .toList(),
      unit: json['unit'] as String,
      resultType: ResultType.values.byName(json['resultType'] as String),
      isTimeBased: json['isTimeBased'] as bool? ?? false,
      isDistanceBased: json['isDistanceBased'] as bool? ?? false,
      isCountBased: json['isCountBased'] as bool? ?? false,
      maxParticipants: json['maxParticipants'] as int? ?? -1,
      minParticipants: json['minParticipants'] as int? ?? 1,
      isActive: json['isActive'] as bool? ?? true,
      countsForPoints: json['countsForPoints'] as bool? ?? true,
      format: CompetitionFormat.values.byName(json['format'] as String? ?? 'direct'),
      preliminaryRounds: json['preliminaryRounds'] as int? ?? 0,
      finalRounds: json['finalRounds'] as int? ?? 1,
      attemptsAllowed: json['attemptsAllowed'] as int? ?? 3,
      scheduledDate: json['scheduledDate'] != null 
          ? DateTime.parse(json['scheduledDate'] as String) 
          : null,
      scheduledTime: json['scheduledTime'] != null 
          ? DateTime.parse(json['scheduledTime'] as String) 
          : null,
      venue: json['venue'] as String?,
      estimatedDuration: Duration(
        minutes: json['estimatedDurationMinutes'] as int? ?? 30,
      ),
      schoolRecord: json['schoolRecord'] != null
          ? EventRecord.fromJson(json['schoolRecord'] as Map<String, dynamic>)
          : null,
      meetRecord: json['meetRecord'] != null
          ? EventRecord.fromJson(json['meetRecord'] as Map<String, dynamic>)
          : null,
      description: json['description'] as String?,
      rules: List<String>.from(json['rules'] as List? ?? []),
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'type': type.name,
      'category': category.name,
      'gender': gender.name,
      'divisions': divisions.map((e) => e.name).toList(),
      'unit': unit,
      'resultType': resultType.name,
      'isTimeBased': isTimeBased,
      'isDistanceBased': isDistanceBased,
      'isCountBased': isCountBased,
      'maxParticipants': maxParticipants,
      'minParticipants': minParticipants,
      'isActive': isActive,
      'countsForPoints': countsForPoints,
      'format': format.name,
      'preliminaryRounds': preliminaryRounds,
      'finalRounds': finalRounds,
      'attemptsAllowed': attemptsAllowed,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'scheduledTime': scheduledTime?.toIso8601String(),
      'venue': venue,
      'estimatedDurationMinutes': estimatedDuration.inMinutes,
      'schoolRecord': schoolRecord?.toJson(),
      'meetRecord': meetRecord?.toJson(),
      'description': description,
      'rules': rules,
    };
  }

  /// 複製項目物件並修改指定欄位
  Event copyWith({
    String? id,
    String? name,
    String? shortName,
    EventType? type,
    EventCategory? category,
    Gender? gender,
    List<Division>? divisions,
    String? unit,
    ResultType? resultType,
    bool? isTimeBased,
    bool? isDistanceBased,
    bool? isCountBased,
    int? maxParticipants,
    int? minParticipants,
    bool? isActive,
    bool? countsForPoints,
    CompetitionFormat? format,
    int? preliminaryRounds,
    int? finalRounds,
    int? attemptsAllowed,
    DateTime? scheduledDate,
    DateTime? scheduledTime,
    String? venue,
    Duration? estimatedDuration,
    EventRecord? schoolRecord,
    EventRecord? meetRecord,
    String? description,
    List<String>? rules,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      type: type ?? this.type,
      category: category ?? this.category,
      gender: gender ?? this.gender,
      divisions: divisions ?? this.divisions,
      unit: unit ?? this.unit,
      resultType: resultType ?? this.resultType,
      isTimeBased: isTimeBased ?? this.isTimeBased,
      isDistanceBased: isDistanceBased ?? this.isDistanceBased,
      isCountBased: isCountBased ?? this.isCountBased,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      minParticipants: minParticipants ?? this.minParticipants,
      isActive: isActive ?? this.isActive,
      countsForPoints: countsForPoints ?? this.countsForPoints,
      format: format ?? this.format,
      preliminaryRounds: preliminaryRounds ?? this.preliminaryRounds,
      finalRounds: finalRounds ?? this.finalRounds,
      attemptsAllowed: attemptsAllowed ?? this.attemptsAllowed,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      venue: venue ?? this.venue,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      schoolRecord: schoolRecord ?? this.schoolRecord,
      meetRecord: meetRecord ?? this.meetRecord,
      description: description ?? this.description,
      rules: rules ?? this.rules,
    );
  }

  /// 獲取完整項目名稱（包含性別和組別）
  String get fullName {
    final genderText = gender == Gender.mixed ? '' : gender.displayName;
    final divisionText = divisions.map((d) => d.displayName).join('/');
    return '$genderText$divisionText$name';
  }

  /// 檢查學生是否符合參賽條件
  bool isEligibleForStudent(Student student) {
    // 檢查性別
    if (gender != Gender.mixed && gender != student.gender) {
      return false;
    }
    
    // 檢查組別
    if (!divisions.contains(student.division)) {
      return false;
    }
    
    // 檢查是否為活躍項目和學生
    if (!isActive || !student.isActive) {
      return false;
    }
    
    return true;
  }

  /// 格式化結果顯示
  String formatResult(double value) {
    switch (resultType) {
      case ResultType.time:
        return formatTime(value);
      case ResultType.distance:
        return '${value.toStringAsFixed(2)}$unit';
      case ResultType.count:
        return '${value.toInt()}$unit';
      case ResultType.points:
        return '${value.toStringAsFixed(1)}分';
    }
  }

  /// 格式化時間顯示
  String formatTime(double seconds) {
    if (seconds < 60) {
      return '${seconds.toStringAsFixed(2)}秒';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '${minutes}分${remainingSeconds.toStringAsFixed(2)}秒';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      final remainingSeconds = seconds % 60;
      return '${hours}小時${minutes}分${remainingSeconds.toStringAsFixed(2)}秒';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 項目類型枚舉
enum EventType {
  individual('個人項目'),
  relay('接力項目'),
  team('團體項目'),
  special('特殊表演');

  const EventType(this.displayName);
  final String displayName;
}

/// 項目分類枚舉
enum EventCategory {
  track('徑賽'),
  field('田賽'),
  special('特殊項目');

  const EventCategory(this.displayName);
  final String displayName;
}

/// 成績類型枚舉
enum ResultType {
  time('時間'),
  distance('距離'),
  count('次數'),
  points('積分');

  const ResultType(this.displayName);
  final String displayName;
}

/// 比賽格式枚舉
enum CompetitionFormat {
  direct('直接決賽'),
  preliminaryAndFinal('預賽+決賽'),
  qualifying('資格賽');

  const CompetitionFormat(this.displayName);
  final String displayName;
}

/// 項目記錄
class EventRecord {
  final String id;
  final String eventId;
  final String holderName; // 記錄保持者
  final String? holderClass; // 記錄保持者班級
  final double result; // 記錄成績
  final DateTime achievedDate; // 創造日期
  final String? venue; // 創造地點
  final String? conditions; // 比賽條件（風速等）

  const EventRecord({
    required this.id,
    required this.eventId,
    required this.holderName,
    this.holderClass,
    required this.result,
    required this.achievedDate,
    this.venue,
    this.conditions,
  });

  factory EventRecord.fromJson(Map<String, dynamic> json) {
    return EventRecord(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      holderName: json['holderName'] as String,
      holderClass: json['holderClass'] as String?,
      result: (json['result'] as num).toDouble(),
      achievedDate: DateTime.parse(json['achievedDate'] as String),
      venue: json['venue'] as String?,
      conditions: json['conditions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'holderName': holderName,
      'holderClass': holderClass,
      'result': result,
      'achievedDate': achievedDate.toIso8601String(),
      'venue': venue,
      'conditions': conditions,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
} 