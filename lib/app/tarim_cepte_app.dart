import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/harvest_provider.dart';
import '../providers/product_provider.dart';
import '../providers/season_provider.dart';
import 'app_dependencies.dart';
import 'session_lifecycle_app.dart';

class TarimCepteApp extends StatelessWidget {
  final AppDependencies dependencies;

  const TarimCepteApp({super.key, required this.dependencies});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: dependencies.authService),
        ),
        ChangeNotifierProvider(
          create:
              (_) =>
                  ProductProvider(productService: dependencies.productService),
        ),
        ChangeNotifierProvider(
          create:
              (_) => HarvestProvider(
                harvestService: dependencies.harvestService,
                seasonService: dependencies.seasonService,
              ),
        ),
        ChangeNotifierProvider(
          create:
              (_) => SeasonProvider(seasonService: dependencies.seasonService),
        ),
      ],
      child: const SessionLifecycleApp(),
    );
  }
}
