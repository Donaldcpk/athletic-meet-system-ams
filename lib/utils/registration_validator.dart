import '../models/student.dart';
import '../models/event.dart';
import '../constants/app_constants.dart';

/// 報名衝突檢查工具
/// 提供完整的報名驗證和衝突檢查功能
class RegistrationValidator {
  
  /// 檢查學生報名是否有衝突
  static RegistrationResult validateRegistration(
    Student student,
    String eventId,
    List<Event> allEvents,
    {List<Student>? allStudents}
  ) {
    final warnings = <String>[];
    final errors = <String>[];
    
    final event = allEvents.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw ArgumentError('找不到項目: $eventId'),
    );

    // 1. 檢查基本資格
    _checkBasicEligibility(student, event, errors);
    
    // 2. 檢查報名數量限制
    _checkRegistrationLimits(student, event, allEvents, warnings, errors);
    
    // 3. 檢查跨組別衝突
    _checkDivisionConflicts(student, event, warnings);
    
    // 4. 檢查時間衝突
    _checkTimeConflicts(student, event, allEvents, warnings);
    
    // 5. 班級名額限制已移除 (根據用戶要求)

    return RegistrationResult(
      isValid: errors.isEmpty,
      warnings: warnings,
      errors: errors,
      recommendedAction: _getRecommendedAction(warnings, errors),
    );
  }

  /// 檢查基本資格
  static void _checkBasicEligibility(Student student, Event event, List<String> errors) {
    // 檢查性別匹配 - 更詳細的驗證
    if (event.gender != Gender.mixed && event.gender != student.gender) {
      final eventGenderText = event.gender == Gender.male ? '男子' : '女子';
      final studentGenderText = student.gender == Gender.male ? '男生' : '女生';
      errors.add('⚠️ 性別不符：「${event.name}」是${eventGenderText}項目，但您是${studentGenderText}，無法報名此項目');
    }
    
    // 檢查組別
    if (!event.divisions.contains(student.division)) {
      final allowedDivisions = event.divisions.map((d) => d.displayName).join('、');
      errors.add('組別不符：此項目僅限$allowedDivisions參加，您的組別是${student.division.displayName}');
    }
    
    // 檢查是否已報名
    if (student.registeredEvents.contains(event.id)) {
      errors.add('重複報名：您已經報名了此項目');
    }
    
    // 檢查項目是否啟用
    if (!event.isActive) {
      errors.add('項目暫停：此項目目前暫停報名');
    }
  }

  /// 檢查報名數量限制
  static void _checkRegistrationLimits(
    Student student,
    Event event,
    List<Event> allEvents,
    List<String> warnings,
    List<String> errors,
  ) {
    final registeredIndividualEvents = student.registeredEvents
        .where((eventId) {
          final regEvent = allEvents.firstWhere((e) => e.id == eventId);
          return regEvent.type == EventType.individual;
        })
        .length;
    
    final registeredRelayEvents = student.registeredEvents
        .where((eventId) {
          final regEvent = allEvents.firstWhere((e) => e.id == eventId);
          return regEvent.type == EventType.relay;
        })
        .length;

    if (event.type == EventType.individual) {
      if (registeredIndividualEvents >= AppConstants.maxIndividualEvents) {
        errors.add('個人項目超限：每位學生最多報名${AppConstants.maxIndividualEvents}個個人項目');
      } else if (registeredIndividualEvents == AppConstants.maxIndividualEvents - 1) {
        warnings.add('個人項目接近上限：這將是您的第${AppConstants.maxIndividualEvents}個個人項目');
      }
    }
    
    if (event.type == EventType.relay) {
      // 接力項目無數量限制，移除相關檢查
      // 根據香港中學運動會規則，接力項目不設報名上限
    }
  }

  /// 檢查跨組別衝突
  static void _checkDivisionConflicts(Student student, Event event, List<String> warnings) {
    // 檢查是否有其他組別的類似項目已報名
    final similarEvents = student.registeredEvents.where((eventId) {
      return eventId.contains(event.shortName) && eventId != event.id;
    }).toList();
    
    if (similarEvents.isNotEmpty) {
      warnings.add('類似項目提醒：您已報名相似項目，請確認是否需要報名此項目');
    }
  }

  /// 檢查時間衝突
  static void _checkTimeConflicts(
    Student student,
    Event event,
    List<Event> allEvents,
    List<String> warnings,
  ) {
    if (event.scheduledDate == null || event.scheduledTime == null) {
      return; // 沒有時間安排，跳過檢查
    }

    for (final registeredEventId in student.registeredEvents) {
      final registeredEvent = allEvents.firstWhere((e) => e.id == registeredEventId);
      
      if (registeredEvent.scheduledDate != null && 
          registeredEvent.scheduledTime != null) {
        
        final eventStart = DateTime(
          event.scheduledDate!.year,
          event.scheduledDate!.month,
          event.scheduledDate!.day,
          event.scheduledTime!.hour,
          event.scheduledTime!.minute,
        );
        
        final registeredStart = DateTime(
          registeredEvent.scheduledDate!.year,
          registeredEvent.scheduledDate!.month,
          registeredEvent.scheduledDate!.day,
          registeredEvent.scheduledTime!.hour,
          registeredEvent.scheduledTime!.minute,
        );
        
        final timeDiff = eventStart.difference(registeredStart).abs();
        
        if (timeDiff < const Duration(hours: 1)) {
          warnings.add(
            '時間緊湊：此項目與${registeredEvent.name}時間相近，請注意準備時間'
          );
        }
      }
    }
  }



  /// 獲取建議操作
  static String _getRecommendedAction(List<String> warnings, List<String> errors) {
    if (errors.isNotEmpty) {
      return '❌ 無法報名：請解決以上問題後重試';
    } else if (warnings.isNotEmpty) {
      return '⚠️ 可以報名但需注意：建議檢查上述提醒事項';
    } else {
      return '✅ 可以報名：符合所有條件';
    }
  }

  /// 批量檢查學生報名衝突
  static Map<String, List<String>> batchValidateStudent(
    Student student,
    List<Event> allEvents,
    {List<Student>? allStudents}
  ) {
    final conflicts = <String, List<String>>{};
    
    for (final eventId in student.registeredEvents) {
      final result = validateRegistration(student, eventId, allEvents, allStudents: allStudents);
      if (result.warnings.isNotEmpty || result.errors.isNotEmpty) {
        conflicts[eventId] = [...result.warnings, ...result.errors];
      }
    }
    
    return conflicts;
  }

  /// 生成班級報名統計
  static ClassRegistrationStats getClassStats(
    String classId,
    List<Student> allStudents,
    List<Event> allEvents,
  ) {
    final classStudents = allStudents.where((s) => s.classId == classId).toList();
    final eventStats = <String, EventClassStats>{};
    
    for (final event in allEvents) {
      final registeredCount = classStudents
          .where((s) => s.registeredEvents.contains(event.id))
          .length;
      
      eventStats[event.id] = EventClassStats(
        eventId: event.id,
        eventName: event.name,
        registeredCount: registeredCount,
        maxAllowed: 3, // 假設每班每項目最多3人
        remainingSlots: 3 - registeredCount,
      );
    }
    
    return ClassRegistrationStats(
      classId: classId,
      totalStudents: classStudents.length,
      participatingStudents: classStudents.where((s) => s.registeredEvents.isNotEmpty).length,
      eventStats: eventStats,
    );
  }
}

/// 報名檢查結果
class RegistrationResult {
  final bool isValid;
  final List<String> warnings;
  final List<String> errors;
  final String recommendedAction;

  const RegistrationResult({
    required this.isValid,
    required this.warnings,
    required this.errors,
    required this.recommendedAction,
  });

  /// 是否有任何問題
  bool get hasIssues => warnings.isNotEmpty || errors.isNotEmpty;
  
  /// 獲取所有問題
  List<String> get allIssues => [...errors, ...warnings];
}

/// 班級報名統計
class ClassRegistrationStats {
  final String classId;
  final int totalStudents;
  final int participatingStudents;
  final Map<String, EventClassStats> eventStats;

  const ClassRegistrationStats({
    required this.classId,
    required this.totalStudents,
    required this.participatingStudents,
    required this.eventStats,
  });

  /// 參與率
  double get participationRate => 
      totalStudents > 0 ? participatingStudents / totalStudents : 0.0;
}

/// 項目班級統計
class EventClassStats {
  final String eventId;
  final String eventName;
  final int registeredCount;
  final int maxAllowed;
  final int remainingSlots;

  const EventClassStats({
    required this.eventId,
    required this.eventName,
    required this.registeredCount,
    required this.maxAllowed,
    required this.remainingSlots,
  });

  /// 是否已滿額
  bool get isFull => remainingSlots <= 0;
  
  /// 是否接近滿額
  bool get isNearFull => remainingSlots == 1;
  
  /// 使用率
  double get utilizationRate => registeredCount / maxAllowed;
} 