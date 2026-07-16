import 'package:supabase_flutter/supabase_flutter.dart';

import '../infrastructure/storage/shared_preferences_auth_session_store.dart';
import '../services/auth/supabase_auth_service.dart';
import '../services/contracts/auth_service_contract.dart';
import '../services/contracts/harvest_service_contract.dart';
import '../services/contracts/product_service_contract.dart';
import '../services/contracts/season_service_contract.dart';
import '../services/harvest/supabase_harvest_service.dart';
import '../services/product/supabase_product_service.dart';
import '../services/season/supabase_season_service.dart';

class AppDependencies {
  final IAuthService authService;
  final IProductService productService;
  final ISeasonService seasonService;
  final IHarvestService harvestService;

  const AppDependencies({
    required this.authService,
    required this.productService,
    required this.seasonService,
    required this.harvestService,
  });

  factory AppDependencies.supabase({SupabaseClient? client}) {
    final supabaseClient = client ?? Supabase.instance.client;
    final sessionStore = SharedPreferencesAuthSessionStore();

    return AppDependencies(
      authService: SupabaseAuthService(
        client: supabaseClient,
        sessionStore: sessionStore,
      ),
      productService: SupabaseProductService(client: supabaseClient),
      seasonService: SupabaseSeasonService(client: supabaseClient),
      harvestService: SupabaseHarvestService(client: supabaseClient),
    );
  }
}
