import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../widgets/add_transaction_sheet.dart';
import '../tabs/list_tab.dart'; // Import de ton nouvel onglet

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeTabIndex = 0; // Index pour gérer l'onglet actif

  // Simulation des autres onglets pour éviter les erreurs
  final List<Widget> _tabs = [
    const ListTab(),
    const Center(child: Text("Calendrier (À venir)")),
    const Center(child: Text("Mois (À venir)")),
    const Center(child: Text("Résumé (À venir)")),
  ];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: store.isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
        : Column(
            children: [
              _buildDateSelector(),
              _buildTabsHeader(),
              _buildGlobalSummary(store),
              Expanded(
                child: _tabs[_activeTabIndex], // Affiche l'onglet sélectionné
              ),
            ],
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFAB(context),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    title: const Text("Transactions", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    centerTitle: true,
    leading: const Icon(LucideIcons.search, color: Colors.grey),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 15),
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: const CircleAvatar(
            radius: 15,
            backgroundColor: Color(0xFFE0E0E0),
            child: Icon(LucideIcons.user, size: 18, color: Colors.grey)
          ),
        ),
      )
    ],
  );

  Widget _buildDateSelector() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.chevron_left, color: Colors.grey),
      const SizedBox(width: 10),
      Text(DateFormat('MMM yyyy', 'fr_FR').format(DateTime.now()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      const SizedBox(width: 10),
      const Icon(Icons.chevron_right, color: Colors.grey),
    ]),
  );

  Widget _buildTabsHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround, 
      children: [
        _tabButton("Liste", 0),
        _tabButton("Calendrier", 1),
        _tabButton("Mois", 2),
        _tabButton("Résumé", 3),
      ]
    ),
  );

  Widget _tabButton(String title, int index) {
    bool isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Column(
        children: [
          Text(title, style: TextStyle(
            color: isActive ? const Color(0xFF2D6A4F) : Colors.grey, 
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal
          )),
          if (isActive) Container(margin: const EdgeInsets.only(top: 5), height: 2, width: 30, color: const Color(0xFF2D6A4F))
        ],
      ),
    );
  }

  Widget _buildGlobalSummary(UserProvider store) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: Colors.grey[200]!))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _SummaryItem(label: "Revenus", value: store.totalRevenus, color: Colors.indigo),
      _SummaryItem(label: "Dépenses", value: store.totalDepenses, color: Colors.orange),
      _SummaryItem(label: "Total", value: store.totalRevenus - store.totalDepenses, color: const Color(0xFF2D6A4F)),
    ]),
  );

  Widget _buildFAB(BuildContext context) => FloatingActionButton(
    backgroundColor: const Color(0xFF2D6A4F),
    onPressed: () => showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        onTransactionAdded: () => context.read<UserProvider>().fetchData(),
      ),
    ),
    child: const Icon(Icons.add, color: Colors.white, size: 30),
  );

  Widget _buildBottomBar(BuildContext context) => BottomAppBar(
    shape: const CircularNotchedRectangle(),
    notchMargin: 8,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const Icon(LucideIcons.calendar, color: Color(0xFF2D6A4F)),
        const Icon(LucideIcons.barChart2, color: Colors.grey),
        const SizedBox(width: 40), 
        const Icon(LucideIcons.dollarSign, color: Colors.grey),
        IconButton(
          icon: const Icon(LucideIcons.user, color: Colors.grey),
          onPressed: () => Navigator.pushNamed(context, '/profile'),
        ),
      ],
    ),
  );
}

class _SummaryItem extends StatelessWidget {
  final String label; final double value; final Color color;
  const _SummaryItem({required this.label, required this.value, required this.color});
  @override Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
    Text(value.toInt().toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
  ]);
}