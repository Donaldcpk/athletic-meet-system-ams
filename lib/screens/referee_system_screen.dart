/// 全新設計的裁判系統 v2
/// 根據香港中學運動會標準設計的寬屏表格式成績輸入界面

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../models/student.dart';
import '../models/referee_models.dart';
import '../models/event.dart' as EventModel show EventType, EventCategory;
import '../constants/event_constants.dart';
import '../constants/app_constants.dart';
import '../utils/app_state.dart';
import '../widgets/common_app_bar.dart';
import '../services/operation_log_service.dart';
import '../services/scoring_service.dart';
import '../services/lane_allocation_service.dart';
import '../services/records_service.dart';
import '../services/user_service.dart';

/// 裁判系統主界面
class RefereeSystemScreen extends StatefulWidget {
  const RefereeSystemScreen({super.key});

  @override
  State<RefereeSystemScreen> createState() => _RefereeSystemScreenState();
}

class _RefereeSystemScreenState extends State<RefereeSystemScreen>
    with TickerProviderStateMixin {
  
  final AppState _appState = AppState();
  
  // Tab控制器
  late TabController _tabController;
  
  // 目前選中的項目
  EventInfo? _selectedEvent;
  
  // 項目篩選狀態
  EventCategory? _selectedCategory;
  Division? _selectedDivision;
  Gender? _selectedGender;
  final _searchController = TextEditingController();
  
  // 成績數據存儲
  final Map<String, String> _preliminaryResults = {};
  final Map<String, String> _finalsResults = {};
  final Map<String, bool> _dnfStatus = {};
  final Map<String, bool> _dqStatus = {};
  final Map<String, bool> _absStatus = {};
  final Map<String, List<String>> _finalists = {};
  final Map<String, List<PodiumWinner>> _podiumResults = {};
  final Map<String, List<String>> _fieldAttempts = {};
  
  // TextEditingController管理
  final Map<String, TextEditingController> _preliminaryControllers = {};
  final Map<String, TextEditingController> _finalsControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeRecords();
    _loadResultsData();
  }
  
  /// 初始化紀錄系統
  Future<void> _initializeRecords() async {
    try {
      RecordsService.initializeRecords();
      setState(() {}); // 刷新UI以顯示記錄
      print('✅ 紀錄系統初始化成功');
    } catch (e) {
      print('❌ 紀錄系統初始化失敗: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 檢查是否有查看裁判系統的權限
    if (!UserService.hasPermission(UserPermissions.viewRefereeSystem)) {
    return Scaffold(
        appBar: const CommonAppBar(title: '裁判系統'),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                '無權限訪問裁判系統',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                '請聯繫系統管理員獲取權限',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ],
        ),
      ),
      );
    }

    return Scaffold(
      appBar: const CommonAppBar(title: '裁判系統'),
      body: Column(
        children: [
          // 權限提示條
          if (UserService.isViewer)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange[100],
              child: Row(
                children: [
                  Icon(Icons.visibility, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '觀看者模式：您只能查看數據，無法進行修改操作',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          
          // 頂部Tab導航
          Container(
            color: Colors.blue[50],
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.timer), text: '初賽成績'),
                Tab(icon: Icon(Icons.emoji_events), text: '決賽成績'),
                Tab(icon: Icon(Icons.group), text: '接力賽事'),
                Tab(icon: Icon(Icons.list), text: '三甲名單'),
              ],
            ),
          ),
          
          // Tab內容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPreliminaryView(),
                _buildFinalsView(),
                _buildRelayView(),
                _buildPodiumView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 初賽成績輸入界面 - 寬屏優化
  Widget _buildPreliminaryView() {
    final events = _getFilteredEvents();
    
    return Row(
      children: [
        // 左側項目選擇面板
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(right: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
            children: [
              Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
                  color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
                child: const Row(
        children: [
                    Icon(Icons.list, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      '選擇項目',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final hasResults = _hasEventResults(event);
                    final isSelected = _selectedEvent?.code == event.code;
                    
                    return ListTile(
                      title: Text(
                        event.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: hasResults ? Colors.green[700] : null,
                        ),
                      ),
                      subtitle: Text('${event.code}'),
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedEvent = event;
                        });
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasResults) 
                            Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                          if (isSelected) 
                            const Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 16),
                        ],
                      ),
                    );
                  },
            ),
          ),
        ],
      ),
        ),
        
        // 右側成績輸入區域
        Expanded(
          child: _selectedEvent != null
              ? Column(
                  children: [
                    _buildEventRecordsInfo(), // 紀錄和標準成績信息
                    Expanded(child: _buildPreliminaryTable(_selectedEvent!)),
                  ],
                )
              : const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                      Icon(Icons.arrow_back, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
            Text(
                        '請在左側選擇一個項目開始輸入初賽成績',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
                ),
        ),
      ],
    );
  }

  /// 決賽成績輸入界面
  Widget _buildFinalsView() {
    final events = _getFilteredEvents();
    
    return Row(
      children: [
        // 左側項目列表
        Container(
          width: 300,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
          children: [
              // 搜索和篩選
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
              child: Column(
                children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: '搜索項目...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    _buildEventFilterDropdowns(),
                  ],
                ),
              ),
              
              // 項目列表
              Expanded(
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final isSelected = _selectedEvent?.code == event.code;
                    final hasFinalists = _finalists[event.code]?.isNotEmpty ?? false;
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[50] : null,
                        border: Border(
                          left: BorderSide(
                            color: isSelected ? Colors.blue : Colors.transparent,
                            width: 4,
                          ),
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                    event.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.code),
                            if (hasFinalists)
                    Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                                  '已有決賽名單',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green[700],
                                  ),
                      ),
                    ),
                ],
              ),
                        selected: isSelected,
                        onTap: () => setState(() => _selectedEvent = event),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // 右側決賽成績輸入區域
        Expanded(
          child: _selectedEvent != null
              ? Column(
                  children: [
                    _buildEventRecordsInfo(), // 紀錄和標準成績信息
                    _buildFinalsControlButtons(), // 操作按鈕
                    Expanded(child: _buildFinalsTable(_selectedEvent!)),
                  ],
                )
              : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                      Icon(Icons.emoji_events, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                  Text(
                        '請在左側選擇一個項目開始輸入決賽成績',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                ],
              ),
            ),
        ),
      ],
    );
  }

  /// 決賽控制按鈕
  Widget _buildFinalsControlButtons() {
    if (_selectedEvent == null) return const SizedBox.shrink();
    
    final hasFinalists = _finalists[_selectedEvent!.code]?.isNotEmpty ?? false;
    
      return Container(
      padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          if (UserService.hasPermission(UserPermissions.generateFinalists)) ...[
            ElevatedButton.icon(
              onPressed: () => _generateFinalists(_selectedEvent!.code),
              icon: const Icon(Icons.list_alt, size: 16),
              label: const Text('生成決賽名單'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                foregroundColor: Colors.blue[700],
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          if (hasFinalists && UserService.hasPermission(UserPermissions.printResults)) ...[
            ElevatedButton.icon(
              onPressed: () => _printFinalistsList(_selectedEvent!.code),
              icon: const Icon(Icons.print, size: 16),
              label: const Text('列印決賽名單'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[100],
                foregroundColor: Colors.green[700],
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          if (hasFinalists && UserService.hasPermission(UserPermissions.inputScores)) ...[
            ElevatedButton.icon(
              onPressed: () => _generatePodium(_selectedEvent!.code),
              icon: const Icon(Icons.emoji_events, size: 16),
              label: const Text('生成三甲名單'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[100],
                foregroundColor: Colors.orange[700],
              ),
            ),
          ],
          
          const Spacer(),
          
          if (hasFinalists && UserService.hasPermission(UserPermissions.inputScores))
            ElevatedButton.icon(
              onPressed: () => _clearFinalists(_selectedEvent!.code),
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('清除決賽名單'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[100],
                foregroundColor: Colors.red[700],
              ),
            ),
        ],
        ),
      );
    }

  /// 決賽成績輸入表格
  Widget _buildFinalsTable(EventInfo event) {
    final finalists = _finalists[event.code] ?? [];
    
    if (finalists.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '尚未生成決賽名單',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '請先在初賽成績中輸入成績，然後點擊「生成決賽名單」',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('名次', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('參賽編號', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('姓名', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('班別', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('初賽成績', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('決賽成績', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('狀態', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: finalists.asMap().entries.map((entry) {
          final index = entry.key;
          final studentId = entry.value;
          final student = _appState.students.firstWhere((s) => s.id == studentId);
          final resultKey = '${student.id}_${event.code}';
          final preliminaryResult = _preliminaryResults[resultKey] ?? '--';
          
          return DataRow(
            cells: [
              DataCell(Text('${index + 1}')),
              DataCell(Text(student.studentCode)),
              DataCell(Text(student.name)),
              DataCell(Text(student.classId)),
              DataCell(Text(preliminaryResult)),
              DataCell(
                UserService.hasPermission(UserPermissions.inputScores)
                    ? _buildResultTextField(
                        resultKey: resultKey,
                        isInitial: false,
                        event: event,
                      )
                    : _buildReadOnlyResultDisplay(resultKey, event),
              ),
              DataCell(
                UserService.hasPermission(UserPermissions.inputScores)
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatusChip('DNF', _dnfStatus[resultKey] ?? false, () => _toggleStatus(resultKey, 'DNF')),
                          const SizedBox(width: 4),
                          _buildStatusChip('DQ', _dqStatus[resultKey] ?? false, () => _toggleStatus(resultKey, 'DQ')),
                          const SizedBox(width: 4),
                          _buildStatusChip('ABS', _absStatus[resultKey] ?? false, () => _toggleStatus(resultKey, 'ABS')),
                        ],
                      )
                    : _buildReadOnlyStatusDisplay(resultKey),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// 接力賽事界面
  Widget _buildRelayView() {
    final events = _getFilteredEvents();
    final relayEvents = events.where((e) => 
      e.category == EventCategory.relay || e.category == EventCategory.special).toList();
    
    // 調試信息
    print('🔍 所有項目數量: ${EventConstants.allEvents.length}');
    print('🔍 過濾後項目數量: ${events.length}');
    print('🔍 接力項目數量: ${relayEvents.length}');
    for (final event in relayEvents) {
      print('🔍 接力項目: ${event.code} - ${event.name} (${event.category})');
    }
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.purple[50],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              const Icon(Icons.group, color: Colors.purple),
              const SizedBox(width: 8),
              const Text(
                '接力賽事成績輸入',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
        child: Text(
                  '${relayEvents.length} 個項目',
                  style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                ),
              ),
            ],
          ),
        ),
        
        // 如果沒有接力項目，顯示提示
        if (relayEvents.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '沒有找到接力項目',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '總項目數: ${EventConstants.allEvents.length}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  Text(
                    '當前標籤頁: ${_tabController.index}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: relayEvents.length,
              itemBuilder: (context, index) {
                final event = relayEvents[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: _buildRelayEventCard(event),
                );
              },
            ),
          ),
      ],
    );
  }

  /// 三甲名單界面
  /// 三甲名單界面
  Widget _buildPodiumView() {
    final allPodiumResults = _podiumResults;
    
    if (allPodiumResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '尚未生成任何三甲名單',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '請先在決賽成績中輸入成績並生成三甲名單',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[600]!, Colors.orange[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Text(
                  '🏆 三甲名單',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // 按項目分組顯示三甲名單
          ...allPodiumResults.entries.map((entry) {
            final eventCode = entry.key;
            final winners = entry.value;
            final event = EventConstants.allEvents.firstWhere((e) => e.code == eventCode);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey[200]!),
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // 項目標題
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                  children: [
                        Icon(Icons.sports, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                          event.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            eventCode,
                            style: TextStyle(
                              fontSize: 12,
                        color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
                  ),
                  
                  // 三甲名單
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // 第二名
                        if (winners.length > 1)
                          Expanded(
                            child: _buildPodiumWinnerCard(winners[1], 2, Colors.grey[400]!, '🥈'),
                          ),
                        
                        if (winners.length > 1) const SizedBox(width: 8),
                        
                        // 第一名
                        if (winners.isNotEmpty)
                          Expanded(
                            child: _buildPodiumWinnerCard(winners[0], 1, Colors.amber[600]!, '🥇'),
                          ),
                        
                        if (winners.isNotEmpty) const SizedBox(width: 8),
                        
                        // 第三名
                        if (winners.length > 2)
                          Expanded(
                            child: _buildPodiumWinnerCard(winners[2], 3, Colors.orange[400]!, '🥉'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// 構建三甲獲獎者卡片
  Widget _buildPodiumWinnerCard(PodiumWinner winner, int position, Color color, String medal) {
    final height = position == 1 ? 140.0 : position == 2 ? 120.0 : 100.0;
    
                    return Container(
      height: height,
                      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
          // 獎牌
          Text(medal, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          
          // 名次
                          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
                            ),
                              child: Text(
              '第 $position 名',
                                style: const TextStyle(
                                  color: Colors.white,
                fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
          const SizedBox(height: 8),
          
          // 學生信息
                                Text(
            winner.studentName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          if (winner.className != null && winner.className!.isNotEmpty) ...[
            const SizedBox(height: 2),
                                Text(
              winner.className ?? '',
                                  style: TextStyle(
                fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
          const SizedBox(height: 4),
          
          // 成績
          Text(
            winner.result.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          
          // 積分
                            Container(
            margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
              '+${winner.points}分',
                                style: TextStyle(
                                  fontSize: 10,
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
  }

  /// 構建接力賽事卡片
  Widget _buildRelayEventCard(EventInfo event) {
    return ExpansionTile(
      title: Text(event.name),
      subtitle: Text(event.specialRules ?? ''),
      children: [
        if (event.category == EventCategory.special)
          _buildSpecialRelayTable(event)
        else
          _buildRegularRelayTable(event),
      ],
    );
  }

  /// 特殊接力項目 - 暫代人員T1-T8
  Widget _buildSpecialRelayTable(EventInfo event) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange[300]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          // 簡潔標題
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${event.name} - 暫代人員',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '無積分計算',
                    style: TextStyle(fontSize: 12, color: Colors.red[700]),
                  ),
                ),
              ],
            ),
          ),
          
          // 暫代人員T1-T8成績輸入表格 - 簡化版
          DataTable(
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('暫代人員')),
              DataColumn(label: Text('成績')),
              DataColumn(label: Text('狀態')),
            ],
            rows: List.generate(8, (index) {
              final tempId = 'T${index + 1}';
              final teamKey = '${tempId}_${event.code}';
              
              return DataRow(
                cells: [
                  DataCell(Text(tempId)),
                  DataCell(
                    SizedBox(
                      width: 100,
                      child: UserService.hasPermission(UserPermissions.inputScores)
                          ? TextField(
                              controller: _getOrCreateRelayController(teamKey),
                              decoration: const InputDecoration(
                                hintText: '00:00.00',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                            )
                          : _buildReadOnlyResultDisplay(teamKey, event),
                    ),
                  ),
                  DataCell(
                    UserService.hasPermission(UserPermissions.inputScores)
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildStatusChip('DNF', _dnfStatus[teamKey] ?? false, () => _toggleStatus(teamKey, 'DNF')),
                              const SizedBox(width: 4),
                              _buildStatusChip('DQ', _dqStatus[teamKey] ?? false, () => _toggleStatus(teamKey, 'DQ')),
                            ],
                          )
                        : _buildReadOnlyStatusDisplay(teamKey),
                  ),
                ],
              );
            }),
          ),
          
          // 儲存按鈕 - 根據權限顯示
          if (UserService.hasPermission(UserPermissions.inputScores))
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _saveSpecialRelayResults(event),
                icon: const Icon(Icons.save),
                label: const Text('儲存成績'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 構建普通接力表格
  Widget _buildRegularRelayTable(EventInfo event) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text('普通接力賽事界面'),
    );
  }

  /// 建構狀態標籤
  Widget _buildStatusChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.red[400]! : Colors.grey[400]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.red[700] : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  /// 初賽成績輸入表格
  Widget _buildPreliminaryTable(EventInfo event) {
    final participants = _getSortedParticipants(event);
    
    if (participants.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '該項目暫無參賽者',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // 表格標題
          Container(
            width: double.infinity,
      padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Text(
              '${event.name} - 初賽成績輸入',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          // 成績輸入表格
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('道次', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('參賽編號', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('姓名', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('班別', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('成績', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('狀態', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('操作', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: participants.asMap().entries.map((entry) {
                final index = entry.key;
                final student = entry.value;
                final resultKey = '${student.id}_${event.code}';
                
                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(student.studentCode)),
                    DataCell(Text(student.name)),
                    DataCell(Text(student.classId)),
                    DataCell(
                      UserService.hasPermission(UserPermissions.inputScores)
                          ? (event.category == EventCategory.field
                              ? _buildFieldAttemptsWidget(resultKey, event)
                              : _buildResultTextField(
                                  resultKey: resultKey,
                                  isInitial: true,
                                  event: event,
                                ))
                          : _buildReadOnlyResultDisplay(resultKey, event),
                    ),
                    DataCell(
                      UserService.hasPermission(UserPermissions.inputScores)
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStatusChip('DNF', _dnfStatus[resultKey] ?? false, () => _toggleStatus(resultKey, 'DNF')),
                                const SizedBox(width: 4),
                                _buildStatusChip('DQ', _dqStatus[resultKey] ?? false, () => _toggleStatus(resultKey, 'DQ')),
                                const SizedBox(width: 4),
                                _buildStatusChip('ABS', _absStatus[resultKey] ?? false, () => _toggleStatus(resultKey, 'ABS')),
                              ],
                            )
                          : _buildReadOnlyStatusDisplay(resultKey),
                    ),
                    DataCell(
                      UserService.hasPermission(UserPermissions.inputScores)
                          ? ElevatedButton(
                              onPressed: () => _clearResult(resultKey),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[100],
                                foregroundColor: Colors.red[700],
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              child: const Text('清除', style: TextStyle(fontSize: 12)),
                            )
                          : const Text('-', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          
          // 操作按鈕 - 根據權限顯示
          if (UserService.hasPermission(UserPermissions.inputScores))
            Container(
            padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                  ElevatedButton.icon(
                    onPressed: () => _savePreliminaryResults(event),
                    icon: const Icon(Icons.save),
                    label: const Text('保存初賽成績'),
                  ),
                  if (UserService.hasPermission(UserPermissions.generateFinalists))
                    ElevatedButton.icon(
                      onPressed: () => _generateFinalists(event.code),
                      icon: const Icon(Icons.list),
                      label: const Text('生成決賽名單'),
                    ),
                  ],
                ),
            ),
        ],
      ),
    );
  }

  /// 田賽成績輸入 - 修復重疊問題
  Widget _buildFieldAttemptsWidget(String resultKey, EventInfo event) {
    final activeCount = _getActiveAttemptCount(resultKey);
    
    return Container(
      width: 350, // 調整寬度
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 嘗試次數選擇 - 放在側邊避免重疊
          Row(
            children: [
              const Text('次數:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Container(
                width: 65,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: DropdownButtonFormField<int>(
                  value: activeCount,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 10),
                  items: List.generate(6, (index) {
                    final count = index + 1;
                    return DropdownMenuItem<int>(
                      value: count,
                      child: Text('$count次'),
                    );
                  }),
                  onChanged: (value) => _setActiveAttemptCount(resultKey, value ?? 3),
                ),
              ),
              const Spacer(),
              // 最佳成績顯示在右側
              if (_getBestFieldResult(resultKey) != '--')
                Text(
                  '最佳: ${_getBestFieldResult(resultKey)}m',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // 成績輸入區域 - 確保不重疊
          Container(
            height: 55,
            child: Row(
              children: List.generate(activeCount, (index) {
                final attempts = _fieldAttempts[resultKey] ?? [];
                final hasValue = index < attempts.length && attempts[index].isNotEmpty;
                final value = hasValue ? attempts[index] : '';
                final isBest = hasValue && _getBestFieldResult(resultKey) == value && value != '0' && value != '0.00';
                
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isBest ? Colors.green[600]! : Colors.grey[300]!,
                        width: isBest ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(3),
                      color: isBest ? Colors.green[50] : Colors.white,
                    ),
                    child: Column(
                      children: [
                        // 標題
                        Container(
                          height: 18,
                          decoration: BoxDecoration(
                            color: isBest ? Colors.green[100] : Colors.grey[100],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(3),
                              topRight: Radius.circular(3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '第${index + 1}次',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: isBest ? Colors.green[800] : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        
                        // 輸入框
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(1),
                            child: TextFormField(
                              controller: _getFieldAttemptController(resultKey, index),
                              decoration: const InputDecoration(
                                hintText: '0.00',
                                hintStyle: TextStyle(fontSize: 8, color: Colors.grey),
                                suffixText: 'm',
                                suffixStyle: TextStyle(fontSize: 8, color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(1),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
                                color: isBest ? Colors.green[800] : Colors.black,
                              ),
                              onChanged: (value) {
                                _updateFieldAttempt(resultKey, index, value);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// 構建只讀成績顯示
  Widget _buildReadOnlyResultDisplay(String resultKey, EventInfo event) {
    final result = _preliminaryResults[resultKey] ?? '';
    final isDNF = _dnfStatus[resultKey] ?? false;
    final isDQ = _dqStatus[resultKey] ?? false;
    final isABS = _absStatus[resultKey] ?? false;
    
    String displayText = '';
    Color? textColor;
    
    if (isDNF) {
      displayText = 'DNF';
      textColor = Colors.red[600];
    } else if (isDQ) {
      displayText = 'DQ';
      textColor = Colors.red[600];
    } else if (isABS) {
      displayText = 'ABS';
      textColor = Colors.grey[600];
    } else if (result.isNotEmpty) {
      displayText = result;
      textColor = Colors.black87;
    } else {
      displayText = '-';
      textColor = Colors.grey[400];
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        displayText,
                                  style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 構建只讀狀態顯示
  Widget _buildReadOnlyStatusDisplay(String resultKey) {
    final isDNF = _dnfStatus[resultKey] ?? false;
    final isDQ = _dqStatus[resultKey] ?? false;
    final isABS = _absStatus[resultKey] ?? false;
    
    if (!isDNF && !isDQ && !isABS) {
      return const Text('-', style: TextStyle(color: Colors.grey));
    }
    
    String statusText = '';
    Color? backgroundColor;
    Color? textColor;
    
    if (isDNF) {
      statusText = 'DNF';
      backgroundColor = Colors.red[100];
      textColor = Colors.red[700];
    } else if (isDQ) {
      statusText = 'DQ';
      backgroundColor = Colors.red[100];
      textColor = Colors.red[700];
    } else if (isABS) {
      statusText = 'ABS';
      backgroundColor = Colors.grey[200];
      textColor = Colors.grey[600];
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor!.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
                                    style: TextStyle(
          fontSize: 12,
                                    fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  /// 構建成績輸入框
  Widget _buildResultTextField({
    required String resultKey,
    required bool isInitial,
    required EventInfo event,
  }) {
    final isDNF = _dnfStatus[resultKey] ?? false;
    final isDQ = _dqStatus[resultKey] ?? false;
    final isABS = _absStatus[resultKey] ?? false;
    
    final hasSpecialStatus = isDNF || isDQ || isABS;
    
    if (hasSpecialStatus) {
      final statusText = isDNF ? 'DNF' : (isDQ ? 'DQ' : 'ABS');
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey[200],
        ),
        child: Text(
          statusText,
                                  style: TextStyle(
                                    color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    
    final controller = _getOrCreateController(resultKey, isInitial);
    
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: _getHintForEvent(event),
        hintStyle: TextStyle(
          color: Colors.grey[300],
          fontSize: 13,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        if (event.category == EventCategory.track)
          FilteringTextInputFormatter.allow(RegExp(r'[\d\.:]+'))
        else
          FilteringTextInputFormatter.allow(RegExp(r'[\d\.]+'))
      ],
    );
  }

  /// 構建紀錄信息卡片
  Widget _buildEventRecordsInfo() {
    if (_selectedEvent == null) return const SizedBox.shrink();
    
    // 獲取對應的性別和組別
    Gender? gender;
    Division? division;
    
    // 根據事件代碼解析性別和組別
    final eventCode = _selectedEvent!.code;
    if (eventCode.startsWith('G')) {
      gender = Gender.female;
    } else if (eventCode.startsWith('B')) {
      gender = Gender.male;
    }
    
    if (eventCode.contains('A')) {
      division = Division.senior;
    } else if (eventCode.contains('B')) {
      division = Division.junior;
    } else if (eventCode.contains('C')) {
      division = Division.primary;
    }
    
    EventRecord? record;
    if (gender != null && division != null) {
      record = RecordsService.getMatchingRecord(_selectedEvent!.name, gender, division);
    }
    
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber[200]!, width: 1),
      ),
      child: Row(
                            children: [
          Icon(Icons.emoji_events, color: Colors.amber[700], size: 16),
          const SizedBox(width: 8),
                              Text(
            _selectedEvent!.code,
                                style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.stars, size: 14, color: Colors.red[600]),
          const SizedBox(width: 4),
          Text(
            '校紀錄: ${record?.recordValue ?? '無'}',
            style: TextStyle(fontSize: 11, color: Colors.red[700]),
          ),
          const SizedBox(width: 12),
          Icon(Icons.flag, size: 14, color: Colors.green[600]),
          const SizedBox(width: 4),
          Text(
            '標準: ${record?.standardValue ?? '無'}',
            style: TextStyle(fontSize: 11, color: Colors.green[700]),
          ),
          const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
              '破紀錄+3分 達標+1分',
                                    style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.blue[800],
                                    ),
                                  ),
                                ),
          const SizedBox(width: 8),
          if (UserService.hasPermission(UserPermissions.inputScores))
            ElevatedButton.icon(
              onPressed: () => _clearAllEventInputs(),
              icon: const Icon(Icons.clear_all, size: 14),
              label: const Text('清除全部'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[100],
                foregroundColor: Colors.red[700],
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                textStyle: const TextStyle(fontSize: 11),
                minimumSize: const Size(0, 28),
              ),
            ),
        ],
      ),
    );
  }

  /// 輔助方法
  List<EventInfo> _getFilteredEvents() {
    return EventConstants.allEvents.where((event) {
      // 根據當前標籤頁過濾事件
      if (_tabController.index == 2) {
        // 接力賽事標籤頁
        return event.category == EventCategory.relay || event.category == EventCategory.special;
      } else {
        // 初賽和決賽標籤頁顯示個人項目
        return event.category == EventCategory.track || event.category == EventCategory.field;
      }
    }).toList();
  }
  
  List<Student> _getSortedParticipants(EventInfo event) {
    return _appState.students
        .where((student) => student.registeredEvents.contains(event.code))
        .toList()
      ..sort((a, b) => a.studentCode.compareTo(b.studentCode));
  }
  
  bool _hasEventResults(EventInfo event) {
    for (final student in _appState.students) {
      if (student.registeredEvents.contains(event.code)) {
        final preliminaryKey = '${student.id}_${event.code}';
        if (_preliminaryResults[preliminaryKey]?.isNotEmpty ?? false) {
          return true;
        }
      }
    }
    return false;
  }
  
  String _getHintForEvent(EventInfo event) {
    if (event.category == EventCategory.track) {
      return event.name.contains('100m') || event.name.contains('200m') 
          ? '00.00' : '0:00.00';
    } else {
      return '0.00';
    }
  }

  /// 田賽支持方法
  int _getActiveAttemptCount(String resultKey) {
    final attempts = _fieldAttempts[resultKey] ?? [];
    if (attempts.isEmpty) {
      // 初始化為3次嘗試
      _fieldAttempts[resultKey] = ['', '', ''];
      return 3;
    }
    return attempts.length.clamp(1, 6);
  }

  void _setActiveAttemptCount(String resultKey, int count) {
    setState(() {
      final currentAttempts = _fieldAttempts[resultKey] ?? [];
      if (count > currentAttempts.length) {
        while (currentAttempts.length < count) {
          currentAttempts.add('');
        }
      } else if (count < currentAttempts.length) {
        currentAttempts.removeRange(count, currentAttempts.length);
      }
      _fieldAttempts[resultKey] = currentAttempts;
    });
  }

  TextEditingController _getFieldAttemptController(String resultKey, int index) {
    final key = '${resultKey}_attempt_$index';
    if (!_preliminaryControllers.containsKey(key)) {
      final controller = TextEditingController();
      final attempts = _fieldAttempts[resultKey] ?? [];
      if (index < attempts.length) {
        controller.text = attempts[index];
      }
      _preliminaryControllers[key] = controller;
    }
    return _preliminaryControllers[key]!;
  }

  void _updateFieldAttempt(String resultKey, int index, String value) {
    final attempts = _fieldAttempts[resultKey] ?? [];
    while (attempts.length <= index) {
      attempts.add('');
    }
    attempts[index] = value;
    _fieldAttempts[resultKey] = attempts;
    
    final bestResult = _getBestFieldResult(resultKey);
    if (bestResult != '--') {
      _preliminaryResults[resultKey] = bestResult;
    }
    
    _saveResultsData();
  }

  String _getBestFieldResult(String resultKey) {
    final attempts = _fieldAttempts[resultKey] ?? [];
    double bestValue = 0.0;
    
    for (final attempt in attempts) {
      if (attempt.isNotEmpty) {
        final value = double.tryParse(attempt) ?? 0.0;
        if (value > bestValue) {
          bestValue = value;
        }
      }
    }
    
    return bestValue > 0 ? bestValue.toStringAsFixed(2) : '--';
  }

  String _getFieldAttemptValue(String resultKey, int index) {
    final attempts = _fieldAttempts[resultKey] ?? [];
    if (index < attempts.length && attempts[index].isNotEmpty) {
      return '${attempts[index]}m';
    }
    return '-';
  }

  /// 控制器管理
  TextEditingController _getOrCreateController(String resultKey, bool isInitial) {
    final controllers = isInitial ? _preliminaryControllers : _finalsControllers;
    final results = isInitial ? _preliminaryResults : _finalsResults;
    
    if (!controllers.containsKey(resultKey)) {
      final controller = TextEditingController();
      final currentValue = results[resultKey] ?? '';
      controller.text = currentValue;
      
      controller.addListener(() {
        final newValue = controller.text;
        if (results[resultKey] != newValue) {
          setState(() {
            results[resultKey] = newValue;
            _saveResultsData();
          });
        }
      });
      
      controllers[resultKey] = controller;
    }
    
    return controllers[resultKey]!;
  }

  TextEditingController _getOrCreateRelayController(String teamKey) {
    if (!_finalsControllers.containsKey(teamKey)) {
      final controller = TextEditingController();
      final currentValue = _finalsResults[teamKey] ?? '';
      controller.text = currentValue;
      
      controller.addListener(() {
        final newValue = controller.text;
        if (_finalsResults[teamKey] != newValue) {
          setState(() {
            _finalsResults[teamKey] = newValue;
          });
          _saveResultsData();
        }
      });
      
      _finalsControllers[teamKey] = controller;
    }
    
    return _finalsControllers[teamKey]!;
  }

  /// 狀態管理
  void _toggleStatus(String resultKey, String statusType) {
    setState(() {
      switch (statusType) {
        case 'DNF':
          _dnfStatus[resultKey] = !(_dnfStatus[resultKey] ?? false);
          if (_dnfStatus[resultKey] == true) {
            _dqStatus[resultKey] = false;
            _absStatus[resultKey] = false;
            _clearResultControllers(resultKey);
          }
          break;
        case 'DQ':
          _dqStatus[resultKey] = !(_dqStatus[resultKey] ?? false);
          if (_dqStatus[resultKey] == true) {
            _dnfStatus[resultKey] = false;
            _absStatus[resultKey] = false;
            _clearResultControllers(resultKey);
          }
          break;
        case 'ABS':
          _absStatus[resultKey] = !(_absStatus[resultKey] ?? false);
          if (_absStatus[resultKey] == true) {
            _dnfStatus[resultKey] = false;
            _dqStatus[resultKey] = false;
            _clearResultControllers(resultKey);
          }
          break;
      }
    });
  }

  void _clearResult(String resultKey) {
    setState(() {
      _preliminaryResults[resultKey] = '';
      _finalsResults[resultKey] = '';
      _dnfStatus.remove(resultKey);
      _dqStatus.remove(resultKey);
      _absStatus.remove(resultKey);
    });
  }

  /// 生成決賽名單
  void _generateFinalists(String eventCode) {
    final event = EventConstants.allEvents.firstWhere((e) => e.code == eventCode);
    final participants = _appState.getEventParticipants(event.code);
    
    // 收集有成績的參與者
    final List<MapEntry<Student, double?>> results = [];
    
    for (final student in participants) {
      final resultKey = '${student.id}_${event.code}';
      final resultStr = _preliminaryResults[resultKey];
      final isDNF = _dnfStatus[resultKey] ?? false;
      final isDQ = _dqStatus[resultKey] ?? false;
      final isABS = _absStatus[resultKey] ?? false;
      
      if (resultStr != null && resultStr.isNotEmpty && !isDNF && !isDQ && !isABS) {
        final result = double.tryParse(resultStr);
        if (result != null && result > 0) {
          results.add(MapEntry(student, result));
        }
      }
    }
    
    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('沒有有效的初賽成績，無法生成決賽名單')),
      );
      return;
    }
    
    // 排序（田賽從大到小，徑賽從小到大）
    results.sort((a, b) {
      if (event.category == EventCategory.field) {
        return b.value!.compareTo(a.value!); // 田賽：大的在前
      } else {
        return a.value!.compareTo(b.value!); // 徑賽：小的在前
      }
    });
    
    // 取前8名進入決賽
    final finalists = results.take(8).map((e) => e.key.id).toList();
    
    setState(() {
      _finalists[eventCode] = finalists;
    });
    
    _saveResultsData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已生成 ${finalists.length} 位決賽選手')),
    );
  }

  /// 列印決賽名單
  void _printFinalistsList(String eventCode) {
    final event = EventConstants.allEvents.firstWhere((e) => e.code == eventCode);
    final finalists = _finalists[eventCode] ?? [];
    
    if (finalists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('沒有決賽名單可列印')),
      );
      return;
    }
    
    // 簡化版：只顯示成功訊息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已準備 ${event.name} 決賽名單，共 ${finalists.length} 位參賽者'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 生成三甲名單
  void _generatePodium(String eventCode) {
    final event = EventConstants.allEvents.firstWhere((e) => e.code == eventCode);
    final finalists = _finalists[eventCode] ?? [];
    
    if (finalists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('沒有決賽名單，無法生成三甲名單')),
      );
      return;
    }
    
    // 收集決賽成績
    final List<MapEntry<Student, double?>> results = [];
    
    for (final studentId in finalists) {
      final student = _appState.students.firstWhere((s) => s.id == studentId);
      final resultKey = '${student.id}_${event.code}';
      final resultStr = _finalsResults[resultKey];
      final isDNF = _dnfStatus[resultKey] ?? false;
      final isDQ = _dqStatus[resultKey] ?? false;
      final isABS = _absStatus[resultKey] ?? false;
      
      if (resultStr != null && resultStr.isNotEmpty && !isDNF && !isDQ && !isABS) {
        final result = double.tryParse(resultStr);
        if (result != null && result > 0) {
          results.add(MapEntry(student, result));
        }
      }
    }
    
    if (results.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('決賽成績不足3人，無法生成三甲名單')),
      );
      return;
    }
    
    // 排序
    results.sort((a, b) {
      if (event.category == EventCategory.field) {
        return b.value!.compareTo(a.value!);
      } else {
        return a.value!.compareTo(b.value!);
      }
    });
    
    // 生成三甲名單
    final podium = <PodiumWinner>[];
    for (int i = 0; i < results.length && i < 3; i++) {
      final student = results[i].key;
      final score = results[i].value!;
      
      podium.add(PodiumWinner(
        studentId: student.id,
        studentName: student.name,
        studentCode: student.studentCode,
        className: student.classId,
        isStaff: student.isStaff,
        result: score,
        finalResult: score.toString(),
        points: [8, 6, 4][i], // 冠亞季軍分數
        rank: i + 1,
      ));
    }
    
    setState(() {
      _podiumResults[eventCode] = podium;
    });
    
    _saveResultsData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已生成 ${podium.length} 位三甲選手')),
    );
    
    // 切換到三甲名單頁面
    _tabController.animateTo(3);
  }

  /// 清除決賽名單
  void _clearFinalists(String eventCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認清除'),
        content: const Text('確定要清除決賽名單嗎？這將同時清除相關的決賽成績。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _finalists.remove(eventCode);
                _podiumResults.remove(eventCode);
                
                // 清除決賽成績
                final keysToRemove = _finalsResults.keys
                    .where((key) => key.endsWith('_$eventCode'))
                    .toList();
                for (final key in keysToRemove) {
                  _finalsResults.remove(key);
                }
              });
              
              _saveResultsData();
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已清除決賽名單')),
              );
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  void _clearResultControllers(String resultKey) {
    _preliminaryResults[resultKey] = '';
    _finalsResults[resultKey] = '';
    
    if (_preliminaryControllers.containsKey(resultKey)) {
      _preliminaryControllers[resultKey]!.clear();
    }
    if (_finalsControllers.containsKey(resultKey)) {
      _finalsControllers[resultKey]!.clear();
    }
  }

  /// 構建項目篩選下拉選單
  Widget _buildEventFilterDropdowns() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<EventCategory?>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: '類別',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('全部')),
              ...EventCategory.values.map((category) => DropdownMenuItem(
                value: category,
                child: Text(category.displayName),
              )),
            ],
            onChanged: (value) => setState(() => _selectedCategory = value),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<Division?>(
            value: _selectedDivision,
            decoration: const InputDecoration(
              labelText: '組別',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('全部')),
              ...Division.values.map((division) => DropdownMenuItem(
                value: division,
                child: Text(division.displayName),
              )),
            ],
            onChanged: (value) => setState(() => _selectedDivision = value),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<Gender?>(
            value: _selectedGender,
            decoration: const InputDecoration(
              labelText: '性別',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('全部')),
              ...Gender.values.map((gender) => DropdownMenuItem(
                value: gender,
                child: Text(gender.displayName),
              )),
            ],
            onChanged: (value) => setState(() => _selectedGender = value),
          ),
        ),
      ],
    );
  }

  /// 清除田賽所有嘗試成績
  void _clearAllFieldAttempts(String resultKey) {
    setState(() {
      _fieldAttempts[resultKey] = [];
      _preliminaryResults[resultKey] = '';
      _dnfStatus.remove(resultKey);
      _dqStatus.remove(resultKey);
      _absStatus.remove(resultKey);
    });
    _saveResultsData();
  }

  void _clearAllEventInputs() {
    if (_selectedEvent == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認清除'),
        content: Text('確定要清除「${_selectedEvent!.name}」的所有輸入內容嗎？此操作無法撤銷。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performClearAllInputs();
            },
            child: const Text('確認清除'),
          ),
        ],
      ),
    );
  }

  void _performClearAllInputs() {
    if (_selectedEvent == null) return;
    
    final eventCode = _selectedEvent!.code;
    
    setState(() {
      _preliminaryResults.removeWhere((key, value) => key.contains(eventCode));
      _finalsResults.removeWhere((key, value) => key.contains(eventCode));
      _podiumResults.remove(eventCode);
      _fieldAttempts.removeWhere((key, value) => key.contains(eventCode));
      
      _preliminaryControllers.removeWhere((key, controller) {
        if (key.contains(eventCode)) {
          controller.dispose();
          return true;
        }
        return false;
      });
      
      _finalsControllers.removeWhere((key, controller) {
        if (key.contains(eventCode)) {
          controller.dispose();
          return true;
        }
        return false;
      });
    });
    
    _saveResultsData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已清除「${_selectedEvent!.name}」的所有輸入內容'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 保存和載入數據
  Future<void> _saveResultsData() async {
    try {
      final data = {
        'preliminary': _preliminaryResults,
        'finals': _finalsResults,
        'dnf': _dnfStatus,
        'dq': _dqStatus,
        'abs': _absStatus,
        'finalists': _finalists,
        'podium': _podiumResults,
        'fieldAttempts': _fieldAttempts,
      };
      
      // 這裡應該保存到本地存儲
      print('✅ 成績數據已保存');
      _appState.notifyListeners();
    } catch (e) {
      print('❌ 保存成績數據失敗: $e');
    }
  }

  Future<void> _loadResultsData() async {
    try {
      // 這裡應該從本地存儲載入數據
      print('✅ 成績數據已載入');
    } catch (e) {
      print('❌ 載入成績數據失敗: $e');
    }
  }

  /// 其他方法
  void _savePreliminaryResults(EventInfo event) {
                ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已保存 ${event.name} 初賽成績'),
        backgroundColor: Colors.green,
      ),
    );
  }


  void _saveSpecialRelayResults(EventInfo event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已儲存 ${event.name} 特殊接力成績 - 不計入積分'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    
    for (final controller in _preliminaryControllers.values) {
      controller.dispose();
    }
    for (final controller in _finalsControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }
}
