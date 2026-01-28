import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../services/transaction_service.dart';
import '../services/budget_service.dart';

class UserProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();
  final OnboardingService _onboardingService = OnboardingService();

  // Services pour les données
  final TransactionService _transactionService = TransactionService();
  final BudgetService _budgetService = BudgetService();

  // ==========================
  // ÉTATS (CORE ONLY)
  // ==========================
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _hasCompletedOnboarding = false;

  Map<String, dynamic>? _profile;
  String? _lastError;

  // États pour transactions, budgets, catégories
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<Category> _categories = [];
  DateTime _selectedDate = DateTime.now();

  // ==========================
  // GETTERS (CORE ONLY)
  // ==========================
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  String? get lastError => _lastError;

  String get displayName => _profile?['nom'] ?? 'Utilisateur';
  String? get email => _profile?['email'];
  String? get userId => _supabase.auth.currentUser?.id;

  Map<String, dynamic>? getProfile() => _profile;

  // Getters pour transactions
  List<Transaction> get transactions => _transactions;
  List<Transaction> get expenseTransactions =>
      _transactions.where((t) => t.type == 'depense').toList();
  List<Transaction> get incomeTransactions =>
      _transactions.where((t) => t.type == 'revenu').toList();

  // Getters pour budgets
  List<Budget> get budgets => _budgets;

  // Getters pour catégories
  List<Category> get categories => _categories;
  List<Category> get incomeCategories =>
      _categories.where((c) => c.type == 'revenu').toList();
  List<Category> get expenseCategories =>
      _categories.where((c) => c.type == 'depense').toList();

  // Getters pour calculs financiers
  double get totalRevenus => _transactions
      .where((t) => t.type == 'revenu')
      .fold(0, (sum, t) => sum + t.amount);
  double get totalDepenses => _transactions
      .where((t) => t.type == 'depense')
      .fold(0, (sum, t) => sum + t.amount);
  double get epargneTotale => totalRevenus - totalDepenses;

  // Getters pour comptages
  int get totalDepensesCount =>
      _transactions.where((t) => t.type == 'depense').length;
  int get totalRevenusCount =>
      _transactions.where((t) => t.type == 'revenu').length;

  // Getter pour mois actifs
  int get moisActifs {
    final months = <String>{};
    for (final tx in _transactions) {
      months.add('${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}');
    }
    return months.length;
  }

  // Getter pour transactions groupées par date
  Map<String, List<Transaction>> get groupedTransactions {
    final Map<String, List<Transaction>> grouped = {};
    for (final t in _transactions) {
      final key = t.date.toString().split('T').first;
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(t);
    }
    return grouped;
  }

  // Getter pour date sélectionnée
  DateTime get selectedDate => _selectedDate;

  // ==========================
  // INITIALISATION
  // ==========================
  Future<void> init() async {
    try {
      debugPrint('🔄 Initialisation du UserProvider...');
      final session = _supabase.auth.currentSession;
      if (session != null) {
        debugPrint('✅ Session trouvée pour: ${session.user.email}');
        _isAuthenticated = true;
        await _loadProfile();
        await fetchData();
        debugPrint('✅ Données chargées avec succès');
      } else {
        debugPrint('⚠️ Aucune session trouvée');
      }
    } catch (e) {
      _lastError = 'Erreur lors de l\'initialisation: $e';
      debugPrint('❌ ERREUR INIT: $_lastError');
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('✅ Initialisation terminée');
    }
  }

  // ==========================
  // AUTHENTIFICATION
  // ==========================
  Future<bool> login({required String email, required String password}) async {
    debugPrint('🔑 Tentative de connexion: $email');
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final (success, error) = await _authService.login(
      email: email,
      password: password,
    );

    if (success) {
      debugPrint('✅ Authentification réussie pour: $email');
      _isAuthenticated = true;
      try {
        debugPrint('📥 Chargement du profil...');
        await _loadProfile();
        debugPrint('✅ Profil chargé');

        // NOTE: Les autres providers (TransactionProvider, BudgetProvider,
        // CategoryProvider) seront initialisés par l'écran principal
      } catch (e) {
        _lastError = 'Erreur lors du chargement du profil: $e';
        debugPrint('❌ ERREUR LOGIN: $_lastError');
      }
    } else {
      _lastError = error;
      _isAuthenticated = false;
      debugPrint('❌ Échec de l\'authentification: $error');
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
  
  Future<bool> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
  }) async {
    debugPrint('📝 Tentative d\'inscription: $email');
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final (success, error) = await _authService.register(
      email: email,
      password: password,
      nom: nom,
      prenom: prenom,
    );

    if (success) {
      debugPrint('✅ Inscription Auth réussie');
      _isAuthenticated = true;
      try {
        // ⏱️ On attend 500ms que le trigger SQL crée la ligne dans 'profiles'
        await Future.delayed(const Duration(milliseconds: 500));
        
        debugPrint('📥 Chargement du profil créé par le trigger...');
        await _loadProfile();
        
        // Charger les données initiales (catégories, etc.)
        await fetchData();
        
      } catch (e) {
        _lastError = 'Compte créé, mais erreur de synchronisation profil: $e';
        debugPrint('❌ Erreur post-inscription: $e');
      }
    } else {
      _lastError = error;
      _isAuthenticated = false;
      debugPrint('❌ Échec de l\'inscription: $error');
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    debugPrint('🚪 Déconnexion en cours...');
    try {
      debugPrint('🔌 Appel du service d\'authentification...');
      await _authService.logout();
      debugPrint('✅ Service d\'authentification déconnecté');

      debugPrint('🗑️ Nettoyage des données...');
      clearAllData();

      debugPrint('✅ DÉCONNEXION RÉUSSIE');
    } catch (e) {
      debugPrint('❌ Erreur lors de la déconnexion: $e');
      rethrow;
    }
  }

  // ==========================
  // PROFIL ET ONBOARDING
  // ==========================
  Future<void> _loadProfile() async {
    try {
      debugPrint('📥 Chargement du profil depuis Supabase...');
      final (profile, error) = await _onboardingService.getUserProfile();
      if (error != null) {
        _lastError = error;
        debugPrint('❌ Erreur lors du chargement du profil: $error');
        return;
      }
      _profile = profile;
      _hasCompletedOnboarding = profile?['onboarding_done'] as bool? ?? false;
      debugPrint(
        '✅ Profil chargé: ${profile?['nom'] ?? 'N/A'}, onboarding_done: $_hasCompletedOnboarding',
      );
    } catch (e) {
      _lastError = 'Erreur lors du chargement du profil: $e';
      debugPrint('❌ EXCEPTION: $_lastError');
    }
  }

  Future<bool> completeOnboarding() async {
    debugPrint('🎯 Marquage du onboarding comme complété');
    // Marquer localement comme complété, même si pas encore authentifié
    _hasCompletedOnboarding = true;
    notifyListeners();
    debugPrint('✅ Onboarding marqué localement: $_hasCompletedOnboarding');

    // Essayer de mettre à jour dans Supabase si l'utilisateur est authentifié
    if (_isAuthenticated) {
      debugPrint('📤 Utilisateur authentifié, mise à jour dans Supabase...');
      final (success, error) = await _onboardingService.completeOnboarding();
      if (!success) {
        _lastError = error;
        debugPrint('❌ Erreur Supabase: $error');
        return false;
      }
      debugPrint('✅ Onboarding mis à jour dans Supabase');
    } else {
      debugPrint(
        '⚠️ Utilisateur non authentifié, onboarding sera mis à jour lors de la connexion',
      );
    }
    return true;
  }

  Future<bool> updateProfile({
    required String prenom,
    required String nom,
  }) async {
    debugPrint('📝 Mise à jour du profil: $prenom $nom');
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _lastError = 'Utilisateur non authentifié';
        return false;
      }

      await _supabase
          .from('utilisateurs')
          .update({'prenom': prenom, 'nom': nom})
          .eq('id', userId);

      _profile?['prenom'] = prenom;
      _profile?['nom'] = nom;
      notifyListeners();
      debugPrint('✅ Profil mis à jour avec succès');
      return true;
    } catch (e) {
      _lastError = 'Erreur lors de la mise à jour du profil: $e';
      debugPrint('❌ Erreur: $_lastError');
      return false;
    }
  }

  // ==========================
  // Cleanup (pour les autres providers)
  // ==========================
  void clearAllData() {
    _profile = null;
    _isAuthenticated = false;
    _hasCompletedOnboarding = false;
    _lastError = null;
    _transactions = [];
    _budgets = [];
    _categories = [];
    notifyListeners();
  }

  // ==========================
  // Méthode fetchData pour charger toutes les données
  // ==========================
  Future<void> fetchData() async {
    try {
      debugPrint('📥 Chargement de toutes les données...');
      await Future.wait([
        fetchTransactions(),
        fetchBudgets(),
        fetchCategories(),
      ]);
      debugPrint('✅ Toutes les données chargées');
    } catch (e) {
      _lastError = 'Erreur lors du chargement des données: $e';
      debugPrint('❌ ERREUR: $_lastError');
    }
    notifyListeners();
  }

  // ==========================
  // TRANSACTIONS
  // ==========================
  Future<void> fetchTransactions() async {
    try {
      debugPrint('📥 Chargement des transactions...');
      final (transactions, error) = await _transactionService.getTransactions();

      if (error != null) {
        _lastError = error;
        _transactions = [];
        debugPrint('❌ Erreur: $error');
      } else {
        _transactions = transactions;
        debugPrint('✅ ${_transactions.length} transaction(s) chargée(s)');
      }
    } catch (e) {
      _lastError = 'Erreur: $e';
      _transactions = [];
      debugPrint('❌ EXCEPTION: $_lastError');
    }
    notifyListeners();
  }

  Future<bool> addTransaction({
    required double montant,
    required String type,
    required String categorieId,
    required DateTime date,
    required String description,
  }) async {
    debugPrint('💰 Ajout transaction: $montant $type');
    final (success, error) = await _transactionService.addTransaction(
      montant: montant,
      type: type,
      categorieId: categorieId,
      date: date,
      description: description,
    );

    if (success) {
      await fetchTransactions();
    } else {
      _lastError = error;
    }
    return success;
  }

  Future<bool> updateTransaction({
    required String transactionId,
    required double montant,
    required String type,
    required String categorieId,
    required DateTime date,
    required String description,
  }) async {
    debugPrint('✏️ Mise à jour transaction: $transactionId');
    final (success, error) = await _transactionService.updateTransaction(
      transactionId: transactionId,
      montant: montant,
      type: type,
      categorieId: categorieId,
      date: date,
      description: description,
    );

    if (success) {
      await fetchTransactions();
    } else {
      _lastError = error;
    }
    return success;
  }

  Future<bool> deleteTransaction(String transactionId) async {
    debugPrint('🗑️ Suppression transaction: $transactionId');
    final (success, error) = await _transactionService.deleteTransaction(
      transactionId,
    );

    if (success) {
      await fetchTransactions();
    } else {
      _lastError = error;
    }
    return success;
  }

  // ==========================
  // BUDGETS
  // ==========================
  Future<void> fetchBudgets() async {
    try {
      final uid = userId;
      if (uid == null) return;

      debugPrint('📥 Chargement des budgets...');
      final (budgets, error) = await _budgetService.fetchBudgets(uid);

      if (error != null) {
        _lastError = error;
        _budgets = [];
        debugPrint('❌ Erreur: $error');
      } else {
        _budgets = budgets;
        debugPrint('✅ ${_budgets.length} budget(s) chargé(s)');
      }
    } catch (e) {
      _lastError = 'Erreur: $e';
      _budgets = [];
      debugPrint('❌ EXCEPTION: $_lastError');
    }
    notifyListeners();
  }

  Future<bool> addBudget({
    required String categoryId,
    required double limitAmount,
  }) async {
    debugPrint('➕ Création budget: $limitAmount');
    final uid = userId;
    if (uid == null) return false;

    final (success, error) = await _budgetService.createBudget(
      userId: uid,
      categoryId: categoryId,
      limitAmount: limitAmount,
    );

    if (success) {
      await fetchBudgets();
    } else {
      _lastError = error;
    }
    return success;
  }

  Future<bool> updateBudget({
    required String budgetId,
    required double limitAmount,
  }) async {
    debugPrint('📝 Mise à jour budget: $budgetId');
    final uid = userId;
    if (uid == null) return false;

    final (success, error) = await _budgetService.updateBudget(
      budgetId: budgetId,
      limitAmount: limitAmount,
    );

    if (success) {
      await fetchBudgets();
    } else {
      _lastError = error;
    }
    return success;
  }

  Future<bool> deleteBudget(String budgetId) async {
    debugPrint('🗑️ Suppression budget: $budgetId');
    final uid = userId;
    if (uid == null) return false;

    final (success, error) = await _budgetService.deleteBudget(budgetId);

    if (success) {
      await fetchBudgets();
    } else {
      _lastError = error;
    }
    return success;
  }

  double getBudgetUsage(String categoryId, DateTime month) {
    double spent = 0;
    for (var tx in _transactions) {
      if (tx.type == 'depense' && tx.category?.id == categoryId) {
        if (tx.date.year == month.year && tx.date.month == month.month) {
          spent += tx.amount;
        }
      }
    }
    return spent;
  }

  // ==========================
  // CATÉGORIES
  // ==========================
  Future<void> fetchCategories() async {
    try {
      debugPrint('📥 Chargement des catégories...');
      final data = await _supabase.from('categories').select();

      _categories =
          (data as List)
              .map((item) => Category.fromJson(item as Map<String, dynamic>))
              .toList();

      debugPrint('✅ ${_categories.length} catégorie(s) chargée(s)');
    } catch (e) {
      _lastError = 'Erreur: $e';
      _categories = [];
      debugPrint('❌ EXCEPTION: $_lastError');
    }
    notifyListeners();
  }

  // ==========================
  // DATE SELECTION
  // ==========================
  void updateSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
}
