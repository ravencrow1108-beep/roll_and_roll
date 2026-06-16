import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
// 【调试用】取消注释以启用单人快速入口
// import 'presentation/pages/live_mode/live_mode_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(const MyApp());
}
//TODO:地图频繁渲染闪屏 局内添加角色 攻击便捷扣血 聊天框悬浮 局内背包 地图缩放拖动 主持和玩家权限区分 保存确认提醒 地图缩放的网格自适应以及比例尺 视野和光源 大地图局内小地图入口 局内主持和玩家头像 局内语音聊天功能 投掷动画