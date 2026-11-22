import 'dart:io';
import 'dart:typed_data';

/// Les images des pions hébergés, gardées sur l'appareil.
///
/// Un fichier par pion et par version : `<clé>-<hash>`. Une image remplacée
/// au backoffice change de hash, donc de nom, et se télécharge une fois ;
/// l'ancienne est effacée à ce moment-là.
///
/// Elles ne dépendent pas du compte : ce sont les mêmes pour tout le monde,
/// et une déconnexion ne les efface pas — un plateau doit rester dessiné hors
/// ligne, pour le compte suivant comme pour celui-ci.
class HostedAssetFiles {
  HostedAssetFiles(this.root);

  final Directory root;

  File fileFor(String key, String hash) => File('${root.path}/$key-$hash');

  Future<void> save(String key, String hash, Uint8List bytes) async {
    await root.create(recursive: true);
    final target = fileFor(key, hash);

    // Écrite à côté puis renommée : une coupure au milieu laisserait sinon un
    // fichier tronqué sous le bon nom, que plus rien ne viendrait remplacer.
    final partial = File('${target.path}.part');
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(target.path);

    // Par le nom et non par le chemin : `list()` rend des séparateurs que
    // `fileFor` n'écrit pas forcément, et l'image neuve passerait pour une
    // ancienne.
    final current = '$key-$hash';
    await for (final entry in root.list()) {
      final name = entry.uri.pathSegments.last;
      if (entry is File && name.startsWith('$key-') && name != current) {
        await entry.delete();
      }
    }
  }
}
