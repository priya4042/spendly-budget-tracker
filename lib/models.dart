import 'package:flutter/material.dart';

/// A fixed set of icons (all const, so icon tree-shaking still works).
/// Custom categories and wallets reference these by key.
const Map<String, IconData> kIcons = {
  'food': Icons.restaurant,
  'groceries': Icons.local_grocery_store,
  'transport': Icons.directions_bus,
  'shopping': Icons.shopping_bag,
  'bills': Icons.receipt_long,
  'rent': Icons.home,
  'health': Icons.favorite,
  'fun': Icons.movie,
  'education': Icons.school,
  'travel': Icons.flight,
  'coffee': Icons.local_cafe,
  'fuel': Icons.local_gas_station,
  'phone': Icons.phone_android,
  'gym': Icons.fitness_center,
  'pets': Icons.pets,
  'other': Icons.category,
  'salary': Icons.account_balance_wallet,
  'business': Icons.storefront,
  'gift': Icons.card_giftcard,
  'investment': Icons.trending_up,
  'cash': Icons.payments,
  'bank': Icons.account_balance,
  'card': Icons.credit_card,
  'savings': Icons.savings,
  'wallet': Icons.wallet,
};

IconData iconFor(String key) => kIcons[key] ?? Icons.category;

/// A curated colour palette users can pick from.
const List<int> kColors = [
  0xFFEF5350, 0xFF66BB6A, 0xFF42A5F5, 0xFFAB47BC, 0xFFFFA726,
  0xFF8D6E63, 0xFFEC407A, 0xFF26C6DA, 0xFF7E57C2, 0xFF78909C,
  0xFF26A69A, 0xFFFFCA28, 0xFF5C6BC0, 0xFFD4E157,
];

/// A category (default or user-created). Serializable.
class CatDef {
  final String name;
  final String iconKey;
  final int color;
  final bool isExpense;
  const CatDef(this.name, this.iconKey, this.color, this.isExpense);

  IconData get icon => iconFor(iconKey);
  Color get colour => Color(color);

  Map<String, dynamic> toJson() =>
      {'name': name, 'iconKey': iconKey, 'color': color, 'isExpense': isExpense};
  factory CatDef.fromJson(Map<String, dynamic> j) => CatDef(
      j['name'] ?? 'Other', j['iconKey'] ?? 'other',
      j['color'] ?? 0xFF78909C, j['isExpense'] ?? true);
}

const List<CatDef> defaultExpenseCats = [
  CatDef('Food', 'food', 0xFFEF5350, true),
  CatDef('Groceries', 'groceries', 0xFF66BB6A, true),
  CatDef('Transport', 'transport', 0xFF42A5F5, true),
  CatDef('Shopping', 'shopping', 0xFFAB47BC, true),
  CatDef('Bills', 'bills', 0xFFFFA726, true),
  CatDef('Rent', 'rent', 0xFF8D6E63, true),
  CatDef('Health', 'health', 0xFFEC407A, true),
  CatDef('Fun', 'fun', 0xFF26C6DA, true),
  CatDef('Education', 'education', 0xFF7E57C2, true),
  CatDef('Other', 'other', 0xFF78909C, true),
];

const List<CatDef> defaultIncomeCats = [
  CatDef('Salary', 'salary', 0xFF66BB6A, false),
  CatDef('Business', 'business', 0xFF26A69A, false),
  CatDef('Gift', 'gift', 0xFFEC407A, false),
  CatDef('Investment', 'investment', 0xFF42A5F5, false),
  CatDef('Other', 'other', 0xFF78909C, false),
];

/// A money account (Cash / Bank / Card / custom).
class Wallet {
  final String id;
  final String name;
  final String iconKey;
  final int color;
  Wallet({required this.id, required this.name, required this.iconKey, required this.color});

  IconData get icon => iconFor(iconKey);
  Color get colour => Color(color);

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'iconKey': iconKey, 'color': color};
  factory Wallet.fromJson(Map<String, dynamic> j) => Wallet(
      id: j['id'] ?? 'cash', name: j['name'] ?? 'Cash',
      iconKey: j['iconKey'] ?? 'cash', color: j['color'] ?? 0xFF66BB6A);
}

List<Wallet> get defaultWallets => [
      Wallet(id: 'cash', name: 'Cash', iconKey: 'cash', color: 0xFF66BB6A),
      Wallet(id: 'bank', name: 'Bank', iconKey: 'bank', color: 0xFF42A5F5),
      Wallet(id: 'card', name: 'Card', iconKey: 'card', color: 0xFFAB47BC),
    ];

/// A single income/expense entry.
class Txn {
  final String id;
  final double amount;
  final bool isExpense;
  final String category;
  final String walletId;
  final String note;
  final int timestamp;

  Txn({
    required this.id,
    required this.amount,
    required this.isExpense,
    required this.category,
    required this.walletId,
    required this.note,
    required this.timestamp,
  });

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(timestamp);

  Map<String, dynamic> toJson() => {
        'id': id, 'amount': amount, 'isExpense': isExpense, 'category': category,
        'walletId': walletId, 'note': note, 'timestamp': timestamp,
      };
  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
        id: j['id'] ?? '',
        amount: (j['amount'] ?? 0).toDouble(),
        isExpense: j['isExpense'] ?? true,
        category: j['category'] ?? 'Other',
        walletId: j['walletId'] ?? 'cash',
        note: j['note'] ?? '',
        timestamp: j['timestamp'] ?? 0,
      );
}

/// A savings goal the user contributes towards.
class Goal {
  final String id;
  final String name;
  final double target;
  double saved;
  final String iconKey;
  final int color;
  Goal({required this.id, required this.name, required this.target,
    this.saved = 0, required this.iconKey, required this.color});

  IconData get icon => iconFor(iconKey);
  Color get colour => Color(color);
  double get progress => target <= 0 ? 0 : (saved / target).clamp(0, 1).toDouble();

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'target': target, 'saved': saved, 'iconKey': iconKey, 'color': color};
  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
      id: j['id'] ?? '', name: j['name'] ?? '', target: (j['target'] ?? 0).toDouble(),
      saved: (j['saved'] ?? 0).toDouble(), iconKey: j['iconKey'] ?? 'savings', color: j['color'] ?? 0xFF0EA97B);
}

/// Money lent to or borrowed from another person (udhaar).
class Debt {
  final String id;
  final String person;
  final double amount;
  final bool iLent; // true = they owe me; false = I owe them
  final String note;
  final int timestamp;
  bool settled;
  Debt({required this.id, required this.person, required this.amount, required this.iLent,
    required this.note, required this.timestamp, this.settled = false});

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(timestamp);
  Map<String, dynamic> toJson() => {'id': id, 'person': person, 'amount': amount, 'iLent': iLent,
    'note': note, 'timestamp': timestamp, 'settled': settled};
  factory Debt.fromJson(Map<String, dynamic> j) => Debt(
      id: j['id'] ?? '', person: j['person'] ?? '', amount: (j['amount'] ?? 0).toDouble(),
      iLent: j['iLent'] ?? true, note: j['note'] ?? '', timestamp: j['timestamp'] ?? 0, settled: j['settled'] ?? false);
}

/// A bill / subscription with a monthly due-day and optional reminder.
class Bill {
  final String id;
  final String name;
  final double amount;
  final int dueDay; // 1..28
  final String iconKey;
  final int color;
  bool remind;
  Bill({required this.id, required this.name, required this.amount, required this.dueDay,
    required this.iconKey, required this.color, this.remind = true});

  IconData get icon => iconFor(iconKey);
  Color get colour => Color(color);
  int get notifId => 2000 + (id.hashCode & 0x7fff);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'amount': amount, 'dueDay': dueDay,
    'iconKey': iconKey, 'color': color, 'remind': remind};
  factory Bill.fromJson(Map<String, dynamic> j) => Bill(
      id: j['id'] ?? '', name: j['name'] ?? '', amount: (j['amount'] ?? 0).toDouble(),
      dueDay: j['dueDay'] ?? 1, iconKey: j['iconKey'] ?? 'bills', color: j['color'] ?? 0xFFFFA726,
      remind: j['remind'] ?? true);
}

/// A recurring transaction template that auto-adds each month.
class Recurring {
  final String id;
  final double amount;
  final bool isExpense;
  final String category;
  final String walletId;
  final String note;
  final int dayOfMonth; // 1..28
  String lastApplied; // 'YYYY-MM' of last time it was created

  Recurring({
    required this.id,
    required this.amount,
    required this.isExpense,
    required this.category,
    required this.walletId,
    required this.note,
    required this.dayOfMonth,
    this.lastApplied = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'amount': amount, 'isExpense': isExpense, 'category': category,
        'walletId': walletId, 'note': note, 'dayOfMonth': dayOfMonth, 'lastApplied': lastApplied,
      };
  factory Recurring.fromJson(Map<String, dynamic> j) => Recurring(
        id: j['id'] ?? '',
        amount: (j['amount'] ?? 0).toDouble(),
        isExpense: j['isExpense'] ?? true,
        category: j['category'] ?? 'Other',
        walletId: j['walletId'] ?? 'cash',
        note: j['note'] ?? '',
        dayOfMonth: j['dayOfMonth'] ?? 1,
        lastApplied: j['lastApplied'] ?? '',
      );
}
