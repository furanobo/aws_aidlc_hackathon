import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SyncSummaryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> syncResults;
  final int totalPoints;

  const SyncSummaryScreen({
    super.key,
    required this.syncResults,
    required this.totalPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('同期サマリー')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.pink.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🐷 ', style: TextStyle(fontSize: 32)),
                Text(
                  '${totalPoints > 0 ? "+" : ""}$totalPoints pt',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: totalPoints > 0 ? Colors.pink : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: syncResults.length,
              itemBuilder: (context, index) {
                final item = syncResults[index];
                final points = item['points'] as int? ?? 0;
                final isUnhealthy = points > 0;
                return ListTile(
                  leading: Icon(
                    isUnhealthy ? Icons.trending_up : Icons.trending_down,
                    color: isUnhealthy ? Colors.pink : Colors.blue,
                  ),
                  title: Text(item['label'] ?? ''),
                  subtitle: Text(item['syncDate'] ?? ''),
                  trailing: Text(
                    '${points > 0 ? "+" : ""}${points}pt',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isUnhealthy ? Colors.pink : Colors.blue,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('確認'),
            ),
          ),
        ],
      ),
    );
  }
}
