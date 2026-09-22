import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/remote_providers.dart';
import '../../config/legal_links.dart';
import '../../data/remote/api_exception.dart';
import '../../design_system/components/qb_button.dart';
import '../../design_system/components/qb_card.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';

/// Barré tant que le compte n'a pas accepté les conditions d'utilisation.
///
/// Il vient après la connexion, et pas avant : les accepter n'a de sens que
/// pour un compte, et c'est au compte que le serveur attache la date. Les
/// comptes créés avant leur publication le croisent donc à leur prochain
/// lancement — personne n'a signé pour eux.
///
/// L'écran résume, il ne recopie pas. Le texte qui fait foi est sur le
/// serveur : deux versions d'une clause divergent, et corriger celle de l'app
/// demanderait une livraison sur les stores.
class TermsScreen extends ConsumerStatefulWidget {
  const TermsScreen({super.key});

  @override
  ConsumerState<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends ConsumerState<TermsScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _accept() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).acceptTerms();
    } catch (error) {
      // Tout, et pas seulement les erreurs prévues : cet écran barre l'app
      // entière, et ses deux boutons sont grisés pendant l'envoi. Une panne
      // qu'on laisserait filer — un trousseau qui refuse d'écrire, une
      // réponse illisible — bloquerait sur un bouton éteint, sans message ni
      // sortie, et il ne resterait qu'à tuer l'app.
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error is ApiException
            ? error.message
            : 'Impossible d’enregistrer ton accord : $error';
      });
    }
  }

  Future<void> _open(Uri page) async {
    if (await LegalLinks.open(page)) return;
    if (!mounted) return;
    // Un lien qui ne s'ouvre pas sur un écran bloquant enferme : au moins
    // l'adresse reste lisible et recopiable ailleurs.
    setState(() => _error = 'Ouvre cette page dans ton navigateur : $page');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QBPageBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: QBCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Avant de t’asseoir',
                      style: QBType.game().copyWith(
                        fontWeight: QBType.weightBold,
                        fontSize: 22,
                        color: QBColors.ink900,
                      ),
                    ),
                    const SizedBox(height: QBSpace.s3),
                    Text(
                      'Questbook se joue à plusieurs : ce que tu écris — ton '
                      'pseudo, tes tables, tes séances, tes investigateurs — '
                      'est lu par les autres joueurs de tes tables.',
                      style: QBType.body().copyWith(
                        fontSize: QBType.sm,
                        color: QBColors.textBody,
                      ),
                    ),
                    const SizedBox(height: QBSpace.s3),
                    Text(
                      'Le harcèlement, les propos haineux et le contenu '
                      'illégal n’y ont pas leur place. Un contenu signalé est '
                      'examiné sous 24 heures, et le compte fautif est fermé.',
                      style: QBType.body().copyWith(
                        fontSize: QBType.sm,
                        color: QBColors.textBody,
                      ),
                    ),
                    const SizedBox(height: QBSpace.s2),
                    // L'horreur est le genre du jeu : sans cette phrase, la
                    // précédente se lit comme une interdiction de jouer.
                    Text(
                      'L’horreur reste le genre du jeu. Une scène dérangeante '
                      'écrite pour une table qui l’a choisie n’est pas un '
                      'abus : ce qui est visé, c’est ce qui s’adresse à une '
                      'personne réelle pour la blesser.',
                      style: QBType.body().copyWith(
                        fontSize: QBType.xs,
                        color: QBColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: QBSpace.s4),
                    _LegalLink(
                      label: 'Lire les conditions d’utilisation',
                      onPressed: () => _open(LegalLinks.terms),
                    ),
                    const SizedBox(height: QBSpace.s2),
                    _LegalLink(
                      label: 'Lire la politique de confidentialité',
                      onPressed: () => _open(LegalLinks.privacy),
                    ),
                    if (_error case final message?) ...[
                      const SizedBox(height: QBSpace.s3),
                      Text(
                        message,
                        style: QBType.body().copyWith(
                          fontSize: QBType.xs,
                          color: QBColors.semanticDanger,
                        ),
                      ),
                    ],
                    const SizedBox(height: QBSpace.s4),
                    QBButton(
                      label: _busy ? 'Un instant…' : 'J’accepte',
                      expand: true,
                      onPressed: _busy ? null : _accept,
                    ),
                    const SizedBox(height: QBSpace.s3),
                    // La seule autre issue. Sans elle, refuser reviendrait à
                    // devoir désinstaller l'app pour se retirer.
                    Center(
                      child: TextButton(
                        onPressed: _busy
                            ? null
                            : () =>
                                ref.read(authControllerProvider.notifier).signOut(),
                        child: Text(
                          'Non merci, me déconnecter',
                          style: QBType.body().copyWith(
                            fontSize: QBType.xs,
                            color: QBColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        children: [
          const Icon(
            LucideIcons.externalLink,
            size: 15,
            color: QBColors.leather700,
          ),
          const SizedBox(width: QBSpace.s2),
          Expanded(
            child: Text(
              label,
              style: QBType.body().copyWith(
                fontSize: QBType.sm,
                color: QBColors.leather700,
                decoration: TextDecoration.underline,
                decorationColor: QBColors.leather700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
