import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../utils/app_theme.dart';

class SessionLifecycleApp extends StatefulWidget {
  const SessionLifecycleApp({super.key});

  @override
  State<SessionLifecycleApp> createState() => _SessionLifecycleAppState();
}

class _SessionLifecycleAppState extends State<SessionLifecycleApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  Future<void> _pauseActivityUpdate = Future.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pauseActivityUpdate = _markSessionActive();
    } else if (state == AppLifecycleState.resumed) {
      _recheckAuthAfterResume();
    }
  }

  Future<void> _markSessionActive() async {
    try {
      await context.read<AuthProvider>().markSessionActive();
    } catch (_) {
      // Oturum kontrolü uygulamaya dönüldüğünde tekrar yapılır.
    }
  }

  Future<void> _recheckAuthAfterResume() async {
    await _pauseActivityUpdate;
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final wasLoggedIn = authProvider.isLoggedIn;
    await authProvider.checkCurrentUser();

    if (!mounted || !wasLoggedIn || authProvider.isLoggedIn) return;
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Hal Fiyat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    await context.read<AuthProvider>().checkCurrentUser(isAppStartup: true);
    if (!mounted) return;
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.agriculture, size: 80, color: Color(0xFF2E7D32)),
              SizedBox(height: 24),
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Yükleniyor...'),
            ],
          ),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
