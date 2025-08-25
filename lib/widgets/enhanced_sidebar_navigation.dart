/// 增強版側邊欄導航
/// 為運動會管理人員設計的直觀導航界面

import 'package:flutter/material.dart';

class EnhancedSidebarNavigation extends StatelessWidget {
  final String currentRoute;

  const EnhancedSidebarNavigation({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavSection('主要功能', [
                  _buildNavItem(
                    context,
                    '儀表板',
                    Icons.dashboard,
                    '/dashboard',
                    '運動會概覽和快速操作',
                    Colors.blue,
                  ),
                  _buildNavItem(
                    context,
                    '參賽者管理',
                    Icons.people,
                    '/students',
                    '學生報名和資料管理',
                    Colors.green,
                  ),
                  _buildNavItem(
                    context,
                    '裁判系統',
                    Icons.assignment_turned_in,
                    '/referee',
                    '成績錄入和比賽管理',
                    Colors.orange,
                  ),
                ]),
                const Divider(),
                _buildNavSection('成績統計', [
                  _buildNavItem(
                    context,
                    '個人排名',
                    Icons.person,
                    '/rankings',
                    '個人成績排行榜',
                    Colors.purple,
                  ),
                  _buildNavItem(
                    context,
                    '班分統計',
                    Icons.bar_chart,
                    '/class_points',
                    '班級積分統計分析',
                    Colors.teal,
                  ),
                  _buildNavItem(
                    context,
                    '頒獎管理',
                    Icons.emoji_events,
                    '/rankings',
                    '獎項和證書管理',
                    Colors.amber,
                  ),
                ]),
                const Divider(),
                _buildNavSection('系統管理', [
                  _buildNavItem(
                    context,
                    '數據管理',
                    Icons.cloud_sync,
                    '/data_management',
                    '數據同步、備份和導入導出',
                    Colors.teal,
                  ),
                  _buildNavItem(
                    context,
                    '項目管理',
                    Icons.sports,
                    '/event_management',
                    '比賽項目設置',
                    Colors.indigo,
                  ),
                  _buildNavItem(
                    context,
                    '報表中心',
                    Icons.assessment,
                    '/reports',
                    '數據匯出和報表',
                    Colors.pink,
                  ),
                ]),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.sports,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  '香港中學運動會',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '管理系統',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(
                    '2024 運動會',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    String description,
    Color color,
  ) {
    final isSelected = currentRoute == route;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : color,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? color : Colors.black87,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          if (currentRoute != route) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
        trailing: isSelected
            ? Icon(Icons.check_circle, color: color, size: 20)
            : null,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.help_outline, color: Colors.red, size: 20),
            ),
            title: const Text(
              '技術支援',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text(
              '遇到問題？聯繫技術團隊',
              style: TextStyle(fontSize: 11),
            ),
            onTap: () {
              _showSupportDialog(context);
            },
          ),
          const SizedBox(height: 8),
          Text(
            '版本 1.0.0 | 2024年運動會專用',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: Colors.blue),
            SizedBox(width: 8),
            Text('技術支援'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('如遇到系統問題，請聯繫：'),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.email, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text('support@athletics.edu.hk'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text('2123-4567'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text('服務時間：08:00-18:00'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
