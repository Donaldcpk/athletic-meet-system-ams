/// 運動會儀表板 - 為舉辦人和計分組老師設計
/// 提供一目了然的關鍵信息和快速操作

import 'package:flutter/material.dart';
import '../utils/app_state.dart';
import '../constants/event_constants.dart';
import '../constants/app_constants.dart';
import '../widgets/enhanced_sidebar_navigation.dart';
import '../services/operation_log_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const EnhancedSidebarNavigation(currentRoute: '/dashboard'),
      appBar: AppBar(
        title: const Text('運動會儀表板'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('數據已更新')),
              );
            },
            tooltip: '刷新數據',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: 打開設置頁面
            },
            tooltip: '系統設置',
          ),
          // 🧪 測試功能按鈕
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.red[600],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.yellow, width: 2),
            ),
            child: IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/test_features');
              },
              tooltip: '🧪 測試所有功能',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 運動會狀態概覽
            _buildMeetStatusCard(),
            const SizedBox(height: 20),
            
            // 關鍵數據卡片
            _buildKeyMetricsRow(),
            const SizedBox(height: 20),
            
            // 進度追蹤
            _buildProgressSection(),
            const SizedBox(height: 20),
            
            // 快速操作面板
            _buildQuickActionsPanel(),
            const SizedBox(height: 20),
            
            // 最新動態
            _buildRecentActivities(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showQuickEntryDialog();
        },
        icon: const Icon(Icons.add_circle),
        label: const Text('快速錄入'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 運動會狀態概覽卡片
  Widget _buildMeetStatusCard() {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sports, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              const Text(
                '香港中學運動會 2024',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '進行中',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatusInfo('開始時間', '08:00', Icons.schedule),
              const SizedBox(width: 24),
              _buildStatusInfo('已完成項目', '12/24', Icons.check_circle),
              const SizedBox(width: 24),
              _buildStatusInfo('參賽人數', '${_appState.students.length}', Icons.people),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 關鍵數據卡片行
  Widget _buildKeyMetricsRow() {
    final totalStudents = _appState.students.length;
    final totalEvents = EventConstants.allEvents.where((e) => e.isScoring).length;
    final staffCount = _appState.students.where((s) => s.isStaff).length;
    final registrations = _appState.students.fold(0, (sum, s) => sum + s.registeredEvents.length);

    return Row(
      children: [
        Expanded(child: _buildMetricCard('參賽者', '$totalStudents', '人', Icons.person, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('比賽項目', '$totalEvents', '項', Icons.emoji_events, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('工作人員', '$staffCount', '人', Icons.work, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('總報名', '$registrations', '次', Icons.assignment, Colors.purple)),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 進度追蹤區塊
  Widget _buildProgressSection() {
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
          const Text(
            '比賽進度',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildProgressItem('田賽項目', 0.75, '6/8', Colors.green),
          const SizedBox(height: 12),
          _buildProgressItem('徑賽項目', 0.45, '5/11', Colors.orange),
          const SizedBox(height: 12),
          _buildProgressItem('接力賽事', 0.25, '1/4', Colors.blue),
          const SizedBox(height: 12),
          _buildProgressItem('成績確認', 0.60, '12/20', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String title, double progress, String detail, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(detail, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  /// 快速操作面板
  Widget _buildQuickActionsPanel() {
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
          const Text(
            '快速操作',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildQuickActionCard('錄入成績', Icons.edit, Colors.blue, () {
                Navigator.pushNamed(context, '/referee');
              }),
              _buildQuickActionCard('個人及班別成績統計', Icons.analytics, Colors.green, () {
                Navigator.pushNamed(context, '/rankings');
              }),
              _buildQuickActionCard('頒獎名單', Icons.emoji_events, Colors.purple, () {
                Navigator.pushNamed(context, '/rankings');
              }),
              _buildQuickActionCard('數據管理', Icons.cloud_sync, Colors.teal, () {
                Navigator.pushNamed(context, '/data_management');
              }),
              _buildQuickActionCard('列印證書', Icons.print, Colors.indigo, () {
                _printCertificates();
              }),
              _buildQuickActionCard('備份數據', Icons.backup, Colors.brown, () {
                _backupData();
              }),
              _buildQuickActionCard('系統設置', Icons.settings, Colors.grey, () {
                _openSettings();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 最新動態
  Widget _buildRecentActivities() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '最新動態',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('查看全部'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildRecentLogItems(),
        ],
      ),
    );
  }

  /// 構建真實的操作日誌項目
  List<Widget> _buildRecentLogItems() {
    final recentLogs = OperationLogService.getLogs(limit: 4);
    
    if (recentLogs.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.history, color: Colors.grey[400], size: 32),
                const SizedBox(height: 8),
                Text(
                  '暫無操作記錄',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    
    return recentLogs.map((log) {
      return _buildActivityItem(
        log.description,
        log.timeDisplay,
        _getLogIcon(log.type),
        _getLogColor(log.type),
      );
    }).toList();
  }
  
  /// 獲取操作類型圖標
  IconData _getLogIcon(OperationType type) {
    switch (type) {
      case OperationType.create:
        return Icons.add_circle;
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
  
  /// 獲取操作類型顏色
  Color _getLogColor(OperationType type) {
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

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 快速錄入對話框
  void _showQuickEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('快速錄入'),
        content: const Text('選擇您要錄入的內容類型：'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/referee');
            },
            child: const Text('錄入成績'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/students');
            },
            child: const Text('新增學生'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('數據匯出功能開發中...')),
    );
  }

  void _printCertificates() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('證書列印功能開發中...')),
    );
  }

  void _backupData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('數據備份功能開發中...')),
    );
  }

  void _openSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('系統設置功能開發中...')),
    );
  }
}
