import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/user_provider.dart';
import '../models/transaction.dart';

class MonthTab extends StatefulWidget {
  const MonthTab({super.key});

  @override
  State<MonthTab> createState() => _MonthTabState();
}

class _MonthTabState extends State<MonthTab> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthSelector(),
          const SizedBox(height: 24),
          _buildMonthStats(provider),
          const SizedBox(height: 24),
          _buildBudgetAlerts(provider),
          const SizedBox(height: 24),
          _buildMonthlyBreakdown(provider),
          const SizedBox(height: 24),
          _buildCategoryDetails(provider),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _selectedMonth = DateTime(
                _selectedMonth.year,
                _selectedMonth.month - 1,
              );
            });
          },
        ),
        Text(
          DateFormat('MMMM yyyy', 'fr_FR').format(_selectedMonth),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            setState(() {
              _selectedMonth = DateTime(
                _selectedMonth.year,
                _selectedMonth.month + 1,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildMonthStats(UserProvider provider) {
    final monthTransactions = _getMonthTransactions(provider);
    double monthRevenue = 0;
    double monthExpense = 0;

    for (var tx in monthTransactions) {
      double amount = tx.amount;
      if (tx.type == 'revenu') {
        monthRevenue += amount;
      } else {
        monthExpense += amount;
      }
    }

    double monthSavings = monthRevenue - monthExpense;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Revenus',
                amount: monthRevenue,
                color: Colors.indigo,
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Dépenses',
                amount: monthExpense,
                color: Colors.orange,
                icon: Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Épargne',
          amount: monthSavings,
          color: monthSavings >= 0 ? Colors.green : Colors.red,
          icon: Icons.savings,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildBudgetAlerts(UserProvider provider) {
    final budgets = provider.budgets;

    if (budgets.isEmpty) {
      return const SizedBox.shrink();
    }

    final exceededBudgets = <dynamic>[];
    final warningBudgets = <dynamic>[];

    for (final budget in budgets) {
      final spent = provider.getBudgetUsage(budget.categoryId, _selectedMonth);
      final percentage = spent / budget.limitAmount;

      if (percentage > 1.0) {
        exceededBudgets.add({
          'budget': budget,
          'spent': spent,
          'percentage': percentage,
        });
      } else if (percentage > 0.8) {
        warningBudgets.add({
          'budget': budget,
          'spent': spent,
          'percentage': percentage,
        });
      }
    }

    if (exceededBudgets.isEmpty && warningBudgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (exceededBudgets.isNotEmpty)
          ...exceededBudgets.map((item) {
            final budget = item['budget'];
            final spent = item['spent'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${budget.emoji} Budget dépassé - ${budget.categoryName}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dépassé de FCFA ${(spent - budget.limitAmount).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        if (warningBudgets.isNotEmpty)
          ...warningBudgets.map((item) {
            final budget = item['budget'];
            final percentage = item['percentage'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${budget.emoji} Budget proche de la limite - ${budget.categoryName}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(percentage * 100).toStringAsFixed(0)}% utilisé',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMonthlyBreakdown(UserProvider provider) {
    final monthTransactions = _getMonthTransactions(provider);
    double monthRevenue = 0;
    double monthExpense = 0;

    for (var tx in monthTransactions) {
      double amount = tx.amount;
      if (tx.type == 'revenu') {
        monthRevenue += amount;
      } else {
        monthExpense += amount;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Répartition',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (monthExpense > 0)
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: monthRevenue,
                    title: 'Revenus\nFCFA ${monthRevenue.toInt()}',
                    color: Colors.indigo,
                    radius: 60,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    value: monthExpense,
                    title: 'Dépenses\nFCFA ${monthExpense.toInt()}',
                    color: Colors.orange,
                    radius: 60,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Aucune transaction ce mois',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryDetails(UserProvider provider) {
    final monthTransactions = _getMonthTransactions(provider);

    // Group by category
    final categoryMap = <String, double>{};
    final categoryEmoji = <String, String>{};

    for (var tx in monthTransactions) {
      if (tx.type == 'depense') {
        String categoryName = tx.category?.name ?? 'Autre';
        String emoji = tx.category?.emoji ?? '📁';
        double amount = tx.amount;

        categoryMap[categoryName] = (categoryMap[categoryName] ?? 0) + amount;
        categoryEmoji[categoryName] = emoji;
      }
    }

    if (categoryMap.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dépenses par catégorie',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Aucune dépense ce mois',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dépenses par catégorie',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...categoryMap.entries.map((entry) {
          String categoryName = entry.key;
          double amount = entry.value;
          String emoji = categoryEmoji[categoryName] ?? '📁';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value:
                              amount /
                              categoryMap.values.reduce((a, b) => a + b),
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(
                            Colors.primaries[categoryMap.keys.toList().indexOf(
                                  categoryName,
                                ) %
                                Colors.primaries.length],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'FCFA ${amount.toInt()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  List<Transaction> _getMonthTransactions(UserProvider provider) {
    return provider.transactions.where((tx) {
      return tx.date.year == _selectedMonth.year &&
          tx.date.month == _selectedMonth.month;
    }).toList();
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isFullWidth;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'FCFA ${amount.toInt()}',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
