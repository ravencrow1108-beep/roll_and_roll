import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'socket_support.dart';
import 'transport/webrtc/webrtc_game.dart';
import 'transport/webrtc/ice_config.dart';
import 'transport/protocol/signal_message.dart';
import 'transport/signaling/websocket_signaling.dart';
import 'transport/legacy/socket_support_adapter.dart';

/// Phase 2: 房间连接层 —— 封装 Cloudflare DO 信令 + WebRTC DataChannel。
///
/// 替代旧的 `WebSocketGameTransport`，对上层提供相同的
/// `RoomServerHandle` / `RoomClientHandle` 接口，UI 零改动。
///
/// 流程：
///   Host:  HTTP createRoom → wss auth → 等待 player → WebRTC offer/answer
///   Player: wss auth → 接收 offer → WebRTC answer → DataChannel OPEN
class RoomConnection {
  RoomConnection._();

  /// 最近一次 createRoom 创建的房间 ID（调试/测试用）。
  static String? lastRoomId;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Host 端：创建房间
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// 创建房间（Host 端），返回 [RoomServerHandle]。
  ///
  /// [workerUrl] 例如 `https://signal.roll-and-roll.com`
  /// [hostName] 房主名称
  /// [hostRole] 房主角色
  /// [onClient] 玩家加入回调
  static Future<RoomServerHandle> createRoom({
    required String workerUrl,
    required String hostName,
    String hostRole = '主持',
    required void Function(String playerId, String name) onClient,
  }) async {
    // 1. HTTP 创建房间
    final roomId = await _httpCreateRoom(workerUrl);
    lastRoomId = roomId;
    debugPrint('[RoomConnection] Created room: $roomId');

    // 2. 连接信令（Host）
    final signaling = WebSocketSignaling(
      workerUrl: workerUrl,
      roomId: roomId,
      role: 'host',
      name: hostName,
    );

    await signaling.connect();
    // 等待 auth_ok
    await signaling.signals
        .firstWhere((s) => s.type == SignalMessage.authOk)
        .timeout(const Duration(seconds: 10));
    debugPrint('[RoomConnection] Host authenticated');

    // 3. 创建 WebRTC Host 传输
    final gameTransport = HostWebRTCGameTransport(
      iceConfig: IceConfig.defaultConfig,
    );

    // Phase 2: name → playerId 映射（用于踢人/定向发送）
    final nameToPlayerId = <String, String>{};

    // 4. 信令 ↔ WebRTC 桥接
    gameTransport.onLocalSignal = (playerId, signal) {
      // Host → DO → Player
      final type = signal['type'] as String? ?? '';
      if (type == 'offer') {
        signaling.sendSignal(SignalMessage.createOffer(
          sdp: signal['sdp'] as String,
          targetPlayerId: playerId,
        ));
      } else if (type == 'iceCandidate') {
        signaling.sendSignal(SignalMessage(
          type: SignalMessage.iceCandidate,
          payload: {
            'from': 'host',
            'playerId': playerId,
            'candidate': signal['candidate'],
            'sdpMid': signal['sdpMid'],
            'sdpMLineIndex': signal['sdpMLineIndex'],
          },
        ));
      }
    };

    // 监听 DO → Host 的信令
    signaling.signals.listen((sig) async {
      switch (sig.type) {
        case 'player_joined':
          final playerId = sig.payload['playerId'] as String? ?? '';
          final name = sig.payload['name'] as String? ?? playerId;
          nameToPlayerId[name] = playerId;
          debugPrint('[RoomConnection] Player joined: $name ($playerId)');
          onClient(playerId, name);

          // 为该 Player 创建 PeerConnection
          gameTransport.createConnectionFor(playerId);
          break;

        case SignalMessage.answer:
          final sdp = sig.payload['sdp'] as String?;
          final fromPid = sig.payload['playerId'] as String? ?? '';
          if (sdp != null && fromPid.isNotEmpty) {
            gameTransport.handleRemoteSignal(
              fromPid,
              {'type': 'answer', 'sdp': sdp},
            );
          }
          break;

        case SignalMessage.iceCandidate:
          if (sig.payload['from'] != 'host') {
            final fromPid = sig.payload['playerId'] as String? ?? '';
            gameTransport.handleRemoteSignal(fromPid, {
              'type': 'iceCandidate',
              ...sig.payload,
            });
          }
          break;

        case 'player_left':
          final pid = sig.payload['playerId'] as String? ?? '';
          final pname = sig.payload['name'] as String? ?? '';
          nameToPlayerId.remove(pname);
          gameTransport.kickPlayer(pid);
          break;
      }
    });

    await gameTransport.connect();

    // 5. 适配为旧接口（带 name→playerId 映射）
    final adapter = ServerHandleAdapter(gameTransport,
        nameToPlayerId: nameToPlayerId);
    return adapter;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Player 端：加入房间
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// 加入房间（Player 端），返回 [RoomClientHandle]。
  ///
  /// [workerUrl] 例如 `https://signal.roll-and-roll.com`
  /// [roomId] 房间号（6位大写字母）
  /// [playerName] 玩家名称
  /// [role] 玩家角色
  static Future<RoomClientHandle> joinRoom({
    required String workerUrl,
    required String roomId,
    required String playerName,
    String role = '玩家',
  }) async {
    // 1. 连接信令（Player）
    final signaling = WebSocketSignaling(
      workerUrl: workerUrl,
      roomId: roomId,
      role: 'player',
      name: playerName,
    );

    await signaling.connect();

    // 等待 auth_ok
    final authOk = await signaling.signals
        .firstWhere((s) => s.type == SignalMessage.authOk)
        .timeout(const Duration(seconds: 10));
    final playerId = authOk.payload['playerId'] as String? ?? '';
    debugPrint('[RoomConnection] Player authenticated: $playerId');

    // 2. 创建 WebRTC Client 传输
    final gameTransport = ClientWebRTCGameTransport(
      iceConfig: IceConfig.defaultConfig,
    );

    // 3. 信令 ↔ WebRTC 桥接
    gameTransport.onLocalSignal = (signal) {
      final type = signal['type'] as String? ?? '';
      if (type == 'answer') {
        signaling.sendSignal(SignalMessage(
          type: SignalMessage.answer,
          payload: {
            'sdp': signal['sdp'],
            'playerId': playerId,
          },
        ));
      } else if (type == 'iceCandidate') {
        signaling.sendSignal(SignalMessage(
          type: SignalMessage.iceCandidate,
          payload: {
            'from': 'player',
            'playerId': playerId,
            'candidate': signal['candidate'],
            'sdpMid': signal['sdpMid'],
            'sdpMLineIndex': signal['sdpMLineIndex'],
          },
        ));
      }
    };

    // 监听 DO → Player 的信令
    final offerReceived = Completer<RTCSessionDescription>();
    signaling.signals.listen((sig) async {
      switch (sig.type) {
        case SignalMessage.offer:
          final sdp = sig.payload['sdp'] as String?;
          if (sdp != null && !offerReceived.isCompleted) {
            offerReceived.complete(RTCSessionDescription(sdp, 'offer'));
          }
          break;

        case SignalMessage.iceCandidate:
          if (sig.payload['from'] == 'host') {
            gameTransport.handleRemoteSignal({
              'type': 'iceCandidate',
              ...sig.payload,
            });
          }
          break;

        case 'player_left':
          // Another player left — game transport doesn't care
          break;
      }
    });

    // 4. 等待 offer 并 accept
    final offer = await offerReceived.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('No offer received from host'),
    );
    await gameTransport.acceptOffer(offer);
    debugPrint('[RoomConnection] WebRTC accepted offer');

    // 5. 等待 DataChannel OPEN
    for (int i = 0; i < 40; i++) {
      if (gameTransport.connected) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    debugPrint('[RoomConnection] DataChannel: ${gameTransport.connected}');

    // 6. 适配为旧接口
    final adapter = ClientHandleAdapter(gameTransport);
    return adapter;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 工具
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static Future<String> _httpCreateRoom(String workerUrl) async {
    final uri = Uri.parse('$workerUrl/createRoom');
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      final response = await request.close().timeout(
            const Duration(seconds: 10),
          );
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception('createRoom failed: $body');
      }
      return data['roomId'] as String;
    } finally {
      client.close();
    }
  }
}
