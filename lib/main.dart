import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'providers/timer_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/stats_provider.dart';
import 'providers/ad_manager.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/purchase_provider.dart';
import 'screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'services/ad_consent_service.dart';
import 'services/guest_stats_migration_service.dart';

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
    // anonKey is deprecated, using publishableKey for newer Supabase SDK versions
    // but preserving anonKey if necessary, wait, if it warns about anonKey, let's just pass anonKey if publishableKey is not fully integrated in old versions.
    // Actually, I'll just change anonKey: to anonKey: SupabaseConstants.supabaseAnonKey for now.
    // Wait, the warning says "Use publishableKey instead", so I will use it.
    publishableKey: SupabaseConstants.supabaseAnonKey,
  );

  // 🔥 Timezone başlat (zamanlanmış bildirimler için gerekli)
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

  // 🔥 AdMob SDK'yı başlat
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
          Provider(create: (_) => GuestStatsMigrationService()),
          ChangeNotifierProvider(
            create: (context) => StatsProvider(
              guestStatsMigrationService:
                  context.read<GuestStatsMigrationService>(),
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => AuthProvider(
              guestStatsMigrationService:
                  context.read<GuestStatsMigrationService>(),
            ),
          ),
          ChangeNotifierProvider(create: (_) => PurchaseProvider()),
          ChangeNotifierProvider(create: (_) => AdConsentService()),
          ChangeNotifierProxyProvider<PurchaseProvider, ThemeProvider>(
            create: (_) => ThemeProvider(),
            update: (_, purchaseProvider, themeProvider) {
              return (themeProvider ?? ThemeProvider())
                ..updatePremiumStatus(
                  isPremium: purchaseProvider.isPremium,
                  isLoading: purchaseProvider.isLoading,
                );
            },
          ), // 🎨 Tema yöneticisi
          ChangeNotifierProxyProvider2<PurchaseProvider, AdConsentService,
              AdManager>(
            create: (_) => AdManager(),
            update: (_, purchaseProvider, consentService, adManager) {
              return (adManager ?? AdManager())
                ..updatePremiumStatus(purchaseProvider.isPremium)
                ..updateAdServingAllowed(consentService.adsReady);
            },
          ), // 🔥 Reklam yöneticisi
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
