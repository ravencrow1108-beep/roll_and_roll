import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../../data/models/models.dart';
import 'coordinate_grid.dart';
import 'token_widget.dart';

/// 地图中心展示区域，含坐标系网格覆盖层。
/// 坐标原点为地图图片的实际渲染区域左上角。
class MapDisplay extends StatefulWidget {
  const MapDisplay({
    required this.mapData,
    required this.positions,
    required this.enemies,
    required this.isGM,
    required this.playerName,
    this.character,
    this.characters = const [],
    super.key,
  });

  final MapData mapData;
  final List<PlayerPosition> positions;
  final List<EnemyData> enemies;
  final bool isGM;
  final String playerName;
  final CharacterData? character;
  final List<CharacterData> characters;

  @override
  State<MapDisplay> createState() => _MapDisplayState();
}

class _MapDisplayState extends State<MapDisplay> {
  bool _showGrid = true;
  bool _showCoords = true;
  bool _showMinorGrid = false;

  /// 地图图片的原始宽高（像素），异步解码后缓存。
  Size? _imageNaturalSize;
  bool _imageDecoded = false;

  @override
  void initState() {
    super.initState();
    _decodeImageSize();
  }

  @override
  void didUpdateWidget(covariant MapDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapData.imageBase64 != widget.mapData.imageBase64) {
      _imageNaturalSize = null;
      _imageDecoded = false;
      _decodeImageSize();
    }
  }

  Future<void> _decodeImageSize() async {
    final b64 = widget.mapData.imageBase64;
    if (b64.isEmpty) {
      _imageDecoded = true;
      return;
    }
    try {
      final bytes = base64Decode(b64);
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      final frame = await codec.getNextFrame();
      final w = frame.image.width.toDouble();
      final h = frame.image.height.toDouble();
      frame.image.dispose();
      if (!mounted) return;
      setState(() {
        _imageNaturalSize = Size(w, h);
        _imageDecoded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _imageDecoded = true);
    }
  }

  /// 计算 BoxFit.contain 后图片在容器内的实际渲染区域。
  Rect _imageRenderRect(BoxConstraints constraints) {
    if (_imageNaturalSize == null) {
      return Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight);
    }
    final imgW = _imageNaturalSize!.width;
    final imgH = _imageNaturalSize!.height;
    final scale = (constraints.maxWidth / imgW) < (constraints.maxHeight / imgH)
        ? constraints.maxWidth / imgW
        : constraints.maxHeight / imgH;
    final renderW = imgW * scale;
    final renderH = imgH * scale;
    final offsetX = (constraints.maxWidth - renderW) / 2;
    final offsetY = (constraints.maxHeight - renderH) / 2;
    return Rect.fromLTWH(offsetX, offsetY, renderW, renderH);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = widget.mapData;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              if (widget.character != null) ...[
                if (widget.character!.portraitBase64.isNotEmpty)
                  ClipOval(
                    child: Image.memory(
                      base64Decode(widget.character!.portraitBase64),
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.character!.name,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                Expanded(
                  child: Text(
                    widget.isGM ? '主持模式' : widget.playerName,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
              // ── 网格控制按钮 ──
              _GridToggle(
                icon: Icons.grid_on,
                tooltip: _showGrid ? '关闭网格' : '显示网格',
                active: _showGrid,
                onTap: () => setState(() => _showGrid = !_showGrid),
              ),
              _GridToggle(
                icon: Icons.pin_drop_outlined,
                tooltip: _showCoords ? '隐藏坐标' : '显示坐标',
                active: _showCoords,
                onTap: () => setState(() => _showCoords = !_showCoords),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: m.imageBase64.isNotEmpty
                ? LayoutBuilder(
                    builder: (ctx, constraints) {
                      final renderRect = _imageRenderRect(constraints);
                      final renderConstraints = BoxConstraints.tight(
                        Size(renderRect.width, renderRect.height),
                      );

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            // 背景图片（BoxFit.contain）
                            Positioned.fill(
                              child: Image.memory(
                                base64Decode(m.imageBase64),
                                fit: BoxFit.contain,
                              ),
                            ),
                            // ── 图片实际渲染区域内的网格与 token ──
                            Positioned(
                              left: renderRect.left,
                              top: renderRect.top,
                              width: renderRect.width,
                              height: renderRect.height,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // 坐标系网格（基于图片左上角）
                                  if (_showGrid || _showCoords)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: CoordinateGridPainter(
                                          columns: m.width,
                                          rows: m.height,
                                          unit:
                                              _showCoords ? m.unit : '',
                                          showLabels: _showCoords,
                                          showGrid: _showGrid,
                                          showMinorGrid: _showMinorGrid,
                                        ),
                                      ),
                                    ),
                                  // 玩家 token
                                  for (final pos in widget.positions)
                                    _buildPlayerToken(
                                      pos,
                                      renderConstraints,
                                    ),
                                  // 敌人 token
                                  for (final e in widget.enemies)
                                    TokenWidget(
                                      x: e.x,
                                      y: e.y,
                                      initial: e.name.isNotEmpty
                                          ? e.name[0].toUpperCase()
                                          : 'E',
                                      label: '${e.name} HP${e.hp}',
                                      isPlayer: false,
                                      constraints: renderConstraints,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      m.name,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 18,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerToken(PlayerPosition pos, BoxConstraints constraints) {
    final char = _findCharacter(pos.name);
    return TokenWidget(
      x: pos.x,
      y: pos.y,
      initial: pos.name[0].toUpperCase(),
      label: pos.name,
      isPlayer: true,
      constraints: constraints,
      portraitBase64: char?.portraitBase64,
      hp: char?.hp,
      maxHp: char?.maxHp,
    );
  }

  CharacterData? _findCharacter(String name) {
    // First check the player's own character
    if (widget.character?.name == name) return widget.character;
    // Then search the full character list
    try {
      return widget.characters.cast<CharacterData?>().firstWhere(
        (c) => c?.name == name,
        orElse: () => null,
      );
    } catch (_) {
      return null;
    }
  }
}

/// 网格/坐标切换小按钮
class _GridToggle extends StatelessWidget {
  const _GridToggle({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(
            color: active
                ? Colors.deepPurple.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? Colors.deepPurple : Colors.grey,
          ),
        ),
      ),
    );
  }
}
