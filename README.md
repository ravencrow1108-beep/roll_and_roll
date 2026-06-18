# Roll & Roll 🐲

> 一款基于 Flutter 的桌面端桌面角色扮演（Tabletop RPG）辅助工具  
> 支持角色管理、骰子投掷、多人联机房间与直播模式

[![Flutter](https://img.shields.io/badge/Flutter-3.12+-blue)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)]()

---

## 🌐 语言 Language

[中文](#chinese) · [English](#english)

---

<span id="chinese"></span>

## 🇨🇳 中文

### 简介

Roll & Roll 是一个面向 TRPG 主持（GM）与玩家的桌面端辅助工具，提供从创建角色、管理存档到多人联机冒险、直播推流的一站式体验。

### 核心功能

| 模块 | 说明 |
|------|------|
| **角色创建** | 编辑角色信息（职业、种族、属性、技能、装备、物品），支持头像上传 |
| **地图编辑** | 创建/管理地图，地图上部署敌人和角色 Token |
| **骰子投掷** | 支持 `d20`、`2d6+3` 等标准骰子表达式 |
| **多人联机** | 主持创建房间 → 玩家加入 → 共同冒险（WebSocket 协议） |
| **冒险面板** | 左侧角色网格 + 中央地图 + 聊天浮窗，支持拖拽位置、装备管理 |
| **直播模式** | 主持视角（角色管理+地图+骰子）+ 独立玩家视角窗口（副屏），通过 `desktop_multi_window` 实现 |
| **存档管理** | ZIP 格式存档（角色 + 地图 + 规则书），支持导入/导出与进度保存 |
| **规则书** | 内置装备模板与物品模板，快速添加装备/物品到角色 |

### 快速开始

```bash
# 安装依赖
flutter pub get

# 运行
flutter run
```

### 系统要求

- **操作系统**：Windows 10+ / macOS 12+ / Linux
- **SDK**：Dart ^3.12.2, Flutter (Material 3)

### 已知限制

- 🚧 **不支持英文版**：当前仅提供中文界面，英文版计划中
- 🚧 **网络穿透**：联机使用直连 WebSocket，不支持 TCP 协议下的 NAT 穿透；如需公网联机需手动配置端口转发，团队正在评估 HTTP/WebRTC 等替代方案

### 反馈与贡献

欢迎通过 Issue 提交 Bug 报告和功能建议！

---

<span id="english"></span>

## 🇬🇧 English

> ⚠️ **This project does not currently support English.**  
> The UI, documentation, and all user-facing text are in Chinese only.  
> An English version is planned but not yet available. We appreciate your patience.

### Overview

Roll & Roll is a desktop TTRPG (Tabletop Role-Playing Game) companion tool built with Flutter, providing character management, dice rolling, multiplayer room support, and a live broadcast mode.

### Features

| Feature | Description |
|---------|-------------|
| **Character Builder** | Create and customize characters (class, race, stats, skills, equipment, items) with portrait uploads |
| **Map Editor** | Build encounter maps with enemy and player token placement |
| **Dice Rolling** | Standard dice notation support (`d20`, `2d6+3`, etc.) |
| **Multiplayer** | Host creates a room → players join → shared adventure (WebSocket) |
| **Adventure Panel** | Character grid + centered map display + floating chat, drag-to-position tokens |
| **Live Mode** | GM view (character manager + map + dice) + separate player-facing window for streaming setups |
| **Save System** | ZIP-based archives (characters + maps + rulebooks), supports import/export and progress saving |
| **Rulebook** | Built-in equipment & item templates for quick character inventory management |

### System Requirements

- **OS**: Windows 10+ / macOS 12+ / Linux
- **SDK**: Dart ^3.12.2, Flutter (Material 3)

### Known Limitations

- 🚧 **No English support**: The UI is currently Chinese-only. English localization is on the roadmap.
- 🚧 **NAT Traversal**: Multiplayer uses direct WebSocket connections without TCP-level NAT traversal. Port forwarding is required for public internet play. We are exploring HTTP-based and WebRTC alternatives.

### Feedback

Bug reports and feature suggestions are welcome via GitHub Issues!

