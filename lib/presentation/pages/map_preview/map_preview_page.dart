import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../../data/models/models.dart';

/// 统一的地图预览页面：大图预览 + 角色位置标记 + 底部信息栏 + 开始冒险按钮
/// 用于 MapEditPage 和 AdventurePage，通过 Navigator.push 调用，保证两处地图预览完全一致
class MapPreviewPage extends StatelessWidget {
  const MapPreviewPage({
    required this.mapData,
    required this.positions,
    required this.characters,
    required this.onBack,
    required this.onStart,
    this.saveFileName,
    super.key,
  });

  final MapData mapData;
  final List<PlayerPosition> positions;
  final List<CharacterData> characters;
  final VoidCallback onBack;
  final VoidCallback onStart;
  final String? saveFileName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = mapData;

    return Scaffold(
      appBar: AppBar(
        title: Text(m.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: Column(
        children: [
          // ── 大地图预览（填满剩余空间） ──
          Expanded(
            child: _BigMapPreview(mapData: m, positions: positions),
          ),
          // ── 底部信息栏 ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        m.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${m.width}×${m.height} · ${m.unit}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (m.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    m.description,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (saveFileName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '已加载存档: $saveFileName',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
                if (positions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: positions
                        .map((p) => _PositionChip(
                              position: p,
                              characters: characters,
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      onStart();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.rocket_launch_outlined),
                    label: const Text(
                      '开始冒险',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 角色位置指示标签
class _PositionChip extends StatelessWidget {
  const _PositionChip({required this.position, required this.characters});
  final PlayerPosition position;
  final List<CharacterData> characters;

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    final color = colors[position.name.hashCode.abs() % colors.length];
    final char = characters.cast<CharacterData?>().firstWhere(
          (c) => c?.name == position.name,
          orElse: () => null,
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (char?.portraitBase64 != null && char!.portraitBase64.isNotEmpty)
            ClipOval(
              child: Image.memory(
                base64Decode(char.portraitBase64),
                width: 18,
                height: 18,
                fit: BoxFit.cover,
              ),
            )
          else
            Icon(Icons.person_pin_circle, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            position.name,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${position.x}, ${position.y})',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

/// 大地图预览组件：可缩放平移 + 角色位置圆形标记
class _BigMapPreview extends StatefulWidget {
  const _BigMapPreview({required this.mapData, required this.positions});

  final MapData mapData;
  final List<PlayerPosition> positions;

  @override
  State<_BigMapPreview> createState() => _BigMapPreviewState();
}

class _BigMapPreviewState extends State<_BigMapPreview> {
  Size? _naturalSize;
  final TransformationController _transformCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    _decodeSize();
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  Future<void> _decodeSize() async {
    final b64 = widget.mapData.imageBase64;
    if (b64.isEmpty) return;
    try {
      final bytes = base64Decode(b64);
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      final frame = await codec.getNextFrame();
      _naturalSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mapData;
    if (m.imageBase64.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              '地图 "${m.name}" 暂无图片',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              '${m.width}×${m.height} · ${m.unit}',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }
    if (_naturalSize == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final imgW = _naturalSize!.width;
    final imgH = _naturalSize!.height;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final scale =
            (constraints.maxWidth / imgW) < (constraints.maxHeight / imgH)
                ? constraints.maxWidth / imgW
                : constraints.maxHeight / imgH;
        final renderW = imgW * scale;
        final renderH = imgH * scale;
        final ox = (constraints.maxWidth - renderW) / 2;
        final oy = (constraints.maxHeight - renderH) / 2;

        return Stack(
          children: [
            Center(
              child: InteractiveViewer(
                transformationController: _transformCtrl,
                minScale: 0.3,
                maxScale: 5.0,
                child: SizedBox(
                  width: renderW,
                  height: renderH,
                  child: Image.memory(
                    base64Decode(m.imageBase64),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            ...widget.positions.map((p) {
              final px = ox + p.x * renderW;
              final py = oy + p.y * renderH;
              final colors = [
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.purple,
                Colors.teal,
                Colors.pink,
                Colors.indigo,
              ];
              final color = colors[p.name.hashCode.abs() % colors.length];
              return Positioned(
                left: px - 12,
                top: py - 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
