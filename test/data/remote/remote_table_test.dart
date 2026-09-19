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
