import 'package:flexify/l10n/l10n.dart';
import 'package:flexify/settings/flexitrack/pairing_service.dart';
import 'package:flutter/material.dart';

/// La PAGE Flexitrack : aujourd'hui l'appairage, demain l'état de synchro,
/// les séances programmées, le délai d'envoi, etc.
class FlexitrackSettings extends StatefulWidget {
  const FlexitrackSettings({super.key});

  @override
  State<FlexitrackSettings> createState() => _FlexitrackSettingsState();
}

class _FlexitrackSettingsState extends State<FlexitrackSettings> {
  final _url = TextEditingController();
  final _name = TextEditingController();
  final _key = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _url.dispose();
    _name.dispose();
    _key.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _doPairing() async {
    if (_busy) return;
    final l10n = context.l10n;

    final url = _url.text.trim();
    if (!url.startsWith('https://')) {
      _showMessage(l10n.flexitrackHttpsRequired);
      return;
    }

    setState(() => _busy = true);
    try {
      await PairingService().pair(
        serverUrl: url,
        name: _name.text.trim(),
        pairingKey: _key.text.trim(),
      );
      _showMessage(l10n.flexitrackPairingSuccess);
    } catch (e) {
      _showMessage(l10n.flexitrackPairingFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showPairingDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.flexitrackPairingTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _url,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: context.l10n.flexitrackServerUrl,
                ),
              ),
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: context.l10n.flexitrackName,
                ),
              ),
              TextField(
                controller: _key,
                decoration: InputDecoration(
                  labelText: context.l10n.flexitrackPairingKey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.flexitrackCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.flexitrackPair),
          ),
        ],
      ),
    );

    if (confirmed == true) await _doPairing();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(context.l10n.flexitrack)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.link_rounded),
            title: Text(context.l10n.flexitrackPairingTileTitle),
            subtitle: Text(context.l10n.flexitrackPairingTileSubtitle),
            trailing: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _showPairingDialog,
          ),
        ],
      ),
    );
  }
}