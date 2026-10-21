import 'package:dio/dio.dart';

/// Résultat d'un appairage réussi : ce que le serveur nous renvoie.
class PairingResult {
  final int subscriberId;
  final String name;
  final String code; // le code d'appareil — précieux, à stocker !

  PairingResult(this.subscriberId, this.name, this.code);
}

/// Erreur métier : message prêt à afficher à l'utilisateur.
class PairingException implements Exception {
  final String message;
  PairingException(this.message);

  @override
  String toString() => message;
}

/// Le "facteur" : il sait parler au serveur Flexitrack, rien d'autre.
/// Il ne connaît ni l'interface, ni la base locale : il transporte.
class PairingService {
  /// Appelle POST /api/pair sur ton Nextcloud.
  Future<PairingResult> pair({
    required String serverUrl,
    required String name,
    required String pairingKey,
    String device = '',
  }) async {
    // dio = la bibliothèque HTTP. On crée un "client" avec une adresse de base.
    final dio = Dio(BaseOptions(
      baseUrl: serverUrl, // ex: https://cloud.xxxx.fr
      connectTimeout: const Duration(seconds: 10),
    ));

    try {
      // La requête POST : on envoie du JSON au serveur.
      final res = await dio.post(
        '/index.php/apps/flexitrack/api/pair',
        data: {
          'pairing_key': pairingKey,
          'name': name,
          'device': device,
        },
        options: Options(contentType: Headers.jsonContentType),
      );

      // Le serveur répond 200 avec le JSON : {"subscriber_id":1,"name":"Marie","code":"..."}
      return PairingResult(
        res.data['subscriber_id'] as int,
        res.data['name'] as String,
        res.data['code'] as String,
      );
    } on DioException catch (e) {
      // Traduction des erreurs techniques en messages humains.
      if (e.response?.statusCode == 401) {
        throw PairingException('Clé d\'appairage invalide ou expirée.');
      }
      throw PairingException('Serveur injoignable : ${e.message}');
    }
  }
}