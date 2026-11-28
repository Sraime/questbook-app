import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/remote_providers.dart';
import '../../app/router.dart';
import '../../data/remote/api_exception.dart';
import 'providers/table_providers.dart';

/// The domain whose `https` links the app claims. It is the production API's,
/// whatever API this build talks to: invitation emails only ever point there.
const invitationLinkHost = 'questbook.nextuscorp.com';

/// The server's tokens are base64url, so anything else is not one of ours.
final _codePattern = RegExp(r'^[A-Za-z0-9_-]{1,200}$');

/// The code of an invitation link, or null for any other link.
///
/// Two shapes reach the app: the `https` link of the email, when Android or
/// iOS hands it over directly, and `questbook://invitations/<code>`, from the
/// button of the page the link opens in a browser.
String? invitationCodeOf(Uri uri) {
  final List<String> segments;
  if (uri.scheme == 'https' && uri.host == invitationLinkHost) {
    segments = uri.pathSegments;
  } else if (uri.scheme == 'questbook' && uri.host == 'invitations') {
    segments = ['invitations', ...uri.pathSegments];
  } else {
    return null;
  }

  final parts = segments.where((segment) => segment.isNotEmpty).toList();
  if (parts.length != 2 || parts.first != 'invitations') return null;
  return _codePattern.hasMatch(parts.last) ? parts.last : null;
}

/// Every link the system hands the app, the one it was launched with
/// included. A seam for tests, which have no platform to deliver links.
final incomingLinksProvider = Provider<Stream<Uri>>(
  (ref) => AppLinks().uriLinkStream,
);

/// Where a joined table opens. A seam for tests too: the real router is a
/// global, and tests mount their own screens.
final openJoinedTableProvider = Provider<void Function(String tableId)>(
  (ref) => (tableId) => appRouter.go('/tables/$tableId'),
);

/// The code of an invitation link that has not been spent yet.
///
/// It waits here for as long as it takes: a link can arrive before the player
/// has signed in, or before they have accepted the terms, and must not be lost
/// on the way. [InvitationLinkHandler] spends it once the app itself shows.
final pendingInvitationProvider =
    NotifierProvider<PendingInvitation, String?>(PendingInvitation.new);

class PendingInvitation extends Notifier<String?> {
  @override
  String? build() {
    final subscription = ref.watch(incomingLinksProvider).listen((uri) {
      final code = invitationCodeOf(uri);
      if (code != null) state = code;
    });
    ref.onDispose(subscription.cancel);
    return null;
  }

  /// Hands the code over and forgets it, so it is only ever spent once.
  String? take() {
    final code = state;
    state = null;
    return code;
  }
}

/// Spends a pending invitation code as soon as there is one, and opens the
/// table it joined.
///
/// It sits where only a signed-in account that accepted the terms ever gets,
/// which is the whole point: a link opened before that simply waits.
class InvitationLinkHandler extends ConsumerStatefulWidget {
  const InvitationLinkHandler({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<InvitationLinkHandler> createState() =>
      _InvitationLinkHandlerState();
}

class _InvitationLinkHandlerState extends ConsumerState<InvitationLinkHandler> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // A code that arrived before sign-in is already waiting: no change will
    // come to announce it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _redeemPending());
  }

  Future<void> _redeemPending() async {
    if (_busy || !mounted) return;
    final code = ref.read(pendingInvitationProvider.notifier).take();
    if (code == null) return;

    _busy = true;
    final messenger = ScaffoldMessenger.of(context);
    final openTable = ref.read(openJoinedTableProvider);

    try {
      final table = await ref.read(tableApiProvider).redeemInvitation(code);
      if (!mounted) return;
      refreshTables(ref, tableId: table.id);
      openTable(table.id);
      messenger.showSnackBar(
        SnackBar(content: Text('Tu as rejoint « ${table.title} ».')),
      );
    } on ApiException catch (error) {
      // Déjà utilisée, expirée, déjà à la table : le serveur dit pourquoi,
      // en français, et c'est ce que le joueur doit lire.
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      _busy = false;
    }

    // A second link may have come in while this one was on its way.
    if (mounted) unawaited(_redeemPending());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(pendingInvitationProvider, (previous, code) {
      if (code != null) unawaited(_redeemPending());
    });
    return widget.child;
  }
}
