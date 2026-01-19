import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/stats_provider.dart';
import '../providers/theme_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<StatsProvider, ThemeProvider>(
      builder: (context, stats, themeProvider, child) {
        final theme = themeProvider.currentTheme;

        // --- RENK PALETİ (Temadan Türetilmiş) ---
        final Color color1 = theme.focus.bgColor; // Odak Rengi
        final Color color2 = theme.idle.accentColor; // İkincil Renk düzeltildi
        final Color color3 = theme.breakState.bgColor; // Mola Rengi
        // color4 unused

        final Color cardBgColor = theme.settingsCardColor ??
            theme.idle.menuButtonColor ??
            const Color(0xFF1E1E1E);
        final Color textColor = theme.settingsItemColor ?? theme.idle.textColor;

        // --- VERİ HESAPLAMALARI ---
        List<int> minutesList =
            stats.thisWeekStats.map((e) => e['minutes'] as int).toList();
        int maxMinutes = minutesList.isEmpty ? 0 : minutesList.reduce(max);
        double maxY = maxMinutes == 0 ? 60.0 : maxMinutes.toDouble() * 1.2;

        final double totalHours = stats.totalMinutes / 60;
        int totalWeekMinutes = minutesList.fold(0, (a, b) => a + b);
        String totalWeekHours = (totalWeekMinutes / 60).toStringAsFixed(1);

        // Yeni Veriler
        final int avgMinutes = stats.dailyAverageMinutes;
        final bestDayData = stats.bestDay;

        return Scaffold(
          backgroundColor: theme.idle.bgColor, // Temanın ana arka planı
          appBar: AppBar(
            title: Text(
              "stats_title".tr(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.delete_outline, color: textColor),
                tooltip: "reset_stats".tr(),
                onPressed: () => _showResetDialog(context, stats),
              )
            ],
          ),
          body: stats.isLoading
              ? Center(child: CircularProgressIndicator(color: color2))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // --- 1. GÜNLÜK SERİ (Feature Card) ---
                    _buildStreakCard(
                      context,
                      streak: stats.currentStreak,
                      gradient: LinearGradient(
                        colors: theme.focus.gradientColors ?? [color1, color1],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      textColor: theme.focus.textColor,
                    ),

                    const SizedBox(height: 25),

                    // --- 2. DETAYLI İSTATİSTİK GRID'İ ---
                    LayoutBuilder(builder: (context, constraints) {
                      return Wrap(
                        spacing: 15,
                        runSpacing: 15,
                        children: [
                          // Bugün
                          _buildStatItem(
                            context,
                            width: (constraints.maxWidth - 15) / 2,
                            title: "today".tr(),
                            value: "${stats.todayMinutes}m",
                            subValue:
                                "${stats.todaySessions} ${"sessions_count".tr()}",
                            icon: Icons.today_rounded,
                            accentColor: color1,
                            cardColor: cardBgColor,
                            textColor: textColor,
                          ),
                          // Toplam Odak
                          _buildStatItem(
                            context,
                            width: (constraints.maxWidth - 15) / 2,
                            title: "total_focus_label".tr(),
                            value: "${totalHours.toStringAsFixed(1)}h",
                            subValue:
                                "${stats.totalSessions} ${"sessions_count".tr()}",
                            icon: Icons.history_edu_rounded,
                            accentColor: color2,
                            cardColor: cardBgColor,
                            textColor: textColor,
                          ),
                          // Günlük Ortalama
                          _buildStatItem(
                            context,
                            width: (constraints.maxWidth - 15) / 2,
                            title: "daily_avg".tr(),
                            value: "${avgMinutes}m",
                            subValue: "per_day".tr(),
                            icon: Icons.speed_rounded,
                            accentColor: color3,
                            cardColor: cardBgColor,
                            textColor: textColor,
                          ),
                          // En İyi Gün
                          _buildStatItem(
                            context,
                            width: (constraints.maxWidth - 15) / 2,
                            title: "best_day".tr(),
                            value: "${bestDayData['minutes']}m",
                            subValue: _formatDate(bestDayData['date']),
                            icon: Icons.emoji_events_rounded,
                            accentColor: theme.finish.bgColor,
                            cardColor: cardBgColor,
                            textColor: textColor,
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 30),

                    // --- 3. HAFTALIK GRAFİK KARTI ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: textColor.withOpacity(0.05),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "this_week".tr(),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "$totalWeekHours ${"focus_hours".tr()}",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: color1, // Odak rengi
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color1.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.bar_chart_rounded,
                                    color: color1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: maxY,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (_) =>
                                        theme.settingsCardColor ??
                                        Colors.grey[900]!,
                                    tooltipPadding: const EdgeInsets.all(8),
                                    tooltipMargin: 8,
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        '${rod.toY.round()} m',
                                        TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  topTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  leftTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= 0 &&
                                            index <
                                                stats.thisWeekStats.length) {
                                          String dateStr = stats
                                              .thisWeekStats[index]['fullDate'];
                                          DateTime date =
                                              DateTime.parse(dateStr);
                                          String dayName = DateFormat('E',
                                                  context.locale.toString())
                                              .format(date);

                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              dayName,
                                              style: TextStyle(
                                                color:
                                                    textColor.withOpacity(0.6),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
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
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: maxY / 4,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: textColor.withOpacity(0.05),
                                    strokeWidth: 1,
                                    dashArray: [5, 5],
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: stats.thisWeekStats
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final index = entry.key;
                                  final data = entry.value;
                                  final minutes =
                                      (data['minutes'] as int).toDouble();

                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: minutes,
                                        gradient: LinearGradient(
                                          colors: [
                                            color1.withOpacity(0.7),
                                            color1,
                                          ],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                        width: 16,
                                        borderRadius: BorderRadius.circular(4),
                                        backDrawRodData:
                                            BackgroundBarChartRodData(
                                          show: true,
                                          toY: maxY,
                                          color: textColor.withOpacity(0.05),
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
                    const SizedBox(height: 30),
                  ],
                ),
        );
      },
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr == '-') return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildStatItem(
    BuildContext context, {
    required double width,
    required String title,
    required String value,
    required String subValue,
    required IconData icon,
    required Color accentColor,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textColor.withOpacity(0.8), size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 28,
                color: textColor,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: textColor.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(
    BuildContext context, {
    required int streak,
    required Gradient gradient,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_fire_department_rounded,
                    color: textColor, size: 28),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "daily_streak".tr(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: textColor.withOpacity(0.9),
                    ),
                  ),
                  Text(
                    "keep_fire_burning"
                        .tr(), // Localize key: keep_streak alternatifi
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            children: [
              Text(
                "$streak",
                style: TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 42,
                  color: textColor,
                  height: 1.0,
                ),
              ),
              Text(
                "day_label".tr(),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: textColor.withOpacity(0.8),
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
            child: Text("yes_delete".tr(),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
