import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'presentation/pages/live_mode/live_window_io.dart'
    if (dart.library.html) 'presentation/pages/live_mode/live_window_stub.dart'
    as live_window;
import 'presentation/pages/live_mode/player_window.dart';

/// ── 主入口：区分 GM 主窗口与直播玩家窗口 ──
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();

  final windowArgs = await live_window.currentWindowArgs();

  if (windowArgs.isNotEmpty) {
    // 直播玩家窗口
    runApp(_LivePlayerWindowApp(windowArgs: windowArgs));
  } else {
    // GM 主窗口
    runApp(const MyApp());
  }
}

/// 直播玩家窗口 App
class _LivePlayerWindowApp extends StatelessWidget {
  const _LivePlayerWindowApp({required this.windowArgs});
  final String windowArgs;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '玩家视角 - 直播模式',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: LivePlayerWindow.fromRawJson(windowArgs),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 局内语音聊天功能未测试
// 内置基础规则书
// 背包物品拖动交互
// 视野和光源
// 地图编辑视野阻挡物
// 地图编辑明区暗区
// 大地图局内小地图入口
// 交易货币
// 攻击便捷扣血
// 主持和玩家权限区分
// 投掷动画
