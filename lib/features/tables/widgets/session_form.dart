import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/remote_providers.dart';
import '../../../data/remote/api_exception.dart';
import '../../../data/remote/remote_scenario.dart';
import '../../../data/remote/remote_table.dart';
import '../../../design_system/components/qb_button.dart';
import '../../../design_system/components/qb_input.dart';
import '../../../design_system/components/qb_select.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../providers/table_providers.dart';
import '../../scenarios/providers/scenario_providers.dart';
import '../table_formatting.dart';

/// Les champs d'une session : ceux qu'on remplit pour la proposer sont ceux
/// qu'on rouvre pour la corriger.
///
/// Proposer une session est un écran à soi ; la corriger se fait depuis le
/// mode MJ, sans quitter la table de jeu. Deux endroits, un seul formulaire —
/// ce qui suit ne sait donc pas où il est affiché, et laisse [onSaved] décider
/// de la suite.
class SessionForm extends ConsumerStatefulWidget {
  const SessionForm({
    super.key,
    required this.tableId,
    this.existing,
    required this.onSaved,
  });

  final String tableId;

  /// Nulle à la création, renseignée à la modification.
  final RemoteGameSession? existing;

  final VoidCallback onSaved;

  @override
  ConsumerState<SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends ConsumerState<SessionForm> {
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.existing?.description ?? '');
  late final TextEditingController _location =
      TextEditingController(text: widget.existing?.location ?? '');

  late DateTime _startsAt = widget.existing?.startsAt ?? _defaultStart();
  late String? _scenarioId;

  bool _busy = false;
  String? _error;

  /// Sessions are evening things: tomorrow at 20h is a better first guess than
  /// "right now".
  static DateTime _defaultStart() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 20);
  }

  @override
  void initState() {
    super.initState();
    _scenarioId = widget.existing?.scenarioId;
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
          scenarioId: _scenarioId,
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
          scenarioId: _scenarioId == existing.scenarioId ? null : _scenarioId,
          clearScenario: existing.scenarioId != null && _scenarioId == null,
        );
      }

      refreshTables(ref, tableId: widget.tableId);
      if (!mounted) return;
      setState(() => _busy = false);
      widget.onSaved();
    } on ApiException catch (error) {
      if (!mounted) return;
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
        _ScenarioPicker(
          selectedId: _scenarioId,
          linkedTitle: widget.existing?.scenario?.title,
          onChanged: (id) => setState(() => _scenarioId = id),
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

class _ScenarioPicker extends ConsumerWidget {
  const _ScenarioPicker({
    required this.selectedId,
    required this.linkedTitle,
    required this.onChanged,
  });

  final String? selectedId;
  final String? linkedTitle;
  final ValueChanged<String?> onChanged;

  static const _none = 'Aucun';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloaded = ref.watch(downloadedScenariosProvider).asData?.value ??
        const <RemoteScenarioDetail>[];

    final byTitle = <String, String>{
      for (final scenario in downloaded) scenario.title: scenario.id,
    };
    if (linkedTitle != null && selectedId != null) {
      byTitle.putIfAbsent(linkedTitle!, () => selectedId!);
    }

    final options = [_none, ...byTitle.keys];
    final value = () {
      if (selectedId == null) return _none;
      for (final entry in byTitle.entries) {
        if (entry.value == selectedId) return entry.key;
      }
      return linkedTitle ?? _none;
    }();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QBSelect(
          label: 'Scénario (facultatif)',
          value: options.contains(value) ? value : _none,
          options: options,
          onChanged: (picked) {
            if (picked == null || picked == _none) {
              onChanged(null);
              return;
            }
            onChanged(byTitle[picked]);
          },
        ),
        if (downloaded.isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Télécharge un scénario dans l’onglet Scénarios pour l’attacher ici.',
            style: QBType.body().copyWith(
              fontSize: QBType.xs,
              color: QBColors.textMuted,
            ),
          ),
        ],
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
