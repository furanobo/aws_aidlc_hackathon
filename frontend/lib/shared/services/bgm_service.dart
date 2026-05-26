import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BgmTrack { pixelPartyRun, menuScreenNap, pixelPantryPanic, glitchyWaffleDuel }

class BgmService {
  BgmService._();
  static final instance = BgmService._();

  final _player = AudioPlayer();
  BgmTrack? _current;

  static const _assets = {
    BgmTrack.pixelPartyRun: 'audio/bgm_pixel_party_run.mp3',
    BgmTrack.menuScreenNap: 'audio/bgm_menu_screen_nap.mp3',
    BgmTrack.pixelPantryPanic: 'audio/bgm_pixel_pantry_panic.mp3',
    BgmTrack.glitchyWaffleDuel: 'audio/bgm_glitchy_waffle_duel.mp3',
  };

  static BgmTrack trackForRoute(String route) {
    if (route == '/start' || route == '/loading' || route == '/tutorial' ||
        route == '/error' || route == '/maintenance' || route == '/force-update') {
      return BgmTrack.pixelPartyRun;
    }
    if (route.startsWith('/battle-')) {
      return BgmTrack.glitchyWaffleDuel;
    }
    if (route.startsWith('/record-')) {
      return BgmTrack.pixelPantryPanic;
    }
    return BgmTrack.menuScreenNap;
  }

  Future<void> play(BgmTrack track) async {
    if (_current == track && _player.state == PlayerState.playing) return;
    _current = track;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0.5);
    await _player.play(AssetSource(_assets[track]!));
  }

  Future<void> stop() async {
    _current = null;
    await _player.stop();
  }
}

final bgmServiceProvider = Provider<BgmService>((ref) => BgmService.instance);
