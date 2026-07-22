import 'store.dart';

/// Tiny localisation helper. `L.t('key')` returns Hindi or English based on the
/// language setting, falling back to English then the key itself.
class L {
  static String t(String key) {
    final lang = Store.instance.lang;
    if (lang == 'hi') return _hi[key] ?? _en[key] ?? key;
    return _en[key] ?? key;
  }

  static const _en = {
    'home': 'Home', 'history': 'History', 'stats': 'Stats', 'more': 'More',
    'totalBalance': 'Total Balance', 'income': 'Income', 'expense': 'Expense',
    'thisMonth': 'This Month', 'entries': 'entries', 'today': 'Today',
    'safeToday': 'Safe to spend today', 'quickAdd': 'Quick add',
    'category': 'Category', 'wallet': 'Wallet', 'note': 'Note (optional)',
    'addExpense': 'Add Expense', 'addIncome': 'Add Income', 'save': 'Save',
    'statistics': 'Statistics', 'spendingByCategory': 'Spending by Category',
    'trend': '6-Month Trend', 'budgets': 'Budgets', 'savingsGoals': 'Savings Goals',
    'udhaar': 'Udhaar', 'billsSubs': 'Bills & Subs', 'recurring': 'Recurring',
    'settings': 'Settings', 'theyOweMe': 'They owe me', 'iOwe': 'I owe',
    'noTxnMonth': 'No transactions this month', 'tapToAdd': 'Tap + to add one',
    'search': 'Search category or note', 'all': 'All', 'calendar': 'Calendar',
    'appearance': 'Appearance', 'darkMode': 'Dark mode', 'security': 'Security',
    'reminders': 'Reminders', 'manage': 'Manage', 'data': 'Data', 'language': 'Language',
    'currency': 'Currency', 'backup': 'Backup & Restore',
  };

  static const _hi = {
    'home': 'होम', 'history': 'इतिहास', 'stats': 'आँकड़े', 'more': 'और',
    'totalBalance': 'कुल शेष', 'income': 'आय', 'expense': 'खर्च',
    'thisMonth': 'इस महीने', 'entries': 'प्रविष्टियाँ', 'today': 'आज',
    'safeToday': 'आज खर्च करने योग्य', 'quickAdd': 'त्वरित जोड़ें',
    'category': 'श्रेणी', 'wallet': 'वॉलेट', 'note': 'नोट (वैकल्पिक)',
    'addExpense': 'खर्च जोड़ें', 'addIncome': 'आय जोड़ें', 'save': 'सेव करें',
    'statistics': 'आँकड़े', 'spendingByCategory': 'श्रेणी अनुसार खर्च',
    'trend': '6-महीने का रुझान', 'budgets': 'बजट', 'savingsGoals': 'बचत लक्ष्य',
    'udhaar': 'उधार', 'billsSubs': 'बिल और सदस्यता', 'recurring': 'आवर्ती',
    'settings': 'सेटिंग्स', 'theyOweMe': 'मुझे देना है', 'iOwe': 'मुझे लेना है',
    'noTxnMonth': 'इस महीने कोई लेनदेन नहीं', 'tapToAdd': 'जोड़ने के लिए + दबाएँ',
    'search': 'श्रेणी या नोट खोजें', 'all': 'सभी', 'calendar': 'कैलेंडर',
    'appearance': 'रूप', 'darkMode': 'डार्क मोड', 'security': 'सुरक्षा',
    'reminders': 'रिमाइंडर', 'manage': 'प्रबंधन', 'data': 'डेटा', 'language': 'भाषा',
    'currency': 'मुद्रा', 'backup': 'बैकअप और रिस्टोर',
  };
}
