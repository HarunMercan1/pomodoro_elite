import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class GuestStatsMigrationGateway {
  Future<void> applyBatch(String userId, GuestStatsMigrationBatch batch);
}

class SupabaseGuestStatsMigrationGateway implements GuestStatsMigrationGateway {
  SupabaseGuestStatsMigrationGateway(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<void> applyBatch(
    String userId,
    GuestStatsMigrationBatch batch,
  ) async {
    await _supabase.rpc(
      'migrate_guest_stats_v1',
      params: {
        'p_batch_id': batch.id,
        'p_total_sessions': batch.totalSessions,
        'p_total_minutes': batch.totalMinutes,
        'p_current_streak': batch.currentStreak,
        'p_daily_stats': batch.dailyStats,
      },
    );
  }
}

/// Misafir istatistiklerini idempotent batch'ler halinde saklar.
///
/// Sunucu cevabı kaybolsa bile aynı batch tekrar gönderilir; Supabase tarafındaki
/// migration ledger'ı aynı verinin ikinci kez eklenmesini engeller.
class GuestStatsMigrationService {
  GuestStatsMigrationService({
    GuestStatsMigrationGateway? gateway,
    Future<SharedPreferences> Function()? preferencesFactory,
  })  : _gateway = gateway ??
            SupabaseGuestStatsMigrationGateway(Supabase.instance.client),
        _preferencesFactory =
            preferencesFactory ?? SharedPreferences.getInstance;

  static const _queueKey = 'guest_stats_migration_queue_v1';

  final GuestStatsMigrationGateway _gateway;
  final Future<SharedPreferences> Function() _preferencesFactory;
  Future<void> _operationTail = Future<void>.value();

  Future<bool> hasPendingBatches() => _locked(() async {
        final prefs = await _preferencesFactory();
        return _readQueue(prefs).isNotEmpty;
      });

  Future<void> clearPendingBatches() => _locked(() async {
        final prefs = await _preferencesFactory();
        await prefs.remove(_queueKey);
      });

  Future<void> prepareGuestSnapshot() => _locked(() async {
        final prefs = await _preferencesFactory();
        final queue = _readQueue(prefs);
        if (queue.isNotEmpty) return;

        final minutesByDate = _readIntMap(prefs.getString('daily_stats'));
        final sessionsByDate =
            _readIntMap(prefs.getString('daily_session_counts'));
        final totalSessions = prefs.getInt('total_sessions') ?? 0;
        final totalMinutes = prefs.getInt('total_minutes') ?? 0;

        if (totalSessions == 0 &&
            totalMinutes == 0 &&
            minutesByDate.isEmpty &&
            sessionsByDate.isEmpty) {
          return;
        }

        queue.add(
          GuestStatsMigrationBatch(
            id: _newBatchId(),
            totalSessions: totalSessions,
            totalMinutes: totalMinutes,
            currentStreak: _calculateStreak(minutesByDate),
            dailyStats: _mergeDailyMaps(minutesByDate, sessionsByDate),
          ),
        );
        await _writeQueue(prefs, queue);
      });

  Future<void> enqueueSessionDelta({
    required int minutes,
    required String dateKey,
    required int currentStreak,
  }) =>
      _locked(() async {
        final prefs = await _preferencesFactory();
        final queue = _readQueue(prefs);
        if (queue.isEmpty) return;

        queue.add(
          GuestStatsMigrationBatch(
            id: _newBatchId(),
            totalSessions: 1,
            totalMinutes: minutes,
            currentStreak: currentStreak,
            dailyStats: [
              {'date_key': dateKey, 'minutes': minutes, 'sessions': 1},
            ],
          ),
        );
        await _writeQueue(prefs, queue);
      });

  /// Tüm batch'leri sırayla uygular. Her başarılı batch anında kuyruktan
  /// çıkarıldığı için işlem uygulama kapanmasına karşı dayanıklıdır.
  Future<void> migratePending(String userId) => _locked(() async {
        final prefs = await _preferencesFactory();
        var queue = _readQueue(prefs);

        while (queue.isNotEmpty) {
          var batch = queue.first;
          if (batch.targetUserId != null && batch.targetUserId != userId) {
            throw StateError(
              'Pending guest data belongs to a different account.',
            );
          }

          if (batch.targetUserId == null) {
            batch = batch.copyWith(targetUserId: userId);
            queue[0] = batch;
            await _writeQueue(prefs, queue);
          }

          await _gateway.applyBatch(userId, batch);
          queue = _readQueue(prefs)
            ..removeWhere((candidate) => candidate.id == batch.id);
          await _writeQueue(prefs, queue);
        }
      });

  Future<T> _locked<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _operationTail = _operationTail.catchError((_) {}).then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  List<GuestStatsMigrationBatch> _readQueue(SharedPreferences prefs) {
    final encoded = prefs.getString(_queueKey);
    if (encoded == null || encoded.isEmpty) return [];
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
          .map((item) => GuestStatsMigrationBatch.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeQueue(
    SharedPreferences prefs,
    List<GuestStatsMigrationBatch> queue,
  ) async {
    if (queue.isEmpty) {
      await prefs.remove(_queueKey);
      return;
    }
    await prefs.setString(
      _queueKey,
      jsonEncode(queue.map((batch) => batch.toJson()).toList()),
    );
  }

  Map<String, int> _readIntMap(String? encoded) {
    if (encoded == null || encoded.isEmpty) return {};
    try {
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
    } catch (_) {
      return {};
    }
  }

  List<Map<String, dynamic>> _mergeDailyMaps(
    Map<String, int> minutes,
    Map<String, int> sessions,
  ) {
    final dates = {...minutes.keys, ...sessions.keys}.toList()..sort();
    return dates
        .map((date) => {
              'date_key': date,
              'minutes': minutes[date] ?? 0,
              'sessions': sessions[date] ?? 0,
            })
        .toList();
  }

  int _calculateStreak(Map<String, int> minutesByDate) {
    var streak = 0;
    var date = DateTime.now();
    while (true) {
      final key = DateFormat('yyyy-MM-dd').format(date);
      if ((minutesByDate[key] ?? 0) > 0) {
        streak++;
        date = date.subtract(const Duration(days: 1));
        continue;
      }
      if (streak == 0 && _isSameDay(date, DateTime.now())) {
        date = date.subtract(const Duration(days: 1));
        continue;
      }
      return streak;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _newBatchId() {
    final random = Random.secure();
    return '${DateTime.now().microsecondsSinceEpoch}-'
        '${random.nextInt(1 << 32).toRadixString(16)}';
  }
}

class GuestStatsMigrationBatch {
  const GuestStatsMigrationBatch({
    required this.id,
    required this.totalSessions,
    required this.totalMinutes,
    required this.currentStreak,
    required this.dailyStats,
    this.targetUserId,
  });

  final String id;
  final String? targetUserId;
  final int totalSessions;
  final int totalMinutes;
  final int currentStreak;
  final List<Map<String, dynamic>> dailyStats;

  GuestStatsMigrationBatch copyWith({String? targetUserId}) =>
      GuestStatsMigrationBatch(
        id: id,
        targetUserId: targetUserId ?? this.targetUserId,
        totalSessions: totalSessions,
        totalMinutes: totalMinutes,
        currentStreak: currentStreak,
        dailyStats: dailyStats,
      );

  factory GuestStatsMigrationBatch.fromJson(Map<String, dynamic> json) =>
      GuestStatsMigrationBatch(
        id: json['id'] as String,
        targetUserId: json['target_user_id'] as String?,
        totalSessions: (json['total_sessions'] as num).toInt(),
        totalMinutes: (json['total_minutes'] as num).toInt(),
        currentStreak: (json['current_streak'] as num).toInt(),
        dailyStats: (json['daily_stats'] as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'target_user_id': targetUserId,
        'total_sessions': totalSessions,
        'total_minutes': totalMinutes,
        'current_streak': currentStreak,
        'daily_stats': dailyStats,
      };
}
