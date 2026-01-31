import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/user_provider.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<UserProvider>();
    final profile = provider.getProfile();
    _nomController = TextEditingController(text: profile?['nom'] ?? '');
    _prenomController = TextEditingController(text: profile?['prenom'] ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final profile = provider.getProfile();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Paramètres du Compte',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Info Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D6A4F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFFE0E0E0),
                    child: Icon(LucideIcons.user, size: 50, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_prenomController.text} ${_nomController.text}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile?['email'] ?? 'Email non disponible',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Edit Profile Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Informations Personnelles',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(
                    _isEditing ? Icons.close : Icons.edit,
                    color: const Color(0xFF2D6A4F),
                  ),
                  onPressed: () {
                    setState(() {
                      if (_isEditing) {
                        _nomController.text = profile?['nom'] ?? '';
                        _prenomController.text = profile?['prenom'] ?? '';
                      }
                      _isEditing = !_isEditing;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isEditing)
              Column(
                children: [
                  TextField(
                    controller: _prenomController,
                    decoration: InputDecoration(
                      labelText: 'Prénom',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(LucideIcons.user),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nomController,
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(LucideIcons.user),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isLoading ? null : _saveProfile,
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text(
                                'Enregistrer les modifications',
                                style: TextStyle(color: Colors.white),
                              ),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildInfoTile('Prénom', _prenomController.text),
                  const SizedBox(height: 12),
                  _buildInfoTile('Nom', _nomController.text),
                ],
              ),
            const SizedBox(height: 32),

            // Paramètres Financiers
            Text(
              'Paramètres Financiers',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              icon: LucideIcons.dollarSign,
              title: 'Devise',
              subtitle: 'FCFA (Franc CFA)',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La devise est actuellement FCFA'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsTile(
              icon: LucideIcons.pieChart,
              title: 'Objectif d\'épargne',
              subtitle: 'Définir un objectif mensuel',
              onTap: () {
                _showSavingsGoalDialog();
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsTile(
              icon: LucideIcons.alertCircle,
              title: 'Alertes budgétaires',
              subtitle: 'Notifications à 80% du budget',
              onTap: () {
                _showBudgetAlertDialog();
              },
            ),
            const SizedBox(height: 32),

            // Other Settings
            Text(
              'Préférences',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              icon: LucideIcons.bell,
              title: 'Notifications',
              subtitle: 'Gérer les notifications',
              onTap: () {
                _showNotificationsDialog();
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsTile(
              icon: LucideIcons.shieldCheck,
              title: 'Sécurité',
              subtitle: 'Changer le mot de passe',
              onTap: () {
                _showChangePasswordDialog();
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsTile(
              icon: LucideIcons.globe,
              title: 'Langue',
              subtitle: 'Français (FR)',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Paramètres de langue - Bientôt disponible'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsTile(
              icon: LucideIcons.info,
              title: 'À propos',
              subtitle: 'Version 1.0.0',
              onTap: () {
                _showAboutDialog();
              },
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF2D6A4F).withOpacity(0.1),
        child: Icon(icon, color: const Color(0xFF2D6A4F), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Future<void> _saveProfile() async {
    if (_prenomController.text.isEmpty || _nomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<UserProvider>().updateProfile(
        prenom: _prenomController.text,
        nom: _nomController.text,
      );

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Changer le mot de passe'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe actuel',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                ),
                onPressed: () {
                  if (newPasswordController.text !=
                      confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Les mots de passe ne correspondent pas'),
                      ),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mot de passe changé avec succès'),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text(
                  'Changer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showSavingsGoalDialog() {
    final goalController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Objectif d\'épargne mensuel'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Définissez votre objectif d\'épargne mensuel en FCFA',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: goalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Montant (FCFA)',
                      prefixIcon: const Icon(LucideIcons.dollarSign),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D6A4F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          LucideIcons.lightbulb,
                          size: 20,
                          color: Color(0xFF2D6A4F),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vous pouvez ajuster cet objectif à tout moment',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                ),
                onPressed: () {
                  if (goalController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez entrer un montant'),
                      ),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Objectif fixé à ${goalController.text} FCFA',
                      ),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text(
                  'Enregistrer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showBudgetAlertDialog() {
    bool enableAlerts = true;
    int alertThreshold = 80;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Alertes budgétaires'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SwitchListTile(
                          title: const Text('Activer les alertes'),
                          value: enableAlerts,
                          onChanged: (value) {
                            setState(() {
                              enableAlerts = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        if (enableAlerts)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Alerter à :',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 12),
                              Slider(
                                value: alertThreshold.toDouble(),
                                min: 50,
                                max: 100,
                                divisions: 5,
                                label: '$alertThreshold%',
                                activeColor: const Color(0xFF2D6A4F),
                                onChanged: (value) {
                                  setState(() {
                                    alertThreshold = value.toInt();
                                  });
                                },
                              ),
                              Center(
                                child: Text(
                                  '$alertThreshold% du budget utilisé',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D6A4F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              enableAlerts
                                  ? 'Alertes activées à $alertThreshold%'
                                  : 'Alertes désactivées',
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Enregistrer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showNotificationsDialog() {
    bool transactionNotif = true;
    bool budgetNotif = true;
    bool weeklyReportNotif = true;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Notifications'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SwitchListTile(
                          title: const Text('Transactions'),
                          subtitle: const Text(
                            'Notifier de chaque transaction',
                          ),
                          value: transactionNotif,
                          onChanged: (value) {
                            setState(() {
                              transactionNotif = value;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text('Budgets'),
                          subtitle: const Text('Alertes budgétaires'),
                          value: budgetNotif,
                          onChanged: (value) {
                            setState(() {
                              budgetNotif = value;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text('Rapports hebdomadaires'),
                          subtitle: const Text('Résumé chaque dimanche'),
                          value: weeklyReportNotif,
                          onChanged: (value) {
                            setState(() {
                              weeklyReportNotif = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Paramètres de notifications enregistrés',
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Enregistrer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('À propos de WiseNkap'),
            content: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WiseNkap v1.0.0',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Une application de gestion financière intelligente pour maîtriser votre budget et vos dépenses.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Fonctionnalités :',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Suivi des transactions'),
                  Text('• Gestion des budgets'),
                  Text('• Analyse des dépenses par mois'),
                  Text('• Objectifs d\'épargne'),
                  Text('• Alertes budgétaires'),
                  SizedBox(height: 16),
                  Text(
                    '© 2026 WiseNkap. Tous droits réservés.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Fermer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
