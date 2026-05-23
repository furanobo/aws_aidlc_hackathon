import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final healthSettingsProvider = FutureProvider<HealthSettings>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return HealthSettings(
    isEnabled: prefs.getBool('health_enabled') ?? false,
    weightEnabled: prefs.getBool('health_weight') ?? true,
    stepsEnabled: prefs.getBool('health_steps') ?? true,
    sleepEnabled: prefs.getBool('health_sleep') ?? true,
    bedtimeTarget: prefs.getInt('health_bedtime_hour') ?? 23,
    sleepDurationTarget: prefs.getInt('health_sleep_duration') ?? 7,
    stepsTarget: prefs.getInt('health_steps_target') ?? 8000,
  );
});

class HealthSettings {
  final bool isEnabled;
  final bool weightEnabled;
  final bool stepsEnabled;
  final bool sleepEnabled;
  final int bedtimeTarget;
  final int sleepDurationTarget;
  final int stepsTarget;

  HealthSettings({
    required this.isEnabled,
    required this.weightEnabled,
    required this.stepsEnabled,
    required this.sleepEnabled,
    required this.bedtimeTarget,
    required this.sleepDurationTarget,
    required this.stepsTarget,
  });
}

class HealthSettingsScreen extends ConsumerStatefulWidget {
  const HealthSettingsScreen({super.key});

  @override
  ConsumerState<HealthSettingsScreen> createState() => _HealthSettingsScreenState();
}

class _HealthSettingsScreenState extends ConsumerState<HealthSettingsScreen> {
  bool _isEnabled = false;
  bool _weightEnabled = true;
  bool _stepsEnabled = true;
  bool _sleepEnabled = true;
  int _bedtimeTarget = 23;
  int _sleepDurationTarget = 7;
  int _stepsTarget = 8000;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEnabled = prefs.getBool('health_enabled') ?? false;
      _weightEnabled = prefs.getBool('health_weight') ?? true;
      _stepsEnabled = prefs.getBool('health_steps') ?? true;
      _sleepEnabled = prefs.getBool('health_sleep') ?? true;
      _bedtimeTarget = prefs.getInt('health_bedtime_hour') ?? 23;
      _sleepDurationTarget = prefs.getInt('health_sleep_duration') ?? 7;
      _stepsTarget = prefs.getInt('health_steps_target') ?? 8000;
    });
  }

  Future<void> _save(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is int) await prefs.setInt(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ヘルスデータ連携')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('ヘルスデータ連携'),
            subtitle: Text(_isEnabled ? '連携中' : '未連携'),
            value: _isEnabled,
            onChanged: (v) {
              setState(() => _isEnabled = v);
              _save('health_enabled', v);
            },
          ),
          const Divider(),
          if (_isEnabled) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('データカテゴリ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            SwitchListTile(
              title: const Text('体重・BMI'),
              value: _weightEnabled,
              onChanged: (v) {
                setState(() => _weightEnabled = v);
                _save('health_weight', v);
              },
            ),
            SwitchListTile(
              title: const Text('歩数'),
              value: _stepsEnabled,
              onChanged: (v) {
                setState(() => _stepsEnabled = v);
                _save('health_steps', v);
              },
            ),
            SwitchListTile(
              title: const Text('睡眠'),
              value: _sleepEnabled,
              onChanged: (v) {
                setState(() => _sleepEnabled = v);
                _save('health_sleep', v);
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('基準値設定', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              title: const Text('就寝基準時刻'),
              trailing: Text('$_bedtimeTarget:00'),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: _bedtimeTarget, minute: 0),
                );
                if (time != null) {
                  setState(() => _bedtimeTarget = time.hour);
                  _save('health_bedtime_hour', time.hour);
                }
              },
            ),
            ListTile(
              title: const Text('睡眠時間基準'),
              trailing: Text('${_sleepDurationTarget}時間'),
              onTap: () async {
                final result = await showDialog<int>(
                  context: context,
                  builder: (ctx) => SimpleDialog(
                    title: const Text('睡眠時間基準'),
                    children: List.generate(10, (i) => i + 4).map((h) =>
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, h),
                        child: Text('$h時間'),
                      ),
                    ).toList(),
                  ),
                );
                if (result != null) {
                  setState(() => _sleepDurationTarget = result);
                  _save('health_sleep_duration', result);
                }
              },
            ),
            ListTile(
              title: const Text('歩数目標'),
              trailing: Text('$_stepsTarget歩'),
              onTap: () async {
                final controller = TextEditingController(text: _stepsTarget.toString());
                final result = await showDialog<int>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('歩数目標'),
                    content: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(suffixText: '歩'),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                );
                if (result != null && result > 0) {
                  setState(() => _stepsTarget = result);
                  _save('health_steps_target', result);
                }
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('連携を解除'),
                      content: const Text('ヘルスデータ連携を解除しますか？\n既存データは保持されます。'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('解除')),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    setState(() => _isEnabled = false);
                    _save('health_enabled', false);
                  }
                },
                child: const Text('連携を解除'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
