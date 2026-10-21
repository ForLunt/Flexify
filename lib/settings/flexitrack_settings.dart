import 'package:flutter/material.dart';
import 'package:flexify/settings/flexitrack/pairing_service.dart';

/// La PAGE Flexitrack : aujourd'hui l'appairage, demain l'état de synchro,
/// les séances programmées, le délai d'envoi, etc.
/// Pattern copié sur DataSettings : un Scaffold + une liste de réglages.
class FlexitrackSettings extends StatefulWidget {
  const FlexitrackSettings({super.key});

  @override
  State<FlexitrackSettings> createState() => _FlexitrackSettingsState();
}

class _FlexitrackSettingsState extends State<FlexitrackSettings> {
  // ... tes 3 TextEditingController, _busy, _doPairing, _showMessage
  //     → TOUT ce que je t'ai donné reste identique ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Flexitrack')),
      body: ListView(
        children: [
          // Ta tuile d'appairage — le TextButton.icon devient ListTile,
          // comme les autres pages de réglages Flexify.
          ListTile(
            leading: const Icon(Icons.link_rounded),
            title: const Text('Appairage avec ton coach'),
            subtitle: const Text('Connecte cette app au serveur Flexitrack'),
            onTap: _showPairingDialog,
          ),
          // Demain, ici :
          // ListTile( title: Text('État de synchronisation'), ... ),      // FT-13
          // ListTile( title: Text('Séances programmées'), ... ),          // FT-14
          // SwitchListTile( title: Text('Envoi automatique'), ... ),      // FT-13
        ],
      ),
    );
  }

  // _showPairingDialog : IDENTIQUE à ce que je t'ai donné
  // (le AlertDialog avec les 3 champs, rien ne change)
}