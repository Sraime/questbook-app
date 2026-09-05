// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $GameSystemsTable extends GameSystems
    with TableInfo<$GameSystemsTable, GameSystemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameSystemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occupationSuggestionsMeta =
      const VerificationMeta('occupationSuggestions');
  @override
  late final GeneratedColumn<String> occupationSuggestions =
      GeneratedColumn<String>(
        'occupation_suggestions',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  @override
  List<GeneratedColumn> get $columns => [id, name, occupationSuggestions];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_systems';
  @override
  VerificationContext validateIntegrity(
    Insertable<GameSystemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('occupation_suggestions')) {
      context.handle(
        _occupationSuggestionsMeta,
        occupationSuggestions.isAcceptableOrUnknown(
          data['occupation_suggestions']!,
          _occupationSuggestionsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GameSystemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameSystemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      occupationSuggestions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occupation_suggestions'],
      )!,
    );
  }

  @override
  $GameSystemsTable createAlias(String alias) {
    return $GameSystemsTable(attachedDatabase, alias);
  }
}

class GameSystemRow extends DataClass implements Insertable<GameSystemRow> {
  final String id;
  final String name;

  /// JSON-encoded `List<String>` of suggested occupations for this system.
  final String occupationSuggestions;
  const GameSystemRow({
    required this.id,
    required this.name,
    required this.occupationSuggestions,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['occupation_suggestions'] = Variable<String>(occupationSuggestions);
    return map;
  }

  GameSystemsCompanion toCompanion(bool nullToAbsent) {
    return GameSystemsCompanion(
      id: Value(id),
      name: Value(name),
      occupationSuggestions: Value(occupationSuggestions),
    );
  }

  factory GameSystemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameSystemRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      occupationSuggestions: serializer.fromJson<String>(
        json['occupationSuggestions'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'occupationSuggestions': serializer.toJson<String>(occupationSuggestions),
    };
  }

  GameSystemRow copyWith({
    String? id,
    String? name,
    String? occupationSuggestions,
  }) => GameSystemRow(
    id: id ?? this.id,
    name: name ?? this.name,
    occupationSuggestions: occupationSuggestions ?? this.occupationSuggestions,
  );
  GameSystemRow copyWithCompanion(GameSystemsCompanion data) {
    return GameSystemRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      occupationSuggestions: data.occupationSuggestions.present
          ? data.occupationSuggestions.value
          : this.occupationSuggestions,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameSystemRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('occupationSuggestions: $occupationSuggestions')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, occupationSuggestions);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameSystemRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.occupationSuggestions == this.occupationSuggestions);
}

class GameSystemsCompanion extends UpdateCompanion<GameSystemRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> occupationSuggestions;
  final Value<int> rowid;
  const GameSystemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.occupationSuggestions = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GameSystemsCompanion.insert({
    required String id,
    required String name,
    this.occupationSuggestions = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<GameSystemRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? occupationSuggestions,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (occupationSuggestions != null)
        'occupation_suggestions': occupationSuggestions,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GameSystemsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? occupationSuggestions,
    Value<int>? rowid,
  }) {
    return GameSystemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      occupationSuggestions:
          occupationSuggestions ?? this.occupationSuggestions,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (occupationSuggestions.present) {
      map['occupation_suggestions'] = Variable<String>(
        occupationSuggestions.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameSystemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('occupationSuggestions: $occupationSuggestions, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharactersTable extends Characters
    with TableInfo<$CharactersTable, CharacterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharactersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _systemIdMeta = const VerificationMeta(
    'systemId',
  );
  @override
  late final GeneratedColumn<String> systemId = GeneratedColumn<String>(
    'system_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES game_systems (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occupationMeta = const VerificationMeta(
    'occupation',
  );
  @override
  late final GeneratedColumn<String> occupation = GeneratedColumn<String>(
    'occupation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.fromMillisecondsSinceEpoch(0)),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _needsSyncMeta = const VerificationMeta(
    'needsSync',
  );
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
    'needs_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    systemId,
    name,
    occupation,
    description,
    level,
    createdAt,
    updatedAt,
    deletedAt,
    needsSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'characters';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('system_id')) {
      context.handle(
        _systemIdMeta,
        systemId.isAcceptableOrUnknown(data['system_id']!, _systemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_systemIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('occupation')) {
      context.handle(
        _occupationMeta,
        occupation.isAcceptableOrUnknown(data['occupation']!, _occupationMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('needs_sync')) {
      context.handle(
        _needsSyncMeta,
        needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      systemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      occupation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occupation'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      needsSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_sync'],
      )!,
    );
  }

  @override
  $CharactersTable createAlias(String alias) {
    return $CharactersTable(attachedDatabase, alias);
  }
}

class CharacterRow extends DataClass implements Insertable<CharacterRow> {
  final String id;
  final String systemId;
  final String name;
  final String? occupation;
  final String? description;
  final int level;
  final DateTime createdAt;

  /// Drives last-write-wins against the API: every local mutation bumps it,
  /// and the server keeps whichever side carries the later value.
  /// The epoch default only exists so the v1 → v2 `ALTER TABLE ADD COLUMN`
  /// stays a constant expression; the migration immediately backfills it
  /// from [createdAt].
  final DateTime updatedAt;

  /// Tombstone. Rows are kept after a delete so the deletion can be pushed to
  /// the API and replicated to the user's other devices.
  final DateTime? deletedAt;

  /// Set on every local write, cleared once the API has acknowledged the push.
  /// Defaults to true so characters created before this feature existed are
  /// uploaded on the first sign-in.
  final bool needsSync;
  const CharacterRow({
    required this.id,
    required this.systemId,
    required this.name,
    this.occupation,
    this.description,
    required this.level,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.needsSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['system_id'] = Variable<String>(systemId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || occupation != null) {
      map['occupation'] = Variable<String>(occupation);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['level'] = Variable<int>(level);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['needs_sync'] = Variable<bool>(needsSync);
    return map;
  }

  CharactersCompanion toCompanion(bool nullToAbsent) {
    return CharactersCompanion(
      id: Value(id),
      systemId: Value(systemId),
      name: Value(name),
      occupation: occupation == null && nullToAbsent
          ? const Value.absent()
          : Value(occupation),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      level: Value(level),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      needsSync: Value(needsSync),
    );
  }

  factory CharacterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterRow(
      id: serializer.fromJson<String>(json['id']),
      systemId: serializer.fromJson<String>(json['systemId']),
      name: serializer.fromJson<String>(json['name']),
      occupation: serializer.fromJson<String?>(json['occupation']),
      description: serializer.fromJson<String?>(json['description']),
      level: serializer.fromJson<int>(json['level']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'systemId': serializer.toJson<String>(systemId),
      'name': serializer.toJson<String>(name),
      'occupation': serializer.toJson<String?>(occupation),
      'description': serializer.toJson<String?>(description),
      'level': serializer.toJson<int>(level),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'needsSync': serializer.toJson<bool>(needsSync),
    };
  }

  CharacterRow copyWith({
    String? id,
    String? systemId,
    String? name,
    Value<String?> occupation = const Value.absent(),
    Value<String?> description = const Value.absent(),
    int? level,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? needsSync,
  }) => CharacterRow(
    id: id ?? this.id,
    systemId: systemId ?? this.systemId,
    name: name ?? this.name,
    occupation: occupation.present ? occupation.value : this.occupation,
    description: description.present ? description.value : this.description,
    level: level ?? this.level,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    needsSync: needsSync ?? this.needsSync,
  );
  CharacterRow copyWithCompanion(CharactersCompanion data) {
    return CharacterRow(
      id: data.id.present ? data.id.value : this.id,
      systemId: data.systemId.present ? data.systemId.value : this.systemId,
      name: data.name.present ? data.name.value : this.name,
      occupation: data.occupation.present
          ? data.occupation.value
          : this.occupation,
      description: data.description.present
          ? data.description.value
          : this.description,
      level: data.level.present ? data.level.value : this.level,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterRow(')
          ..write('id: $id, ')
          ..write('systemId: $systemId, ')
          ..write('name: $name, ')
          ..write('occupation: $occupation, ')
          ..write('description: $description, ')
          ..write('level: $level, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('needsSync: $needsSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    systemId,
    name,
    occupation,
    description,
    level,
    createdAt,
    updatedAt,
    deletedAt,
    needsSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterRow &&
          other.id == this.id &&
          other.systemId == this.systemId &&
          other.name == this.name &&
          other.occupation == this.occupation &&
          other.description == this.description &&
          other.level == this.level &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.needsSync == this.needsSync);
}

class CharactersCompanion extends UpdateCompanion<CharacterRow> {
  final Value<String> id;
  final Value<String> systemId;
  final Value<String> name;
  final Value<String?> occupation;
  final Value<String?> description;
  final Value<int> level;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> needsSync;
  final Value<int> rowid;
  const CharactersCompanion({
    this.id = const Value.absent(),
    this.systemId = const Value.absent(),
    this.name = const Value.absent(),
    this.occupation = const Value.absent(),
    this.description = const Value.absent(),
    this.level = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharactersCompanion.insert({
    required String id,
    required String systemId,
    required String name,
    this.occupation = const Value.absent(),
    this.description = const Value.absent(),
    this.level = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       systemId = Value(systemId),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<CharacterRow> custom({
    Expression<String>? id,
    Expression<String>? systemId,
    Expression<String>? name,
    Expression<String>? occupation,
    Expression<String>? description,
    Expression<int>? level,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? needsSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (systemId != null) 'system_id': systemId,
      if (name != null) 'name': name,
      if (occupation != null) 'occupation': occupation,
      if (description != null) 'description': description,
      if (level != null) 'level': level,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (needsSync != null) 'needs_sync': needsSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharactersCompanion copyWith({
    Value<String>? id,
    Value<String>? systemId,
    Value<String>? name,
    Value<String?>? occupation,
    Value<String?>? description,
    Value<int>? level,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? needsSync,
    Value<int>? rowid,
  }) {
    return CharactersCompanion(
      id: id ?? this.id,
      systemId: systemId ?? this.systemId,
      name: name ?? this.name,
      occupation: occupation ?? this.occupation,
      description: description ?? this.description,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      needsSync: needsSync ?? this.needsSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (systemId.present) {
      map['system_id'] = Variable<String>(systemId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (occupation.present) {
      map['occupation'] = Variable<String>(occupation.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharactersCompanion(')
          ..write('id: $id, ')
          ..write('systemId: $systemId, ')
          ..write('name: $name, ')
          ..write('occupation: $occupation, ')
          ..write('description: $description, ')
          ..write('level: $level, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('needsSync: $needsSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharacterStatsTable extends CharacterStats
    with TableInfo<$CharacterStatsTable, CharacterStatRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES characters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseMeta = const VerificationMeta('base');
  @override
  late final GeneratedColumn<String> base = GeneratedColumn<String>(
    'base',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    characterId,
    kind,
    key,
    label,
    value,
    base,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterStatRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('base')) {
      context.handle(
        _baseMeta,
        base.isAcceptableOrUnknown(data['base']!, _baseMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterStatRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterStatRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
      base: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CharacterStatsTable createAlias(String alias) {
    return $CharacterStatsTable(attachedDatabase, alias);
  }
}

class CharacterStatRow extends DataClass
    implements Insertable<CharacterStatRow> {
  final String id;
  final String characterId;
  final String kind;
  final String key;
  final String label;
  final int value;
  final String? base;
  final int sortOrder;
  const CharacterStatRow({
    required this.id,
    required this.characterId,
    required this.kind,
    required this.key,
    required this.label,
    required this.value,
    this.base,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['character_id'] = Variable<String>(characterId);
    map['kind'] = Variable<String>(kind);
    map['key'] = Variable<String>(key);
    map['label'] = Variable<String>(label);
    map['value'] = Variable<int>(value);
    if (!nullToAbsent || base != null) {
      map['base'] = Variable<String>(base);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CharacterStatsCompanion toCompanion(bool nullToAbsent) {
    return CharacterStatsCompanion(
      id: Value(id),
      characterId: Value(characterId),
      kind: Value(kind),
      key: Value(key),
      label: Value(label),
      value: Value(value),
      base: base == null && nullToAbsent ? const Value.absent() : Value(base),
      sortOrder: Value(sortOrder),
    );
  }

  factory CharacterStatRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterStatRow(
      id: serializer.fromJson<String>(json['id']),
      characterId: serializer.fromJson<String>(json['characterId']),
      kind: serializer.fromJson<String>(json['kind']),
      key: serializer.fromJson<String>(json['key']),
      label: serializer.fromJson<String>(json['label']),
      value: serializer.fromJson<int>(json['value']),
      base: serializer.fromJson<String?>(json['base']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'characterId': serializer.toJson<String>(characterId),
      'kind': serializer.toJson<String>(kind),
      'key': serializer.toJson<String>(key),
      'label': serializer.toJson<String>(label),
      'value': serializer.toJson<int>(value),
      'base': serializer.toJson<String?>(base),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CharacterStatRow copyWith({
    String? id,
    String? characterId,
    String? kind,
    String? key,
    String? label,
    int? value,
    Value<String?> base = const Value.absent(),
    int? sortOrder,
  }) => CharacterStatRow(
    id: id ?? this.id,
    characterId: characterId ?? this.characterId,
    kind: kind ?? this.kind,
    key: key ?? this.key,
    label: label ?? this.label,
    value: value ?? this.value,
    base: base.present ? base.value : this.base,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CharacterStatRow copyWithCompanion(CharacterStatsCompanion data) {
    return CharacterStatRow(
      id: data.id.present ? data.id.value : this.id,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      kind: data.kind.present ? data.kind.value : this.kind,
      key: data.key.present ? data.key.value : this.key,
      label: data.label.present ? data.label.value : this.label,
      value: data.value.present ? data.value.value : this.value,
      base: data.base.present ? data.base.value : this.base,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterStatRow(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('kind: $kind, ')
          ..write('key: $key, ')
          ..write('label: $label, ')
          ..write('value: $value, ')
          ..write('base: $base, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, characterId, kind, key, label, value, base, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterStatRow &&
          other.id == this.id &&
          other.characterId == this.characterId &&
          other.kind == this.kind &&
          other.key == this.key &&
          other.label == this.label &&
          other.value == this.value &&
          other.base == this.base &&
          other.sortOrder == this.sortOrder);
}

class CharacterStatsCompanion extends UpdateCompanion<CharacterStatRow> {
  final Value<String> id;
  final Value<String> characterId;
  final Value<String> kind;
  final Value<String> key;
  final Value<String> label;
  final Value<int> value;
  final Value<String?> base;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CharacterStatsCompanion({
    this.id = const Value.absent(),
    this.characterId = const Value.absent(),
    this.kind = const Value.absent(),
    this.key = const Value.absent(),
    this.label = const Value.absent(),
    this.value = const Value.absent(),
    this.base = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharacterStatsCompanion.insert({
    required String id,
    required String characterId,
    required String kind,
    required String key,
    required String label,
    required int value,
    this.base = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       characterId = Value(characterId),
       kind = Value(kind),
       key = Value(key),
       label = Value(label),
       value = Value(value);
  static Insertable<CharacterStatRow> custom({
    Expression<String>? id,
    Expression<String>? characterId,
    Expression<String>? kind,
    Expression<String>? key,
    Expression<String>? label,
    Expression<int>? value,
    Expression<String>? base,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (characterId != null) 'character_id': characterId,
      if (kind != null) 'kind': kind,
      if (key != null) 'key': key,
      if (label != null) 'label': label,
      if (value != null) 'value': value,
      if (base != null) 'base': base,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharacterStatsCompanion copyWith({
    Value<String>? id,
    Value<String>? characterId,
    Value<String>? kind,
    Value<String>? key,
    Value<String>? label,
    Value<int>? value,
    Value<String?>? base,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return CharacterStatsCompanion(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      kind: kind ?? this.kind,
      key: key ?? this.key,
      label: label ?? this.label,
      value: value ?? this.value,
      base: base ?? this.base,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (base.present) {
      map['base'] = Variable<String>(base.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterStatsCompanion(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('kind: $kind, ')
          ..write('key: $key, ')
          ..write('label: $label, ')
          ..write('value: $value, ')
          ..write('base: $base, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharacterResourcesTable extends CharacterResources
    with TableInfo<$CharacterResourcesTable, CharacterResourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterResourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES characters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentMeta = const VerificationMeta(
    'current',
  );
  @override
  late final GeneratedColumn<int> current = GeneratedColumn<int>(
    'current',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxMeta = const VerificationMeta('max');
  @override
  late final GeneratedColumn<int> max = GeneratedColumn<int>(
    'max',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toneMeta = const VerificationMeta('tone');
  @override
  late final GeneratedColumn<String> tone = GeneratedColumn<String>(
    'tone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('neutral'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    characterId,
    key,
    label,
    current,
    max,
    tone,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_resources';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterResourceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('current')) {
      context.handle(
        _currentMeta,
        current.isAcceptableOrUnknown(data['current']!, _currentMeta),
      );
    } else if (isInserting) {
      context.missing(_currentMeta);
    }
    if (data.containsKey('max')) {
      context.handle(
        _maxMeta,
        max.isAcceptableOrUnknown(data['max']!, _maxMeta),
      );
    } else if (isInserting) {
      context.missing(_maxMeta);
    }
    if (data.containsKey('tone')) {
      context.handle(
        _toneMeta,
        tone.isAcceptableOrUnknown(data['tone']!, _toneMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterResourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterResourceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      current: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current'],
      )!,
      max: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max'],
      )!,
      tone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tone'],
      )!,
    );
  }

  @override
  $CharacterResourcesTable createAlias(String alias) {
    return $CharacterResourcesTable(attachedDatabase, alias);
  }
}

class CharacterResourceRow extends DataClass
    implements Insertable<CharacterResourceRow> {
  final String id;
  final String characterId;
  final String key;
  final String label;
  final int current;
  final int max;
  final String tone;
  const CharacterResourceRow({
    required this.id,
    required this.characterId,
    required this.key,
    required this.label,
    required this.current,
    required this.max,
    required this.tone,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['character_id'] = Variable<String>(characterId);
    map['key'] = Variable<String>(key);
    map['label'] = Variable<String>(label);
    map['current'] = Variable<int>(current);
    map['max'] = Variable<int>(max);
    map['tone'] = Variable<String>(tone);
    return map;
  }

  CharacterResourcesCompanion toCompanion(bool nullToAbsent) {
    return CharacterResourcesCompanion(
      id: Value(id),
      characterId: Value(characterId),
      key: Value(key),
      label: Value(label),
      current: Value(current),
      max: Value(max),
      tone: Value(tone),
    );
  }

  factory CharacterResourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterResourceRow(
      id: serializer.fromJson<String>(json['id']),
      characterId: serializer.fromJson<String>(json['characterId']),
      key: serializer.fromJson<String>(json['key']),
      label: serializer.fromJson<String>(json['label']),
      current: serializer.fromJson<int>(json['current']),
      max: serializer.fromJson<int>(json['max']),
      tone: serializer.fromJson<String>(json['tone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'characterId': serializer.toJson<String>(characterId),
      'key': serializer.toJson<String>(key),
      'label': serializer.toJson<String>(label),
      'current': serializer.toJson<int>(current),
      'max': serializer.toJson<int>(max),
      'tone': serializer.toJson<String>(tone),
    };
  }

  CharacterResourceRow copyWith({
    String? id,
    String? characterId,
    String? key,
    String? label,
    int? current,
    int? max,
    String? tone,
  }) => CharacterResourceRow(
    id: id ?? this.id,
    characterId: characterId ?? this.characterId,
    key: key ?? this.key,
    label: label ?? this.label,
    current: current ?? this.current,
    max: max ?? this.max,
    tone: tone ?? this.tone,
  );
  CharacterResourceRow copyWithCompanion(CharacterResourcesCompanion data) {
    return CharacterResourceRow(
      id: data.id.present ? data.id.value : this.id,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      key: data.key.present ? data.key.value : this.key,
      label: data.label.present ? data.label.value : this.label,
      current: data.current.present ? data.current.value : this.current,
      max: data.max.present ? data.max.value : this.max,
      tone: data.tone.present ? data.tone.value : this.tone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterResourceRow(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('key: $key, ')
          ..write('label: $label, ')
          ..write('current: $current, ')
          ..write('max: $max, ')
          ..write('tone: $tone')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, characterId, key, label, current, max, tone);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterResourceRow &&
          other.id == this.id &&
          other.characterId == this.characterId &&
          other.key == this.key &&
          other.label == this.label &&
          other.current == this.current &&
          other.max == this.max &&
          other.tone == this.tone);
}

class CharacterResourcesCompanion
    extends UpdateCompanion<CharacterResourceRow> {
  final Value<String> id;
  final Value<String> characterId;
  final Value<String> key;
  final Value<String> label;
  final Value<int> current;
  final Value<int> max;
  final Value<String> tone;
  final Value<int> rowid;
  const CharacterResourcesCompanion({
    this.id = const Value.absent(),
    this.characterId = const Value.absent(),
    this.key = const Value.absent(),
    this.label = const Value.absent(),
    this.current = const Value.absent(),
    this.max = const Value.absent(),
    this.tone = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharacterResourcesCompanion.insert({
    required String id,
    required String characterId,
    required String key,
    required String label,
    required int current,
    required int max,
    this.tone = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       characterId = Value(characterId),
       key = Value(key),
       label = Value(label),
       current = Value(current),
       max = Value(max);
  static Insertable<CharacterResourceRow> custom({
    Expression<String>? id,
    Expression<String>? characterId,
    Expression<String>? key,
    Expression<String>? label,
    Expression<int>? current,
    Expression<int>? max,
    Expression<String>? tone,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (characterId != null) 'character_id': characterId,
      if (key != null) 'key': key,
      if (label != null) 'label': label,
      if (current != null) 'current': current,
      if (max != null) 'max': max,
      if (tone != null) 'tone': tone,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharacterResourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? characterId,
    Value<String>? key,
    Value<String>? label,
    Value<int>? current,
    Value<int>? max,
    Value<String>? tone,
    Value<int>? rowid,
  }) {
    return CharacterResourcesCompanion(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      key: key ?? this.key,
      label: label ?? this.label,
      current: current ?? this.current,
      max: max ?? this.max,
      tone: tone ?? this.tone,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (current.present) {
      map['current'] = Variable<int>(current.value);
    }
    if (max.present) {
      map['max'] = Variable<int>(max.value);
    }
    if (tone.present) {
      map['tone'] = Variable<String>(tone.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterResourcesCompanion(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('key: $key, ')
          ..write('label: $label, ')
          ..write('current: $current, ')
          ..write('max: $max, ')
          ..write('tone: $tone, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryItemsTable extends InventoryItems
    with TableInfo<$InventoryItemsTable, InventoryItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES characters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<int> qty = GeneratedColumn<int>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<String> weight = GeneratedColumn<String>(
    'weight',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, characterId, name, qty, weight];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weight'],
      ),
    );
  }

  @override
  $InventoryItemsTable createAlias(String alias) {
    return $InventoryItemsTable(attachedDatabase, alias);
  }
}

class InventoryItemRow extends DataClass
    implements Insertable<InventoryItemRow> {
  final String id;
  final String characterId;
  final String name;
  final int qty;
  final String? weight;
  const InventoryItemRow({
    required this.id,
    required this.characterId,
    required this.name,
    required this.qty,
    this.weight,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['character_id'] = Variable<String>(characterId);
    map['name'] = Variable<String>(name);
    map['qty'] = Variable<int>(qty);
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<String>(weight);
    }
    return map;
  }

  InventoryItemsCompanion toCompanion(bool nullToAbsent) {
    return InventoryItemsCompanion(
      id: Value(id),
      characterId: Value(characterId),
      name: Value(name),
      qty: Value(qty),
      weight: weight == null && nullToAbsent
          ? const Value.absent()
          : Value(weight),
    );
  }

  factory InventoryItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryItemRow(
      id: serializer.fromJson<String>(json['id']),
      characterId: serializer.fromJson<String>(json['characterId']),
      name: serializer.fromJson<String>(json['name']),
      qty: serializer.fromJson<int>(json['qty']),
      weight: serializer.fromJson<String?>(json['weight']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'characterId': serializer.toJson<String>(characterId),
      'name': serializer.toJson<String>(name),
      'qty': serializer.toJson<int>(qty),
      'weight': serializer.toJson<String?>(weight),
    };
  }

  InventoryItemRow copyWith({
    String? id,
    String? characterId,
    String? name,
    int? qty,
    Value<String?> weight = const Value.absent(),
  }) => InventoryItemRow(
    id: id ?? this.id,
    characterId: characterId ?? this.characterId,
    name: name ?? this.name,
    qty: qty ?? this.qty,
    weight: weight.present ? weight.value : this.weight,
  );
  InventoryItemRow copyWithCompanion(InventoryItemsCompanion data) {
    return InventoryItemRow(
      id: data.id.present ? data.id.value : this.id,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      name: data.name.present ? data.name.value : this.name,
      qty: data.qty.present ? data.qty.value : this.qty,
      weight: data.weight.present ? data.weight.value : this.weight,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItemRow(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('name: $name, ')
          ..write('qty: $qty, ')
          ..write('weight: $weight')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, characterId, name, qty, weight);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryItemRow &&
          other.id == this.id &&
          other.characterId == this.characterId &&
          other.name == this.name &&
          other.qty == this.qty &&
          other.weight == this.weight);
}

class InventoryItemsCompanion extends UpdateCompanion<InventoryItemRow> {
  final Value<String> id;
  final Value<String> characterId;
  final Value<String> name;
  final Value<int> qty;
  final Value<String?> weight;
  final Value<int> rowid;
  const InventoryItemsCompanion({
    this.id = const Value.absent(),
    this.characterId = const Value.absent(),
    this.name = const Value.absent(),
    this.qty = const Value.absent(),
    this.weight = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryItemsCompanion.insert({
    required String id,
    required String characterId,
    required String name,
    this.qty = const Value.absent(),
    this.weight = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       characterId = Value(characterId),
       name = Value(name);
  static Insertable<InventoryItemRow> custom({
    Expression<String>? id,
    Expression<String>? characterId,
    Expression<String>? name,
    Expression<int>? qty,
    Expression<String>? weight,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (characterId != null) 'character_id': characterId,
      if (name != null) 'name': name,
      if (qty != null) 'qty': qty,
      if (weight != null) 'weight': weight,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? characterId,
    Value<String>? name,
    Value<int>? qty,
    Value<String?>? weight,
    Value<int>? rowid,
  }) {
    return InventoryItemsCompanion(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      qty: qty ?? this.qty,
      weight: weight ?? this.weight,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (qty.present) {
      map['qty'] = Variable<int>(qty.value);
    }
    if (weight.present) {
      map['weight'] = Variable<String>(weight.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItemsCompanion(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('name: $name, ')
          ..write('qty: $qty, ')
          ..write('weight: $weight, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GameTablesTable extends GameTables
    with TableInfo<$GameTablesTable, GameTableRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameTablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _universeLabelMeta = const VerificationMeta(
    'universeLabel',
  );
  @override
  late final GeneratedColumn<String> universeLabel = GeneratedColumn<String>(
    'universe_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextSessionMeta = const VerificationMeta(
    'nextSession',
  );
  @override
  late final GeneratedColumn<DateTime> nextSession = GeneratedColumn<DateTime>(
    'next_session',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _systemIdMeta = const VerificationMeta(
    'systemId',
  );
  @override
  late final GeneratedColumn<String> systemId = GeneratedColumn<String>(
    'system_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES game_systems (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    universeLabel,
    nextSession,
    systemId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_tables';
  @override
  VerificationContext validateIntegrity(
    Insertable<GameTableRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('universe_label')) {
      context.handle(
        _universeLabelMeta,
        universeLabel.isAcceptableOrUnknown(
          data['universe_label']!,
          _universeLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_universeLabelMeta);
    }
    if (data.containsKey('next_session')) {
      context.handle(
        _nextSessionMeta,
        nextSession.isAcceptableOrUnknown(
          data['next_session']!,
          _nextSessionMeta,
        ),
      );
    }
    if (data.containsKey('system_id')) {
      context.handle(
        _systemIdMeta,
        systemId.isAcceptableOrUnknown(data['system_id']!, _systemIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GameTableRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameTableRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      universeLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}universe_label'],
      )!,
      nextSession: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_session'],
      ),
      systemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system_id'],
      ),
    );
  }

  @override
  $GameTablesTable createAlias(String alias) {
    return $GameTablesTable(attachedDatabase, alias);
  }
}

class GameTableRow extends DataClass implements Insertable<GameTableRow> {
  final String id;
  final String title;
  final String universeLabel;
  final DateTime? nextSession;
  final String? systemId;
  const GameTableRow({
    required this.id,
    required this.title,
    required this.universeLabel,
    this.nextSession,
    this.systemId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['universe_label'] = Variable<String>(universeLabel);
    if (!nullToAbsent || nextSession != null) {
      map['next_session'] = Variable<DateTime>(nextSession);
    }
    if (!nullToAbsent || systemId != null) {
      map['system_id'] = Variable<String>(systemId);
    }
    return map;
  }

  GameTablesCompanion toCompanion(bool nullToAbsent) {
    return GameTablesCompanion(
      id: Value(id),
      title: Value(title),
      universeLabel: Value(universeLabel),
      nextSession: nextSession == null && nullToAbsent
          ? const Value.absent()
          : Value(nextSession),
      systemId: systemId == null && nullToAbsent
          ? const Value.absent()
          : Value(systemId),
    );
  }

  factory GameTableRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameTableRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      universeLabel: serializer.fromJson<String>(json['universeLabel']),
      nextSession: serializer.fromJson<DateTime?>(json['nextSession']),
      systemId: serializer.fromJson<String?>(json['systemId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'universeLabel': serializer.toJson<String>(universeLabel),
      'nextSession': serializer.toJson<DateTime?>(nextSession),
      'systemId': serializer.toJson<String?>(systemId),
    };
  }

  GameTableRow copyWith({
    String? id,
    String? title,
    String? universeLabel,
    Value<DateTime?> nextSession = const Value.absent(),
    Value<String?> systemId = const Value.absent(),
  }) => GameTableRow(
    id: id ?? this.id,
    title: title ?? this.title,
    universeLabel: universeLabel ?? this.universeLabel,
    nextSession: nextSession.present ? nextSession.value : this.nextSession,
    systemId: systemId.present ? systemId.value : this.systemId,
  );
  GameTableRow copyWithCompanion(GameTablesCompanion data) {
    return GameTableRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      universeLabel: data.universeLabel.present
          ? data.universeLabel.value
          : this.universeLabel,
      nextSession: data.nextSession.present
          ? data.nextSession.value
          : this.nextSession,
      systemId: data.systemId.present ? data.systemId.value : this.systemId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameTableRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('universeLabel: $universeLabel, ')
          ..write('nextSession: $nextSession, ')
          ..write('systemId: $systemId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, universeLabel, nextSession, systemId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameTableRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.universeLabel == this.universeLabel &&
          other.nextSession == this.nextSession &&
          other.systemId == this.systemId);
}

class GameTablesCompanion extends UpdateCompanion<GameTableRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> universeLabel;
  final Value<DateTime?> nextSession;
  final Value<String?> systemId;
  final Value<int> rowid;
  const GameTablesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.universeLabel = const Value.absent(),
    this.nextSession = const Value.absent(),
    this.systemId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GameTablesCompanion.insert({
    required String id,
    required String title,
    required String universeLabel,
    this.nextSession = const Value.absent(),
    this.systemId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       universeLabel = Value(universeLabel);
  static Insertable<GameTableRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? universeLabel,
    Expression<DateTime>? nextSession,
    Expression<String>? systemId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (universeLabel != null) 'universe_label': universeLabel,
      if (nextSession != null) 'next_session': nextSession,
      if (systemId != null) 'system_id': systemId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GameTablesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? universeLabel,
    Value<DateTime?>? nextSession,
    Value<String?>? systemId,
    Value<int>? rowid,
  }) {
    return GameTablesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      universeLabel: universeLabel ?? this.universeLabel,
      nextSession: nextSession ?? this.nextSession,
      systemId: systemId ?? this.systemId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (universeLabel.present) {
      map['universe_label'] = Variable<String>(universeLabel.value);
    }
    if (nextSession.present) {
      map['next_session'] = Variable<DateTime>(nextSession.value);
    }
    if (systemId.present) {
      map['system_id'] = Variable<String>(systemId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameTablesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('universeLabel: $universeLabel, ')
          ..write('nextSession: $nextSession, ')
          ..write('systemId: $systemId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataTable extends SyncMetadata
    with TableInfo<$SyncMetadataTable, SyncMetadataRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetadataRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncMetadataRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncMetadataTable createAlias(String alias) {
    return $SyncMetadataTable(attachedDatabase, alias);
  }
}

class SyncMetadataRow extends DataClass implements Insertable<SyncMetadataRow> {
  final String key;
  final String value;
  const SyncMetadataRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncMetadataCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataCompanion(key: Value(key), value: Value(value));
  }

  factory SyncMetadataRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncMetadataRow copyWith({String? key, String? value}) =>
      SyncMetadataRow(key: key ?? this.key, value: value ?? this.value);
  SyncMetadataRow copyWithCompanion(SyncMetadataCompanion data) {
    return SyncMetadataRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncMetadataCompanion extends UpdateCompanion<SyncMetadataRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncMetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetadataCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncMetadataRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetadataCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncMetadataCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GameSystemsTable gameSystems = $GameSystemsTable(this);
  late final $CharactersTable characters = $CharactersTable(this);
  late final $CharacterStatsTable characterStats = $CharacterStatsTable(this);
  late final $CharacterResourcesTable characterResources =
      $CharacterResourcesTable(this);
  late final $InventoryItemsTable inventoryItems = $InventoryItemsTable(this);
  late final $GameTablesTable gameTables = $GameTablesTable(this);
  late final $SyncMetadataTable syncMetadata = $SyncMetadataTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    gameSystems,
    characters,
    characterStats,
    characterResources,
    inventoryItems,
    gameTables,
    syncMetadata,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'characters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('character_stats', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'characters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('character_resources', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'characters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('inventory_items', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$GameSystemsTableCreateCompanionBuilder =
    GameSystemsCompanion Function({
      required String id,
      required String name,
      Value<String> occupationSuggestions,
      Value<int> rowid,
    });
typedef $$GameSystemsTableUpdateCompanionBuilder =
    GameSystemsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> occupationSuggestions,
      Value<int> rowid,
    });

final class $$GameSystemsTableReferences
    extends BaseReferences<_$AppDatabase, $GameSystemsTable, GameSystemRow> {
  $$GameSystemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CharactersTable, List<CharacterRow>>
  _charactersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.characters,
    aliasName: 'game_systems__id__characters__system_id',
  );

  $$CharactersTableProcessedTableManager get charactersRefs {
    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.systemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_charactersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GameTablesTable, List<GameTableRow>>
  _gameTablesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.gameTables,
    aliasName: 'game_systems__id__game_tables__system_id',
  );

  $$GameTablesTableProcessedTableManager get gameTablesRefs {
    final manager = $$GameTablesTableTableManager(
      $_db,
      $_db.gameTables,
    ).filter((f) => f.systemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_gameTablesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GameSystemsTableFilterComposer
    extends Composer<_$AppDatabase, $GameSystemsTable> {
  $$GameSystemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occupationSuggestions => $composableBuilder(
    column: $table.occupationSuggestions,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> charactersRefs(
    Expression<bool> Function($$CharactersTableFilterComposer f) f,
  ) {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.systemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> gameTablesRefs(
    Expression<bool> Function($$GameTablesTableFilterComposer f) f,
  ) {
    final $$GameTablesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gameTables,
      getReferencedColumn: (t) => t.systemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GameTablesTableFilterComposer(
            $db: $db,
            $table: $db.gameTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GameSystemsTableOrderingComposer
    extends Composer<_$AppDatabase, $GameSystemsTable> {
  $$GameSystemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occupationSuggestions => $composableBuilder(
    column: $table.occupationSuggestions,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GameSystemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GameSystemsTable> {
  $$GameSystemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get occupationSuggestions => $composableBuilder(
    column: $table.occupationSuggestions,
    builder: (column) => column,
  );

  Expression<T> charactersRefs<T extends Object>(
    Expression<T> Function($$CharactersTableAnnotationComposer a) f,
  ) {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.systemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> gameTablesRefs<T extends Object>(
    Expression<T> Function($$GameTablesTableAnnotationComposer a) f,
  ) {
    final $$GameTablesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gameTables,
      getReferencedColumn: (t) => t.systemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GameTablesTableAnnotationComposer(
            $db: $db,
            $table: $db.gameTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GameSystemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GameSystemsTable,
          GameSystemRow,
          $$GameSystemsTableFilterComposer,
          $$GameSystemsTableOrderingComposer,
          $$GameSystemsTableAnnotationComposer,
          $$GameSystemsTableCreateCompanionBuilder,
          $$GameSystemsTableUpdateCompanionBuilder,
          (GameSystemRow, $$GameSystemsTableReferences),
          GameSystemRow,
          PrefetchHooks Function({bool charactersRefs, bool gameTablesRefs})
        > {
  $$GameSystemsTableTableManager(_$AppDatabase db, $GameSystemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameSystemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GameSystemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GameSystemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> occupationSuggestions = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GameSystemsCompanion(
                id: id,
                name: name,
                occupationSuggestions: occupationSuggestions,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> occupationSuggestions = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GameSystemsCompanion.insert(
                id: id,
                name: name,
                occupationSuggestions: occupationSuggestions,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GameSystemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({charactersRefs = false, gameTablesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (charactersRefs) db.characters,
                    if (gameTablesRefs) db.gameTables,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (charactersRefs)
                        await $_getPrefetchedData<
                          GameSystemRow,
                          $GameSystemsTable,
                          CharacterRow
                        >(
                          currentTable: table,
                          referencedTable: $$GameSystemsTableReferences
                              ._charactersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GameSystemsTableReferences(
                                db,
                                table,
                                p0,
                              ).charactersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.systemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (gameTablesRefs)
                        await $_getPrefetchedData<
                          GameSystemRow,
                          $GameSystemsTable,
                          GameTableRow
                        >(
                          currentTable: table,
                          referencedTable: $$GameSystemsTableReferences
                              ._gameTablesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GameSystemsTableReferences(
                                db,
                                table,
                                p0,
                              ).gameTablesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.systemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GameSystemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GameSystemsTable,
      GameSystemRow,
      $$GameSystemsTableFilterComposer,
      $$GameSystemsTableOrderingComposer,
      $$GameSystemsTableAnnotationComposer,
      $$GameSystemsTableCreateCompanionBuilder,
      $$GameSystemsTableUpdateCompanionBuilder,
      (GameSystemRow, $$GameSystemsTableReferences),
      GameSystemRow,
      PrefetchHooks Function({bool charactersRefs, bool gameTablesRefs})
    >;
typedef $$CharactersTableCreateCompanionBuilder =
    CharactersCompanion Function({
      required String id,
      required String systemId,
      required String name,
      Value<String?> occupation,
      Value<String?> description,
      Value<int> level,
      required DateTime createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> needsSync,
      Value<int> rowid,
    });
typedef $$CharactersTableUpdateCompanionBuilder =
    CharactersCompanion Function({
      Value<String> id,
      Value<String> systemId,
      Value<String> name,
      Value<String?> occupation,
      Value<String?> description,
      Value<int> level,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> needsSync,
      Value<int> rowid,
    });

final class $$CharactersTableReferences
    extends BaseReferences<_$AppDatabase, $CharactersTable, CharacterRow> {
  $$CharactersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GameSystemsTable _systemIdTable(_$AppDatabase db) =>
      db.gameSystems.createAlias('characters__system_id__game_systems__id');

  $$GameSystemsTableProcessedTableManager get systemId {
    final $_column = $_itemColumn<String>('system_id')!;

    final manager = $$GameSystemsTableTableManager(
      $_db,
      $_db.gameSystems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_systemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CharacterStatsTable, List<CharacterStatRow>>
  _characterStatsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.characterStats,
    aliasName: 'characters__id__character_stats__character_id',
  );

  $$CharacterStatsTableProcessedTableManager get characterStatsRefs {
    final manager = $$CharacterStatsTableTableManager(
      $_db,
      $_db.characterStats,
    ).filter((f) => f.characterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_characterStatsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CharacterResourcesTable,
    List<CharacterResourceRow>
  >
  _characterResourcesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.characterResources,
        aliasName: 'characters__id__character_resources__character_id',
      );

  $$CharacterResourcesTableProcessedTableManager get characterResourcesRefs {
    final manager = $$CharacterResourcesTableTableManager(
      $_db,
      $_db.characterResources,
    ).filter((f) => f.characterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _characterResourcesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InventoryItemsTable, List<InventoryItemRow>>
  _inventoryItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.inventoryItems,
    aliasName: 'characters__id__inventory_items__character_id',
  );

  $$InventoryItemsTableProcessedTableManager get inventoryItemsRefs {
    final manager = $$InventoryItemsTableTableManager(
      $_db,
      $_db.inventoryItems,
    ).filter((f) => f.characterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_inventoryItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CharactersTableFilterComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occupation => $composableBuilder(
    column: $table.occupation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsSync => $composableBuilder(
    column: $table.needsSync,
    builder: (column) => ColumnFilters(column),
  );

  $$GameSystemsTableFilterComposer get systemId {
    final $$GameSystemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.gameSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GameSystemsTableFilterComposer(
            $db: $db,
            $table: $db.gameSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> characterStatsRefs(
    Expression<bool> Function($$CharacterStatsTableFilterComposer f) f,
  ) {
    final $$CharacterStatsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterStats,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharacterStatsTableFilterComposer(
            $db: $db,
            $table: $db.characterStats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> characterResourcesRefs(
    Expression<bool> Function($$CharacterResourcesTableFilterComposer f) f,
  ) {
    final $$CharacterResourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterResources,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharacterResourcesTableFilterComposer(
            $db: $db,
            $table: $db.characterResources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> inventoryItemsRefs(
    Expression<bool> Function($$InventoryItemsTableFilterComposer f) f,
  ) {
    final $$InventoryItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoryItems,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryItemsTableFilterComposer(
            $db: $db,
            $table: $db.inventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CharactersTableOrderingComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occupation => $composableBuilder(
    column: $table.occupation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsSync => $composableBuilder(
    column: $table.needsSync,
    builder: (column) => ColumnOrderings(column),
  );

  $$GameSystemsTableOrderingComposer get systemId {
    final $$GameSystemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.gameSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GameSystemsTableOrderingComposer(
            $db: $db,
            $table: $db.gameSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharactersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get occupation => $composableBuilder(
    column: $table.occupation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);

  $$GameSystemsTableAnnotationComposer get systemId {
    final $$GameSystemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.gameSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GameSystemsTableAnnotationComposer(
            $db: $db,
            $table: $db.gameSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> characterStatsRefs<T extends Object>(
    Expression<T> Function($$CharacterStatsTableAnnotationComposer a) f,
  ) {
    final $$CharacterStatsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterStats,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharacterStatsTableAnnotationComposer(
            $db: $db,
            $table: $db.characterStats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> characterResourcesRefs<T extends Object>(
    Expression<T> Function($$CharacterResourcesTableAnnotationComposer a) f,
  ) {
    final $$CharacterResourcesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.characterResources,
          getReferencedColumn: (t) => t.characterId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CharacterResourcesTableAnnotationComposer(
                $db: $db,
                $table: $db.characterResources,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> inventoryItemsRefs<T extends Object>(
    Expression<T> Function($$InventoryItemsTableAnnotationComposer a) f,
  ) {
    final $$InventoryItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoryItems,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.inventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CharactersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharactersTable,
          CharacterRow,
          $$CharactersTableFilterComposer,
          $$CharactersTableOrderingComposer,
          $$CharactersTableAnnotationComposer,
          $$CharactersTableCreateCompanionBuilder,
          $$CharactersTableUpdateCompanionBuilder,
          (CharacterRow, $$CharactersTableReferences),
          CharacterRow,
          PrefetchHooks Function({
            bool systemId,
            bool characterStatsRefs,
            bool characterResourcesRefs,
            bool inventoryItemsRefs,
          })
        > {
  $$CharactersTableTableManager(_$AppDatabase db, $CharactersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharactersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharactersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharactersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> systemId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> occupation = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> needsSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharactersCompanion(
                id: id,
                systemId: systemId,
                name: name,
                occupation: occupation,
                description: description,
                level: level,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                needsSync: needsSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String systemId,
                required String name,
                Value<String?> occupation = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> level = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> needsSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharactersCompanion.insert(
                id: id,
                systemId: systemId,
                name: name,
                occupation: occupation,
                description: description,
                level: level,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                needsSync: needsSync,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CharactersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                systemId = false,
                characterStatsRefs = false,
                characterResourcesRefs = false,
                inventoryItemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (characterStatsRefs) db.characterStats,
                    if (characterResourcesRefs) db.characterResources,
                    if (inventoryItemsRefs) db.inventoryItems,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (systemId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.systemId,
                                    referencedTable: $$CharactersTableReferences
                                        ._systemIdTable(db),
                                    referencedColumn:
                                        $$CharactersTableReferences
                                            ._systemIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (characterStatsRefs)
                        await $_getPrefetchedData<
                          CharacterRow,
                          $CharactersTable,
                          CharacterStatRow
                        >(
                          currentTable: table,
                          referencedTable: $$CharactersTableReferences
                              ._characterStatsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CharactersTableReferences(
                                db,
                                table,
                                p0,
                              ).characterStatsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.characterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (characterResourcesRefs)
                        await $_getPrefetchedData<
                          CharacterRow,
                          $CharactersTable,
                          CharacterResourceRow
                        >(
                          currentTable: table,
                          referencedTable: $$CharactersTableReferences
                              ._characterResourcesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CharactersTableReferences(
                                db,
                                table,
                                p0,
                              ).characterResourcesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.characterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (inventoryItemsRefs)
                        await $_getPrefetchedData<
                          CharacterRow,
                          $CharactersTable,
                          InventoryItemRow
                        >(
                          currentTable: table,
                          referencedTable: $$CharactersTableReferences
                              ._inventoryItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CharactersTableReferences(
                                db,
                                table,
                                p0,
                              ).inventoryItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.characterId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CharactersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharactersTable,
      CharacterRow,
      $$CharactersTableFilterComposer,
      $$CharactersTableOrderingComposer,
      $$CharactersTableAnnotationComposer,
      $$CharactersTableCreateCompanionBuilder,
      $$CharactersTableUpdateCompanionBuilder,
      (CharacterRow, $$CharactersTableReferences),
      CharacterRow,
      PrefetchHooks Function({
        bool systemId,
        bool characterStatsRefs,
        bool characterResourcesRefs,
        bool inventoryItemsRefs,
      })
    >;
typedef $$CharacterStatsTableCreateCompanionBuilder =
    CharacterStatsCompanion Function({
      required String id,
      required String characterId,
      required String kind,
      required String key,
      required String label,
      required int value,
      Value<String?> base,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$CharacterStatsTableUpdateCompanionBuilder =
    CharacterStatsCompanion Function({
      Value<String> id,
      Value<String> characterId,
      Value<String> kind,
      Value<String> key,
      Value<String> label,
      Value<int> value,
      Value<String?> base,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$CharacterStatsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CharacterStatsTable, CharacterStatRow> {
  $$CharacterStatsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CharactersTable _characterIdTable(_$AppDatabase db) => db.characters
      .createAlias('character_stats__character_id__characters__id');

  $$CharactersTableProcessedTableManager get characterId {
    final $_column = $_itemColumn<String>('character_id')!;

    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_characterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CharacterStatsTableFilterComposer
    extends Composer<_$AppDatabase, $CharacterStatsTable> {
  $$CharacterStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get base => $composableBuilder(
    column: $table.base,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$CharactersTableFilterComposer get characterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterStatsTableOrderingComposer
    extends Composer<_$AppDatabase, $CharacterStatsTable> {
  $$CharacterStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get base => $composableBuilder(
    column: $table.base,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$CharactersTableOrderingComposer get characterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableOrderingComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterStatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharacterStatsTable> {
  $$CharacterStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get base =>
      $composableBuilder(column: $table.base, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$CharactersTableAnnotationComposer get characterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterStatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharacterStatsTable,
          CharacterStatRow,
          $$CharacterStatsTableFilterComposer,
          $$CharacterStatsTableOrderingComposer,
          $$CharacterStatsTableAnnotationComposer,
          $$CharacterStatsTableCreateCompanionBuilder,
          $$CharacterStatsTableUpdateCompanionBuilder,
          (CharacterStatRow, $$CharacterStatsTableReferences),
          CharacterStatRow,
          PrefetchHooks Function({bool characterId})
        > {
  $$CharacterStatsTableTableManager(
    _$AppDatabase db,
    $CharacterStatsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharacterStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharacterStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> characterId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> value = const Value.absent(),
                Value<String?> base = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterStatsCompanion(
                id: id,
                characterId: characterId,
                kind: kind,
                key: key,
                label: label,
                value: value,
                base: base,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String characterId,
                required String kind,
                required String key,
                required String label,
                required int value,
                Value<String?> base = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterStatsCompanion.insert(
                id: id,
                characterId: characterId,
                kind: kind,
                key: key,
                label: label,
                value: value,
                base: base,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CharacterStatsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({characterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (characterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.characterId,
                                referencedTable: $$CharacterStatsTableReferences
                                    ._characterIdTable(db),
                                referencedColumn:
                                    $$CharacterStatsTableReferences
                                        ._characterIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CharacterStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharacterStatsTable,
      CharacterStatRow,
      $$CharacterStatsTableFilterComposer,
      $$CharacterStatsTableOrderingComposer,
      $$CharacterStatsTableAnnotationComposer,
      $$CharacterStatsTableCreateCompanionBuilder,
      $$CharacterStatsTableUpdateCompanionBuilder,
      (CharacterStatRow, $$CharacterStatsTableReferences),
      CharacterStatRow,
      PrefetchHooks Function({bool characterId})
    >;
typedef $$CharacterResourcesTableCreateCompanionBuilder =
    CharacterResourcesCompanion Function({
      required String id,
      required String characterId,
      required String key,
      required String label,
      required int current,
      required int max,
      Value<String> tone,
      Value<int> rowid,
    });
typedef $$CharacterResourcesTableUpdateCompanionBuilder =
    CharacterResourcesCompanion Function({
      Value<String> id,
      Value<String> characterId,
      Value<String> key,
      Value<String> label,
      Value<int> current,
      Value<int> max,
      Value<String> tone,
      Value<int> rowid,
    });

final class $$CharacterResourcesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CharacterResourcesTable,
          CharacterResourceRow
        > {
  $$CharacterResourcesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CharactersTable _characterIdTable(_$AppDatabase db) => db.characters
      .createAlias('character_resources__character_id__characters__id');

  $$CharactersTableProcessedTableManager get characterId {
    final $_column = $_itemColumn<String>('character_id')!;

    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_characterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CharacterResourcesTableFilterComposer
    extends Composer<_$AppDatabase, $CharacterResourcesTable> {
  $$CharacterResourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get current => $composableBuilder(
    column: $table.current,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get max => $composableBuilder(
    column: $table.max,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tone => $composableBuilder(
    column: $table.tone,
    builder: (column) => ColumnFilters(column),
  );

  $$CharactersTableFilterComposer get characterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterResourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $CharacterResourcesTable> {
  $$CharacterResourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get current => $composableBuilder(
    column: $table.current,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get max => $composableBuilder(
    column: $table.max,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tone => $composableBuilder(
    column: $table.tone,
    builder: (column) => ColumnOrderings(column),
  );

  $$CharactersTableOrderingComposer get characterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableOrderingComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterResourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharacterResourcesTable> {
  $$CharacterResourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get current =>
      $composableBuilder(column: $table.current, builder: (column) => column);

  GeneratedColumn<int> get max =>
      $composableBuilder(column: $table.max, builder: (column) => column);

  GeneratedColumn<String> get tone =>
      $composableBuilder(column: $table.tone, builder: (column) => column);

  $$CharactersTableAnnotationComposer get characterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterResourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharacterResourcesTable,
          CharacterResourceRow,
          $$CharacterResourcesTableFilterComposer,
          $$CharacterResourcesTableOrderingComposer,
          $$CharacterResourcesTableAnnotationComposer,
          $$CharacterResourcesTableCreateCompanionBuilder,
          $$CharacterResourcesTableUpdateCompanionBuilder,
          (CharacterResourceRow, $$CharacterResourcesTableReferences),
          CharacterResourceRow,
          PrefetchHooks Function({bool characterId})
        > {
  $$CharacterResourcesTableTableManager(
    _$AppDatabase db,
    $CharacterResourcesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterResourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharacterResourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharacterResourcesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> characterId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> current = const Value.absent(),
                Value<int> max = const Value.absent(),
                Value<String> tone = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterResourcesCompanion(
                id: id,
                characterId: characterId,
                key: key,
                label: label,
                current: current,
                max: max,
                tone: tone,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String characterId,
                required String key,
                required String label,
                required int current,
                required int max,
                Value<String> tone = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterResourcesCompanion.insert(
                id: id,
                characterId: characterId,
                key: key,
                label: label,
                current: current,
                max: max,
                tone: tone,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CharacterResourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({characterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (characterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.characterId,
                                referencedTable:
                                    $$CharacterResourcesTableReferences
                                        ._characterIdTable(db),
                                referencedColumn:
                                    $$CharacterResourcesTableReferences
                                        ._characterIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CharacterResourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharacterResourcesTable,
      CharacterResourceRow,
      $$CharacterResourcesTableFilterComposer,
      $$CharacterResourcesTableOrderingComposer,
      $$CharacterResourcesTableAnnotationComposer,
      $$CharacterResourcesTableCreateCompanionBuilder,
      $$CharacterResourcesTableUpdateCompanionBuilder,
      (CharacterResourceRow, $$CharacterResourcesTableReferences),
      CharacterResourceRow,
      PrefetchHooks Function({bool characterId})
    >;
typedef $$InventoryItemsTableCreateCompanionBuilder =
    InventoryItemsCompanion Function({
      required String id,
      required String characterId,
      required String name,
      Value<int> qty,
      Value<String?> weight,
      Value<int> rowid,
    });
typedef $$InventoryItemsTableUpdateCompanionBuilder =
    InventoryItemsCompanion Function({
      Value<String> id,
      Value<String> characterId,
      Value<String> name,
      Value<int> qty,
      Value<String?> weight,
      Value<int> rowid,
    });

final class $$InventoryItemsTableReferences
    extends
        BaseReferences<_$AppDatabase, $InventoryItemsTable, InventoryItemRow> {
  $$InventoryItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CharactersTable _characterIdTable(_$AppDatabase db) => db.characters
      .createAlias('inventory_items__character_id__characters__id');

  $$CharactersTableProcessedTableManager get characterId {
    final $_column = $_itemColumn<String>('character_id')!;

    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_characterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InventoryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  $$CharactersTableFilterComposer get characterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  $$CharactersTableOrderingComposer get characterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableOrderingComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<String> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  $$CharactersTableAnnotationComposer get characterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoryItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryItemsTable,
          InventoryItemRow,
          $$InventoryItemsTableFilterComposer,
          $$InventoryItemsTableOrderingComposer,
          $$InventoryItemsTableAnnotationComposer,
          $$InventoryItemsTableCreateCompanionBuilder,
          $$InventoryItemsTableUpdateCompanionBuilder,
          (InventoryItemRow, $$InventoryItemsTableReferences),
          InventoryItemRow,
          PrefetchHooks Function({bool characterId})
        > {
  $$InventoryItemsTableTableManager(
    _$AppDatabase db,
    $InventoryItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> characterId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> qty = const Value.absent(),
                Value<String?> weight = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryItemsCompanion(
                id: id,
                characterId: characterId,
                name: name,
                qty: qty,
                weight: weight,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String characterId,
                required String name,
                Value<int> qty = const Value.absent(),
                Value<String?> weight = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryItemsCompanion.insert(
                id: id,
                characterId: characterId,
                name: name,
                qty: qty,
                weight: weight,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InventoryItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({characterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (characterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.characterId,
                                referencedTable: $$InventoryItemsTableReferences
                                    ._characterIdTable(db),
                                referencedColumn:
                                    $$InventoryItemsTableReferences
                                        ._characterIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InventoryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryItemsTable,
      InventoryItemRow,
      $$InventoryItemsTableFilterComposer,
      $$InventoryItemsTableOrderingComposer,
      $$InventoryItemsTableAnnotationComposer,
      $$InventoryItemsTableCreateCompanionBuilder,
      $$InventoryItemsTableUpdateCompanionBuilder,
      (InventoryItemRow, $$InventoryItemsTableReferences),
      InventoryItemRow,
      PrefetchHooks Function({bool characterId})
    >;
typedef $$GameTablesTableCreateCompanionBuilder =
    GameTablesCompanion Function({
      required String id,
      required String title,
      required String universeLabel,
      Value<DateTime?> nextSession,
      Value<String?> systemId,
      Value<int> rowid,
    });
typedef $$GameTablesTableUpdateCompanionBuilder =
    GameTablesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> universeLabel,
      Value<DateTime?> nextSession,
      Value<String?> systemId,
      Value<int> rowid,
    });

final class $$GameTablesTableReferences
    extends BaseReferences<_$AppDatabase, $GameTablesTable, GameTableRow> {
  $$GameTablesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GameSystemsTable _systemIdTable(_$AppDatabase db) =>
      db.gameSystems.createAlias('game_tables__system_id__game_systems__id');

  $$GameSystemsTableProcessedTableManager? get systemId {
    final $_column = $_itemColumn<String>('system_id');
    if ($_column == null) return null;
    final manager = $$GameSystemsTableTableManager(
      $_db,
      $_db.gameSystems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_systemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GameTablesTableFilterComposer
    extends Composer<_$AppDatabase, $GameTablesTable> {
  $$GameTablesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get universeLabel => $composableBuilder(
    column: $table.universeLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextSession => $composableBuilder(
    column: $table.nextSession,
    builder: (column) => ColumnFilters(column),
  );

  $$GameSystemsTableFilterComposer get systemId {
    final $$GameSystemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.gameSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GameSystemsTableFilterComposer(
            $db: $db,
            $table: $db.gameSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GameTablesTableOrderingComposer
    extends Composer<_$AppDatabase, $GameTablesTable> {
  $$GameTablesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get universeLabel => $composableBuilder(
    column: $table.universeLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextSession => $composableBuilder(
    column: $table.nextSession,
    builder: (column) => ColumnOrderings(column),
  );

  $$GameSystemsTableOrderingComposer get systemId {
    final $$GameSystemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.gameSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GameSystemsTableOrderingComposer(
            $db: $db,
            $table: $db.gameSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GameTablesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GameTablesTable> {
  $$GameTablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get universeLabel => $composableBuilder(
    column: $table.universeLabel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextSession => $composableBuilder(
    column: $table.nextSession,
    builder: (column) => column,
  );

  $$GameSystemsTableAnnotationComposer get systemId {
    final $$GameSystemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemId,
      referencedTable: $db.gameSystems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GameSystemsTableAnnotationComposer(
            $db: $db,
            $table: $db.gameSystems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GameTablesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GameTablesTable,
          GameTableRow,
          $$GameTablesTableFilterComposer,
          $$GameTablesTableOrderingComposer,
          $$GameTablesTableAnnotationComposer,
          $$GameTablesTableCreateCompanionBuilder,
          $$GameTablesTableUpdateCompanionBuilder,
          (GameTableRow, $$GameTablesTableReferences),
          GameTableRow,
          PrefetchHooks Function({bool systemId})
        > {
  $$GameTablesTableTableManager(_$AppDatabase db, $GameTablesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameTablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GameTablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GameTablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> universeLabel = const Value.absent(),
                Value<DateTime?> nextSession = const Value.absent(),
                Value<String?> systemId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GameTablesCompanion(
                id: id,
                title: title,
                universeLabel: universeLabel,
                nextSession: nextSession,
                systemId: systemId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String universeLabel,
                Value<DateTime?> nextSession = const Value.absent(),
                Value<String?> systemId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GameTablesCompanion.insert(
                id: id,
                title: title,
                universeLabel: universeLabel,
                nextSession: nextSession,
                systemId: systemId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GameTablesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({systemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (systemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.systemId,
                                referencedTable: $$GameTablesTableReferences
                                    ._systemIdTable(db),
                                referencedColumn: $$GameTablesTableReferences
                                    ._systemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GameTablesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GameTablesTable,
      GameTableRow,
      $$GameTablesTableFilterComposer,
      $$GameTablesTableOrderingComposer,
      $$GameTablesTableAnnotationComposer,
      $$GameTablesTableCreateCompanionBuilder,
      $$GameTablesTableUpdateCompanionBuilder,
      (GameTableRow, $$GameTablesTableReferences),
      GameTableRow,
      PrefetchHooks Function({bool systemId})
    >;
typedef $$SyncMetadataTableCreateCompanionBuilder =
    SyncMetadataCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SyncMetadataTableUpdateCompanionBuilder =
    SyncMetadataCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SyncMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetadataTable,
          SyncMetadataRow,
          $$SyncMetadataTableFilterComposer,
          $$SyncMetadataTableOrderingComposer,
          $$SyncMetadataTableAnnotationComposer,
          $$SyncMetadataTableCreateCompanionBuilder,
          $$SyncMetadataTableUpdateCompanionBuilder,
          (
            SyncMetadataRow,
            BaseReferences<_$AppDatabase, $SyncMetadataTable, SyncMetadataRow>,
          ),
          SyncMetadataRow,
          PrefetchHooks Function()
        > {
  $$SyncMetadataTableTableManager(_$AppDatabase db, $SyncMetadataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetadataTable,
      SyncMetadataRow,
      $$SyncMetadataTableFilterComposer,
      $$SyncMetadataTableOrderingComposer,
      $$SyncMetadataTableAnnotationComposer,
      $$SyncMetadataTableCreateCompanionBuilder,
      $$SyncMetadataTableUpdateCompanionBuilder,
      (
        SyncMetadataRow,
        BaseReferences<_$AppDatabase, $SyncMetadataTable, SyncMetadataRow>,
      ),
      SyncMetadataRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GameSystemsTableTableManager get gameSystems =>
      $$GameSystemsTableTableManager(_db, _db.gameSystems);
  $$CharactersTableTableManager get characters =>
      $$CharactersTableTableManager(_db, _db.characters);
  $$CharacterStatsTableTableManager get characterStats =>
      $$CharacterStatsTableTableManager(_db, _db.characterStats);
  $$CharacterResourcesTableTableManager get characterResources =>
      $$CharacterResourcesTableTableManager(_db, _db.characterResources);
  $$InventoryItemsTableTableManager get inventoryItems =>
      $$InventoryItemsTableTableManager(_db, _db.inventoryItems);
  $$GameTablesTableTableManager get gameTables =>
      $$GameTablesTableTableManager(_db, _db.gameTables);
  $$SyncMetadataTableTableManager get syncMetadata =>
      $$SyncMetadataTableTableManager(_db, _db.syncMetadata);
}
