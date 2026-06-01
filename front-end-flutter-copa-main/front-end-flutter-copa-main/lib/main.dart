import 'package:flutter/material.dart';
import 'package:flutter_campeonato_flutter/core/theme/theme_controller.dart';
import 'package:flutter_campeonato_flutter/core/services/session_service.dart';
import 'package:flutter_campeonato_flutter/features/auth/presentation/login_screen.dart';
import 'package:flutter_campeonato_flutter/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  runApp(const CopaDoMundoApp());
}

class NoTransitionPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class CopaDoMundoApp extends StatelessWidget {
  const CopaDoMundoApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0B5FFF),
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF4F7FB),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? const Color(0xFF020617)
            : const Color(0xFF0B1F4D),
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: isDark,
        fillColor: isDark ? const Color(0xFF142B5F) : null,
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFFD7E3FF) : null,
        ),
        prefixIconColor: isDark ? const Color(0xFFD7E3FF) : null,
        enabledBorder: isDark
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF35558D)),
              )
            : null,
        focusedBorder: isDark
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF8FB3FF)),
              )
            : null,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFE61E4D),
        foregroundColor: Colors.white,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: NoTransitionPageTransitionsBuilder(),
          TargetPlatform.iOS: NoTransitionPageTransitionsBuilder(),
          TargetPlatform.macOS: NoTransitionPageTransitionsBuilder(),
          TargetPlatform.windows: NoTransitionPageTransitionsBuilder(),
          TargetPlatform.linux: NoTransitionPageTransitionsBuilder(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeModeController,
      builder: (context, modoEscuro, _) {
        return MaterialApp(
          title: 'Copa do Mundo 2026',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: modoEscuro ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: {'/': (context) => const _AuthGate()},
        );
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late Future<bool> _sessionCheck;

  @override
  void initState() {
    super.initState();
    _sessionCheck = _verificarSessao();
  }

  Future<bool> _verificarSessao() async {
    final session = await SessionService.getSession();
    return session != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessionCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
