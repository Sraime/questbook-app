import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/remote_providers.dart';
import '../../design_system/components/qb_nav_drawer.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';

/// The burger menu: who is signed in, the destinations that do not earn a tab,
/// and the way out.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  static const _items = [
    QBNavDrawerItem(key: '/profil', icon: LucideIcons.user, label: 'Profil'),
    QBNavDrawerItem(
      key: '/regles',
      icon: LucideIcons.bookOpen,
      label: 'Livre de règle',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    return QBNavDrawer(
      items: _items,
      activeKey: _items
          .map((item) => item.key)
          .where(location.startsWith)
          .firstOrNull,
      onSelect: (key) {
        Navigator.of(context).pop();
        context.go(key);
      },
      header: const _AccountHeader(),
      footer: const _SignOutRow(),
    );
  }
}

/// Shows the account the app is acting as. It used to sit above the character
/// list, where it competed with the characters for attention; here it answers
/// the question at the moment it gets asked.
class _AccountHeader extends ConsumerWidget {
  const _AccountHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return const SizedBox.shrink();

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment(-0.36, -0.44),
              colors: [Color(0xFF5C4326), Color(0xFF2A1C10)],
            ),
          ),
          child: user.pictureUrl == null
              ? Icon(
                  LucideIcons.user,
                  size: 18,
                  color: QBColors.paper100.withValues(alpha: 0.8),
                )
              : Image.network(
                  user.pictureUrl!,
                  fit: BoxFit.cover,
                  // An avatar that fails to load is not worth a broken icon:
                  // the initials circle underneath says as much.
                  errorBuilder: (context, error, stack) => const SizedBox(),
                ),
        ),
        const SizedBox(width: QBSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: QBType.game().copyWith(
                  fontWeight: QBType.weightSemibold,
                  fontSize: 14,
                  color: QBColors.paper50,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: QBType.body().copyWith(
                  fontSize: QBType.xs,
                  color: QBColors.paper300.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignOutRow extends ConsumerWidget {
  const _SignOutRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        Navigator.of(context).pop();
        await ref.read(authControllerProvider.notifier).signOut();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              LucideIcons.logOut,
              size: 17,
              color: QBColors.paper100.withValues(alpha: 0.7),
            ),
            const SizedBox(width: QBSpace.s3 - 2),
            Text(
              'Se déconnecter',
              style: QBType.body().copyWith(
                fontSize: QBType.sm,
                color: QBColors.paper100.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
