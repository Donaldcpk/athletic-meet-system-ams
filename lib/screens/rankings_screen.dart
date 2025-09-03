/// 完整的成績排名系統
/// 包含個人排名、班分統計、頒獎名單、頒獎資料

import 'package:flutter/material.dart';
import '../models/student.dart';
import '../utils/app_state.dart';
import '../constants/app_constants.dart';
import '../constants/event_constants.dart';
import '../widgets/common_app_bar.dart';
import '../services/scoring_service.dart';

/// 成績排名頁面
class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AppState _appState = AppState();
  
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Division? _selectedDivision;
  Gender? _selectedGender;
  String _sortBy = 'rank';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 還原為4個標籤頁
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + kTextTabBarHeight),
        child: Column(
          children: [
            CommonAppBar(
              title: '成績排名',
              showBackButton: true,
              backRoute: '/dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportRankings,
            tooltip: '匯出排名',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: '重新計算',
          ),
        ],
            ),
            Container(
              color: Theme.of(context).primaryColor,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                isScrollable: true,
                tabs: const [
                  Tab(icon: Icon(Icons.person), text: '個人排名'),
                  Tab(icon: Icon(Icons.school), text: '班分統計'),
                  Tab(icon: Icon(Icons.emoji_events), text: '頒獎名單'),
                  Tab(icon: Icon(Icons.card_giftcard), text: '頒獎資料'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIndividualRankingView(), // 個人排名
                _buildClassPointsView(), // 班分統計
                _buildAwardListView(), // 頒獎名單
                _buildAwardDataView(), // 頒獎資料
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 篩選欄
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          Row(
        children: [
          Expanded(
                flex: 3,
            child: TextField(
              controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜尋參賽編號、姓名、班級...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
              decoration: const InputDecoration(
                    labelText: '排序依據',
                border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'rank', child: Text('排名')),
                    DropdownMenuItem(value: 'name', child: Text('姓名')),
                    DropdownMenuItem(value: 'class', child: Text('班級')),
                    DropdownMenuItem(value: 'points', child: Text('積分')),
                  ],
                  onChanged: (value) {
                    setState(() => _sortBy = value ?? 'rank');
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() => _sortAscending = !_sortAscending);
                },
                icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                tooltip: _sortAscending ? '升序' : '降序',
              ),
            ],
          ),
          const SizedBox(width: 12),
          Row(
            children: [
          Expanded(
            child: DropdownButtonFormField<Division>(
              value: _selectedDivision,
              decoration: const InputDecoration(
                    labelText: '組別篩選',
                border: OutlineInputBorder(),
                  ),
                  items: Division.values.map((division) {
                    return DropdownMenuItem(
                  value: division,
                  child: Text(division.displayName),
                    );
                  }).toList(),
              onChanged: (value) {
                    setState(() => _selectedDivision = value);
              },
            ),
          ),
              const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<Gender>(
              value: _selectedGender,
              decoration: const InputDecoration(
                    labelText: '性別篩選',
                border: OutlineInputBorder(),
                  ),
                  items: [Gender.male, Gender.female].map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender.displayName),
                    );
                  }).toList(),
              onChanged: (value) {
                    setState(() => _selectedGender = value);
              },
            ),
          ),
              const SizedBox(width: 12),
              ElevatedButton(
            onPressed: _clearFilters,
                child: const Text('清除篩選'),
              ),
            ],
          ),
        ],
      ),
    );
  }



  /// 個人排名界面
  Widget _buildIndividualRankingView() {
    final rankings = _calculateIndividualRankings(_getFilteredStudents());

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
      children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.leaderboard, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '個人總排名 - 共 ${rankings.length} 位參賽者',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
              itemCount: rankings.length,
            itemBuilder: (context, index) {
                return _buildStudentRankingCard(rankings[index], index + 1);
            },
          ),
        ),
      ],
      ),
    );
  }



  /// 班分統計界面（參考圖片的彩色表格）
  Widget _buildClassPointsView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.school, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  '班分統計表',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: _buildClassPointsTable(),
            ),
          ),
        ],
      ),
    );
  }

  /// 完整的頒獎名單界面
  Widget _buildAwardListView() {
    return Container(
          padding: const EdgeInsets.all(16),
      child: Column(
            children: [
          // 標題和統計概覽
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      '頒獎名單',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '生成時間：${DateTime.now().toString().substring(0, 16)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
                    _buildAwardStat('個人項目', '${_getIndividualEventCount()}', Colors.blue),
                    _buildAwardStat('接力項目', '${_getRelayEventCount()}', Colors.green),
                    _buildAwardStat('總獎項', '${_getTotalAwardsCount()}', Colors.orange),
                    _buildAwardStat('獲獎人次', '${_getWinnerCount()}', Colors.purple),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 頒獎名單表格
          Expanded(
            child: _buildCompleteAwardListTable(),
          ),
        ],
      ),
    );
  }

  /// 構建獎項統計卡片
  Widget _buildAwardStat(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
        ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 獲取個人項目數量
  int _getIndividualEventCount() {
    return 12; // 假設有12個個人項目
  }

  /// 獲取接力項目數量
  int _getRelayEventCount() {
    return 6; // 假設有6個接力項目
  }

  /// 獲取總獎項數量
  int _getTotalAwardsCount() {
    return (_getIndividualEventCount() + _getRelayEventCount()) * 3; // 每個項目3個獎項
  }

  /// 獲取獲獎人次
  int _getWinnerCount() {
    // TODO: 從實際三甲名單計算
    return _getTotalAwardsCount();
  }

  /// 完整的頒獎名單表格
  Widget _buildCompleteAwardListTable() {
    final awards = _generateCompleteAwardList();
    
    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 12,
        headingRowHeight: 40,
        dataRowHeight: 50,
        columns: const [
          DataColumn(label: Text('項目', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('名次', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('參賽編號', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('姓名', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('班別', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('成績', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('獎項', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('狀態', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: awards.map((award) {
          return DataRow(
            color: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                if (award['rank'] == 1) return Colors.amber[50];
                if (award['rank'] == 2) return Colors.grey[100];
                if (award['rank'] == 3) return Colors.orange[50];
                return null;
              },
            ),
            cells: [
              DataCell(Text(award['eventName'] ?? '')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
                    color: _getRankColor(award['rank']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_getRankEmoji(award['rank'])} ${award['rank']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                  ),
          ),
        ),
            ),
              DataCell(Text(award['studentCode'] ?? '')),
              DataCell(Text(award['studentName'] ?? '')),
              DataCell(Text(award['classId'] ?? '')),
              DataCell(
            Text(
                  award['result'] ?? '--',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getAwardType(award['rank']),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              DataCell(
                Icon(
                  award['completed'] ? Icons.check_circle : Icons.pending,
                  color: award['completed'] ? Colors.green : Colors.orange,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// 生成完整的頒獎名單
  List<Map<String, dynamic>> _generateCompleteAwardList() {
    final awards = <Map<String, dynamic>>[];
    
    // TODO: 從實際的三甲名單數據生成
    // 這裡先生成示例數據
    final sampleEvents = ['男甲100m', '女甲100m', '男乙跳遠', '女乙跳遠', '4x100m接力'];
    for (int i = 0; i < sampleEvents.length; i++) {
      final eventName = sampleEvents[i];
      for (int rank = 1; rank <= 3; rank++) {
        awards.add({
          'eventName': eventName,
          'rank': rank,
          'studentCode': 'S${rank}A${String.fromCharCode(48 + rank)}',
          'studentName': '示例學生$rank',
          'classId': '${rank}A',
          'result': rank == 1 ? '12.34' : (rank == 2 ? '12.56' : '12.78'),
          'completed': rank <= 2,
        });
      }
    }
    
    return awards;
  }

  /// 獲取排名顏色
  Color _getRankColor(int rank) {
    switch (rank) {
      case 1: return Colors.amber[600]!;
      case 2: return Colors.grey[600]!;
      case 3: return Colors.orange[600]!;
      default: return Colors.blue[600]!;
    }
  }

  /// 獲取排名表情符號
  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '';
    }
  }

  /// 獲取獎項類型
  String _getAwardType(int rank) {
    switch (rank) {
      case 1: return '金獎';
      case 2: return '銀獎';
      case 3: return '銅獎';
      default: return '參與獎';
    }
  }

  /// 頒獎資料界面
  Widget _buildAwardDataView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.card_giftcard, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  '頒獎資料統計',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildAwardDataSummary(),
          ),
        ],
      ),
    );
  }

  /// 學生排名卡片
  Widget _buildStudentRankingCard(StudentRanking ranking, int rank) {
    final student = ranking.student;
    Color rankColor = Colors.grey;
    String rankText = '$rank';
    String rankIcon = '';

    if (rank == 1) {
      rankColor = Colors.amber;
      rankIcon = '🥇';
    } else if (rank == 2) {
      rankColor = Colors.grey;
      rankIcon = '🥈';
    } else if (rank == 3) {
      rankColor = Colors.orange;
      rankIcon = '🥉';
    }

    return Card(
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: rankColor.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: rankColor, width: 2),
          ),
          child: Center(
            child: Text(
              rankIcon.isNotEmpty ? rankIcon : rankText,
              style: TextStyle(
                fontSize: rankIcon.isNotEmpty ? 24 : 16,
                fontWeight: FontWeight.bold,
                color: rankColor,
                  ),
          ),
        ),
        ),
        title: Row(
          children: [
            Text(
              student.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                student.studentCode,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            if (student.isStaff) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '工作人員',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('班級：${student.classId} | 組別：${student.division.displayName}'),
            const SizedBox(height: 8),
            _buildScoreBreakdown(ranking),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${ranking.totalPoints}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              '總分',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// 班分統計表格（彩色版本，參考圖片）
  Widget _buildClassPointsTable() {
    final classStats = _calculateClassPoints();
    final events = EventConstants.allEvents.where((e) => e.isScoring).toList();
    final classes = _getAllClasses();

    return Column(
      children: [
        // 參與分表格
        _buildPointsTable('參與分統計', classStats['participation']!, events, classes, Colors.blue),
        const SizedBox(height: 24),
        // 決賽分表格
        _buildPointsTable('決賽分統計', classStats['awards']!, events, classes, Colors.green),
        const SizedBox(height: 24),
        // 總分表格
        _buildPointsTable('總分統計', classStats['total']!, events, classes, Colors.purple),
      ],
    );
  }

  /// 建構積分表格
  Widget _buildPointsTable(String title, Map<String, Map<String, int>> data, 
      List<EventInfo> events, List<String> classes, Color themeColor) {
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: themeColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 表格標題
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
      child: Row(
        children: [
                Icon(Icons.table_chart, color: themeColor),
          const SizedBox(width: 8),
                Text(
                  title,
              style: TextStyle(
                    fontSize: 16,
                fontWeight: FontWeight.bold,
                    color: themeColor,
            ),
          ),
        ],
      ),
          ),
          
          // 表格內容
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 12,
              headingRowColor: MaterialStateProperty.all(themeColor.withOpacity(0.1)),
              columns: [
                const DataColumn(
                  label: Text('項目', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const DataColumn(
                  label: Text('分數別', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...classes.map((className) => DataColumn(
                  label: Text(className, style: const TextStyle(fontWeight: FontWeight.bold)),
                )),
                const DataColumn(
                  label: Text('小計', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
              rows: events.map((event) {
                final eventData = data[event.code] ?? {};
                final total = eventData.values.fold(0, (sum, value) => sum + value);
                
                return DataRow(
                  cells: [
                    DataCell(Text(event.name)),
                    DataCell(Text(title.contains('參與') ? '參與分' : 
                                 title.contains('決賽') ? '決賽分' : '總分')),
                    ...classes.map((className) {
                      final points = eventData[className] ?? 0;
                      return DataCell(
          Container(
                          padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                            color: points > 0 ? themeColor.withOpacity(0.1) : null,
                            borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
                            points.toString(),
              style: TextStyle(
                              fontWeight: points > 0 ? FontWeight.bold : FontWeight.normal,
                              color: points > 0 ? themeColor : Colors.black,
                            ),
        ),
      ),
    );
                    }),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          total.toString(),
                          style: TextStyle(
                fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
              ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 頒獎名單表格
  Widget _buildAwardListTable() {
    final awardList = _generateAwardList();
    
    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 20,
        headingRowColor: MaterialStateProperty.all(Colors.amber[100]),
        columns: const [
          DataColumn(label: Text('組別', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('項目', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('名次', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('參賽編號', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('姓名', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('成績', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('已確認', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('時間', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('已列印', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: awardList.map((award) {
          return DataRow(
            cells: [
              DataCell(Text(award['division']!)),
              DataCell(Text(award['event']!)),
              DataCell(
            Row(
              children: [
                    Text(award['rank']!),
                    const SizedBox(width: 4),
                    Text(award['medal']!),
                  ],
                ),
              ),
              DataCell(Text(award['studentCode']!)),
              DataCell(Text(award['name']!)),
              DataCell(Text(award['result']!)),
              DataCell(
                Icon(
                  award['confirmed'] == 'true' ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: award['confirmed'] == 'true' ? Colors.green : Colors.grey,
                ),
              ),
              DataCell(Text(award['time']!)),
              DataCell(
                Icon(
                  award['printed'] == 'true' ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: award['printed'] == 'true' ? Colors.green : Colors.grey,
              ),
            ),
          ],
          );
        }).toList(),
      ),
    );
  }

  /// 頒獎資料統計
  Widget _buildAwardDataSummary() {
    final stats = _calculateAwardStats();
    
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard('總獎項數', '${stats['totalAwards']}', Colors.amber, Icons.emoji_events),
        _buildStatCard('金牌數量', '${stats['goldMedals']}', Colors.yellow[700]!, Icons.looks_one),
        _buildStatCard('銀牌數量', '${stats['silverMedals']}', Colors.grey[600]!, Icons.looks_two),
        _buildStatCard('銅牌數量', '${stats['bronzeMedals']}', Colors.orange[700]!, Icons.looks_3),
        _buildStatCard('已確認獎項', '${stats['confirmedAwards']}', Colors.green, Icons.verified),
        _buildStatCard('待確認獎項', '${stats['pendingAwards']}', Colors.red, Icons.pending),
        _buildStatCard('已列印證書', '${stats['printedCertificates']}', Colors.blue, Icons.print),
        _buildStatCard('待列印證書', '${stats['pendingPrints']}', Colors.purple, Icons.print_disabled),
      ],
    );
  }

  /// 統計卡片
  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
          Text(
            value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
          ),
            ),
            const SizedBox(height: 8),
          Text(
            title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 得分明細
  Widget _buildScoreBreakdown(StudentRanking ranking) {
    return Wrap(
      spacing: 8,
          children: [
        _buildScoreChip('參與分', ranking.participationPoints, Colors.blue),
        _buildScoreChip('名次分', ranking.awardPoints, Colors.green),
        if (ranking.student.isStaff)
          _buildScoreChip('工作分', AppConstants.staffBonus, Colors.orange),
        if (ranking.recordBonus > 0)
          _buildScoreChip('破紀錄', ranking.recordBonus, Colors.amber),
      ],
    );
  }

  Widget _buildScoreChip(String label, int points, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
                  child: Text(
        '$label +$points',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// 計算個人排名
  List<StudentRanking> _calculateIndividualRankings(List<Student> students) {
    final rankings = students.map((student) {
      // 🔥 使用ScoringService的真實積分數據
      final studentScores = ScoringService.getStudentAllScores(student.id);
      
      // 計算各類積分
      int participationPoints = 0;
      int awardPoints = 0;
      int recordBonus = 0;
      
      for (final score in studentScores) {
        participationPoints += score.participationPoints;
        awardPoints += score.awardPoints;
        recordBonus += score.recordBonus;
      }
      
      // 工作人員獎勵分
      final staffBonus = student.isStaff ? AppConstants.staffBonus : 0;
      
      return StudentRanking(
        student: student,
        participationPoints: participationPoints,
        awardPoints: awardPoints,
        recordBonus: recordBonus,
        totalPoints: participationPoints + awardPoints + recordBonus + staffBonus,
      );
    }).toList();
    
    // 排序
    rankings.sort((a, b) {
      switch (_sortBy) {
        case 'name':
          final result = a.student.name.compareTo(b.student.name);
          return _sortAscending ? result : -result;
        case 'class':
          final result = a.student.classId.compareTo(b.student.classId);
          return _sortAscending ? result : -result;
        case 'points':
          final result = a.totalPoints.compareTo(b.totalPoints);
          return _sortAscending ? result : -result;
        case 'rank':
        default:
          return b.totalPoints.compareTo(a.totalPoints); // 總分排名，高分在前
      }
    });
    
    return rankings;
  }

  /// 計算班分統計
  Map<String, Map<String, Map<String, int>>> _calculateClassPoints() {
    final participationPoints = <String, Map<String, int>>{};
    final awardPoints = <String, Map<String, int>>{};
    final totalPoints = <String, Map<String, int>>{};
    
    // 獲取所有項目和班級
    final events = EventConstants.allEvents.where((e) => e.isScoring).toList();
    final classes = _getAllClasses();
    
    // 初始化數據結構
    for (final event in events) {
      participationPoints[event.code] = {};
      awardPoints[event.code] = {};
      totalPoints[event.code] = {};
      
      for (final className in classes) {
        participationPoints[event.code]![className] = 0;
        awardPoints[event.code]![className] = 0;
        totalPoints[event.code]![className] = 0;
      }
    }
    
    // 🔥 使用ScoringService的真實積分數據
    for (final student in _appState.students) {
      final studentScores = ScoringService.getStudentAllScores(student.id);
      
      for (final score in studentScores) {
        final eventCode = score.eventCode;
        
        if (participationPoints.containsKey(eventCode)) {
          // 累加參與分
          participationPoints[eventCode]![student.classId] = 
              (participationPoints[eventCode]![student.classId] ?? 0) + score.participationPoints;
          
          // 累加名次分
          awardPoints[eventCode]![student.classId] = 
              (awardPoints[eventCode]![student.classId] ?? 0) + score.awardPoints + score.recordBonus;
        }
      }
    }
    
    // 計算總分
    for (final event in events) {
      for (final className in classes) {
        totalPoints[event.code]![className] = 
            (participationPoints[event.code]![className] ?? 0) +
            (awardPoints[event.code]![className] ?? 0);
      }
    }
    
    return {
      'participation': participationPoints,
      'awards': awardPoints,
      'total': totalPoints,
    };
  }

  /// 生成頒獎名單
  List<Map<String, String>> _generateAwardList() {
    // TODO: 從裁判系統獲取實際獲獎數據
    // 暫時使用模擬數據
    return [
      {
        'division': '男甲',
        'event': '800m',
        'rank': '1',
        'medal': '🥇',
        'studentCode': '5A01',
        'name': '陳大明',
        'result': '2:15.34',
        'confirmed': 'true',
        'time': '2024年10月4日 下午12:53:49',
        'printed': 'true',
      },
      {
        'division': '男甲',
        'event': '800m',
        'rank': '2',
        'medal': '🥈',
        'studentCode': '5B02',
        'name': '李小華',
        'result': '2:16.78',
        'confirmed': 'true',
        'time': '2024年10月4日 下午12:53:50',
        'printed': 'false',
      },
      // 更多模擬數據...
    ];
  }

  /// 計算頒獎統計
  Map<String, int> _calculateAwardStats() {
    final awardList = _generateAwardList();
    
    return {
      'totalAwards': awardList.length,
      'goldMedals': awardList.where((a) => a['rank'] == '1').length,
      'silverMedals': awardList.where((a) => a['rank'] == '2').length,
      'bronzeMedals': awardList.where((a) => a['rank'] == '3').length,
      'confirmedAwards': awardList.where((a) => a['confirmed'] == 'true').length,
      'pendingAwards': awardList.where((a) => a['confirmed'] == 'false').length,
      'printedCertificates': awardList.where((a) => a['printed'] == 'true').length,
      'pendingPrints': awardList.where((a) => a['printed'] == 'false').length,
    };
  }

  /// 獲取所有班級
  List<String> _getAllClasses() {
    final classes = _appState.students.map((s) => s.classId).toSet().toList();
    classes.sort();
    return classes;
  }

  /// 獲取篩選後的學生
  List<Student> _getFilteredStudents() {
    var students = _appState.students;
    
    // 按組別篩選
    if (_selectedDivision != null) {
      students = students.where((s) => s.division == _selectedDivision).toList();
    }
    
    // 按性別篩選
    if (_selectedGender != null) {
      students = students.where((s) => s.gender == _selectedGender).toList();
    }
    
    // 按搜尋關鍵字篩選
    if (_searchQuery.isNotEmpty) {
      students = students.where((s) =>
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.studentCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.classId.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    
    return students;
  }

  void _clearFilters() {
    setState(() {
      _selectedDivision = null;
      _selectedGender = null;
      _searchController.clear();
    });
  }

  void _refreshData() {
    setState(() {
      // 重新計算所有數據
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('數據已重新計算')),
    );
  }

  void _exportRankings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('匯出功能開發中...')),
    );
  }
}

/// 學生排名
class StudentRanking {
  final Student student;
  final int participationPoints;
  final int awardPoints;
  final int recordBonus;
  final int totalPoints;

  const StudentRanking({
    required this.student,
    required this.participationPoints,
    required this.awardPoints,
    required this.recordBonus,
    required this.totalPoints,
  });
} 