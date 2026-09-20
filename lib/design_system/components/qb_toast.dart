import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Ported from components/feedback/Toast.jsx. Use [showQBToast] rather than
/// building one by hand: a toast has to be handed to the messenger to float
/// above the page and go away on its own.
class QBToast extends StatelessWidget {
  const QBToast({
    super.key,
    required this.message,
    this.tone = QBTone.neutral,
    this.onClose,
  });

  final String message;
  final QBTone tone;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final (top, bottom) = tone.juicyGradient;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
        borderRadius: BorderRadius.circular(QBRadius.md),
        border: Border.all(color: const Color(0x4D000000), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x4D000000), offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              message,
              style: QBType.body()
                  .copyWith(fontSize: QBType.sm, color: tone.foreground),
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: QBSpace.s3),
            GestureDetector(
              onTap: onClose,
              child: Text('×',
                  style: TextStyle(color: tone.foreground.withValues(alpha: 0.7))),
            ),
          ],
        ],
      ),
    );
  }
}

/// Floats a [QBToast] over the current page.
///
/// Goes through [ScaffoldMessenger] rather than an overlay of its own: it
/// already queues messages, dismisses them and survives a route change. The
/// snack bar itself is stripped bare — transparent, no elevation, no padding
/// — so what shows is the toast and nothing of Material underneath.
void showQBToast(
  BuildContext context,
  String message, {
  QBTone tone = QBTone.neutral,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Center(child: QBToast(message: message, tone: tone)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
}
