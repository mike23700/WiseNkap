import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionService _transactionService = TransactionService();

  List<Transaction> _transactions = [];
  String? _lastError;
  bool _isLoading = false;

  List<Transaction> get transactions => _transactions;
  String? get lastError => _lastError;
  bool get isLoading => _isLoading;

  // Groupement par date pour l'affichage en liste
  Map<String, List<Transaction>> get groupedByDate {
    final Map<String, List<Transaction>> grouped = {};
    for (final t in _transactions) {
      final key = t.date.toString().split(' ').first; // Format YYYY-MM-DD
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(t);
    }
    return grouped;
  }

  Future<void> fetchTransactions() async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      final (transactions, error) = await _transactionService.getTransactions();

      if (error != null) {
        _lastError = error;
      } else {
        _transactions = transactions;
        // Tri du plus récent au plus ancien
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      }
    } catch (e) {
      _lastError = 'Erreur: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTransaction({
    required double montant,
    required String type,
    required String categorieId,
    required DateTime date,
    required String description,
  }) async {
    final (success, error) = await _transactionService.addTransaction(
      montant: montant,
      type: type,
      categorieId: categorieId,
      date: date,
      description: description,
    );

    if (success) {
      await fetchTransactions(); // Rafraîchir la liste
    } else {
      _lastError = error;
    }
    return success;
  }
  
  // --- MISE À JOUR ---
  Future<bool> updateTransaction({
    required String transactionId,
    required double montant,
    required String type,
    required String categorieId,
    required DateTime date,
    required String description,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final (success, error) = await _transactionService.updateTransaction(
      transactionId: transactionId,
      montant: montant,
      type: type,
      categorieId: categorieId,
      date: date,
      description: description,
    );

    if (success) {
      debugPrint('✅ Transaction $transactionId mise à jour');
      await fetchTransactions(); // On recharge tout pour garantir la cohérence
    } else {
      _lastError = error;
      _isLoading = false;
      notifyListeners();
    }

    return success;
  }

  // --- SUPPRESSION ---
  Future<bool> deleteTransaction(String transactionId) async {
    _lastError = null;
    
    final (success, error) = await _transactionService.deleteTransaction(
      transactionId,
    );

    if (success) {
      debugPrint('🗑️ Transaction $transactionId supprimée');
      
      _transactions.removeWhere((t) => t.id == transactionId);
      notifyListeners();
    } else {
      _lastError = error;
      notifyListeners();
    }

    return success;
  }
}