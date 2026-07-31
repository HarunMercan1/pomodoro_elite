import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/stats_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_fonts.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<StatsProvider, ThemeProvider>(
      builder: (context, stats, themeProvider, child) {
        final palette = _StatsPalette.fromTheme(themeProvider);
        final weekStats = stats.thisWeekStats;
        final weeklyMinutes = weekStats.fold<int>(
          0,
          (total, day) => total + (day['minutes'] as int),
        );
        final weeklySessions = weekStats.fold<int>(
          0,
          (total, day) => total + (day['sessions'] as int),
        );
        final weeklyAverage = weeklyMinutes ~/ 7;
        final bestDay = stats.bestDay;
        final bestDayLabel = _formatBestDay(
          context,
          bestDay['date'] as String?,
        );

        return Scaffold(
          backgroundColor: palette.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                centerTitle: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: palette.background,
                surfaceTintColor: Colors.transparent,
                foregroundColor: palette.text,
                title: Text(
                  'stats_title'.tr(),
                  style: AppFonts.poppins(
                    context: context,
                    color: palette.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  MediaQuery.sizeOf(context).width >= 600 ? 24 : 16,
                  12,
                  MediaQuery.sizeOf(context).width >= 600 ? 24 : 16,
                  MediaQuery.paddingOf(context).bottom + 32,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: stats.isLoading
                            ? _LoadingState(palette: palette)
                            : Column(
                                key: const ValueKey('stats-content'),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _StreakHero(
                                    streak: stats.currentStreak,
                                    palette: palette,
                                  ),
                                  const SizedBox(height: 28),
                                  _SectionHeading(
                                    title: 'today'.tr(),
                                    icon: Icons.today_rounded,
                                    palette: palette,
                                  ),
                                  const SizedBox(height: 12),
                                  _TodayCard(
                                    focusMinutes: stats.todayMinutes,
                                    sessions: stats.todaySessions,
                                    palette: palette,
                                  ),
                                  const SizedBox(height: 28),
                                  _WeeklyCard(
                                    weekStats: weekStats,
                                    weeklyMinutes: weeklyMinutes,
                                    weeklySessions: weeklySessions,
                                    weeklyAverage: weeklyAverage,
                                    palette: palette,
                                  ),
                                  const SizedBox(height: 28),
                                  _SectionHeading(
                                    title: 'all_time'.tr(),
                                    icon: Icons.auto_graph_rounded,
                                    palette: palette,
                                  ),
                                  const SizedBox(height: 12),
                                  _AllTimeCard(
                                    totalMinutes: stats.totalMinutes,
                                    totalSessions: stats.totalSessions,
                                    dailyAverage: stats.dailyAverageMinutes,
                                    bestDayLabel: bestDayLabel,
                                    bestDayMinutes:
                                        bestDay['minutes'] as int? ?? 0,
                                    palette: palette,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatBestDay(BuildContext context, String? dateKey) {
    if (dateKey == null || dateKey == '-') return '-';
    final date = DateTime.tryParse(dateKey);
    if (date == null) return '-';
    return MaterialLocalizations.of(context).formatShortDate(date);
  }
}

class _StreakHero extends StatelessWidget {
  const _StreakHero({required this.streak, required this.palette});

  final int streak;
  final _StatsPalette palette;

  @override
  Widget build(BuildContext context) {
    final heroStart = Color.lerp(palette.surface, palette.accent, 0.28)!;
    final heroEnd = Color.lerp(palette.background, palette.accent, 0.08)!;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [heroStart, heroEnd],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.accent.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -36,
            top: -46,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.accent.withValues(alpha: 0.10),
              ),
            ),
          ),
          PositionedDirectional(
            end: 58,
            bottom: -64,
            child: Container(
              width: 126,
              height: 126,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.text.withValues(alpha: 0.035),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: palette.flame.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.local_fire_department_rounded,
                              color: palette.flame,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'daily_streak'.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.poppins(
                                context: context,
                                color: palette.mutedText,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          '$streak ${'day_label'.tr()}',
                          style: AppFonts.bebasNeue(
                            context: context,
                            color: palette.text,
                            fontSize: 54,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'keep_streak'.tr(),
                        maxLines: 2,
                        style: AppFonts.poppins(
                          context: context,
                          color: palette.mutedText,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        palette.flame,
                        palette.flame.withValues(alpha: 0.58),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: palette.flame.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white.withValues(alpha: 0.94),
                    size: 46,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.focusMinutes,
    required this.sessions,
    required this.palette,
  });

  final int focusMinutes;
  final int sessions;
  final _StatsPalette palette;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      palette: palette,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _MetricBlock(
                icon: Icons.timer_rounded,
                iconColor: palette.blue,
                label: 'total_focus'.tr(),
                value: _formatDuration(context, focusMinutes),
                palette: palette,
              ),
            ),
            VerticalDivider(
              width: 32,
              thickness: 1,
              color: palette.border,
            ),
            Expanded(
              child: _MetricBlock(
                icon: Icons.check_circle_rounded,
                iconColor: palette.green,
                label: 'total_sessions'.tr(),
                value: sessions.toString(),
                palette: palette,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard({
    required this.weekStats,
    required this.weeklyMinutes,
    required this.weeklySessions,
    required this.weeklyAverage,
    required this.palette,
  });

  final List<Map<String, dynamic>> weekStats;
  final int weeklyMinutes;
  final int weeklySessions;
  final int weeklyAverage;
  final _StatsPalette palette;

  @override
  Widget build(BuildContext context) {
    final highestValue = weekStats.fold<int>(
      0,
      (highest, day) => max(highest, day['minutes'] as int),
    );
    final chartMaximum = max(30.0, (highestValue * 1.25).ceilToDouble());
    final horizontalInterval = max(10.0, chartMaximum / 3);
    final localizations = MaterialLocalizations.of(context);

    return _SurfaceCard(
      palette: palette,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionHeading(
                  title: 'this_week'.tr(),
                  icon: Icons.bar_chart_rounded,
                  palette: palette,
                  compact: true,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatDuration(context, weeklyMinutes),
                style: AppFonts.poppins(
                  context: context,
                  color: palette.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 224,
            child: RepaintBoundary(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: chartMaximum,
                      alignment: BarChartAlignment.spaceAround,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: horizontalInterval,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: palette.border,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: horizontalInterval,
                            getTitlesWidget: (value, meta) {
                              if (value <= 0 || value >= chartMaximum) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                value.round().toString(),
                                style: AppFonts.poppins(
                                  context: context,
                                  color: palette.subtleText,
                                  fontSize: 9,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= weekStats.length) {
                                return const SizedBox.shrink();
                              }
                              final weekday = weekStats[index]['weekday'] as int;
                              final isToday = weekday == DateTime.now().weekday;
                              return Padding(
                                padding: const EdgeInsets.only(top: 9),
                                child: Text(
                                  localizations.narrowWeekdays[weekday % 7],
                                  style: AppFonts.poppins(
                                    context: context,
                                    color: isToday
                                        ? palette.accent
                                        : palette.mutedText,
                                    fontSize: 11,
                                    fontWeight: isToday
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => palette.tooltip,
                          tooltipRoundedRadius: 12,
                          tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            if (rod.toY <= 0) return null;
                            return BarTooltipItem(
                              '${rod.toY.round()} ${'minutes_label'.tr()}',
                              AppFonts.poppins(
                                context: context,
                                color: palette.text,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                      barGroups: List.generate(weekStats.length, (index) {
                        final minutes = weekStats[index]['minutes'] as int;
                        final isToday =
                            weekStats[index]['weekday'] == DateTime.now().weekday;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: minutes.toDouble(),
                              width: 16,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                              color: isToday
                                  ? palette.accent
                                  : palette.accent.withValues(alpha: 0.48),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: chartMaximum,
                                color: palette.chartTrack,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 500),
                    swapAnimationCurve: Curves.easeOutCubic,
                  ),
                  if (weeklyMinutes == 0)
                    IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: palette.elevatedSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: palette.border),
                        ),
                        child: Text(
                          'empty_stats'.tr(),
                          textAlign: TextAlign.center,
                          style: AppFonts.poppins(
                            context: context,
                            color: palette.mutedText,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CompactMetric(
                  label: 'total_sessions'.tr(),
                  value: weeklySessions.toString(),
                  color: palette.green,
                  palette: palette,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CompactMetric(
                  label: 'daily_avg'.tr(),
                  value: _formatDuration(context, weeklyAverage),
                  color: palette.orange,
                  palette: palette,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AllTimeCard extends StatelessWidget {
  const _AllTimeCard({
    required this.totalMinutes,
    required this.totalSessions,
    required this.dailyAverage,
    required this.bestDayLabel,
    required this.bestDayMinutes,
    required this.palette,
  });

  final int totalMinutes;
  final int totalSessions;
  final int dailyAverage;
  final String bestDayLabel;
  final int bestDayMinutes;
  final _StatsPalette palette;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      palette: palette,
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _MetricBlock(
                    icon: Icons.hourglass_bottom_rounded,
                    iconColor: palette.blue,
                    label: 'total_focus'.tr(),
                    value: _formatDuration(context, totalMinutes),
                    palette: palette,
                  ),
                ),
                VerticalDivider(
                  width: 32,
                  thickness: 1,
                  color: palette.border,
                ),
                Expanded(
                  child: _MetricBlock(
                    icon: Icons.task_alt_rounded,
                    iconColor: palette.green,
                    label: 'total_sessions'.tr(),
                    value: totalSessions.toString(),
                    palette: palette,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final average = _DetailPill(
                icon: Icons.query_stats_rounded,
                color: palette.orange,
                label: 'daily_avg'.tr(),
                value: _formatDuration(context, dailyAverage),
                palette: palette,
              );
              final best = _DetailPill(
                icon: Icons.workspace_premium_rounded,
                color: palette.purple,
                label: 'best_day'.tr(),
                value: bestDayLabel,
                subtitle: _formatDuration(context, bestDayMinutes),
                palette: palette,
              );

              if (constraints.maxWidth < 300) {
                return Column(
                  children: [
                    average,
                    const SizedBox(height: 10),
                    best,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: average),
                  const SizedBox(width: 12),
                  Expanded(child: best),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.palette,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final _StatsPalette palette;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.16 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.icon,
    required this.palette,
    this.compact = false,
  });

  final String title;
  final IconData icon;
  final _StatsPalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 32 : 36,
          height: compact ? 32 : 36,
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
          ),
          child: Icon(
            icon,
            color: palette.accent,
            size: compact ? 18 : 20,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.poppins(
              context: context,
              color: palette.text,
              fontSize: compact ? 17 : 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.palette,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final _StatsPalette palette;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.poppins(
                    context: context,
                    color: palette.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              style: AppFonts.bebasNeue(
                context: context,
                color: palette.text,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.palette,
  });

  final String label;
  final String value;
  final Color color;
  final _StatsPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.elevatedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.poppins(
              context: context,
              color: palette.mutedText,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              style: AppFonts.poppins(
                context: context,
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.palette,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? subtitle;
  final _StatsPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.poppins(
                    context: context,
                    color: palette.mutedText,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.poppins(
                    context: context,
                    color: palette.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.poppins(
                      context: context,
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.palette});

  final _StatsPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('stats-loading'),
      height: MediaQuery.sizeOf(context).height * 0.55,
      child: Center(
        child: CircularProgressIndicator(
          color: palette.accent,
          strokeWidth: 3,
        ),
      ),
    );
  }
}

class _StatsPalette {
  const _StatsPalette({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.elevatedSurface,
    required this.tooltip,
    required this.text,
    required this.mutedText,
    required this.subtleText,
    required this.border,
    required this.chartTrack,
    required this.accent,
    required this.blue,
    required this.green,
    required this.orange,
    required this.purple,
    required this.flame,
  });

  factory _StatsPalette.fromTheme(ThemeProvider themeProvider) {
    final background = themeProvider.settingsBgColor;
    final text = themeProvider.settingsTextColor;
    final isDark =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark;
    final contrastColor = isDark ? Colors.white : Colors.black;
    final surface = Color.lerp(
      background,
      contrastColor,
      isDark ? 0.065 : 0.035,
    )!;
    final elevatedSurface = Color.lerp(
      background,
      contrastColor,
      isDark ? 0.105 : 0.065,
    )!;

    return _StatsPalette(
      isDark: isDark,
      background: background,
      surface: surface,
      elevatedSurface: elevatedSurface,
      tooltip: Color.lerp(surface, contrastColor, isDark ? 0.12 : 0.06)!,
      text: text,
      mutedText: text.withValues(alpha: 0.66),
      subtleText: text.withValues(alpha: 0.42),
      border: text.withValues(alpha: isDark ? 0.10 : 0.08),
      chartTrack: text.withValues(alpha: isDark ? 0.055 : 0.04),
      accent: themeProvider.idleAccentColor,
      blue: const Color(0xFF60A5FA),
      green: const Color(0xFF34D399),
      orange: const Color(0xFFFFA24C),
      purple: const Color(0xFFC084FC),
      flame: const Color(0xFFFF7043),
    );
  }

  final bool isDark;
  final Color background;
  final Color surface;
  final Color elevatedSurface;
  final Color tooltip;
  final Color text;
  final Color mutedText;
  final Color subtleText;
  final Color border;
  final Color chartTrack;
  final Color accent;
  final Color blue;
  final Color green;
  final Color orange;
  final Color purple;
  final Color flame;
}

String _formatDuration(BuildContext context, int minutes) {
  if (minutes < 60) {
    return '$minutes ${'minutes_label'.tr()}';
  }

  final hours = minutes / 60;
  final formattedHours = hours == hours.roundToDouble()
      ? hours.toInt().toString()
      : hours.toStringAsFixed(1);
  return '$formattedHours ${'focus_hours'.tr()}';
}
