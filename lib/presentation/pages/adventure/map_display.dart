import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../data/models/models.dart';
import 'token_widget.dart';

/// 地图中心展示区域
class MapDisplay extends StatelessWidget {
  const MapDisplay({
    required this.mapData,
    required this.positions,
    required this.enemies,
    required this.isGM,
    required this.playerName,
    this.character,
    this.characters = const [],
    super.key,
  });

  final MapData mapData;
  final List<PlayerPosition> positions;
  final List<EnemyData> enemies;
  final bool isGM;
  final String playerName;
  final CharacterData? character;
  final List<CharacterData> characters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              if (character != null) ...[
                if (character!.portraitBase64.isNotEmpty)
                  ClipOval(
                    child: Image.memory(
                      base64Decode(character!.portraitBase64),
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    character!.name,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                Expanded(
                  child: Text(
                    isGM ? '主持模式' : playerName,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: mapData.imageBase64.isNotEmpty
                ? LayoutBuilder(
                    builder: (ctx, constraints) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.memory(
                              base64Decode(mapData.imageBase64),
                              fit: BoxFit.contain,
                            ),
                          ),
                          for (final pos in positions)
                            _buildPlayerToken(pos, constraints),
                          for (final e in enemies)
                            TokenWidget(
                              x: e.x,
                              y: e.y,
                              initial: e.name.isNotEmpty
                                  ? e.name[0].toUpperCase()
                                  : 'E',
                              label: '${e.name} HP${e.hp}',
                              isPlayer: false,
                              constraints: constraints,
                            ),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      mapData.name,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 18,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerToken(PlayerPosition pos, BoxConstraints constraints) {
    final char = _findCharacter(pos.name);
    return TokenWidget(
      x: pos.x,
      y: pos.y,
      initial: pos.name[0].toUpperCase(),
      label: pos.name,
      isPlayer: true,
      constraints: constraints,
      portraitBase64: char?.portraitBase64,
      hp: char?.hp,
      maxHp: char?.maxHp,
    );
  }

  CharacterData? _findCharacter(String name) {
    // First check the player's own character
    if (character?.name == name) return character;
    // Then search the full character list
    try {
      return characters.cast<CharacterData?>().firstWhere(
        (c) => c?.name == name,
        orElse: () => null,
      );
    } catch (_) {
      return null;
    }
  }
}
