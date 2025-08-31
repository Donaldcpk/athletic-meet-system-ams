/// 數據管理界面
/// 提供數據持久化、同步狀態、導入導出等功能

import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../models/student.dart';
import '../utils/app_state.dart';
import '../services/storage_service.dart';
import '../services/realtime_sync_service.dart';
import '../services/firebase_service.dart';
import '../widgets/enhanced_sidebar_navigation.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  final AppState _appState = AppState();
  final RealtimeSyncService _syncService = RealtimeSyncService.instance;
  
  Map<String, dynamic> _storageStats = {};
  Map<String, dynamic> _cloudStats = {};
  List<Map<String, dynamic>> _activeSessions = [];
  String _userName = '';
  bool _isInitialized = false;
  bool _isCloudConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeDataManagement();
    _loadStorageStats();
    _loadActiveSessions();
    _loadCloudStats();
  }

  Future<void> _initializeDataManagement() async {
    // 初始化用戶名（可以從設置或彈窗獲取）
    _userName = await _getUserName();
    
    if (!_isInitialized) {
      await _syncService.initialize(_userName);
      _isInitialized = true;
      
      // 添加監聽器
      _syncService.addDataChangeListener(_onDataChange);
      _syncService.addUserActionListener(_onUserAction);
    }
  }

  Future<String> _getUserName() async {
    // 從本地存儲獲取用戶名，如果沒有則提示輸入
    final savedName = html.window.localStorage['athletic_meet_user_name'];
    if (savedName != null && savedName.isNotEmpty) {
      return savedName;
    }
    
    // 提示用戶輸入姓名
    return await _showUserNameDialog() ?? '未知用戶';
  }

  Future<String?> _showUserNameDialog() async {
    String name = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('設置用戶名'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('請輸入您的姓名，這將用於多用戶協作識別：'),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => name = value,
              decoration: const InputDecoration(
                labelText: '您的姓名',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (name.isNotEmpty) {
                html.window.localStorage['athletic_meet_user_name'] = name;
                Navigator.pop(context, name);
              }
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  void _onDataChange(Map<String, dynamic> change) {
    setState(() {
      _loadStorageStats();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${change['from']} 更新了 ${change['type']} 數據'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _onUserAction(String userName, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$userName $action'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _loadStorageStats() {
    setState(() {
      _storageStats = _appState.getStorageStats();
    });
  }

  void _loadActiveSessions() {
    setState(() {
      _activeSessions = _syncService.getActiveSessions();
    });
  }

  Future<void> _loadCloudStats() async {
    try {
      final stats = await FirebaseService.getCloudStats();
      final connected = await FirebaseService.testConnection();
      setState(() {
        _cloudStats = stats;
        _isCloudConnected = connected;
      });
    } catch (e) {
      setState(() {
        _cloudStats = {'error': e.toString()};
        _isCloudConnected = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const EnhancedSidebarNavigation(currentRoute: '/data_management'),
      appBar: AppBar(
        title: const Text('數據管理'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadStorageStats();
              _loadActiveSessions();
              _loadCloudStats();
            },
            tooltip: '刷新數據',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用戶信息卡片
            _buildUserInfoCard(),
            const SizedBox(height: 20),
            
            // 存儲狀態卡片
            _buildStorageStatusCard(),
            const SizedBox(height: 20),
            
            // 雲端狀態卡片
            _buildCloudStatusCard(),
            const SizedBox(height: 20),
            
            // 數據操作卡片
            _buildDataOperationsCard(),
            const SizedBox(height: 20),
            
            // 活躍會話卡片
            _buildActiveSessionsCard(),
            const SizedBox(height: 20),
            
            // 危險操作區域
            _buildDangerZoneCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.white, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '當前用戶',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  _userName.isNotEmpty ? _userName : '載入中...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    _isInitialized ? '✅ 同步已啟用' : '⏳ 初始化中...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showUserNameDialog,
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: '修改用戶名',
          ),
        ],
      ),
    );
  }

  Widget _buildStorageStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.storage, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                '存儲狀態',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_storageStats.isNotEmpty) ...[
            _buildStorageStatRow('學生數量', '${_storageStats['studentsCount']}', Icons.people),
            _buildStorageStatRow('成績記錄', '${_storageStats['scoresCount']}', Icons.score),
            _buildStorageStatRow('決賽名單', '${_storageStats['finalistsCount']}', Icons.list),
            _buildStorageStatRow('三甲名單', '${_storageStats['podiumCount']}', Icons.emoji_events),
            _buildStorageStatRow('最後同步', _storageStats['lastSync'], Icons.sync),
          ] else
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildStorageStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildCloudStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isCloudConnected 
              ? [Colors.green[600]!, Colors.green[400]!]
              : [Colors.orange[600]!, Colors.orange[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isCloudConnected ? Colors.green : Colors.orange).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isCloudConnected ? Icons.cloud_done : Icons.cloud_off,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isCloudConnected ? '🌟 免費雲端已連接' : '📡 設置免費雲端存儲',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _isCloudConnected 
                          ? '數據安全保存在雲端，隨時隨地可存取！'
                          : '點擊下方按鈕設置Firebase，完全免費！',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (_isCloudConnected && _cloudStats.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildCloudStatRow('雲端學生數量', '${_cloudStats['studentsCount']}', Icons.people),
                  _buildCloudStatRow('雲端成績記錄', '${_cloudStats['scoresCount']}', Icons.score),
                  _buildCloudStatRow('最後同步時間', _cloudStats['lastUpdated'], Icons.sync),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isCloudConnected ? _uploadToCloud : _setupFirebase,
                  icon: Icon(_isCloudConnected ? Icons.cloud_upload : Icons.settings),
                  label: Text(_isCloudConnected ? '備份到雲端' : '設置Firebase'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _isCloudConnected ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ),
              if (_isCloudConnected) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _downloadFromCloud,
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('從雲端恢復'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      foregroundColor: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCloudStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDataOperationsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.archive, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                '數據操作',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveData,
                  icon: const Icon(Icons.save),
                  label: const Text('手動保存'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportData,
                  icon: const Icon(Icons.download),
                  label: const Text('匯出數據'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _importData,
              icon: const Icon(Icons.upload),
              label: const Text('導入數據'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups, color: Colors.purple),
              const SizedBox(width: 8),
              const Text(
                '活躍會話',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadActiveSessions,
                icon: const Icon(Icons.refresh),
                tooltip: '刷新會話',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_activeSessions.isEmpty)
            const Center(
              child: Text('目前沒有其他活躍會話'),
            )
          else
            ..._activeSessions.map((session) => _buildSessionItem(session)),
        ],
      ),
    );
  }

  Widget _buildSessionItem(Map<String, dynamic> session) {
    final userName = session['userName'] as String;
    final lastActivity = DateTime.parse(session['lastActivity']);
    final isActive = session['isActive'] ?? true;
    final timeDiff = DateTime.now().difference(lastActivity);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.green[200]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isActive ? Colors.green : Colors.grey,
            radius: 20,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '最後活動：${_formatTimeDiff(timeDiff)}前',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isActive ? '在線' : '離線',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text(
                '危險操作',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '以下操作會永久刪除所有數據，請謹慎使用！',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _clearAllData,
              icon: const Icon(Icons.delete_forever),
              label: const Text('清除所有數據'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeDiff(Duration diff) {
    if (diff.inMinutes < 1) return '不到1分鐘';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分鐘';
    if (diff.inHours < 24) return '${diff.inHours}小時';
    return '${diff.inDays}天';
  }

  Future<void> _saveData() async {
    try {
      await _appState.saveData();
      await _syncService.broadcastUserAction('手動保存了數據');
      _loadStorageStats();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 數據保存成功'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 保存失敗: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportData() async {
    try {
      final jsonData = _appState.exportAllData();
      final fileName = 'athletic_meet_data_${DateTime.now().millisecondsSinceEpoch}.json';
      
      // 創建下載
      final blob = html.Blob([jsonData], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';
      
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      
      await _syncService.broadcastUserAction('匯出了數據');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 數據匯出成功'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 匯出失敗: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importData() async {
    final input = html.FileUploadInputElement()..accept = '.json';
    input.click();

    input.onChange.listen((e) async {
      final files = input.files;
      if (files?.isEmpty ?? true) return;

      final file = files!.first;
      final reader = html.FileReader();

      reader.onLoadEnd.listen((e) async {
        try {
          final jsonData = reader.result as String;
          final success = await _appState.importData(jsonData);
          
          if (success) {
            await _syncService.broadcastDataUpdate('all', 'imported');
            await _syncService.broadcastUserAction('導入了新數據');
            _loadStorageStats();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ 數據導入成功'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            throw Exception('導入數據格式不正確');
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 導入失敗: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });

      reader.readAsText(file);
    });
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 確認刪除'),
        content: const Text('這將永久刪除所有數據，包括學生資料、成績記錄等。\n\n此操作無法復原，您確定要繼續嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('確定刪除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 記錄操作日誌
        await OperationLogService.logOperation(
          OperationType.delete,
          '清除所有系統數據（本地+雲端）',
        );
        
        await _appState.clearAllStorageData();
        await _syncService.broadcastDataUpdate('all', 'cleared');
        await _syncService.broadcastUserAction('清除了所有數據');
        _loadStorageStats();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 所有數據已清除（包括Firebase雲端數據）'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 清除失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setupFirebase() async {
    String firebaseUrl = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud, color: Colors.blue),
            SizedBox(width: 8),
            Text('設置免費Firebase雲端存儲'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('步驟1: 訪問 https://console.firebase.google.com'),
            const Text('步驟2: 創建新項目 (完全免費)'),
            const Text('步驟3: 啟用 Realtime Database'),
            const Text('步驟4: 複製數據庫URL'),
            const SizedBox(height: 16),
            const Text('請貼上您的Firebase Realtime Database URL:'),
            const SizedBox(height: 8),
            TextField(
              onChanged: (value) => firebaseUrl = value,
              decoration: const InputDecoration(
                labelText: 'Firebase URL',
                hintText: 'https://您的項目-default-rtdb.firebaseio.com/',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '💡 提示: Firebase提供每月1GB免費存儲和100,000次操作，足夠運動會使用！',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (firebaseUrl.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('連接'),
          ),
        ],
      ),
    );

    if (confirmed == true && firebaseUrl.isNotEmpty) {
      try {
        FirebaseService.setFirebaseUrl(firebaseUrl);
        final connected = await FirebaseService.testConnection();
        
        setState(() {
          _isCloudConnected = connected;
        });
        
        if (connected) {
          await _loadCloudStats();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('🎉 Firebase雲端連接成功！'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ 連接失敗，請檢查URL是否正確'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 設置失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadToCloud() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('正在備份到雲端...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 10),
        ),
      );

      final success = await FirebaseService.uploadAllData(
        students: _appState.students,
        scores: StorageService.loadScores(),
        finalists: StorageService.loadFinalists(),
        podium: StorageService.loadPodiumResults(),
      );

      if (success) {
        await _loadCloudStats();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.white),
                SizedBox(width: 8),
                Text('✅ 數據已成功備份到雲端！'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('上傳失敗');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 備份失敗: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadFromCloud() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 從雲端恢復數據'),
        content: const Text('這將用雲端數據覆蓋本地所有數據。\n\n您確定要繼續嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('確定恢復', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('正在從雲端恢復數據...'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 10),
          ),
        );

        final cloudData = await FirebaseService.downloadAllData();
        if (cloudData != null) {
          // 恢復學生數據
          final studentsData = cloudData['students'] as List<dynamic>? ?? [];
          final students = studentsData.map((json) => Student.fromJson(json as Map<String, dynamic>)).toList();
          if (students.isNotEmpty) {
            _appState.clearAllStudents();
            _appState.addStudents(students);
          }

          // 恢復其他數據
          final scores = cloudData['scores'] as Map<String, String>;
          if (scores.isNotEmpty) {
            await StorageService.saveScores(scores);
          }

          // 重新加載本地統計
          _loadStorageStats();

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.cloud_download, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('✅ 已恢復 ${students.length} 位學生和 ${scores.length} 條成績！'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('雲端沒有可用數據');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 恢復失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _syncService.removeDataChangeListener(_onDataChange);
      _syncService.removeUserActionListener(_onUserAction);
    }
    super.dispose();
  }
}

