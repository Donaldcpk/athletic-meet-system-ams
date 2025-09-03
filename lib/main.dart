import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/student_management_screen.dart';
import 'screens/event_management_screen.dart';
import 'screens/referee_system_screen.dart';
import 'screens/rankings_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/enhanced_class_points_screen.dart';
import 'screens/professional_data_management_screen.dart';
import 'screens/login_screen.dart';
import 'utils/app_state.dart';
import 'services/user_service.dart';
import 'services/operation_log_service.dart';
import 'services/scoring_service.dart';

void main() {
  runApp(const AthleticMeetSystemApp());
}

class AthleticMeetSystemApp extends StatelessWidget {
  const AthleticMeetSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '香港中學運動會管理系統',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AppInitializer(),
      routes: _buildOtherRoutes(),
    );
  }

  Map<String, WidgetBuilder> _buildOtherRoutes() {
    return {
      '/home': (context) => const HomeScreen(),
      '/dashboard': (context) => const DashboardScreen(),
      '/student_management': (context) => const StudentManagementScreen(),
      '/students': (context) => const StudentManagementScreen(),
      '/event_management': (context) => EventManagementScreen(
        students: AppState().students,
      ),
      '/referee_system': (context) => const RefereeSystemScreen(),
      '/referee': (context) => const RefereeSystemScreen(),
      '/rankings': (context) => const RankingsScreen(),
      '/reports': (context) => const ReportsScreen(),
      '/class_points': (context) => const EnhancedClassPointsScreen(),
      '/data_management': (context) => const ProfessionalDataManagementScreen(),
    };
  }
}

/// 應用初始化器
/// 處理異步數據加載和初始化
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  String _initializationStatus = '正在初始化...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _initializationStatus = '正在初始化系統...';
      });

      // 恢復用戶會話
      UserService.restoreSession();
      
      setState(() {
        _initializationStatus = '正在加載數據...';
      });

      // 初始化應用狀態
      await AppState().initialize();
      
      setState(() {
        _initializationStatus = '正在加載操作日誌...';
      });
      
      // 載入操作日誌
      OperationLogService.loadFromLocal();
      
      setState(() {
        _initializationStatus = '正在載入積分數據...';
      });
      
      // 載入積分數據
      await ScoringService.loadScores();

      setState(() {
        _initializationStatus = '初始化完成';
        _isInitialized = true;
      });

      // 短暫延遲後跳轉
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        // 檢查用戶是否已登入
        if (UserService.isLoggedIn) {
          // 記錄自動登入
          await OperationLogService.logOperation(
            OperationType.login,
            '用戶恢復會話',
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else {
          // 前往登入頁面
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _initializationStatus = '初始化失敗: $e';
      });
      
      // 顯示錯誤後仍然跳轉到登入頁面
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[600],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sports,
                size: 64,
                color: Colors.blue,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 標題
            const Text(
              '香港中學運動會',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              '管理系統',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 20,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // 載入指示器
            if (!_isInitialized) ...[
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
            ],
            
            // 狀態文字
            Text(
              _initializationStatus,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            
            if (_isInitialized) ...[
              const SizedBox(height: 16),
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 32,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
