/// 應用程式常數配置
/// 包含計分規則、設計常數等

import '../models/student.dart' show Gender, Division;
import '../models/event.dart' show EventType, EventCategory, ResultType, Event;

/// 應用程式常數
class AppConstants {
  // 應用程式基本資訊
  static const String appName = '香港中學運動會管理系統';
  static const String appVersion = '1.0.0';
  static const String appDescription = '專為香港中學設計的運動會管理系統，支援甲乙丙組分組、計分統計、裁判系統等完整功能';
  
  // 顏色主題
  static const Map<String, int> colorValues = {
    'primary': 0xFF1976D2,
    'secondary': 0xFF388E3C,
    'accent': 0xFFFF5722,
    'error': 0xFFD32F2F,
    'warning': 0xFFF57C00,
    'success': 0xFF388E3C,
    'info': 0xFF1976D2,
  };

  // 設計常數
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;
  
  // 圖標尺寸
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 48.0;
  
  // 字體大小
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeTitle = 18.0;
  static const double fontSizeHeading = 20.0;

  // ===== 新計分規則 =====
  
  /// 個人項目計分表 (第1名到第8名)
  static const Map<int, int> individualPointsTable = {
    1: 9, // 第1名
    2: 7, // 第2名
    3: 6, // 第3名
    4: 5, // 第4名
    5: 4, // 第5名
    6: 3, // 第6名
    7: 2, // 第7名
    8: 1, // 第8名
  };

  /// 接力項目計分表 (第1名到第8名，分數為個人項目的兩倍)
  static const Map<int, int> relayPointsTable = {
    1: 18, // 第1名
    2: 14, // 第2名
    3: 12, // 第3名
    4: 10, // 第4名
    5: 8,  // 第5名
    6: 6,  // 第6名
    7: 4,  // 第7名
    8: 2,  // 第8名
  };

  /// 特殊計分規則
  static const int staffBonus = 2;           // 工作人員獎勵分
  static const int participationPoints = 1;  // 參與分（有填寫成績）
  static const int recordBonusPoints = 3;    // 破紀錄獎勵分
  static const int absentPenalty = -1;       // 缺席扣分 (ABS)
  static const int dnfPoints = 0;            // DNF得分
  static const int dqPoints = 0;             // DQ得分

  /// 決賽人數限制
  static const int finalsQualifiers = 8;    // 決賽人數（前8名）
  static const int podiumPositions = 3;     // 頒獎台人數（前3名）

  /// 自動決賽條件
  static const int directFinalsThreshold = 8; // 當參賽人數≤8時直接決賽

  /// 計算參與分
  /// 根據成績狀態給予參與分
  static int calculateParticipationPoints(String? result, bool isDNF, bool isDQ, bool isABS) {
    if (isABS) return absentPenalty;  // 缺席扣分
    if (isDNF || isDQ) return dnfPoints; // DNF/DQ無分
    if (result != null && result.isNotEmpty) return participationPoints; // 有成績給參與分
    return 0; // 無成績無分
  }

  /// 計算工作人員獎勵分
  static int calculateStaffBonus(bool isStaff) {
    return isStaff ? staffBonus : 0;
  }

  /// 計算位置分數
  static int calculatePositionPoints(int position, EventType eventType) {
    Map<int, int> pointsTable;
    
    switch (eventType) {
      case EventType.relay:
      case EventType.team:
        pointsTable = relayPointsTable;
        break;
      default:
        pointsTable = individualPointsTable;
        break;
    }
    
    return pointsTable[position] ?? 0;
  }

  /// 計算破紀錄獎勵分
  static int calculateRecordBonus(bool isRecordBreaker) {
    return isRecordBreaker ? recordBonusPoints : 0;
  }

  /// 計算總分
  static int calculateTotalPoints({
    required int position,
    required EventType eventType,
    required bool isStaff,
    required bool hasResult,
    required bool isDNF,
    required bool isDQ,
    required bool isABS,
    required bool isRecordBreaker,
    String? result,
  }) {
    int total = 0;
    
    // 位置分數
    if (position > 0 && position <= 8) {
      total += calculatePositionPoints(position, eventType);
    }
    
    // 工作人員獎勵分
    total += calculateStaffBonus(isStaff);
    
    // 參與分
    total += calculateParticipationPoints(result, isDNF, isDQ, isABS);
    
    // 破紀錄獎勵分
    total += calculateRecordBonus(isRecordBreaker);
    
    return total;
  }

  /// 計算同分名次的平均分數
  static double calculateTiedPoints(List<int> positions, EventType eventType) {
    if (positions.isEmpty) return 0.0;
    
    int totalPoints = 0;
    for (int position in positions) {
      totalPoints += calculatePositionPoints(position, eventType);
    }
    
    return totalPoints / positions.length;
  }
}

/// 比賽項目模板類別
/// 用於創建預設比賽項目
class EventTemplate {
  final String name;
  final String shortName;
  final EventType type;
  final EventCategory category;
  final Gender gender;
  final List<Division> divisions;
  final String unit;
  final ResultType resultType;
  final bool isTimeBased;
  final bool isDistanceBased;
  final bool isCountBased;
  final int minParticipants;
  final int maxParticipants;
  final int attemptsAllowed;
  final bool countsForPoints;

  const EventTemplate({
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
    this.minParticipants = 1,
    this.maxParticipants = -1,
    this.attemptsAllowed = 1,
    this.countsForPoints = true,
  });

  /// 轉換為 Event 物件
  Event toEvent(String id) {
    return Event(
      id: id,
      name: name,
      shortName: shortName,
      type: type,
      category: category,
      gender: gender,
      divisions: divisions,
      unit: unit,
      resultType: resultType,
      isTimeBased: isTimeBased,
      isDistanceBased: isDistanceBased,
      isCountBased: isCountBased,
      minParticipants: minParticipants,
      maxParticipants: maxParticipants,
      attemptsAllowed: attemptsAllowed,
      countsForPoints: countsForPoints,
    );
  }
} 