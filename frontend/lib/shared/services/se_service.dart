import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Se { record, attack, defend, victory, defeat }

class SeService {
  SeService._();
  static final instance = SeService._();

  final _players = <Se, AudioPlayer>{};

  static const _assets = {
    Se.record: 'audio/se_record.mp3',
    Se.attack: 'audio/se_attack.mp3',
    Se.defend: 'audio/se_defend.mp3',
    Se.victory: 'audio/se_victory.mp3',
    Se.defeat: 'audio/se_defeat.mp3',
  };

  static const _volumes = {
    Se.record: 0.7,
    Se.attack: 0.8,
    Se.defend: 0.6,
    Se.victory: 0.9,
    Se.defeat: 0.9,
  };

  Future<void> play(Se se) async {
    var player = _players[se];
    if (player == null) {
      player = AudioPlayer();
      _players[se] = player;
    }
    await player.setVolume(_volumes[se] ?? 0.5);
    await player.stop();
    await player.play(AssetSource(_assets[se]!));
  }
}

final seServiceProvider = Provider<SeService>((ref) => SeService.instance);
