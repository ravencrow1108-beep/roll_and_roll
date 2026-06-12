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

| File | Purpose |
|---|---|
| `lib/main.dart` | App entry, home page (player setup, room join/create) |
| `lib/adventure_page.dart` | Adventure view: character selection, dice rolling |
| `lib/create_save_page.dart` | Character & save file creation UI |
| `lib/save_data.dart` | Data models (`CharacterData`, `DiceExpression`, etc.) & JSON serialization |
| `lib/room_state.dart` | Singleton `RoomSession` with `ValueNotifier` for room state |
| `lib/socket_support.dart` | Platform-agnostic socket abstraction |
| `lib/socket_support_io.dart` | Native socket (desktop) implementation |
| `lib/socket_support_web.dart` | Web stub (sockets unsupported on web) |

## Conventions

- **UI language**: Chinese (中文)
- **State management**: `StatefulWidget` + `setState` (no external state library)
- **Platform branching**: Conditional imports (`dart.library.html`) in `socket_support.dart`
- **JSON**: All models use `toJson()` / `fromJson()` factory pattern
- **Singletons**: `RoomSession.instance` for shared room state
- **Dice notation**: `DiceExpression.roll("2d6+3")` or with attribute modifiers like `"d20+力量"`
