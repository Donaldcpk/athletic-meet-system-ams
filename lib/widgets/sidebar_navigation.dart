/// 側邊欄導航組件
/// 提供系統內各模組的快速導航

import 'package:flutter/material.dart';
import '../utils/app_state.dart';

/// 側邊欄導航
class SidebarNavigation extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const SidebarNavigation({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends State<SidebarNavigation> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 側邊欄
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              border: Border(right: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildNavigationItems()),
                _buildFooter(),
              ],
            ),
          ),
          // 主要內容
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  /// 構建標題區域
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.sports,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            '運動會管理系統',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'v1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 構建導航項目
  Widget _buildNavigationItems() {
    final items = [
      NavigationItem(
        icon: Icons.dashboard,
        title: '系統總覽',
        route: '/',
        description: '系統狀態和快速操作',
      ),
      NavigationItem(
        icon: Icons.people,
        title: '學生管理',
        route: '/student-management',
        description: '學生資料和報名管理',
        badge: _appState.students.length.toString(),
      ),
      NavigationItem(
        icon: Icons.sports,
        title: '項目管理',
        route: '/event-management',
        description: '比賽項目和參與統計',
        badge: _getEventRegistrationCount().toString(),
      ),
      NavigationItem(
        icon: Icons.assignment,
        title: '裁判系統',
        route: '/referee-system',
        description: '成績記錄和計分管理',
      ),
      NavigationItem(
        icon: Icons.leaderboard,
        title: '成績排名',
        route: '/rankings',
        description: '即時排名和統計分析',
      ),
      NavigationItem(
        icon: Icons.description,
        title: '報表管理',
        route: '/reports',
        description: '證書生成和成績匯出',
      ),
      NavigationItem(
        icon: Icons.settings,
        title: '系統設定',
        route: '/settings',
        description: '基本設定和數據備份',
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = widget.currentRoute == item.route;
        final isAvailable = _isRouteAvailable(item.route);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: ListTile(
            leading: Icon(
              item.icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : isAvailable
                      ? Colors.grey[600]
                      : Colors.grey[400],
            ),
            title: Text(
              item.title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : isAvailable
                        ? Colors.black87
                        : Colors.grey[400],
              ),
            ),
            subtitle: Text(
              item.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: item.badge != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[400],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            selected: isSelected,
            selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: isAvailable ? () => _navigateToRoute(item.route) : null,
          ),
        );
      },
    );
  }

  /// 構建底部信息
  Widget _buildFooter() {
    final stats = _appState.getStudentStatistics();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          const Text(
            '系統統計',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('學生', stats['總人數'] ?? 0, Icons.people),
              _buildStatItem('工作人員', stats['工作人員'] ?? 0, Icons.work),
            ],
          ),
          const SizedBox(height: 8),
          if (_appState.hasSampleData) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '包含樣本數據',
                style: TextStyle(fontSize: 10, color: Colors.orange),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  /// 檢查路由是否可用
  bool _isRouteAvailable(String route) {
    switch (route) {
      case '/':
      case '/student-management':
      case '/event-management':
      case '/referee-system':
        return true;
      case '/rankings':
      case '/reports':
        return true;
      case '/settings':
        return false; // 尚未實現
      default:
        return false;
    }
  }

  /// 導航到指定路由
  void _navigateToRoute(String route) {
    if (route == '/') {
      Navigator.pushReplacementNamed(context, '/');
    } else {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  /// 獲取項目報名總數
  int _getEventRegistrationCount() {
    return _appState.students.fold(0, (sum, student) => sum + student.registeredEvents.length);
  }
}

/// 導航項目數據類
class NavigationItem {
  final IconData icon;
  final String title;
  final String route;
  final String description;
  final String? badge;

  const NavigationItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.description,
    this.badge,
  });
} 