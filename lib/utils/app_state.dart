/// 全局應用狀態管理
/// 確保所有數據在頁面切換時不會丟失

import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../models/referee_models.dart';
import '../constants/event_constants.dart';
import '../constants/app_constants.dart';
import '../services/storage_service.dart';

/// 應用狀態管理器
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // 學生數據
  List<Student> _students = [];
  List<Student> get students => List.unmodifiable(_students);

  // 裁判計分表數據
  Map<String, RefereeScoreSheet> _scoreSheets = {};
  Map<String, RefereeScoreSheet> get scoreSheets => Map.unmodifiable(_scoreSheets);

  // 自定義項目
  List<EventInfo> _customEvents = [];
  List<EventInfo> get customEvents => List.unmodifiable(_customEvents);

  // 是否已加載樣本數據
  bool _hasSampleData = false;
  bool get hasSampleData => _hasSampleData;

  // 自動儲存定時器
  // Timer? _autoSaveTimer;

  /// 初始化應用狀態
  Future<void> initialize() async {
    try {
      // 首先嘗試從本地存儲加載數據
      await _loadFromStorage();
      
      // 如果沒有存儲的數據，則加載樣本數據
      if (_students.isEmpty) {
        _loadSampleData();
        await _saveData(); // 保存樣本數據
      }
      
      _initializeScoreSheets();
      print('✅ 應用狀態初始化完成');
    } catch (e) {
      print('❌ 初始化失敗: $e');
      _loadSampleData(); // 失敗時加載樣本數據
      _initializeScoreSheets();
    }
  }

  /// 加載樣本數據
  void _loadSampleData() {
    final sampleStudents = [
      Student(
        id: 'sample_001',
        name: '陳大明',
        classId: '1A',
        studentNumber: '01',
        gender: Gender.male,
        division: Division.primary,
        grade: 1,
        dateOfBirth: DateTime(2013, 3, 15),
        isStaff: false,
        registeredEvents: ['BC100', 'BCLJ'], // 丙組男子100m, 跳遠
      ),
      Student(
        id: 'sample_002',
        name: '李小華',
        classId: '1A',
        studentNumber: '02',
        gender: Gender.female,
        division: Division.primary,
        grade: 1,
        dateOfBirth: DateTime(2013, 5, 20),
        isStaff: false,
        registeredEvents: ['GC100', 'GC200'], // 丙組女子100m, 200m
      ),
      Student(
        id: 'sample_003',
        name: '王志豪',
        classId: '3B',
        studentNumber: '03',
        gender: Gender.male,
        division: Division.junior,
        grade: 3,
        dateOfBirth: DateTime(2011, 8, 12),
        isStaff: true,
        registeredEvents: ['BB100', 'BBHJ'], // 乙組男子100m, 跳高
      ),
      Student(
        id: 'sample_004',
        name: '林美美',
        classId: '3B',
        studentNumber: '04',
        gender: Gender.female,
        division: Division.junior,
        grade: 3,
        dateOfBirth: DateTime(2011, 12, 8),
        isStaff: false,
        registeredEvents: ['GB100', 'GB400', 'GBHJ'], // 乙組女子100m, 400m, 跳高
      ),
      Student(
        id: 'sample_005',
        name: '張強強',
        classId: '6A',
        studentNumber: '05',
        gender: Gender.male,
        division: Division.senior,
        grade: 6,
        dateOfBirth: DateTime(2009, 4, 25),
        isStaff: false,
        registeredEvents: ['BA100', 'BAJT'], // 甲組男子100m, 標槍
      ),
      Student(
        id: 'sample_006',
        name: '黃雅雅',
        classId: '5C',
        studentNumber: '06',
        gender: Gender.female,
        division: Division.senior,
        grade: 5,
        dateOfBirth: DateTime(2009, 11, 3),
        isStaff: false,
        registeredEvents: ['GAJT', 'GALJ', 'GASP'], // 甲組女子標槍, 跳遠, 鉛球
      ),
    ];

    _students = sampleStudents;
    _hasSampleData = true;
    notifyListeners();
  }

  /// 初始化裁判計分表
  void _initializeScoreSheets() {
    _scoreSheets = {
      'overall': _createScoreSheet('overall', null, Gender.mixed),
      'preliminary': _createScoreSheet('preliminary', null, Gender.mixed),
      'finals': _createScoreSheet('finals', null, Gender.mixed),
      'podium': _createScoreSheet('podium', null, Gender.mixed),
    };
  }

  /// 創建計分表
  RefereeScoreSheet _createScoreSheet(String id, Division? division, Gender gender) {
    final filteredStudents = division == null 
        ? _students
        : _students.where((s) => s.division == division).toList();

    final studentRecords = filteredStudents.map((student) {
      final eventResults = <String, EventCompetitionRecord>{};
      
      // 為每個已報名項目創建空白成績記錄
      for (final eventCode in student.registeredEvents) {
        eventResults[eventCode] = EventCompetitionRecord(eventCode: eventCode);
      }

      return StudentEventRecord(
        studentId: student.id,
        studentName: student.name,
        classId: student.classId,
        studentNumber: student.studentNumber,
        isStaff: student.isStaff,
        eventResults: eventResults,
      );
    }).toList();

    return RefereeScoreSheet(
      id: id,
      division: division,
      gender: gender,
      createdAt: DateTime.now(),
      studentRecords: studentRecords,
    );
  }

  /// 添加學生
  void addStudent(Student student) {
    _students.add(student);
    _updateScoreSheets();
    _saveData();
    notifyListeners();
  }

  /// 更新學生
  void updateStudent(Student updatedStudent) {
    final index = _students.indexWhere((s) => s.id == updatedStudent.id);
    if (index != -1) {
      _students[index] = updatedStudent;
      _updateScoreSheets();
      _saveData();
      notifyListeners();
    }
  }

  /// 刪除學生
  void removeStudent(String studentId) {
    _students.removeWhere((s) => s.id == studentId);
    _updateScoreSheets();
    _saveData();
    notifyListeners();
  }

  /// 批量添加學生
  void addStudents(List<Student> newStudents) {
    _students.addAll(newStudents);
    _updateScoreSheets();
    _saveData();
    notifyListeners();
  }

  /// 刪除所有樣本數據
  void clearSampleData() {
    _students.removeWhere((student) => student.id.startsWith('sample_'));
    _hasSampleData = false;
    _updateScoreSheets();
    _saveData();
    notifyListeners();
  }

  /// 清空所有學生數據
  void clearAllStudents() {
    _students.clear();
    _hasSampleData = false;
    _updateScoreSheets();
    _saveData();
    notifyListeners();
  }

  /// 根據ID獲取學生
  Student? getStudent(String id) {
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 更新學生報名項目
  void updateStudentRegistration(String studentId, List<String> eventCodes) {
    final student = getStudent(studentId);
    if (student != null) {
      final updatedStudent = student.copyWith(registeredEvents: eventCodes);
      updateStudent(updatedStudent);
    }
  }

  /// 添加自定義項目
  void addCustomEvent(EventInfo event) {
    _customEvents.add(event);
    _saveData();
    notifyListeners();
  }

  /// 移除自定義項目
  void removeCustomEvent(String eventCode) {
    _customEvents.removeWhere((e) => e.code == eventCode);
    _saveData();
    notifyListeners();
  }

  /// 獲取所有項目（包括自定義項目）
  List<EventInfo> getAllEvents() {
    return [...EventConstants.allEvents, ..._customEvents];
  }

  /// 更新裁判計分表
  void updateScoreSheet(String key, RefereeScoreSheet sheet) {
    _scoreSheets[key] = sheet;
    _saveData();
    notifyListeners();
  }

  /// 重新生成所有計分表
  void _updateScoreSheets() {
    _initializeScoreSheets();
  }

  /// 獲取學生統計
  Map<String, int> getStudentStatistics() {
    final stats = <String, int>{};
    
    for (final division in Division.values) {
      for (final gender in [Gender.male, Gender.female]) {
        final count = _students.where((s) => 
          s.division == division && s.gender == gender).length;
        final key = '${gender.displayName}${division.displayName}';
        stats[key] = count;
      }
    }
    
    stats['總人數'] = _students.length;
    stats['工作人員'] = _students.where((s) => s.isStaff).length;
    
    return stats;
  }

  /// 獲取項目統計
  Map<String, int> getEventStatistics() {
    final stats = <String, int>{};
    final allRegistrations = _students.expand((s) => s.registeredEvents).toList();
    
    stats['總報名人次'] = allRegistrations.length;
    
    for (final category in EventCategory.values) {
      final categoryEvents = EventConstants.filterEvents(category: category);
      final categoryRegistrations = allRegistrations.where((code) =>
        categoryEvents.any((e) => e.code == code)).length;
      stats[category.displayName] = categoryRegistrations;
    }
    
    return stats;
  }

  /// 檢查項目是否需要直接決賽
  bool shouldUseDirectFinals(String eventCode) {
    final participants = _students.where((s) => s.registeredEvents.contains(eventCode)).length;
    final eventInfo = EventConstants.findByCode(eventCode) ?? _customEvents.firstWhere(
      (e) => e.code == eventCode,
      orElse: () => throw Exception('Event not found: $eventCode'),
    );
    
    // 接力比賽或參賽人數≤8人直接決賽
    return eventInfo.isClassRelay || participants <= AppConstants.directFinalsThreshold;
  }

  /// 獲取項目參賽學生
  List<Student> getEventParticipants(String eventCode) {
    return _students.where((s) => s.registeredEvents.contains(eventCode)).toList();
  }

  /// 獲取班級統計
  Map<String, ClassStats> getClassStatistics() {
    final classStats = <String, ClassStats>{};
    
    for (final student in _students) {
      final classId = student.classId;
      if (!classStats.containsKey(classId)) {
        classStats[classId] = ClassStats(classId: classId);
      }
      
      final stats = classStats[classId]!;
      stats.addStudent(student);
    }
    
    return classStats;
  }

  /// 從本地存儲加載數據
  Future<void> _loadFromStorage() async {
    try {
      // 加載學生數據
      final loadedStudents = StorageService.loadStudents();
      if (loadedStudents.isNotEmpty) {
        _students = loadedStudents;
        _hasSampleData = loadedStudents.any((s) => s.id.startsWith('sample_'));
        print('✅ 從本地存儲加載 ${_students.length} 位學生');
      }
      
      // TODO: 加載其他數據（成績、決賽名單等）
      
      notifyListeners();
    } catch (e) {
      print('❌ 從存儲加載數據失敗: $e');
    }
  }

  /// 儲存數據到本地存儲
  Future<void> _saveData() async {
    try {
      // 保存學生數據
      await StorageService.saveStudents(_students);
      
      // TODO: 保存其他數據（成績、決賽名單等）
      
      print('✅ 數據已保存到本地存儲 - ${DateTime.now()}');
    } catch (e) {
      print('❌ 保存數據失敗: $e');
    }
  }

  /// 手動保存數據
  Future<void> saveData() async {
    await _saveData();
  }

  /// 獲取存儲統計信息
  Map<String, dynamic> getStorageStats() {
    return StorageService.getStorageStats();
  }

  /// 導出所有數據
  String exportAllData() {
    return StorageService.exportAllData();
  }

  /// 導入數據
  Future<bool> importData(String jsonData) async {
    try {
      final success = await StorageService.importAllData(jsonData);
      if (success) {
        await _loadFromStorage();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ 導入數據失敗: $e');
      return false;
    }
  }

  /// 清除所有存儲數據
  Future<void> clearAllStorageData() async {
    await StorageService.clearAllData();
    reset();
  }

  // /// 開始自動儲存
  // void _startAutoSave() {
  //   _autoSaveTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
  //     _saveData();
  //   });
  // }

  /// 重置所有數據
  void reset() {
    _students.clear();
    _scoreSheets.clear();
    _customEvents.clear();
    _hasSampleData = false;
    // _autoSaveTimer?.cancel();
    initialize();
    notifyListeners();
  }

  @override
  void dispose() {
    // _autoSaveTimer?.cancel();
    super.dispose();
  }
}

/// 班級統計類
class ClassStats {
  final String classId;
  int totalStudents = 0;
  int staffCount = 0;
  int maleCount = 0;
  int femaleCount = 0;
  int totalRegistrations = 0;
  int totalPoints = 0;

  ClassStats({required this.classId});

  void addStudent(Student student) {
    totalStudents++;
    if (student.isStaff) staffCount++;
    if (student.gender == Gender.male) {
      maleCount++;
    } else {
      femaleCount++;
    }
    totalRegistrations += student.registeredEvents.length;
    
    // 計算班級總分（包括工作人員獎勵分）
    totalPoints += AppConstants.calculateStaffBonus(student.isStaff);
  }

  /// 獲取班級編號樣式
  String get displayName => classId;
  
  /// 平均報名項目數
  double get averageRegistrations => totalStudents > 0 ? totalRegistrations / totalStudents : 0;
} 