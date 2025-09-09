/// 列印服務
/// 支援前三名名單、班級積分、成績報告等列印功能
import 'dart:convert';
import 'dart:html' as html;
import '../models/student.dart';
import '../constants/event_constants.dart';
import '../services/relay_service.dart';
import '../services/scoring_service.dart';

/// 列印服務
class PrintingService {
  
  /// 列印接力賽前三名
  static void printRelayTopThree(String eventCode) {
    try {
      final eventInfo = EventConstants.findByCode(eventCode);
      if (eventInfo == null) {
        throw '找不到項目：$eventCode';
      }
      
      final topThreeData = RelayService.exportTopThreeData(eventCode);
      final htmlContent = _generateRelayTopThreeHTML(topThreeData);
      
      _printHTML(htmlContent, '${eventCode}_前三名_${DateTime.now().millisecondsSinceEpoch}');
      
      print('🖨️ 已列印 $eventCode 前三名名單');
    } catch (e) {
      print('❌ 列印失敗：$e');
      rethrow;
    }
  }
  
  /// 列印班級積分排行榜
  static void printClassLeaderboard(List<Student> students) {
    try {
      final leaderboardData = _generateClassLeaderboardData(students);
      final htmlContent = _generateClassLeaderboardHTML(leaderboardData);
      
      _printHTML(htmlContent, '班級積分排行榜_${DateTime.now().millisecondsSinceEpoch}');
      
      print('🖨️ 已列印班級積分排行榜');
    } catch (e) {
      print('❌ 列印失敗：$e');
      rethrow;
    }
  }
  
  /// 列印所有接力賽前三名總表
  static void printAllRelayTopThree() {
    try {
      final allRelayEvents = RelayService.getAllRelayEvents();
      final allTopThreeData = <String, dynamic>{};
      
      for (final event in allRelayEvents) {
        allTopThreeData[event.code] = RelayService.exportTopThreeData(event.code);
      }
      
      final htmlContent = _generateAllRelayTopThreeHTML(allTopThreeData);
      _printHTML(htmlContent, '所有接力賽前三名總表_${DateTime.now().millisecondsSinceEpoch}');
      
      print('🖨️ 已列印所有接力賽前三名總表');
    } catch (e) {
      print('❌ 列印失敗：$e');
      rethrow;
    }
  }
  
  /// 生成班級積分排行榜數據
  static List<Map<String, dynamic>> _generateClassLeaderboardData(List<Student> students) {
    final classPoints = <String, Map<String, dynamic>>{};
    final allClasses = students.map((s) => s.classId).toSet().toList()..sort();
    
    for (final className in allClasses) {
      classPoints[className] = ScoringService.getClassPointsAnalysis(className, students);
    }
    
    final rankings = classPoints.values.toList();
    rankings.sort((a, b) => (b['totalPoints'] as int).compareTo(a['totalPoints'] as int));
    
    return rankings;
  }
  
  /// 生成接力賽前三名HTML
  static String _generateRelayTopThreeHTML(Map<String, dynamic> data) {
    final eventCode = data['eventCode'];
    final eventName = data['eventName'];
    final divisions = data['divisions'] as Map<String, dynamic>;
    final exportTime = DateTime.parse(data['exportTime']);
    
    final htmlContent = '''
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$eventName 前三名名單</title>
    <style>
        body {
            font-family: 'Microsoft JhengHei', Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 10px;
        }
        .title {
            font-size: 28px;
            font-weight: bold;
            margin-bottom: 10px;
        }
        .subtitle {
            font-size: 16px;
            opacity: 0.9;
        }
        .division-section {
            background: white;
            margin-bottom: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .division-header {
            background: #4a90e2;
            color: white;
            padding: 15px 20px;
            font-size: 20px;
            font-weight: bold;
        }
        .winners-container {
            padding: 20px;
        }
        .winner-card {
            display: flex;
            align-items: center;
            padding: 15px;
            margin-bottom: 10px;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .winner-card.first { background: linear-gradient(135deg, #ffd700, #ffed4e); }
        .winner-card.second { background: linear-gradient(135deg, #c0c0c0, #d3d3d3); }
        .winner-card.third { background: linear-gradient(135deg, #cd7f32, #daa520); }
        .rank {
            font-size: 24px;
            font-weight: bold;
            margin-right: 15px;
            min-width: 60px;
        }
        .class-info {
            flex: 1;
        }
        .class-name {
            font-size: 20px;
            font-weight: bold;
        }
        .result {
            font-size: 16px;
            color: #666;
        }
        .points {
            font-size: 18px;
            font-weight: bold;
            color: #4a90e2;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding: 15px;
            color: #666;
            font-size: 14px;
        }
        @media print {
            body { background-color: white; }
            .division-section { box-shadow: none; border: 1px solid #ddd; }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="title">$eventName 前三名名單</div>
        <div class="subtitle">列印時間：${_formatDateTime(exportTime)}</div>
    </div>
''';

    final sectionsHtml = StringBuffer();
    final rankLabels = ['🥇 冠軍', '🥈 亞軍', '🥉 季軍'];
    final cardClasses = ['first', 'second', 'third'];
    
    for (final divisionName in divisions.keys) {
      final divisionData = divisions[divisionName] as List;
      
      sectionsHtml.write('''
        <div class="division-section">
            <div class="division-header">$divisionName</div>
            <div class="winners-container">
      ''');
      
      for (int i = 0; i < divisionData.length && i < 3; i++) {
        final winner = divisionData[i];
        final rank = winner['rank'];
        final classId = winner['classId'];
        final result = winner['result'];
        final points = winner['points'];
        
        sectionsHtml.write('''
            <div class="winner-card ${cardClasses[i]}">
                <div class="rank">${rankLabels[i]}</div>
                <div class="class-info">
                    <div class="class-name">$classId</div>
                    <div class="result">成績：$result</div>
                </div>
                <div class="points">+$points 分</div>
            </div>
        ''');
      }
      
      sectionsHtml.write('''
            </div>
        </div>
      ''');
    }

    return htmlContent + sectionsHtml.toString() + '''
    <div class="footer">
        <p>此為系統自動生成的前三名名單，時間：${_formatDateTime(DateTime.now())}</p>
    </div>
</body>
</html>
''';
  }
  
  /// 生成班級積分排行榜HTML
  static String _generateClassLeaderboardHTML(List<Map<String, dynamic>> leaderboardData) {
    final htmlContent = '''
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>班級積分排行榜</title>
    <style>
        body {
            font-family: 'Microsoft JhengHei', Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 10px;
        }
        .title {
            font-size: 28px;
            font-weight: bold;
            margin-bottom: 10px;
        }
        .subtitle {
            font-size: 16px;
            opacity: 0.9;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        th {
            background: #4a90e2;
            color: white;
            padding: 15px;
            text-align: center;
            font-weight: bold;
        }
        td {
            padding: 12px;
            text-align: center;
            border-bottom: 1px solid #eee;
        }
        tr:hover {
            background-color: #f8f9fa;
        }
        .rank-1 { background: linear-gradient(135deg, #ffd700, #ffed4e) !important; }
        .rank-2 { background: linear-gradient(135deg, #c0c0c0, #d3d3d3) !important; }
        .rank-3 { background: linear-gradient(135deg, #cd7f32, #daa520) !important; }
        .total-points {
            font-weight: bold;
            color: #4a90e2;
            font-size: 16px;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding: 15px;
            color: #666;
            font-size: 14px;
        }
        @media print {
            body { background-color: white; }
            table { box-shadow: none; border: 1px solid #ddd; }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="title">班級積分排行榜</div>
        <div class="subtitle">列印時間：${_formatDateTime(DateTime.now())}</div>
    </div>
    
    <table>
        <thead>
            <tr>
                <th>排名</th>
                <th>班級</th>
                <th>總積分</th>
                <th>個人積分</th>
                <th>接力積分</th>
                <th>參與分</th>
                <th>名次分</th>
                <th>獎勵分</th>
                <th>參與人數</th>
            </tr>
        </thead>
        <tbody>
''';

    final tableRows = StringBuffer();
    for (int i = 0; i < leaderboardData.length; i++) {
      final data = leaderboardData[i];
      final rank = i + 1;
      final rowClass = rank <= 3 ? 'rank-$rank' : '';
      
      tableRows.write('''
            <tr class="$rowClass">
                <td>${rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : rank}</td>
                <td><strong>${data['classId']}</strong></td>
                <td class="total-points">${data['totalPoints']}</td>
                <td>${data['individualPoints']}</td>
                <td>${data['relayPoints']}</td>
                <td>${data['participationPoints']}</td>
                <td>${data['awardPoints']}</td>
                <td>${data['recordBonus']}</td>
                <td>${data['studentCount']}</td>
            </tr>
      ''');
    }

    return htmlContent + tableRows.toString() + '''
        </tbody>
    </table>
    
    <div class="footer">
        <p>此為系統自動生成的班級積分排行榜，時間：${_formatDateTime(DateTime.now())}</p>
    </div>
</body>
</html>
''';
  }
  
  /// 生成所有接力賽前三名總表HTML
  static String _generateAllRelayTopThreeHTML(Map<String, dynamic> allData) {
    final htmlContent = '''
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>所有接力賽前三名總表</title>
    <style>
        body {
            font-family: 'Microsoft JhengHei', Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 10px;
        }
        .event-section {
            background: white;
            margin-bottom: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .event-header {
            background: #4a90e2;
            color: white;
            padding: 15px 20px;
            font-size: 22px;
            font-weight: bold;
        }
        /* 其他樣式與前面相同... */
    </style>
</head>
<body>
    <div class="header">
        <div style="font-size: 28px; font-weight: bold; margin-bottom: 10px;">所有接力賽前三名總表</div>
        <div style="font-size: 16px; opacity: 0.9;">列印時間：${_formatDateTime(DateTime.now())}</div>
    </div>
''';

    final sectionsHtml = StringBuffer();
    for (final eventCode in allData.keys) {
      final eventData = allData[eventCode];
      sectionsHtml.write('''
        <div class="event-section">
            <div class="event-header">${eventData['eventName']}</div>
            <!-- 這裡添加與單個接力賽相同的內容結構 -->
        </div>
      ''');
    }

    return htmlContent + sectionsHtml.toString() + '''
    <div style="text-align: center; margin-top: 30px; padding: 15px; color: #666; font-size: 14px;">
        <p>此為系統自動生成的所有接力賽前三名總表，時間：${_formatDateTime(DateTime.now())}</p>
    </div>
</body>
</html>
''';
  }
  
  /// 執行HTML列印
  static void _printHTML(String htmlContent, String filename) {
    // 創建一個隱藏的iframe進行列印
    final iframe = html.IFrameElement()
      ..style.display = 'none'
      ..srcdoc = htmlContent;
    
    html.document.body?.append(iframe);
    
    // 等待iframe載入完成後列印
    iframe.onLoad.listen((_) {
      try {
        iframe.contentWindow?.print();
        
        // 延遲移除iframe
        Future.delayed(const Duration(seconds: 2), () {
          iframe.remove();
        });
      } catch (e) {
        print('列印過程中發生錯誤：$e');
        iframe.remove();
      }
    });
  }
  
  /// 格式化日期時間
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}:'
           '${dateTime.second.toString().padLeft(2, '0')}';
  }
  
  /// 下載前三名CSV數據
  static void downloadTopThreeCSV(String eventCode) {
    try {
      final topThreeData = RelayService.exportTopThreeData(eventCode);
      final csvContent = _generateTopThreeCSV(topThreeData);
      
      _downloadFile(csvContent, '${eventCode}_前三名_${DateTime.now().millisecondsSinceEpoch}.csv');
      
      print('📥 已下載 $eventCode 前三名CSV文件');
    } catch (e) {
      print('❌ 下載失敗：$e');
      rethrow;
    }
  }
  
  /// 生成前三名CSV
  static String _generateTopThreeCSV(Map<String, dynamic> data) {
    final lines = <String>[];
    lines.add('項目,組別,排名,班級,成績,積分');
    
    final eventName = data['eventName'];
    final divisions = data['divisions'] as Map<String, dynamic>;
    
    for (final divisionName in divisions.keys) {
      final divisionData = divisions[divisionName] as List;
      
      for (final winner in divisionData) {
        lines.add('$eventName,$divisionName,${winner['rank']},${winner['classId']},${winner['result']},${winner['points']}');
      }
    }
    
    return lines.join('\n');
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
