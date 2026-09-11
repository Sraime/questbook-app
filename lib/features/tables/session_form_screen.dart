import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/remote_providers.dart';
import '../../data/remote/api_exception.dart';
import '../../data/remote/remote_table.dart';
import '../../design_system/components/qb_button.dart';
import '../../design_system/components/qb_icon_button.dart';
import '../../design_system/components/qb_input.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import 'providers/table_providers.dart';
import 'table_formatting.dart';

/// Creates a session when [sessionId] is null, edits it otherwise. The two
/// share every field, and the difference that matters — moving the date or the
/// place notifies the players — is the server's to make.
///
/// A page rather than a modal: five fields and a soft keyboard do not fit in a
/// centred dialog on a phone, and scrolling inside a modal is a poor trade.
class SessionFormScreen extends ConsumerWidget {
  const SessionFormScreen({super.key, required this.tableId, this.sessionId});

  final String tableId;
  final String? sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sessionId == null) {
      return _Scaffold(
        tableId: tableId,
        title: 'Nouvelle session',
        child: _SessionForm(tableId: tableId),
      );
    }

    // Read from the table rather than carrying the session through the route:
    // the page then survives a cold start on a deep link, and shows the
    // session as it stands rather than as it was when the screen was opened.
    final detail = ref.watch(tableDetailProvider(tableId));

    return _Scaffold(
      tableId: tableId,
      title: 'Modifier la session',
      child: detail.when(
        data: (data) {
          final session = data.sessions
              .where((candidate) => candidate.id == sessionId)
              .firstOrNull;

          if (session == null) {
            return const _Message('Cette session n’existe plus.');
          }
          return _SessionForm(tableId: tableId, existing: session);
        },
        loading: () => const Padding(
          padding: EdgeInsets.only(top: QBSpace.s6),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => _Message(
          error is ApiException ? error.message : 'Session indisponible.',
        ),
      ),
    );
  }
}

class _Scaffold extends StatelessWidget {
  const _Scaffold({
    required this.tableId,
    required this.title,
    required this.child,
  });

  final String tableId;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
                    title,
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
            child,
          ],
        ),
      ),
    );
  }
}

class _SessionForm extends ConsumerStatefulWidget {
  const _SessionForm({required this.tableId, this.existing});

  final String tableId;
  final RemoteGameSession? existing;

  @override
  ConsumerState<_SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends ConsumerState<_SessionForm> {
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.existing?.description ?? '');
  late final TextEditingController _location =
      TextEditingController(text: widget.existing?.location ?? '');

  late DateTime _startsAt = widget.existing?.startsAt ?? _defaultStart();

  bool _busy = false;
  String? _error;

  /// Sessions are evening things: tomorrow at 20h is a better first guess than
  /// "right now".
  static DateTime _defaultStart() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 20);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !mounted) return;

    setState(() {
      _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        _startsAt.hour,
        _startsAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null || !mounted) return;

    setState(() {
      _startsAt = DateTime(
        _startsAt.year,
        _startsAt.month,
        _startsAt.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final location = _location.text.trim();

    if (title.isEmpty) {
      setState(() => _error = 'Donne un titre à la session.');
      return;
    }
    if (location.isEmpty) {
      setState(() => _error = 'Indique où se tiendra la session.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final router = GoRouter.of(context);
    final api = ref.read(sessionApiProvider);
    final description = _description.text.trim();
    final existing = widget.existing;

    try {
      if (existing == null) {
        await api.create(
          widget.tableId,
          title: title,
          description: description.isEmpty ? null : description,
          startsAt: _startsAt,
          location: location,
        );
      } else {
        // Only what actually changed goes out: a needless `startsAt` would
        // look to the server like the date moved, and wake everyone up.
        await api.update(
          existing.id,
          title: title == existing.title ? null : title,
          description:
              description == (existing.description ?? '') ? null : description,
          startsAt: _startsAt.isAtSameMomentAs(existing.startsAt) ? null : _startsAt,
          location: location == existing.location ? null : location,
        );
      }

      refreshTables(ref, tableId: widget.tableId);
      router.go('/tables/${widget.tableId}');
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QBInput(
          label: 'Titre',
          controller: _title,
          placeholder: 'Le manoir Corbitt',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: QBSpace.s3),
        // Ahead of the description on purpose: a game master schedules a place
        // and a date, and only then bothers to describe the evening.
        QBInput(
          label: 'Lieu',
          controller: _location,
          placeholder: 'Chez Robin',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: QBSpace.s3),
        Row(
          children: [
            Expanded(
              child: _PickerField(
                label: 'Date',
                value: formatShortDate(_startsAt),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(width: QBSpace.s2),
            Expanded(
              child: _PickerField(
                label: 'Heure',
                value: formatTime(_startsAt),
                onTap: _pickTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: QBSpace.s3),
        QBInput(
          label: 'Description',
          controller: _description,
          placeholder: 'Apportez vos fiches…',
          maxLines: 3,
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
          label: _busy
              ? 'Enregistrement…'
              : (widget.existing == null ? 'Proposer la session' : 'Enregistrer'),
          expand: true,
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}

/// A read-only field that opens a picker, styled to sit next to [QBInput]
/// without pretending to be one.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          // Same label as QBInput's: stacked in a form, the two kinds of field
          // should read as one list rather than as two styles.
          style: QBType.body().copyWith(
            fontSize: QBType.sm,
            fontWeight: QBType.weightSemibold,
            color: QBColors.ink800,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: QBColors.surfaceSunken,
              borderRadius: BorderRadius.circular(QBRadius.md),
              border: Border.all(color: QBColors.borderStrong, width: 2),
            ),
            child: Text(
              value,
              style: QBType.body().copyWith(
                fontSize: QBType.sm,
                color: QBColors.ink900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: QBType.body().copyWith(
        fontSize: QBType.sm,
        color: QBColors.textMuted,
      ),
    );
  }
}
