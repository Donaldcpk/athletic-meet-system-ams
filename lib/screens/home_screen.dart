import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/responsive_helper.dart';

/// 運動會管理系統主頁面
/// 提供系統功能入口和概覽資訊
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        elevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 歡迎區域
            SliverToBoxAdapter(
              child: _buildWelcomeSection(),
            ),
            
            // 功能模組區域
            SliverToBoxAdapter(
              child: _buildFunctionModules(),
            ),
            
            // 快速統計區域
            SliverToBoxAdapter(
              child: _buildQuickStats(),
            ),
            
            // 最近活動區域
            SliverToBoxAdapter(
              child: _buildRecentActivities(),
            ),
          ],
        ),
      ),
    );
  }

  /// 建立歡迎區域
  Widget _buildWelcomeSection() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(AppConstants.colorValues['primary']!),
            Color(AppConstants.colorValues['secondary']!),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
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
                Icons.sports,
                size: AppConstants.iconSizeLarge,
                color: Colors.white,
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '歡迎使用',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '運動會管理系統',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            AppConstants.appDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// 建立功能模組區域
  Widget _buildFunctionModules() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
            child: Text(
              '功能模組',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: ResponsiveHelper.getGridColumns(context),
            mainAxisSpacing: ResponsiveHelper.getCardSpacing(context),
            crossAxisSpacing: ResponsiveHelper.getCardSpacing(context),
            childAspectRatio: ResponsiveHelper.isDesktop(context) ? 1.5 : 1.2,
            children: _buildModuleCards(),
          ),
        ],
      ),
    );
  }

  /// 建立模組卡片列表
  List<Widget> _buildModuleCards() {
    final modules = [
      {
        'title': '學生管理',
        'subtitle': '學生資料、班級分組、報名管理',
        'icon': Icons.people,
        'route': '/student_management',
        'color': Color(AppConstants.colorValues['primary']!),
      },
      {
        'title': '項目管理',
        'subtitle': '運動項目設置、報名統計',
        'icon': Icons.sports,
        'route': '/event_management',
        'color': Color(AppConstants.colorValues['secondary']!),
      },
      {
        'title': '裁判系統',
        'subtitle': '成績錄入、排名計算、三甲名單',
        'icon': Icons.scoreboard,
        'route': '/referee_system',
        'color': Color(AppConstants.colorValues['accent']!),
      },
      {
        'title': '成績排名',
        'subtitle': '即時排名、統計分析',
        'icon': Icons.leaderboard,
        'route': '/rankings',
        'color': Colors.purple,
      },
      {
        'title': '報表管理',
        'subtitle': '證書生成、成績匯出',
        'icon': Icons.description,
        'route': '/reports',
        'color': Colors.red,
      },
      {
        'title': '系統設定',
        'subtitle': '基本設定、數據備份',
        'icon': Icons.settings,
        'route': '/settings',
        'color': Colors.grey,
      },
    ];

    return modules.map((module) => _buildModuleCard(module)).toList();
  }

  /// 建立單個模組卡片
  Widget _buildModuleCard(Map<String, dynamic> module) {
    return Card(
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        onTap: () {
          Navigator.pushNamed(context, module['route']);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: (module['color'] as Color? ?? Colors.blue).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  module['icon'] as IconData? ?? Icons.help,
                  size: AppConstants.iconSizeLarge,
                  color: module['color'] as Color? ?? Colors.blue,
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                module['title'] ?? '',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                module['subtitle'] ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 建立快速統計區域
  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '運動會概覽',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          '學生人數',
                          '520',
                          Icons.people,
                          Color(AppConstants.colorValues['primary']!),
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          '比賽項目',
                          '24',
                          Icons.sports_score,
                          Color(AppConstants.colorValues['secondary']!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          '參賽人數',
                          '486',
                          Icons.directions_run,
                          Color(AppConstants.colorValues['accent']!),
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          '已完成項目',
                          '12',
                          Icons.check_circle,
                          Color(AppConstants.colorValues['success']!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 建立統計項目
  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: AppConstants.iconSizeMedium,
            color: color,
          ),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 建立最近活動區域
  Widget _buildRecentActivities() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '最近活動',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              TextButton(
                onPressed: () {
                  // 查看所有活動
                },
                child: const Text('查看全部'),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return _buildActivityItem(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 建立活動項目
  Widget _buildActivityItem(int index) {
    final activities = [
      '男子甲組100米決賽成績已錄入',
      '女子乙組跳高比賽正在進行',
      '4×100米接力報名截止提醒',
    ];

    final icons = [
      Icons.check_circle,
      Icons.sports,
      Icons.notification_important,
    ];

    final colors = [
      Color(AppConstants.colorValues['success']!),
      Color(AppConstants.colorValues['warning']!),
      Color(AppConstants.colorValues['info']!),
    ];

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors[index].withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icons[index],
          size: AppConstants.iconSizeSmall,
          color: colors[index],
        ),
      ),
      title: Text(activities[index]),
      subtitle: Text('${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // 查看活動詳情
      },
    );
  }
}

/// 模組資訊類別
class ModuleInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const ModuleInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
} 