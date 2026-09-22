import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/remote_providers.dart';
import '../../data/remote/api_exception.dart';
import '../../data/remote/report_api.dart';
import '../../design_system/components/qb_button.dart';
import '../../design_system/components/qb_dialog.dart';
import '../../design_system/components/qb_input.dart';
import '../../design_system/components/qb_toast.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';

/// La fenêtre qui recueille un signalement, la même pour les quatre choses
/// qui se signalent. Elle demande ce qu'on reproche : sans ces mots, le
/// support reçoit un identifiant et rien d'autre à en faire.
Future<void> showReportDialog(
  BuildContext context, {
  required ReportableContent contentType,
  required String contentId,
  /// Ce qui est signalé, nommé comme l'utilisateur le voit à l'écran. Le
  /// titre de la fenêtre le répète : on se trompe de ligne dans une liste.
  required String label,
}) {
  return showQBDialog(
    context: context,
    title: 'Signaler',
    // Le motif est de la prose. L'écrire dans une colonne de deux mots
    // empêche de le relire, comme pour la description d'un PNJ.
    width: 560,
    builder: (_) => _ReportForm(
      contentType: contentType,
      contentId: contentId,
      label: label,
    ),
  );
}

class _ReportForm extends ConsumerStatefulWidget {
  const _ReportForm({
    required this.contentType,
    required this.contentId,
    required this.label,
  });

  final ReportableContent contentType;
  final String contentId;
  final String label;

  @override
  ConsumerState<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends ConsumerState<_ReportForm> {
  final _reason = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  String get _what => switch (widget.contentType) {
        ReportableContent.user => 'ce joueur',
        ReportableContent.table => 'cette table',
        ReportableContent.session => 'cette séance',
        ReportableContent.investigator => 'cet investigateur',
      };

  Future<void> _submit() async {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Dis ce que tu reproches à $_what.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final navigator = Navigator.of(context);
    final messengerContext = context;

    try {
      await ref.read(reportApiProvider).report(
            contentType: widget.contentType,
            contentId: widget.contentId,
            reason: reason,
          );
      await navigator.maybePop();
      if (!messengerContext.mounted) return;
      showQBToast(
        messengerContext,
        'Signalement transmis. Nous le regardons.',
        tone: QBTone.success,
      );
    } on ApiException catch (error) {
      setState(() {
        _busy = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Tu signales $_what : « ${widget.label} ».',
          style: QBType.body().copyWith(
            fontSize: QBType.sm,
            color: QBColors.ink800,
          ),
        ),
        const SizedBox(height: QBSpace.s2),
        Text(
          'Ce que tu écris part à notre équipe, avec une copie du contenu '
          'tel qu’il est en ce moment. Nous répondons sous 24 heures.',
          style: QBType.body().copyWith(
            fontSize: QBType.xs,
            color: QBColors.ink500,
          ),
        ),
        const SizedBox(height: QBSpace.s3),
        QBInput(
          label: 'Ce que tu reproches',
          controller: _reason,
          placeholder: 'Ce qui est écrit là, et pourquoi ça ne va pas…',
          maxLines: 5,
        ),
        if (_error != null) ...[
          const SizedBox(height: QBSpace.s3),
          Text(
            _error!,
            style: QBType.body().copyWith(
              fontSize: QBType.xs,
              color: QBColors.semanticDanger,
            ),
          ),
        ],
        const SizedBox(height: QBSpace.s4),
        QBButton(
          label: _busy ? 'Envoi…' : 'Signaler',
          variant: QBButtonVariant.danger,
          expand: true,
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}
