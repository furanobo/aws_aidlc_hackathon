import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buta_app/features/recording/models.dart';
import 'package:buta_app/features/recording/recording_repository.dart';

class RecordHistoryScreen extends ConsumerStatefulWidget {
  const RecordHistoryScreen({super.key});

  @override
  ConsumerState<RecordHistoryScreen> createState() => _RecordHistoryScreenState();
}

class _RecordHistoryScreenState extends ConsumerState<RecordHistoryScreen> {
  final List<ActivityRecord> _records = [];
  String? _cursor;
  bool _hasMore = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final data = await ref.read(recordingRepositoryProvider).getRecords(cursor: _cursor);
      final items = (data['items'] as List).map((e) => ActivityRecord.fromJson(e)).toList();
      setState(() {
        _records.addAll(items);
        _cursor = data['nextCursor'];
        _hasMore = data['nextCursor'] != null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('記録履歴')),
      body: _records.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _records.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _records.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _loadMore,
                        child: _isLoading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('もっと見る'),
                      ),
                    ),
                  );
                }

                final record = _records[index];
                final isAuto = record.source == RecordSource.autoDetected;
                return ListTile(
                  leading: Icon(
                    isAuto ? Icons.autorenew : Icons.edit_note,
                    color: isAuto ? Colors.green : Colors.orange,
                  ),
                  title: Text(record.categoryId),
                  subtitle: Text(record.recordedAt.substring(0, 16).replaceFirst('T', ' ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${record.points > 0 ? "+" : ""}${record.points}pt',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: record.points > 0 ? Colors.pink : Colors.blue,
                        ),
                      ),
                      if (isAuto) const SizedBox(width: 4),
                      if (isAuto)
                        const Chip(label: Text('自動', style: TextStyle(fontSize: 10)), padding: EdgeInsets.zero),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
