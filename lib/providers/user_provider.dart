import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class UserProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // État de la date sélectionnée
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // Données financières
  double totalRevenus = 0.0;
  double totalDepenses = 0.0;
  int totalDepensesCount = 0;
  int moisActifs = 0;
  double epargneTotale = 0.0; 
  String displayName = "Chargement...";
  
  // Listes pour l'interface
  Map<String, List<Map<String, dynamic>>> groupedTransactions = {};
  List<Map<String, dynamic>> incomeCategories = [];
  List<Map<String, dynamic>> expenseCategories = [];
  
  bool isLoading = true;

  // Fonction pour mettre à jour la date et rafraîchir les données
  void updateSelectedDate(DateTime newDate) {
    _selectedDate = newDate;
    fetchData(); 
  }

  Future<void> fetchData() async {
    try {
      isLoading = true;
      notifyListeners();

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 1. Charger les catégories (Emojis inclus)
      final catData = await _supabase.from('categories').select();
      final allCats = List<Map<String, dynamic>>.from(catData);
      incomeCategories = allCats.where((c) => c['type'] == 'revenu').toList();
      expenseCategories = allCats.where((c) => c['type'] == 'depense').toList();

      // 2. Définir les limites du mois sélectionné
      final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);

      // 3. Récupérer Profil + TOUTES les transactions (Revenus et Dépenses)
      final results = await Future.wait<dynamic>([
        _supabase.from('profiles').select().eq('id', user.id).maybeSingle(),
        _supabase.from('revenus').select('*, categories(nom, emoji)').eq('user_id', user.id),
        _supabase.from('depenses').select('*, categories(nom, emoji)').eq('user_id', user.id),
      ]);

      // --- TRAITEMENT DU PROFIL ---
      final profileData = results[0] as Map<String, dynamic>?;
      if (profileData != null) {
        String p = profileData['prenom'] ?? '';
        String n = profileData['nom'] ?? '';
        displayName = "$p $n".trim();
        if (displayName.isEmpty) displayName = "Utilisateur";
      }

      // --- TRAITEMENT GLOBAL (Stats Profil) ---
      final allRevs = results[1] as List<dynamic>;
      final allDeps = results[2] as List<dynamic>;

      double globalRev = 0;
      double globalDep = 0;
      for (var r in allRevs) globalRev += (r['montant'] as num).toDouble();
      for (var d in allDeps) globalDep += (d['montant'] as num).toDouble();
      
      totalDepensesCount = allDeps.length;
      epargneTotale = (globalRev - globalDep) > 0 ? (globalRev - globalDep) : 0;

      // --- TRAITEMENT MENSUEL (Filtrage avec correction d'erreur de variable) ---
      final monthlyRevs = allRevs.where((item) {
        DateTime txDate = DateTime.parse(item['date']);
        return txDate.isAfter(firstDay.subtract(const Duration(seconds: 1))) && txDate.isBefore(lastDay);
      }).toList();

      final monthlyDeps = allDeps.where((item) {
        DateTime txDate = DateTime.parse(item['date']);
        return txDate.isAfter(firstDay.subtract(const Duration(seconds: 1))) && txDate.isBefore(lastDay);
      }).toList();

      // Fusionner et trier
      final allFiltered = [
        ...monthlyRevs.map((e) => {...e, 'type': 'revenu'}),
        ...monthlyDeps.map((e) => {...e, 'type': 'depense'}),
      ];
      
      allFiltered.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

      // Groupement par date pour la liste
      Map<String, List<Map<String, dynamic>>> groups = {};
      double resRev = 0;
      double resDep = 0;

      for (var tx in allFiltered) {
        String dateKey = DateFormat('yyyy-MM-dd').format(DateTime.parse(tx['date']));
        groups.putIfAbsent(dateKey, () => []);
        groups[dateKey]!.add(Map<String, dynamic>.from(tx));
        
        double mnt = (tx['montant'] as num).toDouble();
        if (tx['type'] == 'revenu') resRev += mnt; else resDep += mnt;
      }

      totalRevenus = resRev;
      totalDepenses = resDep;
      groupedTransactions = groups;
      
      // Calcul de l'ancienneté
      if (user.createdAt != null) {
        DateTime debut = DateTime.parse(user.createdAt!);
        DateTime maintenant = DateTime.now();
        moisActifs = ((maintenant.year - debut.year) * 12) + maintenant.month - debut.month + 1;
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Erreur fatale Provider: $e");
      isLoading = false;
      notifyListeners();
    }
  }

  // Helper pour l'interface AddTransaction
  List<Map<String, dynamic>> getCategoriesByType(String type) {
    return type == 'revenu' ? incomeCategories : expenseCategories;
  }
}