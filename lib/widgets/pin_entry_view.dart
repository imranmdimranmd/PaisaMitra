import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/pin_service.dart';

/// PIN dots + numeric keypad. Calls [onComplete] once [PinService.pinLength]
/// digits are entered, then clears itself ready for the next entry.
class PinEntryView extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? error;
  final Future<void> Function(String pin) onComplete;

  const PinEntryView({
    Key? key,
    required this.title,
    required this.onComplete,
    this.subtitle,
    this.error,
  }) : super(key: key);

  @override
  State<PinEntryView> createState() => _PinEntryViewState();
}

class _PinEntryViewState extends State<PinEntryView> {
  String _pin = '';
  bool _busy = false;

  Future<void> _add(String digit) async {
    if (_busy || _pin.length >= PinService.pinLength) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += digit);
    if (_pin.length == PinService.pinLength) {
      _busy = true;
      final entered = _pin;
      try {
        await widget.onComplete(entered);
      } finally {
        if (mounted) {
          setState(() {
            _pin = '';
            _busy = false;
          });
        } else {
          _busy = false;
        }
      }
    }
  }

  void _backspace() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Widget _key(String label) {
    if (label.isEmpty) return const SizedBox(width: 88, height: 72);
    final isBack = label == 'back';
    return SizedBox(
      width: 88,
      height: 72,
      child: Center(
        child: InkResponse(
          onTap: () => isBack ? _backspace() : _add(label),
          radius: 36,
          child: SizedBox(
            width: 64,
            height: 64,
            child: Center(
              child: isBack
                  ? const Icon(Icons.backspace_outlined, size: 26)
                  : Text(
                      label,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];

    return SafeArea(
      child: Column(
        children: [
          const Spacer(flex: 2),
          Icon(Icons.lock_outline, size: 40, color: color),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 22,
            child: Text(
              widget.error ?? widget.subtitle ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.error != null ? Colors.red : Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(PinService.pinLength, (i) {
              final filled = i < _pin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
              );
            }),
          ),
          const Spacer(),
          for (final row in rows)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map(_key).toList(),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
