import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../data/models/models.dart';

// ============================================================================
// CharacterDetailPopup — 角色详情浮窗
// ============================================================================
///
/// 鼠标悬停在角色头像上 1 秒后弹出。
/// 显示：头像、名字、血量、职业、种族、性格、注释等。
///
/// 【扩展指南】
/// 如需增加新字段，请按以下步骤操作：
///   1. 在 _buildContent 中按区域添加新的 Section 或 Row
///   2. 复杂区域（如技能列表、背包物品）建议抽为独立渲染方法
///   3. 所有样式常量见顶部 _style 区域
///   4. 添加对应的测试数据请在 _CharacterDetailPopupState 验证
///
class CharacterDetailPopup extends StatefulWidget {
  const CharacterDetailPopup({
    required this.character,
    required this.targetCenter,
    this.onPopupEnter,
    this.onPopupExit,
    super.key,
  });

  /// 完整角色数据（所有字段均可访问）
  final CharacterData character;

  /// 触发浮窗的目标元素中心点（屏幕坐标）
  final Offset targetCenter;

  /// 鼠标进入浮窗时回调（取消关闭）
  final VoidCallback? onPopupEnter;

  /// 鼠标离开浮窗时回调（启动关闭延迟）
  final VoidCallback? onPopupExit;

  @override
  State<CharacterDetailPopup> createState() => _CharacterDetailPopupState();
}

class _CharacterDetailPopupState extends State<CharacterDetailPopup> {
  // =========================================================================
  // 样式常量 — 集中管理，方便统一调整
  // =========================================================================
  static const double _cardWidth = 220;
  static const double _cardMaxHeight = 420;
  static const double _portraitSize = 56;
  static const double _sectionSpacing = 10;
  static const Color _bgColor = Color(0xFF1E1E2E);
  static const Color _borderColor = Color(0x55FFFFFF);
  static const Color _accentColor = Color(0xFFBB86FC);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final c = widget.character;

    // 计算浮窗位置：优先在目标右侧，空间不足则左侧
    double left = widget.targetCenter.dx + 20;
    if (left + _cardWidth > screenSize.width - 12) {
      left = widget.targetCenter.dx - _cardWidth - 20;
    }
    if (left < 12) left = 12;

    // 垂直居中于目标
    double top = widget.targetCenter.dy - _cardMaxHeight / 2;
    if (top < 12) top = 12;
    if (top + _cardMaxHeight > screenSize.height - 12) {
      top = screenSize.height - _cardMaxHeight - 12;
    }

    return Positioned(
      left: left,
      top: top,
      width: _cardWidth,
      child: MouseRegion(
        onEnter: (_) => widget.onPopupEnter?.call(),
        onExit: (_) => widget.onPopupExit?.call(),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: _cardMaxHeight),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor, width: 0.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: _buildContent(c),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 浮窗内容主体 — 按区域组织
  // =========================================================================
  Widget _buildContent(CharacterData c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(c),
        const Divider(color: _borderColor, height: 18),
        _buildStatsSection(c),
        const SizedBox(height: _sectionSpacing),
        _buildIdentitySection(c),
        if (c.personalities.isNotEmpty) ...[
          const SizedBox(height: _sectionSpacing),
          _buildPersonalitySection(c),
        ],
        if (c.notes.isNotEmpty) ...[
          const SizedBox(height: _sectionSpacing),
          _buildNotesSection(c),
        ],
        // ── 预留扩展区 ──
        // 如需添加技能列表：
        //   if (c.skills.isNotEmpty) ...[
        //     const SizedBox(height: _sectionSpacing),
        //     _buildSkillsSection(c),
        //   ],
        // 如需添加背包物品：
        //   if (c.backpack.isNotEmpty) ...[
        //     const SizedBox(height: _sectionSpacing),
        //     _buildBackpackSection(c),
        //   ],
        // 如需添加属性详情：
        //   const SizedBox(height: _sectionSpacing),
        //   _buildAttributesSection(c),
      ],
    );
  }

  // =========================================================================
  // 区域：头像 + 名字 + 等级
  // =========================================================================
  Widget _buildHeader(CharacterData c) {
    return Row(
      children: [
        // ── 头像 ──
        _buildPortrait(c.portraitBase64, c.name),
        const SizedBox(width: 12),
        // ── 名字 + 等级 ──
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                c.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Lv.${c.level}',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortrait(String base64, String name) {
    return Container(
      width: _portraitSize,
      height: _portraitSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _accentColor.withValues(alpha: 0.4)),
        color: Colors.grey.shade800,
      ),
      child: base64.isNotEmpty
          ? ClipOval(
              child: Image.memory(
                base64Decode(base64),
                fit: BoxFit.cover,
                errorBuilder: (errCtx, err, stack) => _fallbackAvatar(name),
              ),
            )
          : _fallbackAvatar(name),
    );
  }

  Widget _fallbackAvatar(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // =========================================================================
  // 区域：血量条
  // =========================================================================
  Widget _buildStatsSection(CharacterData c) {
    final ratio = c.maxHp > 0 ? (c.hp / c.maxHp).clamp(0.0, 1.0) : 0.0;
    final hpColor = ratio > 0.6
        ? Colors.green
        : ratio > 0.3
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '血量',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
            Text(
              '${c.hp} / ${c.maxHp}',
              style: TextStyle(
                color: hpColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(hpColor),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 区域：职业 + 种族
  // =========================================================================
  Widget _buildIdentitySection(CharacterData c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _infoRow('职业', c.className),
        // 双职业支持
        if (c.additionalClasses.isNotEmpty)
          _infoRow(
            '副职业',
            c.additionalClasses.join(' / '),
          ),
        _infoRow('种族', c.race),
      ],
    );
  }

  // =========================================================================
  // 区域：性格
  // =========================================================================
  Widget _buildPersonalitySection(CharacterData c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SectionLabel('性格'),
        const SizedBox(height: 4),
        // TODO: 后续可为每条性格添加详情展开箭头
        for (final p in c.personalities)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.psychology_outlined,
                    size: 14, color: _accentColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    p.description != null && p.description!.isNotEmpty
                        ? '${p.trait}：${p.description}'
                        : p.trait,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // =========================================================================
  // 区域：GM 注释
  // =========================================================================
  Widget _buildNotesSection(CharacterData c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SectionLabel('主持注释'),
        const SizedBox(height: 4),
        for (int i = 0; i < c.notes.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _noteRow(i, c.notes[i]),
          ),
      ],
    );
  }

  Widget _noteRow(int index, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}.',
            style: TextStyle(
              color: Colors.amber.shade200,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.amber.shade100,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 共享小组件
  // =========================================================================

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// 区域小标题
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
