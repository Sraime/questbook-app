import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Ported from components/forms/Input.jsx.
class QBInput extends StatelessWidget {
  const QBInput({
    super.key,
    this.label,
    this.hint,
    this.error,
    this.placeholder = '…',
    this.controller,
    this.focusNode,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.readOnly = false,
    this.maxLines = 1,
  });

  final String? label;
  final String? hint;
  final String? error;
  final String placeholder;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  /// Drives the keyboard's action key. `next` turns it into a way to walk down
  /// a form without reaching for the fields themselves.
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        error != null ? QBColors.semanticDanger : QBColors.borderStrong;
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
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          maxLines: maxLines,
          style: QBType.body().copyWith(
            fontSize: QBType.base,
            color: QBColors.ink900,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: QBColors.surfaceRaised,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(QBRadius.sm),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(QBRadius.sm),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(QBRadius.sm),
              borderSide: const BorderSide(color: QBColors.accentFocus, width: 2),
            ),
          ),
        ),
        if (hint != null || error != null) ...[
          const SizedBox(height: 4),
          Text(
            error ?? hint!,
            style: TextStyle(
              fontSize: QBType.xs,
              color: error != null
                  ? QBColors.semanticDanger
                  : QBColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}
