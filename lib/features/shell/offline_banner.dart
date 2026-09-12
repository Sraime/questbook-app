import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/remote_providers.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';

/// Says out loud that the app is showing an archive rather than the truth.
///
/// Hidden affordances alone would be a silent failure: a player who cannot
/// find the button to answer a session has to be told why, not left to
/// conclude the app is broken.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  /// Fixed, because the shell has to reserve exactly this much room above the
  /// page before the banner exists. A single line of notice is all it ever is.
  static const double height = 36;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(connectivityProvider)) return const SizedBox.shrink();

    return Material(
      color: QBColors.leather800,
      child: InkWell(
        onTap: () => ref.read(connectivityProvider.notifier).recheck(),
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: QBSpace.s4),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.cloudOff,
                  size: 16,
                  color: QBColors.paper100,
                ),
                const SizedBox(width: QBSpace.s2),
                Expanded(
                  child: Text(
                    'Hors ligne — consultation seule',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: QBType.game().copyWith(
                      fontWeight: QBType.weightSemibold,
                      fontSize: QBType.xs,
                      color: QBColors.paper100,
                    ),
                  ),
                ),
                Text(
                  'Réessayer',
                  style: QBType.body().copyWith(
                    fontSize: QBType.xs,
                    color: QBColors.paper100,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
