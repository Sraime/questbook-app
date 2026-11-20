import 'package:material_ui/material_ui.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Ported from components/forms/Select.jsx.
class QBSelect extends StatelessWidget {
  const QBSelect({
    super.key,
    this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String? label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: QBType.body().copyWith(
              fontSize: QBType.sm,
              fontWeight: QBType.weightSemibold,
              color: QBColors.ink800,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
          decoration: BoxDecoration(
            color: QBColors.surfaceRaised,
            borderRadius: BorderRadius.circular(QBRadius.sm),
            border: Border.all(color: QBColors.borderStrong, width: 2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.expand_more, color: QBColors.ink800),
              style: QBType.body().copyWith(
                fontSize: QBType.base,
                color: QBColors.ink900,
              ),
              items: [
                for (final option in options)
                  DropdownMenuItem(value: option, child: Text(option)),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
