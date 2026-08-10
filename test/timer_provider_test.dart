import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pomodoro_elite/providers/timer_provider.dart';
import 'package:pomodoro_elite/services/countdown_engine.dart';
import 'package:pomodoro_elite/services/timer_audio_gateway.dart';
import 'package:pomodoro_elite/services/timer_session_store.dart';
import 'package:pomodoro_elite/utils/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CountdownEngine', () {
    test('completes exactly when the displayed value reaches zero', () {
      var now = DateTime(2026, 7, 31, 12);
      final engine = CountdownEngine(
        initialSeconds: 2,
        now: () => now,
      );

      expect(engine.start(), isTrue);

      now = now.add(const Duration(seconds: 1));
      expect(engine.update(), CountdownUpdate.updated);
      expect(engine.remainingSeconds, 1);

      now = now.add(const Duration(seconds: 1));
      expect(engine.update(), CountdownUpdate.completed);
      expect(engine.remainingSeconds, 0);
      expect(engine.isRunning, isFalse);

      expect(engine.update(), CountdownUpdate.unchanged);
    });

    test('derives remaining time from one absolute deadline', () {
      var now = DateTime(2026, 7, 31, 12);
      final engine = CountdownEngine(
        initialSeconds: 10,
        now: () => now,
      )..start();

      now = now.add(const Duration(milliseconds: 4200));
      expect(engine.update(), CountdownUpdate.updated);
      expect(engine.remainingSeconds, 6);

      // Calling update again at the same instant cannot subtract time twice.
      expect(engine.update(), CountdownUpdate.unchanged);
      expect(engine.remainingSeconds, 6);
    });

    test('pause preserves time and resume creates a new deadline', () {
      var now = DateTime(2026, 7, 31, 12);
      final engine = CountdownEngine(
        initialSeconds: 10,
        now: () => now,
      )..start();

      now = now.add(const Duration(seconds: 3));
      engine.pause();
      expect(engine.remainingSeconds, 7);

      now = now.add(const Duration(minutes: 1));
      expect(engine.update(), CountdownUpdate.unchanged);
      expect(engine.remainingSeconds, 7);

      expect(engine.start(), isTrue);
      now = now.add(const Duration(seconds: 7));
      expect(engine.update(), CountdownUpdate.completed);
    });
  });

  group('TimerProvider lifecycle policy', () {
    test('foreground completion records and alarms exactly once', () async {
      var now = DateTime(2026, 7, 31, 12);
      final timers = _ManualTimerFactory();
      final notifications = _FakeTimerNotifications();
      final audio = _FakeTimerAudio();
      final recordedMinutes = <int>[];
      final provider = TimerProvider(
        countdown: CountdownEngine(initialSeconds: 2, now: () => now),
        notifications: notifications,
        audio: audio,
        sessionStore: _MemoryTimerSessionStore(),
        periodicTimerFactory: timers.create,
        textResolver: (key) => key,
        observeLifecycle: false,
      );
      addTearDown(provider.dispose);

      await provider.startCountdown(
        _configuration(recordedMinutes),
      );

      expect(notifications.scheduleCalls, isEmpty);

      now = now.add(const Duration(seconds: 1));
      timers.latest.fire();
      expect(provider.remainingSeconds, 1);
      expect(provider.completedRounds, 0);

      now = now.add(const Duration(seconds: 1));
      timers.latest.fire();
      await Future<void>.delayed(Duration.zero);

      expect(provider.remainingSeconds, 0);
      expect(provider.completedRounds, 1);
      expect(recordedMinutes, [TimerProvider.defaultWorkTime]);
      expect(audio.alarmPlayCount, 1);

      provider.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(provider.completedRounds, 1);
      expect(audio.alarmPlayCount, 1);
    });

    test('background completion relies on one scheduled notification',
        () async {
      var now = DateTime(2026, 7, 31, 12);
      final timers = _ManualTimerFactory();
      final notifications = _FakeTimerNotifications();
      final audio = _FakeTimerAudio();
      final recordedMinutes = <int>[];
      final provider = TimerProvider(
        countdown: CountdownEngine(initialSeconds: 5, now: () => now),
        notifications: notifications,
        audio: audio,
        sessionStore: _MemoryTimerSessionStore(),
        periodicTimerFactory: timers.create,
        textResolver: (key) => key,
        observeLifecycle: false,
      );
      addTearDown(provider.dispose);

      await provider.startCountdown(_configuration(recordedMinutes));
      provider.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);

      expect(notifications.scheduleCalls, [5]);

      now = now.add(const Duration(seconds: 5));
      provider.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(provider.remainingSeconds, 0);
      expect(provider.completedRounds, 1);
      expect(recordedMinutes, [TimerProvider.defaultWorkTime]);
      expect(audio.alarmPlayCount, 0);
      expect(notifications.scheduleCalls, hasLength(1));
    });

    test('resume before deadline continues from the absolute remaining time',
        () async {
      var now = DateTime(2026, 7, 31, 12);
      final timers = _ManualTimerFactory();
      final notifications = _FakeTimerNotifications();
      final audio = _FakeTimerAudio();
      final provider = TimerProvider(
        countdown: CountdownEngine(initialSeconds: 5, now: () => now),
        notifications: notifications,
        audio: audio,
        sessionStore: _MemoryTimerSessionStore(),
        periodicTimerFactory: timers.create,
        textResolver: (key) => key,
        observeLifecycle: false,
      );
      addTearDown(provider.dispose);

      await provider.startCountdown(_configuration(<int>[]));
      provider.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);

      now = now.add(const Duration(seconds: 2));
      provider.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(provider.remainingSeconds, 3);
      expect(provider.isRunning, isTrue);
      expect(timers.created, hasLength(2));

      now = now.add(const Duration(seconds: 3));
      timers.latest.fire();
      await Future<void>.delayed(Duration.zero);

      expect(provider.completedRounds, 1);
      expect(audio.alarmPlayCount, 1);
      expect(notifications.scheduleCalls, hasLength(1));
    });
  });

  group('TimerProvider process death recovery', () {
    test('restores a running countdown from its absolute deadline', () async {
      var now = DateTime(2026, 8, 4, 12);
      final store = _MemoryTimerSessionStore();
      final firstProvider = TimerProvider(
        countdown: CountdownEngine(initialSeconds: 5, now: () => now),
        notifications: _FakeTimerNotifications(),
        audio: _FakeTimerAudio(),
        sessionStore: store,
        periodicTimerFactory: _ManualTimerFactory().create,
        textResolver: (key) => key,
        observeLifecycle: false,
      );

      await firstProvider.startCountdown(_configuration(<int>[]));
      firstProvider.dispose();
      now = now.add(const Duration(seconds: 2));

      final restoredTimers = _ManualTimerFactory();
      final restoredProvider = TimerProvider(
        countdown: CountdownEngine(initialSeconds: 1, now: () => now),
        notifications: _FakeTimerNotifications(),
        audio: _FakeTimerAudio(),
        sessionStore: store,
        periodicTimerFactory: restoredTimers.create,
        textResolver: (key) => key,
        observeLifecycle: false,
      );
      addTearDown(restoredProvider.dispose);

      expect(
        await restoredProvider.restoreCountdown(_configuration(<int>[])),
        isTrue,
      );
      expect(restoredProvider.isRunning, isTrue);
      expect(restoredProvider.remainingSeconds, 3);
      expect(restoredProvider.currentMode, TimerMode.work);
      expect(restoredTimers.created, hasLength(1));
    });

    test('records an elapsed restored session exactly once', () async {
      var now = DateTime(2026, 8, 4, 12);
      final store = _MemoryTimerSessionStore();
      final firstProvider = TimerProvider(
        countdown: CountdownEngine(initialSeconds: 5, now: () => now),
        notifications: _FakeTimerNotifications(),
        audio: _FakeTimerAudio(),
        sessionStore: store,
        periodicTimerFactory: _ManualTimerFactory().create,
        textResolver: (key) => key,
        observeLifecycle: false,
      );
      await firstProvider.startCountdown(_configuration(<int>[]));
      firstProvider.dispose();
      now = now.add(const Duration(seconds: 8));

      final recordedMinutes = <int>[];
      final restoredProvider = TimerProvider(
        countdown: CountdownEngine(initialSeconds: 1, now: () => now),
        notifications: _FakeTimerNotifications(),
        audio: _FakeTimerAudio(),
        sessionStore: store,
        periodicTimerFactory: _ManualTimerFactory().create,
        textResolver: (key) => key,
        observeLifecycle: false,
      );
      addTearDown(restoredProvider.dispose);

      expect(
        await restoredProvider.restoreCountdown(
          _configuration(recordedMinutes),
        ),
        isTrue,
      );
      expect(recordedMinutes, [TimerProvider.defaultWorkTime]);
      expect(await store.load(), isNull);

      final secondRestore = TimerProvider(
        countdown: CountdownEngine(initialSeconds: 1, now: () => now),
        notifications: _FakeTimerNotifications(),
        audio: _FakeTimerAudio(),
        sessionStore: store,
        observeLifecycle: false,
      );
      addTearDown(secondRestore.dispose);
      expect(
        await secondRestore.restoreCountdown(_configuration(recordedMinutes)),
        isFalse,
      );
      expect(recordedMinutes, [TimerProvider.defaultWorkTime]);
    });

    test('restores a paused countdown without consuming wall-clock time',
        () async {
      var now = DateTime(2026, 8, 4, 12);
      final store = _MemoryTimerSessionStore();
      final firstProvider = TimerProvider(
        countdown: CountdownEngine(initialSeconds: 5, now: () => now),
        notifications: _FakeTimerNotifications(),
        audio: _FakeTimerAudio(),
        sessionStore: store,
        periodicTimerFactory: _ManualTimerFactory().create,
        textResolver: (key) => key,
        observeLifecycle: false,
      );
      await firstProvider.startCountdown(_configuration(<int>[]));
      now = now.add(const Duration(seconds: 2));
      await firstProvider.stopTimer(reset: false);
      firstProvider.dispose();
      now = now.add(const Duration(hours: 1));

      final restoredProvider = TimerProvider(
        countdown: CountdownEngine(initialSeconds: 1, now: () => now),
        notifications: _FakeTimerNotifications(),
        audio: _FakeTimerAudio(),
        sessionStore: store,
        observeLifecycle: false,
      );
      addTearDown(restoredProvider.dispose);

      expect(
        await restoredProvider.restoreCountdown(_configuration(<int>[])),
        isTrue,
      );
      expect(restoredProvider.isRunning, isFalse);
      expect(restoredProvider.remainingSeconds, 3);
      expect(restoredProvider.hasActiveProgress, isTrue);
    });
  });

  group('TimerProvider atomic UI notifications', () {
    test('mode selection publishes only the completed state transition',
        () async {
      final provider = TimerProvider(
        notifications: _FakeTimerNotifications(),
        audio: _FakeTimerAudio(),
        sessionStore: _MemoryTimerSessionStore(),
        observeLifecycle: false,
      );
      addTearDown(provider.dispose);

      final snapshots = <(TimerMode, int, int, bool)>[];
      provider.addListener(() {
        snapshots.add((
          provider.currentMode,
          provider.currentDuration,
          provider.remainingSeconds,
          provider.isRunning,
        ));
      });

      await provider.setTime(5, TimerMode.shortBreak);

      expect(snapshots, [
        (TimerMode.shortBreak, 5, 5 * 60, false),
      ]);
    });

    test('reset publishes one coherent idle snapshot', () async {
      final provider = TimerProvider(
        notifications: _FakeTimerNotifications(),
        audio: _FakeTimerAudio(),
        sessionStore: _MemoryTimerSessionStore(),
        observeLifecycle: false,
      );
      addTearDown(provider.dispose);
      await provider.setTime(5, TimerMode.shortBreak);
      await provider.startCountdown(_configuration(<int>[]));

      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.resetTimer();

      expect(notifications, 1);
      expect(provider.currentMode, TimerMode.shortBreak);
      expect(provider.remainingSeconds, 5 * 60);
      expect(provider.isRunning, isFalse);
      expect(provider.currentMotivation, 'ready');
    });

    test('identity change discards the timer and its persisted session',
        () async {
      final store = _MemoryTimerSessionStore();
      final provider = TimerProvider(
        notifications: _FakeTimerNotifications(),
        audio: _FakeTimerAudio(),
        sessionStore: store,
        periodicTimerFactory: _ManualTimerFactory().create,
        observeLifecycle: false,
      );
      addTearDown(provider.dispose);
      await provider.setTime(5, TimerMode.shortBreak);
      await provider.startCountdown(_configuration(<int>[]));

      await provider.clearForIdentityChange(workTime: 30);

      expect(provider.currentMode, TimerMode.work);
      expect(provider.currentDuration, 30);
      expect(provider.remainingSeconds, 30 * 60);
      expect(provider.isRunning, isFalse);
      expect(provider.hasActiveProgress, isFalse);
      expect(await store.load(), isNull);
    });
  });
}

TimerRunConfiguration _configuration(List<int> recordedMinutes) {
  return TimerRunConfiguration(
    notificationSound: 'zil1.mp3',
    isBackgroundMusicEnabled: false,
    backgroundVolume: 0.5,
    recordSession: (sessionId, minutes) async {
      recordedMinutes.add(minutes);
    },
  );
}

class _ManualTimerFactory {
  final List<_ManualTimer> created = [];

  _ManualTimer get latest => created.last;

  Timer create(Duration duration, void Function(Timer timer) callback) {
    final timer = _ManualTimer(callback);
    created.add(timer);
    return timer;
  }
}

class _MemoryTimerSessionStore implements TimerSessionStore {
  PersistedTimerSession? session;

  @override
  Future<PersistedTimerSession?> load() async => session;

  @override
  Future<void> save(PersistedTimerSession session) async {
    this.session = session;
  }

  @override
  Future<void> clear({String? expectedSessionId}) async {
    if (expectedSessionId != null && session?.id != expectedSessionId) return;
    session = null;
  }
}

class _ManualTimer implements Timer {
  final void Function(Timer timer) _callback;
  bool _isActive = true;
  int _tick = 0;

  _ManualTimer(this._callback);

  void fire() {
    if (!_isActive) return;
    _tick++;
    _callback(this);
  }

  @override
  bool get isActive => _isActive;

  @override
  int get tick => _tick;

  @override
  void cancel() {
    _isActive = false;
  }
}

class _FakeTimerNotifications implements TimerNotificationGateway {
  final List<int> scheduleCalls = [];
  int cancelCalls = 0;
  bool scheduleSucceeds = true;

  @override
  Future<bool> scheduleTimerEndNotification({
    required int seconds,
    required String title,
    required String body,
  }) async {
    scheduleCalls.add(seconds);
    return scheduleSucceeds;
  }

  @override
  Future<void> cancelScheduledNotification() async {
    cancelCalls++;
  }
}

class _FakeTimerAudio implements TimerAudioGateway {
  int alarmPlayCount = 0;
  int alarmStopCount = 0;
  int musicStopCount = 0;

  @override
  Future<void> playAlarm(String soundFile) async {
    alarmPlayCount++;
  }

  @override
  Future<void> stopAlarm() async {
    alarmStopCount++;
  }

  @override
  Future<void> playMusic(String filePath, double volume) async {}

  @override
  Future<void> stopMusic() async {
    musicStopCount++;
  }

  @override
  Future<void> setMusicVolume(double volume) async {}

  @override
  Future<void> dispose() async {}
}
