import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../assets/providers/hosted_assets_provider.dart';
import '../../assets/providers/owned_assets_provider.dart';
import '../models/board_catalog.dart';
import 'board_token_view.dart';

/// Ce qu'on a choisi dans le sélecteur. [token] `null` veut dire « aucun
/// pion » ; refermer le sélecteur sans rien toucher rend `null` tout court.
class CharacterTokenChoice {
  const CharacterTokenChoice(this.token);

  final String? token;
}

/// Le pion à associer à [characterName], parmi les pions de personnage que
/// ce compte possède : le socle, puis ses achats.
Future<CharacterTokenChoice?> showCharacterTokenPicker(
  BuildContext context, {
  required String characterName,
  required String? current,
}) {
  return showDialog<CharacterTokenChoice>(
    context: context,
    builder: (context) => _Picker(characterName: characterName, current: current),
  );
}

class _Picker extends ConsumerWidget {
  const _Picker({required this.characterName, required this.current});

  final String characterName;
  final String? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = characterTokensOf(ref.watch(boardCatalogueProvider));

    return AlertDialog(
      title: Text('Pion de $characterName'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: QBSpace.s2,
            runSpacing: QBSpace.s2,
            children: [
              _Choice(
                label: 'Aucun',
                selected: current == null,
                onTap: () =>
                    Navigator.of(context).pop(const CharacterTokenChoice(null)),
                child: const Icon(
                  LucideIcons.circleOff,
                  size: 22,
                  color: QBColors.textMuted,
                ),
              ),
              for (final asset in tokens)
                _Choice(
                  label: asset.name,
                  selected: asset.ref == current,
                  onTap: () =>
                      Navigator.of(context).pop(CharacterTokenChoice(asset.ref)),
                  child: BoardTokenView.ofAsset(asset),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(
            horizontal: QBSpace.s1,
            vertical: QBSpace.s2,
          ),
          decoration: BoxDecoration(
            color: QBColors.paper50,
            border: Border.all(
              color: selected ? QBColors.gold500 : QBColors.borderDefault,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(QBRadius.md),
          ),
          child: Column(
            children: [
              SizedBox(width: 34, height: 34, child: Center(child: child)),
              const SizedBox(height: QBSpace.s1),
              // Deux lignes réservées : « Joueur rouge » passe à la ligne,
              // « Joueur vert » non, et la grille en serait bancale.
              SizedBox(
                height: QBType.xs * 1.2 * 2,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: QBType.body().copyWith(
                    fontSize: QBType.xs,
                    height: 1.2,
                    color: QBColors.ink700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le pion associé à un personnage, en pastille. Un cercle pointillé quand il
/// n'en a pas encore : la place est là, prête à être remplie.
class CharacterTokenSlot extends ConsumerWidget {
  const CharacterTokenSlot({
    super.key,
    required this.token,
    required this.characterName,
    this.onTap,
    this.size = 40,
  });

  final String? token;
  final String characterName;

  /// `null` en lecture seule : la pastille montre le pion sans l'offrir.
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = boardAssetForRef(
      token,
      hosted: ref.watch(hostedAssetsProvider).value ?? const {},
    );

    return Semantics(
      button: onTap != null,
      label: asset == null
          ? 'Associer un pion à $characterName'
          : 'Pion de $characterName : ${asset.name}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: size,
          height: size,
          child: asset != null
              ? BoardTokenView.ofAsset(asset)
              : DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: QBColors.borderStrong, width: 1.5),
                  ),
                  child: Icon(
                    LucideIcons.plus,
                    size: size * 0.45,
                    color: QBColors.textMuted,
                  ),
                ),
        ),
      ),
    );
  }
}
