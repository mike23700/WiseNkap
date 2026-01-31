# WiseNkap - Gestion de Budget Personnelle

Une application Flutter permettant aux utilisateurs camerounais 
de gérer leur budget personnel avec facilité et sécurité.

## Fonctionnalités

### Phase 1 (Complétée)
- Authentification sécurisée (Email/Password via Supabase)
- Suivi des dépenses et revenus
- Gestion des catégories
- Tableaux de bord analytiques
- Onboarding utilisateur
- Profil utilisateur

### Phase 2 (Complétée) ✓
- **Onglet Mois** : 
  - Navigation mensuelle (mois précédent/suivant)
  - Statistiques mensuelles (revenus, dépenses, épargne)
  - Graphiques en camembert (répartition revenus/dépenses)
  - Détail des dépenses par catégorie avec barres de progression
  - Alertes visuelles pour budgets dépassés

- **Paramètres du Profil** :
  - Édition du profil (prénom, nom)
  - Gestion des devises (FCFA)
  - Objectif d'épargne mensuel
  - Configuration des alertes budgétaires
  - Notifications (transactions, budgets, rapports hebdomadaires)
  - Gestion de la sécurité (changement mot de passe)
  - Paramètres de langue et informations

- **Système de Budgets** :
  - Création de budgets par catégorie
  - Édition des limites de budget
  - Suppression de budgets
  - Suivi en temps réel de la consommation vs limite
  - Alertes visuelles (vert/orange/rouge)
  - Résumé global des budgets
  - Calcul automatique du pourcentage utilisé

## Architecture
- Clean Architecture
- Provider Pattern pour l'état global
- Backend Supabase (PostgreSQL)
- Services séparatisés (Auth, Transactions, Budgets, Categories, Onboarding)
- Models TypedSafe avec sérialisation

## Structure du projet
```
lib/
├── main.dart                 # Entry point
├── models/                   # Modèles de données
│   ├── budget.dart
│   ├── category.dart
│   └── transaction.dart
├── providers/
│   └── user_provider.dart    # État global
├── screens/                  # Écrans complets
│   ├── auth/
│   ├── home/
│   ├── onboarding/
│   ├── budgets_screen.dart
│   ├── profile_screen.dart
│   └── profile_settings_screen.dart
├── services/                 # Logique métier
│   ├── auth_service.dart
│   ├── budget_service.dart
│   ├── category_service.dart
│   ├── transaction_service.dart
│   └── onboarding_service.dart
├── router/
│   └── app_router.dart       # Navigation
├── tabs/                     # Onglets du dashboard
│   ├── calendar_tab.dart
│   ├── list_tab.dart
│   ├── month_tab.dart
│   └── summary_tab.dart
└── widgets/                  # Composants réutilisables
```

## État du projet

| Phase | Statut | Progrès |
|-------|--------|---------|
| Phase 1 | ✓ | Authentification, profil, transactions, catégories |
| Phase 2 | ✓ | Onglet Mois, Paramètres Profil, Système de Budgets |
| Phase 3 | 📋 | Notifications, Rapports avancés, Syncro cloud |

## Compilation et test

```bash
# Installer les dépendances
flutter pub get

# Analyser le code
flutter analyze

# Compiler
flutter run
```

## Dépendances principales
- `provider`: Gestion d'état
- `supabase_flutter`: Backend et authentification
- `go_router`: Navigation
- `fl_chart`: Graphiques
- `intl`: Localisation
- `lucide_icons`: Icônes