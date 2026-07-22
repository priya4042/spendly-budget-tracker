import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../l10n.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppC.of(context);
    return ListenableBuilder(
      listenable: Store.instance,
      builder: (context, _) {
        final s = Store.instance;
        final m = s.selectedMonth;
        final data = s.expenseByCategory(m);
        final total = data.fold(0.0, (sum, e) => sum + e.value);
        return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), children: [
          Row(children: [
            Text(L.t('statistics'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.text)),
            const Spacer(),
            IconButton(onPressed: s.prevMonth, icon: Icon(Icons.chevron_left, color: c.text)),
            Text(monthLabel(m), style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
            IconButton(onPressed: s.canGoNext ? s.nextMonth : null,
              icon: Icon(Icons.chevron_right, color: s.canGoNext ? c.text : c.muted.withValues(alpha: 0.3))),
          ]),
          const SizedBox(height: 12),
          _summaryRow(s, m, c),
          const SizedBox(height: 26),
          Text(L.t('trend'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text)),
          const SizedBox(height: 14),
          _trendChart(s, c),
          const SizedBox(height: 28),
          Text(L.t('spendingByCategory'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text)),
          const SizedBox(height: 16),
          if (data.isEmpty) _empty(c) else ...[
            SizedBox(height: 220, child: Stack(alignment: Alignment.center, children: [
              PieChart(PieChartData(sectionsSpace: 3, centerSpaceRadius: 62,
                sections: data.map((e) {
                  final cat = s.categoryDef(e.key, true);
                  final pct = total == 0 ? 0 : (e.value / total * 100);
                  return PieChartSectionData(value: e.value, color: cat.colour, radius: 34,
                    title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                    titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700));
                }).toList())),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Spent', style: TextStyle(color: c.muted, fontSize: 12)),
                Text(money(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kRed)),
              ]),
            ])),
            const SizedBox(height: 20),
            ...data.map((e) => _legend(s, e.key, e.value, total, c)),
          ],
        ]);
      },
    );
  }

  Widget _summaryRow(Store s, DateTime m, AppC c) {
    Widget box(String label, String value, Color color, IconData icon) => Expanded(child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20), const SizedBox(height: 8),
        Text(label, style: TextStyle(color: c.muted, fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w800)),
      ])));
    return Row(children: [
      box(L.t('income'), money(s.monthIncome(m)), kGreen, Icons.arrow_downward),
      const SizedBox(width: 12),
      box(L.t('expense'), money(s.monthExpense(m)), kRed, Icons.arrow_upward),
    ]);
  }

  Widget _trendChart(Store s, AppC c) {
    final data = s.last6MonthsExpense();
    final maxV = data.fold(0.0, (mx, e) => e.value > mx ? e.value : mx);
    return Container(
      height: 200, padding: const EdgeInsets.fromLTRB(8, 20, 12, 8),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16)),
      child: BarChart(BarChartData(
        maxY: maxV == 0 ? 100 : maxV * 1.25,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 26,
            getTitlesWidget: (v, meta) {
              final i = v.toInt();
              if (i < 0 || i >= data.length) return const SizedBox.shrink();
              return Padding(padding: const EdgeInsets.only(top: 6),
                child: Text(DateFormat('MMM').format(data[i].key),
                  style: TextStyle(color: c.muted, fontSize: 11)));
            })),
        ),
        barGroups: [
          for (int i = 0; i < data.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(toY: data[i].value, width: 20, borderRadius: BorderRadius.circular(6),
                color: i == data.length - 1 ? kGreen : kGreen.withValues(alpha: 0.45)),
            ]),
        ],
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (g, gi, rod, ri) =>
              BarTooltipItem(money(rod.toY), const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11))),
        ),
      )),
    );
  }

  Widget _legend(Store s, String name, double value, double total, AppC c) {
    final cat = s.categoryDef(name, true);
    final pct = total == 0 ? 0.0 : value / total * 100;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: cat.colour, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 10),
      Icon(cat.icon, size: 18, color: cat.colour), const SizedBox(width: 8),
      Expanded(child: Text(name, style: TextStyle(fontWeight: FontWeight.w500, color: c.text))),
      Text('${pct.toStringAsFixed(0)}%', style: TextStyle(color: c.muted, fontSize: 12)),
      const SizedBox(width: 12),
      Text(money(value), style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
    ]));
  }

  Widget _empty(AppC c) => Padding(padding: const EdgeInsets.only(top: 30), child: Center(child: Column(children: [
    Icon(Icons.pie_chart_outline, size: 52, color: c.muted.withValues(alpha: 0.5)),
    const SizedBox(height: 12),
    Text('No expenses this month', style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
  ])));
}
