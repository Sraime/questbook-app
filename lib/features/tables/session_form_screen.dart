import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design_system/components/qb_icon_button.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import 'widgets/session_form.dart';

/// Proposer une session à sa table.
///
/// Une page plutôt qu'une modale : cinq champs et un clavier logiciel ne
/// tiennent pas dans un dialogue centré sur un téléphone.
///
/// La corriger ensuite ne passe plus par ici : c'est l'affaire du volet
/// Général du mode MJ, là où le MJ est déjà quand la session se joue.
class SessionFormScreen extends ConsumerWidget {
  const SessionFormScreen({super.key, required this.tableId});

  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return QBPageBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          // The soft keyboard eats the bottom of the viewport; padding by the
          // inset is what lets the last field scroll into view above it.
          padding: EdgeInsets.fromLTRB(
            18,
            12,
            18,
            90 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            Row(
              children: [
                QBIconButton(
                  icon: const Icon(LucideIcons.arrowLeft, size: 18),
                  label: 'Retour',
                  size: 36,
                  onPressed: () => context.go('/tables/$tableId'),
                ),
                const SizedBox(width: QBSpace.s2),
                Expanded(
                  child: Text(
                    'Nouvelle session',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: QBType.game().copyWith(
                      fontWeight: QBType.weightBold,
                      fontSize: 20,
                      color: QBColors.ink900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: QBSpace.s5),
            SessionForm(
              tableId: tableId,
              onSaved: () => context.go('/tables/$tableId'),
            ),
          ],
        ),
      ),
    );
  }
}
