/// 報表管理頁面
/// 提供證書生成和成績匯出功能

import 'package:flutter/material.dart';
import '../utils/app_state.dart';
import '../utils/excel_helper.dart';
import '../widgets/sidebar_navigation.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('報表管理'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: SidebarNavigation(
          currentRoute: '/reports',
          child: Container(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '報表管理',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '生成證書和匯出成績數據',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildReportCard(
                    title: '學生資料匯出',
                    description: '匯出所有學生基本資料',
                    icon: Icons.people,
                    color: Colors.blue,
                    onTap: _exportStudentData,
                  ),
                  _buildReportCard(
                    title: '成績匯出',
                    description: '匯出比賽成績和排名',
                    icon: Icons.assessment,
                    color: Colors.green,
                    onTap: _exportResults,
                  ),
                  _buildReportCard(
                    title: '證書生成',
                    description: '生成獲獎學生證書',
                    icon: Icons.card_membership,
                    color: Colors.orange,
                    onTap: _generateCertificates,
                  ),
                  _buildReportCard(
                    title: '統計報告',
                    description: '班級和個人統計',
                    icon: Icons.bar_chart,
                    color: Colors.purple,
                    onTap: _generateStatistics,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportStudentData() {
    final students = AppState().students;
    if (students.isEmpty) {
      _showMessage('沒有學生資料可匯出');
      return;
    }

    ExcelHelper.generateStudentExport(students);
    _showMessage('學生資料匯出完成');
  }

  void _exportResults() {
    // TODO: 實現成績匯出功能
    _showMessage('成績匯出功能開發中...');
  }

  void _generateCertificates() {
    // TODO: 實現證書生成功能
    _showMessage('證書生成功能開發中...');
  }

  void _generateStatistics() {
    // TODO: 實現統計報告功能
    _showMessage('統計報告功能開發中...');
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
