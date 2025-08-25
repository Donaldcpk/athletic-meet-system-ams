import 'event.dart';

/// 學生資料模型
/// 包含學生的基本資訊、組別分類和比賽相關資料
class Student {
  final String id;
  final String name;
  final String classId;
  final String studentNumber;
  final Gender gender;
  final Division division; // 甲乙丙組
  final int grade; // 年級
  final DateTime dateOfBirth;
  final bool isActive; // 是否在學
  final bool isStaff; // 是否工作人員
  
  // 比賽相關資料
  final List<String> registeredEvents; // 已報名項目
  final int totalPoints; // 總積分
  final List<Achievement> achievements; // 成就記錄

  /// 學生編號 (班別+學號，如 1A01, 4D16)
  String get studentCode => '$classId${studentNumber.padLeft(2, '0')}';

  /// 構造函數
  const Student({
    required this.id,
    required this.name,
    required this.classId,
    required this.studentNumber,
    required this.gender,
    required this.division,
    required this.grade,
    required this.dateOfBirth,
    this.isActive = true,
    required this.isStaff,
    this.registeredEvents = const [],
    this.totalPoints = 0,
    this.achievements = const [],
  });

  /// 從 JSON 創建學生物件
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      classId: json['classId'] as String,
      gender: Gender.values.byName(json['gender'] as String),
      division: Division.values.byName(json['division'] as String),
      studentNumber: json['studentNumber'] as String,
      grade: json['grade'] as int,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      isActive: json['isActive'] as bool? ?? true,
      isStaff: json['isStaff'] as bool? ?? false,
      registeredEvents: List<String>.from(json['registeredEvents'] as List? ?? []),
      totalPoints: json['totalPoints'] as int? ?? 0,
      achievements: (json['achievements'] as List?)
          ?.map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'classId': classId,
      'gender': gender.name,
      'division': division.name,
      'studentNumber': studentNumber,
      'grade': grade,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'isActive': isActive,
      'isStaff': isStaff,
      'registeredEvents': registeredEvents,
      'totalPoints': totalPoints,
      'achievements': achievements.map((e) => e.toJson()).toList(),
    };
  }

  /// 複製學生物件並修改指定欄位
  Student copyWith({
    String? id,
    String? name,
    String? classId,
    Gender? gender,
    Division? division,
    String? studentNumber,
    int? grade,
    DateTime? dateOfBirth,
    bool? isActive,
    bool? isStaff,
    List<String>? registeredEvents,
    int? totalPoints,
    List<Achievement>? achievements,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      classId: classId ?? this.classId,
      gender: gender ?? this.gender,
      division: division ?? this.division,
      studentNumber: studentNumber ?? this.studentNumber,
      grade: grade ?? this.grade,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      isActive: isActive ?? this.isActive,
      isStaff: isStaff ?? this.isStaff,
      registeredEvents: registeredEvents ?? this.registeredEvents,
      totalPoints: totalPoints ?? this.totalPoints,
      achievements: achievements ?? this.achievements,
    );
  }

  /// 獲取學生完整顯示名稱 (包含班級和姓名)
  String get displayName => '$classId $name';

  /// 檢查是否可以報名指定項目
  bool canRegisterForEvent(String eventId, List<Event> allEvents) {
    // 檢查是否已報名此項目
    if (registeredEvents.contains(eventId)) {
      return false;
    }

    final event = allEvents.firstWhere((e) => e.id == eventId);
    
    // 檢查性別是否符合
    if (event.gender != Gender.mixed && event.gender != gender) {
      return false;
    }

    // 檢查組別是否符合
    if (!event.divisions.contains(division)) {
      return false;
    }

    // 檢查個人項目報名數量限制（最多3項個人項目）
    if (event.type == EventType.individual) {
      final individualEventsCount = registeredEvents
          .where((eventId) => allEvents
              .firstWhere((e) => e.id == eventId)
              .type == EventType.individual)
          .length;
      
      if (individualEventsCount >= 3) {
        return false;
      }
    }

    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Student &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 性別枚舉
enum Gender {
  male('男'),
  female('女'),
  mixed('混合');

  const Gender(this.displayName);
  final String displayName;
}

/// 組別枚舉（甲乙丙組）
enum Division {
  senior('甲組', [16, 17, 18]), // 中四至中六
  junior('乙組', [14, 15]),      // 中二至中三
  primary('丙組', [13]);         // 中一

  const Division(this.displayName, this.ages);
  final String displayName;
  final List<int> ages;

  /// 根據出生年份獲取組別（主要分組方法）
  static Division fromBirthYear(int birthYear) {
    if (birthYear <= 2009) return Division.senior;    // 2009年或之前 → 甲組
    if (birthYear <= 2011) return Division.junior;    // 2010-2011年 → 乙組
    return Division.primary;                           // 2012年或之後（包括2013、2014等）→ 丙組
  }

  /// 根據年級獲取組別（向後兼容性）
  static Division fromGrade(int grade) {
    switch (grade) {
      case 1:
        return Division.primary;
      case 2:
      case 3:
        return Division.junior;
      case 4:
      case 5:
      case 6:
        return Division.senior;
      default:
        throw ArgumentError('Invalid grade: $grade');
    }
  }

  /// 從班級名稱提取年級（如 "1A" → 1, "6B" → 6）
  static int gradeFromClass(String classId) {
    final match = RegExp(r'^(\d+)').firstMatch(classId);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '1') ?? 1;
    }
    return 1; // 預設為中1
  }
}

/// 成就記錄
class Achievement {
  final String id;
  final String eventId;
  final String eventName;
  final int position; // 名次 (1=冠軍, 2=亞軍, 3=季軍...)
  final int points; // 獲得積分
  final DateTime achievedDate;
  final String? result; // 成績（時間/距離等）

  const Achievement({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.position,
    required this.points,
    required this.achievedDate,
    this.result,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      eventName: json['eventName'] as String,
      position: json['position'] as int,
      points: json['points'] as int,
      achievedDate: DateTime.parse(json['achievedDate'] as String),
      result: json['result'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'eventName': eventName,
      'position': position,
      'points': points,
      'achievedDate': achievedDate.toIso8601String(),
      'result': result,
    };
  }

  /// 獲取名次顯示文字
  String get positionText {
    switch (position) {
      case 1:
        return '冠軍';
      case 2:
        return '亞軍';
      case 3:
        return '季軍';
      case 4:
        return '第四名';
      case 5:
        return '第五名';
      default:
        return '第${position}名';
    }
  }
}

// 引入其他模型類別 - Event 在 event.dart 中定義 