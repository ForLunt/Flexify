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

    final url = _url.text.trim();
    if (!url.startsWith('https://')) {
      _showMessage("L'URL du serveur doit commencer par https://");
      return;
    }

    setState(() => _busy = true);
    try {
      await PairingService().pair(
        serverUrl: url,
        name: _name.text.trim(),
        pairingKey: _key.text.trim(),
      );
      _showMessage('Appairage réussi');
    } catch (e) {
      _showMessage("Échec de l'appairage : $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showPairingDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appairage Flexitrack'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _url,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'URL du serveur'),
              ),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: _key,
                decoration: const InputDecoration(
                  labelText: "Clé d'appairage",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Appairer'),
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
      appBar: AppBar(title: const Text('Flexitrack')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.link_rounded),
            title: const Text('Appairage avec ton coach'),
            subtitle: const Text('Connecte cette app au serveur Flexitrack'),
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