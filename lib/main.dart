import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart'; 
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'providers/user_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/category_provider.dart';
import 'services/financial_service.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    await dotenv.load(fileName: ".env");

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    await initializeDateFormatting('fr_FR', null);

    runApp(
      MultiProvider(
        providers: [
          // On initialise le UserProvider
          ChangeNotifierProvider(create: (_) => UserProvider()..init()),
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
          ChangeNotifierProvider(create: (_) => BudgetProvider()),
          ChangeNotifierProvider(create: (_) => CategoryProvider()),
          Provider(create: (_) => FinancialService()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    FlutterNativeSplash.remove(); 
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text("Erreur lors du démarrage : $e")),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _router = createRouter(userProvider);
    
    _removeSplashWhenReady();
  }

  void _removeSplashWhenReady() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // On attend que le UserProvider ait fini son chargement initial (isLoading == false)
    if (userProvider.isLoading) {
      // On écoute une seule fois le changement de isLoading
      userProvider.addListener(_onUserProviderLoaded);
    } else {
      FlutterNativeSplash.remove();
    }
  }

  void _onUserProviderLoaded() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoading) {
      FlutterNativeSplash.remove();
      userProvider.removeListener(_onUserProviderLoaded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WiseNkap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2D6A4F),
      ),
      routerConfig: _router,
    );
  }
}