import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../lib/data/services/socket_support.dart';

// ═══════════════════════════════════════════════════════════════
// Phase 2 — PlatformSocketSupport DO+WebRTC 集成测试
//
// 与 UI 使用完全相同的 API，验证完整链路。
// flutter run -t test/transport/phase2_room_test.dart -d windows
// ═══════════════════════════════════════════════════════════════

void main() => runApp(const Phase2App());

class Phase2App extends StatefulWidget {
  const Phase2App({super.key});
  @override
  State<Phase2App> createState() => _Phase2AppState();
}

class _Phase2AppState extends State<Phase2App> {
  final List<_Step> _steps = [];
  bool _running = false;
  String _status = 'Idle';

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          appBar: AppBar(
            title: const Text('Phase 2: DO+WebRTC via PlatformSocketSupport'),
            backgroundColor: const Color(0xFF16213E),
          ),
          body: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF0F3460),
              child: Row(children: [
                const Icon(Icons.wifi, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_status,
                        style: const TextStyle(color: Colors.white, fontSize: 14))),
                ElevatedButton.icon(
                  onPressed: _running ? null : _run,
                  icon: _running
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_arrow),
                  label: Text(_running ? 'Running...' : 'Run Test'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                ),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _steps.length,
                  itemBuilder: (_, i) => _tile(_steps[i])),
            ),
          ]),
        ),
      );

  Widget _tile(_Step s) {
    final icon = s.ok == null
        ? Icons.schedule : s.ok! ? Icons.check_circle : Icons.error;
    final c = s.ok == null
        ? Colors.orange : s.ok! ? Colors.green : Colors.red;
    return Card(
      color: const Color(0xFF16213E),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: c, size: 24),
        title: Text(s.title, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: s.detail.isNotEmpty ? Text(s.detail, style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 12)) : null,
      ),
    );
  }

  void _add(String t, String d) {
    debugPrint('  ➤ $t');
    setState(() => _steps.add(_Step(title: t, detail: d)));
  }

  void _mark(int i, bool ok, String d) {
    debugPrint('    ${ok ? "✅" : "❌"} $d');
    setState(() { if (i < _steps.length) _steps[i] = _steps[i].copyWith(ok: ok, detail: d); });
  }

  Future<void> _run() async {
    setState(() { _running = true; _steps.clear(); _status = 'Starting...'; });

    // Ensure DO mode
    PlatformSocketSupport.useDO = true;
    PlatformSocketSupport.workerUrl = 'https://signal.roll-and-roll.com';

    RoomServerHandle? server;
    RoomClientHandle? client;
    StreamSubscription<String>? clientSub;

    try {
      // ── Step 1: Host creates room ──
      _add('Step 1', 'startServer()');
      final joined = Completer<String>();
      server = await PlatformSocketSupport.startServer(0,
        onClient: (pid, name, role) {
          if (!joined.isCompleted) joined.complete(name);
        },
        hostName: 'GM', hostRole: '主持',
      );
      final roomId = PlatformSocketSupport.lastRoomId ?? 'unknown';
      _mark(0, true, 'Room: $roomId');

      // ── Step 2: Player joins ──
      _add('Step 2', 'connectToRoom("$roomId")');
      client = await PlatformSocketSupport.connectToRoom(
        roomId, 0, playerName: 'Player1', role: '玩家',
      );
      _mark(1, client.isConnected, 'connected: ${client.isConnected}');

      // Wait for DataChannel to be ready
      await Future.delayed(const Duration(seconds: 2));

      // ── Step 3: Host broadcast → client receive ──
      _add('Step 3', 'server.broadcast(chat)');
      final clientMsgs = <String>[];
      clientSub = client.messages.listen(clientMsgs.add);

      server.broadcast(socketEncode({
        'type': 'chat_message', 'from': 'GM', 'text': 'Phase 2 OK!',
      }));
      await Future.delayed(const Duration(seconds: 1));

      final gotChat = clientMsgs.any((raw) {
        try { return (jsonDecode(raw)['text'] ?? '') == 'Phase 2 OK!'; }
        catch (_) { return false; }
      });
      _mark(2, gotChat, gotChat ? 'Received chat' : 'FAILED');

      // ── Step 4: Client → Host ──
      _add('Step 4', 'client.send(player_ready)');
      final hostMsgs = <String>[];
      final hSub = server.messages.listen(hostMsgs.add);

      client.send(socketEncode({'type': 'player_ready', 'name': 'Player1'}));
      await Future.delayed(const Duration(seconds: 1));

      final gotReady = hostMsgs.any((raw) {
        try { return (jsonDecode(raw)['type'] ?? '') == 'player_ready'; }
        catch (_) { return false; }
      });
      await hSub.cancel();
      _mark(3, gotReady, gotReady ? 'Host received ready' : 'FAILED');

      // ── Result ──
      final all = gotChat && gotReady && client.isConnected;
      setState(() => _status = all ? '✅ ALL PASSED' : '❌ FAILURES');

    } catch (e, stack) {
      _add('ERROR', '$e');
      _mark(_steps.length - 1, false, '');
      setState(() => _status = '❌ $e');
      debugPrint('$e\n$stack');
    } finally {
      await clientSub?.cancel();
      await client?.close();
      await server?.close();
      setState(() => _running = false);
    }
  }
}

class _Step {
  final String title;
  final String detail;
  final bool? ok;
  const _Step({required this.title, this.detail = '', this.ok});
  _Step copyWith({bool? ok, String? detail}) =>
      _Step(title: title, detail: detail ?? this.detail, ok: ok);
}
