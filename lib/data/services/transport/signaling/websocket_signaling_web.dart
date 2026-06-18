// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

/// Web (dart:html) WebSocket 包装。
class WebSocketWrapper {
  WebSocketWrapper._(this._ws) {
    _ws.onClose.listen((_) => _onDoneController.add(null));
    _ws.onMessage.listen((event) => _messageController.add(event.data as String));
    _ws.onError.listen((_) => _messageController.addError('WebSocket error'));
  }

  final html.WebSocket _ws;

  final StreamController<String> _messageController = StreamController<String>();
  final StreamController<void> _onDoneController = StreamController<void>();

  Stream<String> get messages => _messageController.stream;
  Stream<void> get onDone => _onDoneController.stream;

  void send(String data) => _ws.send(data);

  Future<void> close() async {
    _ws.close();
    await _messageController.close();
    await _onDoneController.close();
  }
}

Future<WebSocketWrapper> connect(String url) {
  final completer = Completer<WebSocketWrapper>();
  final ws = html.WebSocket(url);

  ws.onOpen.listen((_) {
    if (!completer.isCompleted) completer.complete(WebSocketWrapper._(ws));
  });

  ws.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.completeError(TimeoutException('WebSocket connection to $url failed'));
    }
  });

  Timer(const Duration(seconds: 10), () {
    if (!completer.isCompleted) {
      ws.close();
      completer.completeError(TimeoutException('WebSocket connection to $url timed out'));
    }
  });

  return completer.future;
}
