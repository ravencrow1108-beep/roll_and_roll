import 'dart:async';
import 'dart:io';

/// Desktop (dart:io) WebSocket 包装。
class WebSocketWrapper {
  WebSocketWrapper._(this._ws) {
    _ws.done.then((_) => _onDoneController.add(null));
  }

  final WebSocket _ws;
  final StreamController<void> _onDoneController = StreamController<void>();

  Stream<String> get messages =>
      _ws.map((data) => data is String ? data : String.fromCharCodes(data as List<int>));

  Stream<void> get onDone => _onDoneController.stream;

  void send(String data) => _ws.add(data);

  Future<void> close() async {
    await _ws.close();
    await _onDoneController.close();
  }
}

Future<WebSocketWrapper> connect(String url) async {
  final ws = await WebSocket.connect(url).timeout(
    const Duration(seconds: 10),
    onTimeout: () => throw TimeoutException('WebSocket connection to $url timed out'),
  );
  return WebSocketWrapper._(ws);
}
