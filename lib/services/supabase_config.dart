import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static String get url => _getEnv('SUPABASE_URL');
  static String get anonKey => _getEnv('SUPABASE_ANON_KEY');

  static Future<void> init() async {
    try {
      debugPrint('Chargement des variables d\'environnement...');
      await dotenv.load(fileName: ".env");
      
      debugPrint('Variables d\'environnement chargées');
      debugPrint('URL: ${url.substring(0, 20)}...');
      debugPrint('Clé: ${anonKey.substring(0, 10)}...');
      
      debugPrint('Initialisation de Supabase...');
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: true,
      );
      
      debugPrint('Supabase initialisé avec succès');
    } catch (e, stackTrace) {
      debugPrint('Erreur lors de l\'initialisation de Supabase: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Afficher une erreur plus visible en mode debug
      if (kDebugMode) {
        runApp(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Erreur d\'initialisation',
                      style: TextStyle(fontSize: 24, color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 20),
                    const Text('Vérifiez votre connexion internet et redémarrez l\'application.'),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      rethrow;
    }
  }
  
  static String _getEnv(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception('La variable d\'environnement $key n\'est pas définie');
    }
    return value;
  }
}