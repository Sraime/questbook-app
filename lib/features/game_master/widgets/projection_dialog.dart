import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/remote/api_exception.dart';
import '../../../data/remote/remote_table.dart';
import '../../../design_system/components/qb_button.dart';
import '../../../design_system/components/qb_dialog.dart';
import '../../../design_system/components/qb_toast.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../tables/table_formatting.dart';
import '../providers/projection_provider.dart';

/// Le mode projection : un lien public qui montre le plateau, en lecture
/// seule, sur l'écran de la salle — télé, vidéoprojecteur, ordinateur.
Future<void> showProjectionDialog(
  BuildContext context, {
  required RemoteGameSession session,
}) {
  return showQBDialog(
    context: context,
    title: 'Projeter le plateau',
    builder: (_) => _ProjectionForm(session: session),
  );
}

class _ProjectionForm extends ConsumerStatefulWidget {
  const _ProjectionForm({required this.session});

  final RemoteGameSession session;

  @override
  ConsumerState<_ProjectionForm> createState() => _ProjectionFormState();
}

class _ProjectionFormState extends ConsumerState<_ProjectionForm> {
  bool _busy = false;
  String? _error;

  String get _sessionId => widget.session.id;

  Future<void> _run(
    Future<void> Function(ProjectionLinkController controller) action,
  ) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(ref.read(projectionLinkProvider(_sessionId).notifier));
    } on ApiException catch (error) {
      _error = error.message;
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _copy(ProjectionLink link) async {
    await Clipboard.setData(ClipboardData(text: link.url));
    if (!mounted) return;
    showQBToast(context, 'Lien copié.', tone: QBTone.success);
  }

  Future<void> _open(ProjectionLink link) async {
    final opened = await launchUrl(
      Uri.parse(link.url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      setState(() => _error = 'Impossible d’ouvrir le navigateur.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectionLinkProvider(_sessionId));
    final link = state.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Affiche le plateau sur un écran de la salle, sans connexion et sans '
          'rien pouvoir y toucher. Qui a le lien voit le plateau : '
          'ne le partage qu’avec la table.',
          style: QBType.body().copyWith(
            fontSize: QBType.sm,
            color: QBColors.textMuted,
          ),
        ),
        const SizedBox(height: QBSpace.s4),
        if (state.isLoading && link == null)
          const Center(child: CircularProgressIndicator())
        else if (link == null) ...[
          QBButton(
            label: _busy ? 'Création…' : 'Créer le lien',
            iconLeft: const Icon(LucideIcons.cast, size: 16),
            expand: true,
            onPressed: _busy ? null : () => _run((c) => c.generate()),
          ),
        ] else ...[
          _LinkBox(url: link.url),
          const SizedBox(height: QBSpace.s2),
          Text(
            _validity(link),
            style: QBType.body().copyWith(
              fontSize: QBType.xs,
              color: QBColors.textMuted,
            ),
          ),
          const SizedBox(height: QBSpace.s4),
          QBButton(
            label: 'Copier le lien',
            iconLeft: const Icon(LucideIcons.copy, size: 16),
            expand: true,
            onPressed: () => _copy(link),
          ),
          const SizedBox(height: QBSpace.s3),
          QBButton(
            label: 'Ouvrir',
            iconLeft: const Icon(LucideIcons.externalLink, size: 16),
            variant: QBButtonVariant.secondary,
            expand: true,
            onPressed: () => _open(link),
          ),
          const SizedBox(height: QBSpace.s4),
          Row(
            children: [
              Expanded(
                child: QBButton(
                  label: 'Nouveau lien',
                  variant: QBButtonVariant.ghost,
                  size: QBButtonSize.sm,
                  expand: true,
                  onPressed: _busy ? null : () => _run((c) => c.generate()),
                ),
              ),
              const SizedBox(width: QBSpace.s3),
              Expanded(
                child: QBButton(
                  label: 'Arrêter',
                  variant: QBButtonVariant.danger,
                  size: QBButtonSize.sm,
                  expand: true,
                  onPressed: _busy ? null : () => _run((c) => c.stop()),
                ),
              ),
            ],
          ),
          const SizedBox(height: QBSpace.s2),
          Text(
            'Un nouveau lien, ou l’arrêt, éteint les écrans ouverts avec '
            'celui-ci.',
            style: QBType.body().copyWith(
              fontSize: QBType.xs,
              color: QBColors.textMuted,
            ),
          ),
        ],
        if (_error ?? _loadError(state) case final message?) ...[
          const SizedBox(height: QBSpace.s3),
          Text(
            message,
            style: QBType.body().copyWith(
              fontSize: QBType.xs,
              color: QBColors.semanticDanger,
            ),
          ),
        ],
      ],
    );
  }

  String? _loadError(AsyncValue<ProjectionLink?> state) =>
      switch (state.error) {
        null => null,
        ApiException(:final message) => message,
        _ => 'Impossible de lire l’état de la projection.',
      };

  String _validity(ProjectionLink link) {
    final opensAt = link.opensAt.toLocal();
    final closesAt = link.closesAt.toLocal();
    if (DateTime.now().isBefore(opensAt)) {
      return 'S’ouvre au début de la séance : ${formatSessionDate(opensAt)}. '
          'Valable jusqu’à : ${formatSessionDate(closesAt)}.';
    }
    return 'Valable jusqu’à : ${formatSessionDate(closesAt)}.';
  }
}

class _LinkBox extends StatelessWidget {
  const _LinkBox({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QBSpace.s3,
        vertical: QBSpace.s3,
      ),
      decoration: BoxDecoration(
        color: QBColors.paper200,
        borderRadius: BorderRadius.circular(QBRadius.md),
        border: Border.all(color: QBColors.borderHairline),
      ),
      child: SelectableText(
        url,
        maxLines: 2,
        style: QBType.body().copyWith(
          fontSize: QBType.xs,
          color: QBColors.ink900,
        ),
      ),
    );
  }
}
