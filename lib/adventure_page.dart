import 'package:flutter/material.dart';

class AdventurePage extends StatelessWidget {
  const AdventurePage({required this.playerName, this.saveFilePath, super.key});

  final String playerName;
  final String? saveFilePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('冒险中')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '欢迎，$playerName',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (saveFilePath != null)
                Text('已加载存档：${saveFilePath!.split('/').last.split('\\').last}')
              else
                const Text('未选择存档'),
            ],
          ),
        ),
      ),
    );
  }
}
