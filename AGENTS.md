# AGENTS.md

## Project Overview

Roll and Roll — a Flutter tabletop RPG tool with character management, dice rolling, and multiplayer room support.

- **SDK**: Dart ^3.12.2, Flutter (Material 3)
- **Key deps**: `file_picker`

## Build & Run

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device
flutter analyze          # Static analysis
flutter test             # Run tests
```

## Architecture

```
lib/
├── main.dart                          # 入口文件
├── app.dart                           # 应用配置 (MyApp, Material 3 theme)
├── core/                              # 核心功能
│   ├── constants/                     # 常量定义
│   ├── theme/                         # 主题配置
│   └── utils/                         # 工具类
├── data/                              # 数据层
│   ├── models/                        # 数据模型
│   │   ├── models.dart                # barrel export
│   │   ├── character_data.dart        # CharacterData
│   │   ├── chat_message.dart          # ChatMessage
│   │   ├── dice_expression.dart       # DiceExpression, DiceRollResult
│   │   ├── enemy_data.dart            # EnemyData
│   │   ├── item_data.dart             # ItemData
│   │   ├── map_data.dart              # MapData
│   │   ├── map_tile.dart              # MapTile
│   │   ├── personality_data.dart      # PersonalityData
│   │   ├── player_info.dart           # PlayerInfo
│   │   ├── player_position.dart       # PlayerPosition
│   │   ├── rule_data.dart             # RuleData
│   │   ├── save_data.dart             # SaveData (ZIP I/O)
│   │   └── skill_data.dart            # SkillData
│   ├── repositories/                  # 仓库（数据接口）
│   └── services/                      # 网络服务
│       ├── socket_support.dart        # 抽象接口 + 平台路由
│       ├── socket_support_io.dart     # Native socket 实现
│       └── socket_support_web.dart    # Web 桩实现
├── domain/                            # 领域层
│   └── entities/                      # 实体类
├── presentation/                      # 展示层
│   ├── pages/                         # 页面
│   │   ├── adventure/                 # 冒险主页面
│   │   ├── character_select/          # 角色选择
│   │   ├── create_room/               # 创建房间
│   │   ├── create_save/               # 创建/编辑存档
│   │   ├── home/                      # 首页
│   │   ├── join_room/                 # 加入房间
│   │   ├── live_mode/                 # 单人快速入口
│   │   ├── map_edit/                  # 地图编辑（DM用）
│   │   ├── map_editor/                # 地图编辑器
│   │   └── token_placement/           # Token放置
│   ├── widgets/                       # 组件
│   └── providers/                     # 状态管理
│       └── room_state.dart            # RoomSession 单例
└── routes/                            # 路由配置
```

## Import conventions

- Page files import models via barrel: `import '../../../data/models/models.dart';`
- Room state: `import '../../providers/room_state.dart';` (from pages)
- Socket services: `import '../../../data/services/socket_support.dart';` (from pages)

## Conventions

- **UI language**: Chinese (中文)
- **State management**: `StatefulWidget` + `setState` (no external state library)
- **Platform branching**: Conditional imports (`dart.library.html`) in `socket_support.dart`
- **JSON**: All models use `toJson()` / `fromJson()` factory pattern
- **Singletons**: `RoomSession.instance` for shared room state
- **Dice notation**: `DiceExpression.roll("2d6+3")` or with attribute modifiers like `"d20+力量"`
