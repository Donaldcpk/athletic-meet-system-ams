import 'student.dart';

/// 班級資料模型
/// 包含班級基本資訊、學生名單和積分統計
class ClassInfo {
  final String id;
  final String name; // 班級名稱，如 "1A", "2B"
  final int grade; // 年級 (1-6)
  final Division division; // 主要組別
  final String? teacher; // 班主任
  final String? teacherId;
  
  // 學生相關
  final List<String> studentIds; // 學生 ID 列表
  final int studentCount; // 學生總數
  
  // 積分統計
  final int totalPoints; // 班級總積分
  final int malePoints; // 男子總積分
  final int femalePoints; // 女子總積分
  final Map<Division, int> pointsByDivision; // 各組別積分
  
  // 比賽統計
  final int goldMedals; // 冠軍數量
  final int silverMedals; // 亞軍數量
  final int bronzeMedals; // 季軍數量
  final int totalParticipants; // 參賽人數
  
  // 特殊獎項
  final List<SpecialAward> specialAwards; // 特殊獎項
  final bool isActive; // 是否活躍班級

  const ClassInfo({
    required this.id,
    required this.name,
    required this.grade,
    required this.division,
    this.teacher,
    this.teacherId,
    this.studentIds = const [],
    this.studentCount = 0,
    this.totalPoints = 0,
    this.malePoints = 0,
    this.femalePoints = 0,
    this.pointsByDivision = const {},
    this.goldMedals = 0,
    this.silverMedals = 0,
    this.bronzeMedals = 0,
    this.totalParticipants = 0,
    this.specialAwards = const [],
    this.isActive = true,
  });

  /// 從 JSON 創建班級物件
  factory ClassInfo.fromJson(Map<String, dynamic> json) {
    return ClassInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      grade: json['grade'] as int,
      division: Division.values.byName(json['division'] as String),
      teacher: json['teacher'] as String?,
      teacherId: json['teacherId'] as String?,
      studentIds: List<String>.from(json['studentIds'] as List? ?? []),
      studentCount: json['studentCount'] as int? ?? 0,
      totalPoints: json['totalPoints'] as int? ?? 0,
      malePoints: json['malePoints'] as int? ?? 0,
      femalePoints: json['femalePoints'] as int? ?? 0,
      pointsByDivision: Map<Division, int>.from(
        (json['pointsByDivision'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            Division.values.byName(key),
            value as int,
          ),
        ) ?? {},
      ),
      goldMedals: json['goldMedals'] as int? ?? 0,
      silverMedals: json['silverMedals'] as int? ?? 0,
      bronzeMedals: json['bronzeMedals'] as int? ?? 0,
      totalParticipants: json['totalParticipants'] as int? ?? 0,
      specialAwards: (json['specialAwards'] as List?)
          ?.map((e) => SpecialAward.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'grade': grade,
      'division': division.name,
      'teacher': teacher,
      'teacherId': teacherId,
      'studentIds': studentIds,
      'studentCount': studentCount,
      'totalPoints': totalPoints,
      'malePoints': malePoints,
      'femalePoints': femalePoints,
      'pointsByDivision': pointsByDivision.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'goldMedals': goldMedals,
      'silverMedals': silverMedals,
      'bronzeMedals': bronzeMedals,
      'totalParticipants': totalParticipants,
      'specialAwards': specialAwards.map((e) => e.toJson()).toList(),
      'isActive': isActive,
    };
  }

  /// 複製班級物件並修改指定欄位
  ClassInfo copyWith({
    String? id,
    String? name,
    int? grade,
    Division? division,
    String? teacher,
    String? teacherId,
    List<String>? studentIds,
    int? studentCount,
    int? totalPoints,
    int? malePoints,
    int? femalePoints,
    Map<Division, int>? pointsByDivision,
    int? goldMedals,
    int? silverMedals,
    int? bronzeMedals,
    int? totalParticipants,
    List<SpecialAward>? specialAwards,
    bool? isActive,
  }) {
    return ClassInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      division: division ?? this.division,
      teacher: teacher ?? this.teacher,
      teacherId: teacherId ?? this.teacherId,
      studentIds: studentIds ?? this.studentIds,
      studentCount: studentCount ?? this.studentCount,
      totalPoints: totalPoints ?? this.totalPoints,
      malePoints: malePoints ?? this.malePoints,
      femalePoints: femalePoints ?? this.femalePoints,
      pointsByDivision: pointsByDivision ?? this.pointsByDivision,
      goldMedals: goldMedals ?? this.goldMedals,
      silverMedals: silverMedals ?? this.silverMedals,
      bronzeMedals: bronzeMedals ?? this.bronzeMedals,
      totalParticipants: totalParticipants ?? this.totalParticipants,
      specialAwards: specialAwards ?? this.specialAwards,
      isActive: isActive ?? this.isActive,
    );
  }

  /// 獲取完整班級名稱
  String get fullName => '$grade$name';

  /// 獲取班級排名相關資料
  ClassRanking getRanking(List<ClassInfo> allClasses) {
    // 按總積分排序所有班級
    final sortedClasses = List<ClassInfo>.from(allClasses)
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    final overallRank = sortedClasses.indexWhere((c) => c.id == id) + 1;

    // 按年級排序
    final sameGradeClasses = allClasses
        .where((c) => c.grade == grade)
        .toList()
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    final gradeRank = sameGradeClasses.indexWhere((c) => c.id == id) + 1;

    return ClassRanking(
      classId: id,
      overallRank: overallRank,
      gradeRank: gradeRank,
      totalClasses: allClasses.length,
      gradeClasses: sameGradeClasses.length,
    );
  }

  /// 計算參與率
  double get participationRate {
    if (studentCount == 0) return 0.0;
    return totalParticipants / studentCount;
  }

  /// 獲取獎牌總數
  int get totalMedals => goldMedals + silverMedals + bronzeMedals;

  /// 獲取平均積分
  double get averagePoints {
    if (studentCount == 0) return 0.0;
    return totalPoints / studentCount;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassInfo &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 特殊獎項
class SpecialAward {
  final String id;
  final String name; // 獎項名稱
  final String description; // 獎項描述
  final DateTime awardedDate; // 獲獎日期
  final String? criteria; // 評選標準

  const SpecialAward({
    required this.id,
    required this.name,
    required this.description,
    required this.awardedDate,
    this.criteria,
  });

  factory SpecialAward.fromJson(Map<String, dynamic> json) {
    return SpecialAward(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      awardedDate: DateTime.parse(json['awardedDate'] as String),
      criteria: json['criteria'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'awardedDate': awardedDate.toIso8601String(),
      'criteria': criteria,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpecialAward &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 班級排名資訊
class ClassRanking {
  final String classId;
  final int overallRank; // 全校排名
  final int gradeRank; // 年級排名
  final int totalClasses; // 總班級數
  final int gradeClasses; // 同年級班級數

  const ClassRanking({
    required this.classId,
    required this.overallRank,
    required this.gradeRank,
    required this.totalClasses,
    required this.gradeClasses,
  });

  /// 全校排名百分比
  double get overallPercentile => 
      (totalClasses - overallRank + 1) / totalClasses;

  /// 年級排名百分比
  double get gradePercentile => 
      (gradeClasses - gradeRank + 1) / gradeClasses;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassRanking &&
          runtimeType == other.runtimeType &&
          classId == other.classId;

  @override
  int get hashCode => classId.hashCode;
} 