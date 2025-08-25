import 'package:flutter/material.dart';

/// 響應式設計工具類
/// 根據屏幕大小自動調整布局和樣式
class ResponsiveHelper {
  // 斷點定義
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  /// 獲取設備類型
  static DeviceType getDeviceType(double width) {
    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// 檢查是否為手機
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// 檢查是否為平板
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// 檢查是否為桌面
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// 獲取網格列數
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return 1; // 手機：1列
    } else if (width < tabletBreakpoint) {
      return 2; // 平板：2列
    } else {
      return 3; // 桌面：3列
    }
  }

  /// 獲取側邊欄寬度
  static double getSidebarWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 280.0;
    } else if (isTablet(context)) {
      return 240.0;
    } else {
      return 0.0; // 手機不顯示側邊欄
    }
  }

  /// 獲取內容最大寬度
  static double getMaxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > desktopBreakpoint) {
      return desktopBreakpoint;
    }
    return width;
  }

  /// 獲取適應性邊距
  static EdgeInsets getAdaptivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  /// 獲取卡片間距
  static double getCardSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 12.0;
    } else if (isTablet(context)) {
      return 16.0;
    } else {
      return 20.0;
    }
  }

  /// 獲取字體大小倍率
  static double getFontSizeMultiplier(BuildContext context) {
    if (isMobile(context)) {
      return 1.0;
    } else if (isTablet(context)) {
      return 1.1;
    } else {
      return 1.2;
    }
  }
}

/// 響應式構建器 Widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(
      MediaQuery.of(context).size.width,
    );
    return builder(context, deviceType);
  }
}

/// 設備類型枚舉
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// 響應式佈局 Widget
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        switch (deviceType) {
          case DeviceType.mobile:
            return mobile;
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.desktop:
            return desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}

/// 響應式導航欄
class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<NavigationItem>? navigationItems;
  final Widget? floatingActionButton;
  final bool showDrawer;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.navigationItems,
    this.floatingActionButton,
    this.showDrawer = true,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        if (deviceType == DeviceType.mobile) {
          // 手機版：使用標準 Scaffold + Drawer
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              centerTitle: true,
            ),
            drawer: showDrawer && navigationItems != null
                ? _buildDrawer(context)
                : null,
            body: body,
            floatingActionButton: floatingActionButton,
          );
        } else {
          // 平板/桌面版：使用側邊欄佈局
          return Scaffold(
            body: Row(
              children: [
                if (navigationItems != null)
                  Container(
                    width: ResponsiveHelper.getSidebarWidth(context),
                    color: Theme.of(context).colorScheme.surface,
                    child: _buildSidebar(context),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 80,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).appBarTheme.backgroundColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).appBarTheme.titleTextStyle,
                            ),
                            const Spacer(),
                            if (floatingActionButton != null)
                              floatingActionButton!,
                          ],
                        ),
                      ),
                      Expanded(child: body),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Row(
              children: [
                Icon(Icons.sports, color: Colors.white, size: 32),
                SizedBox(width: 16),
                Text(
                  '運動會系統',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: navigationItems!
                  .map((item) => ListTile(
                        leading: Icon(item.icon),
                        title: Text(item.title),
                        onTap: () {
                          Navigator.pop(context);
                          item.onTap?.call();
                        },
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 80,
          padding: const EdgeInsets.all(16),
          child: const Row(
            children: [
              Icon(Icons.sports, size: 32),
              SizedBox(width: 12),
              Text(
                '運動會系統',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView(
            children: navigationItems!
                .map((item) => ListTile(
                      leading: Icon(item.icon),
                      title: Text(item.title),
                      onTap: item.onTap,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

/// 導航項目
class NavigationItem {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const NavigationItem({
    required this.title,
    required this.icon,
    this.onTap,
  });
} 