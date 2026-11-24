// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Character {

 String get id; String get systemId; String get name; String? get occupation; String? get description; int get level; DateTime get createdAt; List<CharacterResource> get resources; List<CharacterStat> get stats; List<InventoryItem> get inventory;
/// Create a copy of Character
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharacterCopyWith<Character> get copyWith => _$CharacterCopyWithImpl<Character>(this as Character, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Character&&(identical(other.id, id) || other.id == id)&&(identical(other.systemId, systemId) || other.systemId == systemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.occupation, occupation) || other.occupation == occupation)&&(identical(other.description, description) || other.description == description)&&(identical(other.level, level) || other.level == level)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.resources, resources)&&const DeepCollectionEquality().equals(other.stats, stats)&&const DeepCollectionEquality().equals(other.inventory, inventory));
}


@override
int get hashCode => Object.hash(runtimeType,id,systemId,name,occupation,description,level,createdAt,const DeepCollectionEquality().hash(resources),const DeepCollectionEquality().hash(stats),const DeepCollectionEquality().hash(inventory));

@override
String toString() {
  return 'Character(id: $id, systemId: $systemId, name: $name, occupation: $occupation, description: $description, level: $level, createdAt: $createdAt, resources: $resources, stats: $stats, inventory: $inventory)';
}


}

/// @nodoc
abstract mixin class $CharacterCopyWith<$Res>  {
  factory $CharacterCopyWith(Character value, $Res Function(Character) _then) = _$CharacterCopyWithImpl;
@useResult
$Res call({
 String id, String systemId, String name, String? occupation, String? description, int level, DateTime createdAt, List<CharacterResource> resources, List<CharacterStat> stats, List<InventoryItem> inventory
});




}
/// @nodoc
class _$CharacterCopyWithImpl<$Res>
    implements $CharacterCopyWith<$Res> {
  _$CharacterCopyWithImpl(this._self, this._then);

  final Character _self;
  final $Res Function(Character) _then;

/// Create a copy of Character
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? systemId = null,Object? name = null,Object? occupation = freezed,Object? description = freezed,Object? level = null,Object? createdAt = null,Object? resources = null,Object? stats = null,Object? inventory = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,systemId: null == systemId ? _self.systemId : systemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,occupation: freezed == occupation ? _self.occupation : occupation // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,resources: null == resources ? _self.resources : resources // ignore: cast_nullable_to_non_nullable
as List<CharacterResource>,stats: null == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as List<CharacterStat>,inventory: null == inventory ? _self.inventory : inventory // ignore: cast_nullable_to_non_nullable
as List<InventoryItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [Character].
extension CharacterPatterns on Character {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Character value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Character() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Character value)  $default,){
final _that = this;
switch (_that) {
case _Character():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Character value)?  $default,){
final _that = this;
switch (_that) {
case _Character() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String systemId,  String name,  String? occupation,  String? description,  int level,  DateTime createdAt,  List<CharacterResource> resources,  List<CharacterStat> stats,  List<InventoryItem> inventory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Character() when $default != null:
return $default(_that.id,_that.systemId,_that.name,_that.occupation,_that.description,_that.level,_that.createdAt,_that.resources,_that.stats,_that.inventory);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String systemId,  String name,  String? occupation,  String? description,  int level,  DateTime createdAt,  List<CharacterResource> resources,  List<CharacterStat> stats,  List<InventoryItem> inventory)  $default,) {final _that = this;
switch (_that) {
case _Character():
return $default(_that.id,_that.systemId,_that.name,_that.occupation,_that.description,_that.level,_that.createdAt,_that.resources,_that.stats,_that.inventory);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String systemId,  String name,  String? occupation,  String? description,  int level,  DateTime createdAt,  List<CharacterResource> resources,  List<CharacterStat> stats,  List<InventoryItem> inventory)?  $default,) {final _that = this;
switch (_that) {
case _Character() when $default != null:
return $default(_that.id,_that.systemId,_that.name,_that.occupation,_that.description,_that.level,_that.createdAt,_that.resources,_that.stats,_that.inventory);case _:
  return null;

}
}

}

/// @nodoc


class _Character extends Character {
  const _Character({required this.id, required this.systemId, required this.name, this.occupation, this.description, this.level = 1, required this.createdAt, final  List<CharacterResource> resources = const [], final  List<CharacterStat> stats = const [], final  List<InventoryItem> inventory = const []}): _resources = resources,_stats = stats,_inventory = inventory,super._();
  

@override final  String id;
@override final  String systemId;
@override final  String name;
@override final  String? occupation;
@override final  String? description;
@override@JsonKey() final  int level;
@override final  DateTime createdAt;
 final  List<CharacterResource> _resources;
@override@JsonKey() List<CharacterResource> get resources {
  if (_resources is EqualUnmodifiableListView) return _resources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_resources);
}

 final  List<CharacterStat> _stats;
@override@JsonKey() List<CharacterStat> get stats {
  if (_stats is EqualUnmodifiableListView) return _stats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stats);
}

 final  List<InventoryItem> _inventory;
@override@JsonKey() List<InventoryItem> get inventory {
  if (_inventory is EqualUnmodifiableListView) return _inventory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inventory);
}


/// Create a copy of Character
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharacterCopyWith<_Character> get copyWith => __$CharacterCopyWithImpl<_Character>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Character&&(identical(other.id, id) || other.id == id)&&(identical(other.systemId, systemId) || other.systemId == systemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.occupation, occupation) || other.occupation == occupation)&&(identical(other.description, description) || other.description == description)&&(identical(other.level, level) || other.level == level)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._resources, _resources)&&const DeepCollectionEquality().equals(other._stats, _stats)&&const DeepCollectionEquality().equals(other._inventory, _inventory));
}


@override
int get hashCode => Object.hash(runtimeType,id,systemId,name,occupation,description,level,createdAt,const DeepCollectionEquality().hash(_resources),const DeepCollectionEquality().hash(_stats),const DeepCollectionEquality().hash(_inventory));

@override
String toString() {
  return 'Character(id: $id, systemId: $systemId, name: $name, occupation: $occupation, description: $description, level: $level, createdAt: $createdAt, resources: $resources, stats: $stats, inventory: $inventory)';
}


}

/// @nodoc
abstract mixin class _$CharacterCopyWith<$Res> implements $CharacterCopyWith<$Res> {
  factory _$CharacterCopyWith(_Character value, $Res Function(_Character) _then) = __$CharacterCopyWithImpl;
@override @useResult
$Res call({
 String id, String systemId, String name, String? occupation, String? description, int level, DateTime createdAt, List<CharacterResource> resources, List<CharacterStat> stats, List<InventoryItem> inventory
});




}
/// @nodoc
class __$CharacterCopyWithImpl<$Res>
    implements _$CharacterCopyWith<$Res> {
  __$CharacterCopyWithImpl(this._self, this._then);

  final _Character _self;
  final $Res Function(_Character) _then;

/// Create a copy of Character
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? systemId = null,Object? name = null,Object? occupation = freezed,Object? description = freezed,Object? level = null,Object? createdAt = null,Object? resources = null,Object? stats = null,Object? inventory = null,}) {
  return _then(_Character(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,systemId: null == systemId ? _self.systemId : systemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,occupation: freezed == occupation ? _self.occupation : occupation // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,resources: null == resources ? _self._resources : resources // ignore: cast_nullable_to_non_nullable
as List<CharacterResource>,stats: null == stats ? _self._stats : stats // ignore: cast_nullable_to_non_nullable
as List<CharacterStat>,inventory: null == inventory ? _self._inventory : inventory // ignore: cast_nullable_to_non_nullable
as List<InventoryItem>,
  ));
}


}

// dart format on
