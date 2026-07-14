import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/providers.dart';
import 'screens/screens.dart';
import 'services/services.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // env zorunlı değil. bulunamazsa define ile de sağlanabilir.
  }

  final supabaseUrl =
      dotenv.env['SUPABASE_URL'] ??
      const String.fromEnvironment('SUPABASE_URL');
  final supabaseAnonKey =
      dotenv.env['SUPABASE_ANON_KEY'] ??
      const String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL ve SUPABASE_ANON_KEY tanımlanmalı (.env veya --dart-define).',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  await initializeDateFormatting(
    'tr_TR',
    null,
  ); // Türkçe tarih formatı için locale başlatır

  runApp(const HalFiyatApp());
}

class HalFiyatApp extends StatelessWidget {
  const HalFiyatApp({super.key});

  static final IAuthService _authService = SupabaseAuthService();
  static final IProductService _productService = SupabaseProductService();
  static final ISeasonService _seasonService = SupabaseSeasonService();
  static final IHarvestService _harvestService = SupabaseHarvestService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: _authService),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(productService: _productService),
        ),
        ChangeNotifierProvider(
          create:
              (_) => HarvestProvider(
                harvestService: _harvestService,
                seasonService: _seasonService,
              ),
        ),
        ChangeNotifierProvider(
          create: (_) => SeasonProvider(seasonService: _seasonService),
        ),
      ],
      child: const _SessionLifecycleApp(),
    );
  }
}

class _SessionLifecycleApp extends StatefulWidget {
  const _SessionLifecycleApp();

  @override
  State<_SessionLifecycleApp> createState() => _SessionLifecycleAppState();
}

class _SessionLifecycleAppState extends State<_SessionLifecycleApp>
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
      home: const AuthWrapper(),
    );
  }
}

/// Oturum durumuna göre yönlendirme
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth(isAppStartup: true);
    });
  }

  Future<void> _checkAuth({bool isAppStartup = false}) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkCurrentUser(isAppStartup: isAppStartup);
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
        if (auth.isLoggedIn) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
