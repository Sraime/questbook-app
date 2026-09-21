import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/remote_providers.dart';
import '../../data/remote/api_exception.dart';
import '../../data/remote/remote_table.dart';
import '../../design_system/components/qb_badge.dart';
import '../../design_system/components/qb_button.dart';
import '../../design_system/components/qb_card.dart';
import '../../design_system/components/qb_icon_button.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import 'providers/table_providers.dart';
import 'table_formatting.dart';
import 'widgets/attendee_character_sheet.dart';
import 'widgets/invite_player_dialog.dart';
import 'widgets/session_character_dialog.dart';
/// Everything about one table: who is at it, who has been invited, and what is
/// planned. Game-master controls appear only when the server says the viewer
/// is one, so a player never sees a button that would come back a 403.
class TableDetailScreen extends ConsumerWidget {
  const TableDetailScreen({super.key, required this.tableId});

  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(tableDetailProvider(tableId));

    return QBPageBackground(
      child: SafeArea(
        bottom: false,
        child: detail.when(
          data: (data) => _Body(detail: data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _Failure(
            error: error,
            onRetry: () => ref.invalidate(tableDetailProvider(tableId)),
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.detail});

  final TableDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final table = detail.table;
    final canWrite = ref.watch(canWriteProvider);

    return RefreshIndicator(
      onRefresh: () async => refreshTables(ref, tableId: table.id),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
        children: [
          // Sans bouton retour : l'onglet Tables, en bas, ramène à la liste
          // et ne bouge jamais. Une flèche de plus en haut de chaque écran
          // faisait viser une cible de 36 points pour ce que la barre offre
          // déjà, en grand et au même endroit.
          Text(
            table.title,
            style: QBType.game().copyWith(
              fontWeight: QBType.weightBold,
              fontSize: 20,
              color: QBColors.ink900,
            ),
          ),
          const SizedBox(height: QBSpace.s2),
          // Aligné à la main : dans une ListView, un badge seul s'étirerait
          // sur toute la largeur.
          Align(
            alignment: Alignment.centerLeft,
            child: QBBadge(
              label: table.isGameMaster ? 'Tu es MJ' : 'Joueur',
              tone: table.isGameMaster ? QBTone.warning : QBTone.neutral,
            ),
          ),
          if (detail.cachedAt case final fetchedAt?) ...[
            const SizedBox(height: QBSpace.s3),
            _MutedText('Dernière mise à jour ${formatRelative(fetchedAt)}.'),
          ],
          const _Separator(),
          _SectionTitle(
            title: 'Sessions',
            action: table.isGameMaster && canWrite
                ? _SectionAction(
                    label: '+ Proposer',
                    onTap: () => context.go('/tables/${table.id}/sessions/new'),
                  )
                : null,
          ),
          const SizedBox(height: QBSpace.s3),
          if (detail.upcoming.isEmpty)
            _MutedText(
              table.isGameMaster
                  ? 'Aucune session prévue. Propose une date à tes joueurs.'
                  : 'Aucune session prévue pour l’instant.',
            )
          else
            for (final session in detail.upcoming) ...[
              _SessionCard(session: session, table: table),
              const SizedBox(height: QBSpace.s3),
            ],
          if (detail.past.isNotEmpty) ...[
            const SizedBox(height: QBSpace.s3),
            _SectionTitle(title: 'Sessions passées'),
            const SizedBox(height: QBSpace.s3),
            for (final session in detail.past.take(5)) ...[
              _PastSessionRow(session: session),
              const SizedBox(height: QBSpace.s2),
            ],
          ],
          const _Separator(),
          _SectionTitle(
            title: 'Joueurs',
            action: table.isGameMaster && canWrite
                ? _SectionAction(
                    label: '+ Inviter',
                    onTap: () =>
                        showInvitePlayerDialog(context, tableId: table.id),
                  )
                : null,
          ),
          const SizedBox(height: QBSpace.s3),
          for (final (index, member) in table.members.indexed)
            _MemberRow(
              member: member,
              table: table,
              // Le dernier ne porte pas de trait : celui de la section suit
              // juste après, et deux filets à vingt points l'un de l'autre se
              // lisent comme une rature.
              rule: index < table.members.length - 1,
            ),
          if (table.pendingInvitations.isNotEmpty) ...[
            const SizedBox(height: QBSpace.s4),
            _SectionTitle(title: 'Invitations en attente'),
            const SizedBox(height: QBSpace.s3),
            for (final invitation in table.pendingInvitations) ...[
              _PendingInvitationRow(invitation: invitation, tableId: table.id),
              const SizedBox(height: QBSpace.s2),
            ],
          ],
          if (canWrite) ...[
            const _Separator(),
            _DangerZone(table: table),
          ],
        ],
      ),
    );
  }
}

class _SessionCard extends ConsumerStatefulWidget {
  const _SessionCard({required this.session, required this.table});

  final RemoteGameSession session;
  final RemoteGameTable table;

  @override
  ConsumerState<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends ConsumerState<_SessionCard> {
  bool _busy = false;

  Future<void> _answer(AttendanceStatus status) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(sessionApiProvider)
          .setAttendance(widget.session.id, status);
      refreshTables(ref, tableId: widget.table.id);
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openGameMasterMode() {
    context.go(
      '/tables/${widget.table.id}/sessions/${widget.session.id}/mj',
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final canWrite = ref.watch(canWriteProvider);

    // Un bouton nommé, à la place qu'occupent « Je viens » et « Je passe »
    // chez le joueur : corriger la session et l'annuler ont leur volet dans le
    // mode MJ, mais encore faut-il voir comment y entrer. La carte entière y
    // menait, et un geste qu'aucun mot n'annonce ne se devine pas.
    //
    // Ni préparer ni animer ne demande quoi que ce soit au serveur : le
    // plateau et les notes vivent sur l'appareil. Le réseau peut tomber en
    // pleine partie sans emporter l'outil avec lui, d'où le `canWrite` absent
    // ici.
    final runnable = widget.table.isGameMaster && !session.isCancelled;

    // The game master runs the evening rather than attending it, so they are
    // neither expected to answer nor counted among those who have not.
    final answered = session.attendances.map((a) => a.userId).toSet();
    final pending = widget.table.members
        .where((member) =>
            !member.role.isGameMaster && !answered.contains(member.userId))
        .length;

    final card = QBCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            session.title,
            style: QBType.game().copyWith(
              fontWeight: QBType.weightSemibold,
              fontSize: 15,
              color: QBColors.ink900,
            ),
          ),
          const SizedBox(height: QBSpace.s2),
          _IconLine(
            icon: LucideIcons.calendarDays,
            text: formatSessionDate(session.startsAt),
          ),
          const SizedBox(height: 2),
          _IconLine(icon: LucideIcons.mapPin, text: session.location),
          if (session.scenario != null) ...[
            const SizedBox(height: 2),
            _IconLine(icon: LucideIcons.book, text: session.scenario!.title),
          ],
          if (session.description != null && session.description!.isNotEmpty) ...[
            const SizedBox(height: QBSpace.s2),
            Text(
              session.description!,
              style: QBType.body().copyWith(
                fontSize: QBType.sm,
                color: QBColors.textBody,
              ),
            ),
          ],
          const SizedBox(height: QBSpace.s3),
          _AttendanceSummary(session: session, pendingCount: pending),
          if (runnable) ...[
            const SizedBox(height: QBSpace.s3),
            QBButton(
              // Préparer avant l'heure, animer pendant : le même écran, mais
              // pas le même moment, et le MJ sait lequel des deux il vient
              // faire.
              label: session.isUnderway ? 'Animer' : 'Préparer',
              size: QBButtonSize.sm,
              expand: true,
              variant: session.isUnderway
                  ? QBButtonVariant.primary
                  : QBButtonVariant.secondary,
              onPressed: _openGameMasterMode,
            ),
          ] else if (!widget.table.isGameMaster && !session.acceptsAnswers) ...[
            const SizedBox(height: QBSpace.s3),
            _ClosedAnswers(session: session),
          ] else if (!widget.table.isGameMaster && canWrite) ...[
            const SizedBox(height: QBSpace.s3),
            Row(
              children: [
                Expanded(
                  child: QBButton(
                    label: 'Je viens',
                    size: QBButtonSize.sm,
                    expand: true,
                    variant: session.myStatus == AttendanceStatus.yes
                        ? QBButtonVariant.primary
                        : QBButtonVariant.secondary,
                    onPressed:
                        _busy ? null : () => _answer(AttendanceStatus.yes),
                  ),
                ),
                const SizedBox(width: QBSpace.s2),
                Expanded(
                  child: QBButton(
                    label: 'Je passe',
                    size: QBButtonSize.sm,
                    expand: true,
                    variant: session.myStatus == AttendanceStatus.no
                        ? QBButtonVariant.danger
                        : QBButtonVariant.ghost,
                    onPressed:
                        _busy ? null : () => _answer(AttendanceStatus.no),
                  ),
                ),
              ],
            ),
            // Answering and saying who you are playing are two moments: the
            // player confirms first, and names a character whenever they know.
            if (session.myStatus == AttendanceStatus.yes) ...[
              const SizedBox(height: QBSpace.s2),
              _MyCharacterRow(session: session, tableId: widget.table.id),
            ],
          ],
        ],
      ),
    );

    return card;
  }
}

/// Ce qui remplace « Je viens » et « Je passe » une fois les inscriptions
/// closes. Le joueur ne peut plus rien changer, mais il doit pouvoir relire ce
/// qu'il a répondu — et comprendre pourquoi les boutons ont disparu plutôt que
/// de les chercher.
class _ClosedAnswers extends StatelessWidget {
  const _ClosedAnswers({required this.session});

  final RemoteGameSession session;

  @override
  Widget build(BuildContext context) {
    final answer = switch (session.myStatus) {
      AttendanceStatus.yes => 'Tu as dit que tu venais.',
      AttendanceStatus.no => 'Tu as dit que tu ne venais pas.',
      null => 'Tu n’as pas répondu.',
    };

    return _MutedText(
      session.isUnderway
          ? '$answer La partie a commencé, les inscriptions sont closes.'
          : '$answer Les inscriptions sont closes.',
    );
  }
}

class _MyCharacterRow extends StatelessWidget {
  const _MyCharacterRow({required this.session, required this.tableId});

  final RemoteGameSession session;
  final String tableId;

  @override
  Widget build(BuildContext context) {
    final character = session.myCharacter;

    return GestureDetector(
      onTap: () => showSessionCharacterDialog(
        context,
        tableId: tableId,
        sessionId: session.id,
        currentCharacterId: character?.id,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.userRound, size: 13, color: QBColors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              character == null
                              ? 'Choisir ton investigateur'
                  : 'Tu joues ${character.name}',
              style: QBType.body().copyWith(
                fontSize: QBType.xs,
                color: QBColors.leather700,
                decoration: TextDecoration.underline,
                decorationColor: QBColors.leather700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Who said what. Members who have not answered are counted separately: not
/// answering is not the same as saying no, and the game master needs to know
/// who to chase.
///
/// A player who has named a character opens it to everyone else at the table,
/// so those lines are tappable.
class _AttendanceSummary extends StatelessWidget {
  const _AttendanceSummary({required this.session, required this.pendingCount});

  final RemoteGameSession session;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final accepted = session.accepted;
    final declined = session.declined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final attendance in accepted)
          _AttendeeLine(session: session, attendance: attendance, coming: true),
        for (final attendance in declined)
          _AttendeeLine(session: session, attendance: attendance, coming: false),
        if (pendingCount > 0)
          _MutedText(
            pendingCount > 1
                ? '$pendingCount joueurs n’ont pas encore répondu'
                : '1 joueur n’a pas encore répondu',
          ),
      ],
    );
  }
}

class _AttendeeLine extends StatelessWidget {
  const _AttendeeLine({
    required this.session,
    required this.attendance,
    required this.coming,
  });

  final RemoteGameSession session;
  final RemoteAttendance attendance;
  final bool coming;

  @override
  Widget build(BuildContext context) {
    final character = attendance.character;

    final line = Row(
      children: [
        Icon(
          coming ? LucideIcons.check : LucideIcons.x,
          size: 12,
          color: QBColors.textMuted,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: attendance.user.label),
                // Nobody is obliged to say who they are playing, so the
                // character is only named once it is known.
                if (character != null)
                  TextSpan(
                    text: ' · ${character.name}',
                    style: TextStyle(
                      color: QBColors.leather700,
                      decoration: TextDecoration.underline,
                      decorationColor: QBColors.leather700,
                    ),
                  ),
              ],
            ),
            style: QBType.body().copyWith(
              fontSize: QBType.xs,
              color: QBColors.textMuted,
            ),
          ),
        ),
      ],
    );

    if (character == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: line,
      );
    }

    return GestureDetector(
      onTap: () => showAttendeeCharacterSheet(
        context,
        sessionId: session.id,
        userId: attendance.userId,
        playerLabel: attendance.user.label,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: line,
      ),
    );
  }
}

class _PastSessionRow extends StatelessWidget {
  const _PastSessionRow({required this.session});

  final RemoteGameSession session;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            session.title,
            style: QBType.body().copyWith(
              fontSize: QBType.sm,
              color: QBColors.textMuted,
              decoration: session.isCancelled ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        Text(
          session.isCancelled ? 'Annulée' : formatShortDate(session.startsAt),
          style: QBType.body().copyWith(
            fontSize: QBType.xs,
            color: QBColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({
    required this.member,
    required this.table,
    this.rule = true,
  });

  final RemoteTableMember member;
  final RemoteGameTable table;

  /// Le filet sous la rangée, qui la sépare de la suivante.
  final bool rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The game master is the one member who cannot be removed: the table would
    // be left with nobody able to schedule anything.
    final isGm = member.role.isGameMaster;
    final canRemove =
        table.isGameMaster && !isGm && ref.watch(canWriteProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: QBSpace.s2),
      decoration: BoxDecoration(
        border: Border(
          // Transparent plutôt qu'absent : la rangée garde sa hauteur, et la
          // liste ne se resserre pas sur sa dernière ligne.
          bottom: BorderSide(
            color: rule ? QBColors.borderHairline : Colors.transparent,
          ),
        ),
      ),
      child: Row(
        children: [
          // Une pastille par joueur, et un livre pour celui qui mène : la
          // liste se lit d'un coup d'œil, sans avoir à chercher lequel des
          // noms porte la mention en petit.
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isGm ? QBColors.surfaceSunken : QBColors.paper100,
              borderRadius: BorderRadius.circular(QBRadius.md),
              border: Border.all(color: QBColors.borderHairline),
            ),
            child: Icon(
              isGm ? LucideIcons.bookOpen : LucideIcons.user,
              size: 16,
              color: isGm ? QBColors.leather700 : QBColors.ink500,
            ),
          ),
          const SizedBox(width: QBSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  member.user.label,
                  style: QBType.body().copyWith(
                    fontSize: QBType.sm,
                    color: QBColors.textBody,
                  ),
                ),
                if (isGm)
                  Text(
                    'Maître du jeu',
                    style: QBType.body().copyWith(
                      fontSize: QBType.xs,
                      color: QBColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (canRemove)
            // Un seul point d'entrée plutôt que deux boutons jumeaux :
            // confier la table et retirer quelqu'un se ressemblaient trop
            // pour être côte à côte, et se pressaient l'un pour l'autre.
            _MemberMenu(
              label: member.user.label,
              onTransfer: () => _transfer(context, ref),
              onRemove: () => _remove(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(tableApiProvider).removeMember(table.id, member.userId);
      refreshTables(ref, tableId: table.id);
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  /// Handing over is not a small thing: the current game master loses every
  /// control on this screen, so it is worth a clear confirmation.
  Future<void> _transfer(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confier la table ?'),
        content: Text(
          '${member.user.label} deviendra maître du jeu et organisera les '
          'sessions à venir. Il sera retiré des participants de celles qui '
          'n’ont pas encore eu lieu. Toi, tu redeviendras un joueur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confier'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(tableApiProvider)
          .transferGameMaster(table.id, member.userId);
      refreshTables(ref, tableId: table.id);
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

/// Ce qu'un MJ peut faire d'un de ses joueurs, replié derrière trois points.
class _MemberMenu extends StatelessWidget {
  const _MemberMenu({
    required this.label,
    required this.onTransfer,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onTransfer;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoidCallback>(
      tooltip: 'Options de $label',
      icon: const Icon(
        LucideIcons.ellipsisVertical,
        size: 18,
        color: QBColors.ink500,
      ),
      padding: EdgeInsets.zero,
      color: QBColors.paper50,
      // Les libellés par défaut plafonnent à 280 points, et « Désigner comme
      // MJ » y tient de justesse selon la police chargée.
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 320),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QBRadius.md),
        side: const BorderSide(color: QBColors.borderStrong, width: 2),
      ),
      onSelected: (action) => action(),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: onTransfer,
          child: _MenuLine(
            icon: LucideIcons.crown,
            label: 'Désigner comme MJ',
          ),
        ),
        PopupMenuItem(
          value: onRemove,
          child: _MenuLine(
            icon: LucideIcons.userMinus,
            label: 'Retirer de la table',
            danger: true,
          ),
        ),
      ],
    );
  }
}

class _MenuLine extends StatelessWidget {
  const _MenuLine({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? QBColors.semanticDanger : QBColors.ink800;

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: QBSpace.s2),
        Flexible(
          child: Text(
            label,
            style: QBType.body().copyWith(fontSize: QBType.sm, color: color),
          ),
        ),
      ],
    );
  }
}

class _PendingInvitationRow extends ConsumerWidget {
  const _PendingInvitationRow({
    required this.invitation,
    required this.tableId,
  });

  final RemoteTableInvitation invitation;
  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Text(
            invitation.email,
            style: QBType.body().copyWith(
              fontSize: QBType.sm,
              color: QBColors.textMuted,
            ),
          ),
        ),
        if (ref.watch(canWriteProvider))
          QBIconButton(
            icon: const Icon(LucideIcons.x, size: 16),
            label: 'Annuler l’invitation',
            size: 32,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref
                    .read(tableApiProvider)
                    .revokeInvitation(tableId, invitation.id);
                refreshTables(ref, tableId: tableId);
              } on ApiException catch (error) {
                messenger.showSnackBar(SnackBar(content: Text(error.message)));
              }
            },
          ),
      ],
    );
  }
}

/// Leaving and disbanding are the same button in two guises: a player walks
/// away, a game master takes the table with them.
class _DangerZone extends ConsumerWidget {
  const _DangerZone({required this.table});

  final RemoteGameTable table;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGm = table.isGameMaster;
    final label = isGm ? 'Dissoudre la table' : 'Quitter la table';

    // Un lien discret plutôt qu'un pavé rouge pleine largeur : c'est le geste
    // le plus rare de l'écran, et le plus définitif. Le peindre en grand le
    // mettait sur le chemin de tous les autres, et donnait à une table
    // paisible des airs d'avertissement.
    return Center(
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _confirm(context, ref, isGm: isGm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: QBSpace.s2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.trash2,
                  size: 15,
                  color: QBColors.semanticDanger,
                ),
                const SizedBox(width: QBSpace.s2),
                Text(
                  label,
                  style: QBType.body().copyWith(
                    fontSize: QBType.sm,
                    color: QBColors.semanticDanger,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref, {
    required bool isGm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isGm ? 'Dissoudre la table ?' : 'Quitter la table ?'),
        content: Text(
          isGm
              ? 'La table et toutes ses sessions seront supprimées pour '
                  'tout le monde. C’est définitif.'
              : 'Tu ne verras plus cette table ni ses sessions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(isGm ? 'Dissoudre' : 'Quitter'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      final api = ref.read(tableApiProvider);
      if (isGm) {
        await api.delete(table.id);
      } else {
        await api.leave(table.id);
      }
      refreshTables(ref);
      router.go('/tables');
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

// --- Small shared pieces ---

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action});

  final String title;
  final _SectionAction? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: QBType.game().copyWith(
              fontWeight: QBType.weightSemibold,
              fontSize: 15,
              color: QBColors.ink900,
            ),
          ),
        ),
        if (action != null)
          // En sourdine : proposer une session et inviter un joueur sont des
          // gestes occasionnels, et deux pavés dorés en haut de chaque
          // section criaient plus fort que ce qu'elles contiennent.
          QBButton(
            label: action!.label,
            size: QBButtonSize.sm,
            variant: QBButtonVariant.ghost,
            onPressed: action!.onTap,
          ),
      ],
    );
  }
}

/// Le trait qui sépare deux sections. Une page qui empile titres et cartes
/// sans respiration se lit comme une seule liste ; le trait dit où l'une
/// s'arrête.
class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: QBSpace.s5),
      color: QBColors.borderHairline,
    );
  }
}

class _SectionAction {
  const _SectionAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: QBColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: QBType.body().copyWith(
              fontSize: QBType.xs,
              color: QBColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: QBType.body().copyWith(
          fontSize: QBType.xs,
          color: QBColors.textMuted,
        ),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final api = error is ApiException ? error as ApiException : null;
    final message = api == null
        ? '$error'
        : api.isMissing
            ? 'Cette table n’existe plus, ou tu n’en fais plus partie.'
            : api.message;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: QBType.body().copyWith(
              fontSize: QBType.sm,
              color: QBColors.textMuted,
            ),
          ),
          const SizedBox(height: QBSpace.s4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QBButton(
                label: 'Retour',
                variant: QBButtonVariant.ghost,
                size: QBButtonSize.sm,
                onPressed: () => context.go('/tables'),
              ),
              const SizedBox(width: QBSpace.s2),
              QBButton(
                label: 'Réessayer',
                variant: QBButtonVariant.secondary,
                size: QBButtonSize.sm,
                onPressed: onRetry,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
