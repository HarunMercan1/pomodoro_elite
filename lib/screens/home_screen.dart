import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../providers/timer_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/stats_provider.dart'; // <--- EKLENDİ
import '../screens/settings_screen.dart';
import '../screens/stats_screen.dart'; // <--- EKLENDİ
import '../widgets/time_option_button.dart';
import '../utils/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ConfettiController _confettiController;

  @override
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Provider'lara eriş
      final timerProvider = context.read<TimerProvider>();
      final settingsProvider = context.read<SettingsProvider>();

      // --- KRİTİK DÜZELTME: SÜREYİ EŞİTLE ---
      // Eğer sayaç çalışmıyorsa ve Timer'ın süresi (örn: 25), Ayarlardaki süreden (örn: 40) farklıysa;
      // Timer'ı ayarlardaki süreye zorla.
      if (!timerProvider.isRunning &&
          !timerProvider.isAlarmPlaying &&
          timerProvider.currentMode == TimerMode.work) {

        if (timerProvider.currentDuration != settingsProvider.workTime) {
          timerProvider.setTime(settingsProvider.workTime, TimerMode.work);
        }
      }

      // 2. Konfeti Dinleyicisi (Eski kodun aynısı)
      timerProvider.addListener(() {
        if (!mounted) return;
        if (timerProvider.remainingSeconds == 0 &&
            timerProvider.currentDuration != 0 &&
            _confettiController.state != ConfettiControllerState.playing) {
          _confettiController.play();
        }
      });
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / 5);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step), halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep), halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    final bool isTimerRunning = context.select<TimerProvider, bool>((p) => p.isRunning);
    final bool isAlarmPlaying = context.select<TimerProvider, bool>((p) => p.isAlarmPlaying);
    final int currentDuration = context.select<TimerProvider, int>((p) => p.currentDuration);
    final int remainingSeconds = context.select<TimerProvider, int>((p) => p.remainingSeconds);
    final TimerMode currentMode = context.select<TimerProvider, TimerMode>((p) => p.currentMode);
    final String currentMotivation = context.select<TimerProvider, String>((p) => p.currentMotivation);

    final bool isPaused = !isTimerRunning &&
        !isAlarmPlaying &&
        remainingSeconds > 0 &&
        remainingSeconds < currentDuration * 60;

    final bool isActiveState = isTimerRunning || isAlarmPlaying || isPaused;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color defaultBg = Theme.of(context).scaffoldBackgroundColor;
    final Color defaultPrimary = Theme.of(context).primaryColor;
    final Color defaultText = Theme.of(context).colorScheme.onSurface;
    final Color defaultDivider = Theme.of(context).dividerColor;

    final bgGradient = AppColors.getBackgroundGradient(isTimerRunning, isPaused, isAlarmPlaying, defaultBg);
    final topButtonActiveColor = AppColors.getTopButtonActiveColor(isTimerRunning, isPaused, isAlarmPlaying);
    final mainButtonBgColor = AppColors.getMainButtonBackgroundColor(isTimerRunning, isPaused, isAlarmPlaying, defaultPrimary);
    final mainButtonContentColor = AppColors.getMainButtonContentColor(isTimerRunning, isPaused, isAlarmPlaying);
    final resetTextColor = AppColors.getResetTextColor(isActiveState, isPaused, defaultDivider);

    final bool useLightModeStyles = !isDark && !isActiveState;

    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallScreen = screenHeight < 700;
    final double circleSize = isSmallScreen ? 250 : 300;
    final double timerFontSize = circleSize * 0.28;
    final double btnPadV = isSmallScreen ? 12 : 16;
    final double btnPadH = isSmallScreen ? 30 : 40;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        title: Text(
          'title'.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: useLightModeStyles ? AppColors.darkNavy : Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,

        // --- SOL ÜSTE İSTATİSTİK BUTONU GELDİ ---
        leading: IconButton(
          icon: const Icon(Icons.bar_chart_rounded),
          tooltip: "İstatistikler",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StatsScreen()),
            );
          },
        ),

        iconTheme: IconThemeData(
            color: useLightModeStyles ? AppColors.darkNavy : Colors.white
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),

      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgGradient,
          ),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildOption(context, "focus".tr(), settingsProvider.workTime, TimerMode.work, currentMode, useLightModeStyles, topButtonActiveColor)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildOption(context, "short_break".tr(), settingsProvider.shortBreakTime, TimerMode.shortBreak, currentMode, useLightModeStyles, topButtonActiveColor)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildOption(context, "long_break".tr(), settingsProvider.longBreakTime, TimerMode.longBreak, currentMode, useLightModeStyles, topButtonActiveColor)),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActiveState
                              ? Colors.white.withOpacity(0.15)
                              : Theme.of(context).cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              spreadRadius: 10,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                      ),

                      Consumer<TimerProvider>(
                        builder: (context, provider, child) {
                          final localRingColor = AppColors.getRingColor(
                              provider.isRunning,
                              !provider.isRunning && !provider.isAlarmPlaying && provider.remainingSeconds > 0 && provider.remainingSeconds < provider.currentDuration * 60,
                              provider.isAlarmPlaying,
                              defaultPrimary
                          );

                          final localTimerTextColor = AppColors.getTimerTextColor(
                              provider.isRunning,
                              !provider.isRunning && !provider.isAlarmPlaying && provider.remainingSeconds > 0 && provider.remainingSeconds < provider.currentDuration * 60,
                              provider.isAlarmPlaying,
                              defaultText
                          );

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: circleSize - 20,
                                height: circleSize - 20,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                      begin: 0.0,
                                      end: provider.progress
                                  ),
                                  duration: const Duration(seconds: 1),
                                  curve: Curves.linear,
                                  builder: (context, value, _) {
                                    return CircularProgressIndicator(
                                      value: value,
                                      strokeWidth: 18,
                                      backgroundColor: isActiveState
                                          ? Colors.white.withOpacity(0.2)
                                          : (isDark ? Colors.grey.shade800 : const Color(0xFFF0F0F0)),
                                      valueColor: AlwaysStoppedAnimation<Color>(localRingColor),
                                      strokeCap: StrokeCap.round,
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
                                width: circleSize * 0.70,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Transform.translate(
                                    offset: const Offset(0, 5),
                                    child: Text(
                                      provider.timeLeftString,
                                      style: TextStyle(
                                        fontFamily: 'BebasNeue',
                                        fontSize: timerFontSize,
                                        color: localTimerTextColor,
                                        letterSpacing: 2,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        currentMotivation.tr(),
                        key: ValueKey<String>(currentMotivation),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w500,
                          color: isActiveState
                              ? (isPaused ? AppColors.themeBronze : Colors.white.withOpacity(0.9))
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  Padding(
                    padding: EdgeInsets.only(bottom: isSmallScreen ? 20 : 40),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            final provider = context.read<TimerProvider>();
                            final stats = context.read<StatsProvider>(); // <--- STATS EKLENDİ

                            if (provider.isAlarmPlaying) {
                              provider.stopAlarm(
                                workTime: settingsProvider.workTime,
                                shortBreakTime: settingsProvider.shortBreakTime,
                                longBreakTime: settingsProvider.longBreakTime,
                              );
                            } else if (provider.isRunning) {
                              provider.stopTimer(reset: false);
                            } else {
                              // startTimer'a stats'ı da gönderiyoruz
                              provider.startTimer(settingsProvider, stats);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: EdgeInsets.symmetric(horizontal: btnPadH, vertical: btnPadV),
                            decoration: BoxDecoration(
                              color: mainButtonBgColor,
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAlarmPlaying
                                      ? Icons.check_rounded
                                      : isTimerRunning
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: mainButtonContentColor,
                                  size: isSmallScreen ? 28 : 32,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isAlarmPlaying
                                      ? "stop_alarm".tr()
                                      : isTimerRunning
                                      ? "pause".tr()
                                      : (isPaused)
                                      ? "resume".tr()
                                      : "start".tr(),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: isSmallScreen ? 18 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: mainButtonContentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        IgnorePointer(
                          ignoring: isAlarmPlaying ||
                              !isPaused && !isTimerRunning && remainingSeconds == currentDuration * 60,
                          child: Opacity(
                            opacity: (!isAlarmPlaying &&
                                (isPaused || remainingSeconds != currentDuration * 60))
                                ? 1.0
                                : 0.0,
                            child: GestureDetector(
                              onTap: () => context.read<TimerProvider>().resetTimer(),
                              child: Text(
                                "reset".tr(),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: resetTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple
              ],
              createParticlePath: drawStar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, int time, TimerMode mode, TimerMode currentMode, bool isLightMode, Color? activeColor) {
    return TimeOptionButton(
      title: title,
      minutes: time,
      isSelected: currentMode == mode,
      isLightMode: isLightMode,
      activeBackgroundColor: activeColor,
      activeTextColor: activeColor != null ? Colors.white : null,
      onTap: () => context.read<TimerProvider>().setTime(time, mode),
    );
  }
}