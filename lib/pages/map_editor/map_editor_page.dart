import 'dart:convert';

import 'package:flutter/material.dart';

import '../../save_data.dart';

/// Standalone map editor for editing enemies on a map.
/// Used from the modify-save page's map tab.
class MapEditorPage extends StatefulWidget {
  const MapEditorPage({required this.mapData, required this.onSave, super.key});

  final MapData mapData;
  final void Function(MapData updated) onSave;

  @override
  State<MapEditorPage> createState() => _MapEditorPageState();
}

class _MapEditorPageState extends State<MapEditorPage> {
  late List<EnemyData> _enemies;
  // index of enemy selected for moving; null = nothing selected
  String? _selectedEnemyIndex;

  @override
  void initState() {
    super.initState();
    _enemies = widget.mapData.enemies.toList();
  }

  void _editEnemyProps(int index) {
    final e = _enemies[index];
    final nameCtrl = TextEditingController(text: e.name);
    final descCtrl = TextEditingController(text: e.description ?? '');
    final hpCtrl = TextEditingController(text: '${e.hp}');
    final maxHpCtrl = TextEditingController(text: '${e.maxHp}');
    final acCtrl = TextEditingController(text: '${e.ac}');
    final initCtrl = TextEditingController(text: '${e.initiative}');
    final atkCtrl = TextEditingController(text: e.attackDice ?? '');
    final strCtrl = TextEditingController(text: '${e.strength}');
    final dexCtrl = TextEditingController(text: '${e.dexterity}');
    final conCtrl = TextEditingController(text: '${e.constitution}');
    final intCtrl = TextEditingController(text: '${e.intelligence}');
    final wisCtrl = TextEditingController(text: '${e.wisdom}');
    final chaCtrl = TextEditingController(text: '${e.charisma}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('编辑敌人: ${e.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: '名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: '描述',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: hpCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'HP',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: maxHpCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '最大HP',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: acCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'AC',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: initCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '先攻',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: atkCtrl,
                decoration: const InputDecoration(
                  labelText: '攻击骰子 (如 2d6+3)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text('属性', style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  _statField(strCtrl, '力量'),
                  const SizedBox(width: 8),
                  _statField(dexCtrl, '敏捷'),
                  const SizedBox(width: 8),
                  _statField(conCtrl, '体质'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statField(intCtrl, '智力'),
                  const SizedBox(width: 8),
                  _statField(wisCtrl, '感知'),
                  const SizedBox(width: 8),
                  _statField(chaCtrl, '魅力'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final updated = EnemyData(
                name: nameCtrl.text.trim().isEmpty
                    ? e.name
                    : nameCtrl.text.trim(),
                x: e.x,
                y: e.y,
                hp: int.tryParse(hpCtrl.text) ?? e.hp,
                maxHp: int.tryParse(maxHpCtrl.text) ?? e.maxHp,
                ac: int.tryParse(acCtrl.text) ?? e.ac,
                initiative: int.tryParse(initCtrl.text) ?? e.initiative,
                attackDice: atkCtrl.text.trim().isEmpty
                    ? null
                    : atkCtrl.text.trim(),
                description: descCtrl.text.trim().isEmpty
                    ? null
                    : descCtrl.text.trim(),
                strength: int.tryParse(strCtrl.text) ?? e.strength,
                dexterity: int.tryParse(dexCtrl.text) ?? e.dexterity,
                constitution: int.tryParse(conCtrl.text) ?? e.constitution,
                intelligence: int.tryParse(intCtrl.text) ?? e.intelligence,
                wisdom: int.tryParse(wisCtrl.text) ?? e.wisdom,
                charisma: int.tryParse(chaCtrl.text) ?? e.charisma,
              );
              setState(() => _enemies[index] = updated);
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _statField(TextEditingController ctrl, String label) {
    return Expanded(
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  void _removeEnemy(int index) {
    setState(() {
      _enemies.removeAt(index);
      if (_selectedEnemyIndex == '$index') _selectedEnemyIndex = null;
    });
  }

  void _save() {
    final updated = MapData(
      name: widget.mapData.name,
      description: widget.mapData.description,
      width: widget.mapData.width,
      height: widget.mapData.height,
      imageBase64: widget.mapData.imageBase64,
      unit: widget.mapData.unit,
      tiles: widget.mapData.tiles,
      enemies: _enemies,
    );
    widget.onSave(updated);
    Navigator.pop(context);
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
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  return GestureDetector(
                    onTapUp: (details) {
                      final fx =
                          details.localPosition.dx / constraints.maxWidth;
                      final fy =
                          details.localPosition.dy / constraints.maxHeight;
                      if (_selectedEnemyIndex != null) {
                        // Editing an existing enemy position
                        final idx = int.tryParse(_selectedEnemyIndex!);
                        if (idx != null && idx < _enemies.length) {
                          setState(() {
                            _enemies[idx] = _enemies[idx].copyWith(
                              x: fx.clamp(0, 1),
                              y: fy.clamp(0, 1),
                            );
                          });
                          _selectedEnemyIndex = null;
                        }
                      }
                    },
                    child: Stack(
                      children: [
                        // Map image
                        if (m.imageBase64.isNotEmpty)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(m.imageBase64),
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                        else
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(child: Text(m.name)),
                            ),
                          ),
                        // Grid
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _GridPainter(
                              color: Colors.black.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        // Enemy tokens
                        for (int i = 0; i < _enemies.length; i++)
                          Positioned(
                            left: _enemies[i].x * constraints.maxWidth - 16,
                            top: _enemies[i].y * constraints.maxHeight - 16,
                            child: GestureDetector(
                              onTap: () {
                                if (_selectedEnemyIndex == '$i') {
                                  _editEnemyProps(i);
                                } else {
                                  setState(() => _selectedEnemyIndex = '$i');
                                }
                              },
                              onLongPress: () => _removeEnemy(i),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: _selectedEnemyIndex == '$i'
                                          ? Colors.orange
                                          : Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _enemies[i].name.isNotEmpty
                                            ? _enemies[i].name[0].toUpperCase()
                                            : 'E',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _enemies[i].name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Hint
                        if (_selectedEnemyIndex != null)
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '点击地图移动敌人位置，再次点击编辑属性，长按删除',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // ── 敌人列表 + 添加 ──
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        '敌人 (${_enemies.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          _enemies.add(
                            EnemyData(name: '敌人 ${_enemies.length + 1}'),
                          );
                          setState(() {});
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('添加敌人'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _enemies.isEmpty
                      ? const Center(child: Text('暂无敌人，点击"添加敌人"并在地图上放置'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _enemies.length,
                          itemBuilder: (_, i) {
                            final e = _enemies[i];
                            final selected = _selectedEnemyIndex == '$i';
                            return Card(
                              color: selected ? Colors.red.shade50 : null,
                              shape: selected
                                  ? RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: Colors.red.shade300,
                                        width: 2,
                                      ),
                                    )
                                  : null,
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  backgroundColor: Colors.red,
                                  radius: 14,
                                  child: Text(
                                    e.name.isNotEmpty
                                        ? e.name[0].toUpperCase()
                                        : 'E',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  e.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  'HP ${e.hp}/${e.maxHp} · AC ${e.ac} · 先攻 ${e.initiative >= 0 ? "+" : ""}${e.initiative}${e.attackDice != null ? " · ${e.attackDice}" : ""}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      tooltip: '编辑属性',
                                      onPressed: () => _editEnemyProps(i),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      tooltip: '删除',
                                      onPressed: () => _removeEnemy(i),
                                    ),
                                  ],
                                ),
                                onTap: () => setState(
                                  () => _selectedEnemyIndex = selected
                                      ? null
                                      : '$i',
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
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;
    const cells = 5;
    for (int i = 1; i < cells; i++) {
      final x = size.width * i / cells;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      final y = size.height * i / cells;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
