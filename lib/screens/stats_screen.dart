import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/stats_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_fonts.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<StatsProvider, ThemeProvider>(
      builder: (context, stats, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        // Colors
        final bgColor = theme.idle.bgColor ?? (isDark ? const Color(0xFF1E1E2C) : const Color(0xFFF0F2F5));
        final textColor = theme.settingsItemColor ?? (isDark ? Colors.white : Colors.black87);
        final accentColor = theme.idle.accentColor ?? const Color(0xFF6C63FF);

        // Data processing
        List<int> minutesList = stats.thisWeekStats.map((e) => e['minutes'] as int).toList();
        int maxMinutes = minutesList.isEmpty ? 0 : minutesList.reduce(max);
        double maxY = maxMinutes == 0 ? 60.0 : maxMinutes.toDouble() * 1.2;

        final double totalHours = stats.totalMinutes / 60;
        int totalWeekMinutes = minutesList.fold(0, (a, b) => a + b);
        String totalWeekHours = (totalWeekMinutes / 60).toStringAsFixed(1);
        
        final int avgMinutes = stats.dailyAverageMinutes;
        final bestDayData = stats.bestDay;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: Text(
              "stats_title".tr(),
              style: AppFonts.poppins(
                context: context,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: textColor,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🔥 DAILY STREAK HIGHLIGHT
                  _buildGlassCard(
                    isDark: isDark,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "🔥 ${"daily_streak".tr()}",
                              style: AppFonts.poppins(
                                context: context,
                                color: textColor.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${stats.currentStreak} ${"day_label".tr()}",
                              style: AppFonts.bebasNeue(
                                context: context,
                                color: accentColor,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.local_fire_department, size: 64, color: accentColor.withOpacity(0.2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔥 4-GRID STATS
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.2,
                    children: [
                      _buildGridStat(
                        context: context,
                        isDark: isDark,
                        icon: Icons.timer,
                        title: "total_focus".tr(),
                        value: "${totalHours.toStringAsFixed(1)}h",
                        color: Colors.blueAccent,
                      ),
                      _buildGridStat(
                        context: context,
                        isDark: isDark,
                        icon: Icons.check_circle_outline,
                        title: "total_sessions".tr(),
                        value: "${stats.totalSessions}",
                        color: Colors.greenAccent,
                      ),
                      _buildGridStat(
                        context: context,
                        isDark: isDark,
                        icon: Icons.bar_chart,
                        title: "daily_avg".tr(),
                        value: "${avgMinutes}m",
                        color: Colors.orangeAccent,
                      ),
                      _buildGridStat(
                        context: context,
                        isDark: isDark,
                        icon: Icons.star_outline,
                        title: "best_day".tr(),
                        value: bestDayData['day'] as String? ?? "-",
                        color: Colors.purpleAccent,
                        subtitle: "${bestDayData['minutes']}m",
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 🔥 THIS WEEK CHART
                  _buildGlassCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "this_week".tr(),
                              style: AppFonts.poppins(
                                context: context,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: textColor,
                              ),
                            ),
                            Text(
                              "${totalWeekHours}h",
                              style: AppFonts.poppins(
                                context: context,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: maxY > 0 ? (maxY / 4) : 15,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: isDark ? Colors.white10 : Colors.black12,
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      if (value == maxY) return const SizedBox.shrink();
                                      return Text(
                                        "${value.toInt()}m",
                                        style: TextStyle(
                                          color: textColor.withOpacity(0.5),
                                          fontSize: 10,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= 0 && value.toInt() < stats.thisWeekStats.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            stats.thisWeekStats[value.toInt()]['day'] as String,
                                            style: TextStyle(
                                              color: textColor.withOpacity(0.7),
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: 6,
                              minY: 0,
                              maxY: maxY,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                    stats.thisWeekStats.length,
                                    (index) => FlSpot(index.toDouble(), (stats.thisWeekStats[index]['minutes'] as int).toDouble()),
                                  ),
                                  isCurved: true,
                                  color: accentColor,
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        accentColor.withOpacity(0.3),
                                        accentColor.withOpacity(0.0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassCard({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGridStat({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.poppins(
                    context: context,
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppFonts.bebasNeue(
              context: context,
              fontSize: 28,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppFonts.poppins(
                context: context,
                fontSize: 10,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
