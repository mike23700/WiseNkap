import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:wiseNkap/providers/user_provider.dart';
import 'package:wiseNkap/widgets/home_header_stats.dart';
import 'package:wiseNkap/widgets/add_transaction_sheet.dart';

import 'package:wiseNkap/tabs/list_tab.dart';
import 'package:wiseNkap/tabs/calendar_tab.dart';
import 'package:wiseNkap/tabs/month_tab.dart';
import 'package:wiseNkap/tabs/summary_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeTabIndex = 0;

  final List<Widget> _tabs = [
    const ListTab(),
    const CalendarTab(),
    const MonthTab(),
    const SummaryTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: store.isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
        : Column(
            children: [
              HomeHeaderStats(
                activeTabIndex: _activeTabIndex,
                store: store,
                onTabChanged: (index) => setState(() => _activeTabIndex = index),
              ),
              Expanded(child: _tabs[_activeTabIndex]),
            ],
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFAB(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    title: const Text("Transactions", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    centerTitle: true,
    leading: const Icon(LucideIcons.search, color: Colors.grey),
    actions: [
      IconButton(
        onPressed: () {},
        icon: const Icon(LucideIcons.lightbulb, color: Colors.amber, size: 22),
        tooltip: "Conseils",
      ),      
      IconButton(
        onPressed: () => context.push('/profile'),
        icon: const CircleAvatar(
          radius: 15,
          backgroundColor: Color(0xFFE0E0E0),
          child: Icon(LucideIcons.user, size: 18, color: Colors.grey)
        ),
      )
    ],
  );

  Widget _buildFAB() => FloatingActionButton(
    backgroundColor: const Color(0xFF2D6A4F),
    shape: const CircleBorder(),
    elevation: 2,
    onPressed: () => showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        onTransactionAdded: () => context.read<UserProvider>().fetchData()
      ),
    ),
    child: const Icon(Icons.add, color: Colors.white, size: 40),
  );

  Widget _buildBottomBar() => Container(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          spreadRadius: 2,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: const Color(0xFF2D6A4F).withOpacity(0.08),
      elevation: 0, 
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Icône Calendrier (Home)
            IconButton(
              icon: Icon(LucideIcons.calendar, 
                color: _activeTabIndex == 0 ? const Color(0xFF2D6A4F) : Colors.grey),
              onPressed: () => setState(() => _activeTabIndex = 0),
            ),
            // Icône Charts (Stats)
            IconButton(
              icon: Icon(LucideIcons.barChart2, 
                color: _activeTabIndex == 3 ? const Color(0xFF2D6A4F) : Colors.grey),
              onPressed: () => setState(() => _activeTabIndex = 3),
            ),
            
            const SizedBox(width: 40),

            // Icône Dollar (Budget)
            IconButton(
              icon: Icon(LucideIcons.dollarSign, 
                color: _activeTabIndex == 2 ? const Color(0xFF2D6A4F) : Colors.grey),
              onPressed: () => setState(() => _activeTabIndex = 2),
            ),
            // Icône User (Profil)
            IconButton(
              icon: const Icon(LucideIcons.user, color: Colors.grey), 
              onPressed: () => context.push('/profile'),
            ),
          ],
        ),
      ),
    ),
  );
}