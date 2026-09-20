import 'package:flutter/material.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Le carnet du MJ : un bonus accordé, un indice déjà lâché, le nom qu'il vient
/// d'inventer. Rien de structuré — ce serait lui dire quoi noter.
class NotesPanel extends StatefulWidget {
  const NotesPanel({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<NotesPanel> createState() => _NotesPanelState();
}

class _NotesPanelState extends State<NotesPanel> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QBSpace.s6,
        QBSpace.s5,
        QBSpace.s6,
        QBSpace.s6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Notes de session',
            style: QBType.game().copyWith(
              fontWeight: QBType.weightBold,
              fontSize: 16,
              letterSpacing: 16 * QBType.trackingWide,
              color: QBColors.ink900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Enregistrées sur cet appareil au fil de la frappe.',
            style: QBType.body().copyWith(
              fontSize: QBType.xs,
              color: QBColors.textMuted,
            ),
          ),
          const SizedBox(height: QBSpace.s4),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(QBSpace.s4),
              decoration: BoxDecoration(
                color: QBColors.surfaceCard,
                border: Border.all(color: QBColors.borderStrong, width: 2),
                borderRadius: BorderRadius.circular(QBRadius.md),
              ),
              child: TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                cursorColor: QBColors.ink900,
                style: QBType.hand().copyWith(
                  fontSize: 20,
                  color: QBColors.ink900,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  hintText: 'Ce qu’il ne faut pas oublier…',
                  hintStyle: QBType.hand().copyWith(
                    fontSize: 20,
                    color: QBColors.ink300,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
