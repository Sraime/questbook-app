import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/remote_providers.dart';
import '../../design_system/components/qb_button.dart';
import '../../design_system/components/qb_card.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';

/// Shown at launch when nobody is signed in, and the only way past it.
///
/// There used to be a way through without an account. It could not be kept:
/// tables are shared with other players, and answering a session means being
/// somebody the server can name.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? _error;
  bool _busy = false;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final message = await ref.read(authControllerProvider.notifier).signIn();

    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = message;
    });
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
                    // Centred rather than stretched: the column stretches its
                    // children, which would pull the mark out of square.
                    const Center(
                      child: Image(
                        image: AssetImage('assets/brand/logo-mark.png'),
                        width: 104,
                        height: 104,
                      ),
                    ),
                    const SizedBox(height: QBSpace.s2),
                    Text(
                      'Questbook',
                      textAlign: TextAlign.center,
                      style: QBType.game().copyWith(
                        fontWeight: QBType.weightBold,
                        fontSize: 30,
                        color: QBColors.ink900,
                      ),
                    ),
                    const SizedBox(height: QBSpace.s2),
                    Text(
                      'Connecte-toi pour retrouver tes personnages sur tous '
                      'tes appareils.',
                      textAlign: TextAlign.center,
                      style: QBType.body().copyWith(
                        fontSize: QBType.sm,
                        color: QBColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_busy)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      QBButton(
                        label: 'Se connecter avec Google',
                        expand: true,
                        iconLeft: const Icon(
                          LucideIcons.logIn,
                          size: 18,
                          color: QBColors.ink900,
                        ),
                        onPressed: _signIn,
                      ),
                    if (_error case final message?) ...[
                      const SizedBox(height: QBSpace.s3),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: QBType.body().copyWith(
                          fontSize: QBType.xs,
                          color: QBColors.semanticDanger,
                        ),
                      ),
                    ],
                    const SizedBox(height: QBSpace.s3),
                    Text(
                      'Une fois connecté, tes personnages et tes tables '
                      'restent consultables sans réseau.',
                      textAlign: TextAlign.center,
                      style: QBType.body().copyWith(
                        fontSize: QBType.xs,
                        color: QBColors.textMuted,
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
