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
    this.onPlayerTap,
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

  /// 单击玩家 token 时回调
  final void Function(String characterName)? onPlayerTap;

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

  // ── 缩放 ──
  final TransformationController _transformCtrl = TransformationController();
  double _currentScale = 1.0;

  // ── GM 拖拽移动 ──
  int? _draggedIndex;
  PlayerPosition? _dragOriginal;
  Offset? _pointerDownPos;
  Offset? _dragCurrentFraction;
  String _dragDistanceText = '';

  @override
  void initState() {
    super.initState();
    _decodeImageSize();
    _transformCtrl.addListener(_onScaleChanged);
  }

  @override
  void dispose() {
    _transformCtrl.removeListener(_onScaleChanged);
    _transformCtrl.dispose();
    super.dispose();
  }

  void _onScaleChanged() {
    final s = _transformCtrl.value.getMaxScaleOnAxis();
    if ((s - _currentScale).abs() > 0.01) {
      setState(() => _currentScale = s);
    }
  }

  @override
  void didUpdateWidget(covariant MapDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapData.imageBase64 != widget.mapData.imageBase64) {
      _imageNaturalSize = null;
      _cachedImageBytes = null;
      _decodeImageSize();
      _transformCtrl.value = Matrix4.identity();
      _currentScale = 1.0;
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

  /// 计算自适应网格步长：基于当前缩放找到合适的整数步长
  int _calcGridStep(double renderW, int totalCols) {
    if (totalCols <= 0) return 1;
    final cellPx = renderW / totalCols;
    // 目标：每个格子在屏幕上至少 ~25px
    const targetPx = 25.0;
    int step = (targetPx / cellPx).ceil();
    // 对齐到好看的数字：1,2,5,10,20,50,100...
    if (step <= 1) return 1;
    if (step <= 2) return 2;
    if (step <= 5) return 5;
    final mag = (step / 10).ceil();
    // 10,20,50,100,200,500...
    if (mag <= 1) return 10;
    if (mag <= 2) return 20;
    if (mag <= 5) return 50;
    return (mag / 5).ceil() * 50;
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
          // ── 背包物品栏（限制最大高度，避免挤压地图） ──
          if (_showBackpack && widget.backpackItems.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 80),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: BackpackPanel(
                    backpack: widget.backpackItems,
                    slotMax: widget.backpackSlotMax,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          Expanded(
            child: m.imageBase64.isNotEmpty && _imageNaturalSize != null
                ? LayoutBuilder(
                    builder: (ctx, constraints) {
                      final imgW = _imageNaturalSize!.width;
                      final imgH = _imageNaturalSize!.height;
                      final gridStep = _calcGridStep(
                        constraints.maxWidth,
                        m.width,
                      );
                      final renderConstraints = BoxConstraints.tight(
                        Size(imgW, imgH),
                      );

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            InteractiveViewer(
                              transformationController: _transformCtrl,
                              minScale: 0.1,
                              maxScale: 8.0,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: imgW,
                                  height: imgH,
                                  child: Stack(
                                    children: [
                                      // 图片像素与网格 1:1 对齐
                                      Image.memory(
                                        _cachedImageBytes!,
                                        width: imgW,
                                        height: imgH,
                                        fit: BoxFit.fill,
                                        gaplessPlayback: true,
                                      ),
                                      Positioned.fill(
                                        child: RepaintBoundary(
                                          child: Listener(
                                            behavior:
                                                HitTestBehavior.translucent,
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
                                                ? (e) => _onPointerUp(
                                                    e,
                                                    renderConstraints,
                                                  )
                                                : null,
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                if (_showGrid || _showCoords)
                                                  Positioned.fill(
                                                    child: CustomPaint(
                                                      painter:
                                                          CoordinateGridPainter(
                                                            columns: m.width,
                                                            rows: m.height,
                                                            unit: _showCoords
                                                                ? m.unit
                                                                : '',
                                                            showLabels:
                                                                _showCoords,
                                                            showGrid: _showGrid,
                                                            showMinorGrid:
                                                                _showMinorGrid,
                                                            step: gridStep,
                                                          ),
                                                    ),
                                                  ),
                                                for (
                                                  int i = 0;
                                                  i < widget.positions.length;
                                                  i++
                                                )
                                                  _buildPlayerToken(
                                                    widget.positions[i],
                                                    renderConstraints,
                                                    i,
                                                  ),
                                                for (final e in widget.enemies)
                                                  TokenWidget(
                                                    x: e.x,
                                                    y: e.y,
                                                    initial: e.name.isNotEmpty
                                                        ? e.name[0]
                                                              .toUpperCase()
                                                        : 'E',
                                                    label:
                                                        '${e.name} HP${e.hp}',
                                                    isPlayer: false,
                                                    constraints:
                                                        renderConstraints,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // ── 比例尺 ──
                            Positioned(
                              left: 10,
                              bottom: 10,
                              child: _ScaleBar(
                                step: gridStep,
                                unit: m.unit,
                                cellWidth:
                                    (constraints.maxWidth.clamp(1, imgW) /
                                    (m.width > 0 ? m.width : 1)),
                                currentScale: _currentScale,
                              ),
                            ),
                            // ── 缩放百分比 ──
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${(_currentScale * 100).round()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
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
    _pointerDownPos = e.localPosition;
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
    // 判断是拖拽还是点击：移动距离 < 4px 视为点击
    final moved =
        _pointerDownPos != null &&
        (e.localPosition - _pointerDownPos!).distance > 4.0;
    _pointerDownPos = null;
    if (!moved && widget.isGM && widget.onPlayerTap != null) {
      // 单击 → 选中该玩家
      final name = widget.positions[_draggedIndex!].name;
      _cancelDrag();
      widget.onPlayerTap!(name);
      return;
    }
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
    final overlay = Overlay.of(
      context,
      rootOverlay: true,
    ).context.findRenderObject();
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
    final dxGrid = (_dragCurrentFraction!.dx - _dragOriginal!.x) * m.width;
    final dyGrid = (_dragCurrentFraction!.dy - _dragOriginal!.y) * m.height;
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

/// 比例尺组件：显示当前缩放下一段距离对应的像素长度
class _ScaleBar extends StatelessWidget {
  const _ScaleBar({
    required this.step,
    required this.unit,
    required this.cellWidth,
    required this.currentScale,
  });

  final int step;
  final String unit;
  final double cellWidth; // 一个格子在 1x 缩放下的像素宽度
  final double currentScale;

  @override
  Widget build(BuildContext context) {
    final pxPerStep = cellWidth * step * currentScale;
    // 限制最大显示宽度
    const maxBarPx = 120.0;
    final barPx = pxPerStep.clamp(20.0, maxBarPx);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: barPx, height: 3, color: Colors.white),
              const SizedBox(height: 1),
              Container(width: barPx, height: 1, color: Colors.white70),
            ],
          ),
          const SizedBox(width: 6),
          Text(
            '$step $unit',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
