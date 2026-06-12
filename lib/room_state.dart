import 'package:flutter/foundation.dart';

class RoomSession {
  RoomSession._();

  static final RoomSession instance = RoomSession._();

  final ValueNotifier<List<String>> membersNotifier =
      ValueNotifier<List<String>>([]);
  final ValueNotifier<String?> hostNameNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> roomAddressNotifier = ValueNotifier<String?>(null);

  bool isHost = false;
  bool isJoined = false;
  String currentPlayerName = '';

  void reset() {
    currentPlayerName = '';
    isHost = false;
    isJoined = false;
    hostNameNotifier.value = null;
    roomAddressNotifier.value = null;
    membersNotifier.value = [];
  }

  void initializeHost(String playerName, {String roomAddress = '等待开放端口'}) {
    currentPlayerName = playerName;
    isHost = true;
    isJoined = false;
    hostNameNotifier.value = playerName;
    roomAddressNotifier.value = roomAddress;
    membersNotifier.value = [playerName];
  }

  void joinRoom(String playerName, {required String roomAddress}) {
    currentPlayerName = playerName;
    isHost = false;
    isJoined = true;
    hostNameNotifier.value = '房主';
    roomAddressNotifier.value = roomAddress;
    membersNotifier.value = [playerName, '房主'];
  }

  void addMember(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final next = [...membersNotifier.value];
    if (!next.contains(trimmed)) {
      next.add(trimmed);
    }
    membersNotifier.value = next;
  }
}
