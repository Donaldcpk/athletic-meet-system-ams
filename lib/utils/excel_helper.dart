/// Excel/CSV 處理輔助工具
/// 提供學生數據的匯入匯出功能

import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/student.dart';
import '../constants/event_constants.dart';

/// Excel 處理輔助類
class ExcelHelper {
  /// 生成學生匯入模板
  static void generateImportTemplate() {
    final csvContent = '''姓名,班級,學號,性別,出生年份,工作人員,報名項目編碼,備註
1A1,1A,1,男,2013,否,BCLJ;BC100;1441,範例學生
1A2,1A,2,女,2013,是,GCLJ;GC100;1441,工作人員
1B1,1B,1,男,2011,否,BBLJ;BB100;1444,乙組學生
2A1,2A,1,男,2010,否,BALJ;BA100;5641,甲組學生''';

    _downloadFile(csvContent, 'student_import_template.csv');
  }

  /// 生成學生匯出數據
  static void generateStudentExport(List<Student> students) {
    final buffer = StringBuffer();
    buffer.writeln('姓名,班級,學號,性別,出生年份,工作人員,報名項目編碼,報名項目名稱,備註');

    // 批量處理，每100個學生為一批
    for (int i = 0; i < students.length; i += 100) {
      final batch = students.skip(i).take(100);
      for (final student in batch) {
        final eventsText = student.registeredEvents.join(';');
        final eventNames = student.registeredEvents
            .map((code) => EventConstants.findByCode(code)?.name ?? code)
            .join(';');
        
        buffer.writeln(
          '${student.name},${student.classId},${student.studentNumber},'
          '${student.gender.displayName},${student.dateOfBirth.year},'
          '${student.isStaff ? "是" : "否"},$eventsText,$eventNames,',
        );
      }
    }

    _downloadFile(buffer.toString(), 'students_export.csv');
  }

  /// 解析匯入的CSV數據
  static Future<ImportResult> parseImportData(String csvContent) async {
    final result = ImportResult();
    
    try {
      final lines = csvContent.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      if (lines.isEmpty) {
        result.errors.add('CSV文件為空');
        return result;
      }

      // 跳過標題行
      final dataLines = lines.skip(1).toList();
      
      // 批量處理，避免UI阻塞
      int currentLineNumber = 2; // 從第2行開始（跳過標題行）
      
      for (int i = 0; i < dataLines.length; i += 50) {
        final batch = dataLines.skip(i).take(50);
        
        for (final line in batch) {
          final trimmedLine = line.trim();
          if (trimmedLine.isEmpty) {
            currentLineNumber++;
            continue;
          }

          try {
            final student = _parseStudentLine(trimmedLine, currentLineNumber);
            if (student != null) {
              // 檢查重複
              if (result.validStudents.any((s) => s.studentCode == student.studentCode)) {
                result.duplicates++;
                result.errors.add('第${currentLineNumber}行: 學生編號${student.studentCode}重複');
              } else {
                result.validStudents.add(student);
              }
            }
          } catch (e) {
            result.errors.add('第${currentLineNumber}行: $e');
          }
          
          currentLineNumber++;
        }
        
        // 允許UI更新
        await Future.delayed(Duration.zero);
      }

    } catch (e) {
      result.errors.add('CSV解析錯誤: $e');
    }

    return result;
  }

  /// 解析單行學生數據
  static Student? _parseStudentLine(String line, int lineNumber) {
    final fields = _parseCSVLine(line);
    
    if (fields.length < 7) {
      throw '數據欄位不足，需要至少7個欄位';
    }

    // 清理字段
    final name = fields[0].trim();
    final classId = fields[1].trim();
    final studentNumberStr = fields[2].trim();
    final genderStr = fields[3].trim();
    final birthYearStr = fields[4].trim();
    final isStaffStr = fields[5].trim();
    final eventsStr = fields[6].trim();

    // 驗證必填字段
    if (name.isEmpty || classId.isEmpty || studentNumberStr.isEmpty) {
      throw '姓名、班級、學號不能為空';
    }

    // 解析學號
    final studentNumber = int.tryParse(studentNumberStr);
    if (studentNumber == null) {
      throw '學號格式錯誤: $studentNumberStr';
    }

    // 解析性別
    Gender gender;
    switch (genderStr) {
      case '男':
      case 'M':
      case 'Male':
        gender = Gender.male;
        break;
      case '女':
      case 'F':
      case 'Female':
        gender = Gender.female;
        break;
      default:
        throw '性別格式錯誤: $genderStr（應為：男/女）';
    }

    // 解析出生年份
    final birthYear = int.tryParse(birthYearStr);
    if (birthYear == null || birthYear < 2000 || birthYear > 2020) {
      throw '出生年份格式錯誤: $birthYearStr';
    }

    // 解析工作人員狀態
    final isStaff = isStaffStr == '是' || isStaffStr == 'Y' || isStaffStr == 'Yes';

    // 解析報名項目（支援分號或逗號分隔）
    final registeredEvents = <String>[];
    if (eventsStr.isNotEmpty) {
      final eventCodes = eventsStr.split(RegExp(r'[;,，；]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // 驗證項目代碼和性別匹配
      for (final eventCode in eventCodes) {
        final eventInfo = EventConstants.findByCode(eventCode);
        
        // 如果找不到事件，添加為臨時事件（可能是新增項目）
        if (eventInfo == null) {
          // 檢查是否是有效的事件代碼格式
          if (_isValidEventCodeFormat(eventCode)) {
            registeredEvents.add(eventCode);
          } else {
            throw '無效的項目代碼: $eventCode';
          }
          continue;
        }

        // 檢查性別匹配
        if (!eventInfo.genders.contains(gender) && !eventInfo.genders.contains(Gender.mixed)) {
          throw '項目 $eventCode (${eventInfo.name}) 不適用於${gender.displayName}';
        }

        // 檢查組別匹配
        final division = Division.fromBirthYear(birthYear);
        if (!eventInfo.divisions.contains(division)) {
          // 提供更詳細的錯誤信息以便調試
          final allowedDivisions = eventInfo.divisions.map((d) => d.displayName).join('、');
          throw '項目 $eventCode (${eventInfo.name}) 不適用於${division.displayName}，此項目適用於：$allowedDivisions (出生年份：$birthYear)';
        }

        registeredEvents.add(eventCode);
      }
    }

    // 創建學生對象
    return Student(
      id: DateTime.now().millisecondsSinceEpoch.toString() + studentNumber.toString(),
      name: name,
      classId: classId,
      gender: gender,
      division: Division.fromBirthYear(birthYear),
      studentNumber: studentNumber.toString(),
      grade: _gradeFromClassId(classId),
      dateOfBirth: DateTime(birthYear, 1, 1),
      isActive: true,
      isStaff: isStaff,
      registeredEvents: registeredEvents,
    );
  }

  /// 解析CSV行（處理引號包圍的字段）
  static List<String> _parseCSVLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    
    // 添加最後一個字段
    fields.add(buffer.toString().trim());
    
    return fields;
  }

  /// 檢查是否是有效的事件代碼格式
  static bool _isValidEventCodeFormat(String code) {
    // 基本格式檢查：英文字母和數字的組合
    return RegExp(r'^[A-Z0-9]+$').hasMatch(code) && code.length >= 2;
  }

  /// 從班級ID推斷年級
  static int _gradeFromClassId(String classId) {
    final gradeStr = classId.substring(0, 1);
    return int.tryParse(gradeStr) ?? 1;
  }

  /// 下載文件
  static void _downloadFile(String content, String filename) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}

/// 匯入結果
class ImportResult {
  final List<Student> validStudents = [];
  final List<String> errors = [];
  int duplicates = 0;

  bool get hasErrors => errors.isNotEmpty;
  int get totalProcessed => validStudents.length + duplicates;
} 