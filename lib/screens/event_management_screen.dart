/// 項目管理頁面
/// 運動項目設置、報名統計、臨時項目管理

import 'package:flutter/material.dart';
import '../models/student.dart';
import '../constants/event_constants.dart';
import '../utils/app_state.dart';
import '../widgets/add_event_dialog.dart';
import '../widgets/common_app_bar.dart';

/// 項目管理頁面
class EventManagementScreen extends StatefulWidget {
  final List<Student> students;
  final Function(List<Student>)? onStudentsChanged;

  const EventManagementScreen({
    super.key,
    required this.students,
    this.onStudentsChanged,
  });

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  final _searchController = TextEditingController();
  final AppState _appState = AppState();
  
  String _searchQuery = '';
  EventCategory _selectedCategory = EventCategory.track;
  final _expandedStates = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onAppStateChanged);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _searchController.dispose();
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
      appBar: CommonAppBar(
        title: '運動項目管理',
        showBackButton: true,
        backRoute: '/dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: _showEventCodeMapping,
            tooltip: '項目代碼對照表',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: _showAddEventDialog,
            tooltip: '新增臨時項目',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showStatistics,
            tooltip: '統計資訊',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndCategorySelector(),
          _buildOverallSummary(),
          Expanded(
            child: _buildEventStructure(),
          ),
        ],
      ),
    );
  }

  /// 搜尋和類別選擇器
  Widget _buildSearchAndCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜尋項目或學生...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: EventCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 總體統計摘要
  Widget _buildOverallSummary() {
    final allEvents = _appState.getAllEvents();
    final totalEvents = allEvents.length;
    final customEventsCount = _appState.customEvents.length;
    final totalRegistrations = _getTotalRegistrations();
    final averagePerEvent = totalEvents > 0 ? totalRegistrations / totalEvents : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('項目總數', '$totalEvents', Icons.sports, 
                  subtitle: customEventsCount > 0 ? '含${customEventsCount}個臨時項目' : null),
              _buildSummaryItem('報名人次', '$totalRegistrations', Icons.people),
              _buildSummaryItem('平均報名', averagePerEvent.toStringAsFixed(1), Icons.trending_up),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, {String? subtitle}) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ],
    );
  }

  /// 主要的事件結構顯示
  Widget _buildEventStructure() {
    final events = _getFilteredEvents();
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '沒有找到符合條件的項目',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showAddEventDialog,
              icon: const Icon(Icons.add),
              label: const Text('新增臨時項目'),
            ),
          ],
        ),
      );
    }

    // 按項目名稱分組
    final groupedEvents = <String, List<EventInfo>>{};
    for (final event in events) {
      groupedEvents.putIfAbsent(event.name, () => []).add(event);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedEvents.keys.length,
      itemBuilder: (context, index) {
        final eventName = groupedEvents.keys.elementAt(index);
        final eventVariants = groupedEvents[eventName]!;
        return _buildEventGroup(eventName, eventVariants);
      },
    );
  }

  /// 構建項目組（例如：100m下的不同組別）
  Widget _buildEventGroup(String eventName, List<EventInfo> variants) {
    final isExpanded = _expandedStates[eventName] ?? false;
    final totalParticipants = _getTotalParticipantsForEvents(variants);
    final isCustomEvent = variants.any((v) => _appState.customEvents.contains(v));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedStates[eventName] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(variants.first.category),
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              eventName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isCustomEvent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '臨時',
                                  style: TextStyle(fontSize: 10, color: Colors.orange),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${variants.length}個組別，共$totalParticipants人報名',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildParticipantsBadge(totalParticipants),
                  const SizedBox(width: 8),
                  if (isCustomEvent) ...[
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _deleteCustomEvent(variants.first),
                      tooltip: '刪除臨時項目',
                    ),
                  ],
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(),
            ...variants.map((event) => _buildEventDetails(event)),
          ],
        ],
      ),
    );
  }

  /// 構建單個項目詳情（例如：甲組男子100m）
  Widget _buildEventDetails(EventInfo event) {
    final participants = _getParticipantsForEvent(event.code);
    final shouldDirectFinals = _appState.shouldUseDirectFinals(event.code);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getGenderColor(event.genders.first),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${event.divisions.map((d) => d.displayName).join('/')} ${event.genders.first.displayName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.code,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              if (shouldDirectFinals) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '直接決賽',
                    style: TextStyle(fontSize: 10, color: Colors.blue),
                  ),
                ),
              ],
              if (!event.isScoring) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '不計分',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${participants.length}人',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (participants.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: participants.map((student) => _buildStudentChip(student)).toList(),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    '尚無學生報名',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 構建學生標籤（顯示學生編號）
  Widget _buildStudentChip(Student student) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: student.isStaff ? Colors.orange[100] : Colors.blue[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: student.isStaff ? Colors.orange : Colors.blue,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (student.isStaff) ...[
            const Icon(Icons.work, size: 12, color: Colors.orange),
            const SizedBox(width: 4),
          ],
          Text(
            '${student.name} (${student.studentCode})',
            style: TextStyle(
              fontSize: 12,
              color: student.isStaff ? Colors.orange[800] : Colors.blue[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 獲取篩選後的事件
  List<EventInfo> _getFilteredEvents() {
    List<EventInfo> events = _appState.getAllEvents();
    
    // 按分類篩選
    events = events.where((event) => event.category == _selectedCategory).toList();
    
    // 按搜尋詞篩選
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      events = events.where((event) {
        return event.name.toLowerCase().contains(query) ||
               event.code.toLowerCase().contains(query) ||
               _getParticipantsForEvent(event.code).any((student) =>
                 student.name.toLowerCase().contains(query) ||
                 student.classId.toLowerCase().contains(query) ||
                 student.studentCode.toLowerCase().contains(query));
      }).toList();
    }
    
    return events;
  }

  /// 獲取項目參與者
  List<Student> _getParticipantsForEvent(String eventCode) {
    return _appState.students.where((student) =>
      student.registeredEvents.contains(eventCode)).toList();
  }

  /// 獲取多個項目的總參與人數
  int _getTotalParticipantsForEvents(List<EventInfo> events) {
    final Set<String> studentIds = {};
    for (final event in events) {
      for (final student in _getParticipantsForEvent(event.code)) {
        studentIds.add(student.id);
      }
    }
    return studentIds.length;
  }

  /// 獲取總報名人次
  int _getTotalRegistrations() {
    return _appState.students.fold(0, (sum, student) => sum + student.registeredEvents.length);
  }

  /// 顯示新增項目對話框
  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEventDialog(
        onEventAdded: (event) {
          _appState.addCustomEvent(event);
        },
      ),
    );
  }

  /// 刪除自定義項目
  void _deleteCustomEvent(EventInfo event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除臨時項目「${event.name} (${event.code})」嗎？\n\n注意：已報名此項目的學生將被自動取消報名。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 先取消所有學生對此項目的報名
              for (final student in _appState.students) {
                if (student.registeredEvents.contains(event.code)) {
                  final updatedEvents = List<String>.from(student.registeredEvents);
                  updatedEvents.remove(event.code);
                  final updatedStudent = student.copyWith(registeredEvents: updatedEvents);
                  _appState.updateStudent(updatedStudent);
                }
              }
              
              // 刪除自定義項目
              _appState.removeCustomEvent(event.code);
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已刪除臨時項目：${event.name}'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  /// 顯示統計資訊
  void _showStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('項目統計'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._buildStatisticsContent(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatisticsContent() {
    final eventStats = _appState.getEventStatistics();
    final classStats = _appState.getClassStatistics();
    
    return [
      // 項目統計
      const Text('項目統計', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...eventStats.entries.map((entry) => 
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(entry.key),
            Text('${entry.value}'),
          ],
        ),
      ),
      const SizedBox(height: 16),
      
      // 班級統計（前5名）
      const Text('報名最多的班級', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
             ...(classStats.entries
           .toList()
           ..sort((a, b) => b.value.totalRegistrations.compareTo(a.value.totalRegistrations))
           ..take(5))
           .map((entry) => 
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(entry.key),
                 Text('${entry.value.totalRegistrations}人次'),
               ],
             ),
           ),
    ];
  }

  /// 獲取分類圖標
  IconData _getCategoryIcon(EventCategory category) {
    switch (category) {
      case EventCategory.track:
        return Icons.directions_run;
      case EventCategory.field:
        return Icons.sports_baseball;
      case EventCategory.relay:
        return Icons.group;
      case EventCategory.special:
        return Icons.star;
    }
  }

  /// 獲取性別顏色
  Color _getGenderColor(Gender gender) {
    switch (gender) {
      case Gender.male:
        return Colors.blue;
      case Gender.female:
        return Colors.pink;
      case Gender.mixed:
        return Colors.purple;
    }
  }

  /// 構建參與者徽章
  Widget _buildParticipantsBadge(int count) {
    Color color;
    if (count == 0) {
      color = Colors.grey;
    } else if (count <= 4) {
      color = Colors.orange;
    } else if (count <= 8) {
      color = Colors.blue;
    } else {
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 顯示項目代碼對照表
  void _showEventCodeMapping() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.table_chart, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '運動項目代碼對照表',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildMappingSection('甲組女子項目 (中5-6)', EventConstants.seniorFemaleEvents_G),
                      _buildMappingSection('乙組女子項目 (中3-4)', EventConstants.juniorFemaleEvents_G),
                      _buildMappingSection('丙組女子項目 (中1-2)', EventConstants.primaryFemaleEvents_G),
                      _buildMappingSection('甲組男子項目 (中5-6)', EventConstants.seniorMaleEvents_B),
                      _buildMappingSection('乙組男子項目 (中3-4)', EventConstants.juniorMaleEvents_B),
                      _buildMappingSection('丙組男子項目 (中1-2)', EventConstants.primaryMaleEvents_B),
                      _buildMappingSection('班際接力項目', EventConstants.classRelayEvents),
                      _buildMappingSection('社制接力項目', EventConstants.societyRelayEvents),
                      _buildMappingSection('特殊接力項目', EventConstants.specialRelayEvents),
                      _buildMappingSection('公開項目', EventConstants.openEvents),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.info, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '共 ${EventConstants.allEvents.length} 個項目',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 建立對照表區段
  Widget _buildMappingSection(String title, List<EventInfo> events) {
    if (events.isEmpty) return const SizedBox.shrink();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 12),
            Table(
              border: TableBorder.all(color: Colors.grey[300]!),
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFFF5F5F5)),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('代碼', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('項目名稱', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('類型', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                ...events.map((event) => TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        event.code,
                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w500),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(event.name),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(event.category),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.category.displayName,
                          style: const TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ),
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

  /// 獲取類別顏色
  Color _getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.track:
        return Colors.green;
      case EventCategory.field:
        return Colors.orange;
      case EventCategory.relay:
        return Colors.blue;
      case EventCategory.special:
        return Colors.purple;
    }
  }
} 