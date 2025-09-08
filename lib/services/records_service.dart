/// 校內紀錄和標準成績管理服務
/// 解析並管理運動會的標準成績和校內紀錄數據

import 'dart:convert';
import '../models/student.dart';
import '../constants/event_constants.dart';

/// 紀錄類型
enum RecordType {
  schoolRecord,  // 校內紀錄
  standard,      // 標準成績
}

/// 項目紀錄
class EventRecord {
  final String eventCode;      // 項目代碼 (如 BA, BB, BC, GA, GB, GC)
  final String eventName;      // 項目名稱 (如 100m, 跳遠)
  final Division division;     // 組別 (甲組A, 乙組B, 丙組C)
  final Gender gender;         // 性別
  final String? recordHolder;  // 紀錄保持者姓名
  final String? recordClass;   // 紀錄保持者班級
  final String? recordYear;    // 紀錄創造年份
  final String? recordValue;   // 校內紀錄值
  final String? standardValue; // 標準成績值
  
  const EventRecord({
    required this.eventCode,
    required this.eventName,
    required this.division,
    required this.gender,
    this.recordHolder,
    this.recordClass,
    this.recordYear,
    this.recordValue,
    this.standardValue,
  });

  /// 檢查成績是否達到標準
  bool meetsStandard(String result) {
    if (standardValue == null || standardValue!.isEmpty) return false;
    return _compareResults(result, standardValue!);
  }

  /// 檢查成績是否破校紀錄
  bool breaksRecord(String result) {
    if (recordValue == null || recordValue!.isEmpty) return false;
    return _compareResults(result, recordValue!);
  }

  /// 比較成績 (較好的成績返回true)
  bool _compareResults(String newResult, String existingResult) {
    try {
      // 移除單位符號並轉換為數值
      final newValue = _parseResultValue(newResult);
      final existingValue = _parseResultValue(existingResult);
      
      if (newValue == null || existingValue == null) return false;
      
      // 根據項目類型判斷比較方式
      if (_isTimeEvent()) {
        // 時間類：越小越好
        return newValue < existingValue;
      } else {
        // 距離/高度類：越大越好
        return newValue > existingValue;
      }
    } catch (e) {
      return false;
    }
  }

  /// 解析成績數值
  double? _parseResultValue(String result) {
    if (result.isEmpty) return null;
    
    // 移除單位符號
    String cleanResult = result
        .replaceAll('s', '')
        .replaceAll('m', '')
        .replaceAll(' ', '');
    
    // 處理分:秒格式 (如 1:09.00)
    if (cleanResult.contains(':')) {
      final parts = cleanResult.split(':');
      if (parts.length == 2) {
        final minutes = double.tryParse(parts[0]) ?? 0;
        final seconds = double.tryParse(parts[1]) ?? 0;
        return minutes * 60 + seconds;
      }
    }
    
    return double.tryParse(cleanResult);
  }

  /// 判斷是否為時間類項目
  bool _isTimeEvent() {
    final timeEvents = ['60m', '100m', '200m', '400m', '800m', '1500m', '3000m', 
                       '100mH', '110mH', '400mH', '4X100m', '4X400m'];
    return timeEvents.contains(eventName);
  }

  /// 格式化顯示紀錄信息
  String get formattedRecord {
    if (recordValue == null || recordValue!.isEmpty) return '無紀錄';
    return '$recordValue (${recordHolder ?? '未知'} - ${recordYear ?? '未知年份'})';
  }

  /// 格式化顯示標準成績
  String get formattedStandard {
    return standardValue ?? '未設定';
  }
}

/// 校內紀錄服務
class RecordsService {
  static final Map<String, EventRecord> _records = {};
  
  /// 初始化紀錄數據
  static void initializeRecords() {
    _records.clear();
    _parseRecordsFromActualCSV();
  }

  /// 解析完整的學校記錄CSV數據
  static void _parseRecordsFromActualCSV() {
    final csvData = [
      // 60m 項目
      ['BC1', '60m', 'C1', '田瑞澤', '1C', '23-24', '9.32', ''],
      ['BC2', '60m', 'C2', '朱哲豪', '1B', '23-24', '9.43', ''],
      ['GC1', '60m', 'C1', '劉梓瀅', '1D', '23-24', '10.04s', ''],
      ['GC2', '60m', 'C2', '李嘉盈', '1D', '23-24', '9.94s', ''],
      
      // 100m 項目 
      ['BA', '100m', 'A', 'Chau Sing Man', '7A', '06-07', '11.14', '13.80s'],
      ['BB', '100m', 'B', 'Leung Chiu Hang', '5D', '84-85', '11.2', '14.30s'],
      ['BC', '100m', 'C', 'Cheung Kai Kwong', '3E', '84-85', '11.8', '15.10s'],
      ['GA', '100m', 'A', '', '', '', '', '16.50s'],
      ['GB', '100m', 'B', '劉美希', '3A', '24-25', '16.42s', '16.50s'],
      ['GC1', '100m', 'C1', '張菀芝', '2A', '24-25', '15.83s', '16.60s'],
      
      // 200m 項目
      ['BA', '200m', 'A', 'Chau Sing Man', '7A', '06-07', '23.51', '28.50s'],
      ['BB', '200m', 'B', 'Lau Chau Kuen', '5D', '95-96', '23.88', '29.00s'],
      ['BC', '200m', 'C', 'Jim Kam Wai', '3B', '92-93', '25.5', '31.50s'],
      ['GA', '200m', 'A', '', '', '', '', '35.60s'],
      ['GB', '200m', 'B', '', '', '', '', '35.60s'],
      ['GC', '200m', 'C', '陳芷瑤', '1B', '24-25', '35.13s', '36.00s'],
      
      // 400m 項目
      ['BA', '400m', 'A', 'Hui Shiu Lun', '5A', '09-10', '53.6', '1:09.00'],
      ['BB', '400m', 'B', 'Kwok Yat Nam', '4F', '12-13', '56.7', '1:12.00'],
      ['BC', '400m', 'C', 'Tso Chun Wing', '2C', '09-10', '57.45', '1:20.00'],
      ['GA', '400m', 'A', '', '', '', '', '1:31.00'],
      ['GB', '400m', 'B', '馬嘉怡', '3B', '24-25', '1:26.19', '1:34.00'],
      ['GC1', '400m', 'C1', '李嘉盈', '2D', '24-25', '1:18.29', '1:37.00'],
      
      // 800m 項目
      ['BA', '800m', 'A', 'Yuen Chi Fai', '7A', '88-89', '2:10.00', '3:04.00'],
      ['BB', '800m', 'B', 'Au Ka Lun', '5D', '05-06', '2:15.81', '3:10.00'],
      ['BC', '800m', 'C', 'Share Tsz Hin', '2E', '09-10', '2:25.44', '3:20.00'],
      ['GA', '800m', 'A', '', '', '', '', '3:52.00'],
      ['GB', '800m', 'B', '', '', '', '', '3:52.00'],
      ['GC', '800m', 'C', '', '', '', '', '4:00.00'],
      
      // 1500m 項目
      ['BA', '1500m', 'A', 'Tsoi Ka Cheuk', '5B', '11-12', '4:26.58', '6:15.00'],
      ['BB', '1500m', 'B', 'Au Ka Lun', '4D', '05-06', '4:47.40', '6:25.00'],
      ['BC', '1500m', 'C', 'Share Tsz Hin', '2E', '09-10', '5:17.04', '6:45.00'],
      ['GA', '1500m', 'A', '', '', '', '', '7:48.00'],
      ['GB', '1500m', 'B', '', '', '', '', '7:48.00'],
      ['GC', '1500m', 'C', '', '', '', '', '7:48.00'],
      
      // 3000m 項目
      ['BA', '3000m', 'A', 'Au Ka Lun', '6B', '08-09', '10:08.94', '13:30.00'],
      ['BB', '3000m', 'B', 'Tsui Chun Hei', '3C', '14-15', '10:53.25', '15:00.00'],
      ['BC', '3000m', 'C', 'Tsui Chun Hei', '2C', '13-14', '10:56.04', '18:00.00'],
      ['GA', '3000m', 'A', '', '', '', '', '17:00.00'],
      ['GB', '3000m', 'B', '', '', '', '', '17:00.00'],
      ['GC', '3000m', 'C', '', '', '', '', '17:00.00'],
      
      // 跨欄項目
      ['BA', '110mH', 'A', 'Fong Tsz Ming', '5B', '11-12', '14.91', '23.30s'],
      ['BB', '100mH', 'B', 'Chau Ching Yu', '4F', '09-10', '14.47', '22.80s'],
      ['BC', '100mH', 'C', 'Chau Ching Yu', '2C', '07-08', '15.49', '24.50s'],
      ['BOPEN', '400mH', 'OPEN', 'Hui Shiu Lun', '5A', '09-10', '1:01.39', '1:23.00'],
      ['GA', '100mH', 'A', '', '', '', '', '25.00s'],
      ['GB', '100mH', 'B', '', '', '', '', '25.50s'],
      ['GC', '100mH', 'C', '李嘉盈', '2D', '24-25', '20.53s', '26.50s'],
      
      // 田賽 - 鉛球
      ['BA', '鉛球', 'A', '許澤仁', '4C', '08-09', '11.53m', '8.10m'],
      ['BB', '鉛球', 'B', '余家溢', '2A', '13-14', '11.78m', '8.50m'],
      ['BC', '鉛球', 'C', '余家溢', '1A', '12-13', '10.18m', '6.80m'],
      ['GA', '鉛球', 'A', '林詩怡', '3B', '24-25', '6.02m', '5.30m'],
      ['GB', '鉛球', 'B', '張桐桐', '3D', '23-24', '4.91m', '5.70m'],
      ['GC', '鉛球', 'C', '劉逸心', '1C', '24-25', '6.62m', '5.00m'],
      
      // 田賽 - 鐵餅
      ['BA', '鐵餅', 'A', '倪皓森', '6D', '11-12', '33.31m', '16.00m'],
      ['BB', '鐵餅', 'B', '馮日朗', '4A', '08-09', '34.76m', '18.50m'],
      ['BC', '鐵餅', 'C', '余家溢', '1A', '12-13', '23.07m', '13.50m'],
      ['GA', '鐵餅', 'A', '', '', '', '', '12.50m'],
      ['GB', '鐵餅', 'B', '', '', '', '', '11.80m'],
      ['GC', '鐵餅', 'C', '陳煒晴', '1D', '24-25', '12.22m', '10.00m'],
      
      // 田賽 - 跳高
      ['BA', '跳高', 'A', '李澤銘', '6E', '14-15', '1.79m', '1.40m'],
      ['BB', '跳高', 'B', '', '4E', '95-96', '1.74m', '1.35m'],
      ['BC', '跳高', 'C', '', '3E', '93-94', '1.62m', '1.15m'],
      ['GA', '跳高', 'A', '', '', '', '', '1.15m'],
      ['GB', '跳高', 'B', '鄭芷茵', '3B', '24-25', '1.00m', '1.05m'],
      ['GC', '跳高', 'C', '鄭芷茵', '2B', '23-24', '1.07m', '1.00m'],
      
      // 田賽 - 跳遠
      ['BA', '跳遠', 'A', '周程宇', '6B', '11-12', '6.60m', '4.50m'],
      ['BB', '跳遠', 'B', '周程宇', '4F', '09-10', '6.36m', '4.00m'],
      ['BC', '跳遠', 'C', 'Jim Kam Wai', '3B', '92-93', '5.23m', '3.50m'],
      ['GA', '跳遠', 'A', '徐盈盈', '3B', '24-25', '2.47m', '3.10m'],
      ['GB', '跳遠', 'B', '鄭芷茵', '3B', '24-25', '3.12m', '2.90m'],
      ['GC', '跳遠', 'C', '李嘉盈', '2D', '24-25', '3.33m', '2.60m'],
      
      // 田賽 - 三級跳
      ['BA', '三級跳', 'A', '周程宇', '6B', '11-12', '13.47m', '9.40m'],
      ['BB', '三級跳', 'B', '方子銘', '4B', '07-08', '12.24m', '8.60m'],
      
      // 田賽 - 標槍
      ['BA', '標槍', 'A', '馮日朗', '5A', '09-10', '42.25m', '20.00m'],
      ['BB', '標槍', 'B', '馮日朗', '4A', '08-09', '40.60m', '16.00m'],
      ['GB', '標槍', 'B', '馬頌頤', '3B', '24-25', '9.12m', '10.50m'],
      
      // 田賽 - Baseball
      ['BC', 'Baseball', 'C', '鄒汶鋒', '1C', '17-18', '46.65m', '30.00m'],
      
      // 接力記錄
      ['', '4X100m', 'S1,2', '', '2C', '09-10', '51.66s', '58.50s'],
      ['', '4X100m', 'S3,4', '', '4D', '13-14', '49.54s', '54.50s'],
      ['', '4X100m', 'S5,6', '', '5B', '16-17', '50.67s', '52.50s'],
      ['', '4X400m', 'S1,2', '', '2C', '10-11', '4:25.32', '5:17.00'],
      ['', '4X400m', 'S3,4', '', '4F', '12-13', '4:00.14', '4:59.00'],
      ['', '4X400m', 'S5,6', '', '6C', '11-12', '3:59.26', '4:48.00'],
      ['', '4X100m 混合接力', 'S1', '', '1D', '23-24', '1:08.01', ''],
      ['', '4X100m 混合接力', 'S2', '', '2D', '23-24', '1:06.35', ''],
      ['', '4X400m 混合接力', 'S1', '', '1A', '23-24', '6:24.47', ''],
      ['', '4X400m 混合接力', 'S2', '', '2D', '23-24', '5:36.82', ''],
    ];
    
    for (final row in csvData) {
      if (row.length >= 8) {
        try {
          final eventCode = row[0];
          final eventName = row[1];
          final gradeStr = row[2];
          final recordHolder = row[3].isEmpty ? null : row[3];
          final recordClass = row[4].isEmpty ? null : row[4];
          final recordYear = row[5].isEmpty ? null : row[5];
          final recordValue = row[6].isEmpty ? null : row[6];
          final standardValue = row[7].isEmpty ? null : row[7];
          
          // 解析性別和組別
          Gender? gender;
          Division? division;
          
          if (eventCode.startsWith('B') || eventCode.startsWith('M')) {
            gender = Gender.male;
          } else if (eventCode.startsWith('G') || eventCode.startsWith('F')) {
            gender = Gender.female;
          }
          
          if (eventCode.contains('A') || gradeStr == 'A') {
            division = Division.senior;
          } else if (eventCode.contains('B') || gradeStr == 'B') {
            division = Division.junior;
          } else if (eventCode.contains('C') || gradeStr.startsWith('C')) {
            division = Division.primary;
          }
          
          if (gender != null && division != null) {
            final record = EventRecord(
              eventCode: eventCode,
              eventName: eventName,
              division: division,
              gender: gender,
              recordHolder: recordHolder,
              recordClass: recordClass,
              recordYear: recordYear,
              recordValue: recordValue,
              standardValue: standardValue,
            );
            
            // 使用更靈活的key，支援60m等項目
            final key = '${gender.name}_${division.name}_$eventName';
            _records[key] = record;
            
            // 為C1, C2等子組別也創建記錄
            if (eventCode.contains('C1') || eventCode.contains('C2')) {
              final subKey = '${gender.name}_primary_$eventName';
              if (!_records.containsKey(subKey)) {
                _records[subKey] = record;
              }
            }
          }
        } catch (e) {
          print('解析紀錄失敗: $e, 數據: $row');
        }
      }
    }
    
    print('✅ 已載入 ${_records.length} 筆校內紀錄');
  }

  /// 獲取匹配的記錄
  static EventRecord? getMatchingRecord(String eventName, Gender gender, Division division) {
    final key = '${gender.name}_${division.name}_$eventName';
    return _records[key];
  }

  /// 獲取所有記錄
  static Map<String, EventRecord> getAllRecords() {
    return Map.unmodifiable(_records);
  }

  /// 檢查是否有記錄數據
  static bool hasRecords() {
    return _records.isNotEmpty;
  }
}