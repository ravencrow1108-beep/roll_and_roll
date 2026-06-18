import 'package:flutter/foundation.dart';

import '../../data/models/player_position.dart';
import '../../data/models/map_data.dart';
import '../../data/services/socket_support.dart';

/// 房间会话单例，管理成员列表、角色、准备状态、地图数据与网络句柄
class RoomSession {
  RoomSession._();

  static final RoomSession instance = RoomSession._();

  final ValueNotifier<List<String>> membersNotifier =
      ValueNotifier<List<String>>([]);

  /// Maps member name → role (e.g. '玩家', '主持').
  final ValueNotifier<Map<String, String>> memberRolesNotifier =
      ValueNotifier<Map<String, String>>({});
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

  /// Player token positions placed by the host.
  final ValueNotifier<List<PlayerPosition>> playerPositionsNotifier =
      ValueNotifier<List<PlayerPosition>>([]);

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
    memberRolesNotifier.value = {};
    startAdventureNotifier.value = false;
    readyMembersNotifier.value = {};
    mapNotifier.value = null;
    playerPositionsNotifier.value = [];
    _serverHandle = null;
    _clientHandle?.close();
    _clientHandle = null;
  }

  void initializeHost(
    String playerName, {
    String roomAddress = '等待开放端口',
    String role = '玩家',
  }) {
    currentPlayerName = playerName;
    isHost = true;
    isJoined = false;
    hostNameNotifier.value = playerName;
    roomAddressNotifier.value = roomAddress;
    membersNotifier.value = [playerName];
    memberRolesNotifier.value = {playerName: role};
    startAdventureNotifier.value = false;
    readyMembersNotifier.value = {};
    mapNotifier.value = null;
    playerPositionsNotifier.value = [];
  }

  void joinRoom(
    String playerName, {
    required String roomAddress,
    String role = '玩家',
  }) {
    currentPlayerName = playerName;
    isHost = false;
    isJoined = true;
    hostNameNotifier.value = '';
    roomAddressNotifier.value = roomAddress;
    membersNotifier.value = [playerName];
    memberRolesNotifier.value = {playerName: role};
  }

  void addMember(String name, {String role = '玩家'}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final next = [...membersNotifier.value];
    if (!next.contains(trimmed)) {
      next.add(trimmed);
    }
    membersNotifier.value = next;

    // Track the role
    final nextRoles = {...memberRolesNotifier.value};
    nextRoles[trimmed] = role;
    memberRolesNotifier.value = nextRoles;
  }

  /// Update the host's own role.
  void setHostRole(String role) {
    final nextRoles = {...memberRolesNotifier.value};
    nextRoles[currentPlayerName] = role;
    memberRolesNotifier.value = nextRoles;
    _serverHandle?.updateHostRole(role);
  }

  void hostSetSave(String fileName) {
    if (_serverHandle != null) {
      _serverHandle!.broadcast(
        socketEncode({'type': 'host_save_changed', 'fileName': fileName}),
      );
      _serverHandle!.updateHostSaveName(fileName);
    }
  }

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

  /// Remove a player from the ready set (used when a player cancels ready).
  void setStateNotReady(String name) {
    final next = {...readyMembersNotifier.value}..remove(name.trim());
    readyMembersNotifier.value = next;
  }

  /// Remove a member from the member list.
  void removeMember(String name) {
    final trimmed = name.trim();
    final next = [...membersNotifier.value]..remove(trimmed);
    membersNotifier.value = next;
    final nextRoles = {...memberRolesNotifier.value}..remove(trimmed);
    memberRolesNotifier.value = nextRoles;
  }

  /// Kick a member (host only).
  void kickMember(String name) {
    _serverHandle?.kickClient(name);
  }

  /// Send the full member list to all connected clients (used by refresh).
  void sendFullMemberList() {
    if (_serverHandle == null) return;
    final roles = memberRolesNotifier.value;
    final allList = membersNotifier.value
        .map((n) => {'name': n, 'role': roles[n] ?? '玩家'})
        .toList();
    broadcast({'type': 'members_list', 'members': allList});
  }
}
