# AGENTS.md

## Project Overview

Roll and Roll — a Flutter tabletop RPG tool with character management, dice rolling, and multiplayer room support.

- **SDK**: Dart ^3.12.2, Flutter (Material 3)
- **Key deps**: `file_picker`, `flutter_webrtc` (Phase 1+)

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
│       ├── socket_support.dart        # 旧接口 + 平台路由 (Phase 0: 保留)
│       ├── socket_support_io.dart     # Native socket 实现 (Phase 2: 删除)
│       ├── socket_support_web.dart    # Web 桩实现 (Phase 2: 删除)
│       ├── voice_service.dart         # 局内语音 (Phase 4: 替换为 LiveKit)
│       └── transport/                 # ★ 新传输层 (Phase 0+)
│           ├── protocol/
│           │   ├── room_message.dart      # 统一游戏消息信封
│           │   └── signal_message.dart    # 信令消息 (Phase 1+)
│           ├── game/
│           │   ├── game_transport.dart    # GameTransport 抽象
│           │   ├── websocket_game.dart    # WebSocket 实现 (Phase 0)
│           │   └── webrtc_game.dart       # WebRTC 实现 (Phase 2+)
│           ├── signaling/
│           │   ├── signaling_transport.dart    # SignalingTransport 抽象
│           │   └── websocket_signaling.dart    # WebSocket 信令 (Phase 1+)
│           └── legacy/
│               └── socket_support_adapter.dart # 旧接口适配器
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

## Multiplayer Migration Phases

| Phase | Status | Description |
|-------|--------|-------------|
| **Phase 0** | ✅ Done | 创建 transport/ 抽象层，包装现有 WebSocket，UI 零改动 |
| **Phase 1** | 📋 Planned | Cloudflare Worker + Durable Object 信令，WebRTC 建立 |
| **Phase 2** | 📋 Planned | 替换全部传输层为 WebRTC，移除 socket_support 旧实现 |
| **Phase 3** | 📋 Planned | 全平台（Web/Android/iOS）+ 多玩家并发测试 |
| **Phase 4** | 📋 Planned | R2 地图 + LiveKit 语音 + Host 迁移 + 房间大厅 |

## Import conventions

- Page files import models via barrel: `import '../../../data/models/models.dart';`
- Room state: `import '../../providers/room_state.dart';` (from pages)
- Socket services: `import '../../../data/services/socket_support.dart';` (from pages)
- Transport layer: `import '../../../data/services/transport/...';` (Phase 2+)

## Data flow (Phase 0)

```
UI (create_room_page / join_room_page / adventure_page)
 │
 │  RoomServerHandle / RoomClientHandle  (旧接口，不变)
 │
RoomSession
 │
 │  PlatformSocketSupport.startServer() / connectToRoom()
 │
 ├─ ServerHandleAdapter / ClientHandleAdapter  (旧→新转换)
 │
 ├─ WebSocketHostGameTransport / WebSocketClientGameTransport
 │
 └─ IoRoomServerHandle / IoRoomClientHandle  (现有 WebSocket，Phase 2 移除)
```

## Conventions

- **UI language**: Chinese (中文)
- **State management**: `StatefulWidget` + `setState` (no external state library)
- **Platform branching**: Conditional imports (`dart.library.html`) in `socket_support.dart`
- **JSON**: All models use `toJson()` / `fromJson()` factory pattern
- **Singletons**: `RoomSession.instance` for shared room state
- **Dice notation**: `DiceExpression.roll("2d6+3")` or with attribute modifiers like `"d20+力量"`
- **Message protocol**: `RoomMessage` (version, messageId, timestamp, type, senderId, payload) — Phase 0 internal only, Phase 2+ wire format
