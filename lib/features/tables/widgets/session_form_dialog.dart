import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/remote_providers.dart';
import '../../../data/remote/api_exception.dart';
import '../../../data/remote/remote_table.dart';
import '../../../design_system/components/qb_button.dart';
import '../../../design_system/components/qb_dialog.dart';
import '../../../design_system/components/qb_input.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../providers/table_providers.dart';
import '../table_formatting.dart';

/// Creates a session when [existing] is null, edits it otherwise. The two
/// share every field, and the difference that matters — moving the date or the
/// place notifies the players — is the server's to make.
Future<void> showSessionFormDialog(
  BuildContext context, {
  required String tableId,
  RemoteGameSession? existing,
}) {
  return showQBDialog(
    context: context,
    title: existing == null ? 'Nouvelle session' : 'Modifier la session',
    builder: (_) => _SessionForm(tableId: tableId, existing: existing),
  );
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

    final navigator = Navigator.of(context);
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
      await navigator.maybePop();
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
        QBInput(label: 'Titre', controller: _title, placeholder: 'Le manoir Corbitt'),
        const SizedBox(height: QBSpace.s3),
        QBInput(
          label: 'Description',
          controller: _description,
          placeholder: 'Apportez vos fiches…',
          maxLines: 3,
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
          label: 'Lieu',
          controller: _location,
          placeholder: 'Chez Robin',
          error: _error,
        ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: QBType.game().copyWith(
            fontWeight: QBType.weightSemibold,
            fontSize: QBType.xs,
            color: QBColors.ink700,
          ),
        ),
        const SizedBox(height: 4),
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
