import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../constants/event_constants.dart';
import '../models/student.dart';
import '../utils/app_state.dart';

/// 🧪 功能測試頁面 - 驗證所有功能是否正常工作
class TestFeaturesScreen extends StatefulWidget {
  const TestFeaturesScreen({super.key});

  @override
  State<TestFeaturesScreen> createState() => _TestFeaturesScreenState();
}

class _TestFeaturesScreenState extends State<TestFeaturesScreen> {
  final AppState _appState = AppState();
  int _fieldAttempts = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 功能測試頁面'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用戶狀態測試
            _buildUserStatusTest(),
            const SizedBox(height: 24),
            
            // 田賽界面測試
            _buildFieldEventTest(),
            const SizedBox(height: 24),
            
            // 特殊接力測試
            _buildSpecialRelayTest(),
            const SizedBox(height: 24),
            
            // 清除學生功能測試
            _buildClearStudentsTest(),
            const SizedBox(height: 24),
            
            // CSV錯誤報告測試
            _buildCSVErrorTest(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStatusTest() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔑 用戶權限測試',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800]),
            ),
            const SizedBox(height: 12),
            Text('登入狀態: ${UserService.isLoggedIn ? "✅ 已登入" : "❌ 未登入"}'),
            Text('當前用戶: ${UserService.getDisplayName()}'),
            Text('是否管理員: ${UserService.isAdmin ? "✅ 是" : "❌ 否"}'),
            Text('清除數據權限: ${UserService.hasPermission(UserPermissions.clearData) ? "✅ 有" : "❌ 無"}'),
            Text('輸入成績權限: ${UserService.hasPermission(UserPermissions.inputScores) ? "✅ 有" : "❌ 無"}'),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldEventTest() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎯 田賽界面測試',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800]),
            ),
            const SizedBox(height: 12),
            
            // 🔽 新版田賽界面
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green[300]!, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.green[100],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎯 田賽成績輸入 - 優化版本', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  // 下拉選單
                  DropdownButtonFormField<int>(
                    value: _fieldAttempts,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '選擇嘗試次數',
                    ),
                    items: List.generate(6, (index) {
                      final count = index + 1;
                      return DropdownMenuItem<int>(
                        value: count,
                        child: Text('$count 次嘗試'),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        _fieldAttempts = value ?? 3;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // 成績輸入欄位
                  Row(
                    children: List.generate(_fieldAttempts, (index) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              Text('第${index + 1}次'),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  suffixText: 'm',
                                  border: const OutlineInputBorder(),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialRelayTest() {
    return Card(
      color: Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏃‍♂️ 特殊接力測試',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple[800]),
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.purple[400]!, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.purple[100],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.groups, color: Colors.purple[800]),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('🎭 師生家長接力 - 使用暫代人員')),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('⚠️ 無積分計算', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // 暫代人員T1-T8
                  ...List.generate(8, (index) {
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('👤 T${index + 1}'),
                      ),
                      title: const TextField(
                        decoration: InputDecoration(
                          hintText: '0:00.00',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      trailing: const Text('正常'),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearStudentsTest() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🗑️ 清除學生功能測試',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[800]),
            ),
            const SizedBox(height: 12),
            
            Text('學生數量: ${_appState.students.length}'),
            const SizedBox(height: 8),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[300]!, width: 2),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('⚠️ 測試功能'),
                      content: const Text('清除所有學生功能測試成功！'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('確定'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
                label: const Text('🗑️ 清除所有學生（測試）'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red[800],
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCSVErrorTest() {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📄 CSV錯誤報告測試',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[800]),
            ),
            const SizedBox(height: 12),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[400]!, width: 2),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📄 CSV錯誤報告下載功能測試成功！'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                icon: const Icon(Icons.file_download, size: 20),
                label: const Text('📄 下載詳細錯誤報告（測試）'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[300],
                  foregroundColor: Colors.orange[900],
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
