/// 統一接力賽管理畫面
/// 支援4x100c、4x400c、4x100s、4x400s統一顯示和即時排名
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../models/student.dart';
import '../models/event.dart';
import '../models/result.dart';
import '../constants/event_constants.dart';
import '../constants/app_constants.dart';
import '../services/scoring_service.dart';
import '../services/storage_service.dart';
import '../services/relay_service.dart';
import '../services/printing_service.dart';
import '../utils/app_state.dart';
import '../widgets/common_app_bar.dart';

class UnifiedRelayScreen extends StatefulWidget {
  final String eventCode; // 4x100c, 4x400c, 4x100s, 4x400s
  
  const UnifiedRelayScreen({
    Key? key,
    required this.eventCode,
  }) : super(key: key);

  @override
  State<UnifiedRelayScreen> createState() => _UnifiedRelayScreenState();
}

class _UnifiedRelayScreenState extends State<UnifiedRelayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AppState _appState;
  final Map<String, Map<String, List<RelayTeamResult>>> _results = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _tabController = TabController(length: 3, vsync: this); // 甲、乙、丙組
    _loadResults();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 載入接力賽成績
  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    
    try {
      // 為每個組別初始化結果
      for (final division in Division.values) {
        _results[division.displayName] = {};
        
        // 獲取該組別的所有班級
        final classes = _getClassesForDivision(division);
        for (final className in classes) {
          _results[division.displayName]![className] = [];
        }
      }
      
      // 載入已有成績
      await _loadExistingResults();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入成績失敗：$e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 獲取組別對應的班級
  List<String> _getClassesForDivision(Division division) {
    final students = _appState.students;
    final classesSet = <String>{};
    
    for (final student in students) {
      if (student.division == division) {
        classesSet.add(student.classId);
      }
    }
    
    final classesList = classesSet.toList();
    classesList.sort(); // 按班級名稱排序
    return classesList;
  }

  /// 載入既有成績
  Future<void> _loadExistingResults() async {
    // 從ScoringService載入既有的接力賽成績
    // 這裡可以擴展以載入儲存的成績數據
  }

  /// 更新班級成績
  Future<void> _updateClassResult(Division division, String className, String result) async {
    try {
      // 使用RelayService更新成績
      await RelayService.updateClassResult(
        eventCode: widget.eventCode,
        className: className,
        division: division,
        result: result,
      );

      // 重新載入結果
      await _loadResults();

      // 顯示成功訊息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ 已更新 ${division.displayName} $className 成績')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 更新失敗：$e')),
        );
      }
    }
  }

  /// 驗證時間格式
  bool _isValidTimeFormat(String time) {
    final regex = RegExp(r'^\d{1,2}:\d{2}\.\d{2}$');
    return regex.hasMatch(time);
  }

  /// 計算即時排名
  Future<void> _calculateRealTimeRanking(Division division) async {
    final divisionResults = _results[division.displayName]!;
    final validResults = <String, RelayTeamResult>{};

    // 收集有效成績
    for (final className in divisionResults.keys) {
      final results = divisionResults[className];
      if (results != null && results.isNotEmpty) {
        validResults[className] = results.first;
      }
    }

    // 按成績排序（時間越短越好）
    final sortedEntries = validResults.entries.toList()
      ..sort((a, b) => _compareTimeResults(a.value.result, b.value.result));

    // 分配排名和積分
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final rank = i + 1;
      final points = _calculateRelayPoints(rank);

      // 更新排名信息
      entry.value.rank = rank;
      entry.value.points = points;

      // 更新到積分系統
      await _updateClassPoints(entry.key, points, rank);
    }

    // 如果有足夠的班級參與，標記冠亞季軍
    if (sortedEntries.length >= 3) {
      _announceTopThree(division, sortedEntries.take(3).toList());
    }
  }

  /// 比較時間成績
  int _compareTimeResults(String time1, String time2) {
    final ms1 = _timeToMilliseconds(time1);
    final ms2 = _timeToMilliseconds(time2);
    return ms1.compareTo(ms2);
  }

  /// 時間轉換為毫秒
  int _timeToMilliseconds(String time) {
    final parts = time.split(':');
    final minutes = int.parse(parts[0]);
    final secondsParts = parts[1].split('.');
    final seconds = int.parse(secondsParts[0]);
    final milliseconds = int.parse(secondsParts[1]);
    return (minutes * 60 * 1000) + (seconds * 1000) + (milliseconds * 10);
  }

  /// 計算接力賽積分
  int _calculateRelayPoints(int rank) {
    return AppConstants.calculatePositionPoints(rank, EventType.relay);
  }

  /// 更新班級積分
  Future<void> _updateClassPoints(String className, int points, int rank) async {
    // 這裡應該與班級積分系統整合
    // 更新班級在該項目的積分和排名
    print('🏆 $className: 第$rank名, +$points分');
  }

  /// 宣佈前三名
  void _announceTopThree(Division division, List<MapEntry<String, RelayTeamResult>> topThree) {
    final winners = topThree.map((e) => '${e.key}(${e.value.result})').join(', ');
    print('🏆 ${division.displayName} ${widget.eventCode} 前三名：$winners');
  }

  /// 儲存成績
  Future<void> _saveResults() async {
    try {
      final data = {
        'eventCode': widget.eventCode,
        'results': _results,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      html.window.localStorage['relay_${widget.eventCode}'] = json.encode(data);
    } catch (e) {
      print('儲存成績失敗：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '${widget.eventCode}統一管理',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 標籤頁控制器
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: '甲組 (中5-6)'),
                    Tab(text: '乙組 (中3-4)'),
                    Tab(text: '丙組 (中1-2)'),
                  ],
                ),
                // 標籤頁內容
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDivisionView(Division.senior),
                      _buildDivisionView(Division.junior),
                      _buildDivisionView(Division.primary),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportTopThree,
        icon: const Icon(Icons.print),
        label: const Text('列印前三名'),
      ),
    );
  }

  /// 建構組別檢視
  Widget _buildDivisionView(Division division) {
    final classes = _getClassesForDivision(division);
    final divisionResults = _results[division.displayName] ?? {};

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 統計資訊
          _buildStatsCard(division, classes.length),
          const SizedBox(height: 16),
          // 班級成績列表
          Expanded(
            child: ListView.builder(
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final className = classes[index];
                final results = divisionResults[className] ?? [];
                final hasResult = results.isNotEmpty;
                final result = hasResult ? results.first : null;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: hasResult 
                          ? (result!.rank <= 3 ? Colors.amber : Colors.green)
                          : Colors.grey,
                      child: hasResult 
                          ? Text('${result!.rank}')
                          : Text('${index + 1}'),
                    ),
                    title: Text(
                      className,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: hasResult
                        ? Text('成績：${result!.result} | 第${result!.rank}名 | +${result!.points}分')
                        : const Text('尚未填寫成績'),
                    trailing: hasResult
                        ? _buildRankBadge(result!.rank)
                        : IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showResultInputDialog(division, className),
                          ),
                    onTap: () => _showResultInputDialog(division, className),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 建構統計卡片
  Widget _buildStatsCard(Division division, int totalClasses) {
    final divisionResults = _results[division.displayName] ?? {};
    final completedClasses = divisionResults.values
        .where((results) => results != null && results.isNotEmpty)
        .length;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('總班級數', totalClasses.toString()),
            _buildStatItem('已完成', completedClasses.toString()),
            _buildStatItem('完成率', '${(completedClasses / totalClasses * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  /// 建構統計項目
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  /// 建構排名徽章
  Widget _buildRankBadge(int rank) {
    final colors = [Colors.amber, Colors.grey, Colors.brown];
    final icons = [Icons.emoji_events, Icons.emoji_events, Icons.emoji_events];
    
    if (rank <= 3) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors[rank - 1],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icons[rank - 1], size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              rank == 1 ? '冠軍' : rank == 2 ? '亞軍' : '季軍',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  /// 顯示成績輸入對話框
  void _showResultInputDialog(Division division, String className) {
    final controller = TextEditingController();
    final existingResults = _results[division.displayName]![className];
    if (existingResults != null && existingResults.isNotEmpty) {
      controller.text = existingResults.first.result;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('輸入 ${division.displayName} $className 成績'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '成績 (mm:ss.ms)',
                hintText: '例如：02:15.67',
                prefixIcon: Icon(Icons.timer),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 8),
            const Text(
              '格式：分鐘:秒.毫秒 (如 02:15.67)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final result = controller.text.trim();
              if (result.isNotEmpty) {
                Navigator.pop(context);
                _updateClassResult(division, className, result);
              }
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  /// 匯出前三名結果
  void _exportTopThree() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('匯出前三名結果'),
        content: const Text('請選擇匯出方式'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              PrintingService.printRelayTopThree(widget.eventCode);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🖨️ 已送至列印機')),
              );
            },
            child: const Text('列印'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              PrintingService.downloadTopThreeCSV(widget.eventCode);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📥 CSV文件已下載')),
              );
            },
            child: const Text('下載CSV'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}

/// 接力賽團體成績
class RelayTeamResult {
  final String classId;
  final Division division;
  final String eventCode;
  final String result;
  final DateTime timestamp;
  int rank = 0;
  int points = 0;

  RelayTeamResult({
    required this.classId,
    required this.division,
    required this.eventCode,
    required this.result,
    required this.timestamp,
  });
}
