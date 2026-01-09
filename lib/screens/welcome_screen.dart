import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Section Haute : Logo et Slogan
              Column(
                children: [
                  // Remplace par ton asset ou une icône temporaire
                  const Icon(
                    Icons.trending_up_rounded,
                    size: 80,
                    color: Color(0xFF2D6A4F),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Spendwise",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Prenez le contrôle de vos finances intelligemment",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              // Section Milieu : Illustration
              // Assure-toi d'avoir ajouté l'image dans ton pubspec.yaml
              Center(
                child: Image.asset(
                  'assets/Wallet.png', 
                  height: 280,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback si l'image n'est pas encore ajoutée
                    return Container(
                      height: 200,
                      width: 200,
                      color: Colors.grey[100],
                      child: const Icon(Icons.account_balance_wallet, size: 100, color: Colors.grey),
                    );
                  },
                ),
              ),

              // Section Basse : Boutons d'action
              Column(
                children: [
                  // Bouton S'inscrire (Plein)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A4F),
                      minimumSize: const Size(double.infinity, 56),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "S'inscrire",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Bouton Connexion (Bordure)
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: const BorderSide(color: Color(0xFF2D6A4F), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Connexion",
                      style: TextStyle(
                        color: Color(0xFF2D6A4F),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}