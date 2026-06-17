import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../data/models/equipment_data.dart';
import '../../../data/models/item_data.dart';

/// 规则 Tab — 含背包格子上限编辑、物品/装备模板、装备栏编辑
class RulesTab extends StatelessWidget {
  const RulesTab({
    super.key,
    required this.turnSettings,
    required this.phaseSettings,
    required this.backpackSlotMax,
    required this.itemTemplates,
    required this.equipmentSlots,
    required this.equipmentTemplates,
    required this.onBackpackSlotMaxChanged,
    required this.onAddItemTemplate,
    required this.onRemoveItemTemplate,
    required this.onEditItemTemplate,
    required this.onAddEquipmentTemplate,
    required this.onRemoveEquipmentTemplate,
    required this.onEditEquipmentTemplate,
    required this.onAddEquipmentSlot,
    required this.onRemoveEquipmentSlot,
    required this.onAddTurn,
    required this.onRemoveTurn,
    required this.onTurnChanged,
    required this.onAddPhase,
    required this.onRemovePhase,
    required this.onPhaseChanged,
  });

  final List<String> turnSettings;
  final List<String> phaseSettings;
  final int backpackSlotMax;
  final List<ItemData> itemTemplates;
  final List<String> equipmentSlots;
  final List<EquipmentData> equipmentTemplates;
  final ValueChanged<int> onBackpackSlotMaxChanged;
  final ValueChanged<ItemData> onAddItemTemplate;
  final ValueChanged<int> onRemoveItemTemplate;
  final void Function(int index, ItemData updated) onEditItemTemplate;
  final ValueChanged<EquipmentData> onAddEquipmentTemplate;
  final ValueChanged<int> onRemoveEquipmentTemplate;
  final void Function(int index, EquipmentData updated) onEditEquipmentTemplate;
  final ValueChanged<String> onAddEquipmentSlot;
  final ValueChanged<int> onRemoveEquipmentSlot;
  final VoidCallback onAddTurn;
  final void Function(int) onRemoveTurn;
  final void Function(int, String) onTurnChanged;
  final VoidCallback onAddPhase;
  final void Function(int) onRemovePhase;
  final void Function(int, String) onPhaseChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 背包设置 ──
          Text(
            '背包设置',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.backpack_outlined,
                  size: 22, color: Colors.deepPurple),
              const SizedBox(width: 8),
              const Text('物品栏格子上限',
                  style: TextStyle(fontSize: 15)),
              const Spacer(),
              IconButton(
                onPressed: () {
                  if (backpackSlotMax > 4) {
                    onBackpackSlotMaxChanged(backpackSlotMax - 4);
                  }
                },
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.deepPurple),
                tooltip: '减少',
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$backpackSlotMax',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    onBackpackSlotMaxChanged(backpackSlotMax + 4),
                icon: const Icon(Icons.add_circle_outline,
                    color: Colors.deepPurple),
                tooltip: '增加',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '每个角色的背包最多存放 $backpackSlotMax 件物品',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // ── 物品模板编辑 ──
          Text(
            '物品模板 (${itemTemplates.length})',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '自定义物品属性，角色页面从中选择添加到背包',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddItemDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加物品模板', style: TextStyle(fontSize: 16)),
            ),
          ),
          if (itemTemplates.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...List.generate(itemTemplates.length, (i) {
              final item = itemTemplates[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.category_outlined,
                            size: 20, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              Row(
                                children: [
                                  Text(item.type,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              Colors.deepPurple.shade400)),
                                  if (item.value > 0) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.monetization_on_outlined,
                                        size: 11, color: Colors.amber),
                                    Text('${item.value}',
                                        style: const TextStyle(fontSize: 11)),
                                  ],
                                  if (item.weight > 0) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.monitor_weight_outlined,
                                        size: 11, color: Colors.grey),
                                    Text('${item.weight}',
                                        style: const TextStyle(fontSize: 11)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showAddItemDialog(context, editIndex: i, editItem: item),
                          icon: const Icon(Icons.edit, size: 22),
                          tooltip: '编辑',
                        ),
                        IconButton(
                          onPressed: () => onRemoveItemTemplate(i),
                          icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                              size: 20),
                          tooltip: '删除模板',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 32),

          // ── 装备栏编辑 ──
          Text(
            '装备栏编辑',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '定义装备栏位置名称（如 头盔、身甲、手甲、腿甲、饰品）',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ...List.generate(equipmentSlots.length, (i) {
            final slot = equipmentSlots[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 20, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(slot,
                        style: const TextStyle(fontSize: 15)),
                  ),
                  IconButton(
                    onPressed: () => onRemoveEquipmentSlot(i),
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red, size: 20),
                    tooltip: '删除装备栏',
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddSlotDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加装备栏', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 32),

          // ── 装备模板 ──
          Text(
            '装备模板 (${equipmentTemplates.length})',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '自定义装备属性，角色页面从中选择装备到装备栏',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddEquipmentDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加装备模板', style: TextStyle(fontSize: 16)),
            ),
          ),
          if (equipmentTemplates.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...List.generate(equipmentTemplates.length, (i) {
              final eq = equipmentTemplates[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            size: 20, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(eq.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(eq.slot,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange.shade800)),
                                  ),
                                  if (eq.value > 0) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.monetization_on_outlined,
                                        size: 11, color: Colors.amber),
                                    Text('${eq.value}',
                                        style: const TextStyle(fontSize: 11)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showAddEquipmentDialog(context, editIndex: i, editEq: eq),
                          icon: const Icon(Icons.edit, size: 22),
                          tooltip: '编辑',
                        ),
                        IconButton(
                          onPressed: () => onRemoveEquipmentTemplate(i),
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red, size: 20),
                          tooltip: '删除模板',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 32),

          // ── 回合设置 ──
          Text(
            '回合设置',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            turnSettings.isEmpty ? '暂未设置回合参数' : '已设置 ${turnSettings.length} 项',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddTurn,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加回合设置', style: TextStyle(fontSize: 16)),
            ),
          ),
          if (turnSettings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...List.generate(turnSettings.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: turnSettings[i],
                        decoration: InputDecoration(
                          labelText: '回合设置 #${i + 1}',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => onTurnChanged(i, v),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onRemoveTurn(i),
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: '删除',
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 32),
          Text(
            '环节设置',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '已设置 ${phaseSettings.length} 个环节',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddPhase,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加环节', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(phaseSettings.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.flag_outlined,
                    size: 20,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: phaseSettings[i],
                      decoration: InputDecoration(
                        labelText: '环节 #${i + 1}',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => onPhaseChanged(i, v),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onRemovePhase(i),
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    tooltip: '删除环节',
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, {int? editIndex, ItemData? editItem}) {
    final isEdit = editIndex != null;
    final nameCtrl = TextEditingController(text: editItem?.name ?? '');
    final typeCtrl = TextEditingController(text: editItem?.type ?? '杂物');
    final effectCtrl = TextEditingController(text: editItem?.effect ?? '');
    final descCtrl = TextEditingController(text: editItem?.description ?? '');
    final valueCtrl = TextEditingController(text: '${editItem?.value ?? 0}');
    final weightCtrl = TextEditingController(text: '${editItem?.weight ?? 0}');
    String imageBase64 = editItem?.imageBase64 ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(isEdit ? '编辑物品模板' : '添加物品模板'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '物品名称',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: typeCtrl,
                  decoration: const InputDecoration(
                    labelText: '物品类型',
                    hintText: '武器 / 防具 / 药水 / 杂物',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: effectCtrl,
                  decoration: const InputDecoration(
                    labelText: '物品效果',
                    hintText: '例如: 回复2d6+4生命值',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: '描述（可选）',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: valueCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '价值',
                          prefixIcon: Icon(Icons.monetization_on_outlined, size: 18),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: weightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '负重',
                          prefixIcon: Icon(Icons.monitor_weight_outlined, size: 18),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.pickFiles(
                      dialogTitle: '选择物品图片',
                      type: FileType.image,
                    );
                    if (result != null &&
                        result.files.single.path != null) {
                      final bytes =
                          await File(result.files.single.path!).readAsBytes();
                      setDlg(() => imageBase64 = base64Encode(bytes));
                    }
                  },
                  icon: const Icon(Icons.image, size: 18),
                  label: Text(
                    imageBase64.isEmpty ? '选择图片' : '已选择图片',
                  ),
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
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final item = ItemData(
                  name: name,
                  imageBase64: imageBase64,
                  type: typeCtrl.text.trim().isEmpty
                      ? '杂物'
                      : typeCtrl.text.trim(),
                  effect: effectCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  value: int.tryParse(valueCtrl.text.trim()) ?? 0,
                  weight: int.tryParse(weightCtrl.text.trim()) ?? 0,
                );
              if (isEdit) {
                onEditItemTemplate(editIndex, item);
              } else {
                onAddItemTemplate(item);
              }
              Navigator.pop(ctx);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSlotDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加装备栏'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '装备栏名称',
            hintText: '例如: 头盔、手甲、身甲',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              onAddEquipmentSlot(name);
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showAddEquipmentDialog(BuildContext context, {int? editIndex, EquipmentData? editEq}) {
    final isEdit = editIndex != null;
    final nameCtrl = TextEditingController(text: editEq?.name ?? '');
    final typeCtrl = TextEditingController(text: editEq?.type ?? '防具');
    final effectCtrl = TextEditingController(text: editEq?.effect ?? '');
    final descCtrl = TextEditingController(text: editEq?.description ?? '');
    final valueCtrl = TextEditingController(text: '${editEq?.value ?? 0}');
    final weightCtrl = TextEditingController(text: '${editEq?.weight ?? 0}');
    String selectedSlot = editEq?.slot ?? (equipmentSlots.isNotEmpty ? equipmentSlots.first : '饰品');
    String imageBase64 = editEq?.imageBase64 ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(isEdit ? '编辑装备模板' : '添加装备模板'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '装备名称',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 10),
                // Slot picker
                DropdownButtonFormField<String>(
                  initialValue: equipmentSlots.contains(selectedSlot)
                      ? selectedSlot
                      : (equipmentSlots.isNotEmpty ? equipmentSlots.first : null),
                  decoration: const InputDecoration(
                    labelText: '装备位置',
                    border: OutlineInputBorder(),
                  ),
                  items: equipmentSlots
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDlg(() => selectedSlot = v);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: typeCtrl,
                  decoration: const InputDecoration(
                    labelText: '装备类型',
                    hintText: '防具 / 武器 / 饰品',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: effectCtrl,
                  decoration: const InputDecoration(
                    labelText: '装备效果',
                    hintText: '例如: +2护甲',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: '描述（可选）',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: valueCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '价值',
                          prefixIcon: Icon(Icons.monetization_on_outlined, size: 18),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: weightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '负重',
                          prefixIcon: Icon(Icons.monitor_weight_outlined, size: 18),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.pickFiles(
                      dialogTitle: '选择装备图片',
                      type: FileType.image,
                    );
                    if (result != null &&
                        result.files.single.path != null) {
                      final bytes =
                          await File(result.files.single.path!).readAsBytes();
                      setDlg(() => imageBase64 = base64Encode(bytes));
                    }
                  },
                  icon: const Icon(Icons.image, size: 18),
                  label: Text(
                    imageBase64.isEmpty ? '选择图片' : '已选择图片',
                  ),
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
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final eq = EquipmentData(
                  name: name,
                  imageBase64: imageBase64,
                  type: typeCtrl.text.trim().isEmpty
                      ? '防具'
                      : typeCtrl.text.trim(),
                  effect: effectCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  value: int.tryParse(valueCtrl.text.trim()) ?? 0,
                  weight: int.tryParse(weightCtrl.text.trim()) ?? 0,
                  slot: selectedSlot,
                );
              if (isEdit) {
                onEditEquipmentTemplate(editIndex, eq);
              } else {
                onAddEquipmentTemplate(eq);
              }
              Navigator.pop(ctx);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}
