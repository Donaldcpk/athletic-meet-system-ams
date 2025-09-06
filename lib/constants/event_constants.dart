/// 運動會項目常數定義
/// 包含所有項目代碼、分類、限制規則等

import '../models/student.dart';

/// 項目類型分類
enum EventCategory {
  track('徑賽'),      // 跑步項目
  field('田賽'),      // 跳躍、投擲項目
  relay('接力賽'),    // 接力項目
  special('特殊項目'); // 特殊接力等

  const EventCategory(this.displayName);
  final String displayName;
}

/// 項目資料結構
class EventInfo {
  final String code;
  final String name;
  final EventCategory category;
  final List<Division> divisions;
  final List<Gender> genders;
  final bool isScoring;     // 是否計分
  final bool isClassRelay;  // 是否班際接力
  final int? maxParticipants; // 每班最大參與人數
  final String? specialRules; // 特殊規則

  const EventInfo({
    required this.code,
    required this.name,
    required this.category,
    required this.divisions,
    required this.genders,
    this.isScoring = true,
    this.isClassRelay = false,
    this.maxParticipants,
    this.specialRules,
  });
}

/// 所有運動會項目定義
class EventConstants {
  
  /// 甲組女子項目 (高年級：中5-6) - G=Girl
  static const List<EventInfo> seniorFemaleEvents_G = [
    // 田賽
    EventInfo(code: 'GAJT', name: '標槍', category: EventCategory.field, divisions: [Division.senior], genders: [Gender.female]),
    EventInfo(code: 'GALJ', name: '跳遠', category: EventCategory.field, divisions: [Division.senior], genders: [Gender.female]),
    EventInfo(code: 'GASP', name: '鉛球', category: EventCategory.field, divisions: [Division.senior], genders: [Gender.female]),
  ];

  /// 乙組女子項目 (中年級：中3-4) - G=Girl
  static const List<EventInfo> juniorFemaleEvents_G = [
    // 徑賽
    EventInfo(code: 'GB100', name: '100m', category: EventCategory.track, divisions: [Division.junior], genders: [Gender.female]),
    EventInfo(code: 'GB400', name: '400m', category: EventCategory.track, divisions: [Division.junior], genders: [Gender.female]),
    // 田賽
    EventInfo(code: 'GBHJ', name: '跳高', category: EventCategory.field, divisions: [Division.junior], genders: [Gender.female]),
    EventInfo(code: 'GBJT', name: '標槍', category: EventCategory.field, divisions: [Division.junior], genders: [Gender.female]),
    EventInfo(code: 'GBLJ', name: '跳遠', category: EventCategory.field, divisions: [Division.junior], genders: [Gender.female]),
    EventInfo(code: 'GBSP', name: '鉛球', category: EventCategory.field, divisions: [Division.junior], genders: [Gender.female]),
  ];

  /// 丙組女子項目 (低年級：中1-2) - G=Girl
  static const List<EventInfo> primaryFemaleEvents_G = [
    // 徑賽
    EventInfo(code: 'GC100', name: '100m', category: EventCategory.track, divisions: [Division.primary], genders: [Gender.female]),
    EventInfo(code: 'GC200', name: '200m', category: EventCategory.track, divisions: [Division.primary], genders: [Gender.female]),
    EventInfo(code: 'GC400', name: '400m', category: EventCategory.track, divisions: [Division.primary], genders: [Gender.female]),
    EventInfo(code: 'GCHD', name: '100/110mH', category: EventCategory.track, divisions: [Division.primary], genders: [Gender.female]),
    // 田賽
    EventInfo(code: 'GCDT', name: '鐵餅', category: EventCategory.field, divisions: [Division.primary], genders: [Gender.female]),
    EventInfo(code: 'GCHJ', name: '跳高', category: EventCategory.field, divisions: [Division.primary], genders: [Gender.female]),
    EventInfo(code: 'GCLJ', name: '跳遠', category: EventCategory.field, divisions: [Division.primary], genders: [Gender.female]),
    EventInfo(code: 'GCSP', name: '鉛球', category: EventCategory.field, divisions: [Division.primary], genders: [Gender.female]),
  ];

  /// 甲組男子項目 - B=Boy
  static const List<EventInfo> seniorMaleEvents_B = [
    // 徑賽
    EventInfo(code: 'BA100', name: '100m', category: EventCategory.track, divisions: [Division.senior], genders: [Gender.male]),
    EventInfo(code: 'BA200', name: '200m', category: EventCategory.track, divisions: [Division.senior], genders: [Gender.male]),
    EventInfo(code: 'BA400', name: '400m', category: EventCategory.track, divisions: [Division.senior], genders: [Gender.male]),
    EventInfo(code: 'BA800', name: '800m', category: EventCategory.track, divisions: [Division.senior], genders: [Gender.male]),
    EventInfo(code: 'BA1500', name: '1500m', category: EventCategory.track, divisions: [Division.senior], genders: [Gender.male]),
    EventInfo(code: 'BAHD', name: '100/110mH', category: EventCategory.track, divisions: [Division.senior], genders: [Gender.male]),
    // 田賽
    EventInfo(code: 'BADT', name: '鐵餅', category: EventCategory.field, divisions: [Division.senior], genders: [Gender.male]),
    EventInfo(code: 'BAHJ', name: '跳高', category: EventCategory.field, divisions: [Division.senior], genders: [Gender.male]),
    EventInfo(code: 'BAJT', name: '標槍', category: EventCategory.field, divisions: [Division.senior], genders: [Gender.male]),
    EventInfo(code: 'BALJ', name: '跳遠', category: EventCategory.field, divisions: [Division.senior], genders: [Gender.male]),
    EventInfo(code: 'BASP', name: '鉛球', category: EventCategory.field, divisions: [Division.senior], genders: [Gender.male]),
    EventInfo(code: 'BATJ', name: '三級跳', category: EventCategory.field, divisions: [Division.senior], genders: [Gender.male]),
  ];

  /// 乙組男子項目 - B=Boy
  static const List<EventInfo> juniorMaleEvents_B = [
    // 徑賽
    EventInfo(code: 'BB100', name: '100m', category: EventCategory.track, divisions: [Division.junior], genders: [Gender.male]),
    EventInfo(code: 'BB200', name: '200m', category: EventCategory.track, divisions: [Division.junior], genders: [Gender.male]),
    EventInfo(code: 'BB400', name: '400m', category: EventCategory.track, divisions: [Division.junior], genders: [Gender.male]),
    EventInfo(code: 'BB800', name: '800m', category: EventCategory.track, divisions: [Division.junior], genders: [Gender.male]),
    EventInfo(code: 'BB1500', name: '1500m', category: EventCategory.track, divisions: [Division.junior], genders: [Gender.male]),
    // 田賽
    EventInfo(code: 'BBDT', name: '鐵餅', category: EventCategory.field, divisions: [Division.junior], genders: [Gender.male]),
    EventInfo(code: 'BBHJ', name: '跳高', category: EventCategory.field, divisions: [Division.junior], genders: [Gender.male]),
    EventInfo(code: 'BBJT', name: '標槍', category: EventCategory.field, divisions: [Division.junior], genders: [Gender.male]),
    EventInfo(code: 'BBLJ', name: '跳遠', category: EventCategory.field, divisions: [Division.junior], genders: [Gender.male]),
    EventInfo(code: 'BBSP', name: '鉛球', category: EventCategory.field, divisions: [Division.junior], genders: [Gender.male]),
    EventInfo(code: 'BBTJ', name: '三級跳', category: EventCategory.field, divisions: [Division.junior], genders: [Gender.male]),
  ];

  /// 丙組男子項目 - B=Boy
  static const List<EventInfo> primaryMaleEvents_B = [
    // 徑賽
    EventInfo(code: 'BC100', name: '100m', category: EventCategory.track, divisions: [Division.primary], genders: [Gender.male]),
    EventInfo(code: 'BC200', name: '200m', category: EventCategory.track, divisions: [Division.primary], genders: [Gender.male]),
    EventInfo(code: 'BC400', name: '400m', category: EventCategory.track, divisions: [Division.primary], genders: [Gender.male]),
    EventInfo(code: 'BC800', name: '800m', category: EventCategory.track, divisions: [Division.primary], genders: [Gender.male]),
    // 田賽
    EventInfo(code: 'BCDT', name: '鐵餅', category: EventCategory.field, divisions: [Division.primary], genders: [Gender.male]),
    EventInfo(code: 'BCHJ', name: '跳高', category: EventCategory.field, divisions: [Division.primary], genders: [Gender.male]),
    EventInfo(code: 'BCLJ', name: '跳遠', category: EventCategory.field, divisions: [Division.primary], genders: [Gender.male]),
    EventInfo(code: 'BCSP', name: '鉛球', category: EventCategory.field, divisions: [Division.primary], genders: [Gender.male]),
  ];

  /// 班際接力項目 (4x100c, 4x400c)
  static const List<EventInfo> classRelayEvents = [
    // 甲組班際接力 (中5-6)
    EventInfo(
      code: '4x100c_A', 
      name: '4x100c (甲組)', 
      category: EventCategory.relay, 
      divisions: [Division.senior], 
      genders: [Gender.mixed],
      isClassRelay: true,
      maxParticipants: 4,
      specialRules: '甲組班際接力，每班最多一隊，每年級分別排名',
    ),
    EventInfo(
      code: '4x400c_A', 
      name: '4x400c (甲組)', 
      category: EventCategory.relay, 
      divisions: [Division.senior], 
      genders: [Gender.mixed],
      isClassRelay: true,
      maxParticipants: 4,
      specialRules: '甲組班際接力，每班最多一隊，每年級分別排名',
    ),
    // 乙組班際接力 (中3-4)
    EventInfo(
      code: '4x100c_B', 
      name: '4x100c (乙組)', 
      category: EventCategory.relay, 
      divisions: [Division.junior], 
      genders: [Gender.mixed],
      isClassRelay: true,
      maxParticipants: 4,
      specialRules: '乙組班際接力，每班最多一隊，每年級分別排名',
    ),
    EventInfo(
      code: '4x400c_B', 
      name: '4x400c (乙組)', 
      category: EventCategory.relay, 
      divisions: [Division.junior], 
      genders: [Gender.mixed],
      isClassRelay: true,
      maxParticipants: 4,
      specialRules: '乙組班際接力，每班最多一隊，每年級分別排名',
    ),
    // 丙組班際接力 (中1-2)
    EventInfo(
      code: '4x100c_C', 
      name: '4x100c (丙組)', 
      category: EventCategory.relay, 
      divisions: [Division.primary], 
      genders: [Gender.mixed],
      isClassRelay: true,
      maxParticipants: 4,
      specialRules: '丙組班際接力，每班最多一隊，每年級分別排名',
    ),
    EventInfo(
      code: '4x400c_C', 
      name: '4x400c (丙組)', 
      category: EventCategory.relay, 
      divisions: [Division.primary], 
      genders: [Gender.mixed],
      isClassRelay: true,
      maxParticipants: 4,
      specialRules: '丙組班際接力，每班最多一隊，每年級分別排名',
    ),
  ];

  /// 社制接力項目 (4x100s, 4x400s)
  static const List<EventInfo> societyRelayEvents = [
    // 甲組社制接力
    EventInfo(
      code: '4x100s_A', 
      name: '4x100s (甲組)', 
      category: EventCategory.relay, 
      divisions: [Division.senior], 
      genders: [Gender.mixed],
      specialRules: '甲組社制接力，每年級分別排名',
    ),
    EventInfo(
      code: '4x400s_A', 
      name: '4x400s (甲組)', 
      category: EventCategory.relay, 
      divisions: [Division.senior], 
      genders: [Gender.mixed],
      specialRules: '甲組社制接力，每年級分別排名',
    ),
    // 乙組社制接力
    EventInfo(
      code: '4x100s_B', 
      name: '4x100s (乙組)', 
      category: EventCategory.relay, 
      divisions: [Division.junior], 
      genders: [Gender.mixed],
      specialRules: '乙組社制接力，每年級分別排名',
    ),
    EventInfo(
      code: '4x400s_B', 
      name: '4x400s (乙組)', 
      category: EventCategory.relay, 
      divisions: [Division.junior], 
      genders: [Gender.mixed],
      specialRules: '乙組社制接力，每年級分別排名',
    ),
    // 丙組社制接力
    EventInfo(
      code: '4x100s_C', 
      name: '4x100s (丙組)', 
      category: EventCategory.relay, 
      divisions: [Division.primary], 
      genders: [Gender.mixed],
      specialRules: '丙組社制接力，每年級分別排名',
    ),
    EventInfo(
      code: '4x400s_C', 
      name: '4x400s (丙組)', 
      category: EventCategory.relay, 
      divisions: [Division.primary], 
      genders: [Gender.mixed],
      specialRules: '丙組社制接力，每年級分別排名',
    ),
  ];

  /// 特殊接力項目 (10人接力、家長接力、師生接力)
  static const List<EventInfo> specialRelayEvents = [
    // 10人接力
    EventInfo(
      code: '10R', 
      name: '10人接力', 
      category: EventCategory.special, 
      divisions: Division.values, 
      genders: [Gender.mixed],
      maxParticipants: 10,
      specialRules: '10人接力，每班最多一隊，混合年級排名',
    ),
    // 家長接力
    EventInfo(
      code: 'PARENT_R', 
      name: '家長接力', 
      category: EventCategory.special, 
      divisions: Division.values, 
      genders: [Gender.mixed],
      maxParticipants: 4,
      specialRules: '家長接力，每班最多一隊家長，混合年級排名',
    ),
    // 師生接力
    EventInfo(
      code: 'TEACHER_R', 
      name: '師生接力', 
      category: EventCategory.special, 
      divisions: Division.values, 
      genders: [Gender.mixed],
      maxParticipants: 4,
      specialRules: '師生接力，老師+學生混合，混合年級排名',
    ),
  ];

  /// 公開項目
  static const List<EventInfo> openEvents = [
    EventInfo(
      code: 'FREE1500', 
      name: '1500m (Open)', 
      category: EventCategory.track, 
      divisions: Division.values, 
      genders: [Gender.mixed],
      specialRules: '公開1500米',
    ),
  ];

  /// 所有項目的完整列表
  static List<EventInfo> get allEvents => [
    // 女子項目 (G開頭)
    ...seniorFemaleEvents_G,
    ...juniorFemaleEvents_G,
    ...primaryFemaleEvents_G,
    // 男子項目 (B開頭)
    ...seniorMaleEvents_B,
    ...juniorMaleEvents_B,
    ...primaryMaleEvents_B,
    // 接力和特殊項目
    ...classRelayEvents,
    ...societyRelayEvents,
    ...specialRelayEvents,
    ...openEvents,
  ];

  /// 根據代碼查找項目
  static EventInfo? findByCode(String code) {
    try {
      return allEvents.firstWhere((event) => event.code == code);
    } catch (e) {
      return null;
    }
  }

  /// 根據組別和性別篩選項目
  static List<EventInfo> filterEvents({
    Division? division,
    Gender? gender,
    EventCategory? category,
    bool? isScoring,
  }) {
    return allEvents.where((event) {
      if (division != null && !event.divisions.contains(division)) return false;
      if (gender != null && !event.genders.contains(gender) && !event.genders.contains(Gender.mixed)) return false;
      if (category != null && event.category != category) return false;
      if (isScoring != null && event.isScoring != isScoring) return false;
      return true;
    }).toList();
  }

  /// 獲取學生可報名的項目
  static List<EventInfo> getAvailableEvents(Division division, Gender gender) {
    return filterEvents(division: division, gender: gender, isScoring: true);
  }
}

/// 報名規則常數
class RegistrationRules {
  /// 個人項目最大報名數
  static const int maxIndividualEvents = 3;
  
  /// 接力項目無數量限制（設為-1表示無限制）
  static const int maxRelayEvents = -1;
  
  /// 田賽項目最大報名數
  static const int maxFieldEvents = 2;
  
  /// 徑賽項目最大報名數  
  static const int maxTrackEvents = 2;
  
  /// 班際接力每班最大參與人數
  static const int maxClassRelayParticipants = 4;
  
  /// 檢查田賽/徑賽組合是否有效
  static bool isValidTrackFieldCombination(List<EventInfo> events) {
    final trackCount = events.where((e) => e.category == EventCategory.track).length;
    final fieldCount = events.where((e) => e.category == EventCategory.field).length;
    
    // 最多只可參加2項田賽或2項徑賽 (兩田一徑或兩徑一田)
    return (trackCount <= 2 && fieldCount <= 2) && 
           (trackCount + fieldCount <= 3) &&
           !(trackCount > 2 || fieldCount > 2);
  }
  
  /// 檢查班際接力報名是否有效
  static bool isValidClassRelayRegistration(List<String> eventCodes) {
    final classRelayEvents = eventCodes.where((code) => 
      ['5641', '5644', '1441', '1444'].contains(code)
    ).toList();
    
    // 根據香港中學運動會規則，班際接力項目無數量限制
    return true; // 總是返回true，不限制數量
  }
} 