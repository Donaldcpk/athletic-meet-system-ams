/// 通用AppBar組件
/// 為所有頁面提供統一的導航體驗

import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final String? backRoute;
  final VoidCallback? onBackPressed;

  const CommonAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.backRoute = '/dashboard',
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      leading: showBackButton ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed ?? () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, backRoute ?? '/dashboard');
          }
        },
        tooltip: '返回',
      ) : null,
      actions: [
        // 添加快速操作按鈕
        IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/dashboard',
              (route) => false,
            );
          },
          tooltip: '返回首頁',
        ),
        ...?actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// 擴展AppBar - 包含更多功能
class ExtendedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final String? backRoute;
  final VoidCallback? onRefresh;

  const ExtendedAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = true,
    this.backRoute = '/dashboard',
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      leading: showBackButton ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, backRoute ?? '/dashboard');
          }
        },
        tooltip: '返回',
      ) : null,
      actions: [
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
            tooltip: '刷新',
          ),
        IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/dashboard',
              (route) => false,
            );
          },
          tooltip: '返回首頁',
        ),
        ...?actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
