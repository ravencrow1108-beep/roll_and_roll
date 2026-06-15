import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../data/models/models.dart';
import 'character_detail_popup.dart';

/// 地图上的标记物（角色或敌人），角色显示头像/HP进度条、多条注释气泡。
///
/// 当 `characterData` 不为空时，鼠标悬停 1 秒弹出角色详情浮窗。
class TokenWidget extends StatefulWidget {
  const TokenWidget({
    required this.x,
    required this.y,
    required this.initial,
    required this.label,
    required this.isPlayer,
    required this.constraints,
    this.hp,
    this.maxHp,
    this.portraitBase64,
    this.isDragged = false,
    this.notes = const [],
    this.onDeleteNote,
    this.characterData,
    super.key,
  });

  final double x;
  final double y;
  final String initial;
  final String label;
  final bool isPlayer;
  final BoxConstraints constraints;
  final int? hp;
  final int? maxHp;
  final String? portraitBase64;
  final bool isDragged;
  final List<String> notes;
  final void Function(int index)? onDeleteNote;

  /// 完整角色数据，用于悬停浮窗。
  /// 为 null 时不启用悬停（敌人 token 无此字段）。
  final CharacterData? characterData;

  @override
  State<TokenWidget> createState() => _TokenWidgetState();
}

class _TokenWidgetState extends State<TokenWidget> {
  // ── 悬停定时器 ──
  Timer? _hoverTimer;
  Timer? _dismissTimer;
  OverlayEntry? _popupEntry;
  bool _insertingOverlay = false;
  final GlobalKey _avatarKey = GlobalKey();

  static const Duration _hoverDelay = Duration(seconds: 1);

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _dismissTimer?.cancel();
    _dismissPopup();
    super.dispose();
  }

  // ── 悬停逻辑 ──

  void _onHoverEnter(PointerEvent event) {
    if (widget.characterData == null) return;
    _hoverTimer?.cancel();
    _dismissTimer?.cancel();
    _hoverTimer = Timer(_hoverDelay, _showPopup);
  }

  void _onHoverExit(PointerEvent event) {
    _hoverTimer?.cancel();

    // Overlay 插入会触发一次虚假的 onExit（浮窗盖住了头像）。
    // 用 _insertingOverlay 标记跳过这次。
    if (_insertingOverlay) {
      _insertingOverlay = false;
      return;
    }

    _dismissTimer?.cancel();
    _dismissTimer = Timer(
      const Duration(milliseconds: 300),
      _dismissPopup,
    );
  }

  void _showPopup() {
    _dismissPopup();
    if (widget.characterData == null) return;

    final box =
        _avatarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final center = box.localToGlobal(
      box.size.center(Offset.zero),
    );

    _popupEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          CharacterDetailPopup(
            character: widget.characterData!,
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
        ],
      ),
    );

    _insertingOverlay = true;
    Overlay.of(context).insert(_popupEntry!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _insertingOverlay = false;
    });
  }

  void _dismissPopup() {
    _dismissTimer?.cancel();
    _popupEntry?.remove();
    _popupEntry = null;
    _insertingOverlay = false;
  }

  // ── 构建 ──

  @override
  Widget build(BuildContext context) {
    final showHp =
        widget.isPlayer &&
        widget.hp != null &&
        widget.maxHp != null &&
        widget.maxHp! > 0;
    final tokenColor = widget.isPlayer ? Colors.deepPurple : Colors.red;
    final tokenSize = widget.isDragged ? 38.0 : 32.0;
    final halfSize = tokenSize / 2;
    final borderColor = widget.isDragged ? Colors.amber : Colors.white;
    final borderWidth = widget.isDragged ? 3.0 : 2.0;
    const double noteAreaWidth = 80.0;
    // 单条注释气泡高度 ≈ padding(4) + fontSize8.5*lineHeight1.25 + margin(2)
    const double noteBubbleH = 19.0;

    // 注释条数 → 需要把整个 Column 向上偏移的量
    final notesShift =
        widget.isPlayer ? widget.notes.length * noteBubbleH : 0.0;

    // 头像锚点 = (x,y)，因为注释在上方，Positioned(top) 需额外上移 notesShift，
    // 这样头像的绝对坐标始终 = y*maxHeight
    return Positioned(
      left: widget.x * widget.constraints.maxWidth - halfSize,
      top: widget.y * widget.constraints.maxHeight - halfSize - notesShift,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 注释气泡（头像正上方竖直叠加） ──
          if (widget.isPlayer)
            for (int i = 0; i < widget.notes.length; i++)
              _NoteBubble(
                note: widget.notes[i],
                maxWidth: noteAreaWidth,
                onDelete: widget.onDeleteNote != null
                    ? () => widget.onDeleteNote!(i)
                    : null,
                isLast: i == widget.notes.length - 1,
              ),
          // ── 头像圆（带悬停检测） ──
          MouseRegion(
            onEnter: _onHoverEnter,
            onExit: _onHoverExit,
            child: Container(
                key: _avatarKey,
                width: tokenSize,
                height: tokenSize,
                decoration: BoxDecoration(
                  color: tokenColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: borderWidth,
                  ),
                  boxShadow: widget.isDragged
                      ? [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: widget.isPlayer &&
                        widget.portraitBase64 != null &&
                        widget.portraitBase64!.isNotEmpty
                    ? ClipOval(
                        child: Image.memory(
                          base64Decode(widget.portraitBase64!),
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, _) => _initialText(),
                        ),
                      )
                    : _initialText(),
              ),
            ),
          const SizedBox(height: 2),
          // ── 名称标签 ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              widget.label,
              style: const TextStyle(color: Colors.white, fontSize: 9),
            ),
          ),
          // ── HP 进度条 ──
          if (showHp) ...[
            const SizedBox(height: 2),
            SizedBox(
              width: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: widget.hp! / widget.maxHp!,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _hpBarColor(widget.hp!, widget.maxHp!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${widget.hp}/${widget.maxHp}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _initialText() {
    return Center(
      child: Text(
        widget.initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Color _hpBarColor(int hp, int maxHp) {
    final ratio = hp / maxHp;
    if (ratio > 0.6) return Colors.green;
    if (ratio > 0.3) return Colors.orange;
    return Colors.red;
  }
}

/// 角色头顶单条注释气泡，含删除×按钮
class _NoteBubble extends StatelessWidget {
  const _NoteBubble({
    required this.note,
    required this.maxWidth,
    this.onDelete,
    this.isLast = true,
  });

  final String note;
  final double maxWidth;
  final VoidCallback? onDelete;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 0.5,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            // 给 × 按钮留空间
            padding: EdgeInsets.only(right: onDelete != null ? 14 : 0),
            child: Text(
              note,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8.5,
                height: 1.25,
                shadows: [Shadow(color: Colors.black87, blurRadius: 1)],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onDelete != null)
            Positioned(
              top: 0,
              right: -1,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 12,
                  height: 12,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 8, color: Colors.white),
                ),
              ),
            ),
          // 最后一条气泡下方的小三角尖
          if (isLast)
            Positioned(
              bottom: -4,
              left: 0,
              right: 0,
              child: Center(
                child: CustomPaint(
                  size: const Size(8, 4),
                  painter: _TrianglePainter(
                    color: Colors.black.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 向下小三角
class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) => old.color != color;
}
