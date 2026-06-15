import 'dart:convert';

import 'package:flutter/material.dart';

import '../../providers/room_state.dart';
import '../../../data/models/models.dart';
import '../adventure/adventure_page.dart';

/// 主持布置角色位置页面：在地图上点击放置各角色的初始标记
class TokenPlacementPage extends StatefulWidget {
  const TokenPlacementPage({
    required this.playerName,
    required this.role,
    required this.map,
    this.saveFilePath,
    super.key,
  });

  final String playerName;
  final String role;
  final MapData map;
  final String? saveFilePath;

  @override
  State<TokenPlacementPage> createState() => _TokenPlacementPageState();
}

class _TokenPlacementPageState extends State<TokenPlacementPage> {
  /// Map from character name → (x fraction, y fraction)
  final Map<String, Offset> _positions = {};
  String? _selectedCharacter;

  /// Characters loaded from the save file.
  List<CharacterData> _characters = [];

  @override
  void initState() {
    super.initState();
    // Broadcast host is setting up
    RoomSession.instance.broadcast({'type': 'host_setting_up'});
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    if (widget.saveFilePath == null) return;
    try {
      final save = await SaveData.fromZip(widget.saveFilePath!);
      if (mounted) {
        setState(() => _characters = save.characters);
      }
    } catch (_) {
      _characters = [];
    }
  }

  List<String> get _characterNames => _characters.map((c) => c.name).toList();

  void _placeCharacter(String name, Offset fraction) {
    setState(() => _positions[name] = fraction);
  }

  void _removeCharacter(String name) {
    setState(() {
      _positions.remove(name);
      if (_selectedCharacter == name) _selectedCharacter = null;
    });
  }

  void _cancelPlacement() {
    RoomSession.instance.broadcast({'type': 'return_to_room'});
    // Reset adventure state so the host can re-enter from the room
    RoomSession.instance.startAdventureNotifier.value = false;
    RoomSession.instance.mapNotifier.value = null;
    Navigator.of(context).pop();
  }

  void _confirmAndStart() {
    final session = RoomSession.instance;
    final placements = <Map<String, dynamic>>[];

    for (final name in _characterNames) {
      final pos = _positions[name];
      placements.add({'name': name, 'x': pos?.dx ?? 0.5, 'y': pos?.dy ?? 0.5});
    }

    session.mapNotifier.value = widget.map;
    session.playerPositionsNotifier.value = placements
        .map(
          (p) => PlayerPosition(
            name: p['name'] as String,
            x: (p['x'] as num).toDouble(),
            y: (p['y'] as num).toDouble(),
          ),
        )
        .toList();

    session.startAdventureNotifier.value = true;

    session.broadcast({
      'type': 'adventure_started',
      'map': widget.map.toJson(),
      'positions': placements,
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AdventurePage(
          playerName: widget.playerName,
          role: widget.role,
          saveFilePath: widget.saveFilePath,
        ),
      ),
    );
  }

  /// 构建地图放置区域与底部角色选择列表
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _cancelPlacement();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('布置角色位置 · ${widget.map.name}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _cancelPlacement,
          ),
          actions: [
            TextButton.icon(
              onPressed: _confirmAndStart,
              icon: const Icon(Icons.rocket_launch_outlined),
              label: const Text('开始冒险', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
        body: Column(
          children: [
            // ── 地图区域 ──
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    return GestureDetector(
                      onTapUp: (details) {
                        if (_selectedCharacter == null) return;
                        final fx =
                            details.localPosition.dx / constraints.maxWidth;
                        final fy =
                            details.localPosition.dy / constraints.maxHeight;
                        _placeCharacter(
                          _selectedCharacter!,
                          Offset(fx.clamp(0, 1), fy.clamp(0, 1)),
                        );
                        _selectedCharacter = null;
                      },
                      child: Stack(
                        children: [
                          // Map image
                          if (widget.map.imageBase64.isNotEmpty)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(widget.map.imageBase64),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                          else
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.shade300,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    widget.map.name,
                                    style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // Grid overlay
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _GridPainter(
                                color: Colors.black.withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                          // Placed tokens
                          for (final entry in _positions.entries)
                            Positioned(
                              left: entry.value.dx * constraints.maxWidth - 16,
                              top: entry.value.dy * constraints.maxHeight - 16,
                              child: GestureDetector(
                                onTap: () => _removeCharacter(entry.key),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          entry.key[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Hint text
                          if (_selectedCharacter != null)
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withValues(
                                    alpha: 0.85,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '点击地图放置「$_selectedCharacter」的位置',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── 角色列表 ──
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: _characters.isEmpty
                  ? Center(
                      child: Text(
                        '存档中没有角色',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            '角色 (${_characterNames.length}) — 选择角色后点击地图放置',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _characterNames.length,
                            itemBuilder: (_, i) {
                              final name = _characterNames[i];
                              final character = _characters[i];
                              final placed = _positions.containsKey(name);
                              final selected = _selectedCharacter == name;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCharacter = selected
                                          ? null
                                          : name;
                                    });
                                  },
                                  child: Container(
                                    width: 90,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? Colors.deepPurple.shade50
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected
                                            ? Colors.deepPurple
                                            : Colors.grey.shade300,
                                        width: selected ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _PortraitCircle(
                                          portraitBase64:
                                              character.portraitBase64,
                                          placed: placed,
                                          name: name,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: selected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 角色头像圆形组件，有图片时显示图片，无图片时显示首字母
class _PortraitCircle extends StatelessWidget {
  const _PortraitCircle({
    required this.portraitBase64,
    required this.placed,
    required this.name,
  });

  final String portraitBase64;
  final bool placed;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: placed ? Colors.green : Colors.grey.shade400,
          width: placed ? 2.5 : 1,
        ),
      ),
      child: ClipOval(
        child: placed
            ? Stack(
                fit: StackFit.expand,
                children: [
                  _portraitOrInitial(),
                  Container(
                    color: Colors.green.withValues(alpha: 0.4),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              )
            : _portraitOrInitial(),
      ),
    );
  }

  Widget _portraitOrInitial() {
    if (portraitBase64.isNotEmpty) {
      return Image.memory(
        base64Decode(portraitBase64),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _initialFallback(),
      );
    }
    return _initialFallback();
  }

  Widget _initialFallback() {
    return Container(
      color: Colors.deepPurple.shade200,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

/// Draws a light grid on top of the map for placement reference.
class _GridPainter extends CustomPainter {
  _GridPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const cells = 5;
    for (int i = 1; i < cells; i++) {
      final x = size.width * i / cells;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      final y = size.height * i / cells;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
