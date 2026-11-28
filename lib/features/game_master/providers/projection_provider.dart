import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/remote_providers.dart';
import '../../../data/local/remote_cache_dao.dart';
import '../../../data/remote/api_exception.dart';
import '../../../data/remote/remote_table.dart';

/// Le lien de projection d'une séance, tel que le MJ peut le recopier.
///
/// Gardé sur l'appareil, parce que le serveur n'en a que l'empreinte : sans
/// cela, rouvrir l'app en pleine partie obligerait à en générer un autre, et
/// l'écran de la salle s'éteindrait avec l'ancien.
///
/// `null` quand il n'y a rien à montrer : jamais généré, arrêté, remplacé
/// depuis un autre appareil, ou séance close.
final projectionLinkProvider = AsyncNotifierProvider.autoDispose
    .family<ProjectionLinkController, ProjectionLink?, String>(
  ProjectionLinkController.new,
);

class ProjectionLinkController extends AsyncNotifier<ProjectionLink?> {
  ProjectionLinkController(this.sessionId);

  final String sessionId;

  String get _key => RemoteCacheDao.projectionKey(sessionId);

  RemoteCacheDao get _cache => RemoteCacheDao(ref.read(appDatabaseProvider));

  String? get _accountId => ref.read(authControllerProvider).value?.id;

  @override
  Future<ProjectionLink?> build() async {
    final accountId = _accountId;
    if (accountId == null) return null;

    final cached = await _cache.read(_key, accountId);
    final data = cached?.data;
    if (data is! Map) return null;
    final link = ProjectionLink.fromJson(data.cast<String, dynamic>());

    if (!link.closesAt.isAfter(DateTime.now())) {
      await _cache.delete(_key, accountId);
      return null;
    }

    // Le serveur dit si le lien vaut encore ; sans réseau, on garde celui de
    // l'appareil, qui est le meilleur renseignement qu'on ait.
    try {
      final active =
          await ref.read(sessionApiProvider).projectionActive(sessionId);
      if (!active) {
        await _cache.delete(_key, accountId);
        return null;
      }
    } on ApiException catch (error) {
      if (!error.isRetryable) rethrow;
    }
    return link;
  }

  /// Un lien neuf. L'ancien, s'il y en avait un, cesse de fonctionner.
  Future<void> generate() async {
    final link = await ref.read(sessionApiProvider).createProjection(sessionId);
    if (_accountId case final accountId?) {
      await _cache.write(_key, accountId, link.toJson());
    }
    state = AsyncData(link);
  }

  Future<void> stop() async {
    await ref.read(sessionApiProvider).stopProjection(sessionId);
    if (_accountId case final accountId?) {
      await _cache.delete(_key, accountId);
    }
    state = const AsyncData(null);
  }
}
