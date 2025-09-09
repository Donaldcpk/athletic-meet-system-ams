/// 接力賽管理服務
/// 支援統一接力賽格式、即時排名計算、積分整合
import 'dart:convert';
import '../models/student.dart';
import '../models/event.dart' as EventModel;
import '../constants/event_constants.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';
import 'scoring_service.dart';
import 'realtime_sync_service.dart';
import 'dart:html' as html;

/// 接力賽服務
class RelayService {
  static const String _storageKey = 'relay_results';
  
  /// 接力賽結果資料
  static final Map<String, Map<String, Map<String, List<RelayTeamResult>>>> _relayResults = {};
  
  /// 初始化接力賽服務
  static Future<void> initialize() async {
    await _loadResults();
  }
  
  /// 載入接力賽結果
  static Future<void> _loadResults() async {
    try {
      final data = html.window.localStorage[_storageKey];
      if (data != null) {
        final jsonData = json.decode(data);
        _relayResults.clear();
        
        for (final eventCode in jsonData.keys) {
          _relayResults[eventCode] = {};
          final eventData = jsonData[eventCode];
          
          for (final divisionName in eventData.keys) {
            _relayResults[eventCode]![divisionName] = {};
            final divisionData = eventData[divisionName];
            
            for (final className in divisionData.keys) {
              final resultsList = divisionData[className] as List;
              _relayResults[eventCode]![divisionName]![className] = 
                resultsList.map((r) => RelayTeamResult.fromJson(r)).toList();
            }
          }
        }
      }
    } catch (e) {
      print('載入接力賽結果失敗：$e');
    }
  }
  
  /// 儲存接力賽結果
  static Future<void> _saveResults() async {
    try {
      final jsonData = <String, dynamic>{};
      
      for (final eventCode in _relayResults.keys) {
        jsonData[eventCode] = {};
        
        for (final divisionName in _relayResults[eventCode]!.keys) {
          jsonData[eventCode][divisionName] = {};
          
          for (final className in _relayResults[eventCode]![divisionName]!.keys) {
            jsonData[eventCode][divisionName][className] = 
              _relayResults[eventCode]![divisionName]![className]!
                .map((r) => r.toJson()).toList();
          }
        }
      }
      
      html.window.localStorage[_storageKey] = json.encode(jsonData);
      
      // 觸發即時同步 (暫時註釋)
      // RealtimeSyncService.broadcastUpdate('relay_results', {
      //   'action': 'update',
      //   'data': jsonData,
      //   'timestamp': DateTime.now().toIso8601String(),
      // });
    } catch (e) {
      print('儲存接力賽結果失敗：$e');
    }
  }
  
  /// 更新班級接力賽成績
  static Future<void> updateClassResult({
    required String eventCode,
    required String className,
    required Division division,
    required String result,
    List<String>? participants,
  }) async {
    try {
      // 驗證成績格式
      if (!_isValidTimeFormat(result)) {
        throw '成績格式錯誤，請使用 mm:ss.ms 格式';
      }
      
      // 驗證項目代碼
      final eventInfo = EventConstants.findByCode(eventCode);
      if (eventInfo == null) {
        throw '無效的項目代碼：$eventCode';
      }
      
      // 初始化數據結構
      _relayResults.putIfAbsent(eventCode, () => {});
      _relayResults[eventCode]!.putIfAbsent(division.displayName, () => {});
      _relayResults[eventCode]![division.displayName]!.putIfAbsent(className, () => []);
      
      // 創建成績記錄
      final teamResult = RelayTeamResult(
        classId: className,
        division: division,
        eventCode: eventCode,
        result: result,
        participants: participants ?? [],
        timestamp: DateTime.now(),
      );
      
      // 更新結果（替換既有記錄）
      _relayResults[eventCode]![division.displayName]![className] = [teamResult];
      
      // 計算即時排名
      await _calculateRealTimeRanking(eventCode, division);
      
      // 儲存結果
      await _saveResults();
      
      print('✅ 已更新 ${division.displayName} $className $eventCode 成績：$result');
    } catch (e) {
      print('❌ 更新接力賽成績失敗：$e');
      rethrow;
    }
  }
  
  /// 計算即時排名
  static Future<void> _calculateRealTimeRanking(String eventCode, Division division) async {
    final divisionResults = _relayResults[eventCode]?[division.displayName];
    if (divisionResults == null) return;
    
    final validResults = <String, RelayTeamResult>{};
    
    // 收集有效成績
    for (final className in divisionResults.keys) {
      final results = divisionResults[className];
      if (results != null && results.isNotEmpty) {
        validResults[className] = results.first;
      }
    }
    
    if (validResults.isEmpty) return;
    
    // 按成績排序（時間越短越好）
    final sortedEntries = validResults.entries.toList()
      ..sort((a, b) => _compareTimeResults(a.value.result, b.value.result));
    
    // 分配排名和積分
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final rank = i + 1;
      final points = AppConstants.calculatePositionPoints(rank, EventModel.EventType.relay);
      
      // 更新排名信息
      entry.value.rank = rank;
      entry.value.points = points;
      
      // 更新到積分系統
      await _updateClassPoints(entry.key, eventCode, points, rank, division);
    }
    
    // 宣佈前三名
    if (sortedEntries.length >= 3) {
      _announceTopThree(eventCode, division, sortedEntries.take(3).toList());
    }
    
    print('🏆 已更新 ${division.displayName} $eventCode 排名');
  }
  
  /// 比較時間成績
  static int _compareTimeResults(String time1, String time2) {
    final ms1 = _timeToMilliseconds(time1);
    final ms2 = _timeToMilliseconds(time2);
    return ms1.compareTo(ms2);
  }
  
  /// 時間轉換為毫秒
  static int _timeToMilliseconds(String time) {
    try {
      final parts = time.split(':');
      final minutes = int.parse(parts[0]);
      final secondsParts = parts[1].split('.');
      final seconds = int.parse(secondsParts[0]);
      final milliseconds = int.parse(secondsParts[1]);
      return (minutes * 60 * 1000) + (seconds * 1000) + (milliseconds * 10);
    } catch (e) {
      throw '時間格式錯誤：$time';
    }
  }
  
  /// 驗證時間格式
  static bool _isValidTimeFormat(String time) {
    final regex = RegExp(r'^\d{1,2}:\d{2}\.\d{2}$');
    return regex.hasMatch(time);
  }
  
  /// 更新班級積分
  static Future<void> _updateClassPoints(
    String className, 
    String eventCode, 
    int points, 
    int rank, 
    Division division
  ) async {
    try {
      // 通過ScoringService更新積分
      // 這裡需要找到對應班級的學生作為代表
      // 接力賽積分應該加到整個班級，不是個別學生
      
      // 創建一個虛擬的班級代表記錄來記錄接力賽積分
      final classRepresentativeId = '${className}_relay_representative';
      
      await ScoringService.updateStudentScore(
        studentId: classRepresentativeId,
        eventCode: eventCode,
        finalsResult: 'Class Result', // 標記為班級成績
        finalsRank: rank,
        isDNF: false,
        isDQ: false,
        isABS: false,
        isRecordBreaker: false,
      );
      
      print('📊 已更新 $className 在 $eventCode 的積分：第$rank名 (+$points分)');
    } catch (e) {
      print('更新班級積分失敗：$e');
    }
  }
  
  /// 宣佈前三名
  static void _announceTopThree(
    String eventCode, 
    Division division, 
    List<MapEntry<String, RelayTeamResult>> topThree
  ) {
    final winners = topThree.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final titles = ['🥇冠軍', '🥈亞軍', '🥉季軍'];
      return '${titles[index]}：${data.key} (${data.value.result})';
    }).join('\n');
    
    print('🏆 ${division.displayName} $eventCode 前三名：\n$winners');
  }
  
  /// 獲取接力賽結果
  static Map<String, List<RelayTeamResult>>? getEventResults(String eventCode, Division division) {
    return _relayResults[eventCode]?[division.displayName];
  }
  
  /// 獲取前三名結果
  static List<RelayTeamResult> getTopThree(String eventCode, Division division) {
    final results = getEventResults(eventCode, division);
    if (results == null) return [];
    
    final allResults = <RelayTeamResult>[];
    for (final classResults in results.values) {
      if (classResults.isNotEmpty) {
        allResults.add(classResults.first);
      }
    }
    
    // 按排名排序
    allResults.sort((a, b) => a.rank.compareTo(b.rank));
    return allResults.take(3).toList();
  }
  
  /// 獲取所有接力賽項目
  static List<EventInfo> getAllRelayEvents() {
    return EventConstants.allEvents.where((e) => 
      e.category == EventCategory.relay || 
      (e.isClassRelay == true)
    ).toList();
  }
  
  /// 匯出前三名資料
  static Map<String, dynamic> exportTopThreeData(String eventCode) {
    final result = <String, dynamic>{
      'eventCode': eventCode,
      'eventName': EventConstants.findByCode(eventCode)?.name ?? eventCode,
      'divisions': {},
      'exportTime': DateTime.now().toIso8601String(),
    };
    
    for (final division in Division.values) {
      final topThree = getTopThree(eventCode, division);
      if (topThree.isNotEmpty) {
        result['divisions'][division.displayName] = topThree.map((r) => {
          'rank': r.rank,
          'classId': r.classId,
          'result': r.result,
          'points': r.points,
        }).toList();
      }
    }
    
    return result;
  }
}

/// 接力賽團體成績
class RelayTeamResult {
  final String classId;
  final Division division;
  final String eventCode;
  final String result;
  final List<String> participants;
  final DateTime timestamp;
  int rank = 0;
  int points = 0;

  RelayTeamResult({
    required this.classId,
    required this.division,
    required this.eventCode,
    required this.result,
    this.participants = const [],
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'division': division.displayName,
      'eventCode': eventCode,
      'result': result,
      'participants': participants,
      'timestamp': timestamp.toIso8601String(),
      'rank': rank,
      'points': points,
    };
  }
  
  factory RelayTeamResult.fromJson(Map<String, dynamic> json) {
    final result = RelayTeamResult(
      classId: json['classId'],
      division: Division.values.firstWhere(
        (d) => d.displayName == json['division'],
        orElse: () => Division.primary,
      ),
      eventCode: json['eventCode'],
      result: json['result'],
      participants: List<String>.from(json['participants'] ?? []),
      timestamp: DateTime.parse(json['timestamp']),
    );
    result.rank = json['rank'] ?? 0;
    result.points = json['points'] ?? 0;
    return result;
  }
}
