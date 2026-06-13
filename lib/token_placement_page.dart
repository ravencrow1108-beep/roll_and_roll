import 'dart:convert';

import 'package:flutter/material.dart';

import 'adventure_page.dart';
import 'room_state.dart';
import 'save_data.dart';

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
  /// Map from player name → (x fraction, y fraction)
  final Map<String, Offset> _positions = {};
  String? _selectedPlayer;

  @override
  void initState() {
    super.initState();
    // Broadcast host is setting up
    RoomSession.instance.broadcast({'type': 'host_setting_up'});
  }

  List<String> get _players {
    final all = RoomSession.instance.membersNotifier.value;
    final host =
        RoomSession.instance.hostNameNotifier.value ?? widget.playerName;
    return all.where((n) => n != host).toList();
  }

  void _placePlayer(String name, Offset fraction) {
    setState(() => _positions[name] = fraction);
  }

  void _removePlayer(String name) {
    setState(() {
      _positions.remove(name);
      if (_selectedPlayer == name) _selectedPlayer = null;
    });
  }

  void _confirmAndStart() {
    if (_players.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有玩家需要放置')));
      return;
    }

    final placements = <Map<String, dynamic>>[];
    for (final name in _players) {
      final pos = _positions[name];
      placements.add({'name': name, 'x': pos?.dx ?? 0.5, 'y': pos?.dy ?? 0.5});
    }

    final session = RoomSession.instance;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          RoomSession.instance.broadcast({'type': 'return_to_room'});
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('布置玩家位置 · ${widget.map.name}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              RoomSession.instance.broadcast({'type': 'return_to_room'});
              Navigator.of(context).pop();
            },
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
                        if (_selectedPlayer == null) return;
                        final fx =
                            details.localPosition.dx / constraints.maxWidth;
                        final fy =
                            details.localPosition.dy / constraints.maxHeight;
                        _placePlayer(
                          _selectedPlayer!,
                          Offset(fx.clamp(0, 1), fy.clamp(0, 1)),
                        );
                        _selectedPlayer = null;
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
                                onTap: () => _removePlayer(entry.key),
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
                          if (_selectedPlayer != null)
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
                                  '点击地图放置「$_selectedPlayer」的位置',
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

            // ── 玩家列表 ──
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      '玩家 (${_players.length}) — 选择玩家后点击地图放置',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _players.length,
                      itemBuilder: (_, i) {
                        final name = _players[i];
                        final placed = _positions.containsKey(name);
                        final selected = _selectedPlayer == name;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPlayer = selected ? null : name;
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: placed
                                          ? Colors.green
                                          : Colors.grey.shade300,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: placed
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 20,
                                            )
                                          : const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                    ),
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
