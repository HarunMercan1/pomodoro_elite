import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class StatsProvider with ChangeNotifier {
  late SharedPreferences _prefs;

  Map<String, int> _dailyStats = {};
  Map<String, int> _dailySessionCounts = {};

  int _totalSessions = 0;
  int _totalMinutes = 0;
  int _currentStreak = 0; // 🔥 YENİ: Mevcut Seri

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  int get totalSessions => _totalSessions;
  int get totalMinutes => _totalMinutes;
  int get currentStreak => _currentStreak; // 🔥 YENİ

  StatsProvider() {
    _loadStats();
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
      String dayName = DateFormat('E').format(date);

      stats.add({
        'day': dayName,
        'minutes': _dailyStats[dateKey] ?? 0,
        'fullDate': dateKey,
      });
    }
    return stats;
  }

  Future<void> _loadStats() async {
    _prefs = await SharedPreferences.getInstance();

    String? statsString = _prefs.getString('daily_stats');
    if (statsString != null) {
      Map<String, dynamic> decoded = jsonDecode(statsString);
      _dailyStats = decoded.map((key, value) => MapEntry(key, value as int));
    }

    String? sessionCountsString = _prefs.getString('daily_session_counts');
    if (sessionCountsString != null) {
      Map<String, dynamic> decoded = jsonDecode(sessionCountsString);
      _dailySessionCounts =
          decoded.map((key, value) => MapEntry(key, value as int));
    }

    _totalSessions = _prefs.getInt('total_sessions') ?? 0;
    _totalMinutes = _prefs.getInt('total_minutes') ?? 0;

    // 🔥 YENİ: Streak Yükleme ve Hesaplama
    _calculateStreak();

    _isLoading = false;
    notifyListeners();
  }

  // 🔥 STREAK HESAPLAMA MANTIĞI
  void _calculateStreak() {
    int streak = 0;
    DateTime checkDate = DateTime.now();

    // Bugünden geriye doğru git
    while (true) {
      String dateKey = DateFormat('yyyy-MM-dd').format(checkDate);
      if ((_dailyStats[dateKey] ?? 0) > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        // Eğer bugün henüz çalışmadıysak ama dün çalıştıysak seriyi bozma
        // Sadece bugünü kontrol ederken 0 ise ve henüz gün bitmediyse seriyi koru
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

  Future<void> addSession(int minutes) async {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    int currentTodayMinutes = _dailyStats[todayKey] ?? 0;
    _dailyStats[todayKey] = currentTodayMinutes + minutes;

    int currentTodaySessions = _dailySessionCounts[todayKey] ?? 0;
    _dailySessionCounts[todayKey] = currentTodaySessions + 1;

    _totalMinutes += minutes;
    _totalSessions += 1;

    // Kaydet ve Streak'i tekrar hesapla
    await _prefs.setString('daily_stats', jsonEncode(_dailyStats));
    await _prefs.setString(
        'daily_session_counts', jsonEncode(_dailySessionCounts));
    await _prefs.setInt('total_minutes', _totalMinutes);
    await _prefs.setInt('total_sessions', _totalSessions);

    _calculateStreak(); // 🔥 Streak güncelle

    notifyListeners();
  }

  // 🔥 YENİ: Günlük Ortalama (Sadece aktif olunan günler baz alınabilir veya genel)
  int get dailyAverageMinutes {
    if (_dailyStats.isEmpty) return 0;
    // Sadece kayıtlı günlerin ortalaması (aktif günler)
    return _totalMinutes ~/ _dailyStats.length;
  }

  // 🔥 YENİ: En İyi Gün (En çok odaklanılan gün)
  Map<String, dynamic> get bestDay {
    if (_dailyStats.isEmpty) return {'date': '-', 'minutes': 0};

    var maxEntry =
        _dailyStats.entries.reduce((a, b) => a.value > b.value ? a : b);
    return {'date': maxEntry.key, 'minutes': maxEntry.value};
  }

  Future<void> clearAllStats() async {
    _dailyStats.clear();
    _dailySessionCounts.clear();
    _totalMinutes = 0;
    _totalSessions = 0;
    _currentStreak = 0;

    await _prefs.remove('daily_stats');
    await _prefs.remove('daily_session_counts');
    await _prefs.remove('total_minutes');
    await _prefs.remove('total_sessions');

    notifyListeners();
  }
}
