import 'package:flutter/material.dart';

import '../services/pin_service.dart';
import 'pin_flow_screen.dart';

class SecurityScreen extends StatefulWidget {
  static const routeName = '/security';

  const SecurityScreen({Key? key}) : super(key: key);

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool? _hasPin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final has = await PinService.instance.hasPin();
    if (mounted) setState(() => _hasPin = has);
  }

  Future<void> _open(PinFlowMode mode) async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PinFlowScreen(mode: mode)),
    );
    if (done != true) return;
    await _load();
    if (!mounted) return;
    final text = mode == PinFlowMode.remove
        ? 'PIN removed'
        : mode == PinFlowMode.change
            ? 'PIN changed'
            : 'PIN set. Income page is now locked';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final has = _hasPin;
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: has == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  leading: Icon(
                    has ? Icons.lock : Icons.lock_open,
                    color: has ? Colors.green : Colors.grey,
                  ),
                  title: Text(has ? 'PIN lock is ON' : 'PIN lock is OFF'),
                  subtitle: const Text(
                    'When on, the Income page asks for your PIN every time '
                    'you open it.',
                  ),
                ),
                const Divider(height: 1),
                if (!has)
                  ListTile(
                    leading: const Icon(Icons.pin_outlined),
                    title: const Text('Set PIN'),
                    onTap: () => _open(PinFlowMode.create),
                  )
                else ...[
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Change PIN'),
                    onTap: () => _open(PinFlowMode.change),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_reset),
                    title: const Text('Remove PIN'),
                    onTap: () => _open(PinFlowMode.remove),
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Note: if you forget your PIN, it can only be reset by '
                    'clearing the app data (which deletes your records), so '
                    'take a backup first.',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ),
              ],
            ),
    );
  }
}
