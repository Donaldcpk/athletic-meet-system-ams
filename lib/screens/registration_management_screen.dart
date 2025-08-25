/// 報名項目管理頁面
/// 提供學生項目報名管理功能

import 'package:flutter/material.dart';
import '../models/student.dart';
import '../constants/event_constants.dart';
import '../utils/responsive_helper.dart';
import '../utils/app_state.dart';

/// 驗證結果類
class ValidationResult {
  final bool isValid;
  final String message;
  
  ValidationResult(this.isValid, this.message);
}

/// 報名項目管理頁面
class RegistrationManagementScreen extends StatefulWidget {
  final Student student;

  const RegistrationManagementScreen({
    super.key,
    required this.student,
  });

  @override
  State<RegistrationManagementScreen> createState() => _RegistrationManagementScreenState();
}

class _RegistrationManagementScreenState extends State<RegistrationManagementScreen> {
  late Student _student;
  List<EventInfo> _availableEvents = [];
  List<EventInfo> _registeredEvents = [];
  EventCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _loadAvailableEvents();
    _loadRegisteredEvents();
  }

  /// 載入可報名項目
  void _loadAvailableEvents() {
    _availableEvents = EventConstants.getAvailableEvents(
      _student.division,
      _student.gender,
    );
  }

  /// 載入已報名項目
  void _loadRegisteredEvents() {
    _registeredEvents = _student.registeredEvents
        .map((eventCode) => EventConstants.findByCode(eventCode))
        .where((event) => event != null)
        .cast<EventInfo>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_student.name} - 報名管理'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ResponsiveHelper.isMobile(context)
          ? _buildMobileLayout()
          : _buildDesktopLayout(),
    );
  }

  /// 手機版佈局
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildStudentInfo(),
        _buildSearchAndFilter(),
        Expanded(child: _buildEventTabs()),
      ],
    );
  }

  /// 桌面版佈局
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        SizedBox(
          width: 350,
          child: Column(
            children: [
              _buildStudentInfo(),
              _buildRegistrationSummary(),
            ],
          ),
        ),
        const VerticalDivider(),
        Expanded(
          child: Column(
            children: [
              _buildSearchAndFilter(),
              Expanded(child: _buildEventTabs()),
            ],
          ),
        ),
      ],
    );
  }

  /// 建立學生資訊卡片
  Widget _buildStudentInfo() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getDivisionColor(_student.division),
                  child: Text(
                    _student.name.substring(0, 1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _student.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${_student.classId} | ${_student.gender.displayName} | ${_student.division.displayName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_student.isStaff)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '工作人員',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '已報名項目：${_registeredEvents.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// 建立報名統計摘要
  Widget _buildRegistrationSummary() {
    final trackEvents = _registeredEvents.where((e) => e.category == EventCategory.track).length;
    final fieldEvents = _registeredEvents.where((e) => e.category == EventCategory.field).length;
    final relayEvents = _registeredEvents.where((e) => e.category == EventCategory.relay).length;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '報名統計',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('徑賽項目', trackEvents, 2, Colors.blue),
            _buildSummaryRow('田賽項目', fieldEvents, 2, Colors.green),
            _buildSummaryRow('接力項目', relayEvents, 1, Colors.orange),
            const Divider(),
            _buildSummaryRow('總計', _registeredEvents.length, 3, Colors.purple),
          ],
        ),
      ),
    );
  }

  /// 建立統計行
  Widget _buildSummaryRow(String label, int current, int max, Color color) {
    final isOverLimit = current > max;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Text(
                '$current/$max',
                style: TextStyle(
                  color: isOverLimit ? Colors.red : color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                height: 8,
                child: LinearProgressIndicator(
                  value: (current / max).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(
                    isOverLimit ? Colors.red : color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 建立搜尋和篩選
  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: '搜尋項目...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('全部', null),
                _buildCategoryChip('徑賽', EventCategory.track),
                _buildCategoryChip('田賽', EventCategory.field),
                _buildCategoryChip('接力', EventCategory.relay),
                _buildCategoryChip('特殊', EventCategory.special),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 建立分類籌碼
  Widget _buildCategoryChip(String label, EventCategory? category) {
    final isSelected = _selectedCategory == category;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
      ),
    );
  }

  /// 建立項目標籤頁
  Widget _buildEventTabs() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add_circle), text: '可報名項目'),
              Tab(icon: Icon(Icons.list), text: '已報名項目'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAvailableEventsList(),
                _buildRegisteredEventsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 建立可報名項目列表
  Widget _buildAvailableEventsList() {
    final filteredEvents = _getFilteredEvents(_availableEvents);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        final isRegistered = _student.registeredEvents.contains(event.code);
        
        return _buildEventCard(
          event,
          isRegistered: isRegistered,
          onTap: isRegistered ? null : () => _registerForEvent(event),
          trailing: isRegistered 
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.add_circle_outline),
        );
      },
    );
  }

  /// 建立已報名項目列表
  Widget _buildRegisteredEventsList() {
    final filteredEvents = _getFilteredEvents(_registeredEvents);
    
    if (filteredEvents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('尚未報名任何項目'),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        
        return _buildEventCard(
          event,
          isRegistered: true,
          onTap: () => _unregisterFromEvent(event),
          trailing: const Icon(Icons.remove_circle_outline, color: Colors.red),
        );
      },
    );
  }

  /// 建立項目卡片
  Widget _buildEventCard(
    EventInfo event, {
    required bool isRegistered,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(event.category),
          child: Icon(
            _getCategoryIcon(event.category),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          event.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isRegistered ? Colors.green[700] : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${event.category.displayName} | ${event.code}',
              style: const TextStyle(fontSize: 12),
            ),
            if (event.specialRules != null)
              Text(
                event.specialRules!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: trailing,
        onTap: onTap,
        enabled: onTap != null,
      ),
    );
  }

  /// 報名項目
  void _registerForEvent(EventInfo event) {
    // 先檢查報名規則
    final validationResult = _validateRegistration(event);
    if (!validationResult.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationResult.message),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認報名'),
        content: Text('確定要報名「${event.name}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _student = _student.copyWith(
                  registeredEvents: [..._student.registeredEvents, event.code],
                );
                _loadRegisteredEvents();
              });

              // 🔥 關鍵修復：更新全局狀態
              AppState().updateStudent(_student);
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已報名「${event.name}」'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  /// 取消報名項目
  void _unregisterFromEvent(EventInfo event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消報名'),
        content: Text('確定要取消報名「${event.name}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final updatedEvents = _student.registeredEvents.toList();
                updatedEvents.remove(event.code);
                _student = _student.copyWith(registeredEvents: updatedEvents);
                _loadRegisteredEvents();
              });

              // 🔥 關鍵修復：更新全局狀態
              AppState().updateStudent(_student);
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已取消報名「${event.name}」'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  /// 驗證報名規則
  ValidationResult _validateRegistration(EventInfo event) {
    // 檢查性別匹配
    if (!event.genders.contains(_student.gender) && !event.genders.contains(Gender.mixed)) {
      return ValidationResult(false, '性別不符：此項目不允許${_student.gender.displayName}參加');
    }

    // 檢查組別匹配  
    if (!event.divisions.contains(_student.division)) {
      return ValidationResult(false, '組別不符：此項目不允許${_student.division.displayName}參加');
    }

    // 檢查是否已報名
    if (_student.registeredEvents.contains(event.code)) {
      return ValidationResult(false, '已報名此項目');
    }

    final currentEvents = _student.registeredEvents
        .map((code) => EventConstants.findByCode(code))
        .where((e) => e != null)
        .cast<EventInfo>()
        .toList();

    // 檢查總項目數限制
    final individualEvents = currentEvents.where((e) => 
      e.category == EventCategory.track || e.category == EventCategory.field).length;
    if (event.category == EventCategory.track || event.category == EventCategory.field) {
      if (individualEvents >= 3) {
        return ValidationResult(false, '個人項目已達上限（3項）');
      }
    }

    // 檢查田賽/徑賽組合限制
    final trackEvents = currentEvents.where((e) => e.category == EventCategory.track).length;
    final fieldEvents = currentEvents.where((e) => e.category == EventCategory.field).length;
    
    if (event.category == EventCategory.track) {
      if (trackEvents >= 2) {
        return ValidationResult(false, '徑賽項目已達上限（2項）');
      }
    } else if (event.category == EventCategory.field) {
      if (fieldEvents >= 2) {
        return ValidationResult(false, '田賽項目已達上限（2項）');
      }
    }

    // 班際接力無數量限制
    // 根據香港中學運動會規則，接力項目（包含班際接力）不設報名上限

    return ValidationResult(true, '可以報名');
  }

  /// 篩選項目
  List<EventInfo> _getFilteredEvents(List<EventInfo> events) {
    var filtered = events;

    // 按分類篩選
    if (_selectedCategory != null) {
      filtered = filtered.where((e) => e.category == _selectedCategory).toList();
    }

    // 按搜尋關鍵字篩選
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((e) =>
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.code.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return filtered;
  }

  /// 獲取組別顏色
  Color _getDivisionColor(Division division) {
    switch (division) {
      case Division.senior:
        return Colors.red;
      case Division.junior:
        return Colors.orange;
      case Division.primary:
        return Colors.green;
    }
  }

  /// 獲取分類顏色
  Color _getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.track:
        return Colors.blue;
      case EventCategory.field:
        return Colors.green;
      case EventCategory.relay:
        return Colors.orange;
      case EventCategory.special:
        return Colors.purple;
    }
  }

  /// 獲取分類圖標
  IconData _getCategoryIcon(EventCategory category) {
    switch (category) {
      case EventCategory.track:
        return Icons.directions_run;
      case EventCategory.field:
        return Icons.sports_tennis;
      case EventCategory.relay:
        return Icons.group;
      case EventCategory.special:
        return Icons.star;
    }
  }
} 