import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../services/countdown_engine.dart';
import '../services/timer_audio_gateway.dart';
import '../services/timer_session_store.dart';
import '../utils/notification_service.dart';
import 'settings_provider.dart';
import 'stats_provider.dart';

enum TimerMode { work, shortBreak, longBreak }

typedef PeriodicTimerFactory = Timer Function(
  Duration duration,
  void Function(Timer timer) callback,
);
typedef TimerTextResolver = String Function(String key);
typedef SessionRecorder = Future<void> Function(
  String sessionId,
  int minutes,
);

class TimerRunConfiguration {
  final String notificationSound;
  final bool isBackgroundMusicEnabled;
  final double backgroundVolume;
  final Future<String?> Function()? resolveMusicFilePath;
  final SessionRecorder recordSession;

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
  final TimerSessionStore _sessionStore;
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
  String? _activeSessionId;
  Future<bool>? _restoreFuture;
  Future<void>? _recordingCompletion;

  TimerProvider({
    CountdownEngine? countdown,
    TimerNotificationGateway? notifications,
    TimerAudioGateway? audio,
    TimerSessionStore? sessionStore,
    PeriodicTimerFactory? periodicTimerFactory,
    TimerTextResolver? textResolver,
    bool observeLifecycle = true,
  })  : _countdown =
            countdown ?? CountdownEngine(initialSeconds: defaultWorkTime * 60),
        _notifications = notifications ?? NotificationService(),
        _audio = audio ?? AudioPlayersTimerAudioGateway(),
        _sessionStore = sessionStore ?? SharedPreferencesTimerSessionStore(),
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
  bool get hasActiveProgress =>
      _countdown.isRunning ||
      (!_isAlarmPlaying &&
          _countdown.remainingSeconds > 0 &&
          _countdown.remainingSeconds < _selectedTimeInMinutes * 60);

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

  Future<void> startTimer(SettingsProvider settings, StatsProvider stats) {
    return startCountdown(_configurationFor(settings, stats));
  }

  TimerRunConfiguration _configurationFor(
    SettingsProvider settings,
    StatsProvider stats,
  ) {
    return TimerRunConfiguration(
      notificationSound: settings.notificationSound,
      isBackgroundMusicEnabled: settings.isBackgroundMusicEnabled,
      backgroundVolume: settings.backgroundVolume,
      resolveMusicFilePath: () {
        return settings.getMusicFilePath(settings.backgroundMusic);
      },
      recordSession: (sessionId, minutes) => stats.addSession(
        minutes,
        sessionId: sessionId,
      ),
    );
  }

  Future<bool> restoreSession(
    SettingsProvider settings,
    StatsProvider stats,
  ) {
    return restoreCountdown(_configurationFor(settings, stats));
  }

  Future<bool> restoreCountdown(TimerRunConfiguration configuration) {
    return _restoreFuture ??= _restoreCountdown(configuration);
  }

  Future<bool> _restoreCountdown(TimerRunConfiguration configuration) async {
    final persisted = await _sessionStore.load();
    if (persisted == null) return false;

    TimerMode? mode;
    for (final candidate in TimerMode.values) {
      if (candidate.name == persisted.mode) {
        mode = candidate;
        break;
      }
    }
    final isValid = mode != null &&
        persisted.durationMinutes > 0 &&
        persisted.remainingSeconds >= 0 &&
        (!persisted.isRunning || persisted.deadlineUtc != null);
    if (!isValid) {
      await _sessionStore.clear(expectedSessionId: persisted.id);
      return false;
    }

    _activeRunConfiguration = configuration;
    _activeSessionId = persisted.id;
    _selectedTimeInMinutes = persisted.durationMinutes;
    _currentMode = mode;
    _completionHandled = false;
    _isAlarmPlaying = false;
    _currentMotivation = 'start_message';

    if (persisted.isRunning) {
      _countdown.restore(
        remainingSeconds: max(1, persisted.remainingSeconds),
        deadline: persisted.deadlineUtc!.toLocal(),
      );
      _cancelScheduledNotification();
      final update = _countdown.update();
      if (update == CountdownUpdate.completed) {
        _completeTimer(completedInBackground: true);
        await _recordingCompletion;
      } else {
        _startPeriodicTimer();
        _startBackgroundMusic(configuration);
        _notifyListeners();
      }
    } else {
      _countdown.restore(remainingSeconds: persisted.remainingSeconds);
      _notifyListeners();
    }

    return true;
  }

  Future<void> startCountdown(TimerRunConfiguration configuration) async {
    if (_countdown.isRunning) return;

    if (_isAlarmPlaying) {
      _runSafely(_audio.stopAlarm(), 'Alarm stop');
      _isAlarmPlaying = false;
      await resetTimer();
      return;
    }

    _activeRunConfiguration = configuration;
    _completionHandled = false;
    if (!_countdown.start()) return;

    _activeSessionId ??= _newSessionId();
    await _persistActiveSession();
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
      final sessionId = _activeSessionId;
      if (_selectedTimeInMinutes > 0 &&
          configuration != null &&
          sessionId != null) {
        _recordingCompletion = _recordCompletedWork(
          configuration,
          sessionId,
        );
      }
    } else {
      final sessionId = _activeSessionId;
      _activeSessionId = null;
      if (sessionId != null) {
        _recordingCompletion =
            _sessionStore.clear(expectedSessionId: sessionId);
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

  Future<void> _recordCompletedWork(
    TimerRunConfiguration configuration,
    String sessionId,
  ) async {
    try {
      await configuration.recordSession(sessionId, _selectedTimeInMinutes);
      await _sessionStore.clear(expectedSessionId: sessionId);
      if (_activeSessionId == sessionId) _activeSessionId = null;
    } catch (error, stackTrace) {
      debugPrint('Session record error: $error\n$stackTrace');
    }
  }

  Future<void> _persistActiveSession() async {
    final sessionId = _activeSessionId;
    if (sessionId == null) return;
    await _sessionStore.save(
      PersistedTimerSession(
        id: sessionId,
        mode: _currentMode.name,
        durationMinutes: _selectedTimeInMinutes,
        remainingSeconds: _countdown.remainingSeconds,
        isRunning: _countdown.isRunning,
        deadlineUtc: _countdown.deadline?.toUtc(),
      ),
    );
  }

  String _newSessionId() {
    return '${DateTime.now().microsecondsSinceEpoch}-'
        '${Random.secure().nextInt(1 << 32).toRadixString(16)}';
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

  Future<void> stopAlarm({
    required int workTime,
    required int shortBreakTime,
    required int longBreakTime,
  }) async {
    await _recordingCompletion;
    _runSafely(_audio.stopAlarm(), 'Alarm stop');
    _runSafely(_audio.stopMusic(), 'Music stop');
    _isAlarmPlaying = false;

    if (_currentMode == TimerMode.work) {
      if (_completedRounds % 4 == 0 && _completedRounds != 0) {
        await setTime(longBreakTime, TimerMode.longBreak);
      } else {
        await setTime(shortBreakTime, TimerMode.shortBreak);
      }
    } else {
      await setTime(workTime, TimerMode.work);
    }
  }

  Future<void> stopTimer({bool reset = true}) async {
    _stopActivePlayback();
    await _persistActiveSession();
    _notifyListeners();
  }

  void _stopActivePlayback() {
    _countdown.pause();
    _timer?.cancel();
    _timer = null;
    _cancelScheduledNotification();
    _runSafely(_audio.stopAlarm(), 'Alarm stop');
    _runSafely(_audio.stopMusic(), 'Music stop');
    _isAlarmPlaying = false;
  }

  Future<void> resetTimer() async {
    await _recordingCompletion;
    _stopActivePlayback();
    _countdown.reset(_selectedTimeInMinutes * 60);
    _currentMotivation = 'ready';
    _isAlarmPlaying = false;
    _completionHandled = false;
    final sessionId = _activeSessionId;
    _activeSessionId = null;
    if (sessionId != null) {
      await _sessionStore.clear(expectedSessionId: sessionId);
    }
    _notifyListeners();
  }

  /// Discards the current timer when the effective app identity changes.
  /// A timer must never continue from a signed-in account into guest mode or
  /// another account, and an old persisted session must not be restored later.
  Future<void> clearForIdentityChange({required int workTime}) async {
    await _restoreFuture;
    await _recordingCompletion;
    _stopActivePlayback();
    _selectedTimeInMinutes = workTime;
    _countdown.reset(workTime * 60);
    _currentMode = TimerMode.work;
    _currentMotivation = 'ready';
    _isAlarmPlaying = false;
    _completionHandled = false;
    _completedRounds = 0;
    _activeRunConfiguration = null;
    final sessionId = _activeSessionId;
    _activeSessionId = null;
    await _sessionStore.clear(expectedSessionId: sessionId);
    _notifyListeners();
  }

  Future<void> setTime(int minutes, TimerMode mode) async {
    await _recordingCompletion;
    _stopActivePlayback();
    _selectedTimeInMinutes = minutes;
    _countdown.reset(minutes * 60);
    _currentMode = mode;
    _changeQuote();
    _isAlarmPlaying = false;
    _completionHandled = false;
    final sessionId = _activeSessionId;
    _activeSessionId = null;
    if (sessionId != null) {
      await _sessionStore.clear(expectedSessionId: sessionId);
    }
    _notifyListeners();
  }

  void updateDurationFromSettings(int newMinutes, TimerMode mode) {
    if (_countdown.isRunning) return;
    if (_currentMode == mode) {
      _selectedTimeInMinutes = newMinutes;
      _countdown.reset(newMinutes * 60);
      _completionHandled = false;
      final sessionId = _activeSessionId;
      _activeSessionId = null;
      if (sessionId != null) {
        unawaited(_sessionStore.clear(expectedSessionId: sessionId));
      }
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
