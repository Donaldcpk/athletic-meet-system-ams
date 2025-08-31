/// 操作日誌服務
/// 記錄所有用戶操作，支持回溯和審計

import 'dart:convert';
import 'dart:html' as html;
import '../services/user_service.dart';
import '../services/firebase_service.dart';
import '../models/student.dart';

class OperationLogService {
  static final List<OperationLog> _logs = [];
  static const String _localLogKey = 'operation_logs';
  
  /// 記錄操作
  static Future<void> logOperation(OperationType type, String description, {
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    String? targetId,
  }) async {
    final user = UserService.currentUser;
    if (user == null) return;
    
    final log = OperationLog(
      id: _generateLogId(),
      timestamp: DateTime.now(),
      userId: user.username,
      userRole: user.role,
      sessionId: user.sessionId,
      type: type,
      description: description,
      oldData: oldData,
      newData: newData,
      targetId: targetId,
    );
    
    _logs.insert(0, log); // 新的操作插入到前面
    
    // 保持最近1000條記錄
    if (_logs.length > 1000) {
      _logs.removeRange(1000, _logs.length);
    }
    
    // 保存到本地存儲
    _saveToLocal();
    
    // 同步到Firebase
    _syncToFirebase(log);
  }
  
  /// 記錄學生操作
  static Future<void> logStudentOperation(
    OperationType type, 
    String description, 
    Student? oldStudent, 
    Student? newStudent
  ) async {
    await logOperation(
      type,
      description,
      oldData: oldStudent?.toJson(),
      newData: newStudent?.toJson(),
      targetId: newStudent?.id ?? oldStudent?.id,
    );
  }
  
  /// 記錄成績操作
  static Future<void> logScoreOperation(
    OperationType type,
    String description,
    String studentId,
    String eventCode,
    {dynamic oldScore, dynamic newScore}
  ) async {
    await logOperation(
      type,
      description,
      oldData: oldScore != null ? {'score': oldScore, 'studentId': studentId, 'eventCode': eventCode} : null,
      newData: newScore != null ? {'score': newScore, 'studentId': studentId, 'eventCode': eventCode} : null,
      targetId: '${studentId}_$eventCode',
    );
  }
  
  /// 獲取操作日誌
  static List<OperationLog> getLogs({int? limit, OperationType? type}) {
    var logs = List<OperationLog>.from(_logs);
    
    if (type != null) {
      logs = logs.where((log) => log.type == type).toList();
    }
    
    if (limit != null && limit > 0) {
      logs = logs.take(limit).toList();
    }
    
    return logs;
  }
  
  /// 獲取特定用戶的操作日誌
  static List<OperationLog> getUserLogs(String userId, {int? limit}) {
    var logs = _logs.where((log) => log.userId == userId).toList();
    
    if (limit != null && limit > 0) {
      logs = logs.take(limit).toList();
    }
    
    return logs;
  }
  
  /// 獲取今日操作統計
  static Map<String, int> getTodayStats() {
    final today = DateTime.now();
    final todayLogs = _logs.where((log) {
      return log.timestamp.year == today.year &&
             log.timestamp.month == today.month &&
             log.timestamp.day == today.day;
    }).toList();
    
    final stats = <String, int>{};
    for (final type in OperationType.values) {
      stats[type.name] = todayLogs.where((log) => log.type == type).length;
    }
    
    stats['總操作數'] = todayLogs.length;
    stats['活躍用戶'] = todayLogs.map((log) => log.userId).toSet().length;
    
    return stats;
  }
  
  /// 檢查是否可以回溯
  static bool canRollback(String logId) {
    final log = _logs.firstWhere(
      (l) => l.id == logId,
      orElse: () => throw Exception('操作記錄不存在'),
    );
    
    // 只有有舊數據的操作才能回溯
    return log.oldData != null && 
           (log.type == OperationType.update || log.type == OperationType.delete);
  }
  
  /// 執行回溯操作
  static Future<bool> rollbackOperation(String logId) async {
    try {
      final log = _logs.firstWhere(
        (l) => l.id == logId,
        orElse: () => throw Exception('操作記錄不存在'),
      );
      
      if (!canRollback(logId)) {
        throw Exception('此操作無法回溯');
      }
      
      // 記錄回溯操作
      await logOperation(
        OperationType.rollback,
        '回溯操作: ${log.description}',
        oldData: log.newData,
        newData: log.oldData,
        targetId: log.targetId,
      );
      
      return true;
    } catch (e) {
      print('回溯失敗: $e');
      return false;
    }
  }
  
  /// 從本地存儲加載日誌
  static void loadFromLocal() {
    try {
      final logsJson = html.window.localStorage[_localLogKey];
      if (logsJson != null) {
        final logsData = json.decode(logsJson) as List<dynamic>;
        _logs.clear();
        _logs.addAll(
          logsData.map((json) => OperationLog.fromJson(json as Map<String, dynamic>))
        );
      }
    } catch (e) {
      print('載入本地日誌失敗: $e');
    }
  }
  
  /// 保存到本地存儲
  static void _saveToLocal() {
    try {
      final logsJson = json.encode(_logs.map((log) => log.toJson()).toList());
      html.window.localStorage[_localLogKey] = logsJson;
    } catch (e) {
      print('保存本地日誌失敗: $e');
    }
  }
  
  /// 同步到Firebase
  static Future<void> _syncToFirebase(OperationLog log) async {
    try {
      await FirebaseService.uploadOperationLog(log);
    } catch (e) {
      print('同步日誌到Firebase失敗: $e');
    }
  }
  
  /// 生成日誌ID
  static String _generateLogId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'log_${timestamp}_$random';
  }
  
  /// 清理舊日誌
  static void cleanOldLogs({int keepDays = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: keepDays));
    _logs.removeWhere((log) => log.timestamp.isBefore(cutoff));
    _saveToLocal();
  }
}

/// 操作日誌模型
class OperationLog {
  final String id;
  final DateTime timestamp;
  final String userId;
  final String userRole;
  final String sessionId;
  final OperationType type;
  final String description;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final String? targetId;
  
  OperationLog({
    required this.id,
    required this.timestamp,
    required this.userId,
    required this.userRole,
    required this.sessionId,
    required this.type,
    required this.description,
    this.oldData,
    this.newData,
    this.targetId,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'userRole': userRole,
      'sessionId': sessionId,
      'type': type.name,
      'description': description,
      'oldData': oldData,
      'newData': newData,
      'targetId': targetId,
    };
  }
  
  factory OperationLog.fromJson(Map<String, dynamic> json) {
    return OperationLog(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['userId'] as String,
      userRole: json['userRole'] as String,
      sessionId: json['sessionId'] as String,
      type: OperationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => OperationType.other,
      ),
      description: json['description'] as String,
      oldData: json['oldData'] as Map<String, dynamic>?,
      newData: json['newData'] as Map<String, dynamic>?,
      targetId: json['targetId'] as String?,
    );
  }
  
  /// 獲取操作時間顯示
  String get timeDisplay {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) {
      return '剛剛';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分鐘前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}小時前';
    } else {
      return '${timestamp.month}月${timestamp.day}日 ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
  
  /// 獲取操作類型顯示
  String get typeDisplay {
    switch (type) {
      case OperationType.create:
        return '新增';
      case OperationType.update:
        return '修改';
      case OperationType.delete:
        return '刪除';
      case OperationType.import:
        return '匯入';
      case OperationType.export:
        return '匯出';
      case OperationType.login:
        return '登入';
      case OperationType.logout:
        return '登出';
      case OperationType.rollback:
        return '回溯';
      case OperationType.other:
        return '其他';
    }
  }
}

/// 操作類型枚舉
enum OperationType {
  create,    // 新增
  update,    // 修改
  delete,    // 刪除
  import,    // 匯入
  export,    // 匯出
  login,     // 登入
  logout,    // 登出
  rollback,  // 回溯
  other,     // 其他
}
