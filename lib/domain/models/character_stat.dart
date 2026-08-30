import 'package:freezed_annotation/freezed_annotation.dart';

part 'character_stat.freezed.dart';

/// Whether a [CharacterStat] row is a characteristic (shown as a StatDial),
/// a skill (shown as a percentage list row, rollable in the dice modal), or
/// a global attribute (universe-specific extra info, e.g. CoC7's Fortune or
/// age — see `domain/models/creation_mode_config.dart`'s
/// `GlobalAttributeConfig`, shown as a text badge on the sheet).
enum StatKind { characteristic, skill, attribute }

/// One characteristic or skill value on a character sheet. Generic across
/// game systems: the system's seed data decides which keys/labels exist,
/// this row just holds the value.
@freezed
abstract class CharacterStat with _$CharacterStat {
  const factory CharacterStat({
    required String id,
    required String characterId,
    required StatKind kind,
    required String key,
    required String label,
    required int value,
    String? base,
    @Default(0) int sortOrder,
  }) = _CharacterStat;
}
