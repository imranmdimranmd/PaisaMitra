import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/pin_service.dart';
import '../widgets/pin_entry_view.dart';

enum PinFlowMode { create, change, remove }

enum _Step { current, newPin, confirm }

/// Set, change or remove the PIN. Pops with `true` when it succeeds.
class PinFlowScreen extends StatefulWidget {
  final PinFlowMode mode;

  const PinFlowScreen({Key? key, required this.mode}) : super(key: key);

  @override
  State<PinFlowScreen> createState() => _PinFlowScreenState();
}

class _PinFlowScreenState extends State<PinFlowScreen> {
  late _Step _step;
  String? _newPin;
  String? _error;

  @override
  void initState() {
    super.initState();
    _step = widget.mode == PinFlowMode.create ? _Step.newPin : _Step.current;
  }

  String get _appBarTitle {
    switch (widget.mode) {
      case PinFlowMode.create:
        return 'Set PIN';
      case PinFlowMode.change:
        return 'Change PIN';
      case PinFlowMode.remove:
        return 'Remove PIN';
    }
  }

  String get _title {
    switch (_step) {
      case _Step.current:
        return 'Enter current PIN';
      case _Step.newPin:
        return 'Enter new PIN';
      case _Step.confirm:
        return 'Confirm new PIN';
    }
  }

  Future<void> _handle(String pin) async {
    switch (_step) {
      case _Step.current:
        final result = await PinService.instance.verify(pin);
        if (!mounted) return;
        if (!result.ok) {
          HapticFeedback.heavyImpact();
          setState(() => _error = result.message);
          return;
        }
        if (widget.mode == PinFlowMode.remove) {
          await PinService.instance.removePin();
          if (!mounted) return;
          Navigator.of(context).pop(true);
          return;
        }
        setState(() {
          _step = _Step.newPin;
          _error = null;
        });
        return;

      case _Step.newPin:
        setState(() {
          _newPin = pin;
          _step = _Step.confirm;
          _error = null;
        });
        return;

      case _Step.confirm:
        if (pin != _newPin) {
          HapticFeedback.heavyImpact();
          setState(() {
            _newPin = null;
            _step = _Step.newPin;
            _error = "PINs didn't match. Try again.";
          });
          return;
        }
        await PinService.instance.setPin(pin);
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_appBarTitle)),
      body: PinEntryView(
        title: _title,
        subtitle: 'Use a ${PinService.pinLength}-digit PIN',
        error: _error,
        onComplete: _handle,
      ),
    );
  }
}
