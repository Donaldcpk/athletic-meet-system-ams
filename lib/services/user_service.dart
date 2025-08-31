/// 用戶管理服務
/// 處理用戶登入、狀態管理和權限控制

import 'dart:html' as html;
import 'dart:convert';

class UserService {
  static const String _userKey = 'current_user';
  static const String _sessionKey = 'user_session';
  
  static User? _currentUser;
  
  /// 獲取當前用戶
  static User? get currentUser => _currentUser;
  
  /// 檢查是否已登入
  static bool get isLoggedIn => _currentUser != null;
  
  /// 用戶登入
  static Future<bool> login(String username, String role) async {
    if (username.trim().isEmpty) {
      return false;
    }
    
    final user = User(
      username: username.trim(),
      role: role,
      loginTime: DateTime.now(),
      sessionId: _generateSessionId(),
    );
    
    _currentUser = user;
    
    // 保存到本地存儲
    html.window.localStorage[_userKey] = json.encode(user.toJson());
    html.window.localStorage[_sessionKey] = user.sessionId;
    
    return true;
  }
  
  /// 用戶登出
  static void logout() {
    _currentUser = null;
    html.window.localStorage.remove(_userKey);
    html.window.localStorage.remove(_sessionKey);
  }
  
  /// 從本地存儲恢復用戶會話
  static void restoreSession() {
    try {
      final userData = html.window.localStorage[_userKey];
      if (userData != null) {
        final userJson = json.decode(userData) as Map<String, dynamic>;
        _currentUser = User.fromJson(userJson);
        
        // 檢查會話是否過期（24小時）
        final loginTime = _currentUser!.loginTime;
        final now = DateTime.now();
        if (now.difference(loginTime).inHours > 24) {
          logout();
        }
      }
    } catch (e) {
      // 如果恢復失敗，清除無效數據
      logout();
    }
  }
  
  /// 更新用戶最後活動時間
  static void updateLastActivity() {
    if (_currentUser != null) {
      _currentUser = User(
        username: _currentUser!.username,
        role: _currentUser!.role,
        loginTime: _currentUser!.loginTime,
        sessionId: _currentUser!.sessionId,
        lastActivity: DateTime.now(),
      );
      
      html.window.localStorage[_userKey] = json.encode(_currentUser!.toJson());
    }
  }
  
  /// 獲取用戶顯示名稱
  static String getDisplayName() {
    if (_currentUser == null) return '未登入';
    return '${_currentUser!.role} - ${_currentUser!.username}';
  }
  
  /// 生成會話ID
  static String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return '${timestamp.toString().substring(8)}$random';
  }
  
  /// 檢查用戶權限
  static bool hasPermission(String action) {
    if (_currentUser == null) return false;
    
    // 所有登入用戶都有基本權限
    // 可以根據需要擴展角色權限系統
    return true;
  }
}

/// 用戶模型
class User {
  final String username;
  final String role;
  final DateTime loginTime;
  final String sessionId;
  final DateTime? lastActivity;
  
  User({
    required this.username,
    required this.role,
    required this.loginTime,
    required this.sessionId,
    this.lastActivity,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'role': role,
      'loginTime': loginTime.toIso8601String(),
      'sessionId': sessionId,
      'lastActivity': lastActivity?.toIso8601String(),
    };
  }
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] as String,
      role: json['role'] as String,
      loginTime: DateTime.parse(json['loginTime'] as String),
      sessionId: json['sessionId'] as String,
      lastActivity: json['lastActivity'] != null 
          ? DateTime.parse(json['lastActivity'] as String)
          : null,
    );
  }
}

/// 用戶角色定義
class UserRole {
  static const String admin = '系統管理員';
  static const String referee = '裁判員';
  static const String scorer = '計分員';
  static const String viewer = '觀看者';
  
  static List<String> get allRoles => [admin, referee, scorer, viewer];
}
