import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PersistedTimerSession {
  const PersistedTimerSession({
    required this.id,
    required this.mode,
    required this.durationMinutes,
    required this.remainingSeconds,
    required this.isRunning,
    this.deadlineUtc,
  });

  final String id;
  final String mode;
  final int durationMinutes;
  final int remainingSeconds;
  final bool isRunning;
  final DateTime? deadlineUtc;

  factory PersistedTimerSession.fromJson(Map<String, dynamic> json) {
    final deadlineValue = json['deadline_utc'] as String?;
    return PersistedTimerSession(
      id: json['id'] as String,
      mode: json['mode'] as String,
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      remainingSeconds: (json['remaining_seconds'] as num).toInt(),
      isRunning: json['is_running'] as bool,
      deadlineUtc: deadlineValue == null
          ? null
          : DateTime.tryParse(deadlineValue)?.toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode,
        'duration_minutes': durationMinutes,
        'remaining_seconds': remainingSeconds,
        'is_running': isRunning,
        'deadline_utc': deadlineUtc?.toIso8601String(),
      };
}

abstract interface class TimerSessionStore {
  Future<PersistedTimerSession?> load();

  Future<void> save(PersistedTimerSession session);

  Future<void> clear({String? expectedSessionId});
}

class SharedPreferencesTimerSessionStore implements TimerSessionStore {
  SharedPreferencesTimerSessionStore({
    Future<SharedPreferences> Function()? preferencesFactory,
  }) : _preferencesFactory =
            preferencesFactory ?? SharedPreferences.getInstance;

  static const _activeSessionKey = 'active_timer_session_v1';

  final Future<SharedPreferences> Function() _preferencesFactory;

  @override
  Future<PersistedTimerSession?> load() async {
    final prefs = await _preferencesFactory();
    final encoded = prefs.getString(_activeSessionKey);
    if (encoded == null || encoded.isEmpty) return null;

    try {
      return PersistedTimerSession.fromJson(
        Map<String, dynamic>.from(jsonDecode(encoded) as Map),
      );
    } catch (_) {
      await prefs.remove(_activeSessionKey);
      return null;
    }
  }

  @override
  Future<void> save(PersistedTimerSession session) async {
    final prefs = await _preferencesFactory();
    await prefs.setString(_activeSessionKey, jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear({String? expectedSessionId}) async {
    final prefs = await _preferencesFactory();
    if (expectedSessionId != null) {
      final current = await load();
      if (current == null || current.id != expectedSessionId) return;
    }
    await prefs.remove(_activeSessionKey);
  }
}
