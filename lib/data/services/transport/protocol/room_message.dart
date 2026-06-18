import 'dart:convert';

/// 统一游戏消息协议 —— 所有游戏数据（聊天、骰子、地图、Token等）的标准化信封。
///
/// Phase 0：作为内存表示，现有 WebSocket 线上格式不变（向后兼容）。
/// Phase 2+：WebRTC DataChannel 直接使用 [toJson]/[fromJson] 作为线上格式。
class RoomMessage {
  /// 协议版本号，当前 = 1
  final int version;

  /// 全局唯一消息 ID（UUID v4），用于去重、重放检测、日志关联
  final String messageId;

  /// Unix 毫秒时间戳，发送方本地时钟
  final int timestamp;

  /// 消息类型，参见 [RoomMessage.type] 常量
  final String type;

  /// 发送者标识（Host 为 "host"；Player 为 playerId）
  final String senderId;

  /// 消息载荷，类型相关
  final Map<String, dynamic> payload;

  const RoomMessage({
    this.version = 1,
    required this.messageId,
    required this.timestamp,
    required this.type,
    required this.senderId,
    required this.payload,
  });

  // ─── 工厂：从现有数据创建 ───

  /// 快捷构造（自动生成 messageId + timestamp）
  factory RoomMessage.create({
    int version = 1,
    required String type,
    required String senderId,
    required Map<String, dynamic> payload,
  }) =>
      RoomMessage(
        version: version,
        messageId: _generateId(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        type: type,
        senderId: senderId,
        payload: payload,
      );

  // ─── 序列化（Phase 2+ 线上格式） ───

  Map<String, dynamic> toJson() => {
        'version': version,
        'messageId': messageId,
        'timestamp': timestamp,
        'type': type,
        'senderId': senderId,
        'payload': payload,
      };

  factory RoomMessage.fromJson(Map<String, dynamic> json) => RoomMessage(
        version: json['version'] as int? ?? 1,
        messageId: json['messageId'] as String? ?? _generateId(),
        timestamp: json['timestamp'] as int? ??
            DateTime.now().millisecondsSinceEpoch,
        type: json['type'] as String,
        senderId: json['senderId'] as String? ?? '',
        payload: json['payload'] as Map<String, dynamic>? ?? {},
      );

  // ─── Phase 0 兼容：与旧协议互转 ───

  /// 从旧协议 Map 创建（Phase 0 过渡用）。
  ///
  /// 旧协议格式: `{"type":"chat_message","from":"张三","text":"hello"}`
  /// 映射规则：
  ///   - `from` → senderId
  ///   - 其余字段 → payload
  ///   - `type` 映射到新类型名（参见 [_legacyTypeMap]）
  factory RoomMessage.fromLegacy(Map<String, dynamic> map) {
    final legacyType = map['type'] as String? ?? '';
    final from = map['from'] as String? ?? map['name'] as String? ?? '';

    // 复制所有字段到 payload（不含 type/from）
    final payload = Map<String, dynamic>.from(map);
    payload.remove('type');
    payload.remove('from');

    final newType = _legacyTypeMap[legacyType] ?? legacyType;

    return RoomMessage.create(
      type: newType,
      senderId: from,
      payload: payload,
    );
  }

  /// 从旧协议 JSON 字符串创建（Phase 0 过渡用）。
  ///
  /// 委托给 [RoomMessage.fromLegacy]。
  factory RoomMessage.fromLegacyString(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return RoomMessage.fromLegacy(map);
  }

  /// 转换回旧协议 Map（Phase 0 过渡用）。
  ///
  /// 注意：先展开 payload，再覆盖 type/from，确保 payload 中的
  /// type/from 不会污染输出。
  Map<String, dynamic> toLegacy() {
    final map = <String, dynamic>{
      ...payload,
      'type': _reverseLegacyTypeMap[type] ?? type,
      'from': senderId,
    };
    return map;
  }

  /// 转换回旧协议 JSON 字符串（Phase 0 过渡用）。
  ///
  /// 委托给 [toLegacy]。
  String toLegacyString() => jsonEncode(toLegacy());

  // ─── 调试 ───

  @override
  String toString() =>
      'RoomMessage(v$version, $type, from=$senderId, id=$messageId)';

  // ─── 消息类型常量 ───

  static const String chat = 'chat';
  static const String dice = 'dice';
  static const String mapUpdate = 'map_update';
  static const String tokenMove = 'token_move';
  static const String tokenPlace = 'token_place';
  static const String playerReady = 'player_ready';
  static const String playerCancelReady = 'player_cancel_ready';
  static const String memberJoined = 'member_joined';
  static const String memberLeft = 'member_left';
  static const String membersList = 'members_list';
  static const String adventureStarted = 'adventure_started';
  static const String startAdventure = 'start_adventure';
  static const String characterCreate = 'character_create';
  static const String characterUpdate = 'character_update';
  static const String positionUpdate = 'position_update';
  static const String hostSaveChanged = 'host_save_changed';
  static const String roleChange = 'role_change';
  static const String returnToRoom = 'return_to_room';
  static const String kicked = 'kicked';
  static const String hostDisconnected = 'host_disconnected';
  static const String hostLeaving = 'host_leaving';
  static const String hostMigrated = 'host_migrated';
  static const String nameTaken = 'name_taken';
  static const String hostSettingUp = 'host_setting_up';
  static const String requestMembers = 'request_members';
  static const String voiceData = 'voice_data';
  static const String voiceJoin = 'voice_join';
  static const String voiceLeave = 'voice_leave';

  // ─── 旧→新类型映射（Phase 0 兼容） ───

  static const Map<String, String> _legacyTypeMap = {
    'chat_message': chat,
    'dice_result': dice,
    'adventure_started': adventureStarted,
    'start_adventure': startAdventure,
    'position_update': positionUpdate,
    'character_create': characterCreate,
    'character_update': characterUpdate,
    'player_ready': playerReady,
    'player_cancel_ready': playerCancelReady,
    'member_joined': memberJoined,
    'member_left': memberLeft,
    'members_list': membersList,
    'host_save_changed': hostSaveChanged,
    'host_setting_up': hostSettingUp,
    'role_change': roleChange,
    'return_to_room': returnToRoom,
    'kicked': kicked,
    'host_disconnected': hostDisconnected,
    'name_taken': nameTaken,
    'voice_data': voiceData,
    'voice_join': voiceJoin,
    'voice_leave': voiceLeave,
  };

  static const Map<String, String> _reverseLegacyTypeMap = {
    chat: 'chat_message',
    dice: 'dice_result',
    adventureStarted: 'adventure_started',
    startAdventure: 'start_adventure',
    positionUpdate: 'position_update',
    characterCreate: 'character_create',
    characterUpdate: 'character_update',
    playerReady: 'player_ready',
    playerCancelReady: 'player_cancel_ready',
    memberJoined: 'member_joined',
    memberLeft: 'member_left',
    membersList: 'members_list',
    hostSaveChanged: 'host_save_changed',
    hostSettingUp: 'host_setting_up',
    roleChange: 'role_change',
    returnToRoom: 'return_to_room',
    kicked: 'kicked',
    hostDisconnected: 'host_disconnected',
    nameTaken: 'name_taken',
    voiceData: 'voice_data',
    voiceJoin: 'voice_join',
    voiceLeave: 'voice_leave',
  };

  // ─── 内部工具 ───

  static int _idCounter = 0;
  static final String _prefix =
      '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-';

  static String _generateId() {
    _idCounter++;
    return '$_prefix${_idCounter.toRadixString(36)}';
  }
}
