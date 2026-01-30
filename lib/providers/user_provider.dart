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
  final TransactionService _transactionService = TransactionService();
  final BudgetService _budgetService = BudgetService();

  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _hasCompletedOnboarding = false;
  Map<String, dynamic>? _profile;
  String? _lastError;

  // Stockage de TOUTES les données
  List<Transaction> _allTransactions = []; 
  List<Budget> _budgets = [];
  List<Category> _categories = [];
  DateTime _selectedDate = DateTime.now();

  // ==========================
  // GETTERS (FILTRÉS PAR DATE)
  // ==========================
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  String? get lastError => _lastError;
  String get displayName => _profile?['nom'] ?? 'Utilisateur';
  String? get email => _profile?['email'];
  String? get userId => _supabase.auth.currentUser?.id;
  DateTime get selectedDate => _selectedDate;
  Map<String, dynamic>? getProfile() => _profile;

  // FILTRE : Retourne uniquement les transactions du mois sélectionné
  List<Transaction> get transactions {
    return _allTransactions.where((t) {
      return t.date.year == _selectedDate.year && 
             t.date.month == _selectedDate.month;
    }).toList();
  }

  List<Budget> get budgets => _budgets;
  List<Category> get categories => _categories;

  // Filtrage catégories
  List<Category> get incomeCategories => _categories.where((c) => c.type == 'revenu').toList();
  List<Category> get expenseCategories => _categories.where((c) => c.type == 'depense').toList();

  // CALCULS FINANCIERS 
  double get totalRevenus => transactions
      .where((t) => t.type == 'revenu')
      .fold(0, (sum, t) => sum + t.amount);

  double get totalDepenses => transactions
      .where((t) => t.type == 'depense')
      .fold(0, (sum, t) => sum + t.amount);

  double get epargneTotale => totalRevenus - totalDepenses;
  
  // Statistiques
  int get totalDepensesCount => transactions.where((t) => t.type == 'depense').length;
  int get totalRevenusCount => transactions.where((t) => t.type == 'revenu').length;
  
  int get moisActifs {
    final months = <String>{};
    for (final tx in _allTransactions) {
      months.add('${tx.date.year}-${tx.date.month}');
    }
    return months.isEmpty ? 1 : months.length;
  }

  // Groupement par date pour ListTab (Basé sur la liste filtrée)
  Map<String, List<Transaction>> get groupedTransactions {
    final Map<String, List<Transaction>> grouped = {};
    for (final t in transactions) {
      final key = t.date.toString().split(' ').first; 
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(t);
    }
    return grouped;
  }

  // ==========================
  // INITIALISATION & AUTH
  // ==========================
  Future<void> init() async {
    try {
      _isLoading = true;
      final session = _supabase.auth.currentSession;
      if (session != null) {
        _isAuthenticated = true;
        await _loadProfile();
        await fetchData();
      }
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    final (success, error) = await _authService.login(email: email, password: password);
    if (success) {
      _isAuthenticated = true;
      await _loadProfile();
      await fetchData();
    } else {
      _lastError = error;
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> register({required String email, required String password, required String nom, required String prenom}) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    final (success, error) = await _authService.register(email: email, password: password, nom: nom, prenom: prenom);
    if (success) {
      _isAuthenticated = true;
      await Future.delayed(const Duration(milliseconds: 800));
      await _loadProfile();
      await fetchData();
    } else {
      _lastError = error;
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  // ==========================
  // PROFIL & ONBOARDING
  // ==========================
  Future<void> _loadProfile() async {
    final (profile, error) = await _onboardingService.getUserProfile();
    if (error == null) {
      _profile = profile;
      _hasCompletedOnboarding = profile?['onboarding_done'] as bool? ?? false;
    }
  }

  Future<bool> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    notifyListeners();
    if (_isAuthenticated) {
      final (success, error) = await _onboardingService.completeOnboarding();
      if (!success) _lastError = error;
      return success;
    }
    return true;
  }

  Future<bool> updateProfile({required String prenom, required String nom}) async {
    try {
      final uid = userId;
      if (uid == null) return false;
      await _supabase.from('profiles').update({'prenom': prenom, 'nom': nom}).eq('id', uid);
      _profile?['prenom'] = prenom;
      _profile?['nom'] = nom;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  // ==========================
  // TRANSACTIONS
  // ==========================
  Future<void> fetchTransactions() async {
    final (data, error) = await _transactionService.getTransactions();
    if (error == null) {
      _allTransactions = data;
      _allTransactions.sort((a, b) => b.date.compareTo(a.date));
    }
    notifyListeners();
  }

  Future<bool> addTransaction({required double montant, required String type, required String categorieId, required DateTime date, required String description}) async {
    final (success, error) = await _transactionService.addTransaction(montant: montant, type: type, categorieId: categorieId, date: date, description: description);
    if (success) await fetchTransactions();
    return success;
  }

  Future<bool> updateTransaction({required String transactionId, required double montant, required String type, required String categorieId, required DateTime date, required String description}) async {
    final (success, error) = await _transactionService.updateTransaction(transactionId: transactionId, montant: montant, type: type, categorieId: categorieId, date: date, description: description);
    if (success) await fetchTransactions();
    return success;
  }

  Future<bool> deleteTransaction(String transactionId) async {
    final (success, error) = await _transactionService.deleteTransaction(transactionId);
    if (success) {
      _allTransactions.removeWhere((t) => t.id == transactionId);
      notifyListeners();
    }
    return success;
  }

  // ==========================
  // BUDGETS
  // ==========================
  Future<void> fetchBudgets() async {
    final uid = userId;
    if (uid == null) return;
    final (b, error) = await _budgetService.fetchBudgets(uid);
    if (error == null) _budgets = b;
    notifyListeners();
  }

  Future<bool> addBudget({required String categoryId, required double limitAmount}) async {
    final uid = userId;
    if (uid == null) return false;
    final (success, error) = await _budgetService.createBudget(userId: uid, categoryId: categoryId, limitAmount: limitAmount);
    if (success) await fetchBudgets();
    return success;
  }

  Future<bool> updateBudget({required String budgetId, required double limitAmount}) async {
    final (success, error) = await _budgetService.updateBudget(budgetId: budgetId, limitAmount: limitAmount);
    if (success) await fetchBudgets();
    return success;
  }

  Future<bool> deleteBudget(String budgetId) async {
    final (success, error) = await _budgetService.deleteBudget(budgetId);
    if (success) await fetchBudgets();
    return success;
  }

  double getBudgetUsage(String categoryId, DateTime month) {
    return _allTransactions
        .where((t) => t.type == 'depense' && 
                      t.category?.id == categoryId && 
                      t.date.year == month.year && 
                      t.date.month == month.month)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // ==========================
  // UTILS
  // ==========================
  Future<void> fetchCategories() async {
    try {
      final data = await _supabase.from('categories').select();
      _categories = (data as List).map((item) => Category.fromJson(item)).toList();
    } catch (e) {
      _lastError = e.toString();
    }
    notifyListeners();
  }

  Future<void> fetchData() async {
    await Future.wait([fetchTransactions(), fetchBudgets(), fetchCategories()]);
  }

  void clearAllData() {
    _profile = null;
    _isAuthenticated = false;
    _hasCompletedOnboarding = false;
    _allTransactions = [];
    _budgets = [];
    _categories = [];
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    clearAllData();
  }

  // Changement de mois : Déclenche la mise à jour des getters filtrés
  void updateSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
}