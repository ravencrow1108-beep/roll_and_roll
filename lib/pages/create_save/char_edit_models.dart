import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../save_data.dart';

/// 职业编辑模型
class ClassEdit {
  final TextEditingController ctrl = TextEditingController();

  ClassEdit({String text = ''}) {
    ctrl.text = text;
  }

  void dispose() => ctrl.dispose();
}

/// 性格编辑模型
class PersonalityEdit {
  final TextEditingController traitCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();

  PersonalityEdit({String trait = '', String description = ''}) {
    traitCtrl.text = trait;
    descCtrl.text = description;
  }

  void dispose() {
    traitCtrl.dispose();
    descCtrl.dispose();
  }
}

/// 角色编辑模型
class CharEdit {
  final nameCtrl = TextEditingController(text: '无名冒险者');
  final List<ClassEdit> classes = [ClassEdit(text: '战士')];
  final raceCtrl = TextEditingController();
  String race = '人类';
  bool raceCustom = false;
  int level = 1;
  List<SkillData> skills = [];
  List<PersonalityEdit> personalities = [];
  List<ItemData> backpack = [];
  int hp = 1;
  int maxHp = 1;
  String portraitBase64 = '';
  Uint8List? portraitBytes;
  final Map<String, int> baseStats = {
    '力量': 10,
    '敏捷': 10,
    '体质': 10,
    '智力': 10,
    '感知': 10,
    '魅力': 10,
  };
  final Map<String, int> customStats = {};

  void dispose() {
    nameCtrl.dispose();
    raceCtrl.dispose();
    for (final c in classes) {
      c.dispose();
    }
    for (final p in personalities) {
      p.dispose();
    }
  }

  CharacterData toCharacterData() => CharacterData(
    name: nameCtrl.text.trim(),
    className: classes.isNotEmpty ? classes.first.ctrl.text.trim() : '',
    additionalClasses: classes
        .skip(1)
        .map((c) => c.ctrl.text.trim())
        .where((s) => s.isNotEmpty)
        .toList(),
    race: raceCustom ? raceCtrl.text.trim() : race,
    level: level,
    skills: skills,
    personalities: personalities
        .map(
          (p) => PersonalityData(
            trait: p.traitCtrl.text.trim(),
            description: p.descCtrl.text.trim().isEmpty
                ? null
                : p.descCtrl.text.trim(),
          ),
        )
        .toList(),
    backpack: backpack,
    strength: baseStats['力量'] ?? 0,
    dexterity: baseStats['敏捷'] ?? 0,
    constitution: baseStats['体质'] ?? 0,
    intelligence: baseStats['智力'] ?? 0,
    wisdom: baseStats['感知'] ?? 0,
    charisma: baseStats['魅力'] ?? 0,
    customStats: Map<String, int>.from(customStats),
    hp: hp,
    maxHp: maxHp,
    portraitBase64: portraitBase64,
  );
}
