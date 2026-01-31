import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/profile_settings_screen.dart';
import '../screens/budgets_screen.dart';

GoRouter createRouter(UserProvider userProvider) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: userProvider,
    redirect: (context, state) {
      final location = state.matchedLocation;

      // 🔄 Pendant le chargement, on ne redirige pas pour garder le Splash Natif
      if (userProvider.isLoading) return null;

      final isAuth = userProvider.isAuthenticated;
      final hasOnboarding = userProvider.hasCompletedOnboarding;

      // 1️⃣ CAS CONNECTÉ : Si l'utilisateur est authentifié
      if (isAuth) {
        // Liste des routes publiques où on ne veut plus aller
        const authRoutes = ['/login', '/register', '/welcome', '/forgot-password', '/onboarding'];
        
        // Si on est sur une route d'auth, on force le Home
        if (authRoutes.contains(location)) return '/home';
        
        // Sinon on le laisse naviguer librement
        return null;
      }

      // 2️⃣ CAS NON CONNECTÉ : On vérifie l'onboarding
      if (!hasOnboarding) {
        if (location == '/onboarding') return null;
        return '/onboarding';
      }

      // 3️⃣ CAS NON CONNECTÉ + ONBOARDING FINI : On l'envoie vers Welcome
      const publicRoutes = ['/login', '/register', '/welcome', '/forgot-password'];
      if (!publicRoutes.contains(location)) {
        return '/welcome';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(
        path: '/profile-settings',
        builder: (context, state) => const ProfileSettingsScreen(),
      ),
      GoRoute(path: '/budgets', builder: (context, state) => const BudgetsScreen()),
    ],
  );
}