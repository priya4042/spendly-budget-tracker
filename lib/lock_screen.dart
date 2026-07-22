import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'store.dart';
import 'theme.dart';

/// Wraps the app. If a lock (PIN + optional fingerprint) is enabled, the user
/// must unlock before seeing content.
class LockGate extends StatefulWidget {
  final Widget child;
  const LockGate({super.key, required this.child});
  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> {
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    if (!Store.instance.lockEnabled) {
      _unlocked = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    }
  }

  Future<void> _tryBiometric() async {
    try {
      final auth = LocalAuthentication();
      final can = await auth.isDeviceSupported();
      if (!can) return;
      final ok = await auth.authenticate(
        localizedReason: 'Unlock Spendly',
        persistAcrossBackgrounding: true,
      );
      if (ok && mounted) setState(() => _unlocked = true);
    } catch (_) {/* fall back to PIN */}
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;
    return _PinScreen(
      correctPin: Store.instance.pin,
      onBiometric: _tryBiometric,
      onSuccess: () => setState(() => _unlocked = true),
    );
  }
}

class _PinScreen extends StatefulWidget {
  final String correctPin;
  final VoidCallback onBiometric;
  final VoidCallback onSuccess;
  const _PinScreen({required this.correctPin, required this.onBiometric, required this.onSuccess});
  @override
  State<_PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<_PinScreen> {
  String _entry = '';
  bool _error = false;

  void _tap(String d) {
    if (_entry.length >= 4) return;
    setState(() { _entry += d; _error = false; });
    if (_entry.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (_entry == widget.correctPin) {
          widget.onSuccess();
        } else {
          setState(() { _error = true; _entry = ''; });
        }
      });
    }
  }

  void _back() { if (_entry.isNotEmpty) setState(() => _entry = _entry.substring(0, _entry.length - 1)); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGreen,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.lock, color: Colors.white, size: 46),
            const SizedBox(height: 14),
            const Text('Enter PIN', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(_error ? 'Wrong PIN, try again' : 'Spendly is locked',
                style: TextStyle(color: _error ? Colors.yellowAccent : Colors.white70)),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) {
              final filled = i < _entry.length;
              return Container(width: 16, height: 16, margin: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: filled ? Colors.white : Colors.transparent,
                  border: Border.all(color: Colors.white, width: 2)));
            })),
            const Spacer(),
            _keypad(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _keypad() {
    Widget key(String label, {VoidCallback? onTap, IconData? icon}) => SizedBox(
      width: 78, height: 78,
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap ?? () => _tap(label),
        child: Center(
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 26)
              : Text(label, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w500)),
        ),
      ),
    );
    Widget row(List<Widget> c) => Row(mainAxisAlignment: MainAxisAlignment.center,
        children: c.map((w) => Padding(padding: const EdgeInsets.all(6), child: w)).toList());
    return Column(children: [
      row([key('1'), key('2'), key('3')]),
      row([key('4'), key('5'), key('6')]),
      row([key('7'), key('8'), key('9')]),
      row([key('', icon: Icons.fingerprint, onTap: widget.onBiometric), key('0'), key('', icon: Icons.backspace_outlined, onTap: _back)]),
    ]);
  }
}
