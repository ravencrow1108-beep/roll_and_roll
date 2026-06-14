import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import 'character_data.dart';
import 'item_data.dart';
import 'map_data.dart';
import 'player_position.dart';
import 'rule_data.dart';

/// 存档数据模型（整合三类对象）— ZIP 格式
class SaveData {
  final int version;
  final String createdAt;
  final List<CharacterData> characters;
  final List<MapData> maps;
  final List<ItemData> items;
  final List<PlayerPosition> playerPositions;
  final RuleData rules;

  const SaveData({
    this.version = 1,
    required this.createdAt,
    this.characters = const [],
    this.maps = const [],
    this.items = const [],
    this.playerPositions = const [],
    this.rules = const RuleData(),
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'characters': characters.map((c) => c.toJson()).toList(),
    'maps': maps.map((m) => m.toJson()).toList(),
    'items': items.map((i) => i.toJson()).toList(),
    'createdAt': createdAt,
    if (playerPositions.isNotEmpty)
      'playerPositions': playerPositions.map((p) => p.toJson()).toList(),
    'rules': rules.toJson(),
  };

  factory SaveData.fromJson(Map<String, dynamic> json) {
    List<CharacterData> chars;
    if (json.containsKey('characters')) {
      chars = (json['characters'] as List<dynamic>)
          .map((c) => CharacterData.fromJson(c as Map<String, dynamic>))
          .toList();
    } else if (json.containsKey('character')) {
      chars = [
        CharacterData.fromJson(
          json['character'] as Map<String, dynamic>? ?? {},
        ),
      ];
    } else {
      chars = [];
    }
    return SaveData(
      version: json['version'] as int? ?? 1,
      createdAt:
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      characters: chars,
      maps:
          (json['maps'] as List<dynamic>?)
              ?.map((m) => MapData.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      items:
          (json['items'] as List<dynamic>?)
              ?.map((i) => ItemData.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      playerPositions:
          (json['playerPositions'] as List<dynamic>?)
              ?.map((p) => PlayerPosition.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      rules: json.containsKey('rules')
          ? RuleData.fromJson(json['rules'] as Map<String, dynamic>)
          : const RuleData(),
    );
  }

  // ═══════════════════════════════════════════════
  //  ZIP 存档（v2）
  // ═══════════════════════════════════════════════

  /// Write this SaveData to a ZIP file at [path].
  /// Images are stored as raw PNG bytes inside the archive.
  Future<void> packToZip(String path) async {
    final archive = Archive();

    // 1. JSON manifest (without base64 blobs — images are separate files)
    final manifest = _toZipManifest();
    archive.addFile(
      ArchiveFile(
        'save.json',
        utf8
            .encode(const JsonEncoder.withIndent('  ').convert(manifest))
            .length,
        utf8.encode(const JsonEncoder.withIndent('  ').convert(manifest)),
      ),
    );

    // 2. Map images
    for (final m in maps) {
      if (m.imageBase64.isNotEmpty) {
        final bytes = base64Decode(m.imageBase64);
        archive.addFile(
          ArchiveFile('maps/${_safeFileName(m.name)}.png', bytes.length, bytes),
        );
      }
    }

    // 3. Character portraits
    for (final c in characters) {
      if (c.portraitBase64.isNotEmpty) {
        final bytes = base64Decode(c.portraitBase64);
        archive.addFile(
          ArchiveFile(
            'portraits/${_safeFileName(c.name)}.png',
            bytes.length,
            bytes,
          ),
        );
      }
    }

    final encoded = ZipEncoder().encode(archive);
    await File(path).writeAsBytes(encoded, flush: true);
  }

  /// Generate a clean manifest that references image paths instead of
  /// embedding base64 blobs.
  Map<String, dynamic> _toZipManifest() {
    final mapJson = maps.map((m) {
      final j = m.toJson();
      if (m.imageBase64.isNotEmpty) {
        j['imageFile'] = 'maps/${_safeFileName(m.name)}.png';
        j.remove('imageBase64');
      }
      return j;
    }).toList();

    final charJson = characters.map((c) {
      final j = c.toJson();
      if (c.portraitBase64.isNotEmpty) {
        j['portraitFile'] = 'portraits/${_safeFileName(c.name)}.png';
        j.remove('portraitBase64');
      }
      return j;
    }).toList();

    return {
      'version': 2,
      'format': 'zip',
      'createdAt': createdAt,
      'characters': charJson,
      'maps': mapJson,
      'items': items.map((i) => i.toJson()).toList(),
      if (playerPositions.isNotEmpty)
        'playerPositions': playerPositions.map((p) => p.toJson()).toList(),
      'rules': rules.toJson(),
    };
  }

  /// Read a ZIP archive and reconstruct SaveData with images loaded
  /// into base64 fields.
  static Future<SaveData> fromZip(String path) async {
    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Find save.json
    final manifestFile = archive.findFile('save.json');
    if (manifestFile == null) {
      throw FormatException('ZIP 存档中缺少 save.json');
    }

    final manifest =
        jsonDecode(utf8.decode(manifestFile.content as List<int>))
            as Map<String, dynamic>;

    // Load maps, injecting imageBase64 from ZIP image entries
    final maps = <MapData>[];
    for (final m in (manifest['maps'] as List<dynamic>? ?? <dynamic>[])) {
      final j = m as Map<String, dynamic>;
      final imageFile = j['imageFile'] as String?;
      if (imageFile != null) {
        final img = archive.findFile(imageFile);
        if (img != null) {
          j['imageBase64'] = base64Encode(img.content as List<int>);
        }
      }
      j.remove('imageFile');
      maps.add(MapData.fromJson(j));
    }

    // Load characters, injecting portraitBase64 from ZIP image entries
    final characters = <CharacterData>[];
    for (final c in (manifest['characters'] as List<dynamic>? ?? <dynamic>[])) {
      final j = c as Map<String, dynamic>;
      final portraitFile = j['portraitFile'] as String?;
      if (portraitFile != null) {
        final img = archive.findFile(portraitFile);
        if (img != null) {
          j['portraitBase64'] = base64Encode(img.content as List<int>);
        }
      }
      j.remove('portraitFile');
      characters.add(CharacterData.fromJson(j));
    }

    return SaveData(
      version: manifest['version'] as int? ?? 1,
      createdAt:
          manifest['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      characters: characters,
      maps: maps,
      items:
          (manifest['items'] as List<dynamic>?)
              ?.map((i) => ItemData.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      playerPositions:
          (manifest['playerPositions'] as List<dynamic>?)
              ?.map((p) => PlayerPosition.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      rules: manifest.containsKey('rules')
          ? RuleData.fromJson(manifest['rules'] as Map<String, dynamic>)
          : const RuleData(),
    );
  }

  /// Sanitize a name for use as a file name inside the ZIP.
  static String _safeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }
}
