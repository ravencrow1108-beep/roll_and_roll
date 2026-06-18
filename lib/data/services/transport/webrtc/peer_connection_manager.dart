import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../protocol/room_message.dart';
import 'ice_config.dart';

/// WebRTC 信令回调：向外暴露 offer/answer/ICE candidate，由外部信令层转发。
typedef SignalingCallback = void Function(Map<String, dynamic> signal);

/// 单个 PeerConnection 的管理器。
///
/// 封装一个 [RTCPeerConnection] + 一条 [RTCDataChannel] 的生命周期。
///
/// **Host 模式：**
///   1. [createOffer] → 生成 SDP Offer + DataChannel
///   2. 收到 Answer 后调用 [setRemoteAnswer]
///   3. ICE candidates 通过 [onSignal] 回调暴露
///   4. DataChannel OPEN → [connected] = true
///
/// **Client 模式：**
///   1. 收到 Offer 后调用 [acceptOffer]
///   2. 自动创建 Answer，通过 [onSignal] 暴露
///   3. ICE candidates 通过 [onSignal] 回调暴露
///   4. DataChannel OPEN → [connected] = true
class PeerConnectionManager {
  PeerConnectionManager({
    this.label = 'game',
    this.onSignal,
    Map<String, dynamic>? iceConfig,
  }) : _config = iceConfig ?? IceConfig.defaultConfig;

  final String label;
  final Map<String, dynamic> _config;
  final SignalingCallback? onSignal;

  RTCPeerConnection? _pc;
  RTCDataChannel? _dc;

  final StreamController<RoomMessage> _messageController =
      StreamController<RoomMessage>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  StreamSubscription<RTCDataChannelState>? _dcStateSub;
  StreamSubscription<RTCDataChannelMessage>? _dcMessageSub;
  bool _connected = false;

  /// 连接状态
  bool get connected => _connected;

  /// 连接状态变化流
  Stream<bool> get onConnectionChanged => _connectionController.stream;

  /// DataChannel 消息流（已解析为 RoomMessage）
  Stream<RoomMessage> get messages => _messageController.stream;

  /// 当前 DataChannel（可能为 null 直到连接建立）
  RTCDataChannel? get dataChannel => _dc;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Host 模式
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// [Host] 创建 PeerConnection + DataChannel + Offer。
  Future<RTCSessionDescription> createOffer() async {
    _pc = await createPeerConnection(_config);

    // 创建 DataChannel（Host 端主动创建）
    final init = RTCDataChannelInit()..ordered = true;
    _dc = await _pc!.createDataChannel(label, init);
    _setupDataChannel();

    // 监听 ICE candidates
    _pc!.onIceCandidate = (RTCIceCandidate candidate) {
      onSignal?.call({
        'type': 'iceCandidate',
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    // 监听连接状态
    _pc!.onIceConnectionState = (RTCIceConnectionState state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        _setConnected(false);
      }
    };

    // 生成 Offer
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    return offer;
  }

  /// [Host] 收到 Client 的 Answer 后设置远程描述。
  Future<void> setRemoteAnswer(RTCSessionDescription answer) async {
    await _pc?.setRemoteDescription(answer);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Client 模式
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// [Client] 收到 Host 的 Offer，创建 Answer。
  Future<RTCSessionDescription> acceptOffer(
      RTCSessionDescription offer) async {
    _pc = await createPeerConnection(_config);

    // 监听远程 DataChannel（Client 端被动接收）
    _pc!.onDataChannel = (RTCDataChannel channel) {
      _dc = channel;
      _setupDataChannel();
    };

    // 监听 ICE candidates
    _pc!.onIceCandidate = (RTCIceCandidate candidate) {
      onSignal?.call({
        'type': 'iceCandidate',
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    // 监听连接状态
    _pc!.onIceConnectionState = (RTCIceConnectionState state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        _setConnected(false);
      }
    };

    await _pc!.setRemoteDescription(offer);
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    return answer;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 共享方法
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// 添加远程 ICE Candidate。
  Future<void> addRemoteCandidate(RTCIceCandidate candidate) async {
    await _pc?.addCandidate(candidate);
  }

  /// 发送 RoomMessage 到此 DataChannel。
  Future<void> send(RoomMessage message) async {
    if (!_connected || _dc == null) return;
    final json = jsonEncode(message.toJson());
    _dc!.send(RTCDataChannelMessage(json));
  }

  /// 关闭连接。
  Future<void> close() async {
    _connected = false;
    await _dcStateSub?.cancel();
    await _dcMessageSub?.cancel();
    _dcStateSub = null;
    _dcMessageSub = null;
    try {
      await _dc?.close();
    } catch (_) {}
    try {
      await _pc?.close();
    } catch (_) {}
    _dc = null;
    _pc = null;
    await _messageController.close();
    await _connectionController.close();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 内部
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _setupDataChannel() {
    if (_dc == null) return;

    _dcStateSub = _dc!.stateChangeStream.listen((state) {
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        _setConnected(true);
      } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
        _setConnected(false);
      }
    });

    _dcMessageSub = _dc!.messageStream.listen((RTCDataChannelMessage msg) {
      if (msg.isBinary) return; // 只处理文本消息
      try {
        final json = jsonDecode(msg.text) as Map<String, dynamic>;
        final roomMsg = RoomMessage.fromJson(json);
        _messageController.add(roomMsg);
      } catch (_) {
        // 无法解析的消息静默丢弃
      }
    });
  }

  void _setConnected(bool state) {
    if (_connected != state) {
      _connected = state;
      _connectionController.add(state);
    }
  }
}
