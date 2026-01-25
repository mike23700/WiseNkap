import '../models/transaction.dart';

class FinancialService {
  // Cache des calculs
  final Map<String, dynamic> _cache = {};
  DateTime? _lastCalculation;

  // Réinitialiser le cache
  void clearCache() {
    _cache.clear();
    _lastCalculation = null;
  }

  // Vérifier si le cache est toujours valide (5 minutes)
  bool _isCacheValid() {
    if (_lastCalculation == null) return false;
    return DateTime.now().difference(_lastCalculation!).inMinutes < 5;
  }

  // Calculer les totaux (revenus, dépenses, épargne)
  ({double totalRevenus, double totalDepenses, double epargne}) calculateTotals(
    List<Transaction> transactions,
  ) {
    final cacheKey = 'totals';

    if (_isCacheValid() && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    double totalRevenus = 0;
    double totalDepenses = 0;

    for (var tx in transactions) {
      if (tx.type == 'revenu') {
        totalRevenus += tx.amount;
      } else if (tx.type == 'depense') {
        totalDepenses += tx.amount;
      }
    }

    final result = (
      totalRevenus: totalRevenus,
      totalDepenses: totalDepenses,
      epargne: totalRevenus - totalDepenses,
    );

    _cache[cacheKey] = result;
    _lastCalculation = DateTime.now();
    return result;
  }

  // Compter les transactions par type
  (int depenses, int revenus) countTransactions(
    List<Transaction> transactions,
  ) {
    final cacheKey = 'counts';

    if (_isCacheValid() && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    int depenses = 0;
    int revenus = 0;

    for (var tx in transactions) {
      if (tx.type == 'depense') {
        depenses++;
      } else if (tx.type == 'revenu') {
        revenus++;
      }
    }

    final result = (depenses, revenus);
    _cache[cacheKey] = result;
    _lastCalculation = DateTime.now();
    return result;
  }

  // Compter les mois actifs
  int countActiveMonths(List<Transaction> transactions) {
    final cacheKey = 'activeMonths';

    if (_isCacheValid() && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    if (transactions.isEmpty) return 0;

    final moisUniques =
        transactions.map((t) => "${t.date.year}-${t.date.month}").toSet();

    _cache[cacheKey] = moisUniques.length;
    _lastCalculation = DateTime.now();
    return moisUniques.length;
  }

  // Calculer les dépenses par catégorie
  Map<String, double> calculateExpensesByCategory(
    List<Transaction> transactions,
  ) {
    final cacheKey = 'expensesByCategory';

    if (_isCacheValid() && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    final Map<String, double> result = {};

    for (var tx in transactions) {
      if (tx.type == 'depense' && tx.category != null) {
        final categoryName = tx.category!.name;
        result[categoryName] = (result[categoryName] ?? 0) + tx.amount;
      }
    }

    _cache[cacheKey] = result;
    _lastCalculation = DateTime.now();
    return result;
  }

  // Calculer l'utilisation du budget
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

  // Calculer le pourcentage d'utilisation du budget
  double getBudgetPercentage(double spent, double limit) {
    if (limit <= 0) return 0;
    return (spent / limit * 100).clamp(0, 999);
  }

  // Déterminer l'état du budget (ok, warning, exceeded)
  String getBudgetStatus(double spent, double limit) {
    if (spent > limit) return 'exceeded';
    if (spent > limit * 0.8) return 'warning';
    return 'ok';
  }

  // Calculer les transactions du mois courant
  List<Transaction> getCurrentMonthTransactions(
    List<Transaction> transactions,
  ) {
    final now = DateTime.now();
    return transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();
  }

  // Calculer les dépenses du mois courant
  double getCurrentMonthExpenses(List<Transaction> transactions) {
    final currentMonth = getCurrentMonthTransactions(transactions);
    return currentMonth
        .where((t) => t.type == 'depense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Calculer les revenus du mois courant
  double getCurrentMonthIncome(List<Transaction> transactions) {
    final currentMonth = getCurrentMonthTransactions(transactions);
    return currentMonth
        .where((t) => t.type == 'revenu')
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}
