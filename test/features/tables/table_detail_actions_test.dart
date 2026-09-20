import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/design_system/components/qb_button.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';
import 'package:questbook/features/tables/table_detail_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final now = DateTime.utc(2026, 9, 19);
  final table = RemoteGameTable(
    id: 'table-1',
    title: 'Les ombres d’Arkham',
    ownerId: 'gm-1',
    role: TableRole.gameMaster,
    createdAt: now,
    updatedAt: now,
    members: [
      RemoteTableMember(
        userId: 'gm-1',
        role: TableRole.gameMaster,
        joinedAt: now,
        user: const RemoteUser(
          id: 'gm-1',
          displayName: 'Marie',
          pictureUrl: null,
        ),
      ),
    ],
    pendingInvitations: const [],
    nextSessionAt: null,
  );

  testWidgets('game master sees Inviter and Proposer as real buttons',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          canWriteProvider.overrideWithValue(true),
          tableDetailProvider.overrideWith((ref, tableId) async {
            return TableDetail(table: table, sessions: const []);
          }),
        ],
        child: const MaterialApp(
          home: TableDetailScreen(tableId: 'table-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(QBButton, '+ Proposer'),
      findsOneWidget,
      reason: 'the mockup makes Proposer a gold button, not a text link',
    );
    expect(
      find.widgetWithText(QBButton, '+ Inviter'),
      findsOneWidget,
      reason: 'the mockup makes Inviter a gold button, not a text link',
    );
  });
}
