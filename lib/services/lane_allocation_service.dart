/// 徑賽線道分配服務
/// 基於Circle Seeding算法為徑賽項目分配熱身賽和線道

import 'dart:math';
import '../models/student.dart';

/// 線道分配結果
class LaneAllocation {
  final String heatName;
  final List<LaneAssignment> assignments;
  
  const LaneAllocation({
    required this.heatName,
    required this.assignments,
  });
}

/// 單個線道分配
class LaneAssignment {
  final Student student;
  final int lane;
  final int seedRank; // 種子排名
  
  const LaneAssignment({
    required this.student,
    required this.lane,
    required this.seedRank,
  });
}

/// 徑賽線道分配服務
class LaneAllocationService {
  /// 分配徑賽初賽熱身賽和線道
  /// 
  /// [participants] 參賽運動員列表
  /// [maxLanes] 每熱身賽最大人數 (預設 8)
  /// [minHeatSize] 每熱身賽最小人數 (預設 3)
  /// [preferredLanes] 線道優選順序 (中間優先)
  static List<LaneAllocation> allocateHeatsAndLanes(
    List<Student> participants, {
    int maxLanes = 8,
    int minHeatSize = 3,
    List<int> preferredLanes = const [4, 5, 6, 3, 7, 2, 8, 1],
  }) {
    final numAthletes = participants.length;
    
    if (numAthletes < 3 || numAthletes > 100) {
      throw ArgumentError('運動員數必須在 3 到 100 之間。');
    }
    
    // 步驟 1: 計算最佳熱身賽數
    int numHeats = _calculateOptimalHeats(numAthletes, maxLanes, minHeatSize);
    
    // 步驟 2: 建立運動員種子排名（隨機或根據已有成績）
    final shuffledParticipants = List<Student>.from(participants);
    shuffledParticipants.shuffle(Random());
    
    // 步驟 3: 使用 Circle Seeding 分配到熱身賽
    final heats = _distributeToHeats(shuffledParticipants, numHeats);
    
    // 步驟 4: 為每熱身賽分配線道
    final allocations = <LaneAllocation>[];
    
    for (int i = 0; i < heats.length; i++) {
      final heatParticipants = heats[i];
      final assignments = _assignLanes(heatParticipants, preferredLanes);
      
      allocations.add(LaneAllocation(
        heatName: 'Heat ${i + 1}',
        assignments: assignments,
      ));
    }
    
    return allocations;
  }
  
  /// 計算最佳熱身賽數
  static int _calculateOptimalHeats(int numAthletes, int maxLanes, int minHeatSize) {
    // 計算最大可能熱身賽數 (確保每組 <= maxLanes)
    int maxHeats = numAthletes ~/ minHeatSize;
    
    // 調整為最小熱身賽數，確保每組 >= minHeatSize
    int numHeats = min(maxHeats, (numAthletes + maxLanes - 1) ~/ maxLanes);
    numHeats = max(1, numHeats);
    
    // 驗證並調整：如果導致小於 minHeatSize，減少熱身賽數
    while (numHeats > 1) {
      final baseSize = numAthletes ~/ numHeats;
      final extra = numAthletes % numHeats;
      
      bool allValid = true;
      for (int i = 0; i < numHeats; i++) {
        final heatSize = i < extra ? baseSize + 1 : baseSize;
        if (heatSize < minHeatSize) {
          allValid = false;
          break;
        }
      }
      
      if (allValid) break;
      numHeats--;
    }
    
    return numHeats;
  }
  
  /// 使用Circle Seeding將運動員分配到熱身賽
  static List<List<Student>> _distributeToHeats(List<Student> athletes, int numHeats) {
    final heats = List.generate(numHeats, (index) => <Student>[]);
    
    for (int i = 0; i < athletes.length; i++) {
      heats[i % numHeats].add(athletes[i]);
    }
    
    return heats;
  }
  
  /// 為熱身賽分配線道
  static List<LaneAssignment> _assignLanes(List<Student> heatParticipants, List<int> preferredLanes) {
    final size = heatParticipants.length;
    
    // 取前 size 個優選線道並隨機打亂
    final availableLanes = List<int>.from(preferredLanes.take(size));
    availableLanes.shuffle(Random());
    
    // 按熱身賽內排名排序後分配
    final sortedParticipants = List<Student>.from(heatParticipants);
    // 可以根據預賽成績排序，這裡暫時按學號排序
    sortedParticipants.sort((a, b) => a.studentCode.compareTo(b.studentCode));
    
    final assignments = <LaneAssignment>[];
    for (int i = 0; i < sortedParticipants.length; i++) {
      assignments.add(LaneAssignment(
        student: sortedParticipants[i],
        lane: availableLanes[i],
        seedRank: i + 1,
      ));
    }
    
    // 按線道順序排序以便顯示
    assignments.sort((a, b) => a.lane.compareTo(b.lane));
    
    return assignments;
  }
  
  /// 根據已有成績重新分配線道（用於決賽）
  static List<LaneAllocation> allocateFinalsLanes(
    List<Student> finalists,
    Map<String, String> preliminaryResults, {
    List<int> preferredLanes = const [4, 5, 6, 3, 7, 2, 8, 1],
  }) {
    // 根據初賽成績排序
    final rankedFinalists = List<Student>.from(finalists);
    rankedFinalists.sort((a, b) {
      final aResult = preliminaryResults['${a.id}_event'] ?? '99:99.99';
      final bResult = preliminaryResults['${b.id}_event'] ?? '99:99.99';
      
      final aTime = _parseTimeResult(aResult);
      final bTime = _parseTimeResult(bResult);
      
      return aTime.compareTo(bTime);
    });
    
    // 為決賽分配最佳線道
    final assignments = _assignFinalsLanes(rankedFinalists, preferredLanes);
    
    return [LaneAllocation(
      heatName: '決賽',
      assignments: assignments,
    )];
  }
  
  /// 為決賽分配線道（最佳成績在中間線道）
  static List<LaneAssignment> _assignFinalsLanes(List<Student> rankedFinalists, List<int> preferredLanes) {
    final assignments = <LaneAssignment>[];
    
    // 決賽線道分配：最佳成績在中間，依次向兩邊分配
    final laneOrder = List<int>.from(preferredLanes.take(rankedFinalists.length));
    
    for (int i = 0; i < rankedFinalists.length; i++) {
      assignments.add(LaneAssignment(
        student: rankedFinalists[i],
        lane: laneOrder[i],
        seedRank: i + 1,
      ));
    }
    
    // 按線道順序排序
    assignments.sort((a, b) => a.lane.compareTo(b.lane));
    
    return assignments;
  }
  
  /// 解析時間成績
  static double _parseTimeResult(String result) {
    try {
      if (result.contains(':')) {
        final parts = result.split(':');
        if (parts.length == 2) {
          final minutes = double.parse(parts[0]);
          final seconds = double.parse(parts[1]);
          return minutes * 60 + seconds;
        }
      }
      return double.parse(result);
    } catch (e) {
      return 99999.0; // 無效成績排到最後
    }
  }
  
  /// 生成線道分配報告
  static String generateAllocationReport(List<LaneAllocation> allocations) {
    final buffer = StringBuffer();
    buffer.writeln('徑賽線道分配表');
    buffer.writeln('=' * 50);
    
    for (final allocation in allocations) {
      buffer.writeln('\n${allocation.heatName}：');
      buffer.writeln('-' * 30);
      
      for (final assignment in allocation.assignments) {
        buffer.writeln(
          '線道 ${assignment.lane}: ${assignment.student.studentCode} ${assignment.student.name} (${assignment.student.classId})'
        );
      }
    }
    
    return buffer.toString();
  }
}
