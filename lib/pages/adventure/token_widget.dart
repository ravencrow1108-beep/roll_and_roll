import 'package:flutter/material.dart';

/// 地图上的标记物（玩家或敌人）
class TokenWidget extends StatelessWidget {
  const TokenWidget({
    required this.x,
    required this.y,
    required this.initial,
    required this.label,
    required this.isPlayer,
    required this.constraints,
    super.key,
  });

  final double x;
  final double y;
  final String initial;
  final String label;
  final bool isPlayer;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x * constraints.maxWidth - 16,
      top: y * constraints.maxHeight - 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isPlayer ? Colors.deepPurple : Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              label,
              style:
                  const TextStyle(color: Colors.white, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}
