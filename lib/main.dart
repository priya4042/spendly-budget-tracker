import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_helper.dart';
import 'store.dart';
import 'theme.dart';
import 'l10n.dart';
import 'notifications.dart';
import 'lock_screen.dart';
import 'add_sheet.dart';
import 'screens/home_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/more_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await Store.instance.load();
  await Notifs.init();
  runApp(const SpendlyApp());
}

class SpendlyApp extends StatelessWidget {
  const SpendlyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Store.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Spendly',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(false),
          darkTheme: buildTheme(true),
          themeMode: Store.instance.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: LockGate(child: const HomeShell()),
        );
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _interstitial = InterstitialManager(showEvery: 4);
  BannerAd? _banner;
  bool _bannerReady = false;

  @override
  void initState() {
    super.initState();
    _interstitial.load();
    _loadBanner();
  }

  void _loadBanner() {
    _banner = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) { if (mounted) setState(() => _bannerReady = true); },
        onAdFailedToLoad: (ad, e) { ad.dispose(); _banner = null; },
      ),
    )..load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    _interstitial.dispose();
    super.dispose();
  }

  Future<void> _openAdd() async {
    final added = await showAddSheet(context);
    if (added == true) _interstitial.maybeShow();
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [HomeScreen(), TransactionsScreen(), StatsScreen(), MoreScreen()];
    return Scaffold(
      body: SafeArea(bottom: false, child: pages[_index]),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_bannerReady && _banner != null)
            SizedBox(
              width: _banner!.size.width.toDouble(),
              height: _banner!.size.height.toDouble(),
              child: AdWidget(ad: _banner!),
            ),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              NavigationDestination(icon: const Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: const Icon(Icons.account_balance_wallet), label: L.t('home')),
              NavigationDestination(icon: const Icon(Icons.receipt_long_outlined),
                  selectedIcon: const Icon(Icons.receipt_long), label: L.t('history')),
              NavigationDestination(icon: const Icon(Icons.pie_chart_outline),
                  selectedIcon: const Icon(Icons.pie_chart), label: L.t('stats')),
              NavigationDestination(icon: const Icon(Icons.grid_view_outlined),
                  selectedIcon: const Icon(Icons.grid_view), label: L.t('more')),
            ],
          ),
        ],
      ),
    );
  }
}
