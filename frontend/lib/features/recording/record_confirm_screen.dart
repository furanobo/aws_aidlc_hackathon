import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/features/recording/models.dart';
import 'package:buta_app/features/recording/recording_repository.dart';

class RecordConfirmScreen extends ConsumerStatefulWidget {
  final ActivityCategory category;
  const RecordConfirmScreen({super.key, required this.category});

  @override
  ConsumerState<RecordConfirmScreen> createState() => _RecordConfirmScreenState();
}

class _RecordConfirmScreenState extends ConsumerState<RecordConfirmScreen> {
  final _memoController = TextEditingController();
  DateTime _recordedAt = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_memoController.text.length > 100) {
      setState(() => _errorMessage = 'メモは100文字以内で入力してください');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await ref.read(recordingRepositoryProvider).createRecord(
        categoryId: widget.category.categoryId,
        memo: _memoController.text.isEmpty ? null : _memoController.text,
        recordedAt: _recordedAt.toIso8601String(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🐷 +${widget.category.basePoints}pt！ぶたが喜んでいます！'),
            backgroundColor: Colors.pink.shade300,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _errorMessage = '記録に失敗しました');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      widget.category.type == CategoryType.food
                          ? Icons.restaurant : Icons.bed,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.category.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text('+${widget.category.basePoints}pt',
                            style: TextStyle(color: Colors.pink.shade400, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('日時'),
              subtitle: Text('${_recordedAt.year}/${_recordedAt.month}/${_recordedAt.day} ${_recordedAt.hour}:${_recordedAt.minute.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _recordedAt,
                  firstDate: DateTime.now().subtract(const Duration(days: 7)),
                  lastDate: DateTime.now(),
                );
                if (date != null && mounted) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_recordedAt),
                  );
                  if (time != null) {
                    setState(() {
                      _recordedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _memoController,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'メモ（任意）',
                border: OutlineInputBorder(),
                hintText: '例: 深夜2時のラーメン最高だった',
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: const Text('記録する'),
            ),
          ],
        ),
      ),
    );
  }
}
