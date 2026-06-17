import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../../data/models/models.dart';
import 'backpack_panel.dart';
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
    this.backpackItems = const [],
    this.backpackSlotMax = 40,
    this.onPositionChanged,
    this.onEditHp,
    this.onAddNote,
    this.onDeleteNote,
    super.key,
  });

  final MapData mapData;
  final List<PlayerPosition> positions;
  final List<EnemyData> enemies;
  final bool isGM;
  final String playerName;
  final CharacterData? character;
  final List<CharacterData> characters;
  final List<ItemData> backpackItems;
  final int backpackSlotMax;
  /// GM 移动角色位置后调
  final void Function(int index, PlayerPosition newPos)? onPositionChanged;
  /// GM 右键编辑角色血量
  final void Function(String characterName)? onEditHp;
  /// GM 右键添加角色注释
  final void Function(String characterName)? onAddNote;
  /// GM 删除角色注释
  final void Function(String characterName, int noteIndex)? onDeleteNote;

  @override
  State<MapDisplay> createState() => _MapDisplayState();
}

class _MapDisplayState extends State<MapDisplay> {
  bool _showGrid = true;
  bool _showCoords = true;
  bool _showBackpack = false;
  final bool _showMinorGrid = false;

  /// 地图图片的原始宽高（像素），异步解码后缓存。
  Size? _imageNaturalSize;

  /// 缓存解码后的地图图片字节，避免每次 build 重新 base64Decode 导致闪烁。
  Uint8List? _cachedImageBytes;

  // ── GM 拖拽移动 ──
  int? _draggedIndex;
  PlayerPosition? _dragOriginal;
  Offset? _dragCurrentFraction;
  String _dragDistanceText = '';

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
      _cachedImageBytes = null;
      _decodeImageSize();
    }
  }

  Future<void> _decodeImageSize() async {
    final b64 = widget.mapData.imageBase64;
    if (b64.isEmpty) return;
    try {
      final bytes = Uint8List.fromList(base64Decode(b64));
      _cachedImageBytes = bytes;
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width.toDouble();
      final h = frame.image.height.toDouble();
      frame.image.dispose();
      if (!mounted) return;
      setState(() {
        _imageNaturalSize = Size(w, h);
      });
    } catch (_) {
      if (!mounted) return;
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.isGM ? '主持模式' : widget.playerName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      // ── GM 拖拽距离信息 ──
                      if (_dragDistanceText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _dragDistanceText,
                            style: TextStyle(
                              color: Colors.deepPurple.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
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
              const SizedBox(width: 2),
              _GridToggle(
                icon: Icons.backpack_outlined,
                tooltip: _showBackpack ? '关闭背包' : '显示背包',
                active: _showBackpack,
                onTap: () => setState(() => _showBackpack = !_showBackpack),
              ),
            ],
          ),
          // ── 背包物品栏 ──
          if (_showBackpack && widget.backpackItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: BackpackPanel(
                backpack: widget.backpackItems,
                slotMax: widget.backpackSlotMax,
              ),
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
                            // 使用缓存的字节避免每次 build 重新解码；
                            // RepaintBoundary 隔离背景层，网格/token 更新时不会触发背景重绘。
                            if (_cachedImageBytes != null)
                              Positioned.fill(
                                child: RepaintBoundary(
                                  child: Image.memory(
                                    _cachedImageBytes!,
                                    fit: BoxFit.contain,
                                    gaplessPlayback: true,
                                  ),
                                ),
                              ),
                            // ── 图片实际渲染区域内的网格与 token ──
                            Positioned(
                              left: renderRect.left,
                              top: renderRect.top,
                              width: renderRect.width,
                              height: renderRect.height,
                              child: RepaintBoundary(
                                child: Listener(
                                behavior: HitTestBehavior.translucent,
                                onPointerDown: widget.isGM
                                    ? (e) => _onPointerDown(
                                          e,
                                          renderConstraints,
                                        )
                                    : null,
                                onPointerMove: widget.isGM
                                    ? (e) => _onPointerMove(
                                          e,
                                          renderConstraints,
                                        )
                                    : null,
                                onPointerUp: widget.isGM
                                    ? (e) => _onPointerUp(e, renderConstraints)
                                    : null,
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
                                    for (int i = 0;
                                        i < widget.positions.length;
                                        i++)
                                      _buildPlayerToken(
                                        widget.positions[i],
                                        renderConstraints,
                                        i,
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

  // ──────────────────── 拖拽逻辑 ────────────────────

  static const double _tokenHitRadius = 24; // 点击判定半径（像素）

  void _onPointerDown(PointerDownEvent e, BoxConstraints rc) {
    final fx = e.localPosition.dx / rc.maxWidth;
    final fy = e.localPosition.dy / rc.maxHeight;

    // 右键：检测命中玩家 token → 弹出菜单
    if (e.buttons == 2) {
      _cancelDrag();
      for (int i = 0; i < widget.positions.length; i++) {
        final pos = widget.positions[i];
        final dx = (pos.x - fx) * rc.maxWidth;
        final dy = (pos.y - fy) * rc.maxHeight;
        if (dx * dx + dy * dy <= _tokenHitRadius * _tokenHitRadius) {
          _showContextMenu(e.position, pos.name);
          return;
        }
      }
      return;
    }

    // 左键：检测是否命中某个 player token → 开始拖拽
    for (int i = 0; i < widget.positions.length; i++) {
      final pos = widget.positions[i];
      final dx = (pos.x - fx) * rc.maxWidth;
      final dy = (pos.y - fy) * rc.maxHeight;
      if (dx * dx + dy * dy <= _tokenHitRadius * _tokenHitRadius) {
        setState(() {
          _draggedIndex = i;
          _dragOriginal = pos;
          _dragCurrentFraction = Offset(pos.x, pos.y);
          _updateDistance(rc);
        });
        return;
      }
    }
  }

  void _onPointerMove(PointerMoveEvent e, BoxConstraints rc) {
    if (_draggedIndex == null) return;
    final fx = (e.localPosition.dx / rc.maxWidth).clamp(0.0, 1.0);
    final fy = (e.localPosition.dy / rc.maxHeight).clamp(0.0, 1.0);
    setState(() {
      _dragCurrentFraction = Offset(fx, fy);
      _updateDistance(rc);
    });
  }

  void _onPointerUp(PointerUpEvent e, BoxConstraints rc) {
    if (_draggedIndex == null) return;
    _confirmPlacement();
  }

  void _confirmPlacement() {
    if (_draggedIndex == null || _dragCurrentFraction == null) return;
    final newPos = PlayerPosition(
      name: widget.positions[_draggedIndex!].name,
      x: _dragCurrentFraction!.dx,
      y: _dragCurrentFraction!.dy,
    );
    widget.onPositionChanged?.call(_draggedIndex!, newPos);
    setState(() {
      _draggedIndex = null;
      _dragOriginal = null;
      _dragCurrentFraction = null;
      _dragDistanceText = '';
    });
  }

  void _cancelDrag() {
    setState(() {
      _draggedIndex = null;
      _dragOriginal = null;
      _dragCurrentFraction = null;
      _dragDistanceText = '';
    });
  }

  void _showContextMenu(Offset globalPosition, String characterName) {
    final overlay =
        Overlay.of(context, rootOverlay: true).context.findRenderObject();
    if (overlay is! RenderBox) return;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: 'note',
          child: ListTile(
            leading: Icon(Icons.edit_note),
            title: Text('注释'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'hp',
          child: ListTile(
            leading: Icon(Icons.favorite),
            title: Text('编辑血量'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    ).then((value) {
      if (value == 'hp') {
        widget.onEditHp?.call(characterName);
      } else if (value == 'note') {
        widget.onAddNote?.call(characterName);
      }
    });
  }

  void _updateDistance(BoxConstraints rc) {
    if (_dragOriginal == null || _dragCurrentFraction == null) {
      _dragDistanceText = '';
      return;
    }
    final m = widget.mapData;
    final dxGrid =
        (_dragCurrentFraction!.dx - _dragOriginal!.x) * m.width;
    final dyGrid =
        (_dragCurrentFraction!.dy - _dragOriginal!.y) * m.height;
    final distVal = _sqrt(dxGrid * dxGrid + dyGrid * dyGrid);
    _dragDistanceText =
        '↕ ${distVal.toStringAsFixed(1)} ${m.unit}  '
        '(ΔX: ${dxGrid.toStringAsFixed(1)}, ΔY: ${dyGrid.toStringAsFixed(1)})';
  }

  double _sqrt(double v) {
    if (v <= 0) return 0;
    double x = v;
    for (int i = 0; i < 10; i++) {
      x = (x + v / x) / 2;
    }
    return x;
  }

  // ──────────────────── Token 构建 ────────────────────

  Widget _buildPlayerToken(
    PlayerPosition pos,
    BoxConstraints constraints,
    int index,
  ) {
    final char = _findCharacter(pos.name);
    final isDragged = _draggedIndex == index;
    final displayX = isDragged && _dragCurrentFraction != null
        ? _dragCurrentFraction!.dx
        : pos.x;
    final displayY = isDragged && _dragCurrentFraction != null
        ? _dragCurrentFraction!.dy
        : pos.y;

    return TokenWidget(
      key: ValueKey(pos.name),
      x: displayX,
      y: displayY,
      initial: pos.name[0].toUpperCase(),
      label: pos.name,
      isPlayer: true,
      constraints: constraints,
      portraitBase64: char?.portraitBase64,
      hp: char?.hp,
      maxHp: char?.maxHp,
      isDragged: isDragged,
      notes: char?.notes ?? const [],
      characterData: char,
      onDeleteNote: widget.isGM && (char?.notes.isNotEmpty == true)
          ? (int i) => widget.onDeleteNote?.call(pos.name, i)
          : null,
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
