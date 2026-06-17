import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

/// 局内语音服务 — 录音 / 播放，socket 通信由调用方处理
class VoiceService {
  VoiceService._();

  static final VoiceService instance = VoiceService._();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  /// 是否已加入语音频道
  final ValueNotifier<bool> isInChannel = ValueNotifier(false);

  /// 麦克风是否静音
  final ValueNotifier<bool> isMuted = ValueNotifier(false);

  /// 可用麦克风设备列表
  final ValueNotifier<List<InputDevice>> availableMics =
      ValueNotifier<List<InputDevice>>([]);

  /// 当前选中的麦克风设备 ID
  final ValueNotifier<String?> selectedMicId = ValueNotifier<String?>(null);

  /// 正在发言的成员名
  final ValueNotifier<Set<String>> speakingMembers = ValueNotifier<Set<String>>(
    {},
  );

  /// 自身麦克风音量 (0.0 ~ 1.0)
  final ValueNotifier<double> micVolume = ValueNotifier<double>(0.0);

  StreamSubscription<Uint8List>? _recordingSub;
  StreamSubscription<Amplitude>? _amplitudeSub;
  bool _isRecording = false;

  /// 音频数据回调 (PCM bytes → 外部通过 socket 发送)
  void Function(Uint8List pcmData)? onAudioCaptured;

  /// 加入语音频道
  Future<void> joinChannel() async {
    if (isInChannel.value) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('没有麦克风权限');
    }

    // 枚举可用麦克风
    try {
      final mics = await _recorder.listInputDevices();
      availableMics.value = mics;
      if (mics.isNotEmpty && selectedMicId.value == null) {
        selectedMicId.value = mics.first.id;
      }
    } catch (_) {
      availableMics.value = [];
    }

    isInChannel.value = true;
    await _startRecording();
  }

  /// 退出语音频道
  Future<void> leaveChannel() async {
    if (!isInChannel.value) return;

    isInChannel.value = false;
    await _stopAll();
    speakingMembers.value = {};
  }

  /// 切换静音（不停止录音器，只在回调中丢弃数据）
  Future<void> toggleMute() async {
    isMuted.value = !isMuted.value;
    micVolume.value = 0.0;
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;

    try {
      final config = const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        numChannels: 1,
        sampleRate: 16000,
      );
      final stream = await _recorder.startStream(config);

      _isRecording = true;
      _recordingSub = stream.listen(
        (data) {
          if (isMuted.value || !isInChannel.value) return;
          onAudioCaptured?.call(data);
        },
        onError: (_) => _isRecording = false,
        cancelOnError: true,
      );

      // 振幅监听（自身音量指示器）
      _amplitudeSub?.cancel();
      _amplitudeSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amp) {
            if (isMuted.value) return;
            final v = ((amp.current + 60) / 60).clamp(0.0, 1.0);
            micVolume.value = v;
          });
    } catch (_) {
      _isRecording = false;
    }
  }

  Future<void> _stopRecording() async {
    await _recordingSub?.cancel();
    _recordingSub = null;
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    micVolume.value = 0.0;
    _isRecording = false;
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
  }

  Future<void> _stopAll() async {
    await _stopRecording();
    try {
      await _player.stop();
    } catch (_) {}
  }

  /// 播放接收到的语音数据 (base64 → PCM → 播放)
  void playVoiceData(String from, String base64Data) {
    if (!isInChannel.value) return;

    try {
      final pcmBytes = base64Decode(base64Data);
      _player.play(BytesSource(pcmBytes));

      final current = Set<String>.from(speakingMembers.value);
      current.add(from);
      speakingMembers.value = current;

      Future.delayed(const Duration(seconds: 2), () {
        final updated = Set<String>.from(speakingMembers.value);
        updated.remove(from);
        speakingMembers.value = updated;
      });
    } catch (_) {}
  }

  void dispose() {
    leaveChannel();
    _player.dispose();
    _recorder.dispose();
    isInChannel.dispose();
    isMuted.dispose();
    speakingMembers.dispose();
    availableMics.dispose();
    selectedMicId.dispose();
    micVolume.dispose();
  }
}
