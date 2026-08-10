import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/guest_stats_migration_service.dart';

class StatsProvider with ChangeNotifier {
  static const _localStateKey = 'stats_state_v2';

  StatsProvider({
    SupabaseClient? supabaseClient,
    GuestStatsMigrationService? guestStatsMigrationService,
  })  : _supabase = supabaseClient ?? Supabase.instance.client,
        _guestStatsMigrationService =
            guestStatsMigrationService ?? GuestStatsMigrationService() {
    _queueStatsLoad();

    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.signedOut) {
        _queueStatsLoad(
            clearLocalOnSignedOut: event == AuthChangeEvent.signedOut);
      }
    });
  }

  late SharedPreferences _prefs;
  final SupabaseClient _supabase;
  final GuestStatsMigrationService _guestStatsMigrationService;
  Future<void> _loadTail = Future<void>.value();
  Future<void> _mutationTail = Future<void>.value();

  Map<String, int> _dailyStats = {};
  Map<String, int> _dailySessionCounts = {};
  Set<String> _recordedSessionIds = {};

  int _totalSessions = 0;
  int _totalMinutes = 0;
  int _currentStreak = 0;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  int get totalSessions => _totalSessions;
  int get totalMinutes => _totalMinutes;
  int get currentStreak => _currentStreak;

  void _queueStatsLoad({bool clearLocalOnSignedOut = false}) {
    _loadTail = _loadTail
        .catchError((_) {})
        .then((_) => _loadStats(clearLocalOnSignedOut: clearLocalOnSignedOut));
  }

  int get todayMinutes {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _dailyStats[todayKey] ?? 0;
  }

  int get todaySessions {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _dailySessionCounts[todayKey] ?? 0;
  }

  List<Map<String, dynamic>> get thisWeekStats {
    List<Map<String, dynamic>> stats = [];
    DateTime now = DateTime.now();
    int currentDayOfWeek = now.weekday;
    DateTime startOfWeek = now.subtract(Duration(days: currentDayOfWeek - 1));

    for (int i = 0; i < 7; i++) {
      DateTime date = startOfWeek.add(Duration(days: i));
      String dateKey = DateFormat('yyyy-MM-dd').format(date);
      stats.add({
        'weekday': date.weekday,
        'minutes': _dailyStats[dateKey] ?? 0,
        'sessions': _dailySessionCounts[dateKey] ?? 0,
        'fullDate': dateKey,
      });
    }
    return stats;
  }

  Future<void> _loadStats({bool clearLocalOnSignedOut = false}) async {
    _isLoading = true;
    notifyListeners();

    _prefs = await SharedPreferences.getInstance();

    final user = _supabase.auth.currentUser;

    if (user != null) {
      try {
        if (await _guestStatsMigrationService.hasPendingBatches(
          userId: user.id,
        )) {
          await _guestStatsMigrationService.migratePending(user.id);
        }
        await _fetchFromSupabase(user.id);
      } catch (e) {
        debugPrint('Stats migration/fetch error: $e');
        // Migration tamamlanmadan lokal verinin üzerine bulut verisi yazılmaz.
        _loadFromLocal();
      }
    } else {
      if (clearLocalOnSignedOut) {
        await _clearLocalStatsCache();
      }
      _loadFromLocal();
    }

    _calculateStreak();
    _isLoading = false;
    notifyListeners();
  }

  void _loadFromLocal() {
    final stateString = _prefs.getString(_localStateKey);
    if (stateString != null) {
      try {
        final state = Map<String, dynamic>.from(jsonDecode(stateString) as Map);
        _dailyStats = _decodeIntMap(state['daily_stats']);
        _dailySessionCounts = _decodeIntMap(state['daily_session_counts']);
        _totalSessions = (state['total_sessions'] as num?)?.toInt() ?? 0;
        _totalMinutes = (state['total_minutes'] as num?)?.toInt() ?? 0;
        _recordedSessionIds = (state['recorded_session_ids'] as List<dynamic>?)
                ?.whereType<String>()
                .toSet() ??
            {};
        return;
      } catch (_) {
        // Fall back to the legacy preference keys.
      }
    }

    String? statsString = _prefs.getString('daily_stats');
    if (statsString != null) {
      Map<String, dynamic> decoded = jsonDecode(statsString);
      _dailyStats = decoded.map((key, value) => MapEntry(key, value as int));
    } else {
      _dailyStats = {};
    }

    String? sessionCountsString = _prefs.getString('daily_session_counts');
    if (sessionCountsString != null) {
      Map<String, dynamic> decoded = jsonDecode(sessionCountsString);
      _dailySessionCounts =
          decoded.map((key, value) => MapEntry(key, value as int));
    } else {
      _dailySessionCounts = {};
    }

    _totalSessions = _prefs.getInt('total_sessions') ?? 0;
    _totalMinutes = _prefs.getInt('total_minutes') ?? 0;
    _recordedSessionIds = {};
  }

  Map<String, int> _decodeIntMap(dynamic value) {
    if (value is! Map) return {};
    return Map<String, dynamic>.from(value).map(
      (key, item) => MapEntry(key, (item as num).toInt()),
    );
  }

  Future<void> _persistLocalState() async {
    await _prefs.setString(
      _localStateKey,
      jsonEncode({
        'daily_stats': _dailyStats,
        'daily_session_counts': _dailySessionCounts,
        'total_minutes': _totalMinutes,
        'total_sessions': _totalSessions,
        'recorded_session_ids': _recordedSessionIds.toList()..sort(),
      }),
    );

    // Keep the legacy keys current for one release to preserve rollback safety.
    await Future.wait([
      _prefs.setString('daily_stats', jsonEncode(_dailyStats)),
      _prefs.setString(
        'daily_session_counts',
        jsonEncode(_dailySessionCounts),
      ),
      _prefs.setInt('total_minutes', _totalMinutes),
      _prefs.setInt('total_sessions', _totalSessions),
    ]);
  }

  Future<void> _clearLocalStatsCache() async {
    await Future.wait([
      _prefs.remove('daily_stats'),
      _prefs.remove('daily_session_counts'),
      _prefs.remove('total_minutes'),
      _prefs.remove('total_sessions'),
      _prefs.remove(_localStateKey),
    ]);
  }

  Future<void> _fetchFromSupabase(String userId) async {
    // A) user_stats çek
    final userStatsResponse = await _supabase
        .from('user_stats')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (userStatsResponse != null) {
      _totalSessions = userStatsResponse['total_sessions'] ?? 0;
      _totalMinutes = userStatsResponse['total_minutes'] ?? 0;
      _currentStreak = userStatsResponse['current_streak'] ?? 0;

      // Lokali güncelle
    } else {
      // Supabase'de veri yoksa lokaldekini buluta gönder (İlk Senkronizasyon)
      _loadFromLocal();
      if (_totalSessions > 0) {
        await _syncToSupabase(userId);
      }
      return;
    }

    // B) daily_stats çek
    final dailyStatsResponse =
        await _supabase.from('daily_stats').select().eq('user_id', userId);

    _dailyStats.clear();
    _dailySessionCounts.clear();

    for (var row in dailyStatsResponse) {
      final dateKey = row['date_key'] as String;
      _dailyStats[dateKey] = row['minutes'] ?? 0;
      _dailySessionCounts[dateKey] = row['sessions'] ?? 0;
    }

    // Lokali güncelle
    await _persistLocalState();
  }

  Future<void> _syncToSupabase(String userId) async {
    // 1. user_stats güncelle
    await _supabase.from('user_stats').upsert({
      'user_id': userId,
      'total_sessions': _totalSessions,
      'total_minutes': _totalMinutes,
      'current_streak': _currentStreak,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // 2. daily_stats güncelle (Sadece bugünü güncellemek performansı artırır,
    // ama ilk sync için tüm günleri göndermek lazım. Burada sadece bugünü gönderiyoruz)
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_dailyStats.containsKey(todayKey)) {
      await _supabase.from('daily_stats').upsert({
        'user_id': userId,
        'date_key': todayKey,
        'minutes': _dailyStats[todayKey],
        'sessions': _dailySessionCounts[todayKey],
      }, onConflict: 'user_id,date_key');
    }
  }

  void _calculateStreak() {
    int streak = 0;
    DateTime checkDate = DateTime.now();

    while (true) {
      String dateKey = DateFormat('yyyy-MM-dd').format(checkDate);
      if ((_dailyStats[dateKey] ?? 0) > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        if (isSameDay(checkDate, DateTime.now()) && streak == 0) {
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
    }
    _currentStreak = streak;
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> addSession(int minutes, {String? sessionId}) {
    final operation = _mutationTail
        .catchError((_) {})
        .then((_) => _addSession(minutes, sessionId: sessionId));
    _mutationTail = operation;
    return operation;
  }

  Future<void> _addSession(int minutes, {String? sessionId}) async {
    // Auth değişimi sırasında çalışan migration/fetch tamamlanmadan toplamları
    // değiştirme; aksi halde eski lokal snapshot bulut toplamını ezebilir.
    await _loadTail;
    final effectiveSessionId =
        sessionId ?? 'legacy-${DateTime.now().microsecondsSinceEpoch}';
    if (_recordedSessionIds.contains(effectiveSessionId)) return;

    final user = _supabase.auth.currentUser;
    if (user == null) {
      await _guestStatsMigrationService.prepareGuestSnapshot();
    }
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    int currentTodayMinutes = _dailyStats[todayKey] ?? 0;
    _dailyStats[todayKey] = currentTodayMinutes + minutes;

    int currentTodaySessions = _dailySessionCounts[todayKey] ?? 0;
    _dailySessionCounts[todayKey] = currentTodaySessions + 1;

    _totalMinutes += minutes;
    _totalSessions += 1;

    // 1. LOKALDE KAYDET
    _calculateStreak();

    await _guestStatsMigrationService.enqueueSessionDelta(
      minutes: minutes,
      dateKey: todayKey,
      currentStreak: _currentStreak,
      batchId: effectiveSessionId,
      targetUserId: user?.id,
    );
    _recordedSessionIds.add(effectiveSessionId);
    await _persistLocalState();
    notifyListeners();

    if (user != null) unawaited(_syncPendingStats(user.id));
  }

  Future<void> _syncPendingStats(String userId) async {
    try {
      await _guestStatsMigrationService.migratePending(userId);
      await _fetchFromSupabase(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Pending stats sync error: $e');
    }
  }

  int get dailyAverageMinutes {
    if (_dailyStats.isEmpty) return 0;
    return _totalMinutes ~/ _dailyStats.length;
  }

  Map<String, dynamic> get bestDay {
    if (_dailyStats.isEmpty) return {'date': '-', 'minutes': 0};

    var maxEntry =
        _dailyStats.entries.reduce((a, b) => a.value > b.value ? a : b);
    return {'date': maxEntry.key, 'minutes': maxEntry.value};
  }

  Future<void> clearAllStats() async {
    _dailyStats.clear();
    _dailySessionCounts.clear();
    _recordedSessionIds.clear();
    _totalMinutes = 0;
    _totalSessions = 0;
    _currentStreak = 0;

    await _clearLocalStatsCache();
    await _guestStatsMigrationService.clearPendingBatches();

    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('user_stats').delete().eq('user_id', user.id);
        await _supabase.from('daily_stats').delete().eq('user_id', user.id);
      } catch (e) {
        debugPrint("Supabase silme hatası: $e");
      }
    }

    notifyListeners();
  }
}
