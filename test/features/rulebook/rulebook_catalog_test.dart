import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/features/rulebook/content/rulebook_catalog.dart';
import 'package:questbook/features/rulebook/content/rulebook_models.dart';

void main() {
  test('sommaire lists five unique chapters and all of them are ready', () {
    expect(rulebookChapters, hasLength(5));
    expect(rulebookChapters.map((c) => c.id).toSet(), hasLength(5));
    expect(
      rulebookChapters.where((c) => c.isReady).map((c) => c.id),
      ['tests', 'combat', 'sante', 'folie', 'poursuites'],
    );
  });

  test('Tests covers the keeper-screen headings for rolls', () {
    final tests = rulebookChapterById('tests')!;
    expect(
      tests.sections.map((s) => s.id),
      [
        'difficulte',
        'des-bonus-malus',
        'comparaison',
        'developpement',
        'niveaux-de-vie',
      ],
    );
  });

  test('difficulty table keeps the three official thresholds', () {
    final table = rulebookChapterById('tests')!
        .sections
        .firstWhere((s) => s.id == 'difficulte')
        .blocks
        .whereType<RulebookTable>()
        .first;
    expect(table.rows, [
      ['Normal', '≤ la compétence'],
      ['Difficile', '≤ la moitié'],
      ['Extrême', '≤ le cinquième'],
    ]);
  });

  test('living-standards table has the six credit bands', () {
    final table = rulebookChapterById('tests')!
        .sections
        .firstWhere((s) => s.id == 'niveaux-de-vie')
        .blocks
        .whereType<RulebookTable>()
        .single;
    expect(table.rows, hasLength(6));
    expect(table.rows.map((r) => r.first), [
      'Misérable',
      'Pauvre',
      'Moyen',
      'Aisé',
      'Riche',
      'Super riche',
    ]);
  });

  test('Combat covers the keeper-screen fight headings', () {
    expect(
      rulebookChapterById('combat')!.sections.map((s) => s.id),
      [
        'ordre',
        'melee',
        'manoeuvres',
        'empale',
        'distance',
        'auto',
        'armure',
      ],
    );
  });

  test('range table keeps the four official bands', () {
    final table = rulebookChapterById('combat')!
        .sections
        .firstWhere((s) => s.id == 'distance')
        .blocks
        .whereType<RulebookTable>()
        .first;
    expect(table.rows.map((r) => r.first), [
      'Bout portant (≤ 1/5 de la base)',
      'Portée de base',
      'Longue (×2)',
      'Extrême (×4)',
    ]);
  });

  test('Santé covers wounds, treatment and other damage', () {
    expect(
      rulebookChapterById('sante')!.sections.map((s) => s.id),
      ['pv', 'agonie', 'soins', 'guerison', 'autres'],
    );
  });

  test('other-damage table keeps the usual keeper-screen sources', () {
    final table = rulebookChapterById('sante')!
        .sections
        .firstWhere((s) => s.id == 'autres')
        .blocks
        .whereType<RulebookTable>()
        .single;
    expect(table.rows.map((r) => r.first), [
      'Chute',
      'Feu (torche, vêtement)',
      'Brasier, pièce en feu',
      'Noyade, asphyxie',
      'Froid, électricité',
      'Poison',
    ]);
  });

  test('Folie covers sanity thresholds, the bout table and the Mythos cap', () {
    expect(
      rulebookChapterById('folie')!.sections.map((s) => s.id),
      ['san', 'seuils', 'crise', 'troubles', 'mythe', 'couts'],
    );
  });

  test('bout-of-madness table has ten entries', () {
    final table = rulebookChapterById('folie')!
        .sections
        .firstWhere((s) => s.id == 'crise')
        .blocks
        .whereType<RulebookTable>()
        .single;
    expect(table.rows, hasLength(10));
    expect(table.rows.first, [
      '1',
      'Amnésie — plus rien de la dernière heure, ou plus',
    ]);
    expect(table.rows.last.first, '10');
  });

  test('Poursuites covers the track, a round, hazards and wrecks', () {
    expect(
      rulebookChapterById('poursuites')!.sections.map((s) => s.id),
      ['piste', 'round', 'obstacles', 'vehicules', 'collisions'],
    );
  });

  test('vehicle table keeps the five keeper-screen mounts', () {
    final table = rulebookChapterById('poursuites')!
        .sections
        .firstWhere((s) => s.id == 'vehicules')
        .blocks
        .whereType<RulebookTable>()
        .single;
    expect(table.rows.map((r) => r.first), [
      'Bicyclette',
      'Cheval',
      'Moto',
      'Automobile',
      'Camion, autobus',
    ]);
  });

  test('unknown chapter id is a miss, not a throw', () {
    expect(rulebookChapterById('unknown'), isNull);
  });
}
