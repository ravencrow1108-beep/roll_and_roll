import 'package:desktop_multi_window/desktop_multi_window.dart';

/// Get the args for the current window.
Future<String> currentWindowArgs() async {
  final c = await WindowController.fromCurrentEngine();
  return c.arguments;
}

/// Open a separate OS window with the given JSON arguments.
/// Always creates a new window — never reuses to avoid cross-window
/// method channel deadlocks.
Future<Object?> openPlayerWindow(String args) async {
  try {
    final ctrl = await WindowController.create(
      WindowConfiguration(arguments: args),
    );
    await ctrl.show();
    return ctrl;
  } catch (_) {
    return null;
  }
}

/// Hide a player window. Call this before creating a new one to avoid
/// GPU resource contention between multiple Flutter engines.
Future<void> closePlayerWindow(Object? controller) async {
  final ctrl = controller as WindowController?;
  if (ctrl == null) return;
  try {
    await ctrl.hide().timeout(const Duration(seconds: 2));
  } catch (_) {
    // Window may already be destroyed, ignore
  }
}
