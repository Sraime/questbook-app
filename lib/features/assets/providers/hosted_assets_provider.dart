import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/providers.dart';
import '../../../app/remote_providers.dart';
import '../../../data/local/hosted_asset_files.dart';
import '../../../data/local/remote_cache_dao.dart';
import '../../../data/remote/api_exception.dart';
import '../../../data/remote/asset_api.dart';
import '../../game_master/models/board_catalog.dart';
import '../../game_master/models/board_token.dart';

final hostedAssetFilesProvider = FutureProvider<HostedAssetFiles>((ref) async {
  final support = await getApplicationSupportDirectory();
  return HostedAssetFiles(Directory('${support.path}/hosted_assets'));
});

/// Un asset hébergé et sa copie sur l'appareil, `null` tant qu'elle n'est pas
/// descendue.
typedef HostedDownload = ({RemoteAsset asset, String? file});

/// Les assets que le serveur héberge, pions et cartes, avec leur image sur
/// l'appareil.
///
/// **Tous, possédés ou non.** Un joueur regarde les pions que pose le MJ et
/// la carte qu'il a choisie : les dessiner ne peut pas dépendre de les avoir
/// achetés. C'est la possession, lue à part dans [ownedAssetKeysProvider],
/// qui décide de ce que le tiroir propose.
///
/// Et **hors ligne aussi** : une partie se joue parfois sans réseau. La liste
/// est gardée dans `remote_cache`, les images sur le disque, et un plateau
/// reste dessiné tant que les deux sont là. Une image qui n'a pas pu
/// descendre laisse le pion à sa forme et la carte à sa grille, le temps du
/// prochain essai.
final hostedDownloadsProvider =
    FutureProvider<List<HostedDownload>>((ref) async {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return const [];

  final api = ref.watch(assetApiProvider);
  final cache = RemoteCacheDao(ref.watch(appDatabaseProvider));
  final files = await ref.watch(hostedAssetFilesProvider.future);

  List<RemoteAsset> assets;
  var online = true;
  try {
    assets = await api.list();
    await cache.write(
      RemoteCacheDao.hostedAssetsKey,
      user.id,
      [for (final asset in assets) asset.toJson()],
    );
  } on ApiException catch (error) {
    if (!error.isRetryable) rethrow;
    online = false;
    final cached = await cache.read(RemoteCacheDao.hostedAssetsKey, user.id);
    assets = [
      for (final entry in (cached?.data as List? ?? const []).whereType<Map>())
        RemoteAsset.fromJson(entry.cast<String, dynamic>()),
    ];
  }

  return Future.wait(
    assets.map((asset) async {
      final file = files.fileFor(asset.key, asset.imageHash);
      if (online && !await file.exists()) {
        try {
          await files.save(asset.key, asset.imageHash, await api.image(asset.key));
        } on ApiException {
          // L'asset garde son repli ; la prochaine lecture retentera.
        }
      }

      return (asset: asset, file: await file.exists() ? file.path : null);
    }),
  );
});

/// Les pions hébergés, par leur clé, prêts à dessiner.
final hostedAssetsProvider = FutureProvider<Map<String, BoardAsset>>((ref) async {
  final downloads = await ref.watch(hostedDownloadsProvider.future);
  return {
    for (final (:asset, :file) in downloads)
      if (!asset.isMap)
        asset.key: BoardAsset(
          key: asset.key,
          name: asset.name,
          kind: BoardTokenKind.parse(asset.kind),
          color: BoardTokenColor.green,
          imageFile: file,
        ),
  };
});

/// Les cartes hébergées, par leur clé.
///
/// Sans dimensions connues, une carte prend les proportions d'une table :
/// mieux vaut une image un peu étirée qu'un plateau qui ne s'ouvre pas.
final hostedMapsProvider = FutureProvider<Map<String, BoardMap>>((ref) async {
  final downloads = await ref.watch(hostedDownloadsProvider.future);
  return {
    for (final (:asset, :file) in downloads)
      if (asset.isMap)
        asset.key: BoardMap(
          id: asset.key,
          label: asset.name,
          asset: null,
          file: file,
          aspectRatio: switch ((asset.width, asset.height)) {
            (final int w, final int h) when w > 0 && h > 0 => w / h,
            _ => 4 / 3,
          },
        ),
  };
});
