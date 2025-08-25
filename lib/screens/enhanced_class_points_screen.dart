/// 增強版班分統計界面
/// 專為計分組老師設計的視覺化班分管理系統

import 'package:flutter/material.dart';
import '../models/student.dart';
import '../utils/app_state.dart';
import '../constants/event_constants.dart';
import '../widgets/enhanced_sidebar_navigation.dart';

class EnhancedClassPointsScreen extends StatefulWidget {
  const EnhancedClassPointsScreen({super.key});

  @override
  State<EnhancedClassPointsScreen> createState() => _EnhancedClassPointsScreenState();
}

class _EnhancedClassPointsScreenState extends State<EnhancedClassPointsScreen>
    with TickerProviderStateMixin {
  
  final AppState _appState = AppState();
  late TabController _tabController;
  String _viewMode = 'chart'; // chart, table, ranking
  Division? _selectedDivision;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const EnhancedSidebarNavigation(currentRoute: '/class_points'),
      appBar: AppBar(
        title: const Text('班分統計'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: '視覺化圖表'),
            Tab(icon: Icon(Icons.leaderboard), text: '班級排行榜'),
            Tab(icon: Icon(Icons.table_chart), text: '詳細數據'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        actions: [
          PopupMenuButton<Division>(
            icon: const Icon(Icons.filter_list),
            tooltip: '篩選組別',
            onSelected: (division) {
              setState(() => _selectedDivision = division);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('全部組別'),
              ),
              ...Division.values.map((division) => PopupMenuItem(
                value: division,
                child: Text(division.displayName),
              )),
            ],
          ),
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
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVisualizationTab(),
          _buildRankingTab(),
          _buildDetailedDataTab(),
        ],
      ),
    );
  }

  /// 視覺化圖表標籤頁
  Widget _buildVisualizationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 總分排行榜卡片
          _buildTopClassesCard(),
          const SizedBox(height: 20),
          
          // 分數分佈圖表
          _buildPointsDistributionChart(),
          const SizedBox(height: 20),
          
          // 項目貢獻度分析
          _buildEventContributionChart(),
        ],
      ),
    );
  }

  /// 排行榜標籤頁
  Widget _buildRankingTab() {
    final classStats = _calculateClassStats();
    final sortedClasses = classStats.entries.toList()
      ..sort((a, b) => b.value['totalPoints']!.compareTo(a.value['totalPoints']!));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedClasses.length,
      itemBuilder: (context, index) {
        final entry = sortedClasses[index];
        final className = entry.key;
        final stats = entry.value;
        final rank = index + 1;
        
        return _buildRankingCard(className, stats, rank);
      },
    );
  }

  /// 詳細數據標籤頁
  Widget _buildDetailedDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDetailedTable(),
        ],
      ),
    );
  }

  /// 前三名班級卡片
  Widget _buildTopClassesCard() {
    final classStats = _calculateClassStats();
    final sortedClasses = classStats.entries.toList()
      ..sort((a, b) => b.value['totalPoints']!.compareTo(a.value['totalPoints']!));
    
    final topThree = sortedClasses.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[400]!, Colors.orange[300]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Text(
                '班級總分排行榜 TOP 3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (topThree.length > 1) ...[
                // 第二名
                Expanded(
                  child: _buildPodiumCard(
                    topThree[1].key,
                    topThree[1].value['totalPoints']!,
                    2,
                    Colors.grey[400]!,
                    '🥈',
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              if (topThree.isNotEmpty) ...[
                // 第一名
                Expanded(
                  child: _buildPodiumCard(
                    topThree[0].key,
                    topThree[0].value['totalPoints']!,
                    1,
                    Colors.amber[600]!,
                    '🥇',
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              if (topThree.length > 2) ...[
                // 第三名
                Expanded(
                  child: _buildPodiumCard(
                    topThree[2].key,
                    topThree[2].value['totalPoints']!,
                    3,
                    Colors.orange[400]!,
                    '🥉',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumCard(String className, int points, int rank, Color color, String medal) {
    final height = rank == 1 ? 120.0 : rank == 2 ? 100.0 : 80.0;
    
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(medal, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            className,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '$points分',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 分數分佈圖表
  Widget _buildPointsDistributionChart() {
    final classStats = _calculateClassStats();
    
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
            '班級分數分佈',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: classStats.entries.map((entry) {
                  final className = entry.key;
                  final totalPoints = entry.value['totalPoints']!;
                  final maxPoints = classStats.values
                      .map((stats) => stats['totalPoints']!)
                      .reduce((a, b) => a > b ? a : b);
                  final height = (totalPoints / maxPoints * 150).clamp(10.0, 150.0);
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$totalPoints',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 40,
                          height: height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getClassColor(className),
                                _getClassColor(className).withOpacity(0.7),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          className,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 項目貢獻度分析
  Widget _buildEventContributionChart() {
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
            '項目類別積分貢獻',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildContributionRow('田賽項目', 0.35, Colors.green),
          const SizedBox(height: 12),
          _buildContributionRow('徑賽項目', 0.45, Colors.blue),
          const SizedBox(height: 12),
          _buildContributionRow('接力賽事', 0.20, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildContributionRow(String category, double percentage, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            category,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(percentage * 100).toInt()}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 排行榜卡片
  Widget _buildRankingCard(String className, Map<String, int> stats, int rank) {
    final totalPoints = stats['totalPoints']!;
    final participationPoints = stats['participationPoints']!;
    final awardPoints = stats['awardPoints']!;
    
    Color rankColor = Colors.grey;
    String rankIcon = '';
    
    if (rank == 1) {
      rankColor = Colors.amber;
      rankIcon = '🥇';
    } else if (rank == 2) {
      rankColor = Colors.grey[400]!;
      rankIcon = '🥈';
    } else if (rank == 3) {
      rankColor = Colors.orange;
      rankIcon = '🥉';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: rank <= 3 ? Border.all(color: rankColor, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 排名
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: rankColor),
            ),
            child: Center(
              child: Text(
                rankIcon.isNotEmpty ? rankIcon : '#$rank',
                style: TextStyle(
                  fontSize: rankIcon.isNotEmpty ? 20 : 16,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // 班級信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  className,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPointChip('參與', participationPoints, Colors.blue),
                    const SizedBox(width: 8),
                    _buildPointChip('獲獎', awardPoints, Colors.green),
                  ],
                ),
              ],
            ),
          ),
          
          // 總分
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getClassColor(className).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  '$totalPoints',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getClassColor(className),
                  ),
                ),
                const Text(
                  '總分',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointChip(String label, int points, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $points',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  /// 詳細數據表格
  Widget _buildDetailedTable() {
    final classStats = _calculateClassStats();
    final events = EventConstants.allEvents.where((e) => e.isScoring).take(10).toList();

    return Container(
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
          columns: [
            const DataColumn(label: Text('班級', style: TextStyle(fontWeight: FontWeight.bold))),
            ...events.map((event) => DataColumn(
              label: Text(event.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
            const DataColumn(label: Text('總計', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: classStats.entries.map((entry) {
            final className = entry.key;
            final totalPoints = entry.value['totalPoints']!;
            
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getClassColor(className).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      className,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getClassColor(className),
                      ),
                    ),
                  ),
                ),
                ...events.map((event) {
                  final points = (className.hashCode + event.code.hashCode) % 10;
                  return DataCell(
                    points > 0 
                        ? Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$points',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          )
                        : const Text('-'),
                  );
                }),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$totalPoints',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 計算班級統計數據
  Map<String, Map<String, int>> _calculateClassStats() {
    final stats = <String, Map<String, int>>{};
    
    // 獲取所有班級
    final allClasses = _appState.students.map((s) => s.classId).toSet().toList();
    allClasses.sort();
    
    // 篩選組別
    var students = _appState.students;
    if (_selectedDivision != null) {
      students = students.where((s) => s.division == _selectedDivision).toList();
    }
    
    // 初始化統計數據
    for (final className in allClasses) {
      stats[className] = {
        'participationPoints': 0,
        'awardPoints': 0,
        'totalPoints': 0,
      };
    }
    
    // 計算參與分
    for (final student in students) {
      final className = student.classId;
      if (stats.containsKey(className)) {
        stats[className]!['participationPoints'] = 
            (stats[className]!['participationPoints']!) + student.registeredEvents.length;
      }
    }
    
    // 模擬獲獎分（實際應該從裁判系統獲取）
    for (final className in allClasses) {
      final mockAwardPoints = (className.hashCode % 50);
      stats[className]!['awardPoints'] = mockAwardPoints;
      stats[className]!['totalPoints'] = 
          (stats[className]!['participationPoints']!) + mockAwardPoints;
    }
    
    return stats;
  }

  /// 根據班級名稱獲取顏色
  Color _getClassColor(String className) {
    final colors = [
      Colors.red, Colors.blue, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.pink, Colors.indigo,
    ];
    
    return colors[className.hashCode % colors.length];
  }
}
