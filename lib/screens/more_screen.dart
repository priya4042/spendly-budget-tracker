import 'package:flutter/material.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import 'budgets_screen.dart';
import 'goals_screen.dart';
import 'udhaar_screen.dart';
import 'bills_screen.dart';
import 'settings_screen.dart';
import 'manage_screens.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppC.of(context);
    return ListenableBuilder(
      listenable: Store.instance,
      builder: (context, _) {
        final s = Store.instance;
        return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), children: [
          Text('More', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.text)),
          const SizedBox(height: 16),
          // Udhaar quick summary
          Row(children: [
            _mini(c, 'They owe me', money(s.theyOweMe), kGreen),
            const SizedBox(width: 12),
            _mini(c, 'I owe', money(s.iOwe), kRed),
          ]),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
            children: [
              _tile(context, c, Icons.savings, 'Savings Goals', const Color(0xFF0EA97B), const GoalsScreen()),
              _tile(context, c, Icons.handshake, 'Udhaar', const Color(0xFFAB47BC), const UdhaarScreen()),
              _tile(context, c, Icons.notifications_active, 'Bills & Subs', const Color(0xFFFFA726), const BillsScreen()),
              _tile(context, c, Icons.pie_chart, 'Budgets', const Color(0xFF42A5F5), const BudgetsScreen()),
              _tile(context, c, Icons.repeat, 'Recurring', const Color(0xFF26A69A), const RecurringScreen()),
              _tile(context, c, Icons.settings, 'Settings', const Color(0xFF78909C), const SettingsScreen()),
            ],
          ),
        ]);
      },
    );
  }

  Widget _mini(AppC c, String label, String value, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: c.muted, fontSize: 12)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
    ])));

  Widget _tile(BuildContext context, AppC c, IconData icon, String label, Color color, Widget screen) =>
    GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(width: 42, height: 42,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22)),
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: c.text, fontSize: 15)),
        ]),
      ),
    );
}
