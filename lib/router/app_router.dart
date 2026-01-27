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

// 💡 Un petit widget de SplashScreen simple pour l'initialisation
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF2D6A4F)),
      ),
    );
  }
}

GoRouter createRouter(UserProvider userProvider) {
  return GoRouter(
    // 💡 On commence par la racine (neutre) au lieu de l'onboarding
    initialLocation: '/',
    refreshListenable: userProvider,
    redirect: (context, state) {
      final location = state.matchedLocation;

      // 🔄 ÉTAPE 0 : Si le provider charge encore la session ou les SharedPreferences
      // On reste sur le SplashScreen (/)
      if (userProvider.isLoading) {
        return location == '/' ? null : '/';
      }

      final isAuth = userProvider.isAuthenticated;
      final hasOnboarding = userProvider.hasCompletedOnboarding;

      // 1️⃣ ONBOARDING : Si non complété et pas d'auth
      if (!hasOnboarding && !isAuth) {
        if (location == '/onboarding') return null;
        return '/onboarding';
      }

      // 2️⃣ NON CONNECTÉ : Onboarding fait, mais pas d'auth
      if (!isAuth && hasOnboarding) {
        const authRoutes = ['/login', '/register', '/welcome', '/forgot-password'];
        if (authRoutes.contains(location)) return null;
        return '/welcome';
      }

      // 3️⃣ CONNECTÉ : Si authentifié
      if (isAuth) {
        const publicRoutes = ['/', '/welcome', '/login', '/register', '/forgot-password', '/onboarding'];
        if (publicRoutes.contains(location)) return '/home';
      }

      return null;
    },
    routes: [
      // 💡 Route racine pour éviter le flash
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
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