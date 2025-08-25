/// 實時同步服務
/// 處理多用戶之間的數據同步和協作

import 'dart:convert';
import 'dart:html' as html;
import 'dart:async';
import '../utils/app_state.dart';
import 'storage_service.dart';

class RealtimeSyncService {
  static const String _sessionKey = 'athletic_meet_session';
  static const String _syncChannelName = 'athletic_meet_sync';
  
  static RealtimeSyncService? _instance;
  static RealtimeSyncService get instance {
    _instance ??= RealtimeSyncService._();
    return _instance!;
  }
  
  RealtimeSyncService._();
  
  late String _sessionId;
  late String _userName;
  Timer? _syncTimer;
  html.BroadcastChannel? _broadcastChannel;
  final AppState _appState = AppState();
  
  // 監聽器
  final List<Function(Map<String, dynamic>)> _dataChangeListeners = [];
  final List<Function(String, String)> _userActionListeners = [];
  
  /// 初始化同步服務
  Future<void> initialize(String userName) async {
    _userName = userName;
    _sessionId = _generateSessionId();
    
    // 設置會話信息
    await _setSessionInfo();
    
    // 初始化廣播通道（用於同一瀏覽器多標籤頁同步）
    _initializeBroadcastChannel();
    
    // 開始定期同步
    _startPeriodicSync();
    
    print('✅ 實時同步服務已啟動 - 用戶: $_userName, 會話: $_sessionId');
  }
  
  /// 生成會話ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 31) % 10000;
    return '${_userName}_${timestamp}_$random';
  }
  
  /// 設置會話信息
  Future<void> _setSessionInfo() async {
    final sessionInfo = {
      'sessionId': _sessionId,
      'userName': _userName,
      'startTime': DateTime.now().toIso8601String(),
      'lastActivity': DateTime.now().toIso8601String(),
      'isActive': true,
    };
    
    html.window.localStorage['${_sessionKey}_$_sessionId'] = json.encode(sessionInfo);
  }
  
  /// 初始化廣播通道
  void _initializeBroadcastChannel() {
    try {
      _broadcastChannel = html.BroadcastChannel(_syncChannelName);
      _broadcastChannel!.onMessage.listen((event) {
        _handleBroadcastMessage(event.data);
      });
      print('✅ 廣播通道已初始化');
    } catch (e) {
      print('⚠️ 廣播通道初始化失敗: $e');
    }
  }
  
  /// 處理廣播消息
  void _handleBroadcastMessage(dynamic data) {
    try {
      final message = data as Map<String, dynamic>;
      final type = message['type'] as String;
      final fromSession = message['sessionId'] as String;
      
      // 忽略自己發送的消息
      if (fromSession == _sessionId) return;
      
      switch (type) {
        case 'data_update':
          _handleDataUpdate(message);
          break;
        case 'user_action':
          _handleUserAction(message);
          break;
        case 'session_ping':
          _handleSessionPing(message);
          break;
      }
    } catch (e) {
      print('❌ 處理廣播消息失敗: $e');
    }
  }
  
  /// 處理數據更新
  void _handleDataUpdate(Map<String, dynamic> message) {
    try {
      final dataType = message['dataType'] as String;
      final data = message['data'];
      
      // 通知監聽器
      for (final listener in _dataChangeListeners) {
        listener({
          'type': dataType,
          'data': data,
          'from': message['userName'],
          'timestamp': message['timestamp'],
        });
      }
      
      // 如果是重要數據變更，重新加載
      if (['students', 'scores', 'finalists'].contains(dataType)) {
        _reloadDataFromStorage();
      }
      
    } catch (e) {
      print('❌ 處理數據更新失敗: $e');
    }
  }
  
  /// 處理用戶操作
  void _handleUserAction(Map<String, dynamic> message) {
    final action = message['action'] as String;
    final userName = message['userName'] as String;
    
    for (final listener in _userActionListeners) {
      listener(userName, action);
    }
  }
  
  /// 處理會話ping
  void _handleSessionPing(Map<String, dynamic> message) {
    // 更新活躍會話列表
    final sessionId = message['sessionId'] as String;
    final userName = message['userName'] as String;
    print('📡 收到會話ping: $userName');
  }
  
  /// 廣播數據更新
  Future<void> broadcastDataUpdate(String dataType, dynamic data) async {
    if (_broadcastChannel != null) {
      final message = {
        'type': 'data_update',
        'sessionId': _sessionId,
        'userName': _userName,
        'dataType': dataType,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _broadcastChannel!.postMessage(message);
      await _updateLastActivity();
    }
  }
  
  /// 廣播用戶操作
  Future<void> broadcastUserAction(String action) async {
    if (_broadcastChannel != null) {
      final message = {
        'type': 'user_action',
        'sessionId': _sessionId,
        'userName': _userName,
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _broadcastChannel!.postMessage(message);
      await _updateLastActivity();
    }
  }
  
  /// 開始定期同步
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _performSync();
    });
  }
  
  /// 執行同步
  Future<void> _performSync() async {
    try {
      // 發送session ping
      if (_broadcastChannel != null) {
        final pingMessage = {
          'type': 'session_ping',
          'sessionId': _sessionId,
          'userName': _userName,
          'timestamp': DateTime.now().toIso8601String(),
        };
        _broadcastChannel!.postMessage(pingMessage);
      }
      
      // 更新最後活動時間
      await _updateLastActivity();
      
      // 檢查是否有外部數據更新
      await _checkForExternalUpdates();
      
    } catch (e) {
      print('❌ 同步失敗: $e');
    }
  }
  
  /// 檢查外部數據更新
  Future<void> _checkForExternalUpdates() async {
    // 這裡可以實現檢查雲端或其他來源的數據更新
    // 暫時檢查本地存儲的變更
    final currentStats = StorageService.getStorageStats();
    // TODO: 比較數據版本，如有需要則重新加載
  }
  
  /// 重新從存儲加載數據
  Future<void> _reloadDataFromStorage() async {
    try {
      // 觸發AppState重新加載
      await _appState.initialize();
      print('✅ 數據已從存儲重新加載');
    } catch (e) {
      print('❌ 重新加載數據失敗: $e');
    }
  }
  
  /// 更新最後活動時間
  Future<void> _updateLastActivity() async {
    try {
      final sessionKey = '${_sessionKey}_$_sessionId';
      final existingData = html.window.localStorage[sessionKey];
      if (existingData != null) {
        final sessionInfo = json.decode(existingData) as Map<String, dynamic>;
        sessionInfo['lastActivity'] = DateTime.now().toIso8601String();
        html.window.localStorage[sessionKey] = json.encode(sessionInfo);
      }
    } catch (e) {
      print('❌ 更新活動時間失敗: $e');
    }
  }
  
  /// 獲取活躍會話
  List<Map<String, dynamic>> getActiveSessions() {
    final sessions = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    try {
      // 掃描本地存儲中的會話 - 使用不同的方法迭代keys
      final allKeys = <String>[];
      
      // 獲取所有localStorage的keys
      for (var key in html.window.localStorage.keys) {
        if (key.startsWith(_sessionKey)) {
          allKeys.add(key);
        }
      }
      
      for (final key in allKeys) {
        final sessionData = html.window.localStorage[key];
        if (sessionData != null) {
          final sessionInfo = json.decode(sessionData) as Map<String, dynamic>;
          final lastActivity = DateTime.parse(sessionInfo['lastActivity']);
          
          // 只顯示最近5分鐘內活躍的會話
          if (now.difference(lastActivity).inMinutes <= 5) {
            sessions.add(sessionInfo);
          }
        }
      }
    } catch (e) {
      print('❌ 獲取活躍會話失敗: $e');
    }
    
    return sessions;
  }
  
  /// 添加數據變更監聽器
  void addDataChangeListener(Function(Map<String, dynamic>) listener) {
    _dataChangeListeners.add(listener);
  }
  
  /// 移除數據變更監聽器
  void removeDataChangeListener(Function(Map<String, dynamic>) listener) {
    _dataChangeListeners.remove(listener);
  }
  
  /// 添加用戶操作監聽器
  void addUserActionListener(Function(String, String) listener) {
    _userActionListeners.add(listener);
  }
  
  /// 移除用戶操作監聽器
  void removeUserActionListener(Function(String, String) listener) {
    _userActionListeners.remove(listener);
  }
  
  /// 關閉同步服務
  Future<void> dispose() async {
    _syncTimer?.cancel();
    _broadcastChannel?.close();
    
    // 標記會話為非活躍
    try {
      final sessionKey = '${_sessionKey}_$_sessionId';
      final existingData = html.window.localStorage[sessionKey];
      if (existingData != null) {
        final sessionInfo = json.decode(existingData) as Map<String, dynamic>;
        sessionInfo['isActive'] = false;
        sessionInfo['endTime'] = DateTime.now().toIso8601String();
        html.window.localStorage[sessionKey] = json.encode(sessionInfo);
      }
    } catch (e) {
      print('❌ 關閉會話失敗: $e');
    }
    
    print('✅ 實時同步服務已關閉');
  }
  
  /// 清理過期會話
  static void cleanupExpiredSessions() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    try {
      // 獲取所有localStorage的keys
      final allKeys = <String>[];
      for (var key in html.window.localStorage.keys) {
        if (key.startsWith(_sessionKey)) {
          allKeys.add(key);
        }
      }
      
      for (final key in allKeys) {
        final sessionData = html.window.localStorage[key];
        if (sessionData != null) {
          final sessionInfo = json.decode(sessionData) as Map<String, dynamic>;
          final lastActivity = DateTime.parse(sessionInfo['lastActivity']);
          
          // 清理1小時前的會話
          if (now.difference(lastActivity).inHours >= 1) {
            keysToRemove.add(key);
          }
        }
      }
      
      // 移除過期會話
      for (final key in keysToRemove) {
        html.window.localStorage.remove(key);
      }
      
      if (keysToRemove.isNotEmpty) {
        print('🧹 已清理 ${keysToRemove.length} 個過期會話');
      }
    } catch (e) {
      print('❌ 清理過期會話失敗: $e');
    }
  }
}
