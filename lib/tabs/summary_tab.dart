import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/user_provider.dart';
import '../models/transaction.dart';

class SummaryTab extends StatefulWidget {
  const SummaryTab({super.key});

  @override
  State<SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<SummaryTab> {
  String _selectedPeriod = 'mois'; // mois, trimestre, annee

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final totalRevenus = provider.totalRevenus;
    final totalDepenses = provider.totalDepenses;
    final epargneTotale = provider.epargneTotale;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée disponible',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des transactions pour voir l\'analyse',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cartes de résumé financier
          _SummaryCardsSection(
            totalRevenus: totalRevenus,
            totalDepenses: totalDepenses,
            epargneTotale: epargneTotale,
          ),
          const SizedBox(height: 24),

          // Sélecteur de période
          _PeriodSelector(
            selectedPeriod: _selectedPeriod,
            onPeriodChanged: (period) {
              setState(() => _selectedPeriod = period);
            },
          ),
          const SizedBox(height: 24),

          // Graphique circulaire - Répartition des dépenses
          if (totalDepenses > 0) ...[
            Text(
              'Répartition des dépenses',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _ExpensesPieChart(provider: provider),
            const SizedBox(height: 24),
          ],

          // Graphique en barres - Comparaison Revenus/Dépenses
          Text(
            'Revenus vs Dépenses',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _RevenueVsExpensesChart(
            totalRevenus: totalRevenus,
            totalDepenses: totalDepenses,
          ),
          const SizedBox(height: 24),

          // Graphique linéaire - Évolution temporelle
          Text(
            'Évolution temporelle',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _TimelineChart(
            transactions: provider.transactions,
            period: _selectedPeriod,
          ),
          const SizedBox(height: 24),

          // Détails des catégories
          Text(
            'Dépenses par catégorie',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _CategoryBreakdown(provider: provider),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// Cartes de résumé
class _SummaryCardsSection extends StatelessWidget {
  final double totalRevenus;
  final double totalDepenses;
  final double epargneTotale;

  const _SummaryCardsSection({
    required this.totalRevenus,
    required this.totalDepenses,
    required this.epargneTotale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Revenus',
                amount: totalRevenus,
                color: Colors.indigo,
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Dépenses',
                amount: totalDepenses,
                color: Colors.orange,
                icon: Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          label: 'Épargne totale',
          amount: epargneTotale,
          color: epargneTotale >= 0 ? Colors.green : Colors.red,
          icon: Icons.savings,
          isFullWidth: true,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isFullWidth;

  const _SummaryCard({
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'FCFA ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => ' ')}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Sélecteur de période
class _PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PeriodButton(
          label: 'Mois',
          value: 'mois',
          isSelected: selectedPeriod == 'mois',
          onPressed: () => onPeriodChanged('mois'),
        ),
        const SizedBox(width: 8),
        _PeriodButton(
          label: 'Trimestre',
          value: 'trimestre',
          isSelected: selectedPeriod == 'trimestre',
          onPressed: () => onPeriodChanged('trimestre'),
        ),
        const SizedBox(width: 8),
        _PeriodButton(
          label: 'Année',
          value: 'annee',
          isSelected: selectedPeriod == 'annee',
          onPressed: () => onPeriodChanged('annee'),
        ),
      ],
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onPressed;

  const _PeriodButton({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[200],
        foregroundColor:
            isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
        elevation: isSelected ? 4 : 0,
      ),
      child: Text(label),
    );
  }
}

// Graphique circulaire
class _ExpensesPieChart extends StatelessWidget {
  final UserProvider provider;

  const _ExpensesPieChart({required this.provider});

  Map<String, double> _getCategoryExpenses() {
    final Map<String, double> categoryExpenses = {};

    for (final tx in provider.transactions) {
      if (tx.type != 'depense') continue;

      final categoryName = tx.category?.name ?? 'Autre';
      final amount = tx.amount;

      categoryExpenses[categoryName] =
          (categoryExpenses[categoryName] ?? 0) + amount;
    }

    return categoryExpenses;
  }

  @override
  Widget build(BuildContext context) {
    final categoryExpenses = _getCategoryExpenses();
    if (categoryExpenses.isEmpty) {
      return const Center(child: Text('Pas de dépenses'));
    }

    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: List.generate(categoryExpenses.length, (index) {
            final entry = categoryExpenses.entries.toList()[index];
            final total = categoryExpenses.values.fold(0.0, (a, b) => a + b);
            final percentage = (entry.value / total * 100);

            return PieChartSectionData(
              value: entry.value,
              title: '${percentage.toStringAsFixed(1)}%',
              color: colors[index % colors.length],
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          }),
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }
}

// Graphique en barres
class _RevenueVsExpensesChart extends StatelessWidget {
  final double totalRevenus;
  final double totalDepenses;

  const _RevenueVsExpensesChart({
    required this.totalRevenus,
    required this.totalDepenses,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = [totalRevenus, totalDepenses].reduce((a, b) => a > b ? a : b);
    final padding = maxY * 0.2;

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          maxY: maxY + padding,
          minY: 0,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(),
            topTitles: AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const labels = ['Revenus', 'Dépenses'];
                  return Text(labels[value.toInt()]);
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${(value / 1000).toStringAsFixed(0)}K',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: totalRevenus,
                  color: Colors.indigo,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: totalDepenses,
                  color: Colors.orange,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Graphique linéaire - Évolution temporelle
class _TimelineChart extends StatelessWidget {
  final List<Transaction> transactions;
  final String period;

  const _TimelineChart({required this.transactions, required this.period});

  List<FlSpot> _getTimelineData() {
    final Map<String, double> balanceByDate = {};
    double runningBalance = 0;

    final sorted = List<Transaction>.from(transactions);
    sorted.sort((a, b) => a.date.compareTo(b.date));

    for (final tx in sorted) {
      final date = tx.date.toString().split('T').first;
      final amount = tx.amount;
      final type = tx.type;

      runningBalance += (type == 'revenu' ? amount : -amount);
      balanceByDate[date] = runningBalance;
    }

    // Convertir en FlSpot avec index
    final spots = <FlSpot>[];
    int index = 0;
    for (final balance in balanceByDate.values) {
      spots.add(FlSpot(index.toDouble(), balance));
      index++;
    }

    if (spots.isEmpty) {
      return [FlSpot(0, 0)];
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final spots = _getTimelineData();
    if (spots.isEmpty) {
      return const Center(child: Text('Pas de données'));
    }

    final maxY = spots.fold<double>(
      0,
      (max, spot) => spot.y > max ? spot.y : max,
    );
    final minY = spots.fold<double>(
      0,
      (min, spot) => spot.y < min ? spot.y : min,
    );
    final padding = (maxY - minY).abs() * 0.2;

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(),
            topTitles: AxisTitles(),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    Theme.of(context).colorScheme.primary.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Détails des catégories
class _CategoryBreakdown extends StatelessWidget {
  final UserProvider provider;

  const _CategoryBreakdown({required this.provider});

  Map<String, double> _getCategoryExpenses() {
    final Map<String, double> categoryExpenses = {};

    for (final tx in provider.transactions) {
      if (tx.type != 'depense') continue;

      final categoryName = tx.category?.name ?? 'Autre';
      final amount = tx.amount;

      categoryExpenses[categoryName] =
          (categoryExpenses[categoryName] ?? 0) + amount;
    }

    // Trier par montant décroissant
    final sorted = categoryExpenses.entries.toList();
    sorted.sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted);
  }

  @override
  Widget build(BuildContext context) {
    final categoryExpenses = _getCategoryExpenses();

    if (categoryExpenses.isEmpty) {
      return const Center(child: Text('Pas de dépenses par catégorie'));
    }

    final total = categoryExpenses.values.fold(0.0, (a, b) => a + b);

    return Column(
      children:
          categoryExpenses.entries.map((entry) {
            final percentage = (entry.value / total * 100);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text(
                        'FCFA ${entry.value.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(
                        Colors.primaries[entry.key.hashCode %
                            Colors.primaries.length],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
