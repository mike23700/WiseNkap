import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_config.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  runApp(const SpendwiseApp());
}

class SpendwiseApp extends StatelessWidget {
  const SpendwiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spendwise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2D6A4F),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _supabase = Supabase.instance.client;
  late final Stream<AuthState> _authStateStream;

  @override
  void initState() {
    super.initState();
    _authStateStream = _supabase.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        // Afficher un écran de chargement pendant la vérification
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final session = _supabase.auth.currentSession;
        
        // Si l'utilisateur est connecté, afficher l'écran d'accueil
        if (session != null) {
          return const HomeScreen();
        }
        
        // Sinon, afficher l'écran de bienvenue
        return const WelcomeScreen();
      },
    );
  }
}