import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/pin_service.dart';
import 'pin_entry_view.dart';

/// Wraps a page and asks for the PIN before showing it (only if a PIN is set).
/// The page locks again when the app goes to the background.
///
/// Usage: `PinGate(title: 'Income', child: IncomeScreen())`
class PinGate extends StatefulWidget {
  final String title;
  final Widget child;

  const PinGate({Key? key, required this.title, required this.child})
      : super(key: key);

  @override
  State<PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<PinGate> with WidgetsBindingObserver {
  bool? _needsPin;
  bool _unlocked = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _check() async {
    final has = await PinService.instance.hasPin();
    if (mounted) setState(() => _needsPin = has);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden) &&
        _unlocked) {
      setState(() {
        _unlocked = false;
        _error = null;
      });
      _check();
    }
  }

  Future<void> _onPin(String pin) async {
    final result = await PinService.instance.verify(pin);
    if (!mounted) return;
    if (result.ok) {
      setState(() {
        _unlocked = true;
        _error = null;
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _error = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_needsPin == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_needsPin == false || _unlocked) return widget.child;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: PinEntryView(
        title: 'Enter PIN',
        subtitle: 'This page is protected',
        error: _error,
        onComplete: _onPin,
      ),
    );
  }
}
