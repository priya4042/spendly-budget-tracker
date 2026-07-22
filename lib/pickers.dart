import 'package:flutter/material.dart';
import 'models.dart';
import 'theme.dart';

/// Small reusable grid pickers for icons and colours, used when creating
/// custom categories and wallets.
class IconPickerRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onPick;
  const IconPickerRow({super.key, required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final c = AppC.of(context);
    return Wrap(spacing: 8, runSpacing: 8, children: kIcons.entries.map((e) {
      final sel = e.key == selected;
      return GestureDetector(
        onTap: () => onPick(e.key),
        child: Container(width: 42, height: 42,
          decoration: BoxDecoration(
            color: sel ? kGreen.withValues(alpha: 0.15) : c.field, shape: BoxShape.circle,
            border: Border.all(color: sel ? kGreen : Colors.transparent, width: 2)),
          child: Icon(e.value, size: 20, color: sel ? kGreen : c.muted)),
      );
    }).toList());
  }
}

class ColorPickerRow extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onPick;
  const ColorPickerRow({super.key, required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 10, runSpacing: 10, children: kColors.map((col) {
      final sel = col == selected;
      return GestureDetector(
        onTap: () => onPick(col),
        child: Container(width: 34, height: 34,
          decoration: BoxDecoration(color: Color(col), shape: BoxShape.circle,
            border: Border.all(color: sel ? Colors.white : Colors.transparent, width: 3),
            boxShadow: sel ? [BoxShadow(color: Color(col).withValues(alpha: 0.6), blurRadius: 8)] : null)),
      );
    }).toList());
  }
}
