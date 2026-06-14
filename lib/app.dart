import 'package:flutter/material.dart';

import 'presentation/pages/home/home_page.dart';

/// 应用根组件，配置 Material 3 主题与首页入口
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// 构建带有 Material 3 主题与调试横幅关闭的应用入口
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roll and Roll',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 98, 57, 175),
        ),
      ),
      home: const HomePage(),
      // ═════════════════════════════════════════════
      // 【调试】单人快速入口
      // 取消下方注释并将上面 home: 行注释即可
      // 跳过主菜单直接进入直播模式（单人调试用）
      // ═════════════════════════════════════════════
      // home: const LiveModePage(),
    );
  }
}
