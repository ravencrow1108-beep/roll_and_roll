import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../save_data.dart';

class LiveModePage extends StatefulWidget {
  const LiveModePage({super.key});

  @override
  State<LiveModePage> createState() => _LiveModePageState();
}

class _LiveModePageState extends State<LiveModePage> {
  SaveData? _save;
  String? _filePath;
  String _fileName = '未选择存档';
  MapData? _currentMap;
  Map<int, int> _enemyHp = {};
  List<PlayerPosition> _playerPositions = [];
  bool _isLoading = false;

  final _diceInputCtrl = TextEditingController();
  String _diceResult = '';
  String? _selectedEnemyIndex;

  Future<void> _loadSave() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '选择存档文件 (.zip)',
      type: FileType.any,
    );
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    if (!path.endsWith('.zip')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请选择 .zip 存档'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final save = await SaveData.fromZip(path);
      if (!mounted) return;
      setState(() {
        _save = save;
        _filePath = path;
        _fileName = result.files.single.name;
        _currentMap = save.maps.isNotEmpty ? save.maps.first : null;
        _playerPositions = save.playerPositions.toList();
        _enemyHp = {};
        if (_currentMap != null) {
          for (int i = 0; i < _currentMap!.enemies.length; i++) {
            _enemyHp[i] = _currentMap!.enemies[i].hp;
          }
        }
        _selectedEnemyIndex = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveProgress() async {
    if (_filePath == null || _save == null || _currentMap == null) return;
    setState(() => _isLoading = true);
    try {
      final updatedEnemies = <EnemyData>[];
      for (int i = 0; i < _currentMap!.enemies.length; i++) {
        final e = _currentMap!.enemies[i];
        updatedEnemies.add(e.copyWith(hp: _enemyHp[i] ?? e.hp));
      }
      final updatedMap = _currentMap!.copyWith(enemies: updatedEnemies);
      final maps = _save!.maps.toList();
      for (int i = 0; i < maps.length; i++) {
        if (maps[i].name == _currentMap!.name) {
          maps[i] = updatedMap;
          break;
        }
      }
      final updatedSave = SaveData(
        createdAt: DateTime.now().toIso8601String(),
        characters: _save!.characters,
        maps: maps,
        playerPositions: _playerPositions,
        rules: _save!.rules,
      );
      await updatedSave.packToZip(_filePath!);
      if (!mounted) return;
      setState(() {
        _currentMap = updatedMap;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('进度已保存'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _setEnemyHp(int index, int delta) {
    setState(() {
      final e = (_currentMap != null && index < _currentMap!.enemies.length)
          ? _currentMap!.enemies[index]
          : null;
      final cur = _enemyHp[index] ?? e?.hp ?? 0;
      final maxHp = e?.maxHp ?? 99;
      _enemyHp[index] = (cur + delta).clamp(0, maxHp);
    });
  }

  void _rollDice(int sides) {
    final roll = (DateTime.now().millisecondsSinceEpoch % sides) + 1;
    setState(() => _diceResult = 'd$sides = $roll');
  }

  void _rollCustomDice() {
    final text = _diceInputCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      final result = DiceExpression.roll(text);
      setState(() => _diceResult = result.toString());
    } catch (_) {
      setState(() => _diceResult = '表达式无效');
    }
  }

  void _switchMap(MapData m) {
    setState(() {
      _currentMap = m;
      _enemyHp = {};
      for (int i = 0; i < m.enemies.length; i++) {
        _enemyHp[i] = m.enemies[i].hp;
      }
      _selectedEnemyIndex = null;
    });
  }

  @override
  void dispose() {
    _diceInputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 600;

    if (_save == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('直播模式')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_outlined,
                size: 72,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text('选择一个存档开始直播', style: theme.textTheme.titleMedium),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadSave,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_open),
                label: const Text('选择存档', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final m = _currentMap;
    if (m == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('直播模式 · $_fileName'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: '保存进度',
              onPressed: _saveProgress,
            ),
          ],
        ),
        body: Center(
          child: Text(
            '该存档中没有地图',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    final enemies = m.enemies;
    return Scaffold(
      appBar: AppBar(
        title: Text('直播 · ${m.name}'),
        actions: [
          if (_save!.maps.length > 1)
            PopupMenuButton<MapData>(
              icon: const Icon(Icons.map_outlined),
              tooltip: '切换地图',
              onSelected: _switchMap,
              itemBuilder: (_) => _save!.maps
                  .map(
                    (map) => PopupMenuItem(value: map, child: Text(map.name)),
                  )
                  .toList(),
            ),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            tooltip: '保存游戏进度',
            onPressed: _isLoading ? null : _saveProgress,
          ),
        ],
      ),
      body: SafeArea(
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDicePanel(theme, isWide),
                  Expanded(flex: 4, child: _buildMapCenter(theme, m, enemies)),
                  _buildEnemyPanel(theme, enemies),
                ],
              )
            : Column(
                children: [
                  Expanded(child: _buildMapCenter(theme, m, enemies)),
                  _buildDicePanel(theme, false),
                ],
              ),
      ),
    );
  }

  Widget _buildDicePanel(ThemeData theme, bool isWide) {
    final dice = [4, 6, 8, 10, 12, 20];
    return Container(
      width: isWide ? 160 : null,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: isWide
            ? Border(right: BorderSide(color: theme.dividerColor))
            : Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        mainAxisSize: isWide ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Text(
            '骰子',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: dice.map((d) {
              return SizedBox(
                width: isWide ? 68 : 52,
                height: 36,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.deepPurple.shade100,
                    foregroundColor: Colors.deepPurple.shade900,
                  ),
                  onPressed: () => _rollDice(d),
                  child: Text(
                    'd$d',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: isWide ? 140 : double.infinity,
            height: 36,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade900,
              ),
              onPressed: () => _rollDice(100),
              child: const Text(
                'd100',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (isWide) ...[
            TextField(
              controller: _diceInputCtrl,
              decoration: const InputDecoration(
                hintText: '2d6+3',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              style: const TextStyle(fontSize: 13),
              onSubmitted: (_) => _rollCustomDice(),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                onPressed: _rollCustomDice,
                child: const Text('投掷', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
          if (_diceResult.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _diceResult,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapCenter(ThemeData theme, MapData m, List<EnemyData> enemies) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: m.imageBase64.isNotEmpty
          ? LayoutBuilder(
              builder: (ctx, constraints) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.memory(
                          base64Decode(m.imageBase64),
                          fit: BoxFit.contain,
                        ),
                      ),
                      for (final pos in _playerPositions)
                        Positioned(
                          left: pos.x * constraints.maxWidth - 16,
                          top: pos.y * constraints.maxHeight - 16,
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
                                ),
                                child: Center(
                                  child: Text(
                                    pos.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  pos.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      for (int i = 0; i < enemies.length; i++)
                        Positioned(
                          left: enemies[i].x * constraints.maxWidth - 16,
                          top: enemies[i].y * constraints.maxHeight - 16,
                          child: GestureDetector(
                            onTap: () => setState(
                              () => _selectedEnemyIndex =
                                  _selectedEnemyIndex == '$i' ? null : '$i',
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: _selectedEnemyIndex == '$i' ? 36 : 32,
                                  height: _selectedEnemyIndex == '$i' ? 36 : 32,
                                  decoration: BoxDecoration(
                                    color: (_enemyHp[i] ?? enemies[i].hp) <= 0
                                        ? Colors.grey
                                        : Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _selectedEnemyIndex == '$i'
                                          ? Colors.yellow
                                          : Colors.white,
                                      width: _selectedEnemyIndex == '$i'
                                          ? 3
                                          : 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      enemies[i].name.isNotEmpty
                                          ? enemies[i].name[0].toUpperCase()
                                          : 'E',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '${enemies[i].name} HP${_enemyHp[i] ?? enemies[i].hp}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
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
                style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
              ),
            ),
    );
  }

  Widget _buildEnemyPanel(ThemeData theme, List<EnemyData> enemies) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '敌人 (${enemies.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: enemies.isEmpty
                ? const Center(
                    child: Text(
                      '暂无敌人',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    itemCount: enemies.length,
                    itemBuilder: (_, i) {
                      final e = enemies[i];
                      final hp = _enemyHp[i] ?? e.hp;
                      final selected = _selectedEnemyIndex == '$i';
                      final dead = hp <= 0;
                      return Card(
                        color: selected
                            ? Colors.yellow.shade50
                            : (dead ? Colors.grey.shade100 : null),
                        shape: selected
                            ? RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: Colors.yellow.shade700,
                                  width: 2,
                                ),
                              )
                            : null,
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor: dead ? Colors.grey : Colors.red,
                            radius: 14,
                            child: Text(
                              e.name.isNotEmpty ? e.name[0].toUpperCase() : 'E',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            e.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              decoration: dead
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Text(
                            dead
                                ? '已击败'
                                : 'HP $hp / ${e.maxHp}  AC ${e.ac}${e.attackDice != null ? "\n🎲 ${e.attackDice}" : ""}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: dead
                              ? null
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _setEnemyHp(i, -1),
                                      tooltip: 'HP -1',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle,
                                        size: 18,
                                        color: Colors.green,
                                      ),
                                      onPressed: () => _setEnemyHp(i, 1),
                                      tooltip: 'HP +1',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                          onTap: () => setState(
                            () => _selectedEnemyIndex = selected ? null : '$i',
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
