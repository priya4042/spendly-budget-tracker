import 'package:flutter/material.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int? _selectedDay;

  Map<int, double> _dailyExpense(DateTime m) {
    final map = <int, double>{};
    for (final t in Store.instance.all) {
      if (t.isExpense && t.date.year == m.year && t.date.month == m.month) {
        map[t.date.day] = (map[t.date.day] ?? 0) + t.amount;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppC.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: ListenableBuilder(listenable: Store.instance, builder: (context, _) {
        final s = Store.instance;
        final m = s.selectedMonth;
        final daily = _dailyExpense(m);
        final maxV = daily.values.fold(0.0, (mx, v) => v > mx ? v : mx);
        final daysInMonth = DateTime(m.year, m.month + 1, 0).day;
        final firstWeekday = DateTime(m.year, m.month, 1).weekday % 7; // 0=Sun
        final cells = <Widget>[];
        for (int i = 0; i < firstWeekday; i++) { cells.add(const SizedBox()); }
        for (int d = 1; d <= daysInMonth; d++) {
          final v = daily[d] ?? 0;
          final intensity = maxV == 0 ? 0.0 : (v / maxV);
          final bg = v == 0 ? c.field : Color.lerp(kGreen.withValues(alpha: 0.18), kRed, intensity)!;
          final sel = _selectedDay == d;
          cells.add(GestureDetector(
            onTap: () => setState(() => _selectedDay = d),
            child: Container(
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10),
                border: sel ? Border.all(color: c.text, width: 2) : null),
              alignment: Alignment.center,
              child: Text('$d', style: TextStyle(
                color: v > 0 && intensity > 0.5 ? Colors.white : c.text,
                fontWeight: v > 0 ? FontWeight.w700 : FontWeight.w400, fontSize: 13)),
            ),
          ));
        }
        return ListView(padding: const EdgeInsets.all(16), children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(onPressed: () => setState(() { s.prevMonth(); _selectedDay = null; }), icon: Icon(Icons.chevron_left, color: c.text)),
            Text(monthLabel(m), style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
            IconButton(onPressed: s.canGoNext ? () => setState(() { s.nextMonth(); _selectedDay = null; }) : null,
              icon: Icon(Icons.chevron_right, color: s.canGoNext ? c.text : c.muted.withValues(alpha: 0.3))),
          ]),
          const SizedBox(height: 8),
          Row(children: ['S','M','T','W','T','F','S'].map((d) =>
            Expanded(child: Center(child: Text(d, style: TextStyle(color: c.muted, fontWeight: FontWeight.w600, fontSize: 12))))).toList()),
          const SizedBox(height: 8),
          GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6, crossAxisSpacing: 6, children: cells),
          const SizedBox(height: 20),
          if (_selectedDay != null)
            Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Text('${_selectedDay!} ${monthLabel(m).split(' ')[0]}', style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
                const Spacer(),
                Text('Spent ${money(daily[_selectedDay!] ?? 0)}', style: const TextStyle(color: kRed, fontWeight: FontWeight.w800)),
              ])),
          const SizedBox(height: 16),
          Row(children: [
            Text('Less', style: TextStyle(color: c.muted, fontSize: 11)),
            const SizedBox(width: 8),
            ...[0.15, 0.4, 0.65, 0.9].map((i) => Container(width: 20, height: 12, margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(color: Color.lerp(kGreen.withValues(alpha: 0.18), kRed, i), borderRadius: BorderRadius.circular(3)))),
            const SizedBox(width: 4),
            Text('More', style: TextStyle(color: c.muted, fontSize: 11)),
          ]),
        ]);
      }),
    );
  }
}
