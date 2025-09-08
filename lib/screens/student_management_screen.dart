/// 學生管理頁面
/// 學生資料登記、修改、查詢功能

import 'package:flutter/material.dart';
import '../models/student.dart';
import '../utils/responsive_helper.dart';
import '../utils/excel_helper.dart';
import '../utils/app_state.dart';
import '../widgets/student_dialogs.dart';
import '../widgets/common_app_bar.dart';
import '../services/user_service.dart';
import 'registration_management_screen.dart';

/// 學生管理頁面
class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _classController = TextEditingController();
  final _studentNumberController = TextEditingController();
  final _searchController = TextEditingController();
  
  final AppState _appState = AppState();
  
  Gender _selectedGender = Gender.male;
  Division _autoDivision = Division.primary;
  DateTime _selectedDate = DateTime.now();
  bool _isStaff = false;
  
  List<Student> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    _appState.initialize();
    _appState.addListener(_onAppStateChanged);
    _searchController.addListener(_filterStudents);
    _filterStudents();
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _nameController.dispose();
    _classController.dispose();
    _studentNumberController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      setState(() {
        _filterStudents();
      });
    }
  }

  void _filterStudents() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredStudents = _appState.students;
      } else {
        final query = _searchController.text.toLowerCase();
        _filteredStudents = _appState.students.where((student) {
          return student.name.toLowerCase().contains(query) ||
                 student.classId.toLowerCase().contains(query) ||
                 student.studentNumber.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ExtendedAppBar(
        title: '學生管理',
        subtitle: '已登記 ${_appState.students.length} 位學生',
        onRefresh: () => setState(() {}),
        actions: [
          if (_appState.hasSampleData) ...[
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearSampleData,
              tooltip: '清除樣本數據',
            ),
          ],
          // 🗑️ 清除所有學生功能 - 只有管理員可見
          if (UserService.hasPermission(UserPermissions.clearData) && _appState.students.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[300]!, width: 2),
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
                onPressed: _clearAllStudents,
                tooltip: '🗑️ 危險：清除所有學生數據',
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _downloadTemplate,
            tooltip: '下載CSV模板',
          ),
          if (UserService.hasPermission(UserPermissions.importData))
            IconButton(
              icon: const Icon(Icons.file_upload),
              onPressed: _importStudents,
              tooltip: '匯入學生',
            ),
          if (UserService.hasPermission(UserPermissions.exportData))
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportStudents,
              tooltip: '匯出學生名單',
            ),
        ],
      ),
      body: ResponsiveHelper.isMobile(context)
          ? _buildMobileLayout()
          : _buildDesktopLayout(),
    );
  }

  /// 手機版佈局
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatistics(),
          const SizedBox(height: 20),
          _buildStudentForm(),
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildStudentList(),
        ],
      ),
    );
  }

  /// 桌面版佈局
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        SizedBox(
          width: 400,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatistics(),
                const SizedBox(height: 20),
                _buildStudentForm(),
              ],
            ),
          ),
        ),
        const VerticalDivider(),
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildSearchBar(),
              ),
              Expanded(child: _buildStudentList()),
            ],
          ),
        ),
      ],
    );
  }

  /// 統計資料卡片
  Widget _buildStatistics() {
    final stats = _appState.getStudentStatistics();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '學生統計',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_appState.hasSampleData)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '包含樣本數據',
                      style: TextStyle(fontSize: 10, color: Colors.orange),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildCompactStatItem('總人數', stats['總人數'] ?? 0, Icons.people, Colors.blue),
                _buildCompactStatItem('工作人員', stats['工作人員'] ?? 0, Icons.work, Colors.orange),
                _buildCompactStatItem('男甲', stats['男子甲組'] ?? 0, Icons.male, Colors.red),
                _buildCompactStatItem('男乙', stats['男子乙組'] ?? 0, Icons.male, Colors.orange),
                _buildCompactStatItem('男丙', stats['男子丙組'] ?? 0, Icons.male, Colors.green),
                _buildCompactStatItem('女甲', stats['女子甲組'] ?? 0, Icons.female, Colors.red),
                _buildCompactStatItem('女乙', stats['女子乙組'] ?? 0, Icons.female, Colors.orange),
                _buildCompactStatItem('女丙', stats['女子丙組'] ?? 0, Icons.female, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatItem(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  /// 學生表單
  Widget _buildStudentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '新增學生',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '姓名',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入姓名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _classController,
                      decoration: const InputDecoration(
                        labelText: '班級 (如：1A)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '請輸入班級';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _studentNumberController,
                      decoration: const InputDecoration(
                        labelText: '學號',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '請輸入學號';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Gender>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: '性別',
                  border: OutlineInputBorder(),
                ),
                items: Gender.values.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '出生日期',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDivisionInfo()),
                ],
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('工作人員'),
                subtitle: const Text('負責運動會工作的學生'),
                value: _isStaff,
                onChanged: (value) {
                  setState(() {
                    _isStaff = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('新增學生'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 組別資訊顯示
  Widget _buildDivisionInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '自動分組',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            _autoDivision.displayName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            '基於出生年份: ${_selectedDate.year}',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// 搜尋欄
  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '搜尋學生姓名、班級或學號...',
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              )
            : null,
      ),
    );
  }

  /// 學生列表
  Widget _buildStudentList() {
    if (_filteredStudents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '尚無學生資料',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              '請新增學生或匯入學生名單',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 8,
        columns: const [
          DataColumn(label: Text('姓名', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('班級', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('學號', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('性別', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('組別', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('已報名項目', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('操作', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _filteredStudents.map((student) {
          return DataRow(
            cells: [
              DataCell(
                Row(
                  children: [
                    if (student.isStaff) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '工作人員',
                          style: TextStyle(fontSize: 8, color: Colors.orange),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        student.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text(student.classId)),
              DataCell(Text(student.studentNumber)),
              DataCell(Text(student.gender.displayName)),
              DataCell(Text(student.division.displayName)),
              DataCell(
                SizedBox(
                  width: 120,
                  child: Text(
                    student.registeredEvents.isNotEmpty
                        ? student.registeredEvents.join(', ')
                        : '未報名',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: student.registeredEvents.isNotEmpty 
                          ? Colors.blue 
                          : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.run_circle, color: Colors.blue),
                      onPressed: () => _manageRegistration(student),
                      tooltip: '管理報名',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.green),
                      onPressed: () => _editStudent(student),
                      tooltip: '編輯學生',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteStudent(student.id),
                      tooltip: '刪除學生',
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // 其餘方法實現...
  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _autoDivision = Division.fromBirthYear(picked.year);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final grade = Division.gradeFromClass(_classController.text);
      
      final student = Student(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        classId: _classController.text.toUpperCase(),
        studentNumber: _studentNumberController.text,
        gender: _selectedGender,
        division: _autoDivision,
        grade: grade,
        dateOfBirth: _selectedDate,
        isStaff: _isStaff,
        registeredEvents: [],
      );

      _appState.addStudent(student);
      _clearForm();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已新增學生：${student.name}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _classController.clear();
    _studentNumberController.clear();
    _selectedGender = Gender.male;
    _selectedDate = DateTime.now();
    _autoDivision = Division.fromBirthYear(DateTime.now().year);
    _isStaff = false;
  }

  void _manageRegistration(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationManagementScreen(student: student),
      ),
    );
  }

  void _editStudent(Student student) {
    showDialog(
      context: context,
      builder: (context) => EditStudentDialog(
        student: student,
        onStudentChanged: (updatedStudent) {
          _appState.updateStudent(updatedStudent);
        },
      ),
    );
  }

  void _deleteStudent(String studentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: const Text('確定要刪除此學生嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _appState.removeStudent(studentId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('學生已刪除'),
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

  void _clearSampleData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除樣本數據'),
        content: const Text('確定要清除所有樣本數據嗎？這將刪除6個範例學生。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _appState.clearSampleData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('樣本數據已清除'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }

  void _clearAllStudents() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 危險操作'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('確定要清除所有學生數據嗎？'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '此操作將會：',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('• 刪除所有 ${_appState.students.length} 位學生', style: TextStyle(color: Colors.red[600])),
                  Text('• 清除所有報名資料', style: TextStyle(color: Colors.red[600])),
                  Text('• 清除所有成績記錄', style: TextStyle(color: Colors.red[600])),
                  const SizedBox(height: 8),
                  Text(
                    '⚠️ 此操作無法復原！',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _performClearAllStudents();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: const Text('確認清除'),
          ),
        ],
      ),
    );
  }

  void _performClearAllStudents() {
    final studentCount = _appState.students.length;
    
    // 清除所有學生數據
    _appState.clearAllStudents();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ 已清除所有學生數據（$studentCount 位學生）'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _downloadTemplate() {
    ExcelHelper.generateImportTemplate();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV模板已下載'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _importStudents() {
    showDialog(
      context: context,
      builder: (context) => FileImportDialog(
        onStudentsImported: (students) {
          _appState.addStudents(students);
          
          // 強制刷新頁面
          setState(() {
            _filterStudents();
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('✅ 成功匯入 ${students.length} 位學生！數據已更新'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: '查看',
                textColor: Colors.white,
                onPressed: () {
                  _searchController.clear();
                  _filterStudents();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _exportStudents() {
    ExcelHelper.generateStudentExport(_appState.students);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('學生名單已匯出'),
        backgroundColor: Colors.green,
      ),
    );
  }
} 