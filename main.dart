import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Importaciones para localización y fechas
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Providers
import 'package:mi_app_habitos/providers/locale_provider.dart';
import 'package:mi_app_habitos/providers/theme_provider.dart';
import 'package:mi_app_habitos/providers/achievements_provider.dart';
import 'package:mi_app_habitos/providers/habits_provider.dart';
import 'package:mi_app_habitos/providers/tasks_provider.dart';
import 'package:mi_app_habitos/services/auth_service.dart';

// Pantallas
import 'package:mi_app_habitos/models/data/models/habit_model.dart';
import 'package:mi_app_habitos/screens/presentation/home_screen.dart';
import 'package:mi_app_habitos/screens/presentation/login_screen.dart';
import 'package:mi_app_habitos/screens/register_screen.dart';
import 'package:mi_app_habitos/screens/achievements_screen.dart';
import 'package:mi_app_habitos/screens/presentation/agenda_screen.dart';
import 'package:mi_app_habitos/screens/presentation/habit_stats_screen.dart';
import 'package:mi_app_habitos/screens/presentation/profile_screen.dart';
import 'package:mi_app_habitos/services/data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- INTEGRACIÓN: Inicialización de datos regionales ---
  // Esto corrige el LocaleDataException en las gráficas y calendarios
  await initializeDateFormatting('es_ES', null);

  // Lógica de inicio silencioso
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    try {
      await auth.signInAnonymously();
      debugPrint("✅ Sesión de invitado iniciada automáticamente");
    } catch (e) {
      debugPrint("❌ Error en inicio anónimo: $e");
    }
  }

  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
      await NotificationService.init();
      await NotificationService.requestPermissions();

      await NotificationService.scheduleDailyReminder(
        id: 0,
        title: "¡Hora de tus hábitos!",
        body: "No olvides revisar tus tareas de hoy 🔥",
        hour: 20,
        minute: 0,
      );
      debugPrint("✅ Servicios móviles inicializados");
    } catch (e) {
      debugPrint("❌ Error en servicios: $e");
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AchievementsProvider()),
        ChangeNotifierProvider(create: (_) => HabitsProvider()),
        ChangeNotifierProvider(create: (_) => TasksProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const HabitApp(),
    ),
  );
}

class HabitApp extends StatelessWidget {
  const HabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Mi App de Hábitos',
          locale: localeProvider.locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'ES'),
            Locale('en', 'US'),
          ],
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFFFF5252),
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: const Color(0xFFFF5252),
          ),
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }
              // El StreamBuilder detectará si el usuario es anónimo o real y mostrará el Home
              return const HomeScreen();
            },
          ),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
            '/achievements': (context) => const AchievementsScreen(),
            '/calendar': (context) => const AgendaScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/stats': (context) {
              final habit = ModalRoute.of(context)!.settings.arguments as Habit;
              return HabitStatsScreen(habit: habit);
            },
          },
        );
      },
    );
  }
}
