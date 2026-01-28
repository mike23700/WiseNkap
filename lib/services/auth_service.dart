import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Connexion
  Future<(bool success, String? error)> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return (response.user != null, null);
    } on AuthException catch (e) {
      return (false, e.message);
    } catch (e) {
      return (false, 'Une erreur est survenue lors de la connexion');
    }
  }

  /// Inscription 
  Future<(bool success, String? error)> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
  }) async {
    try {
      final authResponse = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'nom': nom.trim(), 
          'prenom': prenom.trim()
        },
      );

      return (authResponse.user != null, null);
    } on AuthException catch (e) {
      return (false, e.message);
    } catch (e) {
      return (false, 'Erreur lors de l\'inscription');
    }
  }

  /// RÉINITIALISATION DU MOT DE PASSE 
  Future<(bool success, String? error)> resetPassword({
    required String email,
  }) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'io.supabase.flutter://reset-callback', 
      );
      return (true, null);
    } on AuthException catch (e) {
      debugPrint('Erreur réinitialisation: ${e.message}');
      return (false, e.message);
    } catch (e) {
      debugPrint('Erreur inattendue: $e');
      return (false, 'Une erreur est survenue');
    }
  }

  /// Déconnexion
  Future<(bool success, String? error)> logout() async {
    try {
      await _supabase.auth.signOut();
      return (true, null);
    } catch (e) {
      return (false, 'Erreur lors de la déconnexion');
    }
  }

  bool get isAuthenticated => _supabase.auth.currentUser != null;
  User? get currentUser => _supabase.auth.currentUser;
}