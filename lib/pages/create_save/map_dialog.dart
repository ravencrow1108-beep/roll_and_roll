import 'dart:convert';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../save_data.dart';

/// 添加地图对话框
class MapDialog extends StatefulWidget {
  const MapDialog({super.key, required this.onSave});

  final void Function(MapData) onSave;

  @override
  State<MapDialog> createState() => _MapDialogState();
}

class _MapDialogState extends State<MapDialog> {
  final _nameCtrl = TextEditingController(text: '无名地图');
  final _descCtrl = TextEditingController();
  final _widthCtrl = TextEditingController(text: '20');
  final _heightCtrl = TextEditingController(text: '20');
  String? _imageBase64;
  String? _imageFileName;
  double _aspectRatio = 1.0;
  bool _hasImage = false;

  @override
  void initState() {
    super.initState();
    _widthCtrl.addListener(_onWidthChanged);
  }

  void _onWidthChanged() {
    final w = double.tryParse(_widthCtrl.text.trim());
    if (w != null && w > 0 && _hasImage && _aspectRatio > 0) {
      final h = (w / _aspectRatio).round();
      _heightCtrl.text = '$h';
    }
  }

  @override
  void dispose() {
    _widthCtrl.removeListener(_onWidthChanged);
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    // 解码图片获取像素尺寸，计算宽高比
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final pw = frame.image.width.toDouble();
    final ph = frame.image.height.toDouble();
    frame.image.dispose();
    codec.dispose();
    final ratio = ph > 0 ? pw / ph : 1.0;

    setState(() {
      _imageBase64 = base64Encode(bytes);
      _imageFileName = file.name;
      _aspectRatio = ratio;
      _hasImage = true;
    });

    // 根据宽高比自动更新长度
    _onWidthChanged();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加地图'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '地图名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: '描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            // ── 上传图片（必选）──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: Icon(
                  _hasImage ? Icons.check_circle : Icons.image_outlined,
                  color: _hasImage ? Colors.green : null,
                ),
                label: Text(_imageFileName ?? '上传地图图片 *'),
                style: _hasImage
                    ? null
                    : OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade300),
                      ),
              ),
            ),
            if (_hasImage) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(
                  base64Decode(_imageBase64!),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _widthCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '宽度（米）',
                      border: OutlineInputBorder(),
                      suffixText: '米',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '×',
                  style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _heightCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: '长度（米）',
                      border: const OutlineInputBorder(),
                      suffixText: '米',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            if (!_hasImage || _imageBase64 == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('请先上传地图图片'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            widget.onSave(
              MapData(
                name: name,
                description: _descCtrl.text.trim(),
                width: int.tryParse(_widthCtrl.text.trim()) ?? 20,
                height: int.tryParse(_heightCtrl.text.trim()) ?? 20,
                imageBase64: _imageBase64!,
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}
