import 'package:flutter/foundation.dart';

import 'save_data.dart';
import 'socket_support.dart';

class RoomSession {
  RoomSession._();

  static final RoomSession instance = RoomSession._();

  final ValueNotifier<List<String>> membersNotifier =
      ValueNotifier<List<String>>([]);
  final ValueNotifier<String?> hostNameNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> roomAddressNotifier = ValueNotifier<String?>(
    null,
  );

  /// Fires when the host starts the adventure – clients should navigate.
  final ValueNotifier<bool> startAdventureNotifier = ValueNotifier<bool>(false);

  /// Tracks which players have clicked "ready".
  final ValueNotifier<Set<String>> readyMembersNotifier =
      ValueNotifier<Set<String>>({});

  /// The map data to display once all players are ready.
  final ValueNotifier<MapData?> mapNotifier = ValueNotifier<MapData?>(null);

  bool isHost = false;
  bool isJoined = false;
  String currentPlayerName = '';

  /// The server handle (only valid on host).
  RoomServerHandle? _serverHandle;

  /// The client handle (only valid on joined clients).
  RoomClientHandle? _clientHandle;

  RoomServerHandle? get serverHandle => _serverHandle;

  void setServerHandle(RoomServerHandle? h) => _serverHandle = h;

  RoomClientHandle? get clientHandle => _clientHandle;

  void setClientHandle(RoomClientHandle? h) => _clientHandle = h;

  /// Broadcast a JSON message to all connected clients.
  void broadcast(Map<String, dynamic> data) {
    _serverHandle?.broadcast(socketEncode(data));
  }

  void reset() {
    currentPlayerName = '';
    isHost = false;
    isJoined = false;
    hostNameNotifier.value = null;
    roomAddressNotifier.value = null;
    membersNotifier.value = [];
    startAdventureNotifier.value = false;
    readyMembersNotifier.value = {};
    mapNotifier.value = null;
    _serverHandle = null;
    _clientHandle?.close();
    _clientHandle = null;
  }

  void initializeHost(String playerName, {String roomAddress = '等待开放端口'}) {
    currentPlayerName = playerName;
    isHost = true;
    isJoined = false;
    hostNameNotifier.value = playerName;
    roomAddressNotifier.value = roomAddress;
    membersNotifier.value = [playerName];
    startAdventureNotifier.value = false;
    readyMembersNotifier.value = {};
    mapNotifier.value = null;
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

  /// Called by a player client when they are ready with a character selected.
  void setPlayerReady(String playerName) {
    final next = {...readyMembersNotifier.value, playerName};
    readyMembersNotifier.value = next;

    // Notify the host
    _clientHandle?.send(
      socketEncode({'type': 'player_ready', 'name': playerName}),
    );
  }

  /// Called by the host when receiving a player_ready message.
  void onPlayerReady(String name) {
    setStateReady(name);
  }

  void setStateReady(String name) {
    final next = {...readyMembersNotifier.value, name};
    readyMembersNotifier.value = next;
  }
}
