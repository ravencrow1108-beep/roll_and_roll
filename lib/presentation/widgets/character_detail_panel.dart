import 'dart:convert';

import 'package:flutter/material.dart';

import '../../data/models/models.dart';

/// 角色详情面板：头像、HP条、装备/物品/技能 Tab
/// 复用自冒险页面的 GM 角色详情布局
class CharacterDetailPanel extends StatefulWidget {
  const CharacterDetailPanel({
    required this.character,
    this.showClose = true,
    super.key,
  });

  final CharacterData character;
  final bool showClose;

  @override
  State<CharacterDetailPanel> createState() => _CharacterDetailPanelState();
}

class _CharacterDetailPanelState extends State<CharacterDetailPanel> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final c = widget.character;
    final theme = Theme.of(context);

    // ── 头像 + 名称 + HP 条 ──
    return SingleChildScrollView(
      child: Column(
        children: [
          // 头像
          if (c.portraitBase64.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ClipOval(
                child: Image.memory(
                  base64Decode(c.portraitBase64),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.15,
                ),
                child: Text(
                  c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            c.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${c.className} · ${c.race} · Lv${c.level}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          // HP 条
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.favorite, size: 16, color: Colors.red),
                    Text(
                      'HP: ${c.hp} / ${c.maxHp}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: c.maxHp > 0 ? (c.hp / c.maxHp).clamp(0.0, 1.0) : 0,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      (c.maxHp > 0 ? c.hp / c.maxHp : 0) > 0.5
                          ? Colors.green
                          : (c.maxHp > 0 ? c.hp / c.maxHp : 0) > 0.25
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 属性摘要
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _statChip('力量', c.strength, Colors.red),
                _statChip('敏捷', c.dexterity, Colors.green),
                _statChip('体质', c.constitution, Colors.orange),
                _statChip('智力', c.intelligence, Colors.blue),
                _statChip('感知', c.wisdom, Colors.purple),
                _statChip('魅力', c.charisma, Colors.pink),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(),

          // Tab 切换
          _TabBarRow(
            tabs: const ['装备', '物品', '技能'],
            current: _tabIndex,
            onChanged: (i) => setState(() => _tabIndex = i),
          ),
          const Divider(height: 1),

          // Tab 内容（固定高度）
          SizedBox(
            height: 260,
            child: IndexedStack(
              index: _tabIndex,
              children: [
                _EquipmentTab(character: c),
                _BackpackTab(character: c),
                _SkillsTab(character: c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Tab 切换行
class _TabBarRow extends StatelessWidget {
  const _TabBarRow({
    required this.tabs,
    required this.current,
    required this.onChanged,
  });

  final List<String> tabs;
  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 36,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == current;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? theme.colorScheme.primary
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 装备 Tab
class _EquipmentTab extends StatelessWidget {
  const _EquipmentTab({required this.character});
  final CharacterData character;

  @override
  Widget build(BuildContext context) {
    final eq = character.equipment;
    if (eq.isEmpty || eq.entries.every((e) => e.value == null)) {
      return const Center(
        child: Text('暂无装备', style: TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: eq.entries
          .where((e) => e.value != null)
          .map((e) => _buildEqCard(e.key, e.value!, context))
          .toList(),
    );
  }

  Widget _buildEqCard(String slot, EquipmentData eq, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            if (eq.imageBase64.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.memory(
                  base64Decode(eq.imageBase64),
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Icon(
                Icons.shield_outlined,
                size: 28,
                color: Colors.deepPurple,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eq.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    slot,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  if (eq.effect.isNotEmpty)
                    Text(
                      eq.effect,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            if (eq.ac > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'AC${eq.ac}',
                  style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 物品（背包） Tab
class _BackpackTab extends StatelessWidget {
  const _BackpackTab({required this.character});
  final CharacterData character;

  @override
  Widget build(BuildContext context) {
    final items = character.backpack;
    if (items.isEmpty) {
      return const Center(
        child: Text('暂无物品', style: TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: items.map((item) => _buildItemCard(item, context)).toList(),
    );
  }

  Widget _buildItemCard(ItemData item, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            if (item.imageBase64.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.memory(
                  base64Decode(item.imageBase64),
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Icon(
                Icons.category_outlined,
                size: 22,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.effect.isNotEmpty)
                    Text(
                      item.effect,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            if (item.value > 0)
              Text('💎${item.value}', style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

/// 技能 Tab
class _SkillsTab extends StatelessWidget {
  const _SkillsTab({required this.character});
  final CharacterData character;

  @override
  Widget build(BuildContext context) {
    final skills = character.skills;
    if (skills.isEmpty) {
      return const Center(
        child: Text('暂无技能', style: TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: skills.map((s) => _buildSkillCard(s, context)).toList(),
    );
  }

  Widget _buildSkillCard(SkillData s, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_fix_high, size: 16, color: Colors.teal),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (s.damages.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: s.damages.map((d) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${d.expression ?? ""}${d.damageType != null ? " ${d.damageType}" : ""}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (s.description != null && s.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                s.description!,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
            if (s.imageBase64 != null && s.imageBase64!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.memory(
                    base64Decode(s.imageBase64!),
                    width: 60,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
