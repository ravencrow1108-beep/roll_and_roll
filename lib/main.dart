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

// 局内语音聊天功能
// 内置基础规则书
// TODO:局内添加角色
// 局内添加物品
// 背包物品拖动交互
// 视野和光源
// 局内主持和玩家头像
// 地图编辑视野阻挡物
// 地图编辑明区暗区
// 大地图局内小地图入口
// 交易货币
// 攻击便捷扣血
// 主持和玩家权限区分
// 投掷动画
