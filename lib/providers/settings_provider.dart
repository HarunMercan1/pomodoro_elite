import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  final AudioPlayer _previewPlayer = AudioPlayer();

  // --- AYARLAR ---
  bool _isDarkMode = true;

  // Varsayılan: Artık olmayan 'digital.mp3' yerine 'zil1.mp3' yaptık
  String _notificationSound = 'zil1.mp3';

  bool _isBackgroundMusicEnabled = false;
  String _backgroundMusic = 'rain1.mp3';
  double _backgroundVolume = 0.5;

  int _workTime = 25;
  int _shortBreakTime = 5;
  int _longBreakTime = 15;

  // Getterlar
  bool get isDarkMode => _isDarkMode;
  String get notificationSound => _notificationSound;
  bool get isBackgroundMusicEnabled => _isBackgroundMusicEnabled;
  String get backgroundMusic => _backgroundMusic;
  double get backgroundVolume => _backgroundVolume;

  int get workTime => _workTime;
  int get shortBreakTime => _shortBreakTime;
  int get longBreakTime => _longBreakTime;

  // --- 1. BİLDİRİM SESLERİ (TEMİZLENDİ) ---
  // Sadece klasörde olan zil1-zil5 arası kaldı.
  final Map<String, String> notificationSounds = {
    'zil1.mp3': 'sound_zil1',
    'zil2.mp3': 'sound_zil2',
    'zil3.mp3': 'sound_zil3',
    'zil4.mp3': 'sound_zil4',
    'zil5.mp3': 'sound_zil5',
  };

  // --- 2. ARKA PLAN MÜZİKLERİ (TAKAS YAPILDI) ---
  final Map<String, String> backgroundMusics = {
    'rain1.mp3': 'sound_rain2', // rain1.mp3 artık "Orman Yağmuru" oldu
    'rain2.mp3': 'sound_rain1', // rain2.mp3 artık "Çiseleyen Yağmur" oldu
    'rain3.mp3': 'sound_rain3',
    'thunder.mp3': 'sound_thunder',
    'wind.mp3': 'sound_wind',
    'forest.mp3': 'sound_forest',
    'ocean.mp3': 'sound_ocean',
  };

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool('isDarkMode') ?? true;

    // Eğer hafızada kalan eski bir dosya varsa (örn: digital.mp3), varsayılan 'zil1.mp3'e dön
    String loadedNotif = _prefs.getString('notificationSound') ?? 'zil1.mp3';
    _notificationSound = notificationSounds.containsKey(loadedNotif) ? loadedNotif : 'zil1.mp3';

    _isBackgroundMusicEnabled = _prefs.getBool('isBackgroundMusicEnabled') ?? false;

    String loadedMusic = _prefs.getString('backgroundMusic') ?? 'rain1.mp3';
    _backgroundMusic = backgroundMusics.containsKey(loadedMusic) ? loadedMusic : 'rain1.mp3';

    _backgroundVolume = _prefs.getDouble('backgroundVolume') ?? 0.5;
    _workTime = _prefs.getInt('workTime') ?? 25;
    _shortBreakTime = _prefs.getInt('shortBreakTime') ?? 5;
    _longBreakTime = _prefs.getInt('longBreakTime') ?? 15;
    notifyListeners();
  }

  void toggleTheme(bool value) {
    _isDarkMode = value;
    _prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  // --- BİLDİRİM SESİ SEÇME ---
  Future<void> setNotificationSound(String soundPath) async {
    _notificationSound = soundPath;
    _prefs.setString('notificationSound', soundPath);
    notifyListeners();

    debugPrint("🔔 Zil Deneniyor: sounds/bell/$soundPath");

    try {
      await _previewPlayer.stop();
      await _previewPlayer.setReleaseMode(ReleaseMode.stop);
      await _previewPlayer.play(
        AssetSource('sounds/bell/$soundPath'),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint("❌ Zil Hatası: $e");
    }
  }

  // --- MÜZİK SEÇME ---
  Future<void> setBackgroundMusic(String soundPath) async {
    _backgroundMusic = soundPath;
    _prefs.setString('backgroundMusic', soundPath);
    notifyListeners();

    if (_isBackgroundMusicEnabled) {
      try {
        await _previewPlayer.stop();
        await _previewPlayer.setSource(AssetSource('sounds/music/$soundPath'));
        await _previewPlayer.setVolume(_backgroundVolume);
        await _previewPlayer.setReleaseMode(ReleaseMode.loop);
        await _previewPlayer.resume();
      } catch (e) {
        debugPrint("❌ Müzik Hatası: $e");
      }
    }
  }

  void setVolumeLive(double volume) {
    _backgroundVolume = volume;
    if (_previewPlayer.state == PlayerState.playing) {
      _previewPlayer.setVolume(volume);
    }
  }

  void saveVolumeToPrefs() {
    _prefs.setDouble('backgroundVolume', _backgroundVolume);
    notifyListeners();
  }

  void toggleBackgroundMusic(bool value) async {
    _isBackgroundMusicEnabled = value;
    _prefs.setBool('isBackgroundMusicEnabled', value);
    notifyListeners();
    if (!value) {
      await _previewPlayer.stop();
    } else {
      setBackgroundMusic(_backgroundMusic);
    }
  }

  Future<void> stopPreview() async {
    await _previewPlayer.stop();
  }

  void setWorkTime(int minutes) { _workTime = minutes; _prefs.setInt('workTime', minutes); notifyListeners(); }
  void setShortBreakTime(int minutes) { _shortBreakTime = minutes; _prefs.setInt('shortBreakTime', minutes); notifyListeners(); }
  void setLongBreakTime(int minutes) { _longBreakTime = minutes; _prefs.setInt('longBreakTime', minutes); notifyListeners(); }
}