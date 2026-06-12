import 'package:flutter/material.dart';

class LiveModePage extends StatelessWidget {
  const LiveModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('直播模式')),
      body: const Center(child: Text('这里将来可以用于直播模式')),
    );
  }
}
