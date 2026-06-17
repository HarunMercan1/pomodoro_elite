import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'providers/timer_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/stats_provider.dart';
import 'providers/ad_manager.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';

// main artık hafifledi, bekleme yapmıyor
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // 🔥 Sadece dikey modda çalışmasını sağla
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 🔥 Supabase'i Başlat
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  // 🔥 Timezone başlat (zamanlanmış bildirimler için gerekli)
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

  // 🔥 AdMob SDK'yı başlat
  await MobileAds.instance.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'), // İngilizce
        Locale('tr'), // Türkçe
        Locale('es'), // İspanyolca
        Locale('pt'), // Portekizce
        Locale('de'), // Almanca
        Locale('fr'), // Fransızca
        Locale('it'), // İtalyanca
        Locale('ru'), // Rusça
        Locale('ja'), // Japonca
        Locale('ko'), // Korece
        Locale('zh'), // Çince
        Locale('hi'), // Hintçe
        Locale('ar'), // Arapça
        Locale('id'), // Endonezyaca
        Locale('vi'), // Vietnamca
        Locale('bn'), // Bengalce
        Locale('ur'), // Urduca
        Locale('pl'), // Lehçe
        Locale('th'), // Tayca
        Locale('nl'), // Hollandaca
        Locale('uk'), // Ukraynaca
        Locale('el'), // Yunanca
        Locale('sv'), // İsveççe
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale(
        'en',
      ),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TimerProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => StatsProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(
              create: (_) => ThemeProvider()), // 🎨 Tema yöneticisi
          ChangeNotifierProvider(
              create: (_) => AdManager()), // 🔥 Reklam yöneticisi
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
