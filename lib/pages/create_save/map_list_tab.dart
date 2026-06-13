import 'dart:convert';

import 'package:flutter/material.dart';

import '../../save_data.dart';

/// 地图列表 Tab
class MapListTab extends StatelessWidget {
  const MapListTab({
    super.key,
    required this.maps,
    required this.onAdd,
    required this.onDelete,
    required this.onEdit,
  });

  final List<MapData> maps;
  final VoidCallback onAdd;
  final void Function(int index) onDelete;
  final void Function(int index) onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '地图列表',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '已添加 ${maps.length} 张地图',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('添加地图', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: maps.isEmpty
                ? Center(
                    child: Text(
                      '暂无地图，点击上方按钮添加',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: maps.length,
                    itemBuilder: (_, i) {
                      final m = maps[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              // 缩略图
                              Container(
                                width: 72,
                                height: 56,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.memory(
                                  base64Decode(m.imageBase64),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.map_outlined,
                                    size: 28,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.name,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      '${m.width} × ${m.height} ${m.unit}'
                                      '${m.tiles.isNotEmpty ? ' · ${m.tiles.length} 地块' : ''}'
                                      '${m.description.isNotEmpty ? ' · ${m.description}' : ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => onEdit(i),
                                icon: const Icon(Icons.edit, size: 22),
                                tooltip: '编辑地图',
                              ),
                              IconButton(
                                onPressed: () => onDelete(i),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 22,
                                ),
                                tooltip: '删除地图',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
