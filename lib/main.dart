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
    // .env zorunlu değil; --dart-define ile de çalışabilir.
  }

  final supabaseUrl =
      dotenv.env['SUPABASE_URL'] ?? const String.fromEnvironment('SUPABASE_URL');
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
      const String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL ve SUPABASE_ANON_KEY tanımlanmalı (.env veya --dart-define).',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  // Türkçe tarih formatı için locale başlat
  await initializeDateFormatting('tr_TR', null);
  
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
          create: (_) => HarvestProvider(
            harvestService: _harvestService,
            seasonService: _seasonService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SeasonProvider(seasonService: _seasonService),
        ),
      ],
      child: MaterialApp(
        title: 'Hal Fiyat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
      ),
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
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkCurrentUser();
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
              Icon(
                Icons.agriculture,
                size: 80,
                color: Color(0xFF2E7D32),
              ),
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