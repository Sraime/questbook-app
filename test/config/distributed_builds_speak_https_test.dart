import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/config/legal_links.dart';
import 'package:questbook/data/remote/board_live_client.dart';

/// L'app ne parle en `https` au VPS que parce qu'une ligne le dit dans chaque
/// workflow, et rien d'autre ne l'impose : le défaut du code est l'adresse en
/// clair de l'émulateur, et le système ne rattrape pas l'erreur — les sockets
/// de `dart:io` ne consultent ni `usesCleartextTraffic` sous Android, ni ATS
/// sous iOS. Une ligne effacée par mégarde partirait donc aux testeurs, ou sur
/// un store, en échouant à chaque appel sans que rien ne l'ait signalé.
void main() {
  group('les builds distribués parlent en https', () {
    for (final workflow in const [
      '.github/workflows/firebase-distribution.yml',
      '.github/workflows/store-publish.yml',
    ]) {
      test(workflow, () {
        final contents = File(workflow).readAsStringSync();
        final url = RegExp(
          r'QUESTBOOK_API_URL:\s*"?([^"\s]+)"?',
        ).firstMatch(contents)?.group(1);

        expect(
          url,
          isNotNull,
          reason:
              '$workflow ne définit plus QUESTBOOK_API_URL : le build '
              'retomberait sur le défaut du code, http://10.0.2.2:3000.',
        );
        expect(
          url,
          startsWith('https://'),
          reason:
              '$workflow distribue un build qui parlerait en clair. Rien ne '
              "l'en empêcherait à l'exécution.",
        );
      });
    }
  });

  group('le plateau en direct suit le schéma de l’API', () {
    test('https donne wss', () {
      final client = BoardLiveClient(
        origin: 'https://questbook.nextuscorp.com',
      );
      expect(client.wsOrigin, 'wss://questbook.nextuscorp.com');
    });

    // Le mode dev atteint l'hôte en clair, et doit continuer de le faire :
    // un `wss` vers une API locale sans certificat ne se connecterait pas.
    test('une API de développement en clair le reste', () {
      final client = BoardLiveClient(origin: 'http://10.0.2.2:3000');
      expect(client.wsOrigin, 'ws://10.0.2.2:3000');
    });
  });

  group('les pages légales ne suivent pas l’API', () {
    // Elles l'ont suivie, et les liens étaient morts sur un poste de
    // développement : les pages sont servies par Caddy, qui ne tourne pas en
    // local — l'API Node répondait `Route not found`. Les faire dépendre de
    // l'étape n'a de toute façon pas de sens, ces textes engageant NextUs de
    // la même manière pour tout le monde.
    for (final page in [LegalLinks.terms, LegalLinks.privacy]) {
      test('$page', () {
        expect(page.scheme, 'https');
        expect(page.host, 'questbook.nextuscorp.com');
      });
    }
  });
}
