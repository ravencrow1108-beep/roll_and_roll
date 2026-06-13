import 'dart:convert';

import 'package:flutter/material.dart';
import '../../save_data.dart';
import 'ready_status_panel.dart';

/// 地图预览视图（主持查看地图详情 + 开始冒险）
class MapPreviewView extends StatelessWidget {
  const MapPreviewView({
    required this.mapData,
    required this.isReady,
    required this.onBack,
    required this.onStart,
    this.saveFileName,
    super.key,
  });

  final MapData mapData;
  final bool isReady;
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
            onPressed: onBack),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.name,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              if (m.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(m.description,
                    style: TextStyle(
                        color: Colors.grey.shade700)),
              ],
              const SizedBox(height: 12),
              Text(
                  '尺寸: ${m.width} × ${m.height} · 单位: ${m.unit}'),
              if (m.imageBase64.isNotEmpty) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(m.imageBase64),
                    fit: BoxFit.contain,
                  ),
                ),
              ],
              if (saveFileName != null) ...[
                const SizedBox(height: 16),
                Text('已加载存档: $saveFileName',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12)),
              ],
              const SizedBox(height: 32),
              const ReadyStatusPanel(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isReady ? null : onStart,
                  icon: Icon(isReady
                      ? Icons.check_circle
                      : Icons.rocket_launch_outlined),
                  label: Text(
                    isReady ? '已准备，等待所有玩家…' : '开始冒险',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 地图选择视图
class MapSelectionView extends StatelessWidget {
  const MapSelectionView({
    required this.playerName,
    required this.saveFileName,
    required this.loadedMaps,
    required this.onPickSaveFile,
    required this.onSelectMap,
    required this.onCreateSave,
    super.key,
  });

  final String playerName;
  final String saveFileName;
  final List<MapData> loadedMaps;
  final VoidCallback onPickSaveFile;
  final void Function(MapData m) onSelectMap;
  final VoidCallback onCreateSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('选择地图')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('主持模式 · $playerName',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text('从存档中选择地图',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.save_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(saveFileName)),
                            IconButton(
                              icon: const Icon(
                                  Icons.folder_open),
                              tooltip: '选择存档文件',
                              onPressed: onPickSaveFile,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (loadedMaps.isNotEmpty) ...[
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: loadedMaps.length,
                    itemBuilder: (_, i) {
                      final m = loadedMaps[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Colors.teal.shade100,
                            child: const Icon(
                                Icons.map_outlined,
                                color: Colors.teal),
                          ),
                          title: Text(m.name,
                              style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold)),
                          subtitle: Text(
                            '${m.width}×${m.height} · ${m.description.isNotEmpty ? m.description : "无描述"}',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16),
                          onTap: () => onSelectMap(m),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text('或创建 / 编辑地图',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCreateSave,
                  icon: const Icon(
                      Icons.add_location_alt_outlined),
                  label: const Text(
                      '创建 / 编辑地图 (打开创建存档)',
                      style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
