import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../data/models/models.dart';

/// 背包物品栏 — 以方格形式展示物品，鼠标悬停弹出详情。
class BackpackPanel extends StatefulWidget {
  const BackpackPanel({
    required this.backpack,
    required this.slotMax,
    super.key,
  });

  final List<ItemData> backpack;
  final int slotMax;

  @override
  State<BackpackPanel> createState() => _BackpackPanelState();
}

class _BackpackPanelState extends State<BackpackPanel> {
  // ── 悬停 ──
  Timer? _hoverTimer;
  Timer? _dismissTimer;
  OverlayEntry? _popupEntry;
  bool _insertingOverlay = false;

  static const Duration _hoverDelay = Duration(milliseconds: 600);

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _dismissTimer?.cancel();
    _dismissPopup();
    super.dispose();
  }

  void _dismissPopup() {
    _dismissTimer?.cancel();
    _popupEntry?.remove();
    _popupEntry = null;
    _insertingOverlay = false;
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.backpack.length;
    final max = widget.slotMax;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 物品格子 ──
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(max, (i) {
            final hasItem = i < count;
            final item = hasItem ? widget.backpack[i] : null;
            return _ItemSlot(
              item: item,
              index: i,
              onHoverEnter: (ctx, offset) {
                if (item == null) return;
                _hoverTimer?.cancel();
                _dismissTimer?.cancel();
                final captured = item;
                _hoverTimer = Timer(_hoverDelay, () {
                  _showPopup(ctx, offset, captured);
                });
              },
              onHoverExit: (_) {
                _hoverTimer?.cancel();
                if (_insertingOverlay) {
                  _insertingOverlay = false;
                  return;
                }
                _dismissTimer?.cancel();
                _dismissTimer = Timer(
                  const Duration(milliseconds: 300),
                  _dismissPopup,
                );
              },
            );
          }),
        ),
        // ── 计数 ──
        const SizedBox(height: 4),
        Text(
          '背包 $count / $max',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  void _showPopup(BuildContext ctx, Offset targetCenter, ItemData item) {
    _dismissPopup();
    final renderBox = ctx.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final globalPos = renderBox.localToGlobal(Offset.zero);
    final center = Offset(
      globalPos.dx + targetCenter.dx,
      globalPos.dy + targetCenter.dy,
    );

    _popupEntry = OverlayEntry(
      builder: (_) => _ItemDetailPopup(
        item: item,
        targetCenter: center,
        onPopupEnter: () {
          _dismissTimer?.cancel();
        },
        onPopupExit: () {
          _dismissTimer?.cancel();
          _dismissTimer = Timer(
            const Duration(milliseconds: 300),
            _dismissPopup,
          );
        },
      ),
    );

    _insertingOverlay = true;
    Overlay.of(context).insert(_popupEntry!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _insertingOverlay = false;
    });
  }
}

// ──────────────────────────────────────────────
// 单个物品格子
// ──────────────────────────────────────────────

class _ItemSlot extends StatelessWidget {
  const _ItemSlot({
    required this.item,
    required this.index,
    required this.onHoverEnter,
    required this.onHoverExit,
  });

  final ItemData? item;
  final int index;
  final void Function(BuildContext ctx, Offset localPos) onHoverEnter;
  final void Function(PointerEvent) onHoverExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double size = 42.0;

    return MouseRegion(
      onHover: item != null
          ? (e) => onHoverEnter(context, e.localPosition)
          : null,
      onExit: onHoverExit,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: item != null
              ? theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5)
              : Colors.grey.shade200.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: item != null
                ? theme.colorScheme.outline.withValues(alpha: 0.2)
                : Colors.grey.shade300.withValues(alpha: 0.3),
          ),
        ),
        child: item == null
            ? null
            : _buildSlotChild(item!, size, theme),
      ),
    );
  }

  Widget _buildSlotChild(ItemData it, double size, ThemeData theme) {
    return it.imageBase64.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.memory(
              base64Decode(it.imageBase64),
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => _itemInitial(it, theme),
            ),
          )
        : _itemInitial(it, theme);
  }

  Widget _itemInitial(ItemData item, ThemeData theme) {
    return Center(
      child: Text(
        item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 物品详情浮窗（悬停弹出）
// ──────────────────────────────────────────────

class _ItemDetailPopup extends StatelessWidget {
  const _ItemDetailPopup({
    required this.item,
    required this.targetCenter,
    this.onPopupEnter,
    this.onPopupExit,
  });

  final ItemData item;
  final Offset targetCenter;
  final VoidCallback? onPopupEnter;
  final VoidCallback? onPopupExit;

  static const double _cardWidth = 200;
  static const Color _bgColor = Color(0xFF1E1E2E);
  static const Color _borderColor = Color(0x55FFFFFF);
  static const Color _accentColor = Color(0xFFBB86FC);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    double left = targetCenter.dx + 16;
    if (left + _cardWidth > screenSize.width - 12) {
      left = targetCenter.dx - _cardWidth - 16;
    }
    if (left < 12) left = 12;

    double top = targetCenter.dy - 80;
    if (top < 12) top = 12;
    if (top + 260 > screenSize.height - 12) {
      top = screenSize.height - 260 - 12;
    }

    return Positioned(
      left: left,
      top: top,
      width: _cardWidth,
      child: MouseRegion(
        onEnter: (_) => onPopupEnter?.call(),
        onExit: (_) => onPopupExit?.call(),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(10),
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderColor, width: 0.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 名称 + 类型 ──
                Row(
                  children: [
                    if (item.imageBase64.isNotEmpty)
                      Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.memory(
                            base64Decode(item.imageBase64),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.type,
                              style: TextStyle(
                                color: _accentColor.withValues(alpha: 0.9),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // ── 属性行（类型 + 价值 + 负重） ──
                const SizedBox(height: 6),
                Row(
                  children: [
                    _statChip(Icons.category_outlined, item.type),
                    const SizedBox(width: 6),
                    if (item.value > 0) ...[
                      _statChip(Icons.monetization_on_outlined, '${item.value}G'),
                      const SizedBox(width: 6),
                    ],
                    if (item.weight > 0)
                      _statChip(Icons.monitor_weight_outlined, '${item.weight}'),
                  ],
                ),
                // ── 效果 ──
                if (item.effect.isNotEmpty) ...[
                  const Divider(color: _borderColor, height: 16),
                  Text(
                    item.effect,
                    style: TextStyle(
                      color: Colors.green.shade300,
                      fontSize: 12,
                    ),
                  ),
                ],
                // ── 描述 ──
                if (item.description.isNotEmpty) ...[
                  const Divider(color: _borderColor, height: 16),
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _statChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white38),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
}
