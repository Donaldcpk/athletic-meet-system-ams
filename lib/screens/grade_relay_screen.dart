/// 年級接力賽管理畫面
/// 按年級組織接力賽，支援所有班級參與，即時排名計算

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:html' as html;

import '../services/grade_relay_service.dart';
import '../utils/app_state.dart';
import '../widgets/common_app_bar.dart';
import '../constants/app_constants.dart';

class GradeRelayScreen extends StatefulWidget {
  final String eventCode; // 4x100c, 4x400c, 4x100s, 4x400s
  
  const GradeRelayScreen({
    Key? key,
    required this.eventCode,
  }) : super(key: key);

  @override
  State<GradeRelayScreen> createState() => _GradeRelayScreenState();
}

class _GradeRelayScreenState extends State<GradeRelayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AppState _appState;
  bool _isLoading = false;
  
  // 年級控制器
  final Map<int, Map<String, TextEditingController>> _controllers = {};
  
  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _tabController = TabController(length: 6, vsync: this); // 1-6年級
    _initializeControllers();
    _loadResults();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _disposeControllers();
    super.dispose();
  }
  
  /// 初始化文字控制器
  void _initializeControllers() {
    for (int grade = 1; grade <= 6; grade++) {
      _controllers[grade] = {};
      final gradeClasses = _getClassesForGrade(grade);
      for (final classId in gradeClasses) {
        _controllers[grade]![classId] = TextEditingController();
      }
    }
  }
  
  /// 釋放文字控制器
  void _disposeControllers() {
    for (final gradeControllers in _controllers.values) {
      for (final controller in gradeControllers.values) {
        controller.dispose();
      }
    }
  }
  
  /// 載入成績資料
  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    
    try {
      await GradeRelayService.initialize();
      
      // 載入現有成績到控制器
      for (int grade = 1; grade <= 6; grade++) {
        final gradeClasses = _getClassesForGrade(grade);
        for (final classId in gradeClasses) {
          final result = GradeRelayService.getClassResult(widget.eventCode, grade, classId);
          if (result != null) {
            _controllers[grade]![classId]?.text = result.result;
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('載入失敗：$e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  /// 獲取指定年級的班級列表
  List<String> _getClassesForGrade(int grade) {
    return _appState.students
        .where((s) => s.grade == grade)
        .map((s) => s.classId)
        .toSet()
        .toList()
      ..sort();
  }
  
  /// 儲存單個班級成績
  Future<void> _saveClassResult(int grade, String classId, String result) async {
    if (result.trim().isEmpty) return;
    
    try {
      await GradeRelayService.updateClassResult(
        eventCode: widget.eventCode,
        grade: grade,
        classId: classId,
        result: result.trim(),
      );
      
      setState(() {}); // 重新整理界面以顯示最新排名
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 已儲存 ${grade}年級 $classId 成績：$result'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 儲存失敗：$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// 列印年級前三名
  void _printTopThree(int grade) {
    final topThree = GradeRelayService.getTopThree(widget.eventCode, grade);
    if (topThree.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${grade}年級尚無成績記錄')),
      );
      return;
    }
    
    final eventName = _getEventName(widget.eventCode);
    final htmlContent = _generateTopThreeHTML(eventName, grade, topThree);
    _downloadFile(htmlContent, '${eventName}_${grade}年級_前三名.html');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🖨️ 已下載 ${grade}年級前三名列印檔案')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '${_getEventName(widget.eventCode)} - 年級接力賽',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(child: _buildTabBarView()),
              ],
            ),
    );
  }
  
  /// 建構標題區域
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(AppConstants.colorValues['primary']!).withOpacity(0.1),
        border: const Border(bottom: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        children: [
          Icon(Icons.sports_score, color: Color(AppConstants.colorValues['primary']!)),
          const SizedBox(width: 8),
          Text(
            '${_getEventName(widget.eventCode)} - 按年級排名',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '所有班級均可參與，按年級分別排名',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 建構標籤列
  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: Color(AppConstants.colorValues['primary']!),
      unselectedLabelColor: Colors.grey,
      indicatorColor: Color(AppConstants.colorValues['primary']!),
      tabs: [
        for (int grade = 1; grade <= 6; grade++)
          Tab(text: '${grade}年級'),
      ],
    );
  }
  
  /// 建構標籤頁內容
  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        for (int grade = 1; grade <= 6; grade++)
          _buildGradeView(grade),
      ],
    );
  }
  
  /// 建構年級視圖
  Widget _buildGradeView(int grade) {
    final gradeClasses = _getClassesForGrade(grade);
    final rankings = GradeRelayService.getGradeRankings(widget.eventCode, grade);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGradeHeader(grade, gradeClasses.length, rankings.length),
          const SizedBox(height: 16),
          
          // 成績輸入區域
          _buildResultsInputSection(grade, gradeClasses),
          const SizedBox(height: 24),
          
          // 排名顯示區域
          if (rankings.isNotEmpty) ...[
            _buildRankingsSection(grade, rankings),
            const SizedBox(height: 16),
            _buildTopThreeSection(grade, rankings),
          ],
        ],
      ),
    );
  }
  
  /// 建構年級標題
  Widget _buildGradeHeader(int grade, int totalClasses, int recordedClasses) {
    return Row(
      children: [
        Text(
          '${grade}年級接力賽',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(
          '班級數：$totalClasses | 已記錄：$recordedClasses',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _printTopThree(grade),
          icon: const Icon(Icons.print),
          label: const Text('列印前三名'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(AppConstants.colorValues['primary']!),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
  
  /// 建構成績輸入區域
  Widget _buildResultsInputSection(int grade, List<String> gradeClasses) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '成績輸入',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: gradeClasses.map((classId) {
                return SizedBox(
                  width: 200,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          classId,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controllers[grade]![classId],
                          decoration: const InputDecoration(
                            hintText: 'mm:ss.ms',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9:.]')),
                          ],
                          onSubmitted: (value) => _saveClassResult(grade, classId, value),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _saveClassResult(
                          grade,
                          classId,
                          _controllers[grade]![classId]!.text,
                        ),
                        icon: const Icon(Icons.save, size: 20),
                        tooltip: '儲存成績',
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 建構排名區域
  Widget _buildRankingsSection(int grade, List<RelayTeamResult> rankings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${grade}年級排名',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FixedColumnWidth(60),
                1: FixedColumnWidth(80),
                2: FixedColumnWidth(100),
                3: FixedColumnWidth(80),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Colors.grey),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('名次', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('班級', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('成績', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('積分', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                ...rankings.map((result) => TableRow(
                  decoration: BoxDecoration(
                    color: result.rank <= 3 
                        ? Color(AppConstants.colorValues['primary']!).withOpacity(0.1)
                        : null,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '第${result.rank}名',
                        style: TextStyle(
                          fontWeight: result.rank <= 3 ? FontWeight.bold : null,
                          color: result.rank == 1 ? Colors.amber[700] :
                                 result.rank == 2 ? Colors.grey[600] :
                                 result.rank == 3 ? Colors.brown[600] : null,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(result.classId),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(result.result),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('${result.points}分'),
                    ),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 建構前三名區域
  Widget _buildTopThreeSection(int grade, List<RelayTeamResult> rankings) {
    final topThree = rankings.take(3).toList();
    if (topThree.isEmpty) return const SizedBox.shrink();
    
    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  '${grade}年級前三名',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: topThree.asMap().entries.map((entry) {
                final index = entry.key;
                final result = entry.value;
                final medals = ['🥇', '🥈', '🥉'];
                
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          medals[index],
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.classId,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          result.result,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '${result.points}分',
                          style: const TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 獲取項目名稱
  String _getEventName(String eventCode) {
    switch (eventCode) {
      case '4x100c': return '4x100m班際接力';
      case '4x400c': return '4x400m班際接力';
      case '4x100s': return '4x100m社制接力';
      case '4x400s': return '4x400m社制接力';
      default: return eventCode;
    }
  }
  
  /// 產生前三名HTML
  String _generateTopThreeHTML(String eventName, int grade, List<RelayTeamResult> topThree) {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html><head><meta charset="UTF-8">');
    buffer.writeln('<title>${eventName} ${grade}年級前三名</title>');
    buffer.writeln('<style>');
    buffer.writeln('body { font-family: Arial, sans-serif; margin: 40px; }');
    buffer.writeln('h1 { text-align: center; color: #333; }');
    buffer.writeln('table { width: 100%; border-collapse: collapse; margin: 20px 0; }');
    buffer.writeln('th, td { border: 1px solid #ddd; padding: 12px; text-align: center; }');
    buffer.writeln('th { background-color: #f5f5f5; font-weight: bold; }');
    buffer.writeln('.rank-1 { background-color: #fff9c4; }');
    buffer.writeln('.rank-2 { background-color: #f5f5f5; }');
    buffer.writeln('.rank-3 { background-color: #ffeaa7; }');
    buffer.writeln('</style></head><body>');
    
    buffer.writeln('<h1>${eventName} ${grade}年級前三名</h1>');
    buffer.writeln('<p style="text-align: center; color: #666;">列印時間：${DateTime.now().toString().substring(0, 19)}</p>');
    
    buffer.writeln('<table>');
    buffer.writeln('<tr><th>名次</th><th>班級</th><th>成績</th><th>積分</th></tr>');
    
    for (int i = 0; i < topThree.length; i++) {
      final result = topThree[i];
      final rankClass = 'rank-${i + 1}';
      buffer.writeln('<tr class="$rankClass">');
      buffer.writeln('<td>第${result.rank}名</td>');
      buffer.writeln('<td>${result.classId}</td>');
      buffer.writeln('<td>${result.result}</td>');
      buffer.writeln('<td>${result.points}分</td>');
      buffer.writeln('</tr>');
    }
    
    buffer.writeln('</table>');
    buffer.writeln('</body></html>');
    
    return buffer.toString();
  }
  
  /// 下載文件
  void _downloadFile(String content, String filename) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = filename;
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}
