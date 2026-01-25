import 'package:flutter/material.dart';
import '../models/category.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Category> _categories = [];
  String? _lastError;
  bool _isLoading = false;

  // Getters
  List<Category> get categories => _categories;
  String? get lastError => _lastError;
  bool get isLoading => _isLoading;

  // Filtered getters
  List<Category> get incomeCategories =>
      _categories.where((c) => c.type == 'revenu').toList();

  List<Category> get expenseCategories =>
      _categories.where((c) => c.type == 'depense').toList();

  // Get category by ID
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Fetch categories
  Future<void> fetchCategories() async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      debugPrint('📥 Chargement des catégories...');
      final data = await _supabase.from('categories').select();
      
      _categories = (data as List)
          .map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList();
      
      debugPrint('✅ ${_categories.length} catégorie(s) chargée(s)');
    } catch (e) {
      _lastError = 'Erreur lors du chargement des catégories: $e';
      _categories = [];
      debugPrint('❌ EXCEPTION: $_lastError');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear data
  void clear() {
    _categories = [];
    _lastError = null;
    _isLoading = false;
    notifyListeners();
  }
}
