import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-App Review yöneticisi
/// Belirli pomodoro sayısından sonra değerlendirme popup'ı gösterir
class ReviewHelper {
  static const String _keyPomodoroCount = 'total_pomodoro_for_review';
  static const String _keyHasReviewed = 'has_shown_review';
  static const String _keyLastReviewDate = 'last_review_prompt_date';

  /// İlk review için gereken pomodoro sayısı
  static const int _firstReviewThreshold = 2;

  /// Tekrar review istemek için gereken ek pomodoro sayısı
  static const int _repeatReviewThreshold = 3;

  /// İki review arasında minimum gün sayısı (0 = kısıtlama yok)
  static const int _minDaysBetweenReviews = 0;

  final InAppReview _inAppReview = InAppReview.instance;

  /// Pomodoro tamamlandığında çağır
  /// Uygun koşullar sağlanırsa review popup'ı gösterir
  Future<void> onPomodoroCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Toplam pomodoro sayısını artır
      int totalPomodoros = prefs.getInt(_keyPomodoroCount) ?? 0;
      totalPomodoros++;
      await prefs.setInt(_keyPomodoroCount, totalPomodoros);

      debugPrint('⭐ Review Helper: Toplam pomodoro: $totalPomodoros');

      // Review gösterilip gösterilmeyeceğini kontrol et
      if (await _shouldRequestReview(prefs, totalPomodoros)) {
        await _requestReview(prefs);
      }
    } catch (e) {
      debugPrint('❌ Review Helper hatası: $e');
    }
  }

  /// Review gösterilmeli mi?
  Future<bool> _shouldRequestReview(
      SharedPreferences prefs, int totalPomodoros) async {
    // Daha önce hiç gösterilmedi mi?
    final bool hasShownBefore = prefs.getBool(_keyHasReviewed) ?? false;

    if (!hasShownBefore) {
      // İlk kez: 10 pomodoro tamamlandıysa göster
      return totalPomodoros >= _firstReviewThreshold;
    }

    // Daha önce gösterildiyse:
    // 1. Son gösterimden 30 gün geçmiş olmalı
    // 2. Ek 50 pomodoro tamamlanmış olmalı

    final String? lastDateStr = prefs.getString(_keyLastReviewDate);
    if (lastDateStr == null) return false;

    final DateTime lastDate = DateTime.parse(lastDateStr);
    final int daysSinceLastReview = DateTime.now().difference(lastDate).inDays;

    if (daysSinceLastReview < _minDaysBetweenReviews) {
      return false;
    }

    // Son review'dan bu yana yeterli pomodoro tamamlandı mı?
    final int pomodorosAtLastReview =
        prefs.getInt('pomodoros_at_last_review') ?? 0;
    return (totalPomodoros - pomodorosAtLastReview) >= _repeatReviewThreshold;
  }

  /// Review popup'ını göster
  Future<void> _requestReview(SharedPreferences prefs) async {
    debugPrint('⭐ Review isteniyor...');

    // Cihaz destekliyor mu kontrol et
    if (await _inAppReview.isAvailable()) {
      debugPrint('✅ In-App Review kullanılabilir, gösteriliyor...');

      // Review'ı göster
      await _inAppReview.requestReview();

      // Gösterildiğini kaydet
      await prefs.setBool(_keyHasReviewed, true);
      await prefs.setString(
          _keyLastReviewDate, DateTime.now().toIso8601String());
      await prefs.setInt(
          'pomodoros_at_last_review', prefs.getInt(_keyPomodoroCount) ?? 0);

      debugPrint('✅ Review popup gösterildi');
    } else {
      debugPrint(
          '⚠️ In-App Review kullanılamıyor (cihaz desteklemiyor veya kota doldu)');
    }
  }

  /// Manuel olarak review iste (Ayarlar ekranından)
  Future<bool> requestReviewManually() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        return true;
      } else {
        // Fallback: Play Store'u aç
        await _inAppReview.openStoreListing(
          appStoreId: '', // iOS için gerekli, Android'de boş bırakılabilir
        );
        return true;
      }
    } catch (e) {
      debugPrint('❌ Review isteği başarısız: $e');
      return false;
    }
  }
}
