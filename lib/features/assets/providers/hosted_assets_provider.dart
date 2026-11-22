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

/// Les pions que le serveur héberge, par leur clé, prêts à dessiner.
///
/// **Tous, possédés ou non.** Un joueur regarde les pions que pose le MJ :
/// les dessiner ne peut pas dépendre de les avoir achetés. C'est la
/// possession, lue à part dans [ownedAssetKeysProvider], qui décide de ce que
/// le tiroir propose.
///
/// Et **hors ligne aussi** : une partie se joue parfois sans réseau. La liste
/// est gardée dans `remote_cache`, les images sur le disque, et un plateau
/// reste dessiné tant que les deux sont là. Une image qui n'a pas pu
/// descendre laisse le pion à sa forme, le temps du prochain essai.
final hostedAssetsProvider = FutureProvider<Map<String, BoardAsset>>((ref) async {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return const {};

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

  final drawn = await Future.wait(
    assets.map((asset) async {
      final file = files.fileFor(asset.key, asset.imageHash);
      if (online && !await file.exists()) {
        try {
          await files.save(asset.key, asset.imageHash, await api.image(asset.key));
        } on ApiException {
          // Le pion garde sa forme ; la prochaine lecture retentera.
        }
      }

      return BoardAsset(
        key: asset.key,
        name: asset.name,
        kind: BoardTokenKind.parse(asset.kind),
        color: BoardTokenColor.green,
        imageFile: await file.exists() ? file.path : null,
      );
    }),
  );

  return {for (final asset in drawn) asset.key!: asset};
});
