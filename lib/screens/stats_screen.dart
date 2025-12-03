import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/stats_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsProvider>(
        builder: (context, stats, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final primaryColor = Theme.of(context).primaryColor;

          // --- VERİ HESAPLAMALARI ---
          List<int> minutesList = stats.thisWeekStats.map((e) => e['minutes'] as int).toList();
          int maxMinutes = minutesList.isEmpty ? 0 : minutesList.reduce(max);
          double maxY = maxMinutes == 0 ? 60.0 : maxMinutes.toDouble();

          final double totalHours = stats.totalMinutes / 60;

          int totalWeekMinutes = minutesList.reduce((a, b) => a + b);
          String totalWeekHours = (totalWeekMinutes / 60).toStringAsFixed(1);

          return Scaffold(
            appBar: AppBar(
              title: Text(
                "stats_title".tr(),
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: "reset_stats".tr(),
                  onPressed: () => _showResetDialog(context, stats),
                )
              ],
            ),
            body: stats.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // --- 1. SATIR: BUGÜN & TÜM ZAMANLAR (Birleştirilmiş Kartlar) ---
                Row(
                  children: [
                    // BUGÜN KARTI (Süre + Seans)
                    Expanded(
                      child: _buildDualStatCard(
                        context,
                        title: "today".tr(),
                        icon: Icons.bolt_rounded,
                        color: Colors.orange,
                        // Veri 1: Dakika
                        value1: stats.todayMinutes.toString(),
                        unit1: "minutes_label".tr(),
                        // Veri 2: Seans
                        value2: "${stats.todaySessions}",
                        unit2: "sessions_count".tr(),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // TÜM ZAMANLAR KARTI (Saat + Seans)
                    Expanded(
                      child: _buildDualStatCard(
                        context,
                        title: "all_time".tr(),
                        icon: Icons.history,
                        color: Colors.blueAccent,
                        // Veri 1: Saat
                        value1: totalHours.toStringAsFixed(1),
                        unit1: "focus_hours".tr(),
                        // Veri 2: Seans
                        value2: "${stats.totalSessions}",
                        unit2: "sessions_count".tr(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // --- 2. SATIR: 🔥 GÜNLÜK SERİ (Tek Büyük Kart) ---
                _buildStreakCard(
                  context,
                  streak: stats.currentStreak,
                ),

                const SizedBox(height: 30),

                // --- 3. HAFTALIK GRAFİK ---
                Text(
                    "this_week".tr(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    )
                ),
                const SizedBox(height: 15),

                Container(
                  height: 350,
                  padding: const EdgeInsets.fromLTRB(15, 25, 15, 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10, bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "total_focus_label".tr(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  totalWeekHours,
                                  style: TextStyle(
                                    fontFamily: 'BebasNeue',
                                    fontSize: 36,
                                    color: primaryColor,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    "focus_hours".tr(),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxY,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) => const Color(0xFF2A2A35),
                                tooltipPadding: const EdgeInsets.all(8),
                                tooltipMargin: 8,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    '${rod.toY.round()} ${"minutes_label".tr()}',
                                    const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins'
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < stats.thisWeekStats.length) {
                                      String dateStr = stats.thisWeekStats[index]['fullDate'];
                                      DateTime date = DateTime.parse(dateStr);
                                      String dayName = DateFormat('E', context.locale.toString()).format(date);

                                      return Padding(
                                        padding: const EdgeInsets.only(top: 10.0),
                                        child: Text(
                                          dayName,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ),
                            ),
                            gridData: FlGridData(show: false),
                            borderData: FlBorderData(show: false),

                            barGroups: stats.thisWeekStats.asMap().entries.map((entry) {
                              final index = entry.key;
                              final data = entry.value;
                              final minutes = (data['minutes'] as int).toDouble();

                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: minutes,
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryColor.withOpacity(0.6),
                                        primaryColor,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    width: 14,
                                    borderRadius: BorderRadius.circular(6),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: maxY,
                                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }
    );
  }

  // --- YENİ BİRLEŞTİRİLMİŞ KART (Süs yok, net bilgi) ---
  Widget _buildDualStatCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String value1,
    required String unit1,
    required String value2,
    required String unit2,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BAŞLIK
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // VERİLER (YAN YANA)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Veri (Süre)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value1,
                    style: TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 24,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    unit1,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),

              // Araya İnce Çizgi
              Container(
                width: 1,
                height: 30,
                color: Theme.of(context).dividerColor,
              ),

              // 2. Veri (Seans)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value2,
                    style: TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 24,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    unit2,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- ALEVLİ STREAK KARTI (GENİŞ) ---
  Widget _buildStreakCard(BuildContext context, {required int streak}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2E1C11), const Color(0xFF3E2723)] // Dark: Koyu Turuncu/Kahve
              : [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)], // Light: Açık Turuncu
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange, size: 30),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "daily_streak".tr(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    "keep_streak".tr(), // Artık JSON'dan okuyacak
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "$streak",
                style: const TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 36,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                "day_label".tr(),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: Colors.deepOrange.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, StatsProvider stats) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("reset_dialog_title".tr()),
        content: Text("reset_dialog_content".tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("cancel".tr()),
          ),
          TextButton(
            onPressed: () {
              stats.clearAllStats();
              Navigator.pop(ctx);
            },
            child: Text("yes_delete".tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}