import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/home/home_page.dart';
// 【调试用】取消注释以启用单人快速入口
// import 'live_mode_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
