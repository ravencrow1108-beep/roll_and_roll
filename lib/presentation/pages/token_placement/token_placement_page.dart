import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../providers/room_state.dart';
import '../../../data/models/models.dart';
import '../adventure/adventure_page.dart';
import '../adventure/coordinate_grid.dart';

/// 主持布置角色位置页面：在地图上点击放置各角色的初始标记
class TokenPlacementPage extends StatefulWidget {
  const TokenPlacementPage({
    required this.playerName,
    required this.role,
    required this.map,
    this.saveFilePath,
    this.existingPositions = const [],
    this.saveOnly = false,
    super.key,
  });

  final String playerName;
  final String role;
  final MapData map;
  final String? saveFilePath;

  /// 已有的角色位置，用于预填充
  final List<PlayerPosition> existingPositions;

  /// 为 true 时仅保存位置并返回，不开始冒险
  final bool saveOnly;

  @override
  State<TokenPlacementPage> createState() => _TokenPlacementPageState();
}

class _TokenPlacementPageState extends State<TokenPlacementPage> {
  /// Map from character name → (x fraction, y fraction)
  final Map<String, Offset> _positions = {};
  String? _selectedCharacter;

  /// Characters loaded from the save file.
  List<CharacterData> _characters = [];

  bool _showGrid = true;
  bool _showCoords = true;

  /// 地图图片的原始宽高（像素），异步解码后缓存。
  Size? _imageNaturalSize;

  @override
  void initState() {
    super.initState();
    if (!widget.saveOnly) {
      RoomSession.instance.broadcast({'type': 'host_setting_up'});
    }
    // 预填充已有位置
    for (final p in widget.existingPositions) {
      _positions[p.name] = Offset(p.x, p.y);
    }
    _loadCharacters();
    _decodeImageSize();
  }

  Future<void> _decodeImageSize() async {
    final b64 = widget.map.imageBase64;
    if (b64.isEmpty) return;
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
      });
    } catch (_) {}
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
    if (widget.saveOnly) {
      Navigator.of(context).pop();
      return;
    }
    RoomSession.instance.broadcast({'type': 'return_to_room'});
    RoomSession.instance.startAdventureNotifier.value = false;
    RoomSession.instance.mapNotifier.value = null;
    Navigator.of(context).pop();
  }

  /// 保存模式：仅返回位置列表
  List<PlayerPosition> _buildPositions() {
    final placements = <PlayerPosition>[];
    for (final name in _characterNames) {
      final pos = _positions[name];
      placements.add(
        PlayerPosition(name: name, x: pos?.dx ?? 0.5, y: pos?.dy ?? 0.5),
      );
    }
    return placements;
  }

  void _savePositions() {
    final placements = _buildPositions();
    Navigator.pop(context, placements);
  }

  void _confirmAndStart() {
    final session = RoomSession.instance;
    final placements = _buildPositions();

    session.mapNotifier.value = widget.map;
    session.playerPositionsNotifier.value = placements;

    session.startAdventureNotifier.value = true;

    session.broadcast({
      'type': 'adventure_started',
      'map': widget.map.toJson(),
      'positions': placements.map((p) => p.toJson()).toList(),
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
              onPressed: widget.saveOnly ? _savePositions : _confirmAndStart,
              icon: Icon(
                widget.saveOnly ? Icons.save : Icons.rocket_launch_outlined,
              ),
              label: Text(
                widget.saveOnly ? '保存' : '开始冒险',
                style: const TextStyle(fontSize: 16),
              ),
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
                child: widget.map.imageBase64.isNotEmpty
                    ? LayoutBuilder(
                        builder: (ctx, constraints) {
                          final renderRect = _imageRenderRect(constraints);
                          final renderConstraints = BoxConstraints.tight(
                            Size(renderRect.width, renderRect.height),
                          );

                          return Column(
                            children: [
                              // 网格/坐标切换按钮
                              Row(
                                children: [
                                  _GridToggle(
                                    icon: Icons.grid_on,
                                    tooltip: _showGrid ? '关闭网格' : '显示网格',
                                    active: _showGrid,
                                    onTap: () =>
                                        setState(() => _showGrid = !_showGrid),
                                  ),
                                  const SizedBox(width: 4),
                                  _GridToggle(
                                    icon: Icons.pin_drop_outlined,
                                    tooltip: _showCoords ? '隐藏坐标' : '显示坐标',
                                    active: _showCoords,
                                    onTap: () => setState(
                                      () => _showCoords = !_showCoords,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '已放置 ${_positions.length}/${_characterNames.length}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(
                                    children: [
                                      // 背景图片（BoxFit.contain）
                                      Positioned.fill(
                                        child: Image.memory(
                                          base64Decode(widget.map.imageBase64),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      // 网格、坐标与角色标记（对齐图片左上角）
                                      Positioned(
                                        left: renderRect.left,
                                        top: renderRect.top,
                                        width: renderRect.width,
                                        height: renderRect.height,
                                        child: GestureDetector(
                                          onTapUp: (details) {
                                            if (_selectedCharacter == null)
                                              return;
                                            final fx =
                                                details.localPosition.dx /
                                                renderConstraints.maxWidth;
                                            final fy =
                                                details.localPosition.dy /
                                                renderConstraints.maxHeight;
                                            _placeCharacter(
                                              _selectedCharacter!,
                                              Offset(
                                                fx.clamp(0, 1),
                                                fy.clamp(0, 1),
                                              ),
                                            );
                                            _selectedCharacter = null;
                                          },
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              // 坐标系网格（基于图片左上角）
                                              if (_showGrid || _showCoords)
                                                Positioned.fill(
                                                  child: CustomPaint(
                                                    painter:
                                                        CoordinateGridPainter(
                                                          columns:
                                                              widget.map.width,
                                                          rows:
                                                              widget.map.height,
                                                          unit: _showCoords
                                                              ? widget.map.unit
                                                              : '',
                                                          showLabels:
                                                              _showCoords,
                                                          showGrid: _showGrid,
                                                        ),
                                                  ),
                                                ),
                                              // 已放置的角色标记
                                              for (final entry
                                                  in _positions.entries)
                                                Positioned(
                                                  left:
                                                      entry.value.dx *
                                                          renderConstraints
                                                              .maxWidth -
                                                      16,
                                                  top:
                                                      entry.value.dy *
                                                          renderConstraints
                                                              .maxHeight -
                                                      16,
                                                  child: GestureDetector(
                                                    onTap: () =>
                                                        _removeCharacter(
                                                          entry.key,
                                                        ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 32,
                                                          height: 32,
                                                          decoration: BoxDecoration(
                                                            color: Colors
                                                                .deepPurple,
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                              color:
                                                                  Colors.white,
                                                              width: 2,
                                                            ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black
                                                                    .withValues(
                                                                      alpha:
                                                                          0.3,
                                                                    ),
                                                                blurRadius: 4,
                                                              ),
                                                            ],
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              entry.key[0]
                                                                  .toUpperCase(),
                                                              style: const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 4,
                                                                vertical: 1,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.black
                                                                .withValues(
                                                                  alpha: 0.6,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            entry.key,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 10,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              // 提示文字
                                              if (_selectedCharacter != null)
                                                Positioned(
                                                  bottom: 12,
                                                  left: 12,
                                                  right: 12,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.deepPurple
                                                          .withValues(
                                                            alpha: 0.85,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '点击地图放置「$_selectedCharacter」的位置',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    : Center(child: Text(widget.map.name)),
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
    return Material(
      color: active ? Colors.deepPurple.shade50 : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              icon,
              size: 20,
              color: active ? Colors.deepPurple : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
