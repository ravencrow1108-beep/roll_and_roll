import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../data/models/models.dart';
import '../adventure/coordinate_grid.dart';
import '../token_placement/token_placement_page.dart';

/// 地图编辑页面：查看地图、布置角色位置
/// 用于创建/编辑存档中的地图选项卡。
class MapEditorPage extends StatefulWidget {
  const MapEditorPage({
    required this.mapData,
    required this.onSave,
    this.saveFilePath,
    this.initialPositions = const [],
    super.key,
  });

  final MapData mapData;
  final void Function(MapData updated) onSave;
  final String? saveFilePath;
  final List<PlayerPosition> initialPositions;

  @override
  State<MapEditorPage> createState() => _MapEditorPageState();
}

class _MapEditorPageState extends State<MapEditorPage> {
  late List<PlayerPosition> _positions;
  bool _showGrid = true;
  bool _showCoords = true;

  /// 地图图片的原始宽高（像素），异步解码后缓存。
  Size? _imageNaturalSize;

  @override
  void initState() {
    super.initState();
    _positions = widget.initialPositions.toList();
    _decodeImageSize();
  }

  Future<void> _decodeImageSize() async {
    final b64 = widget.mapData.imageBase64;
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

  void _save() {
    final updated = widget.mapData.copyWith();
    widget.onSave(updated);
    Navigator.pop(context);
  }

  Future<void> _navigateToTokenPlacement() async {
    final result = await Navigator.push<List<PlayerPosition>>(
      context,
      MaterialPageRoute(
        builder: (_) => TokenPlacementPage(
          playerName: '',
          role: '主持',
          map: widget.mapData,
          saveFilePath: widget.saveFilePath,
          existingPositions: _positions,
          saveOnly: true,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _positions = result);
      _savePositionsToFile();
    }
  }

  Future<void> _savePositionsToFile() async {
    if (widget.saveFilePath == null) return;
    try {
      final save = await SaveData.fromZip(widget.saveFilePath!);
      final updated = SaveData(
        createdAt: DateTime.now().toIso8601String(),
        characters: save.characters,
        maps: save.maps,
        items: save.items,
        rules: save.rules,
        playerPositions: _positions,
      );
      await updated.packToZip(widget.saveFilePath!);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = widget.mapData;

    return Scaffold(
      appBar: AppBar(
        title: Text('编辑地图 · ${m.name}'),
        actions: [
          TextButton.icon(
            onPressed: _navigateToTokenPlacement,
            icon: const Icon(Icons.person_pin_circle_outlined),
            label: const Text('布置角色位置'),
          ),
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('保存'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 地图区域 ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // 工具栏
                  Row(
                    children: [
                      _GridToggle(
                        icon: Icons.grid_on,
                        tooltip: _showGrid ? '关闭网格' : '显示网格',
                        active: _showGrid,
                        onTap: () => setState(() => _showGrid = !_showGrid),
                      ),
                      const SizedBox(width: 4),
                      _GridToggle(
                        icon: Icons.pin_drop_outlined,
                        tooltip: _showCoords ? '隐藏坐标' : '显示坐标',
                        active: _showCoords,
                        onTap: () => setState(() => _showCoords = !_showCoords),
                      ),
                      const Spacer(),
                      if (_positions.isNotEmpty)
                        Text(
                          '已布置 ${_positions.length} 个角色',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
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
                                    // 背景图片
                                    Positioned.fill(
                                      child: Image.memory(
                                        base64Decode(m.imageBase64),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    // 网格与角色位置（对齐图片左上角）
                                    Positioned(
                                      left: renderRect.left,
                                      top: renderRect.top,
                                      width: renderRect.width,
                                      height: renderRect.height,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // 坐标系网格
                                          if (_showGrid || _showCoords)
                                            Positioned.fill(
                                              child: CustomPaint(
                                                painter: CoordinateGridPainter(
                                                  columns: m.width,
                                                  rows: m.height,
                                                  unit: _showCoords
                                                      ? m.unit
                                                      : '',
                                                  showLabels: _showCoords,
                                                  showGrid: _showGrid,
                                                ),
                                              ),
                                            ),
                                          // 角色位置标记
                                          for (final pos in _positions)
                                            Positioned(
                                              left:
                                                  pos.x *
                                                      renderConstraints
                                                          .maxWidth -
                                                  16,
                                              top:
                                                  pos.y *
                                                      renderConstraints
                                                          .maxHeight -
                                                  16,
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
                                                          color: Colors.black
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                          blurRadius: 4,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        pos.name.isNotEmpty
                                                            ? pos.name[0]
                                                                  .toUpperCase()
                                                            : '?',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
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
                                                      pos.name,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Center(child: Text(m.name)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
