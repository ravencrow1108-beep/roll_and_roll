import 'dart:convert';

import 'package:flutter/material.dart';

/// 地图上的标记物（角色或敌人），角色显示头像/HP进度条
class TokenWidget extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final showHp = isPlayer && hp != null && maxHp != null && maxHp! > 0;
    final tokenColor = isPlayer ? Colors.deepPurple : Colors.red;

    return Positioned(
      left: x * constraints.maxWidth - 16,
      top: y * constraints.maxHeight - 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 头像/标记圆 ──
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tokenColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child:
                isPlayer && portraitBase64 != null && portraitBase64!.isNotEmpty
                ? ClipOval(
                    child: Image.memory(
                      base64Decode(portraitBase64!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => _initialText(),
                    ),
                  )
                : _initialText(),
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
              label,
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
                      value: hp! / maxHp!,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _hpBarColor(hp!, maxHp!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$hp/$maxHp',
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
        initial,
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
