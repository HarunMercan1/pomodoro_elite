import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import '../utils/notification_service.dart';
import 'settings_provider.dart';
import 'stats_provider.dart';

enum TimerMode { work, shortBreak, longBreak }

class TimerProvider with ChangeNotifier, WidgetsBindingObserver {
  static const int defaultWorkTime = 25;

  int _remainingSeconds = defaultWorkTime * 60;
  int _selectedTimeInMinutes = defaultWorkTime;
  TimerMode _currentMode = TimerMode.work;
  String _currentMotivation = "start_message";
  DateTime? _backgroundExitTime; // Arkaplana giriş zamanı

  Timer? _timer;
  bool _isRunning = false;
  bool _isAlarmPlaying = false;
  int _completedRounds = 0;

  final AudioPlayer _alarmPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  // Arka plan tamamlanma mantığı için provider referansları
  SettingsProvider? _lastSettings;
  StatsProvider? _lastStats;

  TimerProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _alarmPlayer.dispose();
    _musicPlayer.dispose();
    super.dispose();
  }

  // --- LIFECYCLE (ARKAPLAN) YÖNETİMİ ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Uygulama arka plana geçiyor
      if (_isRunning) {
        _backgroundExitTime = DateTime.now();
        debugPrint("⏸️ Uygulama arka plana geçti, sayaç çalışıyor.");
      }
    } else if (state == AppLifecycleState.resumed) {
      // Uygulama ön plana döndü
      if (_isRunning && _backgroundExitTime != null) {
        final timePassed =
            DateTime.now().difference(_backgroundExitTime!).inSeconds;
        _backgroundExitTime = null;

        if (timePassed > 0) {
          _remainingSeconds -= timePassed;
          debugPrint("⏳ Arkaplanda geçen süre: $timePassed sn, Kalan: $_remainingSeconds sn");

          if (_remainingSeconds <= 0) {
            _remainingSeconds = 0;

            // --- SÜRE ARKAPLANDA BİTTİ: TAM TAMAMLANMA MANTIĞI ---
            _timer?.cancel();
            _timer = null;

            // Zamanlanmış bildirimi iptal et (zaten gelmiş olmalı)
            NotificationService().cancelScheduledNotification();

            _handleTimerCompletion();
          } else {
            // Süre hâlâ devam ediyor — Timer.periodic'i yeniden kontrol et
            _ensureTimerRunning();

            // Zamanlanmış bildirimi güncelle (kalan süreye göre)
            _scheduleEndNotification();
          }
        }
      }

      // Uygulama ön plana döndü, zamanlanmış bildirimi iptal et
      // (artık uygulama açık, anlık bildirim yeterli)
      if (!_isRunning || _remainingSeconds <= 0) {
        NotificationService().cancelScheduledNotification();
      }
    }
  }

  /// Timer.periodic'in çalıştığını doğrular, çalışmıyorsa yeniden başlatır.
  void _ensureTimerRunning() {
    if (_timer == null || !_timer!.isActive) {
      debugPrint("🔄 Timer.periodic yeniden başlatılıyor...");
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          notifyListeners();
        } else {
          timer.cancel();
          _timer = null;
          NotificationService().cancelScheduledNotification();
          _handleTimerCompletion();
        }
      });
    }
  }

  /// Timer tamamlandığında çalışan ortak mantık.
  /// Hem ön plan (Timer.periodic) hem arka plan (resume) tarafından çağrılır.
  void _handleTimerCompletion() {
    _isRunning = false;
    _isAlarmPlaying = true;
    _currentMotivation = "congrats";

    _musicPlayer.stop();

    // --- BİLDİRİM METNİNİ AYARLA ---
    String notifTitle = "";
    String notifBody = "";

    if (_currentMode == TimerMode.work) {
      // İŞ BİTTİ
      _completedRounds++;
      if (_selectedTimeInMinutes > 0 && _lastStats != null) {
        _lastStats!.addSession(_selectedTimeInMinutes);
      }
      notifTitle = "work_completed_title".tr();
      notifBody = "work_completed_msg".tr();
    } else {
      // MOLA BİTTİ
      notifTitle = "break_over_title".tr();
      notifBody = "break_over_msg".tr();
    }

    // Bildirimi Gönder (Anlık)
    NotificationService().showNotification(
      title: notifTitle,
      body: notifBody,
    );

    // Alarmı Çal
    _playAlarm();

    notifyListeners();
  }

  /// Alarm sesini çalar
  Future<void> _playAlarm() async {
    try {
      final soundFile = _lastSettings?.notificationSound ?? 'zil1.mp3';
      await _alarmPlayer.stop();
      await _alarmPlayer.setSource(
          AssetSource('sounds/bell/$soundFile'));
      await _alarmPlayer.setVolume(1.0);
      await _alarmPlayer.setReleaseMode(ReleaseMode.stop);
      await _alarmPlayer.resume();
    } catch (e) {
      debugPrint("❌ Alarm Hatası: $e");
    }
  }

  /// Kalan süreye göre bitiş bildirimi planlar
  void _scheduleEndNotification() {
    if (_remainingSeconds <= 0) return;

    String title;
    String body;

    if (_currentMode == TimerMode.work) {
      title = "work_completed_title".tr();
      body = "work_completed_msg".tr();
    } else {
      title = "break_over_title".tr();
      body = "break_over_msg".tr();
    }

    NotificationService().scheduleTimerEndNotification(
      seconds: _remainingSeconds,
      title: title,
      body: body,
    );
  }

  // Getterlar
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  String get currentMotivation => _currentMotivation;
  int get currentDuration => _selectedTimeInMinutes;
  TimerMode get currentMode => _currentMode;
  bool get isAlarmPlaying => _isAlarmPlaying;
  int get completedRounds => _completedRounds;

  double get progress {
    if (_selectedTimeInMinutes == 0) return 0;
    int totalSeconds = _selectedTimeInMinutes * 60;
    return 1 - (_remainingSeconds / totalSeconds);
  }

  String get timeLeftString {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  final List<String> _quotes =
      List.generate(100, (index) => "quote_${index + 1}");

  void _changeQuote() {
    _currentMotivation = _quotes[Random().nextInt(_quotes.length)];
  }

  // --- START TIMER ---
  void startTimer(SettingsProvider settings, StatsProvider stats) async {
    // Eğer zaten bir sayaç varsa yenisini başlatma
    if (_timer != null) return;

    if (_isAlarmPlaying) {
      _alarmPlayer.stop();
      _isAlarmPlaying = false;
      resetTimer();
      notifyListeners();
      return;
    }

    // Provider referanslarını sakla (arka plan tamamlanma için)
    _lastSettings = settings;
    _lastStats = stats;

    _isRunning = true;
    _changeQuote();
    notifyListeners();

    // MÜZİK BAŞLAT
    if (settings.isBackgroundMusicEnabled) {
      try {
        final musicPath =
            await settings.getMusicFilePath(settings.backgroundMusic);
        if (musicPath != null) {
          await _musicPlayer.setSource(DeviceFileSource(musicPath));
          await _musicPlayer.setVolume(settings.backgroundVolume);
          await _musicPlayer.setReleaseMode(ReleaseMode.loop);
          await _musicPlayer.resume();
        } else {
          debugPrint(
              "⚠️ Müzik dosyası bulunamadı: ${settings.backgroundMusic}");
        }
      } catch (e) {
        debugPrint("❌ Müzik Çalma Hatası: $e");
      }
    }

    // 📅 BİTİŞ BİLDİRİMİ PLANLA (arka planda bile çalışır)
    _scheduleEndNotification();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        // --- SÜRE BİTTİ (ÖN PLAN) ---
        timer.cancel();
        _timer = null;

        // Zamanlanmış bildirimi iptal et (ön planda tamamlandı)
        NotificationService().cancelScheduledNotification();

        _handleTimerCompletion();
      }
    });
  }

  void stopAlarm(
      {required int workTime,
      required int shortBreakTime,
      required int longBreakTime}) {
    _alarmPlayer.stop();
    _musicPlayer.stop();
    _isAlarmPlaying = false;

    if (_currentMode == TimerMode.work) {
      if (_completedRounds % 4 == 0 && _completedRounds != 0) {
        setTime(longBreakTime, TimerMode.longBreak);
      } else {
        setTime(shortBreakTime, TimerMode.shortBreak);
      }
    } else {
      setTime(workTime, TimerMode.work);
    }
    notifyListeners();
  }

  void stopTimer({bool reset = true}) {
    _timer?.cancel();
    _timer = null;
    _alarmPlayer.stop();
    _musicPlayer.stop();
    _isRunning = false;
    _isAlarmPlaying = false;

    // 🚫 Zamanlanmış bildirimi iptal et
    NotificationService().cancelScheduledNotification();

    notifyListeners();
  }

  void resetTimer() {
    stopTimer();
    _remainingSeconds = _selectedTimeInMinutes * 60;
    _currentMotivation = "ready";
    _isAlarmPlaying = false;
    notifyListeners();
  }

  void setTime(int minutes, TimerMode mode) {
    stopTimer();
    _selectedTimeInMinutes = minutes;
    _remainingSeconds = minutes * 60;
    _currentMode = mode;
    _changeQuote();
    _isAlarmPlaying = false;
    notifyListeners();
  }

  void updateDurationFromSettings(int newMinutes, TimerMode mode) {
    if (_isRunning) return;
    if (_currentMode == mode) {
      _selectedTimeInMinutes = newMinutes;
      _remainingSeconds = newMinutes * 60;
      notifyListeners();
    }
  }

  void updateMusicVolume(double volume) {
    if (_isRunning) {
      _musicPlayer.setVolume(volume);
    }
  }
}
