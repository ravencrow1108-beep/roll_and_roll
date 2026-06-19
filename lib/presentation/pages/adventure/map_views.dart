import 'package:flutter/material.dart';
import '../../../data/models/models.dart';

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '主持模式 · $playerName',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '从存档中选择地图',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.save_outlined),
                            const SizedBox(width: 12),
                            Expanded(child: Text(saveFileName)),
                            IconButton(
                              icon: const Icon(Icons.save_as_outlined),
                              tooltip: '另存为',
                              onPressed: onPickSaveFile,
                            ),
                            IconButton(
                              icon: const Icon(Icons.folder_open),
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
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: loadedMaps.length,
                  itemBuilder: (_, i) {
                    final m = loadedMaps[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: const Icon(
                            Icons.map_outlined,
                            color: Colors.teal,
                          ),
                        ),
                        title: Text(
                          m.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${m.width}×${m.height} · ${m.description.isNotEmpty ? m.description : "无描述"}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => onSelectMap(m),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
              Text(
                '或创建 / 编辑地图',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCreateSave,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text(
                    '创建 / 编辑地图 (打开创建存档)',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
