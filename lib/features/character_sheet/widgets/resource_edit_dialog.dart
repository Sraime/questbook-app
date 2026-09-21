import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/qb_button.dart';
import '../../../design_system/components/qb_dialog.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../providers/character_detail_provider.dart';

/// Screen 1j — "Modifier PV/SAN/PM" modal. Generalized to any resource key
/// (the mockup shows it for PV specifically, titled "Points de vie").
class ResourceEditDialog extends ConsumerWidget {
  const ResourceEditDialog({
    super.key,
    required this.characterId,
    required this.resourceKey,
  });

  final String characterId;
  final String resourceKey;

  static Future<void> show(
    BuildContext context, {
    required String characterId,
    required String resourceKey,
    required String title,
  }) {
    return showQBDialog(
      context: context,
      title: title,
      width: 300,
      builder: (context) => ResourceEditDialog(
        characterId: characterId,
        resourceKey: resourceKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characterAsync = ref.watch(characterDetailProvider(characterId));

    return characterAsync.when(
      data: (character) {
        final resource = character?.resourceByKey(resourceKey);
        if (resource == null) {
          return const SizedBox(height: 60);
        }
        final actions = ref.read(characterActionsProvider);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CircleStepper(
                  label: '−',
                  onTap: () => actions.adjustResource(
                    characterId,
                    resourceKey,
                    -1,
                    current: resource.current,
                    max: resource.max,
                  ),
                ),
                const SizedBox(width: QBSpace.s5),
                // Les deux pastilles ne cèdent rien : c'est au nombre de
                // rétrécir quand la jauge compte large.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        text: '${resource.current}',
                        style: QBType.mono().copyWith(
                          fontWeight: QBType.weightBold,
                          fontSize: 36,
                          color: QBColors.ink900,
                        ),
                        children: [
                          TextSpan(
                            text: '/${resource.max}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: QBColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: QBSpace.s5),
                _CircleStepper(
                  label: '+',
                  filled: true,
                  onTap: () => actions.adjustResource(
                    characterId,
                    resourceKey,
                    1,
                    current: resource.current,
                    max: resource.max,
                  ),
                ),
              ],
            ),
            const SizedBox(height: QBSpace.s5),
            QBButton(
              label: 'Valider',
              variant: QBButtonVariant.primary,
              expand: true,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Text('Erreur : $error'),
    );
  }
}

class _CircleStepper extends StatelessWidget {
  const _CircleStepper({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: filled
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [QBColors.juicyGoldTop, QBColors.juicyGoldBottom],
                )
              : null,
          color: filled ? null : QBColors.surfaceSunken,
          border: Border.all(
            color: filled ? const Color(0x59000000) : QBColors.borderStrong,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: QBType.game().copyWith(
            fontWeight: QBType.weightBold,
            fontSize: 22,
            color: QBColors.ink900,
          ),
        ),
      ),
    );
  }
}
