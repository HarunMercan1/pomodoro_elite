import 'package:audioplayers/audioplayers.dart';

abstract interface class TimerAudioGateway {
  Future<void> playAlarm(String soundFile);

  Future<void> stopAlarm();

  Future<void> playMusic(String filePath, double volume);

  Future<void> stopMusic();

  Future<void> setMusicVolume(double volume);

  Future<void> dispose();
}

class AudioPlayersTimerAudioGateway implements TimerAudioGateway {
  final AudioPlayer _alarmPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  @override
  Future<void> playAlarm(String soundFile) async {
    await _alarmPlayer.stop();
    await _alarmPlayer.setSource(AssetSource('sounds/bell/$soundFile'));
    await _alarmPlayer.setVolume(1.0);
    await _alarmPlayer.setReleaseMode(ReleaseMode.stop);
    await _alarmPlayer.resume();
  }

  @override
  Future<void> stopAlarm() => _alarmPlayer.stop();

  @override
  Future<void> playMusic(String filePath, double volume) async {
    await _musicPlayer.setSource(DeviceFileSource(filePath));
    await _musicPlayer.setVolume(volume);
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.resume();
  }

  @override
  Future<void> stopMusic() => _musicPlayer.stop();

  @override
  Future<void> setMusicVolume(double volume) {
    return _musicPlayer.setVolume(volume);
  }

  @override
  Future<void> dispose() async {
    await _alarmPlayer.dispose();
    await _musicPlayer.dispose();
  }
}
