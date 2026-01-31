import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../services/budget_service.dart';
import '../models/transaction.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetService _budgetService = BudgetService();

  List<Budget> _budgets = [];
  String? _lastError;
  bool _isLoading = false;

  // Getters
  List<Budget> get budgets => _budgets;
  String? get lastError => _lastError;
  bool get isLoading => _isLoading;

  // Fetch budgets
  Future<void> fetchBudgets(String userId) async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      debugPrint('📥 Chargement des budgets pour: $userId');
      final (budgets, error) = await _budgetService.fetchBudgets(userId);

      if (error != null) {
        _lastError = error;
        _budgets = [];
        debugPrint('❌ Erreur lors du chargement: $error');
      } else {
        _budgets = budgets;
        debugPrint('✅ ${_budgets.length} budget(s) chargé(s)');
      }
    } catch (e) {
      _lastError = 'Erreur lors du chargement des budgets: $e';
      _budgets = [];
      debugPrint('❌ EXCEPTION: $_lastError');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add budget
  Future<bool> addBudget({
    required String userId,
    required String categoryId,
    required double limitAmount,
  }) async {
    debugPrint('➕ Création d\'un budget: $limitAmount FCFA');
    _lastError = null;

    final (success, error) = await _budgetService.createBudget(
      userId: userId,
      categoryId: categoryId,
      limitAmount: limitAmount,
    );

    if (success) {
      debugPrint('✅ Budget créé avec succès');
      await fetchBudgets(userId);
    } else {
      _lastError = error;
      debugPrint('❌ Erreur lors de la création: $error');
    }

    return success;
  }

  // Update budget
  Future<bool> updateBudget({
    required String userId,
    required String budgetId,
    required double limitAmount,
  }) async {
    debugPrint('📝 Mise à jour du budget: $budgetId');
    _lastError = null;

    final (success, error) = await _budgetService.updateBudget(
      budgetId: budgetId,
      limitAmount: limitAmount,
    );

    if (success) {
      debugPrint('✅ Budget mis à jour avec succès');
      await fetchBudgets(userId);
    } else {
      _lastError = error;
      debugPrint('❌ Erreur lors de la mise à jour: $error');
    }

    return success;
  }

  // Delete budget
  Future<bool> deleteBudget(String userId, String budgetId) async {
    debugPrint('🗑️ Suppression du budget: $budgetId');
    _lastError = null;

    final (success, error) = await _budgetService.deleteBudget(budgetId);

    if (success) {
      debugPrint('✅ Budget supprimé avec succès');
      await fetchBudgets(userId);
    } else {
      _lastError = error;
      debugPrint('❌ Erreur lors de la suppression: $error');
    }

    return success;
  }

  // Utility: Get budget usage for a category in a specific month
  double getBudgetUsage(
    String categoryId,
    DateTime month,
    List<Transaction> transactions,
  ) {
    double spent = 0;
    for (var tx in transactions) {
      if (tx.type == 'depense' && tx.category?.id == categoryId) {
        if (tx.date.year == month.year && tx.date.month == month.month) {
          spent += tx.amount;
        }
      }
    }
    return spent;
  }

  // Clear data
  void clear() {
    _budgets = [];
    _lastError = null;
    _isLoading = false;
    notifyListeners();
  }
}
