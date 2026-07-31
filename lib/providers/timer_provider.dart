import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../services/countdown_engine.dart';
import '../services/timer_audio_gateway.dart';
import '../utils/notification_service.dart';
import 'settings_provider.dart';
import 'stats_provider.dart';

enum TimerMode { work, shortBreak, longBreak }

typedef PeriodicTimerFactory = Timer Function(
  Duration duration,
  void Function(Timer timer) callback,
);
typedef TimerTextResolver = String Function(String key);

class TimerRunConfiguration {
  final String notificationSound;
  final bool isBackgroundMusicEnabled;
  final double backgroundVolume;
  final Future<String?> Function()? resolveMusicFilePath;
  final Future<void> Function(int minutes) recordSession;

  const TimerRunConfiguration({
    required this.notificationSound,
    required this.isBackgroundMusicEnabled,
    required this.backgroundVolume,
    required this.recordSession,
    this.resolveMusicFilePath,
  });
}

class TimerProvider with ChangeNotifier, WidgetsBindingObserver {
  static const int defaultWorkTime = 25;

  final CountdownEngine _countdown;
  final TimerNotificationGateway _notifications;
  final TimerAudioGateway _audio;
  final PeriodicTimerFactory _periodicTimerFactory;
  final TimerTextResolver _resolveText;
  final bool _observeLifecycle;

  int _selectedTimeInMinutes = defaultWorkTime;
  TimerMode _currentMode = TimerMode.work;
  String _currentMotivation = 'start_message';
  Timer? _timer;
  TimerRunConfiguration? _activeRunConfiguration;
  bool _isAlarmPlaying = false;
  bool _completionHandled = false;
  bool _isInBackground = false;
  bool _hasScheduledNotification = false;
  bool _isDisposed = false;
  int _notificationGeneration = 0;
  int _completedRounds = 0;

  TimerProvider({
    CountdownEngine? countdown,
    TimerNotificationGateway? notifications,
    TimerAudioGateway? audio,
    PeriodicTimerFactory? periodicTimerFactory,
    TimerTextResolver? textResolver,
    bool observeLifecycle = true,
  })  : _countdown =
            countdown ?? CountdownEngine(initialSeconds: defaultWorkTime * 60),
        _notifications = notifications ?? NotificationService(),
        _audio = audio ?? AudioPlayersTimerAudioGateway(),
        _periodicTimerFactory = periodicTimerFactory ?? Timer.periodic,
        _resolveText = textResolver ?? ((key) => key.tr()),
        _observeLifecycle = observeLifecycle {
    if (_observeLifecycle) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_observeLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _timer?.cancel();
    _cancelScheduledNotification();
    _runSafely(_audio.dispose(), 'Audio dispose');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _isInBackground = true;
      if (!_countdown.isRunning) return;

      _timer?.cancel();
      _timer = null;
      final update = _countdown.update();
      if (update == CountdownUpdate.completed) {
        _completeTimer(completedInBackground: false);
      } else {
        _scheduleBackgroundNotification();
        _notifyListeners();
      }
      return;
    }

    if (state == AppLifecycleState.resumed) {
      final notificationWasScheduled = _hasScheduledNotification;
      _isInBackground = false;
      _cancelScheduledNotification();

      if (!_countdown.isRunning) return;

      final update = _countdown.update();
      if (update == CountdownUpdate.completed) {
        _completeTimer(
          completedInBackground: notificationWasScheduled,
        );
      } else {
        _startPeriodicTimer();
        _notifyListeners();
      }
    }
  }

  int get remainingSeconds => _countdown.remainingSeconds;
  bool get isRunning => _countdown.isRunning;
  String get currentMotivation => _currentMotivation;
  int get currentDuration => _selectedTimeInMinutes;
  TimerMode get currentMode => _currentMode;
  bool get isAlarmPlaying => _isAlarmPlaying;
  int get completedRounds => _completedRounds;

  double get progress {
    if (_selectedTimeInMinutes == 0) return 0;
    final totalSeconds = _selectedTimeInMinutes * 60;
    return 1 - (_countdown.remainingSeconds / totalSeconds);
  }

  String get timeLeftString {
    final minutes = _countdown.remainingSeconds ~/ 60;
    final seconds = _countdown.remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  final List<String> _quotes = List.generate(
    100,
    (index) => 'quote_${index + 1}',
  );

  void _changeQuote() {
    _currentMotivation = _quotes[Random().nextInt(_quotes.length)];
  }

  void startTimer(SettingsProvider settings, StatsProvider stats) {
    startCountdown(
      TimerRunConfiguration(
        notificationSound: settings.notificationSound,
        isBackgroundMusicEnabled: settings.isBackgroundMusicEnabled,
        backgroundVolume: settings.backgroundVolume,
        resolveMusicFilePath: () {
          return settings.getMusicFilePath(settings.backgroundMusic);
        },
        recordSession: stats.addSession,
      ),
    );
  }

  void startCountdown(TimerRunConfiguration configuration) {
    if (_countdown.isRunning) return;

    if (_isAlarmPlaying) {
      _runSafely(_audio.stopAlarm(), 'Alarm stop');
      _isAlarmPlaying = false;
      resetTimer();
      return;
    }

    _activeRunConfiguration = configuration;
    _completionHandled = false;
    if (!_countdown.start()) return;

    _changeQuote();
    _startPeriodicTimer();
    _startBackgroundMusic(configuration);
    _notifyListeners();
  }

  void _startPeriodicTimer() {
    if (_isInBackground || !_countdown.isRunning) return;

    _timer?.cancel();
    _timer = _periodicTimerFactory(
      const Duration(seconds: 1),
      _handleTimerTick,
    );
  }

  void _handleTimerTick(Timer timer) {
    final update = _countdown.update();
    if (update == CountdownUpdate.completed) {
      timer.cancel();
      _timer = null;
      _completeTimer(completedInBackground: false);
    } else if (update == CountdownUpdate.updated) {
      _notifyListeners();
    }
  }

  void _completeTimer({required bool completedInBackground}) {
    if (_completionHandled) return;
    _completionHandled = true;

    _timer?.cancel();
    _timer = null;
    _cancelScheduledNotification();
    _isAlarmPlaying = true;
    _currentMotivation = 'congrats';
    _runSafely(_audio.stopMusic(), 'Music stop');

    if (_currentMode == TimerMode.work) {
      _completedRounds++;
      final configuration = _activeRunConfiguration;
      if (_selectedTimeInMinutes > 0 && configuration != null) {
        _runSafely(
          configuration.recordSession(_selectedTimeInMinutes),
          'Session record',
        );
      }
    }

    // Arka planda planlanan bildirim sesi zaten kullanıcıyı uyardı. Uygulama
    // açıkken ise yalnızca uygulama içi alarm çalar; ikinci sistem bildirimi yok.
    if (!completedInBackground) {
      final soundFile =
          _activeRunConfiguration?.notificationSound ?? 'zil1.mp3';
      unawaited(_playAlarm(soundFile));
    }

    _notifyListeners();
  }

  Future<void> _playAlarm(String soundFile) async {
    try {
      await _audio.playAlarm(soundFile);
    } catch (error, stackTrace) {
      debugPrint('Alarm hatası: $error\n$stackTrace');
    }
  }

  void _startBackgroundMusic(TimerRunConfiguration configuration) {
    if (!configuration.isBackgroundMusicEnabled ||
        configuration.resolveMusicFilePath == null) {
      return;
    }

    unawaited(() async {
      try {
        final musicPath = await configuration.resolveMusicFilePath!();
        if (musicPath == null || !_countdown.isRunning || _isDisposed) return;
        await _audio.playMusic(musicPath, configuration.backgroundVolume);
      } catch (error, stackTrace) {
        debugPrint('Müzik çalma hatası: $error\n$stackTrace');
      }
    }());
  }

  void _scheduleBackgroundNotification() {
    if (_countdown.remainingSeconds <= 0) return;

    final generation = ++_notificationGeneration;
    final titleKey = _currentMode == TimerMode.work
        ? 'work_completed_title'
        : 'break_over_title';
    final bodyKey = _currentMode == TimerMode.work
        ? 'work_completed_msg'
        : 'break_over_msg';

    unawaited(() async {
      final scheduled = await _notifications.scheduleTimerEndNotification(
        seconds: _countdown.remainingSeconds,
        title: _resolveText(titleKey),
        body: _resolveText(bodyKey),
      );

      if (_isDisposed || generation != _notificationGeneration) {
        if (scheduled) {
          await _notifications.cancelScheduledNotification();
        }
        return;
      }

      _hasScheduledNotification = scheduled;
    }());
  }

  void _cancelScheduledNotification() {
    _notificationGeneration++;
    _hasScheduledNotification = false;
    unawaited(_notifications.cancelScheduledNotification());
  }

  void stopAlarm({
    required int workTime,
    required int shortBreakTime,
    required int longBreakTime,
  }) {
    _runSafely(_audio.stopAlarm(), 'Alarm stop');
    _runSafely(_audio.stopMusic(), 'Music stop');
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
    _notifyListeners();
  }

  void stopTimer({bool reset = true}) {
    _countdown.pause();
    _timer?.cancel();
    _timer = null;
    _cancelScheduledNotification();
    _runSafely(_audio.stopAlarm(), 'Alarm stop');
    _runSafely(_audio.stopMusic(), 'Music stop');
    _isAlarmPlaying = false;
    _notifyListeners();
  }

  void resetTimer() {
    stopTimer();
    _countdown.reset(_selectedTimeInMinutes * 60);
    _currentMotivation = 'ready';
    _isAlarmPlaying = false;
    _completionHandled = false;
    _notifyListeners();
  }

  void setTime(int minutes, TimerMode mode) {
    stopTimer();
    _selectedTimeInMinutes = minutes;
    _countdown.reset(minutes * 60);
    _currentMode = mode;
    _changeQuote();
    _isAlarmPlaying = false;
    _completionHandled = false;
    _notifyListeners();
  }

  void updateDurationFromSettings(int newMinutes, TimerMode mode) {
    if (_countdown.isRunning) return;
    if (_currentMode == mode) {
      _selectedTimeInMinutes = newMinutes;
      _countdown.reset(newMinutes * 60);
      _completionHandled = false;
      _notifyListeners();
    }
  }

  void updateMusicVolume(double volume) {
    if (_countdown.isRunning) {
      _runSafely(_audio.setMusicVolume(volume), 'Music volume');
    }
  }

  void _runSafely(Future<void> operation, String operationName) {
    unawaited(
      operation.catchError((Object error, StackTrace stackTrace) {
        debugPrint('$operationName hatası: $error\n$stackTrace');
      }),
    );
  }

  void _notifyListeners() {
    if (!_isDisposed) notifyListeners();
  }
}
