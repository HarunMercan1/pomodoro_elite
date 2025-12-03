import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'providers/timer_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/stats_provider.dart';
import 'screens/splash_screen.dart';

// main artık hafifledi, bekleme yapmıyor
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  // NotificationService burdan kalktı, Splash'e gitti.
  // Wakelock burdan kalktı, Splash'e gitti.

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('tr',), Locale('en',)],
      path: 'assets/translations',
      fallbackLocale: const Locale('en',),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TimerProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => StatsProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'Pomodoro Elite',
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        cardColor: Colors.white,
        dividerColor: Colors.grey.shade300,
        primaryColor: const Color(0xFF6C63FF),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        dividerColor: Colors.grey.shade800,
        primaryColor: const Color(0xFFBB86FC),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFBB86FC),
          secondary: Color(0xFF03DAC6),
          onSurface: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}