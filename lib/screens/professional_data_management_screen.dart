/// 專業數據管理界面
/// 包含操作日誌、回溯功能、導入匯出等企業級功能

import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../services/user_service.dart';
import '../services/operation_log_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_state.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/enhanced_sidebar_navigation.dart';

class ProfessionalDataManagementScreen extends StatefulWidget {
  const ProfessionalDataManagementScreen({Key? key}) : super(key: key);

  @override
  State<ProfessionalDataManagementScreen> createState() => _ProfessionalDataManagementScreenState();
}

class _ProfessionalDataManagementScreenState extends State<ProfessionalDataManagementScreen> {
  final AppState _appState = AppState();
  bool _isFirebaseConnected = false;
  String _firebaseUrl = '';
  List<OperationLog> _recentLogs = [];
  Map<String, int> _todayStats = {};
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _firebaseUrl = FirebaseService.getFirebaseUrl();
      _recentLogs = OperationLogService.getLogs(limit: 20);
      _todayStats = OperationLogService.getTodayStats();
    });
    
    // 檢查Firebase連接
    _checkFirebaseConnection();
  }

  Future<void> _checkFirebaseConnection() async {
    try {
      final connected = await FirebaseService.testConnection();
      setState(() {
        _isFirebaseConnected = connected;
      });
    } catch (e) {
      setState(() {
        _isFirebaseConnected = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ExtendedAppBar(
        title: '數據管理中心',
        subtitle: '操作日誌 • 數據管理 • 回溯功能',
        onRefresh: _refreshLogs,
      ),
      drawer: const EnhancedSidebarNavigation(
        currentRoute: '/data_management',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用戶信息卡片
            _buildUserInfoCard(),
            const SizedBox(height: 20),
            
            // Firebase連接狀態
            _buildFirebaseStatusCard(),
            const SizedBox(height: 20),
            
            // 今日統計
            _buildTodayStatsCard(),
            const SizedBox(height: 20),
            
            // 數據操作區域
            _buildDataOperationsCard(),
            const SizedBox(height: 20),
            
            // 操作日誌
            _buildOperationLogsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final user = UserService.currentUser;
    if (user == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user.role,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '會話ID: ${user.sessionId}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('登出'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirebaseStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isFirebaseConnected 
              ? [Colors.green[600]!, Colors.green[400]!]
              : [Colors.orange[600]!, Colors.orange[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isFirebaseConnected ? Colors.green : Colors.orange).withOpacity(0.3),
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
                _isFirebaseConnected ? Icons.cloud_done : Icons.cloud_off,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isFirebaseConnected ? 'Firebase雲端已連接' : 'Firebase未連接',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _isFirebaseConnected 
                          ? '所有操作自動同步到雲端，支援多設備協作'
                          : '點擊下方按鈕連接Firebase雲端數據庫',
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
          if (!_isFirebaseConnected) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _setupFirebase,
              icon: const Icon(Icons.settings),
              label: const Text('連接Firebase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayStatsCard() {
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
              Icon(Icons.analytics, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                '今日操作統計',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: _todayStats.entries.map((entry) {
              return _buildStatChip(entry.key, entry.value);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count) {
    Color color = Colors.blue;
    IconData icon = Icons.info;
    
    switch (label) {
      case '總操作數':
        color = Colors.purple;
        icon = Icons.analytics;
        break;
      case '活躍用戶':
        color = Colors.green;
        icon = Icons.people;
        break;
      case 'create':
        color = Colors.blue;
        icon = Icons.add;
        label = '新增';
        break;
      case 'update':
        color = Colors.orange;
        icon = Icons.edit;
        label = '修改';
        break;
      case 'delete':
        color = Colors.red;
        icon = Icons.delete;
        label = '刪除';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            '$label: $count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
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
              Icon(Icons.import_export, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                '數據操作',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _importData,
                  icon: const Icon(Icons.file_upload),
                  label: const Text('匯入數據'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportData,
                  icon: const Icon(Icons.file_download),
                  label: const Text('匯出數據'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperationLogsCard() {
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
              const Icon(Icons.history, color: Colors.indigo),
              const SizedBox(width: 8),
              const Text(
                '操作日誌',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _refreshLogs,
                icon: const Icon(Icons.refresh),
                label: const Text('刷新'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentLogs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  '暂无操作记录',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentLogs.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final log = _recentLogs[index];
                return _buildLogItem(log);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLogItem(OperationLog log) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getLogTypeColor(log.type).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getLogTypeIcon(log.type),
          color: _getLogTypeColor(log.type),
          size: 20,
        ),
      ),
      title: Text(
        log.description,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${log.userRole} - ${log.userId}'),
          Text(
            log.timeDisplay,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
      trailing: log.oldData != null
          ? IconButton(
              icon: const Icon(Icons.undo),
              tooltip: '回溯此操作',
              onPressed: () => _showRollbackDialog(log),
            )
          : null,
      isThreeLine: true,
    );
  }

  Color _getLogTypeColor(OperationType type) {
    switch (type) {
      case OperationType.create:
        return Colors.green;
      case OperationType.update:
        return Colors.orange;
      case OperationType.delete:
        return Colors.red;
      case OperationType.import:
        return Colors.blue;
      case OperationType.export:
        return Colors.purple;
      case OperationType.login:
        return Colors.teal;
      case OperationType.logout:
        return Colors.grey;
      case OperationType.rollback:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getLogTypeIcon(OperationType type) {
    switch (type) {
      case OperationType.create:
        return Icons.add;
      case OperationType.update:
        return Icons.edit;
      case OperationType.delete:
        return Icons.delete;
      case OperationType.import:
        return Icons.file_upload;
      case OperationType.export:
        return Icons.file_download;
      case OperationType.login:
        return Icons.login;
      case OperationType.logout:
        return Icons.logout;
      case OperationType.rollback:
        return Icons.undo;
      default:
        return Icons.info;
    }
  }

  Future<void> _setupFirebase() async {
    String firebaseUrl = _firebaseUrl;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud, color: Colors.blue),
            SizedBox(width: 8),
            Text('連接Firebase雲端'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) => firebaseUrl = value,
              decoration: const InputDecoration(
                labelText: 'Firebase Realtime Database URL',
                hintText: 'https://您的項目-default-rtdb.firebaseio.com/',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: firebaseUrl),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('連接'),
          ),
        ],
      ),
    );

    if (confirmed == true && firebaseUrl.isNotEmpty) {
      FirebaseService.setFirebaseUrl(firebaseUrl);
      await _checkFirebaseConnection();
      
      await OperationLogService.logOperation(
        OperationType.other,
        '設置Firebase連接',
        newData: {'firebaseUrl': firebaseUrl},
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFirebaseConnected ? '✅ Firebase連接成功！' : '❌ Firebase連接失敗'),
            backgroundColor: _isFirebaseConnected ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    await OperationLogService.logOperation(
      OperationType.import,
      '用戶點擊匯入數據',
    );
    
    // 這裡會觸發文件選擇和數據匯入
    // 具體實現可以調用現有的CSV匯入功能
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
      
      await OperationLogService.logOperation(
        OperationType.export,
        '匯出所有數據到 $fileName',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 數據匯出成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      await OperationLogService.logOperation(
        OperationType.other,
        '數據匯出失敗: $e',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 匯出失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await OperationLogService.logOperation(
      OperationType.logout,
      '用戶登出系統',
    );
    
    UserService.logout();
    
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    }
  }

  Future<void> _refreshLogs() async {
    setState(() {
      _recentLogs = OperationLogService.getLogs(limit: 20);
      _todayStats = OperationLogService.getTodayStats();
    });
  }

  Future<void> _showRollbackDialog(OperationLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('確認回溯操作'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('您確定要回溯以下操作嗎？'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('操作: ${log.description}'),
                  Text('時間: ${log.timeDisplay}'),
                  Text('用戶: ${log.userId}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '⚠️ 回溯操作會恢復到之前的狀態，此操作不可撤銷',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('確認回溯'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await OperationLogService.rollbackOperation(log.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '✅ 回溯成功' : '❌ 回溯失敗'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        
        if (success) {
          _refreshLogs();
        }
      }
    }
  }
}
