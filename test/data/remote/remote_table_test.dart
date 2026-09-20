import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/data/remote/remote_table.dart';

void main() {
  test('parses a member who carries no email', () {
    final user = RemoteUser.fromJson({
      'id': 'user-2',
      'displayName': 'Alice',
      'pictureUrl': null,
    });

    expect(user.email, isNull);
    expect(user.label, 'Alice');
  });

  test('parses a table still carrying the old universe label', () {
    final table = RemoteGameTable.fromJson({
      'id': 'table-1',
      'title': 'Les ombres d’Arkham',
      'universeLabel': 'L’Appel de Cthulhu',
      'ownerId': 'user-1',
      'role': 'gm',
      'createdAt': '2026-09-01T10:00:00.000Z',
      'updatedAt': '2026-09-01T10:00:00.000Z',
      'members': <dynamic>[],
      'pendingInvitations': <dynamic>[],
      'nextSessionAt': null,
    });

    expect(table.title, 'Les ombres d’Arkham');
  });

  test('never falls back to the mailbox as a public label', () {
    final user = RemoteUser.fromJson({
      'id': 'user-1',
      'email': 'alice@example.com',
      'displayName': null,
      'pictureUrl': null,
    });

    expect(user.label, 'Joueur');
  });
}
