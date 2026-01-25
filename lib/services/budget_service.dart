import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/budget.dart';

class BudgetService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<(List<Budget>, String?)> fetchBudgets(String userId) async {
    try {
      final response = await _supabase
          .from('budgets')
          .select('*, categories(nom, emoji)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final budgets =
          (response as List).map((item) {
            final categoryData = item['categories'] as Map<String, dynamic>;
            return Budget(
              id: item['id'],
              userId: item['user_id'],
              categoryId: item['categorie_id'],
              categoryName: categoryData['nom'] ?? 'Autre',
              emoji: categoryData['emoji'] ?? '📁',
              limitAmount: (item['montant_limite'] as num).toDouble(),
              createdAt: DateTime.parse(item['created_at']),
              updatedAt:
                  item['updated_at'] != null
                      ? DateTime.parse(item['updated_at'])
                      : null,
            );
          }).toList();

      return (budgets, null);
    } catch (e) {
      return (<Budget>[], 'Erreur lors de la récupération des budgets: $e');
    }
  }

  Future<(bool, String?)> createBudget({
    required String userId,
    required String categoryId,
    required double limitAmount,
  }) async {
    try {
      await _supabase.from('budgets').insert({
        'user_id': userId,
        'categorie_id': categoryId,
        'montant_limite': limitAmount,
      });
      return (true, null);
    } catch (e) {
      return (false, 'Erreur lors de la création du budget: $e');
    }
  }

  Future<(bool, String?)> updateBudget({
    required String budgetId,
    required double limitAmount,
  }) async {
    try {
      await _supabase
          .from('budgets')
          .update({'montant_limite': limitAmount})
          .eq('id', budgetId);
      return (true, null);
    } catch (e) {
      return (false, 'Erreur lors de la mise à jour du budget: $e');
    }
  }

  Future<(bool, String?)> deleteBudget(String budgetId) async {
    try {
      await _supabase.from('budgets').delete().eq('id', budgetId);
      return (true, null);
    } catch (e) {
      return (false, 'Erreur lors de la suppression du budget: $e');
    }
  }
}
