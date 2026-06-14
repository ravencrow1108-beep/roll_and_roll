import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../data/models/models.dart';
import 'char_edit_models.dart';

/// 角色 Tab —— 角色信息编辑界面
class CharacterTab extends StatelessWidget {
  const CharacterTab({
    super.key,
    required this.nameCtrl,
    required this.classes,
    required this.onAddClass,
    required this.onRemoveClass,
    required this.race,
    required this.raceCustom,
    required this.raceCtrl,
    required this.onRaceChanged,
    required this.level,
    required this.onLevelChanged,
    required this.hp,
    required this.maxHp,
    required this.onHpChanged,
    required this.onMaxHpChanged,
    required this.skills,
    required this.onAddSkill,
    required this.backpack,
    required this.onAddBackpackItem,
    required this.onRemoveBackpackItem,
    required this.personalities,
    required this.onAddPersonality,
    required this.onRemovePersonality,
    required this.baseStats,
    required this.customStats,
    required this.onAddCustomStat,
    required this.onRemoveCustomStat,
    required this.onRemoveBaseStat,
    required this.onAdjust,
    required this.onStatChanged,
    required this.portraitBase64,
    required this.portraitBytes,
    required this.onPickPortrait,
  });

  final TextEditingController nameCtrl;
  final List<ClassEdit> classes;
  final VoidCallback onAddClass;
  final void Function(int index) onRemoveClass;
  final String race;
  final bool raceCustom;
  final TextEditingController raceCtrl;
  final ValueChanged<String?> onRaceChanged;
  final int level;
  final ValueChanged<int> onLevelChanged;
  final int hp;
  final int maxHp;
  final ValueChanged<int> onHpChanged;
  final ValueChanged<int> onMaxHpChanged;
  final List<SkillData> skills;
  final VoidCallback onAddSkill;
  final List<ItemData> backpack;
  final VoidCallback onAddBackpackItem;
  final void Function(int index) onRemoveBackpackItem;
  final List<PersonalityEdit> personalities;
  final VoidCallback onAddPersonality;
  final void Function(int index) onRemovePersonality;
  final Map<String, int> baseStats;
  final Map<String, int> customStats;
  final VoidCallback onAddCustomStat;
  final void Function(String name) onRemoveCustomStat;
  final void Function(String stat) onRemoveBaseStat;
  final void Function(String stat, int delta) onAdjust;
  final void Function(String stat, int value) onStatChanged;
  final String portraitBase64;
  final Uint8List? portraitBytes;
  final VoidCallback onPickPortrait;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '角色信息',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: '角色名称',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          // ── 角色头像 ──
          InkWell(
            onTap: onPickPortrait,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: portraitBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.memory(portraitBytes!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 36,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '选择头像',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // ── 职业 ──
          Row(
            children: [
              const Text('职业', style: TextStyle(fontSize: 16)),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddClass,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加职业'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...List.generate(classes.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: classes[i].ctrl,
                      decoration: InputDecoration(
                        labelText: i == 0 ? '主职业' : '副职业 #$i',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.school),
                      ),
                    ),
                  ),
                  if (classes.length > 1)
                    IconButton(
                      onPressed: () => onRemoveClass(i),
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: '移除职业',
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          // ── 种族 ──
          Row(
            children: [
              const Text('种族', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: raceCustom
                      ? '__custom__'
                      : ([
                            '人类',
                            '精灵',
                            '矮人',
                            '半身人',
                            '龙裔',
                            '兽人',
                          ].contains(race)
                              ? race
                              : '__custom__'),
                  items: const [
                    DropdownMenuItem(value: '人类', child: Text('人类')),
                    DropdownMenuItem(value: '精灵', child: Text('精灵')),
                    DropdownMenuItem(value: '矮人', child: Text('矮人')),
                    DropdownMenuItem(value: '半身人', child: Text('半身人')),
                    DropdownMenuItem(value: '龙裔', child: Text('龙裔')),
                    DropdownMenuItem(value: '兽人', child: Text('兽人')),
                    DropdownMenuItem(value: '__custom__', child: Text('自定义')),
                  ],
                  onChanged: onRaceChanged,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          if (raceCustom) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: raceCtrl,
              decoration: const InputDecoration(
                labelText: '自定义种族名称',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // ── 等级 ──
          Row(
            children: [
              const Text('等级', style: TextStyle(fontSize: 16)),
              const Spacer(),
              IconButton(
                onPressed: level > 1 ? () => onLevelChanged(level - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(' Lv$level ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => onLevelChanged(level + 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '血量',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // 血条进度
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: maxHp > 0 ? hp / maxHp : 0,
                            minHeight: 14,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation(
                              Colors.red,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$hp/$maxHp',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 当前血量调节
                  Row(
                    children: [
                      const SizedBox(width: 32),
                      const Text('当前', style: TextStyle(fontSize: 14)),
                      const Spacer(),
                      IconButton(
                        onPressed: hp > 0 ? () => onHpChanged(hp - 1) : null,
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        visualDensity: VisualDensity.compact,
                      ),
                      SizedBox(
                        width: 52,
                        child: TextFormField(
                          initialValue: '$hp',
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 15),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          onFieldSubmitted: (v) {
                            final n = int.tryParse(v);
                            if (n != null && n >= 0 && n <= maxHp) {
                              onHpChanged(n);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: hp < maxHp
                            ? () => onHpChanged(hp + 1)
                            : null,
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  // 上限血量调节
                  Row(
                    children: [
                      const SizedBox(width: 32),
                      const Text('上限', style: TextStyle(fontSize: 14)),
                      const Spacer(),
                      IconButton(
                        onPressed: maxHp > 1
                            ? () => onMaxHpChanged(maxHp - 1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        visualDensity: VisualDensity.compact,
                      ),
                      SizedBox(
                        width: 52,
                        child: TextFormField(
                          initialValue: '$maxHp',
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 15),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          onFieldSubmitted: (v) {
                            final n = int.tryParse(v);
                            if (n != null && n >= 1) {
                              onMaxHpChanged(n);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () => onMaxHpChanged(maxHp + 1),
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '技能 (${skills.length})',
                style: const TextStyle(fontSize: 16),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddSkill,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加技能'),
              ),
            ],
          ),
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...skills.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.casino,
                              size: 18,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (s.description != null &&
                            s.description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            s.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        if (s.diceType != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '🎲 ${s.diceType}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                '背包与装备 (${backpack.length})',
                style: const TextStyle(fontSize: 16),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddBackpackItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加物品'),
              ),
            ],
          ),
          if (backpack.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...List.generate(backpack.length, (i) {
              final item = backpack[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.backpack_outlined,
                          size: 20,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (item.description.isNotEmpty)
                                Text(
                                  item.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => onRemoveBackpackItem(i),
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          tooltip: '移出背包',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 24),
          Text(
            '属性分配',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...baseStats.entries.map((e) {
            final icon = switch (e.key) {
              '力量' => Icons.fitness_center,
              '敏捷' => Icons.directions_run,
              '体质' => Icons.favorite_outline,
              '智力' => Icons.psychology_outlined,
              '感知' => Icons.visibility_outlined,
              '魅力' => Icons.emoji_emotions_outlined,
              _ => Icons.star_outline,
            };
            return _StatLine(
              e.key,
              e.value,
              icon,
              e.value < 99,
              onAdjust,
              onValueSet: onStatChanged,
              canDelete: true,
              onDelete: () => onRemoveBaseStat(e.key),
            );
          }),
          ...customStats.entries.map(
            (e) => _StatLine(
              e.key,
              e.value,
              Icons.star_outline,
              e.value < 99,
              onAdjust,
              onValueSet: onStatChanged,
              canDelete: true,
              onDelete: () => onRemoveCustomStat(e.key),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddCustomStat,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加属性'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine(
    this.label,
    this.value,
    this.icon,
    this.canIncrement,
    this.onAdjust, {
    this.onValueSet,
    this.canDelete = false,
    this.onDelete,
  });

  final String label;
  final int value;
  final IconData icon;
  final bool canIncrement;
  final void Function(String, int) onAdjust;
  final void Function(String, int)? onValueSet;
  final bool canDelete;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.deepPurple),
            const SizedBox(width: 12),
            SizedBox(
              width: 48,
              child: Text(label, style: const TextStyle(fontSize: 16)),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > 0 ? () => onAdjust(label, -1) : null,
              tooltip: '减少',
            ),
            SizedBox(
              width: 48,
              child: TextFormField(
                initialValue: '$value',
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (v) {
                  final n = int.tryParse(v);
                  if (n != null && n >= 0 && n <= 99) {
                    onValueSet?.call(label, n);
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: canIncrement ? () => onAdjust(label, 1) : null,
              tooltip: '增加',
            ),
            if (canDelete && onDelete != null)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 22,
                ),
                onPressed: onDelete,
                tooltip: '删除属性',
              ),
          ],
        ),
      ),
    );
  }
}
