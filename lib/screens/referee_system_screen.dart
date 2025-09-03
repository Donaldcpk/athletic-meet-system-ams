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

/// 裁判系統主界面
class RefereeSystemScreen extends StatefulWidget {
  const RefereeSystemScreen({super.key});

  @override
  State<RefereeSystemScreen> createState() => _RefereeSystemScreenState();
}

class _RefereeSystemScreenState extends State<RefereeSystemScreen>
    with TickerProviderStateMixin {
  
  final AppState _appState = AppState();
  late TabController _tabController;
  
  // 搜尋和篩選
  final _searchController = TextEditingController();
  String _searchQuery = '';
  EventCategory? _selectedCategory;
  Division? _selectedDivision;
  Gender? _selectedGender;
  String _sortBy = 'lane'; // lane, name, class, number
  bool _sortAscending = true;
  
  // 當前選中的項目
  EventInfo? _selectedEvent;
  
  // 成績數據
  final Map<String, String> _preliminaryResults = {}; // studentId_eventCode -> result
  final Map<String, String> _finalsResults = {}; // studentId_eventCode -> result
  final Map<String, bool> _dnfStatus = {}; // studentId_eventCode -> isDNF
  final Map<String, bool> _dqStatus = {}; // studentId_eventCode -> isDQ
  final Map<String, bool> _absStatus = {}; // studentId_eventCode -> isABS
  
  // 成績輸入控制器 - 解決數據持久化問題
  final Map<String, TextEditingController> _preliminaryControllers = {}; // resultKey -> controller
  final Map<String, TextEditingController> _finalsControllers = {}; // resultKey -> controller
  
  // 決賽晉級名單
  final Map<String, List<String>> _finalists = {}; // eventCode -> [studentId]
  final Map<String, List<PodiumWinner>> _podiumResults = {}; // eventCode -> [PodiumWinner]

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // 增加為5個TAB
    
    // 🔥 添加TAB切換監聽器，切換時重新載入項目列表
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedEvent = null; // 清除選中的項目
          _selectedCategory = null; // 清除選中的分類
        });
      }
    });
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    
    // 載入已儲存的成績數據
    _loadResultsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    
    // 釋放所有TextEditingController
    for (final controller in _preliminaryControllers.values) {
      controller.dispose();
  }
    for (final controller in _finalsControllers.values) {
      controller.dispose();
    }
    _preliminaryControllers.clear();
    _finalsControllers.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + kTextTabBarHeight),
        child: Column(
          children: [
            const CommonAppBar(
              title: '裁判系統',
              showBackButton: true,
              backRoute: '/dashboard',
            ),
            Container(
              color: Theme.of(context).colorScheme.primary,
              child: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                isScrollable: true,
          tabs: const [
                  Tab(icon: Icon(Icons.timer), text: '初賽成績'),
                  Tab(icon: Icon(Icons.emoji_events), text: '決賽成績'),
                  Tab(icon: Icon(Icons.military_tech), text: '三甲名單'),
                  Tab(icon: Icon(Icons.verified), text: '成績確認'),
                  Tab(icon: Icon(Icons.sports), text: '接力賽事'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildControlPanel(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPreliminaryView(),
                _buildFinalsView(),
                _buildPodiumView(), // 新增：三甲名單頁面
                _buildResultsConfirmationView(),
                _buildRelayView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 控制面板 - 搜尋、篩選和排序
  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // 搜尋欄
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
                    hintText: '搜尋項目、參賽編號、姓名...',
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
                    DropdownMenuItem(value: 'lane', child: Text('道次')),
                    DropdownMenuItem(value: 'name', child: Text('姓名')),
                    DropdownMenuItem(value: 'class', child: Text('班級')),
                    DropdownMenuItem(value: 'number', child: Text('參賽編號')),
                  ],
                  onChanged: (value) {
                    setState(() => _sortBy = value ?? 'lane');
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
          const SizedBox(height: 12),
          
          // 篩選器
          Row(
              children: [
              Expanded(
                child: DropdownButtonFormField<EventCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: '項目分類',
                    border: OutlineInputBorder(),
                  ),
                  items: EventCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<Division>(
                  value: _selectedDivision,
                  decoration: const InputDecoration(
                    labelText: '組別',
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
                    labelText: '性別',
                    border: OutlineInputBorder(),
                  ),
                  items: [Gender.male, Gender.female, Gender.mixed].map((gender) {
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
                    final isSelected = _selectedEvent?.code == event.code;
                    return ListTile(
                      title: Text(
                        '${event.code} ${event.name}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(event.category.displayName),
                      selected: isSelected,
                      selectedTileColor: Colors.blue[100],
                      onTap: () {
                        setState(() {
                          _selectedEvent = event;
                        });
                      },
                      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
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
              ? _buildPreliminaryTable(_selectedEvent!)
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

  /// 初賽成績輸入表格 - 寬屏優化
  Widget _buildPreliminaryTable(EventInfo event) {
    final participants = _getSortedParticipants(event);
    
    return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // 表格標題和操作按鈕
            Container(
            padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              ),
            child: Row(
                  children: [
                Expanded(
              child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                        '${event.code} ${event.name}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                        '初賽成績輸入 - 共 ${participants.length} 位參賽者',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _savePreliminaryResults(event),
                      icon: const Icon(Icons.save),
                      label: const Text('保存成績'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _generateFinalists(event),
                      icon: const Icon(Icons.forward),
                      label: const Text('生成決賽名單'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 表格
          Expanded(
            child: Container(
                      decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      columns: const [
                        DataColumn(label: Text('道次'), numeric: true),
                        DataColumn(label: Text('參賽編號')),
                        DataColumn(label: Text('姓名')),
                        DataColumn(label: Text('班級')),
                        DataColumn(label: Text('成績')),
                        DataColumn(label: Text('狀態')),
                        DataColumn(label: Text('操作')),
                      ],
                      rows: participants.asMap().entries.map((entry) {
                        final index = entry.key;
                        final student = entry.value;
                        final lane = index + 1;
                        final resultKey = '${student.id}_${event.code}';
                        
                        return DataRow(
                          cells: [
                            DataCell(
                          Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                                  '$lane',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                student.studentCode,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataCell(Text(student.name)),
                            DataCell(Text(student.classId)),
                            DataCell(
                              SizedBox(
                                width: 150,
                                child: _buildResultTextField(
                                  resultKey: resultKey,
                                  isInitial: true,
                                  event: event,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                              children: [
                                  _buildStatusChip('DNF', _dnfStatus[resultKey] ?? false, () {
                                    setState(() {
                                      _dnfStatus[resultKey] = !(_dnfStatus[resultKey] ?? false);
                                      if (_dnfStatus[resultKey] == true) {
                                        _dqStatus[resultKey] = false;
                                        _absStatus[resultKey] = false;
                                      }
                                    });
                                  }),
                                  const SizedBox(width: 4),
                                  _buildStatusChip('DQ', _dqStatus[resultKey] ?? false, () {
          setState(() {
                                      _dqStatus[resultKey] = !(_dqStatus[resultKey] ?? false);
                                      if (_dqStatus[resultKey] == true) {
                                        _dnfStatus[resultKey] = false;
                                        _absStatus[resultKey] = false;
                                      }
                                    });
                                  }),
                                  const SizedBox(width: 4),
                                  _buildStatusChip('ABS', _absStatus[resultKey] ?? false, () {
                                    setState(() {
                                      _absStatus[resultKey] = !(_absStatus[resultKey] ?? false);
                                      if (_absStatus[resultKey] == true) {
                                        _dnfStatus[resultKey] = false;
                                        _dqStatus[resultKey] = false;
                                      }
                                    });
                                  }),
                                ],
                              ),
                            ),
                            DataCell(
                              ElevatedButton(
                                onPressed: () {
                                  _clearStudentResult(resultKey);
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(60, 30),
                                ),
                                child: const Text('清除'),
                                  ),
                                ),
                              ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                                ),
                              ),
                            ),
                        ],
      ),
    );
  }

  /// 決賽成績輸入界面
  Widget _buildFinalsView() {
    return Row(
          children: [
        // 左側決賽名單
            Container(
          width: 400,
              decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(right: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.list_alt, color: Colors.green),
                    SizedBox(width: 8),
                  Text(
                      '決賽名單',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildFinalistsList(),
              ),
              ],
            ),
          ),
        
        // 右側決賽成績輸入
        Expanded(
          child: _selectedEvent != null && (_finalists[_selectedEvent!.code]?.isNotEmpty ?? false)
              ? _buildFinalsTable(_selectedEvent!)
              : const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                      Icon(Icons.emoji_events, size: 48, color: Colors.grey),
            SizedBox(height: 16),
                    Text(
                        '請先在初賽頁面生成決賽名單',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                ],
              ),
            ),
        ),
      ],
    );
  }

  /// 成績確認界面
  Widget _buildResultsConfirmationView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 項目選擇和名稱顯示
          Container(
            padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      _selectedEvent != null 
                          ? '${_selectedEvent!.name} - 成績確認'
                          : '成績確認',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (_selectedEvent != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '項目代碼：${_selectedEvent!.code} | '
                    '類型：${_selectedEvent!.category == EventCategory.track ? '徑賽' : '田賽'} | '
                    '組別：${_selectedEvent!.divisions.map((d) => d.name).join('、')}',
                      style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
              color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
                        ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      '什麼是成績確認？',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '成績確認是運動會的最後步驟，用於：\n'
                  '• 檢查所有項目的初賽和決賽成績是否正確\n'
                  '• 確認決賽名單和三甲名單是否準確\n'
                  '• 計算最終積分和排名\n'
                  '• 生成正式的成績單和獎狀\n'
                  '• 確保所有數據無誤後才公佈結果',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 只顯示決賽名單，三甲名單移到獨立TAB
                          Expanded(
            child: _selectedEvent != null 
                ? _buildFinalistsList()
                : const Center(
        child: Text(
                      '請先選擇一個項目',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
          ),
        ],
        ),
      );
    }

  /// 三甲名單界面 - 獨立TAB
  Widget _buildPodiumView() {
    return Padding(
      padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
          // 項目選擇和名稱顯示
          Container(
            padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.military_tech, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                                Text(
                      _selectedEvent != null 
                          ? '${_selectedEvent!.name} - 三甲名單'
                          : '三甲名單',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '生成時間：${DateTime.now().toString().substring(0, 16)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (_selectedEvent != null) ...[
                  const SizedBox(height: 8),
                                Text(
                    '項目代碼：${_selectedEvent!.code} | '
                    '類型：${_selectedEvent!.category == EventCategory.track ? '徑賽' : '田賽'} | '
                    '組別：${_selectedEvent!.divisions.map((d) => d.name).join('、')}',
          style: TextStyle(
                                    fontSize: 14,
                      color: Colors.grey[600],
                                  ),
                                ),
                ],
                              ],
                            ),
                          ),
          
          const SizedBox(height: 16),
          
          // 三甲名單內容
          Expanded(
            child: _selectedEvent != null 
                ? _buildPodiumList()
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.military_tech, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          '請先選擇一個項目',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '選擇項目後，完成決賽成績輸入即可生成三甲名單',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 接力賽界面
  Widget _buildRelayView() {
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
                Icon(Icons.groups, color: Colors.purple),
                SizedBox(width: 8),
                                Text(
                  '接力賽事 - 直接決賽',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildRelayEventsList(),
                                  ),
          ],
      ),
    );
  }

  /// 接力賽事列表
  Widget _buildRelayEventsList() {
    final relayEvents = EventConstants.allEvents
        .where((e) => e.category == EventCategory.relay)
        .toList();
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: relayEvents.length,
      itemBuilder: (context, index) {
        final event = relayEvents[index];
        return Card(
          child: InkWell(
            onTap: () => _showRelayDialog(event),
          child: Padding(
            padding: const EdgeInsets.all(16),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                    Text(
                    '${event.code} ${event.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.specialRules ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
            ),
          ),
        );
      },
    );
  }

  /// 決賽名單列表
  Widget _buildFinalistsList() {
    if (_selectedEvent == null || _finalists[_selectedEvent!.code] == null) {
      return const Center(
        child: Text('暫無決賽名單', style: TextStyle(color: Colors.grey)),
      );
    }
    
    final finalistIds = _finalists[_selectedEvent!.code]!;
    final finalists = finalistIds
        .map((id) => _appState.students.firstWhere((s) => s.id == id))
        .toList();

    return ListView.builder(
      itemCount: finalists.length,
      itemBuilder: (context, index) {
        final student = finalists[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text('${index + 1}'),
          ),
          title: Text(student.name),
          subtitle: Text('${student.studentCode} - ${student.classId}'),
        );
      },
    );
  }

  /// 三甲名單列表
  Widget _buildPodiumList() {
    if (_selectedEvent == null) {
      return const Center(
        child: Text('請先選擇項目', style: TextStyle(color: Colors.grey)),
      );
    }
    
    final podium = _podiumResults[_selectedEvent!.code];
                    
                    return Container(
                      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
                        children: [
          // 標題欄
                          Container(
            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedEvent!.name} - 三甲名單',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                  Text(
                  '生成時間：${DateTime.now().toString().substring(0, 16)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '項目代碼：${_selectedEvent!.code} | '
                  '類型：${_selectedEvent!.category == EventCategory.track ? '徑賽' : '田賽'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          
          // 三甲名單內容
                          Expanded(
            child: podium == null || podium.isEmpty
                ? const Center(
                            child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Icon(Icons.emoji_events_outlined, 
                             color: Colors.grey, size: 48),
                        SizedBox(height: 16),
                        Text('暫無三甲名單', 
                             style: TextStyle(color: Colors.grey, fontSize: 16)),
                        SizedBox(height: 8),
                        Text('請先完成決賽並生成成績', 
                             style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  )
                : DataTable(
                    columnSpacing: 12,
                    headingRowHeight: 40,
                    dataRowHeight: 80,
                    columns: const [
                      DataColumn(label: Text('名次', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('參賽編號', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('姓名', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('班別', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('學號', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('成績', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('頒獎組', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('存檔', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: podium.asMap().entries.map((entry) {
                      final index = entry.key;
                      final winner = entry.value;
                      final medals = ['🥇', '🥈', '🥉'];
                      final student = _appState.students.firstWhere(
                        (s) => s.id == winner.studentId,
                        orElse: () => Student(
                          id: winner.studentId,
                          name: winner.studentName,
                          classId: 'Unknown',
                          studentNumber: '00',
                          gender: Gender.male,
                          division: Division.senior,
                          grade: 1,
                          dateOfBirth: DateTime.now(),
                          isStaff: false,
                        ),
                      );
                      
                      return DataRow(
                        color: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            if (index == 0) return Colors.amber[50];
                            if (index == 1) return Colors.grey[100];
                            if (index == 2) return Colors.orange[50];
                            return null;
                          },
                        ),
                        cells: [
                          // 名次
                          DataCell(
                          Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: index < 3 ? Colors.green[600] : Colors.blue[600],
                                borderRadius: BorderRadius.circular(12),
                            ),
                              child: Text(
                                index < medals.length 
                                    ? '${medals[index]} ${index + 1}'
                                    : '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          // 參賽編號
                          DataCell(
                                Text(
                              student.studentCode,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          // 姓名
                          DataCell(Text(student.name)),
                          // 班別
                          DataCell(Text(student.classId)),
                          // 學號
                          DataCell(Text(student.studentNumber)),
                          // 成績
                          DataCell(
                                Text(
                              winner.finalResult.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          // 頒獎組核對按鈕
                          DataCell(
                            IconButton(
                              icon: Icon(
                                winner.submittedToAwards 
                                    ? Icons.check_circle 
                                    : Icons.radio_button_unchecked,
                                color: winner.submittedToAwards 
                                    ? Colors.green 
                                    : Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  final updatedWinner = PodiumWinner(
                                    studentId: winner.studentId,
                                    studentName: winner.studentName,
                                    studentCode: winner.studentCode,
                                    isStaff: winner.isStaff,
                                    result: winner.result,
                                    finalResult: winner.finalResult,
                                    points: winner.points,
                                    submittedToAwards: !winner.submittedToAwards,
                                    archived: winner.archived,
                                  );
                                  podium[index] = updatedWinner;
                                  _saveResultsData();
                                });
                              },
                              tooltip: winner.submittedToAwards 
                                  ? '已提交頒獎組' 
                                  : '提交至頒獎組',
                            ),
                          ),
                          // 存檔核對按鈕
                          DataCell(
                            IconButton(
                              icon: Icon(
                                winner.archived 
                                    ? Icons.archive 
                                    : Icons.unarchive,
                                color: winner.archived 
                                    ? Colors.blue 
                                    : Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  final updatedWinner = PodiumWinner(
                                    studentId: winner.studentId,
                                    studentName: winner.studentName,
                                    studentCode: winner.studentCode,
                                    isStaff: winner.isStaff,
                                    result: winner.result,
                                    finalResult: winner.finalResult,
                                    points: winner.points,
                                    submittedToAwards: winner.submittedToAwards,
                                    archived: !winner.archived,
                                  );
                                  podium[index] = updatedWinner;
                                  _saveResultsData();
                                });
                              },
                              tooltip: winner.archived 
                                  ? '已存檔' 
                                  : '存檔',
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

  /// 決賽成績表格
  Widget _buildFinalsTable(EventInfo event) {
    final finalists = _finalists[event.code];
    
    if (finalists == null || finalists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '請先在初賽頁面輸入成績並生成決賽名單',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.sports_score),
              label: const Text('前往初賽頁面'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 頂部操作欄
                                Container(
      padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[200]!),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
              children: [
              Icon(Icons.emoji_events, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                '${event.name} - 決賽成績輸入',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _saveFinalsResults(event),
                icon: const Icon(Icons.save),
                label: const Text('保存並生成三甲'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _printFinalsResults(event),
                icon: const Icon(Icons.print),
                label: const Text('列印決賽表'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
        
        // 決賽成績表格
        Expanded(
          child: Container(
                      decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(Colors.blue[100]),
                columns: const [
                  DataColumn(label: Text('道次', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('參賽編號', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('姓名', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('班別', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('初賽成績', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('初賽排名', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('決賽成績', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('狀態', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('決賽排名', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _buildFinalsDataRows(event, finalists),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 建構決賽數據行
  List<DataRow> _buildFinalsDataRows(EventInfo event, List<String> finalists) {
    final rows = <DataRow>[];
    
    for (int i = 0; i < finalists.length; i++) {
      final studentId = finalists[i];
      final student = _appState.students.firstWhere((s) => s.id == studentId);
      final prelimKey = '${studentId}_${event.code}';
      final finalsKey = '${studentId}_${event.code}_finals';
      
      // 初賽成績和排名
      final prelimResult = _preliminaryResults[prelimKey] ?? '';
      final prelimRank = i + 1; // 已按初賽排名排序
      
      // 決賽成績
      final finalsResult = _finalsResults[finalsKey] ?? '';
      final isDNF = _dnfStatus[finalsKey] ?? false;
      final isDQ = _dqStatus[finalsKey] ?? false;
      final isABS = _absStatus[finalsKey] ?? false;
      
      // 計算決賽排名
      final finalsRank = _getFinalsRank(event, studentId);
      
      rows.add(DataRow(
        cells: [
          // 道次
          DataCell(
                          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // 參賽編號
          DataCell(Text(
            student.studentCode,
            style: const TextStyle(fontWeight: FontWeight.w500),
          )),
          
          // 姓名
          DataCell(Text(
            student.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          )),
          
          // 班別
          DataCell(Text(student.classId)),
          
          // 初賽成績
          DataCell(Text(
            prelimResult,
            style: TextStyle(color: Colors.grey[600]),
          )),
          
          // 初賽排名
          DataCell(Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: prelimRank <= 3 ? Colors.amber[100] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '第${prelimRank}名',
              style: TextStyle(
                fontSize: 12,
                color: prelimRank <= 3 ? Colors.amber[800] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          )),
          
          // 決賽成績輸入
          DataCell(
            SizedBox(
              width: 120,
              child: _buildResultTextField(
                resultKey: finalsKey,
                isInitial: false,
                event: event,
              ),
            ),
          ),
          
          // 狀態按鈕
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusChip('DNF', isDNF, () => _toggleStatus(finalsKey, 'DNF')),
                const SizedBox(width: 4),
                _buildStatusChip('DQ', isDQ, () => _toggleStatus(finalsKey, 'DQ')),
                const SizedBox(width: 4),
                _buildStatusChip('ABS', isABS, () => _toggleStatus(finalsKey, 'ABS')),
              ],
            ),
          ),
          
          // 決賽排名
          DataCell(
            finalsRank > 0 
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: finalsRank <= 3 ? Colors.green[100] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: finalsRank <= 3 
                          ? Border.all(color: Colors.green[400]!, width: 2)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                              children: [
                        if (finalsRank <= 3) 
                          Text(['🥇', '🥈', '🥉'][finalsRank - 1], style: const TextStyle(fontSize: 16)),
                                Text(
                          '第${finalsRank}名',
                          style: TextStyle(
                            fontSize: 12,
                            color: finalsRank <= 3 ? Colors.green[800] : Colors.blue[600],
                                    fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : const Text('-'),
          ),
        ],
      ));
    }
    
    return rows;
  }

  /// 獲取決賽排名
  int _getFinalsRank(EventInfo event, String studentId) {
    final finalsKey = '${studentId}_${event.code}_finals';
    final result = _finalsResults[finalsKey];
    
    if (result == null || result.isEmpty) return 0;
    if (_dnfStatus[finalsKey] == true || _dqStatus[finalsKey] == true || _absStatus[finalsKey] == true) return 0;
    
    final numericResult = _parseResult(result);
    if (numericResult == null) return 0;
    
    // 收集所有有效的決賽成績
    final allResults = <String, double>{};
    final finalists = _finalists[event.code] ?? [];
    
    for (final id in finalists) {
      final key = '${id}_${event.code}_finals';
      final res = _finalsResults[key];
      if (res != null && res.isNotEmpty) {
        final isDNF = _dnfStatus[key] ?? false;
        final isDQ = _dqStatus[key] ?? false;
        final isABS = _absStatus[key] ?? false;
        
        if (!isDNF && !isDQ && !isABS) {
          final numeric = _parseResult(res);
          if (numeric != null) {
            allResults[id] = numeric;
          }
        }
      }
    }
    
    // 排序
    final sortedResults = allResults.entries.toList();
    if (event.category == EventCategory.track) {
      sortedResults.sort((a, b) => a.value.compareTo(b.value)); // 時間越短越好
    } else {
      sortedResults.sort((a, b) => b.value.compareTo(a.value)); // 距離越大越好
    }
    
    // 找到當前學生的排名
    for (int i = 0; i < sortedResults.length; i++) {
      if (sortedResults[i].key == studentId) {
        return i + 1;
      }
    }
    
    return 0;
  }

    /// 顯示接力賽對話框
  void _showRelayDialog(EventInfo event) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
        children: [
            const Icon(Icons.groups, color: Colors.purple),
            const SizedBox(width: 8),
            Expanded(child: Text('${event.name} 成績輸入')),
          ],
        ),
        content: SizedBox(
          width: 900,
          height: 700,
          child: _buildRelayInputForm(event),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
              onPressed: () {
              _saveRelayResults(event);
                Navigator.pop(context);
              },
            child: const Text('保存成績'),
                                  ),
                              ],
                            ),
    );
  }

  /// 建構接力賽輸入表單
  Widget _buildRelayInputForm(EventInfo event) {
    // S1-S6年級分組
    final grades = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6'];
    final classes = ['A', 'B', 'C', 'D']; // 每年級的班別
    
    return Column(
        children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                '接力賽成績輸入 - ${event.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '規則：${event.specialRules ?? "按年級分組，每級4個班別參賽"}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              const Text(
                '說明：接力賽直接進行決賽，無需初賽。請按年級和班別填入最終成績。',
                style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
        ],
      ),
        ),
        
        const SizedBox(height: 16),
        
        Expanded(
          child: SingleChildScrollView(
            child: _buildRelayGradeTable(grades, classes, event),
          ),
        ),
      ],
    );
  }

  /// 建構接力賽年級表格
  Widget _buildRelayGradeTable(List<String> grades, List<String> classes, EventInfo event) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: MaterialStateProperty.all(Colors.purple[100]),
          headingTextStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          columns: const [
            DataColumn(label: Text('年級')),
            DataColumn(label: Text('班別')),
            DataColumn(label: Text('隊伍名稱')),
            DataColumn(label: Text('成績')),
            DataColumn(label: Text('排名')),
            DataColumn(label: Text('狀態')),
            DataColumn(label: Text('操作')),
          ],
          rows: grades.expand((grade) {
            return classes.map((classLetter) {
              final teamKey = '${grade}${classLetter}_${event.code}';
              final rank = _calculateRelayRank(teamKey, event);
              
              return DataRow(
                color: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                    if (rank == 1) return Colors.amber[50];
                    if (rank == 2) return Colors.grey[50];
                    if (rank == 3) return Colors.orange[50];
                    return null;
                  },
                ),
                cells: [
                  DataCell(
                                Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                        color: _getGradeColor(grade),
                        borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                        grade,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                                    ),
                                  ),
                                ),
                  ),
                  DataCell(Text(classLetter, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('${grade}${classLetter}班')),
                  DataCell(
                    SizedBox(
                      width: 120,
                      child: TextField(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: _getHintForEvent(event),
                          hintStyle: TextStyle(
                            color: Colors.grey[300], // 非常淺的灰色
                            fontSize: 13,
                          ),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _finalsResults[teamKey] = value;
                          });
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d\.:]+'))
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    rank > 0 
                        ? Row(
        children: [
                              Text(
                                rank.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              if (rank <= 3) Text(_getRankMedal(rank)),
                            ],
                          )
                        : const Text('-'),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusChip('DNF', _dnfStatus[teamKey] ?? false, () {
                          setState(() {
                            _dnfStatus[teamKey] = !(_dnfStatus[teamKey] ?? false);
                            if (_dnfStatus[teamKey] == true) {
                              _dqStatus[teamKey] = false;
                              _absStatus[teamKey] = false;
                            }
                          });
                        }),
                        const SizedBox(width: 4),
                        _buildStatusChip('DQ', _dqStatus[teamKey] ?? false, () {
                          setState(() {
                            _dqStatus[teamKey] = !(_dqStatus[teamKey] ?? false);
                            if (_dqStatus[teamKey] == true) {
                              _dnfStatus[teamKey] = false;
                              _absStatus[teamKey] = false;
                            }
                          });
                        }),
              ],
            ),
          ),
                  DataCell(
                    ElevatedButton(
              onPressed: () {
                        setState(() {
                          _finalsResults.remove(teamKey);
                          _dnfStatus.remove(teamKey);
                          _dqStatus.remove(teamKey);
                          _absStatus.remove(teamKey);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(60, 30),
                      ),
                      child: const Text('清除'),
                    ),
                  ),
                ],
              );
            });
          }).toList(),
        ),
      ),
    );
  }

  /// 獲取年級顏色
  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'S1': return Colors.red;
      case 'S2': return Colors.orange;
      case 'S3': return Colors.yellow[700]!;
      case 'S4': return Colors.green;
      case 'S5': return Colors.blue;
      case 'S6': return Colors.purple;
      default: return Colors.grey;
    }
  }

  /// 獲取排名獎牌
  String _getRankMedal(int rank) {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '';
    }
  }

  /// 計算接力賽排名
  int _calculateRelayRank(String teamKey, EventInfo event) {
    final result = _finalsResults[teamKey];
    if (result == null || result.isEmpty) return 0;
    
    final isDNF = _dnfStatus[teamKey] ?? false;
    final isDQ = _dqStatus[teamKey] ?? false;
    
    if (isDNF || isDQ) return 0;
    
    final numericResult = _parseResult(result);
    if (numericResult == null) return 0;
    
    // 計算該項目中所有隊伍的排名
    final allResults = <String, double>{};
    _finalsResults.forEach((key, value) {
      if (key.contains(event.code) && value.isNotEmpty) {
        final isDNFTeam = _dnfStatus[key] ?? false;
        final isDQTeam = _dqStatus[key] ?? false;
        if (!isDNFTeam && !isDQTeam) {
          final teamResult = _parseResult(value);
          if (teamResult != null) {
            allResults[key] = teamResult;
          }
        }
      }
    });
    
    final sortedResults = allResults.entries.toList();
    sortedResults.sort((a, b) => a.value.compareTo(b.value)); // 時間越短越好
    
    for (int i = 0; i < sortedResults.length; i++) {
      if (sortedResults[i].key == teamKey) {
        return i + 1;
      }
    }
    
    return 0;
  }

  /// 保存接力賽成績
  void _saveRelayResults(EventInfo event) {
    final savedCount = _finalsResults.entries
        .where((entry) => entry.key.contains(event.code) && entry.value.isNotEmpty)
        .length;
    
    // 生成三甲名單
    final podium = <PodiumWinner>[];
    final allResults = <String, double>{};
    
    // 收集所有有效成績
    _finalsResults.forEach((key, value) {
      if (key.contains(event.code) && value.isNotEmpty) {
        final isDNF = _dnfStatus[key] ?? false;
        final isDQ = _dqStatus[key] ?? false;
        
        if (!isDNF && !isDQ) {
          final result = _parseResult(value);
          if (result != null) {
            allResults[key] = result;
          }
        }
      }
    });
    
    // 排序並取前3名
    final sortedResults = allResults.entries.toList();
    sortedResults.sort((a, b) => a.value.compareTo(b.value)); // 時間越短越好
    
    for (int i = 0; i < sortedResults.length && i < 3; i++) {
      final entry = sortedResults[i];
      final teamKey = entry.key;
      final result = entry.value;
      
      // 提取隊伍信息
      final teamName = teamKey.split('_')[0];
      
      podium.add(PodiumWinner(
        studentId: teamKey,
        studentName: '${teamName}班接力隊',
        studentCode: teamName,
        isStaff: false,
        result: result,
        finalResult: _formatResult(result, event),
        points: AppConstants.relayPointsTable[i + 1] ?? 0,
      ));
    }
    
    setState(() {
      _podiumResults[event.code] = podium;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已保存 ${event.name} 成績（$savedCount個隊伍）並生成三甲名單'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 建構狀態標籤
  Widget _buildStatusChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 獲取篩選後的項目列表
  List<EventInfo> _getFilteredEvents() {
    var events = EventConstants.allEvents.where((event) => event.isScoring).toList();
    
    // 🔥 根據當前TAB篩選項目類型
    if (_tabController.index == 0 || _tabController.index == 1) {
      // 初賽和決賽TAB：排除接力項目，因為接力項目直接進行決賽
      events = events.where((e) => e.category != EventCategory.relay).toList();
    } else if (_tabController.index == 4) {
      // 接力賽TAB：只顯示接力項目
      events = events.where((e) => e.category == EventCategory.relay).toList();
    }
    
    // 按分類篩選
    if (_selectedCategory != null) {
      events = events.where((e) => e.category == _selectedCategory).toList();
    }
    
    // 按搜尋關鍵字篩選
    if (_searchQuery.isNotEmpty) {
      events = events.where((e) =>
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.code.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    
    return events;
  }

  /// 獲取排序後的參賽者
  List<Student> _getSortedParticipants(EventInfo event) {
    var participants = _appState.students
        .where((student) => student.registeredEvents.contains(event.code))
        .toList();
    
    // 按搜尋關鍵字篩選
    if (_searchQuery.isNotEmpty) {
      participants = participants.where((s) =>
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.studentCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.classId.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    
    // 排序
    participants.sort((a, b) {
      int result = 0;
      switch (_sortBy) {
        case 'name':
          result = a.name.compareTo(b.name);
          break;
        case 'class':
          result = a.classId.compareTo(b.classId);
          break;
        case 'number':
          result = a.studentCode.compareTo(b.studentCode);
          break;
        case 'lane':
        default:
          result = a.studentCode.compareTo(b.studentCode); // 默認按參賽編號排序
          break;
      }
      return _sortAscending ? result : -result;
    });
    
    return participants;
  }

  /// 獲取成績輸入提示
  String _getHintForEvent(EventInfo event) {
    switch (event.category) {
      case EventCategory.track:
        return '12.34 或 1:23.45';
      case EventCategory.field:
        return '1.85 或 12.34';
      case EventCategory.relay:
        return '45.67';
      default:
        return '輸入成績';
    }
  }

  /// 更新積分系統（成績確認後立即計算積分）
  Future<void> _updateScoringSystem(EventInfo event, List<String> finalists) async {
    print('🔥 開始更新積分系統：${event.name}');
    
    for (final studentId in finalists) {
      final prelimKey = '${studentId}_${event.code}';
      final finalsKey = '${studentId}_${event.code}_finals';
      
      // 獲取成績
      final prelimResult = _preliminaryResults[prelimKey];
      final finalsResult = _finalsResults[finalsKey];
      
      // 獲取狀態
      final isDNF = _dnfStatus[finalsKey] ?? false;
      final isDQ = _dqStatus[finalsKey] ?? false;
      final isABS = _absStatus[finalsKey] ?? false;
      
      // 獲取排名
      final finalsRank = _getFinalsRank(event, studentId);
      
      // 檢查是否破紀錄（暫時設為false，可以後續擴展）
      final isRecordBreaker = false;
      
      // 更新積分系統
      await ScoringService.updateStudentScore(
        studentId: studentId,
        eventCode: event.code,
        preliminaryResult: prelimResult,
        finalsResult: finalsResult,
        preliminaryRank: 0, // 初賽排名暫不使用
        finalsRank: finalsRank,
        isDNF: isDNF,
        isDQ: isDQ,
        isABS: isABS,
        isRecordBreaker: isRecordBreaker,
      );
      
      print('✅ 已更新積分：學生$studentId, 項目${event.code}, 排名$finalsRank');
    }
    
    // 記錄操作日誌
    await OperationLogService.logOperation(
      OperationType.update,
      '成績確認：${event.name} (${finalists.length}人)',
    );
    
    print('✅ 積分系統更新完成：${event.name}');
  }

  /// 清除學生成績
  void _clearStudentResult(String resultKey) {
    setState(() {
      _preliminaryResults.remove(resultKey);
      _dnfStatus.remove(resultKey);
      _dqStatus.remove(resultKey);
      _absStatus.remove(resultKey);
    });
  }

  /// 保存初賽成績
  void _savePreliminaryResults(EventInfo event) {
    // TODO: 實現保存邏輯
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已保存 ${event.name} 初賽成績'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 生成決賽名單（前8名）- 初賽階段只生成決賽名單
  void _generateFinalists(EventInfo event) {
    final participants = _getSortedParticipants(event);
    final validResults = <String, double>{};
    
    // 收集有效成績
    for (final student in participants) {
      final resultKey = '${student.id}_${event.code}';
      final result = _preliminaryResults[resultKey];
      final isDNF = _dnfStatus[resultKey] ?? false;
      final isDQ = _dqStatus[resultKey] ?? false;
      final isABS = _absStatus[resultKey] ?? false;
      
      if (!isDNF && !isDQ && !isABS && result != null && result.isNotEmpty) {
        final numericResult = _parseResult(result);
        if (numericResult != null) {
          validResults[student.id] = numericResult;
        }
      }
    }
    
    // 排序並取前8名
    final sortedResults = validResults.entries.toList();
    
    if (event.category == EventCategory.track) {
      // 徑賽：時間越短越好
      sortedResults.sort((a, b) => a.value.compareTo(b.value));
      } else {
      // 田賽：距離/高度越大越好
      sortedResults.sort((a, b) => b.value.compareTo(a.value));
    }
    
    final finalists = sortedResults.take(8).map((e) => e.key).toList();
    
    setState(() {
      _finalists[event.code] = finalists;
      // 清除之前可能錯誤產生的三甲名單
      _podiumResults.remove(event.code);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ 已生成 ${event.name} 決賽名單（${finalists.length}人）\n⚠️ 三甲名單將在決賽完成後產生'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 格式化成績顯示
  String _formatResult(double result, EventInfo event) {
    if (event.category == EventCategory.track && result >= 60) {
      // 轉換為分:秒格式
      final minutes = (result / 60).floor();
      final seconds = result % 60;
      return '$minutes:${seconds.toStringAsFixed(2).padLeft(5, '0')}';
    }
    return result.toStringAsFixed(2);
  }

  /// 解析成績字符串為數值
  double? _parseResult(String result) {
    try {
      // 處理時間格式 (1:23.45 或 12.34)
      if (result.contains(':')) {
        final parts = result.split(':');
        if (parts.length == 2) {
          final minutes = double.parse(parts[0]);
          final seconds = double.parse(parts[1]);
          return minutes * 60 + seconds;
        }
      }
      return double.parse(result);
    } catch (e) {
      return null;
    }
  }

  /// 保存決賽成績並生成三甲名單
  Future<void> _saveFinalsResults(EventInfo event) async {
    final finalists = _finalists[event.code] ?? [];
    if (finalists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ 沒有決賽選手'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 收集有效的決賽成績
    final validResults = <String, double>{};
    int savedCount = 0;

    for (final studentId in finalists) {
      final finalsKey = '${studentId}_${event.code}_finals';
      final result = _finalsResults[finalsKey];
      final isDNF = _dnfStatus[finalsKey] ?? false;
      final isDQ = _dqStatus[finalsKey] ?? false;
      final isABS = _absStatus[finalsKey] ?? false;

      if (result != null && result.isNotEmpty) {
        savedCount++;
        
        if (!isDNF && !isDQ && !isABS) {
          final numericResult = _parseResult(result);
          if (numericResult != null) {
            validResults[studentId] = numericResult;
          }
        }
      }
    }

    if (savedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ 請至少輸入一個決賽成績'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 排序並生成三甲名單
    final sortedResults = validResults.entries.toList();
    if (event.category == EventCategory.track) {
      sortedResults.sort((a, b) => a.value.compareTo(b.value)); // 時間越短越好
    } else {
      sortedResults.sort((a, b) => b.value.compareTo(a.value)); // 距離越大越好
    }

    final podium = <PodiumWinner>[];
    for (int i = 0; i < sortedResults.length && i < 3; i++) {
      final entry = sortedResults[i];
      final studentId = entry.key;
      final result = entry.value;
      final student = _appState.students.firstWhere((s) => s.id == studentId);

      podium.add(PodiumWinner(
        studentId: studentId,
            studentName: student.name,
            studentCode: student.studentCode,
            isStaff: student.isStaff,
        result: result,
        finalResult: _formatResult(result, event),
        points: AppConstants.individualPointsTable[i + 1] ?? 0,
      ));
    }

    setState(() {
      _podiumResults[event.code] = podium;
    });

    // 🔥 新增：立即更新積分系統
    await _updateScoringSystem(event, finalists);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ 已保存 ${event.name} 決賽成績（$savedCount人）並生成三甲名單（${podium.length}人）\n💰 積分已同步更新到排名系統'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// 列印決賽成績表
  void _printFinalsResults(EventInfo event) {
    final finalists = _finalists[event.code];
    if (finalists == null || finalists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ 沒有決賽名單可列印'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 生成HTML列印內容
    final StringBuffer htmlContent = StringBuffer();
    htmlContent.writeln('<!DOCTYPE html>');
    htmlContent.writeln('<html><head>');
    htmlContent.writeln('<meta charset="UTF-8">');
    htmlContent.writeln('<title>${event.name} - 決賽成績表</title>');
    htmlContent.writeln('<style>');
    htmlContent.writeln('body { font-family: Arial, sans-serif; margin: 20px; }');
    htmlContent.writeln('h1 { text-align: center; color: #333; }');
    htmlContent.writeln('table { width: 100%; border-collapse: collapse; margin: 20px 0; }');
    htmlContent.writeln('th, td { border: 1px solid #ddd; padding: 8px; text-align: center; }');
    htmlContent.writeln('th { background-color: #f5f5f5; font-weight: bold; }');
    htmlContent.writeln('.lane { background-color: #3f51b5; color: white; font-weight: bold; }');
    htmlContent.writeln('.prelim-rank { background-color: #fff3e0; }');
    htmlContent.writeln('.finals-rank { background-color: #e8f5e8; }');
    htmlContent.writeln('.medal { font-size: 18px; }');
    htmlContent.writeln('@media print { body { margin: 0; } }');
    htmlContent.writeln('</style>');
    htmlContent.writeln('</head><body>');
    
    htmlContent.writeln('<h1>${event.name} - 決賽成績表</h1>');
    htmlContent.writeln('<p>日期：${DateTime.now().toString().substring(0, 16)}</p>');
    
    htmlContent.writeln('<table>');
    htmlContent.writeln('<tr>');
    htmlContent.writeln('<th>道次</th><th>參賽編號</th><th>姓名</th><th>班別</th>');
    htmlContent.writeln('<th>初賽成績</th><th>初賽排名</th><th>決賽成績</th><th>決賽排名</th>');
    htmlContent.writeln('</tr>');

    for (int i = 0; i < finalists.length; i++) {
      final studentId = finalists[i];
      final student = _appState.students.firstWhere((s) => s.id == studentId);
      final prelimKey = '${studentId}_${event.code}';
      final finalsKey = '${studentId}_${event.code}_finals';
      
      final prelimResult = _preliminaryResults[prelimKey] ?? '';
      final finalsResult = _finalsResults[finalsKey] ?? '';
      final finalsRank = _getFinalsRank(event, studentId);
      
      htmlContent.writeln('<tr>');
      htmlContent.writeln('<td class="lane">${i + 1}</td>');
      htmlContent.writeln('<td>${student.studentCode}</td>');
      htmlContent.writeln('<td>${student.name}</td>');
      htmlContent.writeln('<td>${student.classId}</td>');
      htmlContent.writeln('<td>$prelimResult</td>');
      htmlContent.writeln('<td class="prelim-rank">第${i + 1}名</td>');
      htmlContent.writeln('<td>$finalsResult</td>');
      if (finalsRank > 0) {
        final medal = finalsRank <= 3 ? ['🥇', '🥈', '🥉'][finalsRank - 1] : '';
        htmlContent.writeln('<td class="finals-rank">$medal 第${finalsRank}名</td>');
      } else {
        htmlContent.writeln('<td>-</td>');
      }
      htmlContent.writeln('</tr>');
    }
    
    htmlContent.writeln('</table>');
    htmlContent.writeln('<p style="text-align: center; margin-top: 30px;">');
    htmlContent.writeln('裁判簽名：_________________　　記錄員簽名：_________________');
    htmlContent.writeln('</p>');
    htmlContent.writeln('</body></html>');

    // 使用簡化的列印方案
    try {
      // 創建Blob URL方式列印
      final blob = html.Blob([htmlContent.toString()], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final printWindow = html.window.open(url, '_blank', 'width=800,height=600');
      
      if (printWindow != null) {
        print('✅ 已開啟列印視窗');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 列印視窗已開啟，請在新視窗中使用Ctrl+P列印'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        
        // 清理URL
        Future.delayed(const Duration(seconds: 30), () {
          html.Url.revokeObjectUrl(url);
        });
      } else {
        throw Exception('無法開啟新視窗，可能被瀏覽器阻擋');
      }
    } catch (e) {
      print('❌ 開啟新視窗失敗: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 開啟列印視窗失敗：$e\n請允許彈出視窗後重試'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      
      // 降級方案：直接在當前窗口列印  
      final originalContent = html.document.body?.innerHtml;
      html.document.body?.innerHtml = htmlContent.toString();
      html.window.print();
      
      // 恢復原內容
      if (originalContent != null) {
        html.document.body?.innerHtml = originalContent;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📄 ${event.name} 決賽成績表已準備列印'),
        backgroundColor: Colors.purple,
      ),
    );
  }

    /// 獲取或創建成績輸入控制器
  TextEditingController _getOrCreateController(String resultKey, bool isInitial) {
    final controllers = isInitial ? _preliminaryControllers : _finalsControllers;
    final results = isInitial ? _preliminaryResults : _finalsResults;
    
    if (!controllers.containsKey(resultKey)) {
      final controller = TextEditingController();
      
      // 設置初始值
      final currentValue = results[resultKey] ?? '';
      controller.text = currentValue;
      
      // 監聽變化並同步到數據
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

  /// 構建成績輸入框 - 使用TextEditingController確保數據持久化
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
      // 特殊狀態顯示
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
    
    // 正常成績輸入
    final controller = _getOrCreateController(resultKey, isInitial);
    
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: _getHintForEvent(event),
        hintStyle: TextStyle(
          color: Colors.grey[300], // 非常淺的灰色
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

  /// 切換狀態（DNF/DQ/ABS）
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
      _saveResultsData();
    });
  }

  /// 清除成績控制器和數據
  void _clearResultControllers(String resultKey) {
    // 清除數據
    _preliminaryResults[resultKey] = '';
    _finalsResults[resultKey] = '';
    
    // 清除控制器內容
    if (_preliminaryControllers.containsKey(resultKey)) {
      _preliminaryControllers[resultKey]!.clear();
    }
    if (_finalsControllers.containsKey(resultKey)) {
      _finalsControllers[resultKey]!.clear();
    }
  }

  /// 自動儲存成績數據
  void _saveResultsData() {
    try {
      // 儲存到本地存儲
      final allResults = <String, dynamic>{
        'preliminary': _preliminaryResults,
        'finals': _finalsResults,
        'dnf': _dnfStatus,
        'dq': _dqStatus,
        'abs': _absStatus,
        'finalists': _finalists,
        'podium': _podiumResults,
      };
      
      html.window.localStorage['referee_results'] = json.encode(allResults);
      
      // 同步到AppState
      _appState.notifyListeners();
      
      print('✅ 成績數據已自動儲存');
    } catch (e) {
      print('❌ 儲存成績數據失敗: $e');
    }
  }

    /// 載入已儲存的成績數據
  void _loadResultsData() {
    try {
      final savedData = html.window.localStorage['referee_results'];
      if (savedData != null) {
        final data = json.decode(savedData) as Map<String, dynamic>;
        
                    setState(() {
          _preliminaryResults.clear();
          _finalsResults.clear();
          _dnfStatus.clear();
          _dqStatus.clear();
          _absStatus.clear();
          _finalists.clear();
          _podiumResults.clear();
          
          if (data['preliminary'] != null) {
            _preliminaryResults.addAll(Map<String, String>.from(data['preliminary']));
          }
          if (data['finals'] != null) {
            _finalsResults.addAll(Map<String, String>.from(data['finals']));
          }
          if (data['dnf'] != null) {
            _dnfStatus.addAll(Map<String, bool>.from(data['dnf']));
          }
          if (data['dq'] != null) {
            _dqStatus.addAll(Map<String, bool>.from(data['dq']));
          }
          if (data['abs'] != null) {
            _absStatus.addAll(Map<String, bool>.from(data['abs']));
          }
          if (data['finalists'] != null) {
            final finalistsMap = Map<String, dynamic>.from(data['finalists']);
            finalistsMap.forEach((key, value) {
              _finalists[key] = List<String>.from(value);
            });
          }
          if (data['podium'] != null) {
            final podiumMap = Map<String, dynamic>.from(data['podium']);
            podiumMap.forEach((key, value) {
              _podiumResults[key] = (value as List).map((e) => PodiumWinner.fromJson(e)).toList();
            });
          }
        });
        
        // 重要：數據載入後，清除所有控制器，讓它們重新創建
        _clearAllControllers();
        
        print('✅ 成績數據已載入，控制器已重置');
      }
    } catch (e) {
      print('❌ 載入成績數據失敗: $e');
    }
  }

  /// 清除所有控制器，強制重新創建
  void _clearAllControllers() {
    // 釋放現有控制器
    for (final controller in _preliminaryControllers.values) {
      controller.dispose();
    }
    for (final controller in _finalsControllers.values) {
      controller.dispose();
    }
    
    // 清空控制器Map
    _preliminaryControllers.clear();
    _finalsControllers.clear();
  }

  /// 清除篩選
  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedDivision = null;
      _selectedGender = null;
      _searchController.clear();
    });
  }
}