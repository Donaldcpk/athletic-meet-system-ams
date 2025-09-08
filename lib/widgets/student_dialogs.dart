/// 學生相關對話框組件
/// 包含編輯學生資料和文件匯入功能

import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../models/student.dart';
import '../utils/excel_helper.dart';
import '../constants/event_constants.dart';

/// 編輯學生對話框
class EditStudentDialog extends StatefulWidget {
  final Student student;
  final Function(Student) onStudentChanged;

  const EditStudentDialog({
    super.key,
    required this.student,
    required this.onStudentChanged,
  });

  @override
  State<EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<EditStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _classController;
  late TextEditingController _studentNumberController;
  late TextEditingController _eventCodeController;
  
  late Gender _selectedGender;
  late Division _selectedDivision;
  late bool _isStaff;
  late DateTime _selectedDate;
  late List<String> _registeredEvents;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.name);
    _classController = TextEditingController(text: widget.student.classId);
    _studentNumberController = TextEditingController(text: widget.student.studentNumber);
    _eventCodeController = TextEditingController();
    
    _selectedGender = widget.student.gender;
    _selectedDivision = widget.student.division;
    _isStaff = widget.student.isStaff;
    _selectedDate = widget.student.dateOfBirth;
    _registeredEvents = List.from(widget.student.registeredEvents);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('編輯學生 - ${widget.student.name}'),
      content: SizedBox(
        width: 500,
        height: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 基本資料
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '學生姓名',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '請輸入學生姓名';
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
                          labelText: '班級',
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
                  items: Gender.values.map((gender) => DropdownMenuItem(
                    value: gender,
                    child: Text(gender.displayName),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedGender = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Division>(
                  value: _selectedDivision,
                  decoration: const InputDecoration(
                    labelText: '組別',
                    border: OutlineInputBorder(),
                  ),
                  items: Division.values.map((division) => DropdownMenuItem(
                    value: division,
                    child: Text(division.displayName),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedDivision = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('工作人員'),
                  value: _isStaff,
                  onChanged: (value) {
                    setState(() => _isStaff = value ?? false);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '出生日期',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 已報名項目管理
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '已報名項目 (${_registeredEvents.length})',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _showAddEventDialog,
                              tooltip: '新增項目',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_registeredEvents.isEmpty)
                          const Text('尚未報名任何項目')
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _registeredEvents.map((eventCode) {
                              final event = EventConstants.findByCode(eventCode);
                              return Chip(
                                label: Text('${event?.name ?? eventCode} ($eventCode)'),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () => _removeEvent(eventCode),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _saveStudent,
          child: const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _selectedDivision = Division.fromBirthYear(date.year);
      });
    }
  }

  void _showAddEventDialog() {
    _eventCodeController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增報名項目'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _eventCodeController,
              decoration: const InputDecoration(
                labelText: '項目編碼',
                hintText: '例如：GC100, BC200, GCLJ',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {}); // 觸發重建以更新提示
              },
            ),
            const SizedBox(height: 8),
            if (_eventCodeController.text.isNotEmpty) ...[
              const Divider(),
              Text(
                '項目預覽：',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              _buildEventPreview(_eventCodeController.text),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => _addEvent(_eventCodeController.text),
            child: const Text('新增'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventPreview(String code) {
    final event = EventConstants.findByCode(code.toUpperCase());
    if (event == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '無效的項目編碼',
          style: TextStyle(color: Colors.red[700], fontSize: 12),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.name,
            style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
          ),
          Text(
            '${event.category.displayName} - ${event.divisions.map((d) => d.displayName).join('/')} ${event.genders.first.displayName}',
            style: TextStyle(color: Colors.green[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _addEvent(String eventCode) {
    final code = eventCode.toUpperCase().trim();
    if (code.isEmpty) return;

    final event = EventConstants.findByCode(code);
    if (event == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('無效的項目編碼：$code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 檢查性別和組別匹配
    if (!event.divisions.contains(_selectedDivision)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('此項目不適合${_selectedDivision.displayName}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (event.genders.isNotEmpty && 
        !event.genders.contains(_selectedGender) && 
        !event.genders.contains(Gender.mixed)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('此項目不適合${_selectedGender.displayName}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_registeredEvents.contains(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('此項目已報名'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _registeredEvents.add(code);
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已新增項目：${event.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removeEvent(String eventCode) {
    setState(() {
      _registeredEvents.remove(eventCode);
    });
  }

  void _saveStudent() {
    if (_formKey.currentState!.validate()) {
      final updatedStudent = widget.student.copyWith(
        name: _nameController.text.trim(),
        classId: _classController.text.trim().toUpperCase(),
        studentNumber: _studentNumberController.text.trim(),
        gender: _selectedGender,
        division: _selectedDivision,
        isStaff: _isStaff,
        dateOfBirth: _selectedDate,
        registeredEvents: _registeredEvents,
        grade: Division.gradeFromClass(_classController.text.trim()),
      );
      
      widget.onStudentChanged(updatedStudent);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    _studentNumberController.dispose();
    _eventCodeController.dispose();
    super.dispose();
  }
}

/// 文件匯入對話框
class FileImportDialog extends StatefulWidget {
  final Function(List<Student>) onStudentsImported;

  const FileImportDialog({
    super.key,
    required this.onStudentsImported,
  });

  @override
  State<FileImportDialog> createState() => _FileImportDialogState();
}

class _FileImportDialogState extends State<FileImportDialog> {
  final _textController = TextEditingController();
  ImportResult? _importResults;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('匯入學生資料'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectFile,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('選擇CSV檔案'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.paste),
                    label: const Text('貼上CSV資料'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('CSV資料預覽：'),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                    hintText: '選擇檔案或貼上CSV資料...\n\n格式示例：\n姓名,班級,學號,性別,出生年份,工作人員,報名項目編碼,備註\n陳大明,1A,001,男,2013,否,GC100;GCLJ,範例',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_importResults != null) _buildValidationResults(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _textController.text.trim().isEmpty || _isProcessing 
              ? null 
              : _validateData,
          child: _isProcessing 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('驗證資料'),
        ),
        if (_importResults != null && _getValidStudents().isNotEmpty)
          ElevatedButton(
            onPressed: _importValidStudents,
            child: Text('匯入 ${_getValidStudents().length} 位學生'),
          ),
      ],
    );
  }

  Widget _buildValidationResults() {
    final result = _importResults!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.hasErrors ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.hasErrors ? Colors.red[200]! : Colors.green[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.hasErrors ? Icons.error : Icons.check_circle,
                color: result.hasErrors ? Colors.red[700] : Colors.green[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                result.hasErrors ? '驗證失敗' : '驗證成功',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: result.hasErrors ? Colors.red[700] : Colors.green[700],
                ),
              ),
              const Spacer(),
              if (result.hasErrors)
                OutlinedButton.icon(
                  onPressed: _downloadErrorReport,
                  icon: const Icon(Icons.description, size: 16),
                  label: const Text('下載錯誤報告'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red[300]!),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 統計信息
          Wrap(
            spacing: 16,
            children: [
              _buildStatItem('有效學生', result.validStudents.length, Colors.green),
              if (result.duplicates > 0)
                _buildStatItem('重複數據', result.duplicates, Colors.orange),
              if (result.errors.isNotEmpty)
                _buildStatItem('錯誤數', result.errors.length, Colors.red),
            ],
          ),
          
          // 錯誤詳情
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '錯誤詳情：',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: ListView.builder(
                itemCount: result.errors.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${index + 1}. ${result.errors[index]}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color[700]),
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color[800],
            ),
          ),
        ],
      ),
    );
  }

  void _downloadErrorReport() {
    final result = _importResults!;
    final buffer = StringBuffer();
    
    buffer.writeln('CSV匯入錯誤報告');
    buffer.writeln('生成時間：${DateTime.now().toString()}');
    buffer.writeln('');
    buffer.writeln('統計信息：');
    buffer.writeln('- 有效學生：${result.validStudents.length}');
    buffer.writeln('- 重複數據：${result.duplicates}');
    buffer.writeln('- 錯誤數量：${result.errors.length}');
    buffer.writeln('');
    
    if (result.errors.isNotEmpty) {
      buffer.writeln('詳細錯誤：');
      for (int i = 0; i < result.errors.length; i++) {
        buffer.writeln('${i + 1}. ${result.errors[i]}');
      }
      buffer.writeln('');
    }
    
    buffer.writeln('建議解決方案：');
    buffer.writeln('1. 檢查CSV格式是否正確（需要7個欄位：姓名,班級,學號,性別,出生年份,工作人員,報名項目編碼）');
    buffer.writeln('2. 確保學號為數字格式');
    buffer.writeln('3. 性別只能填寫：男/女 或 M/F');
    buffer.writeln('4. 出生年份應在2000-2020之間');
    buffer.writeln('5. 工作人員狀態填寫：是/否 或 Y/N');
    buffer.writeln('6. 項目代碼請參考模板或聯繫管理員');
    
    _downloadTextFile(buffer.toString(), 'csv_import_error_report.txt');
  }

  void _downloadTextFile(String content, String filename) {
    final bytes = content.codeUnits;
    final blob = html.Blob([bytes], 'text/plain;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  List<Student> _getValidStudents() {
    return _importResults?.validStudents ?? [];
  }

  void _selectFile() {
    final input = html.FileUploadInputElement()..accept = '.csv';
    input.click();

    input.onChange.listen((e) {
      final files = input.files;
      if (files?.isEmpty ?? true) return;

      final file = files!.first;
      final reader = html.FileReader();

      reader.onLoadEnd.listen((e) {
        setState(() {
          _textController.text = reader.result as String;
        });
      });

      reader.readAsText(file);
    });
  }

  void _pasteFromClipboard() {
    // 顯示提示對話框，引導用戶手動貼上
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('貼上CSV資料'),
        content: const Text('請複製您的CSV資料，然後直接貼上到左側的文字框中。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _validateData() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請先輸入或選擇CSV資料'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final results = await ExcelHelper.parseImportData(_textController.text);
      setState(() {
        _importResults = results;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('驗證失敗：$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _importValidStudents() {
    final validStudents = _getValidStudents();
    if (validStudents.isNotEmpty) {
      widget.onStudentsImported(validStudents);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
} 