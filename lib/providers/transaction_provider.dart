import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionService _transactionService = TransactionService();

  List<Transaction> _transactions = [];
  String? _lastError;
  bool _isLoading = false;

  // Getters
  List<Transaction> get transactions => _transactions;
  String? get lastError => _lastError;
  bool get isLoading => _isLoading;

  // Filtres et groupements
  List<Transaction> get expenseTransactions =>
      _transactions.where((t) => t.type == 'depense').toList();

  List<Transaction> get incomeTransactions =>
      _transactions.where((t) => t.type == 'revenu').toList();

  Map<String, List<Transaction>> get groupedByDate {
    final Map<String, List<Transaction>> grouped = {};
    for (final t in _transactions) {
      final key = t.date.toString().split('T').first;
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(t);
    }
    return grouped;
  }

  // Fetch transactions
  Future<void> fetchTransactions() async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      debugPrint('📥 Chargement des transactions...');
      final (transactions, error) = await _transactionService.getTransactions();

      if (error != null) {
        _lastError = error;
        _transactions = [];
        debugPrint('❌ Erreur lors du chargement: $error');
      } else {
        _transactions = transactions;
        debugPrint('✅ ${_transactions.length} transaction(s) chargée(s)');
      }
    } catch (e) {
      _lastError = 'Erreur lors du chargement des transactions: $e';
      _transactions = [];
      debugPrint('❌ EXCEPTION: $_lastError');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add transaction
  Future<bool> addTransaction({
    required double montant,
    required String type,
    required String categorieId,
    required DateTime date,
    required String description,
  }) async {
    debugPrint('💰 Ajout d\'une transaction: $montant $type');
    _lastError = null;

    final (success, error) = await _transactionService.addTransaction(
      montant: montant,
      type: type,
      categorieId: categorieId,
      date: date,
      description: description,
    );

    if (success) {
      debugPrint('✅ Transaction ajoutée avec succès');
      await fetchTransactions();
    } else {
      _lastError = error;
      debugPrint('❌ Erreur lors de l\'ajout: $error');
    }

    return success;
  }

  // Update transaction
  Future<bool> updateTransaction({
    required String transactionId,
    required double montant,
    required String type,
    required String categorieId,
    required DateTime date,
    required String description,
  }) async {
    debugPrint('✏️ Mise à jour d\'une transaction: $montant $type');
    _lastError = null;

    final (success, error) = await _transactionService.updateTransaction(
      transactionId: transactionId,
      montant: montant,
      type: type,
      categorieId: categorieId,
      date: date,
      description: description,
    );

    if (success) {
      debugPrint('✅ Transaction mise à jour avec succès');
      await fetchTransactions();
    } else {
      _lastError = error;
      debugPrint('❌ Erreur lors de la mise à jour: $error');
    }

    return success;
  }

  // Delete transaction
  Future<bool> deleteTransaction(String transactionId) async {
    debugPrint('🗑️ Suppression d\'une transaction: $transactionId');
    _lastError = null;

    final (success, error) = await _transactionService.deleteTransaction(
      transactionId,
    );

    if (success) {
      debugPrint('✅ Transaction supprimée avec succès');
      await fetchTransactions();
    } else {
      _lastError = error;
      debugPrint('❌ Erreur lors de la suppression: $error');
    }

    return success;
  }

  // Clear data
  void clear() {
    _transactions = [];
    _lastError = null;
    _isLoading = false;
    notifyListeners();
  }
}
