import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../game/game_transport.dart';
import '../protocol/room_message.dart';
import 'ice_config.dart';
import 'peer_connection_manager.dart';

/// 本地信令回调类型。
///
/// Host 端: `(playerId, signal)` — signal 需转发给对应 playerId 的客户端。
/// Client 端: `(signal)` — signal 需转发给 Host。
typedef LocalSignalCallback = void Function(Map<String, dynamic> signal);

/// 备用信令回调（Host 端带 playerId）。
typedef HostSignalCallback = void Function(
    String playerId, Map<String, dynamic> signal);

// ═══════════════════════════════════════════════════════════════
// HostWebRTCGameTransport
// ═══════════════════════════════════════════════════════════════

/// WebRTC Host 端传输（Star Topology 中心节点）。
///
/// 为每个 Player 维护独立的 [PeerConnectionManager] + DataChannel。
/// 信令数据通过 [onLocalSignal] 暴露，由外部信令层转发。
///
/// Phase 1A：本地手动信令（无 Cloudflare），调用方通过以下方式完成信令：
///   1. 监听 [onLocalSignal] 获取 offer/ICE candidates
///   2. 使用 [handleRemoteSignal] 注入 Player 的 answer/ICE candidates
class HostWebRTCGameTransport extends HostGameTransport {
  HostWebRTCGameTransport({Map<String, dynamic>? iceConfig})
      : _iceConfig = iceConfig ?? IceConfig.defaultConfig;

  final Map<String, dynamic> _iceConfig;

  /// playerId → PeerConnectionManager
  final Map<String, PeerConnectionManager> _managers = {};

  final StreamController<RoomMessage> _messageController =
      StreamController<RoomMessage>.broadcast();
  final StreamController<String> _playerConnectedController =
      StreamController<String>.broadcast();
  final StreamController<String> _playerDisconnectedController =
      StreamController<String>.broadcast();

  bool _connected = false;

  /// 本地信令回调：Host 生成的 offer/ICE candidates 通过此回调暴露。
  /// 签名: `(playerId, signal)`
  HostSignalCallback? onLocalSignal;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // HostGameTransport 接口实现
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  bool get connected => _connected;

  @override
  Stream<RoomMessage> get messages => _messageController.stream;

  @override
  Stream<String> get onPlayerConnected => _playerConnectedController.stream;

  @override
  Stream<String> get onPlayerDisconnected =>
      _playerDisconnectedController.stream;

  @override
  Map<String, bool> get playerConnectionStates {
    final map = <String, bool>{};
    for (final entry in _managers.entries) {
      map[entry.key] = entry.value.connected;
    }
    return map;
  }

  @override
  Future<void> connect() async {
    _connected = true;
  }

  @override
  Future<void> broadcast(RoomMessage message) async {
    for (final mgr in _managers.values) {
      if (mgr.connected) {
        await mgr.send(message);
      }
    }
  }

  @override
  Future<void> sendToPlayer(String playerId, RoomMessage message) async {
    final mgr = _managers[playerId];
    if (mgr != null && mgr.connected) {
      await mgr.send(message);
    }
  }

  @override
  Future<void> kickPlayer(String playerId) async {
    final mgr = _managers.remove(playerId);
    if (mgr != null) {
      await mgr.close();
      _playerDisconnectedController.add(playerId);
    }
  }

  @override
  Future<void> close() async {
    _connected = false;
    for (final mgr in _managers.values) {
      await mgr.close();
    }
    _managers.clear();
    await _messageController.close();
    await _playerConnectedController.close();
    await _playerDisconnectedController.close();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // WebRTC 信令 API
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// 为指定 [playerId] 创建 PeerConnection + Offer。
  ///
  /// 返回的 Offer 同时通过 [onLocalSignal] 回调暴露。
  /// 调用方应将其转发给对应 Player。
  Future<RTCSessionDescription> createConnectionFor(String playerId) async {
    if (_managers.containsKey(playerId)) {
      throw StateError('Player $playerId already has a connection');
    }

    final mgr = PeerConnectionManager(
      label: 'game_$playerId',
      iceConfig: _iceConfig,
      onSignal: (signal) {
        // 转发 ICE candidates
        onLocalSignal?.call(playerId, signal);
      },
    );

    // 监听此 Player 的消息
    mgr.messages.listen((msg) {
      _messageController.add(msg);
    });

    // 监听连接状态
    mgr.onConnectionChanged.listen((connected) {
      if (connected) {
        _playerConnectedController.add(playerId);
      } else {
        _playerDisconnectedController.add(playerId);
      }
    });

    final offer = await mgr.createOffer();
    _managers[playerId] = mgr;

    // 暴露 Offer 给信令层
    onLocalSignal?.call(playerId, {
      'type': 'offer',
      'sdp': offer.sdp,
    });

    return offer;
  }

  /// 处理从 Player 收到的远程信令数据（answer 或 ICE candidate）。
  Future<void> handleRemoteSignal(
      String playerId, Map<String, dynamic> signal) async {
    final mgr = _managers[playerId];
    if (mgr == null) return;

    final type = signal['type'] as String? ?? '';

    switch (type) {
      case 'answer':
        final sdp = signal['sdp'] as String?;
        if (sdp != null) {
          await mgr.setRemoteAnswer(RTCSessionDescription(sdp, 'answer'));
        }
        break;
      case 'iceCandidate':
        final candidate = signal['candidate'] as String?;
        final sdpMid = signal['sdpMid'] as String?;
        final sdpMLineIndex = signal['sdpMLineIndex'] as int?;
        if (candidate != null) {
          await mgr.addRemoteCandidate(
            RTCIceCandidate(candidate, sdpMid, sdpMLineIndex),
          );
        }
        break;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// ClientWebRTCGameTransport
// ═══════════════════════════════════════════════════════════════

/// WebRTC Client 端传输。
///
/// 维护单条到 Host 的 DataChannel。
/// 信令数据通过 [onLocalSignal] 暴露，由外部信令层转发。
///
/// Phase 1A：本地手动信令（无 Cloudflare），调用方通过以下方式完成信令：
///   1. 调用 [acceptOffer] 接受 Host 的 Offer
///   2. 监听 [onLocalSignal] 获取 Answer/ICE candidates
///   3. 使用 [handleRemoteSignal] 注入远端的 ICE candidates
class ClientWebRTCGameTransport extends ClientGameTransport {
  ClientWebRTCGameTransport({Map<String, dynamic>? iceConfig})
      : _iceConfig = iceConfig ?? IceConfig.defaultConfig;

  final Map<String, dynamic> _iceConfig;

  PeerConnectionManager? _manager;
  bool _connected = false;

  final StreamController<RoomMessage> _messageController =
      StreamController<RoomMessage>.broadcast();

  /// 本地信令回调：Answer + ICE candidates 通过此回调暴露。
  LocalSignalCallback? onLocalSignal;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ClientGameTransport 接口实现
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  bool get connected => _connected;

  @override
  Stream<RoomMessage> get messages => _messageController.stream;

  @override
  Future<void> connect() async {
    // Phase 1A: 连接由 acceptOffer 触发，此处为 no-op。
    // Phase 1B: 信令层会先 connect → acceptOffer。
  }

  @override
  Future<void> send(RoomMessage message) async {
    await _manager?.send(message);
  }

  @override
  Future<void> close() async {
    _connected = false;
    await _manager?.close();
    _manager = null;
    await _messageController.close();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // WebRTC 信令 API
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// 接受 Host 的 Offer，生成 Answer。
  ///
  /// 返回的 Answer 同时通过 [onLocalSignal] 回调暴露。
  /// 调用方应将其转发给 Host。
  Future<RTCSessionDescription> acceptOffer(
      RTCSessionDescription offer) async {
    _manager = PeerConnectionManager(
      label: 'game_client',
      iceConfig: _iceConfig,
      onSignal: (signal) {
        onLocalSignal?.call(signal);
      },
    );

    // 监听 Host 的消息
    _manager!.messages.listen((msg) {
      _messageController.add(msg);
    });

    // 监听连接状态
    _manager!.onConnectionChanged.listen((connected) {
      _connected = connected;
    });

    final answer = await _manager!.acceptOffer(offer);

    // 暴露 Answer 给信令层
    onLocalSignal?.call({
      'type': 'answer',
      'sdp': answer.sdp,
    });

    return answer;
  }

  /// 处理从 Host 收到的远程 ICE Candidate。
  Future<void> handleRemoteSignal(Map<String, dynamic> signal) async {
    final type = signal['type'] as String? ?? '';
    if (type != 'iceCandidate') return;

    final candidate = signal['candidate'] as String?;
    final sdpMid = signal['sdpMid'] as String?;
    final sdpMLineIndex = signal['sdpMLineIndex'] as int?;
    if (candidate != null) {
      await _manager?.addRemoteCandidate(
        RTCIceCandidate(candidate, sdpMid, sdpMLineIndex),
      );
    }
  }
}
