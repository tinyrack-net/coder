// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkspaceDto {

 String get id; String get name; String get rootPath; WorkspaceKind get kind; DateTime get createdAt;
/// Create a copy of WorkspaceDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceDtoCopyWith<WorkspaceDto> get copyWith => _$WorkspaceDtoCopyWithImpl<WorkspaceDto>(this as WorkspaceDto, _$identity);

  /// Serializes this WorkspaceDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,rootPath,kind,createdAt);

@override
String toString() {
  return 'WorkspaceDto(id: $id, name: $name, rootPath: $rootPath, kind: $kind, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $WorkspaceDtoCopyWith<$Res>  {
  factory $WorkspaceDtoCopyWith(WorkspaceDto value, $Res Function(WorkspaceDto) _then) = _$WorkspaceDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String rootPath, WorkspaceKind kind, DateTime createdAt
});




}
/// @nodoc
class _$WorkspaceDtoCopyWithImpl<$Res>
    implements $WorkspaceDtoCopyWith<$Res> {
  _$WorkspaceDtoCopyWithImpl(this._self, this._then);

  final WorkspaceDto _self;
  final $Res Function(WorkspaceDto) _then;

/// Create a copy of WorkspaceDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? rootPath = null,Object? kind = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rootPath: null == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as WorkspaceKind,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkspaceDto].
extension WorkspaceDtoPatterns on WorkspaceDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceDto value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceDto value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String rootPath,  WorkspaceKind kind,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceDto() when $default != null:
return $default(_that.id,_that.name,_that.rootPath,_that.kind,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String rootPath,  WorkspaceKind kind,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceDto():
return $default(_that.id,_that.name,_that.rootPath,_that.kind,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String rootPath,  WorkspaceKind kind,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceDto() when $default != null:
return $default(_that.id,_that.name,_that.rootPath,_that.kind,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkspaceDto implements WorkspaceDto {
  const _WorkspaceDto({required this.id, required this.name, required this.rootPath, required this.kind, required this.createdAt});
  factory _WorkspaceDto.fromJson(Map<String, dynamic> json) => _$WorkspaceDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String rootPath;
@override final  WorkspaceKind kind;
@override final  DateTime createdAt;

/// Create a copy of WorkspaceDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceDtoCopyWith<_WorkspaceDto> get copyWith => __$WorkspaceDtoCopyWithImpl<_WorkspaceDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkspaceDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,rootPath,kind,createdAt);

@override
String toString() {
  return 'WorkspaceDto(id: $id, name: $name, rootPath: $rootPath, kind: $kind, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceDtoCopyWith<$Res> implements $WorkspaceDtoCopyWith<$Res> {
  factory _$WorkspaceDtoCopyWith(_WorkspaceDto value, $Res Function(_WorkspaceDto) _then) = __$WorkspaceDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String rootPath, WorkspaceKind kind, DateTime createdAt
});




}
/// @nodoc
class __$WorkspaceDtoCopyWithImpl<$Res>
    implements _$WorkspaceDtoCopyWith<$Res> {
  __$WorkspaceDtoCopyWithImpl(this._self, this._then);

  final _WorkspaceDto _self;
  final $Res Function(_WorkspaceDto) _then;

/// Create a copy of WorkspaceDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? rootPath = null,Object? kind = null,Object? createdAt = null,}) {
  return _then(_WorkspaceDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rootPath: null == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as WorkspaceKind,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$WorktreeDto {

 String get id; String get workspaceId; String get name; String get path; WorktreeKind get kind; bool get isCoderOwned; DateTime get createdAt; String? get branch; String? get head; DateTime? get archivedAt;
/// Create a copy of WorktreeDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorktreeDtoCopyWith<WorktreeDto> get copyWith => _$WorktreeDtoCopyWithImpl<WorktreeDto>(this as WorktreeDto, _$identity);

  /// Serializes this WorktreeDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorktreeDto&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.isCoderOwned, isCoderOwned) || other.isCoderOwned == isCoderOwned)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.head, head) || other.head == head)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,name,path,kind,isCoderOwned,createdAt,branch,head,archivedAt);

@override
String toString() {
  return 'WorktreeDto(id: $id, workspaceId: $workspaceId, name: $name, path: $path, kind: $kind, isCoderOwned: $isCoderOwned, createdAt: $createdAt, branch: $branch, head: $head, archivedAt: $archivedAt)';
}


}

/// @nodoc
abstract mixin class $WorktreeDtoCopyWith<$Res>  {
  factory $WorktreeDtoCopyWith(WorktreeDto value, $Res Function(WorktreeDto) _then) = _$WorktreeDtoCopyWithImpl;
@useResult
$Res call({
 String id, String workspaceId, String name, String path, WorktreeKind kind, bool isCoderOwned, DateTime createdAt, String? branch, String? head, DateTime? archivedAt
});




}
/// @nodoc
class _$WorktreeDtoCopyWithImpl<$Res>
    implements $WorktreeDtoCopyWith<$Res> {
  _$WorktreeDtoCopyWithImpl(this._self, this._then);

  final WorktreeDto _self;
  final $Res Function(WorktreeDto) _then;

/// Create a copy of WorktreeDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workspaceId = null,Object? name = null,Object? path = null,Object? kind = null,Object? isCoderOwned = null,Object? createdAt = null,Object? branch = freezed,Object? head = freezed,Object? archivedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as WorktreeKind,isCoderOwned: null == isCoderOwned ? _self.isCoderOwned : isCoderOwned // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,branch: freezed == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String?,head: freezed == head ? _self.head : head // ignore: cast_nullable_to_non_nullable
as String?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorktreeDto].
extension WorktreeDtoPatterns on WorktreeDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorktreeDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorktreeDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorktreeDto value)  $default,){
final _that = this;
switch (_that) {
case _WorktreeDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorktreeDto value)?  $default,){
final _that = this;
switch (_that) {
case _WorktreeDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String name,  String path,  WorktreeKind kind,  bool isCoderOwned,  DateTime createdAt,  String? branch,  String? head,  DateTime? archivedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorktreeDto() when $default != null:
return $default(_that.id,_that.workspaceId,_that.name,_that.path,_that.kind,_that.isCoderOwned,_that.createdAt,_that.branch,_that.head,_that.archivedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String name,  String path,  WorktreeKind kind,  bool isCoderOwned,  DateTime createdAt,  String? branch,  String? head,  DateTime? archivedAt)  $default,) {final _that = this;
switch (_that) {
case _WorktreeDto():
return $default(_that.id,_that.workspaceId,_that.name,_that.path,_that.kind,_that.isCoderOwned,_that.createdAt,_that.branch,_that.head,_that.archivedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workspaceId,  String name,  String path,  WorktreeKind kind,  bool isCoderOwned,  DateTime createdAt,  String? branch,  String? head,  DateTime? archivedAt)?  $default,) {final _that = this;
switch (_that) {
case _WorktreeDto() when $default != null:
return $default(_that.id,_that.workspaceId,_that.name,_that.path,_that.kind,_that.isCoderOwned,_that.createdAt,_that.branch,_that.head,_that.archivedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorktreeDto implements WorktreeDto {
  const _WorktreeDto({required this.id, required this.workspaceId, required this.name, required this.path, required this.kind, required this.isCoderOwned, required this.createdAt, this.branch, this.head, this.archivedAt});
  factory _WorktreeDto.fromJson(Map<String, dynamic> json) => _$WorktreeDtoFromJson(json);

@override final  String id;
@override final  String workspaceId;
@override final  String name;
@override final  String path;
@override final  WorktreeKind kind;
@override final  bool isCoderOwned;
@override final  DateTime createdAt;
@override final  String? branch;
@override final  String? head;
@override final  DateTime? archivedAt;

/// Create a copy of WorktreeDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorktreeDtoCopyWith<_WorktreeDto> get copyWith => __$WorktreeDtoCopyWithImpl<_WorktreeDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorktreeDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorktreeDto&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.isCoderOwned, isCoderOwned) || other.isCoderOwned == isCoderOwned)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.head, head) || other.head == head)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,name,path,kind,isCoderOwned,createdAt,branch,head,archivedAt);

@override
String toString() {
  return 'WorktreeDto(id: $id, workspaceId: $workspaceId, name: $name, path: $path, kind: $kind, isCoderOwned: $isCoderOwned, createdAt: $createdAt, branch: $branch, head: $head, archivedAt: $archivedAt)';
}


}

/// @nodoc
abstract mixin class _$WorktreeDtoCopyWith<$Res> implements $WorktreeDtoCopyWith<$Res> {
  factory _$WorktreeDtoCopyWith(_WorktreeDto value, $Res Function(_WorktreeDto) _then) = __$WorktreeDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String workspaceId, String name, String path, WorktreeKind kind, bool isCoderOwned, DateTime createdAt, String? branch, String? head, DateTime? archivedAt
});




}
/// @nodoc
class __$WorktreeDtoCopyWithImpl<$Res>
    implements _$WorktreeDtoCopyWith<$Res> {
  __$WorktreeDtoCopyWithImpl(this._self, this._then);

  final _WorktreeDto _self;
  final $Res Function(_WorktreeDto) _then;

/// Create a copy of WorktreeDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workspaceId = null,Object? name = null,Object? path = null,Object? kind = null,Object? isCoderOwned = null,Object? createdAt = null,Object? branch = freezed,Object? head = freezed,Object? archivedAt = freezed,}) {
  return _then(_WorktreeDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as WorktreeKind,isCoderOwned: null == isCoderOwned ? _self.isCoderOwned : isCoderOwned // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,branch: freezed == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String?,head: freezed == head ? _self.head : head // ignore: cast_nullable_to_non_nullable
as String?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$WorkspaceCatalogDto {

 List<WorkspaceDto> get workspaces; List<WorktreeDto> get worktrees;
/// Create a copy of WorkspaceCatalogDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceCatalogDtoCopyWith<WorkspaceCatalogDto> get copyWith => _$WorkspaceCatalogDtoCopyWithImpl<WorkspaceCatalogDto>(this as WorkspaceCatalogDto, _$identity);

  /// Serializes this WorkspaceCatalogDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceCatalogDto&&const DeepCollectionEquality().equals(other.workspaces, workspaces)&&const DeepCollectionEquality().equals(other.worktrees, worktrees));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(workspaces),const DeepCollectionEquality().hash(worktrees));

@override
String toString() {
  return 'WorkspaceCatalogDto(workspaces: $workspaces, worktrees: $worktrees)';
}


}

/// @nodoc
abstract mixin class $WorkspaceCatalogDtoCopyWith<$Res>  {
  factory $WorkspaceCatalogDtoCopyWith(WorkspaceCatalogDto value, $Res Function(WorkspaceCatalogDto) _then) = _$WorkspaceCatalogDtoCopyWithImpl;
@useResult
$Res call({
 List<WorkspaceDto> workspaces, List<WorktreeDto> worktrees
});




}
/// @nodoc
class _$WorkspaceCatalogDtoCopyWithImpl<$Res>
    implements $WorkspaceCatalogDtoCopyWith<$Res> {
  _$WorkspaceCatalogDtoCopyWithImpl(this._self, this._then);

  final WorkspaceCatalogDto _self;
  final $Res Function(WorkspaceCatalogDto) _then;

/// Create a copy of WorkspaceCatalogDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workspaces = null,Object? worktrees = null,}) {
  return _then(_self.copyWith(
workspaces: null == workspaces ? _self.workspaces : workspaces // ignore: cast_nullable_to_non_nullable
as List<WorkspaceDto>,worktrees: null == worktrees ? _self.worktrees : worktrees // ignore: cast_nullable_to_non_nullable
as List<WorktreeDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkspaceCatalogDto].
extension WorkspaceCatalogDtoPatterns on WorkspaceCatalogDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceCatalogDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceCatalogDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceCatalogDto value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceCatalogDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceCatalogDto value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceCatalogDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<WorkspaceDto> workspaces,  List<WorktreeDto> worktrees)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceCatalogDto() when $default != null:
return $default(_that.workspaces,_that.worktrees);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<WorkspaceDto> workspaces,  List<WorktreeDto> worktrees)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceCatalogDto():
return $default(_that.workspaces,_that.worktrees);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<WorkspaceDto> workspaces,  List<WorktreeDto> worktrees)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceCatalogDto() when $default != null:
return $default(_that.workspaces,_that.worktrees);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkspaceCatalogDto implements WorkspaceCatalogDto {
  const _WorkspaceCatalogDto({required final  List<WorkspaceDto> workspaces, required final  List<WorktreeDto> worktrees}): _workspaces = workspaces,_worktrees = worktrees;
  factory _WorkspaceCatalogDto.fromJson(Map<String, dynamic> json) => _$WorkspaceCatalogDtoFromJson(json);

 final  List<WorkspaceDto> _workspaces;
@override List<WorkspaceDto> get workspaces {
  if (_workspaces is EqualUnmodifiableListView) return _workspaces;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_workspaces);
}

 final  List<WorktreeDto> _worktrees;
@override List<WorktreeDto> get worktrees {
  if (_worktrees is EqualUnmodifiableListView) return _worktrees;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_worktrees);
}


/// Create a copy of WorkspaceCatalogDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceCatalogDtoCopyWith<_WorkspaceCatalogDto> get copyWith => __$WorkspaceCatalogDtoCopyWithImpl<_WorkspaceCatalogDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkspaceCatalogDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceCatalogDto&&const DeepCollectionEquality().equals(other._workspaces, _workspaces)&&const DeepCollectionEquality().equals(other._worktrees, _worktrees));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_workspaces),const DeepCollectionEquality().hash(_worktrees));

@override
String toString() {
  return 'WorkspaceCatalogDto(workspaces: $workspaces, worktrees: $worktrees)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceCatalogDtoCopyWith<$Res> implements $WorkspaceCatalogDtoCopyWith<$Res> {
  factory _$WorkspaceCatalogDtoCopyWith(_WorkspaceCatalogDto value, $Res Function(_WorkspaceCatalogDto) _then) = __$WorkspaceCatalogDtoCopyWithImpl;
@override @useResult
$Res call({
 List<WorkspaceDto> workspaces, List<WorktreeDto> worktrees
});




}
/// @nodoc
class __$WorkspaceCatalogDtoCopyWithImpl<$Res>
    implements _$WorkspaceCatalogDtoCopyWith<$Res> {
  __$WorkspaceCatalogDtoCopyWithImpl(this._self, this._then);

  final _WorkspaceCatalogDto _self;
  final $Res Function(_WorkspaceCatalogDto) _then;

/// Create a copy of WorkspaceCatalogDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workspaces = null,Object? worktrees = null,}) {
  return _then(_WorkspaceCatalogDto(
workspaces: null == workspaces ? _self._workspaces : workspaces // ignore: cast_nullable_to_non_nullable
as List<WorkspaceDto>,worktrees: null == worktrees ? _self._worktrees : worktrees // ignore: cast_nullable_to_non_nullable
as List<WorktreeDto>,
  ));
}


}


/// @nodoc
mixin _$WorktreeArchivePreviewDto {

 String get worktreeId; bool get dirty; int get unpushedCommitCount; int get runningSessionCount; bool get removesDirectory;
/// Create a copy of WorktreeArchivePreviewDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorktreeArchivePreviewDtoCopyWith<WorktreeArchivePreviewDto> get copyWith => _$WorktreeArchivePreviewDtoCopyWithImpl<WorktreeArchivePreviewDto>(this as WorktreeArchivePreviewDto, _$identity);

  /// Serializes this WorktreeArchivePreviewDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorktreeArchivePreviewDto&&(identical(other.worktreeId, worktreeId) || other.worktreeId == worktreeId)&&(identical(other.dirty, dirty) || other.dirty == dirty)&&(identical(other.unpushedCommitCount, unpushedCommitCount) || other.unpushedCommitCount == unpushedCommitCount)&&(identical(other.runningSessionCount, runningSessionCount) || other.runningSessionCount == runningSessionCount)&&(identical(other.removesDirectory, removesDirectory) || other.removesDirectory == removesDirectory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,worktreeId,dirty,unpushedCommitCount,runningSessionCount,removesDirectory);

@override
String toString() {
  return 'WorktreeArchivePreviewDto(worktreeId: $worktreeId, dirty: $dirty, unpushedCommitCount: $unpushedCommitCount, runningSessionCount: $runningSessionCount, removesDirectory: $removesDirectory)';
}


}

/// @nodoc
abstract mixin class $WorktreeArchivePreviewDtoCopyWith<$Res>  {
  factory $WorktreeArchivePreviewDtoCopyWith(WorktreeArchivePreviewDto value, $Res Function(WorktreeArchivePreviewDto) _then) = _$WorktreeArchivePreviewDtoCopyWithImpl;
@useResult
$Res call({
 String worktreeId, bool dirty, int unpushedCommitCount, int runningSessionCount, bool removesDirectory
});




}
/// @nodoc
class _$WorktreeArchivePreviewDtoCopyWithImpl<$Res>
    implements $WorktreeArchivePreviewDtoCopyWith<$Res> {
  _$WorktreeArchivePreviewDtoCopyWithImpl(this._self, this._then);

  final WorktreeArchivePreviewDto _self;
  final $Res Function(WorktreeArchivePreviewDto) _then;

/// Create a copy of WorktreeArchivePreviewDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? worktreeId = null,Object? dirty = null,Object? unpushedCommitCount = null,Object? runningSessionCount = null,Object? removesDirectory = null,}) {
  return _then(_self.copyWith(
worktreeId: null == worktreeId ? _self.worktreeId : worktreeId // ignore: cast_nullable_to_non_nullable
as String,dirty: null == dirty ? _self.dirty : dirty // ignore: cast_nullable_to_non_nullable
as bool,unpushedCommitCount: null == unpushedCommitCount ? _self.unpushedCommitCount : unpushedCommitCount // ignore: cast_nullable_to_non_nullable
as int,runningSessionCount: null == runningSessionCount ? _self.runningSessionCount : runningSessionCount // ignore: cast_nullable_to_non_nullable
as int,removesDirectory: null == removesDirectory ? _self.removesDirectory : removesDirectory // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WorktreeArchivePreviewDto].
extension WorktreeArchivePreviewDtoPatterns on WorktreeArchivePreviewDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorktreeArchivePreviewDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorktreeArchivePreviewDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorktreeArchivePreviewDto value)  $default,){
final _that = this;
switch (_that) {
case _WorktreeArchivePreviewDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorktreeArchivePreviewDto value)?  $default,){
final _that = this;
switch (_that) {
case _WorktreeArchivePreviewDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String worktreeId,  bool dirty,  int unpushedCommitCount,  int runningSessionCount,  bool removesDirectory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorktreeArchivePreviewDto() when $default != null:
return $default(_that.worktreeId,_that.dirty,_that.unpushedCommitCount,_that.runningSessionCount,_that.removesDirectory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String worktreeId,  bool dirty,  int unpushedCommitCount,  int runningSessionCount,  bool removesDirectory)  $default,) {final _that = this;
switch (_that) {
case _WorktreeArchivePreviewDto():
return $default(_that.worktreeId,_that.dirty,_that.unpushedCommitCount,_that.runningSessionCount,_that.removesDirectory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String worktreeId,  bool dirty,  int unpushedCommitCount,  int runningSessionCount,  bool removesDirectory)?  $default,) {final _that = this;
switch (_that) {
case _WorktreeArchivePreviewDto() when $default != null:
return $default(_that.worktreeId,_that.dirty,_that.unpushedCommitCount,_that.runningSessionCount,_that.removesDirectory);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorktreeArchivePreviewDto implements WorktreeArchivePreviewDto {
  const _WorktreeArchivePreviewDto({required this.worktreeId, required this.dirty, required this.unpushedCommitCount, required this.runningSessionCount, required this.removesDirectory});
  factory _WorktreeArchivePreviewDto.fromJson(Map<String, dynamic> json) => _$WorktreeArchivePreviewDtoFromJson(json);

@override final  String worktreeId;
@override final  bool dirty;
@override final  int unpushedCommitCount;
@override final  int runningSessionCount;
@override final  bool removesDirectory;

/// Create a copy of WorktreeArchivePreviewDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorktreeArchivePreviewDtoCopyWith<_WorktreeArchivePreviewDto> get copyWith => __$WorktreeArchivePreviewDtoCopyWithImpl<_WorktreeArchivePreviewDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorktreeArchivePreviewDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorktreeArchivePreviewDto&&(identical(other.worktreeId, worktreeId) || other.worktreeId == worktreeId)&&(identical(other.dirty, dirty) || other.dirty == dirty)&&(identical(other.unpushedCommitCount, unpushedCommitCount) || other.unpushedCommitCount == unpushedCommitCount)&&(identical(other.runningSessionCount, runningSessionCount) || other.runningSessionCount == runningSessionCount)&&(identical(other.removesDirectory, removesDirectory) || other.removesDirectory == removesDirectory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,worktreeId,dirty,unpushedCommitCount,runningSessionCount,removesDirectory);

@override
String toString() {
  return 'WorktreeArchivePreviewDto(worktreeId: $worktreeId, dirty: $dirty, unpushedCommitCount: $unpushedCommitCount, runningSessionCount: $runningSessionCount, removesDirectory: $removesDirectory)';
}


}

/// @nodoc
abstract mixin class _$WorktreeArchivePreviewDtoCopyWith<$Res> implements $WorktreeArchivePreviewDtoCopyWith<$Res> {
  factory _$WorktreeArchivePreviewDtoCopyWith(_WorktreeArchivePreviewDto value, $Res Function(_WorktreeArchivePreviewDto) _then) = __$WorktreeArchivePreviewDtoCopyWithImpl;
@override @useResult
$Res call({
 String worktreeId, bool dirty, int unpushedCommitCount, int runningSessionCount, bool removesDirectory
});




}
/// @nodoc
class __$WorktreeArchivePreviewDtoCopyWithImpl<$Res>
    implements _$WorktreeArchivePreviewDtoCopyWith<$Res> {
  __$WorktreeArchivePreviewDtoCopyWithImpl(this._self, this._then);

  final _WorktreeArchivePreviewDto _self;
  final $Res Function(_WorktreeArchivePreviewDto) _then;

/// Create a copy of WorktreeArchivePreviewDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? worktreeId = null,Object? dirty = null,Object? unpushedCommitCount = null,Object? runningSessionCount = null,Object? removesDirectory = null,}) {
  return _then(_WorktreeArchivePreviewDto(
worktreeId: null == worktreeId ? _self.worktreeId : worktreeId // ignore: cast_nullable_to_non_nullable
as String,dirty: null == dirty ? _self.dirty : dirty // ignore: cast_nullable_to_non_nullable
as bool,unpushedCommitCount: null == unpushedCommitCount ? _self.unpushedCommitCount : unpushedCommitCount // ignore: cast_nullable_to_non_nullable
as int,runningSessionCount: null == runningSessionCount ? _self.runningSessionCount : runningSessionCount // ignore: cast_nullable_to_non_nullable
as int,removesDirectory: null == removesDirectory ? _self.removesDirectory : removesDirectory // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$DirectorySuggestionDto {

 String get path; String get name;
/// Create a copy of DirectorySuggestionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DirectorySuggestionDtoCopyWith<DirectorySuggestionDto> get copyWith => _$DirectorySuggestionDtoCopyWithImpl<DirectorySuggestionDto>(this as DirectorySuggestionDto, _$identity);

  /// Serializes this DirectorySuggestionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DirectorySuggestionDto&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,name);

@override
String toString() {
  return 'DirectorySuggestionDto(path: $path, name: $name)';
}


}

/// @nodoc
abstract mixin class $DirectorySuggestionDtoCopyWith<$Res>  {
  factory $DirectorySuggestionDtoCopyWith(DirectorySuggestionDto value, $Res Function(DirectorySuggestionDto) _then) = _$DirectorySuggestionDtoCopyWithImpl;
@useResult
$Res call({
 String path, String name
});




}
/// @nodoc
class _$DirectorySuggestionDtoCopyWithImpl<$Res>
    implements $DirectorySuggestionDtoCopyWith<$Res> {
  _$DirectorySuggestionDtoCopyWithImpl(this._self, this._then);

  final DirectorySuggestionDto _self;
  final $Res Function(DirectorySuggestionDto) _then;

/// Create a copy of DirectorySuggestionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? name = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DirectorySuggestionDto].
extension DirectorySuggestionDtoPatterns on DirectorySuggestionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DirectorySuggestionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DirectorySuggestionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DirectorySuggestionDto value)  $default,){
final _that = this;
switch (_that) {
case _DirectorySuggestionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DirectorySuggestionDto value)?  $default,){
final _that = this;
switch (_that) {
case _DirectorySuggestionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DirectorySuggestionDto() when $default != null:
return $default(_that.path,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String name)  $default,) {final _that = this;
switch (_that) {
case _DirectorySuggestionDto():
return $default(_that.path,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String name)?  $default,) {final _that = this;
switch (_that) {
case _DirectorySuggestionDto() when $default != null:
return $default(_that.path,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DirectorySuggestionDto implements DirectorySuggestionDto {
  const _DirectorySuggestionDto({required this.path, required this.name});
  factory _DirectorySuggestionDto.fromJson(Map<String, dynamic> json) => _$DirectorySuggestionDtoFromJson(json);

@override final  String path;
@override final  String name;

/// Create a copy of DirectorySuggestionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DirectorySuggestionDtoCopyWith<_DirectorySuggestionDto> get copyWith => __$DirectorySuggestionDtoCopyWithImpl<_DirectorySuggestionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DirectorySuggestionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DirectorySuggestionDto&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,name);

@override
String toString() {
  return 'DirectorySuggestionDto(path: $path, name: $name)';
}


}

/// @nodoc
abstract mixin class _$DirectorySuggestionDtoCopyWith<$Res> implements $DirectorySuggestionDtoCopyWith<$Res> {
  factory _$DirectorySuggestionDtoCopyWith(_DirectorySuggestionDto value, $Res Function(_DirectorySuggestionDto) _then) = __$DirectorySuggestionDtoCopyWithImpl;
@override @useResult
$Res call({
 String path, String name
});




}
/// @nodoc
class __$DirectorySuggestionDtoCopyWithImpl<$Res>
    implements _$DirectorySuggestionDtoCopyWith<$Res> {
  __$DirectorySuggestionDtoCopyWithImpl(this._self, this._then);

  final _DirectorySuggestionDto _self;
  final $Res Function(_DirectorySuggestionDto) _then;

/// Create a copy of DirectorySuggestionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? name = null,}) {
  return _then(_DirectorySuggestionDto(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$GitBranchDto {

 String get name; bool get current; bool get checkedOut;
/// Create a copy of GitBranchDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitBranchDtoCopyWith<GitBranchDto> get copyWith => _$GitBranchDtoCopyWithImpl<GitBranchDto>(this as GitBranchDto, _$identity);

  /// Serializes this GitBranchDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitBranchDto&&(identical(other.name, name) || other.name == name)&&(identical(other.current, current) || other.current == current)&&(identical(other.checkedOut, checkedOut) || other.checkedOut == checkedOut));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,current,checkedOut);

@override
String toString() {
  return 'GitBranchDto(name: $name, current: $current, checkedOut: $checkedOut)';
}


}

/// @nodoc
abstract mixin class $GitBranchDtoCopyWith<$Res>  {
  factory $GitBranchDtoCopyWith(GitBranchDto value, $Res Function(GitBranchDto) _then) = _$GitBranchDtoCopyWithImpl;
@useResult
$Res call({
 String name, bool current, bool checkedOut
});




}
/// @nodoc
class _$GitBranchDtoCopyWithImpl<$Res>
    implements $GitBranchDtoCopyWith<$Res> {
  _$GitBranchDtoCopyWithImpl(this._self, this._then);

  final GitBranchDto _self;
  final $Res Function(GitBranchDto) _then;

/// Create a copy of GitBranchDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? current = null,Object? checkedOut = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as bool,checkedOut: null == checkedOut ? _self.checkedOut : checkedOut // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GitBranchDto].
extension GitBranchDtoPatterns on GitBranchDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitBranchDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitBranchDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitBranchDto value)  $default,){
final _that = this;
switch (_that) {
case _GitBranchDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitBranchDto value)?  $default,){
final _that = this;
switch (_that) {
case _GitBranchDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  bool current,  bool checkedOut)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitBranchDto() when $default != null:
return $default(_that.name,_that.current,_that.checkedOut);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  bool current,  bool checkedOut)  $default,) {final _that = this;
switch (_that) {
case _GitBranchDto():
return $default(_that.name,_that.current,_that.checkedOut);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  bool current,  bool checkedOut)?  $default,) {final _that = this;
switch (_that) {
case _GitBranchDto() when $default != null:
return $default(_that.name,_that.current,_that.checkedOut);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GitBranchDto implements GitBranchDto {
  const _GitBranchDto({required this.name, required this.current, required this.checkedOut});
  factory _GitBranchDto.fromJson(Map<String, dynamic> json) => _$GitBranchDtoFromJson(json);

@override final  String name;
@override final  bool current;
@override final  bool checkedOut;

/// Create a copy of GitBranchDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitBranchDtoCopyWith<_GitBranchDto> get copyWith => __$GitBranchDtoCopyWithImpl<_GitBranchDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GitBranchDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitBranchDto&&(identical(other.name, name) || other.name == name)&&(identical(other.current, current) || other.current == current)&&(identical(other.checkedOut, checkedOut) || other.checkedOut == checkedOut));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,current,checkedOut);

@override
String toString() {
  return 'GitBranchDto(name: $name, current: $current, checkedOut: $checkedOut)';
}


}

/// @nodoc
abstract mixin class _$GitBranchDtoCopyWith<$Res> implements $GitBranchDtoCopyWith<$Res> {
  factory _$GitBranchDtoCopyWith(_GitBranchDto value, $Res Function(_GitBranchDto) _then) = __$GitBranchDtoCopyWithImpl;
@override @useResult
$Res call({
 String name, bool current, bool checkedOut
});




}
/// @nodoc
class __$GitBranchDtoCopyWithImpl<$Res>
    implements _$GitBranchDtoCopyWith<$Res> {
  __$GitBranchDtoCopyWithImpl(this._self, this._then);

  final _GitBranchDto _self;
  final $Res Function(_GitBranchDto) _then;

/// Create a copy of GitBranchDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? current = null,Object? checkedOut = null,}) {
  return _then(_GitBranchDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as bool,checkedOut: null == checkedOut ? _self.checkedOut : checkedOut // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$AgentDto {

 String get id; String get worktreeId; String get title; String get providerConnectionId; String get model; AgentStatus get status; PermissionMode get permissionMode; DateTime get createdAt; DateTime get updatedAt; String get reasoningEffort; String? get activeTurnId; String? get lastError;
/// Create a copy of AgentDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentDtoCopyWith<AgentDto> get copyWith => _$AgentDtoCopyWithImpl<AgentDto>(this as AgentDto, _$identity);

  /// Serializes this AgentDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentDto&&(identical(other.id, id) || other.id == id)&&(identical(other.worktreeId, worktreeId) || other.worktreeId == worktreeId)&&(identical(other.title, title) || other.title == title)&&(identical(other.providerConnectionId, providerConnectionId) || other.providerConnectionId == providerConnectionId)&&(identical(other.model, model) || other.model == model)&&(identical(other.status, status) || other.status == status)&&(identical(other.permissionMode, permissionMode) || other.permissionMode == permissionMode)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort)&&(identical(other.activeTurnId, activeTurnId) || other.activeTurnId == activeTurnId)&&(identical(other.lastError, lastError) || other.lastError == lastError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,worktreeId,title,providerConnectionId,model,status,permissionMode,createdAt,updatedAt,reasoningEffort,activeTurnId,lastError);

@override
String toString() {
  return 'AgentDto(id: $id, worktreeId: $worktreeId, title: $title, providerConnectionId: $providerConnectionId, model: $model, status: $status, permissionMode: $permissionMode, createdAt: $createdAt, updatedAt: $updatedAt, reasoningEffort: $reasoningEffort, activeTurnId: $activeTurnId, lastError: $lastError)';
}


}

/// @nodoc
abstract mixin class $AgentDtoCopyWith<$Res>  {
  factory $AgentDtoCopyWith(AgentDto value, $Res Function(AgentDto) _then) = _$AgentDtoCopyWithImpl;
@useResult
$Res call({
 String id, String worktreeId, String title, String providerConnectionId, String model, AgentStatus status, PermissionMode permissionMode, DateTime createdAt, DateTime updatedAt, String reasoningEffort, String? activeTurnId, String? lastError
});




}
/// @nodoc
class _$AgentDtoCopyWithImpl<$Res>
    implements $AgentDtoCopyWith<$Res> {
  _$AgentDtoCopyWithImpl(this._self, this._then);

  final AgentDto _self;
  final $Res Function(AgentDto) _then;

/// Create a copy of AgentDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? worktreeId = null,Object? title = null,Object? providerConnectionId = null,Object? model = null,Object? status = null,Object? permissionMode = null,Object? createdAt = null,Object? updatedAt = null,Object? reasoningEffort = null,Object? activeTurnId = freezed,Object? lastError = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,worktreeId: null == worktreeId ? _self.worktreeId : worktreeId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,providerConnectionId: null == providerConnectionId ? _self.providerConnectionId : providerConnectionId // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AgentStatus,permissionMode: null == permissionMode ? _self.permissionMode : permissionMode // ignore: cast_nullable_to_non_nullable
as PermissionMode,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reasoningEffort: null == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as String,activeTurnId: freezed == activeTurnId ? _self.activeTurnId : activeTurnId // ignore: cast_nullable_to_non_nullable
as String?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentDto].
extension AgentDtoPatterns on AgentDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentDto value)  $default,){
final _that = this;
switch (_that) {
case _AgentDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentDto value)?  $default,){
final _that = this;
switch (_that) {
case _AgentDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String worktreeId,  String title,  String providerConnectionId,  String model,  AgentStatus status,  PermissionMode permissionMode,  DateTime createdAt,  DateTime updatedAt,  String reasoningEffort,  String? activeTurnId,  String? lastError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentDto() when $default != null:
return $default(_that.id,_that.worktreeId,_that.title,_that.providerConnectionId,_that.model,_that.status,_that.permissionMode,_that.createdAt,_that.updatedAt,_that.reasoningEffort,_that.activeTurnId,_that.lastError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String worktreeId,  String title,  String providerConnectionId,  String model,  AgentStatus status,  PermissionMode permissionMode,  DateTime createdAt,  DateTime updatedAt,  String reasoningEffort,  String? activeTurnId,  String? lastError)  $default,) {final _that = this;
switch (_that) {
case _AgentDto():
return $default(_that.id,_that.worktreeId,_that.title,_that.providerConnectionId,_that.model,_that.status,_that.permissionMode,_that.createdAt,_that.updatedAt,_that.reasoningEffort,_that.activeTurnId,_that.lastError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String worktreeId,  String title,  String providerConnectionId,  String model,  AgentStatus status,  PermissionMode permissionMode,  DateTime createdAt,  DateTime updatedAt,  String reasoningEffort,  String? activeTurnId,  String? lastError)?  $default,) {final _that = this;
switch (_that) {
case _AgentDto() when $default != null:
return $default(_that.id,_that.worktreeId,_that.title,_that.providerConnectionId,_that.model,_that.status,_that.permissionMode,_that.createdAt,_that.updatedAt,_that.reasoningEffort,_that.activeTurnId,_that.lastError);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentDto implements AgentDto {
  const _AgentDto({required this.id, required this.worktreeId, required this.title, required this.providerConnectionId, required this.model, required this.status, required this.permissionMode, required this.createdAt, required this.updatedAt, this.reasoningEffort = 'medium', this.activeTurnId, this.lastError});
  factory _AgentDto.fromJson(Map<String, dynamic> json) => _$AgentDtoFromJson(json);

@override final  String id;
@override final  String worktreeId;
@override final  String title;
@override final  String providerConnectionId;
@override final  String model;
@override final  AgentStatus status;
@override final  PermissionMode permissionMode;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override@JsonKey() final  String reasoningEffort;
@override final  String? activeTurnId;
@override final  String? lastError;

/// Create a copy of AgentDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentDtoCopyWith<_AgentDto> get copyWith => __$AgentDtoCopyWithImpl<_AgentDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentDto&&(identical(other.id, id) || other.id == id)&&(identical(other.worktreeId, worktreeId) || other.worktreeId == worktreeId)&&(identical(other.title, title) || other.title == title)&&(identical(other.providerConnectionId, providerConnectionId) || other.providerConnectionId == providerConnectionId)&&(identical(other.model, model) || other.model == model)&&(identical(other.status, status) || other.status == status)&&(identical(other.permissionMode, permissionMode) || other.permissionMode == permissionMode)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort)&&(identical(other.activeTurnId, activeTurnId) || other.activeTurnId == activeTurnId)&&(identical(other.lastError, lastError) || other.lastError == lastError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,worktreeId,title,providerConnectionId,model,status,permissionMode,createdAt,updatedAt,reasoningEffort,activeTurnId,lastError);

@override
String toString() {
  return 'AgentDto(id: $id, worktreeId: $worktreeId, title: $title, providerConnectionId: $providerConnectionId, model: $model, status: $status, permissionMode: $permissionMode, createdAt: $createdAt, updatedAt: $updatedAt, reasoningEffort: $reasoningEffort, activeTurnId: $activeTurnId, lastError: $lastError)';
}


}

/// @nodoc
abstract mixin class _$AgentDtoCopyWith<$Res> implements $AgentDtoCopyWith<$Res> {
  factory _$AgentDtoCopyWith(_AgentDto value, $Res Function(_AgentDto) _then) = __$AgentDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String worktreeId, String title, String providerConnectionId, String model, AgentStatus status, PermissionMode permissionMode, DateTime createdAt, DateTime updatedAt, String reasoningEffort, String? activeTurnId, String? lastError
});




}
/// @nodoc
class __$AgentDtoCopyWithImpl<$Res>
    implements _$AgentDtoCopyWith<$Res> {
  __$AgentDtoCopyWithImpl(this._self, this._then);

  final _AgentDto _self;
  final $Res Function(_AgentDto) _then;

/// Create a copy of AgentDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? worktreeId = null,Object? title = null,Object? providerConnectionId = null,Object? model = null,Object? status = null,Object? permissionMode = null,Object? createdAt = null,Object? updatedAt = null,Object? reasoningEffort = null,Object? activeTurnId = freezed,Object? lastError = freezed,}) {
  return _then(_AgentDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,worktreeId: null == worktreeId ? _self.worktreeId : worktreeId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,providerConnectionId: null == providerConnectionId ? _self.providerConnectionId : providerConnectionId // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AgentStatus,permissionMode: null == permissionMode ? _self.permissionMode : permissionMode // ignore: cast_nullable_to_non_nullable
as PermissionMode,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reasoningEffort: null == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as String,activeTurnId: freezed == activeTurnId ? _self.activeTurnId : activeTurnId // ignore: cast_nullable_to_non_nullable
as String?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ModelCapabilitiesDto {

 CapabilitySupport get streaming; CapabilitySupport get toolCalling; CapabilitySupport get reasoningEffort; List<String> get supportedReasoningEfforts; CapabilitySource get source;
/// Create a copy of ModelCapabilitiesDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelCapabilitiesDtoCopyWith<ModelCapabilitiesDto> get copyWith => _$ModelCapabilitiesDtoCopyWithImpl<ModelCapabilitiesDto>(this as ModelCapabilitiesDto, _$identity);

  /// Serializes this ModelCapabilitiesDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelCapabilitiesDto&&(identical(other.streaming, streaming) || other.streaming == streaming)&&(identical(other.toolCalling, toolCalling) || other.toolCalling == toolCalling)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort)&&const DeepCollectionEquality().equals(other.supportedReasoningEfforts, supportedReasoningEfforts)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streaming,toolCalling,reasoningEffort,const DeepCollectionEquality().hash(supportedReasoningEfforts),source);

@override
String toString() {
  return 'ModelCapabilitiesDto(streaming: $streaming, toolCalling: $toolCalling, reasoningEffort: $reasoningEffort, supportedReasoningEfforts: $supportedReasoningEfforts, source: $source)';
}


}

/// @nodoc
abstract mixin class $ModelCapabilitiesDtoCopyWith<$Res>  {
  factory $ModelCapabilitiesDtoCopyWith(ModelCapabilitiesDto value, $Res Function(ModelCapabilitiesDto) _then) = _$ModelCapabilitiesDtoCopyWithImpl;
@useResult
$Res call({
 CapabilitySupport streaming, CapabilitySupport toolCalling, CapabilitySupport reasoningEffort, List<String> supportedReasoningEfforts, CapabilitySource source
});




}
/// @nodoc
class _$ModelCapabilitiesDtoCopyWithImpl<$Res>
    implements $ModelCapabilitiesDtoCopyWith<$Res> {
  _$ModelCapabilitiesDtoCopyWithImpl(this._self, this._then);

  final ModelCapabilitiesDto _self;
  final $Res Function(ModelCapabilitiesDto) _then;

/// Create a copy of ModelCapabilitiesDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? streaming = null,Object? toolCalling = null,Object? reasoningEffort = null,Object? supportedReasoningEfforts = null,Object? source = null,}) {
  return _then(_self.copyWith(
streaming: null == streaming ? _self.streaming : streaming // ignore: cast_nullable_to_non_nullable
as CapabilitySupport,toolCalling: null == toolCalling ? _self.toolCalling : toolCalling // ignore: cast_nullable_to_non_nullable
as CapabilitySupport,reasoningEffort: null == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as CapabilitySupport,supportedReasoningEfforts: null == supportedReasoningEfforts ? _self.supportedReasoningEfforts : supportedReasoningEfforts // ignore: cast_nullable_to_non_nullable
as List<String>,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as CapabilitySource,
  ));
}

}


/// Adds pattern-matching-related methods to [ModelCapabilitiesDto].
extension ModelCapabilitiesDtoPatterns on ModelCapabilitiesDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModelCapabilitiesDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModelCapabilitiesDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModelCapabilitiesDto value)  $default,){
final _that = this;
switch (_that) {
case _ModelCapabilitiesDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModelCapabilitiesDto value)?  $default,){
final _that = this;
switch (_that) {
case _ModelCapabilitiesDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CapabilitySupport streaming,  CapabilitySupport toolCalling,  CapabilitySupport reasoningEffort,  List<String> supportedReasoningEfforts,  CapabilitySource source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModelCapabilitiesDto() when $default != null:
return $default(_that.streaming,_that.toolCalling,_that.reasoningEffort,_that.supportedReasoningEfforts,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CapabilitySupport streaming,  CapabilitySupport toolCalling,  CapabilitySupport reasoningEffort,  List<String> supportedReasoningEfforts,  CapabilitySource source)  $default,) {final _that = this;
switch (_that) {
case _ModelCapabilitiesDto():
return $default(_that.streaming,_that.toolCalling,_that.reasoningEffort,_that.supportedReasoningEfforts,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CapabilitySupport streaming,  CapabilitySupport toolCalling,  CapabilitySupport reasoningEffort,  List<String> supportedReasoningEfforts,  CapabilitySource source)?  $default,) {final _that = this;
switch (_that) {
case _ModelCapabilitiesDto() when $default != null:
return $default(_that.streaming,_that.toolCalling,_that.reasoningEffort,_that.supportedReasoningEfforts,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModelCapabilitiesDto implements ModelCapabilitiesDto {
  const _ModelCapabilitiesDto({this.streaming = CapabilitySupport.unknown, this.toolCalling = CapabilitySupport.unknown, this.reasoningEffort = CapabilitySupport.unknown, final  List<String> supportedReasoningEfforts = const <String>[], this.source = CapabilitySource.unknown}): _supportedReasoningEfforts = supportedReasoningEfforts;
  factory _ModelCapabilitiesDto.fromJson(Map<String, dynamic> json) => _$ModelCapabilitiesDtoFromJson(json);

@override@JsonKey() final  CapabilitySupport streaming;
@override@JsonKey() final  CapabilitySupport toolCalling;
@override@JsonKey() final  CapabilitySupport reasoningEffort;
 final  List<String> _supportedReasoningEfforts;
@override@JsonKey() List<String> get supportedReasoningEfforts {
  if (_supportedReasoningEfforts is EqualUnmodifiableListView) return _supportedReasoningEfforts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_supportedReasoningEfforts);
}

@override@JsonKey() final  CapabilitySource source;

/// Create a copy of ModelCapabilitiesDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModelCapabilitiesDtoCopyWith<_ModelCapabilitiesDto> get copyWith => __$ModelCapabilitiesDtoCopyWithImpl<_ModelCapabilitiesDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModelCapabilitiesDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModelCapabilitiesDto&&(identical(other.streaming, streaming) || other.streaming == streaming)&&(identical(other.toolCalling, toolCalling) || other.toolCalling == toolCalling)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort)&&const DeepCollectionEquality().equals(other._supportedReasoningEfforts, _supportedReasoningEfforts)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streaming,toolCalling,reasoningEffort,const DeepCollectionEquality().hash(_supportedReasoningEfforts),source);

@override
String toString() {
  return 'ModelCapabilitiesDto(streaming: $streaming, toolCalling: $toolCalling, reasoningEffort: $reasoningEffort, supportedReasoningEfforts: $supportedReasoningEfforts, source: $source)';
}


}

/// @nodoc
abstract mixin class _$ModelCapabilitiesDtoCopyWith<$Res> implements $ModelCapabilitiesDtoCopyWith<$Res> {
  factory _$ModelCapabilitiesDtoCopyWith(_ModelCapabilitiesDto value, $Res Function(_ModelCapabilitiesDto) _then) = __$ModelCapabilitiesDtoCopyWithImpl;
@override @useResult
$Res call({
 CapabilitySupport streaming, CapabilitySupport toolCalling, CapabilitySupport reasoningEffort, List<String> supportedReasoningEfforts, CapabilitySource source
});




}
/// @nodoc
class __$ModelCapabilitiesDtoCopyWithImpl<$Res>
    implements _$ModelCapabilitiesDtoCopyWith<$Res> {
  __$ModelCapabilitiesDtoCopyWithImpl(this._self, this._then);

  final _ModelCapabilitiesDto _self;
  final $Res Function(_ModelCapabilitiesDto) _then;

/// Create a copy of ModelCapabilitiesDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? streaming = null,Object? toolCalling = null,Object? reasoningEffort = null,Object? supportedReasoningEfforts = null,Object? source = null,}) {
  return _then(_ModelCapabilitiesDto(
streaming: null == streaming ? _self.streaming : streaming // ignore: cast_nullable_to_non_nullable
as CapabilitySupport,toolCalling: null == toolCalling ? _self.toolCalling : toolCalling // ignore: cast_nullable_to_non_nullable
as CapabilitySupport,reasoningEffort: null == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as CapabilitySupport,supportedReasoningEfforts: null == supportedReasoningEfforts ? _self._supportedReasoningEfforts : supportedReasoningEfforts // ignore: cast_nullable_to_non_nullable
as List<String>,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as CapabilitySource,
  ));
}


}


/// @nodoc
mixin _$ModelPricingDto {

 double? get input; double? get output; double? get cacheRead; double? get cacheWrite;
/// Create a copy of ModelPricingDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelPricingDtoCopyWith<ModelPricingDto> get copyWith => _$ModelPricingDtoCopyWithImpl<ModelPricingDto>(this as ModelPricingDto, _$identity);

  /// Serializes this ModelPricingDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelPricingDto&&(identical(other.input, input) || other.input == input)&&(identical(other.output, output) || other.output == output)&&(identical(other.cacheRead, cacheRead) || other.cacheRead == cacheRead)&&(identical(other.cacheWrite, cacheWrite) || other.cacheWrite == cacheWrite));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,input,output,cacheRead,cacheWrite);

@override
String toString() {
  return 'ModelPricingDto(input: $input, output: $output, cacheRead: $cacheRead, cacheWrite: $cacheWrite)';
}


}

/// @nodoc
abstract mixin class $ModelPricingDtoCopyWith<$Res>  {
  factory $ModelPricingDtoCopyWith(ModelPricingDto value, $Res Function(ModelPricingDto) _then) = _$ModelPricingDtoCopyWithImpl;
@useResult
$Res call({
 double? input, double? output, double? cacheRead, double? cacheWrite
});




}
/// @nodoc
class _$ModelPricingDtoCopyWithImpl<$Res>
    implements $ModelPricingDtoCopyWith<$Res> {
  _$ModelPricingDtoCopyWithImpl(this._self, this._then);

  final ModelPricingDto _self;
  final $Res Function(ModelPricingDto) _then;

/// Create a copy of ModelPricingDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? input = freezed,Object? output = freezed,Object? cacheRead = freezed,Object? cacheWrite = freezed,}) {
  return _then(_self.copyWith(
input: freezed == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as double?,output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as double?,cacheRead: freezed == cacheRead ? _self.cacheRead : cacheRead // ignore: cast_nullable_to_non_nullable
as double?,cacheWrite: freezed == cacheWrite ? _self.cacheWrite : cacheWrite // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModelPricingDto].
extension ModelPricingDtoPatterns on ModelPricingDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModelPricingDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModelPricingDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModelPricingDto value)  $default,){
final _that = this;
switch (_that) {
case _ModelPricingDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModelPricingDto value)?  $default,){
final _that = this;
switch (_that) {
case _ModelPricingDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? input,  double? output,  double? cacheRead,  double? cacheWrite)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModelPricingDto() when $default != null:
return $default(_that.input,_that.output,_that.cacheRead,_that.cacheWrite);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? input,  double? output,  double? cacheRead,  double? cacheWrite)  $default,) {final _that = this;
switch (_that) {
case _ModelPricingDto():
return $default(_that.input,_that.output,_that.cacheRead,_that.cacheWrite);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? input,  double? output,  double? cacheRead,  double? cacheWrite)?  $default,) {final _that = this;
switch (_that) {
case _ModelPricingDto() when $default != null:
return $default(_that.input,_that.output,_that.cacheRead,_that.cacheWrite);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModelPricingDto implements ModelPricingDto {
  const _ModelPricingDto({this.input, this.output, this.cacheRead, this.cacheWrite});
  factory _ModelPricingDto.fromJson(Map<String, dynamic> json) => _$ModelPricingDtoFromJson(json);

@override final  double? input;
@override final  double? output;
@override final  double? cacheRead;
@override final  double? cacheWrite;

/// Create a copy of ModelPricingDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModelPricingDtoCopyWith<_ModelPricingDto> get copyWith => __$ModelPricingDtoCopyWithImpl<_ModelPricingDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModelPricingDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModelPricingDto&&(identical(other.input, input) || other.input == input)&&(identical(other.output, output) || other.output == output)&&(identical(other.cacheRead, cacheRead) || other.cacheRead == cacheRead)&&(identical(other.cacheWrite, cacheWrite) || other.cacheWrite == cacheWrite));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,input,output,cacheRead,cacheWrite);

@override
String toString() {
  return 'ModelPricingDto(input: $input, output: $output, cacheRead: $cacheRead, cacheWrite: $cacheWrite)';
}


}

/// @nodoc
abstract mixin class _$ModelPricingDtoCopyWith<$Res> implements $ModelPricingDtoCopyWith<$Res> {
  factory _$ModelPricingDtoCopyWith(_ModelPricingDto value, $Res Function(_ModelPricingDto) _then) = __$ModelPricingDtoCopyWithImpl;
@override @useResult
$Res call({
 double? input, double? output, double? cacheRead, double? cacheWrite
});




}
/// @nodoc
class __$ModelPricingDtoCopyWithImpl<$Res>
    implements _$ModelPricingDtoCopyWith<$Res> {
  __$ModelPricingDtoCopyWithImpl(this._self, this._then);

  final _ModelPricingDto _self;
  final $Res Function(_ModelPricingDto) _then;

/// Create a copy of ModelPricingDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? input = freezed,Object? output = freezed,Object? cacheRead = freezed,Object? cacheWrite = freezed,}) {
  return _then(_ModelPricingDto(
input: freezed == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as double?,output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as double?,cacheRead: freezed == cacheRead ? _self.cacheRead : cacheRead // ignore: cast_nullable_to_non_nullable
as double?,cacheWrite: freezed == cacheWrite ? _self.cacheWrite : cacheWrite // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$ModelLimitsDto {

 int? get context; int? get input; int? get output;
/// Create a copy of ModelLimitsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelLimitsDtoCopyWith<ModelLimitsDto> get copyWith => _$ModelLimitsDtoCopyWithImpl<ModelLimitsDto>(this as ModelLimitsDto, _$identity);

  /// Serializes this ModelLimitsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelLimitsDto&&(identical(other.context, context) || other.context == context)&&(identical(other.input, input) || other.input == input)&&(identical(other.output, output) || other.output == output));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,context,input,output);

@override
String toString() {
  return 'ModelLimitsDto(context: $context, input: $input, output: $output)';
}


}

/// @nodoc
abstract mixin class $ModelLimitsDtoCopyWith<$Res>  {
  factory $ModelLimitsDtoCopyWith(ModelLimitsDto value, $Res Function(ModelLimitsDto) _then) = _$ModelLimitsDtoCopyWithImpl;
@useResult
$Res call({
 int? context, int? input, int? output
});




}
/// @nodoc
class _$ModelLimitsDtoCopyWithImpl<$Res>
    implements $ModelLimitsDtoCopyWith<$Res> {
  _$ModelLimitsDtoCopyWithImpl(this._self, this._then);

  final ModelLimitsDto _self;
  final $Res Function(ModelLimitsDto) _then;

/// Create a copy of ModelLimitsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? context = freezed,Object? input = freezed,Object? output = freezed,}) {
  return _then(_self.copyWith(
context: freezed == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as int?,input: freezed == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as int?,output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModelLimitsDto].
extension ModelLimitsDtoPatterns on ModelLimitsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModelLimitsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModelLimitsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModelLimitsDto value)  $default,){
final _that = this;
switch (_that) {
case _ModelLimitsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModelLimitsDto value)?  $default,){
final _that = this;
switch (_that) {
case _ModelLimitsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? context,  int? input,  int? output)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModelLimitsDto() when $default != null:
return $default(_that.context,_that.input,_that.output);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? context,  int? input,  int? output)  $default,) {final _that = this;
switch (_that) {
case _ModelLimitsDto():
return $default(_that.context,_that.input,_that.output);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? context,  int? input,  int? output)?  $default,) {final _that = this;
switch (_that) {
case _ModelLimitsDto() when $default != null:
return $default(_that.context,_that.input,_that.output);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModelLimitsDto implements ModelLimitsDto {
  const _ModelLimitsDto({this.context, this.input, this.output});
  factory _ModelLimitsDto.fromJson(Map<String, dynamic> json) => _$ModelLimitsDtoFromJson(json);

@override final  int? context;
@override final  int? input;
@override final  int? output;

/// Create a copy of ModelLimitsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModelLimitsDtoCopyWith<_ModelLimitsDto> get copyWith => __$ModelLimitsDtoCopyWithImpl<_ModelLimitsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModelLimitsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModelLimitsDto&&(identical(other.context, context) || other.context == context)&&(identical(other.input, input) || other.input == input)&&(identical(other.output, output) || other.output == output));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,context,input,output);

@override
String toString() {
  return 'ModelLimitsDto(context: $context, input: $input, output: $output)';
}


}

/// @nodoc
abstract mixin class _$ModelLimitsDtoCopyWith<$Res> implements $ModelLimitsDtoCopyWith<$Res> {
  factory _$ModelLimitsDtoCopyWith(_ModelLimitsDto value, $Res Function(_ModelLimitsDto) _then) = __$ModelLimitsDtoCopyWithImpl;
@override @useResult
$Res call({
 int? context, int? input, int? output
});




}
/// @nodoc
class __$ModelLimitsDtoCopyWithImpl<$Res>
    implements _$ModelLimitsDtoCopyWith<$Res> {
  __$ModelLimitsDtoCopyWithImpl(this._self, this._then);

  final _ModelLimitsDto _self;
  final $Res Function(_ModelLimitsDto) _then;

/// Create a copy of ModelLimitsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? context = freezed,Object? input = freezed,Object? output = freezed,}) {
  return _then(_ModelLimitsDto(
context: freezed == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as int?,input: freezed == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as int?,output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ProviderAuthMethodDto {

 String get id; String get label; ProviderAuthKind get kind; ProviderAuthFlow get flow; bool get experimental;
/// Create a copy of ProviderAuthMethodDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderAuthMethodDtoCopyWith<ProviderAuthMethodDto> get copyWith => _$ProviderAuthMethodDtoCopyWithImpl<ProviderAuthMethodDto>(this as ProviderAuthMethodDto, _$identity);

  /// Serializes this ProviderAuthMethodDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderAuthMethodDto&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.flow, flow) || other.flow == flow)&&(identical(other.experimental, experimental) || other.experimental == experimental));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,kind,flow,experimental);

@override
String toString() {
  return 'ProviderAuthMethodDto(id: $id, label: $label, kind: $kind, flow: $flow, experimental: $experimental)';
}


}

/// @nodoc
abstract mixin class $ProviderAuthMethodDtoCopyWith<$Res>  {
  factory $ProviderAuthMethodDtoCopyWith(ProviderAuthMethodDto value, $Res Function(ProviderAuthMethodDto) _then) = _$ProviderAuthMethodDtoCopyWithImpl;
@useResult
$Res call({
 String id, String label, ProviderAuthKind kind, ProviderAuthFlow flow, bool experimental
});




}
/// @nodoc
class _$ProviderAuthMethodDtoCopyWithImpl<$Res>
    implements $ProviderAuthMethodDtoCopyWith<$Res> {
  _$ProviderAuthMethodDtoCopyWithImpl(this._self, this._then);

  final ProviderAuthMethodDto _self;
  final $Res Function(ProviderAuthMethodDto) _then;

/// Create a copy of ProviderAuthMethodDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? kind = null,Object? flow = null,Object? experimental = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ProviderAuthKind,flow: null == flow ? _self.flow : flow // ignore: cast_nullable_to_non_nullable
as ProviderAuthFlow,experimental: null == experimental ? _self.experimental : experimental // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderAuthMethodDto].
extension ProviderAuthMethodDtoPatterns on ProviderAuthMethodDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderAuthMethodDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderAuthMethodDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderAuthMethodDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderAuthMethodDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderAuthMethodDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderAuthMethodDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  ProviderAuthKind kind,  ProviderAuthFlow flow,  bool experimental)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderAuthMethodDto() when $default != null:
return $default(_that.id,_that.label,_that.kind,_that.flow,_that.experimental);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  ProviderAuthKind kind,  ProviderAuthFlow flow,  bool experimental)  $default,) {final _that = this;
switch (_that) {
case _ProviderAuthMethodDto():
return $default(_that.id,_that.label,_that.kind,_that.flow,_that.experimental);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  ProviderAuthKind kind,  ProviderAuthFlow flow,  bool experimental)?  $default,) {final _that = this;
switch (_that) {
case _ProviderAuthMethodDto() when $default != null:
return $default(_that.id,_that.label,_that.kind,_that.flow,_that.experimental);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderAuthMethodDto implements ProviderAuthMethodDto {
  const _ProviderAuthMethodDto({required this.id, required this.label, required this.kind, required this.flow, this.experimental = false});
  factory _ProviderAuthMethodDto.fromJson(Map<String, dynamic> json) => _$ProviderAuthMethodDtoFromJson(json);

@override final  String id;
@override final  String label;
@override final  ProviderAuthKind kind;
@override final  ProviderAuthFlow flow;
@override@JsonKey() final  bool experimental;

/// Create a copy of ProviderAuthMethodDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderAuthMethodDtoCopyWith<_ProviderAuthMethodDto> get copyWith => __$ProviderAuthMethodDtoCopyWithImpl<_ProviderAuthMethodDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderAuthMethodDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderAuthMethodDto&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.flow, flow) || other.flow == flow)&&(identical(other.experimental, experimental) || other.experimental == experimental));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,kind,flow,experimental);

@override
String toString() {
  return 'ProviderAuthMethodDto(id: $id, label: $label, kind: $kind, flow: $flow, experimental: $experimental)';
}


}

/// @nodoc
abstract mixin class _$ProviderAuthMethodDtoCopyWith<$Res> implements $ProviderAuthMethodDtoCopyWith<$Res> {
  factory _$ProviderAuthMethodDtoCopyWith(_ProviderAuthMethodDto value, $Res Function(_ProviderAuthMethodDto) _then) = __$ProviderAuthMethodDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, ProviderAuthKind kind, ProviderAuthFlow flow, bool experimental
});




}
/// @nodoc
class __$ProviderAuthMethodDtoCopyWithImpl<$Res>
    implements _$ProviderAuthMethodDtoCopyWith<$Res> {
  __$ProviderAuthMethodDtoCopyWithImpl(this._self, this._then);

  final _ProviderAuthMethodDto _self;
  final $Res Function(_ProviderAuthMethodDto) _then;

/// Create a copy of ProviderAuthMethodDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? kind = null,Object? flow = null,Object? experimental = null,}) {
  return _then(_ProviderAuthMethodDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ProviderAuthKind,flow: null == flow ? _self.flow : flow // ignore: cast_nullable_to_non_nullable
as ProviderAuthFlow,experimental: null == experimental ? _self.experimental : experimental // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ProviderDefinitionDto {

 String get id; String get name; String get description; List<ProviderAuthMethodDto> get authMethods; List<String> get recommendedModelIds; bool get local; bool get experimental; String? get documentationUrl;
/// Create a copy of ProviderDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderDefinitionDtoCopyWith<ProviderDefinitionDto> get copyWith => _$ProviderDefinitionDtoCopyWithImpl<ProviderDefinitionDto>(this as ProviderDefinitionDto, _$identity);

  /// Serializes this ProviderDefinitionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderDefinitionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.authMethods, authMethods)&&const DeepCollectionEquality().equals(other.recommendedModelIds, recommendedModelIds)&&(identical(other.local, local) || other.local == local)&&(identical(other.experimental, experimental) || other.experimental == experimental)&&(identical(other.documentationUrl, documentationUrl) || other.documentationUrl == documentationUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,const DeepCollectionEquality().hash(authMethods),const DeepCollectionEquality().hash(recommendedModelIds),local,experimental,documentationUrl);

@override
String toString() {
  return 'ProviderDefinitionDto(id: $id, name: $name, description: $description, authMethods: $authMethods, recommendedModelIds: $recommendedModelIds, local: $local, experimental: $experimental, documentationUrl: $documentationUrl)';
}


}

/// @nodoc
abstract mixin class $ProviderDefinitionDtoCopyWith<$Res>  {
  factory $ProviderDefinitionDtoCopyWith(ProviderDefinitionDto value, $Res Function(ProviderDefinitionDto) _then) = _$ProviderDefinitionDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, List<ProviderAuthMethodDto> authMethods, List<String> recommendedModelIds, bool local, bool experimental, String? documentationUrl
});




}
/// @nodoc
class _$ProviderDefinitionDtoCopyWithImpl<$Res>
    implements $ProviderDefinitionDtoCopyWith<$Res> {
  _$ProviderDefinitionDtoCopyWithImpl(this._self, this._then);

  final ProviderDefinitionDto _self;
  final $Res Function(ProviderDefinitionDto) _then;

/// Create a copy of ProviderDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? authMethods = null,Object? recommendedModelIds = null,Object? local = null,Object? experimental = null,Object? documentationUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,authMethods: null == authMethods ? _self.authMethods : authMethods // ignore: cast_nullable_to_non_nullable
as List<ProviderAuthMethodDto>,recommendedModelIds: null == recommendedModelIds ? _self.recommendedModelIds : recommendedModelIds // ignore: cast_nullable_to_non_nullable
as List<String>,local: null == local ? _self.local : local // ignore: cast_nullable_to_non_nullable
as bool,experimental: null == experimental ? _self.experimental : experimental // ignore: cast_nullable_to_non_nullable
as bool,documentationUrl: freezed == documentationUrl ? _self.documentationUrl : documentationUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderDefinitionDto].
extension ProviderDefinitionDtoPatterns on ProviderDefinitionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderDefinitionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderDefinitionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderDefinitionDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderDefinitionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderDefinitionDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderDefinitionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  List<ProviderAuthMethodDto> authMethods,  List<String> recommendedModelIds,  bool local,  bool experimental,  String? documentationUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderDefinitionDto() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.authMethods,_that.recommendedModelIds,_that.local,_that.experimental,_that.documentationUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  List<ProviderAuthMethodDto> authMethods,  List<String> recommendedModelIds,  bool local,  bool experimental,  String? documentationUrl)  $default,) {final _that = this;
switch (_that) {
case _ProviderDefinitionDto():
return $default(_that.id,_that.name,_that.description,_that.authMethods,_that.recommendedModelIds,_that.local,_that.experimental,_that.documentationUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  List<ProviderAuthMethodDto> authMethods,  List<String> recommendedModelIds,  bool local,  bool experimental,  String? documentationUrl)?  $default,) {final _that = this;
switch (_that) {
case _ProviderDefinitionDto() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.authMethods,_that.recommendedModelIds,_that.local,_that.experimental,_that.documentationUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderDefinitionDto implements ProviderDefinitionDto {
  const _ProviderDefinitionDto({required this.id, required this.name, required this.description, required final  List<ProviderAuthMethodDto> authMethods, final  List<String> recommendedModelIds = const <String>[], this.local = false, this.experimental = false, this.documentationUrl}): _authMethods = authMethods,_recommendedModelIds = recommendedModelIds;
  factory _ProviderDefinitionDto.fromJson(Map<String, dynamic> json) => _$ProviderDefinitionDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String description;
 final  List<ProviderAuthMethodDto> _authMethods;
@override List<ProviderAuthMethodDto> get authMethods {
  if (_authMethods is EqualUnmodifiableListView) return _authMethods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_authMethods);
}

 final  List<String> _recommendedModelIds;
@override@JsonKey() List<String> get recommendedModelIds {
  if (_recommendedModelIds is EqualUnmodifiableListView) return _recommendedModelIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recommendedModelIds);
}

@override@JsonKey() final  bool local;
@override@JsonKey() final  bool experimental;
@override final  String? documentationUrl;

/// Create a copy of ProviderDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderDefinitionDtoCopyWith<_ProviderDefinitionDto> get copyWith => __$ProviderDefinitionDtoCopyWithImpl<_ProviderDefinitionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderDefinitionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderDefinitionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._authMethods, _authMethods)&&const DeepCollectionEquality().equals(other._recommendedModelIds, _recommendedModelIds)&&(identical(other.local, local) || other.local == local)&&(identical(other.experimental, experimental) || other.experimental == experimental)&&(identical(other.documentationUrl, documentationUrl) || other.documentationUrl == documentationUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,const DeepCollectionEquality().hash(_authMethods),const DeepCollectionEquality().hash(_recommendedModelIds),local,experimental,documentationUrl);

@override
String toString() {
  return 'ProviderDefinitionDto(id: $id, name: $name, description: $description, authMethods: $authMethods, recommendedModelIds: $recommendedModelIds, local: $local, experimental: $experimental, documentationUrl: $documentationUrl)';
}


}

/// @nodoc
abstract mixin class _$ProviderDefinitionDtoCopyWith<$Res> implements $ProviderDefinitionDtoCopyWith<$Res> {
  factory _$ProviderDefinitionDtoCopyWith(_ProviderDefinitionDto value, $Res Function(_ProviderDefinitionDto) _then) = __$ProviderDefinitionDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, List<ProviderAuthMethodDto> authMethods, List<String> recommendedModelIds, bool local, bool experimental, String? documentationUrl
});




}
/// @nodoc
class __$ProviderDefinitionDtoCopyWithImpl<$Res>
    implements _$ProviderDefinitionDtoCopyWith<$Res> {
  __$ProviderDefinitionDtoCopyWithImpl(this._self, this._then);

  final _ProviderDefinitionDto _self;
  final $Res Function(_ProviderDefinitionDto) _then;

/// Create a copy of ProviderDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? authMethods = null,Object? recommendedModelIds = null,Object? local = null,Object? experimental = null,Object? documentationUrl = freezed,}) {
  return _then(_ProviderDefinitionDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,authMethods: null == authMethods ? _self._authMethods : authMethods // ignore: cast_nullable_to_non_nullable
as List<ProviderAuthMethodDto>,recommendedModelIds: null == recommendedModelIds ? _self._recommendedModelIds : recommendedModelIds // ignore: cast_nullable_to_non_nullable
as List<String>,local: null == local ? _self.local : local // ignore: cast_nullable_to_non_nullable
as bool,experimental: null == experimental ? _self.experimental : experimental // ignore: cast_nullable_to_non_nullable
as bool,documentationUrl: freezed == documentationUrl ? _self.documentationUrl : documentationUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CustomProviderConfigDto {

 String get name; String get baseUrl; ProviderApiFormat get apiFormat; bool get authenticationRequired; bool get strictToolSchema; List<String> get manualModelIds;
/// Create a copy of CustomProviderConfigDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomProviderConfigDtoCopyWith<CustomProviderConfigDto> get copyWith => _$CustomProviderConfigDtoCopyWithImpl<CustomProviderConfigDto>(this as CustomProviderConfigDto, _$identity);

  /// Serializes this CustomProviderConfigDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomProviderConfigDto&&(identical(other.name, name) || other.name == name)&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.apiFormat, apiFormat) || other.apiFormat == apiFormat)&&(identical(other.authenticationRequired, authenticationRequired) || other.authenticationRequired == authenticationRequired)&&(identical(other.strictToolSchema, strictToolSchema) || other.strictToolSchema == strictToolSchema)&&const DeepCollectionEquality().equals(other.manualModelIds, manualModelIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,baseUrl,apiFormat,authenticationRequired,strictToolSchema,const DeepCollectionEquality().hash(manualModelIds));

@override
String toString() {
  return 'CustomProviderConfigDto(name: $name, baseUrl: $baseUrl, apiFormat: $apiFormat, authenticationRequired: $authenticationRequired, strictToolSchema: $strictToolSchema, manualModelIds: $manualModelIds)';
}


}

/// @nodoc
abstract mixin class $CustomProviderConfigDtoCopyWith<$Res>  {
  factory $CustomProviderConfigDtoCopyWith(CustomProviderConfigDto value, $Res Function(CustomProviderConfigDto) _then) = _$CustomProviderConfigDtoCopyWithImpl;
@useResult
$Res call({
 String name, String baseUrl, ProviderApiFormat apiFormat, bool authenticationRequired, bool strictToolSchema, List<String> manualModelIds
});




}
/// @nodoc
class _$CustomProviderConfigDtoCopyWithImpl<$Res>
    implements $CustomProviderConfigDtoCopyWith<$Res> {
  _$CustomProviderConfigDtoCopyWithImpl(this._self, this._then);

  final CustomProviderConfigDto _self;
  final $Res Function(CustomProviderConfigDto) _then;

/// Create a copy of CustomProviderConfigDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? baseUrl = null,Object? apiFormat = null,Object? authenticationRequired = null,Object? strictToolSchema = null,Object? manualModelIds = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,apiFormat: null == apiFormat ? _self.apiFormat : apiFormat // ignore: cast_nullable_to_non_nullable
as ProviderApiFormat,authenticationRequired: null == authenticationRequired ? _self.authenticationRequired : authenticationRequired // ignore: cast_nullable_to_non_nullable
as bool,strictToolSchema: null == strictToolSchema ? _self.strictToolSchema : strictToolSchema // ignore: cast_nullable_to_non_nullable
as bool,manualModelIds: null == manualModelIds ? _self.manualModelIds : manualModelIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomProviderConfigDto].
extension CustomProviderConfigDtoPatterns on CustomProviderConfigDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomProviderConfigDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomProviderConfigDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomProviderConfigDto value)  $default,){
final _that = this;
switch (_that) {
case _CustomProviderConfigDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomProviderConfigDto value)?  $default,){
final _that = this;
switch (_that) {
case _CustomProviderConfigDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String baseUrl,  ProviderApiFormat apiFormat,  bool authenticationRequired,  bool strictToolSchema,  List<String> manualModelIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomProviderConfigDto() when $default != null:
return $default(_that.name,_that.baseUrl,_that.apiFormat,_that.authenticationRequired,_that.strictToolSchema,_that.manualModelIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String baseUrl,  ProviderApiFormat apiFormat,  bool authenticationRequired,  bool strictToolSchema,  List<String> manualModelIds)  $default,) {final _that = this;
switch (_that) {
case _CustomProviderConfigDto():
return $default(_that.name,_that.baseUrl,_that.apiFormat,_that.authenticationRequired,_that.strictToolSchema,_that.manualModelIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String baseUrl,  ProviderApiFormat apiFormat,  bool authenticationRequired,  bool strictToolSchema,  List<String> manualModelIds)?  $default,) {final _that = this;
switch (_that) {
case _CustomProviderConfigDto() when $default != null:
return $default(_that.name,_that.baseUrl,_that.apiFormat,_that.authenticationRequired,_that.strictToolSchema,_that.manualModelIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustomProviderConfigDto implements CustomProviderConfigDto {
  const _CustomProviderConfigDto({required this.name, required this.baseUrl, required this.apiFormat, required this.authenticationRequired, this.strictToolSchema = false, final  List<String> manualModelIds = const <String>[]}): _manualModelIds = manualModelIds;
  factory _CustomProviderConfigDto.fromJson(Map<String, dynamic> json) => _$CustomProviderConfigDtoFromJson(json);

@override final  String name;
@override final  String baseUrl;
@override final  ProviderApiFormat apiFormat;
@override final  bool authenticationRequired;
@override@JsonKey() final  bool strictToolSchema;
 final  List<String> _manualModelIds;
@override@JsonKey() List<String> get manualModelIds {
  if (_manualModelIds is EqualUnmodifiableListView) return _manualModelIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_manualModelIds);
}


/// Create a copy of CustomProviderConfigDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomProviderConfigDtoCopyWith<_CustomProviderConfigDto> get copyWith => __$CustomProviderConfigDtoCopyWithImpl<_CustomProviderConfigDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomProviderConfigDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomProviderConfigDto&&(identical(other.name, name) || other.name == name)&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.apiFormat, apiFormat) || other.apiFormat == apiFormat)&&(identical(other.authenticationRequired, authenticationRequired) || other.authenticationRequired == authenticationRequired)&&(identical(other.strictToolSchema, strictToolSchema) || other.strictToolSchema == strictToolSchema)&&const DeepCollectionEquality().equals(other._manualModelIds, _manualModelIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,baseUrl,apiFormat,authenticationRequired,strictToolSchema,const DeepCollectionEquality().hash(_manualModelIds));

@override
String toString() {
  return 'CustomProviderConfigDto(name: $name, baseUrl: $baseUrl, apiFormat: $apiFormat, authenticationRequired: $authenticationRequired, strictToolSchema: $strictToolSchema, manualModelIds: $manualModelIds)';
}


}

/// @nodoc
abstract mixin class _$CustomProviderConfigDtoCopyWith<$Res> implements $CustomProviderConfigDtoCopyWith<$Res> {
  factory _$CustomProviderConfigDtoCopyWith(_CustomProviderConfigDto value, $Res Function(_CustomProviderConfigDto) _then) = __$CustomProviderConfigDtoCopyWithImpl;
@override @useResult
$Res call({
 String name, String baseUrl, ProviderApiFormat apiFormat, bool authenticationRequired, bool strictToolSchema, List<String> manualModelIds
});




}
/// @nodoc
class __$CustomProviderConfigDtoCopyWithImpl<$Res>
    implements _$CustomProviderConfigDtoCopyWith<$Res> {
  __$CustomProviderConfigDtoCopyWithImpl(this._self, this._then);

  final _CustomProviderConfigDto _self;
  final $Res Function(_CustomProviderConfigDto) _then;

/// Create a copy of CustomProviderConfigDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? baseUrl = null,Object? apiFormat = null,Object? authenticationRequired = null,Object? strictToolSchema = null,Object? manualModelIds = null,}) {
  return _then(_CustomProviderConfigDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,apiFormat: null == apiFormat ? _self.apiFormat : apiFormat // ignore: cast_nullable_to_non_nullable
as ProviderApiFormat,authenticationRequired: null == authenticationRequired ? _self.authenticationRequired : authenticationRequired // ignore: cast_nullable_to_non_nullable
as bool,strictToolSchema: null == strictToolSchema ? _self.strictToolSchema : strictToolSchema // ignore: cast_nullable_to_non_nullable
as bool,manualModelIds: null == manualModelIds ? _self._manualModelIds : manualModelIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$ProviderConnectionDto {

 String get id; String get definitionId; String get displayName; ProviderConnectionStatus get status; ProviderAuthKind get authKind; ProviderCredentialOrigin get credentialOrigin; bool get isDefault; DateTime get createdAt; DateTime get updatedAt; String? get defaultModelId; String? get error; CustomProviderConfigDto? get customConfig;
/// Create a copy of ProviderConnectionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderConnectionDtoCopyWith<ProviderConnectionDto> get copyWith => _$ProviderConnectionDtoCopyWithImpl<ProviderConnectionDto>(this as ProviderConnectionDto, _$identity);

  /// Serializes this ProviderConnectionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderConnectionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.definitionId, definitionId) || other.definitionId == definitionId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.status, status) || other.status == status)&&(identical(other.authKind, authKind) || other.authKind == authKind)&&(identical(other.credentialOrigin, credentialOrigin) || other.credentialOrigin == credentialOrigin)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.defaultModelId, defaultModelId) || other.defaultModelId == defaultModelId)&&(identical(other.error, error) || other.error == error)&&(identical(other.customConfig, customConfig) || other.customConfig == customConfig));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,definitionId,displayName,status,authKind,credentialOrigin,isDefault,createdAt,updatedAt,defaultModelId,error,customConfig);

@override
String toString() {
  return 'ProviderConnectionDto(id: $id, definitionId: $definitionId, displayName: $displayName, status: $status, authKind: $authKind, credentialOrigin: $credentialOrigin, isDefault: $isDefault, createdAt: $createdAt, updatedAt: $updatedAt, defaultModelId: $defaultModelId, error: $error, customConfig: $customConfig)';
}


}

/// @nodoc
abstract mixin class $ProviderConnectionDtoCopyWith<$Res>  {
  factory $ProviderConnectionDtoCopyWith(ProviderConnectionDto value, $Res Function(ProviderConnectionDto) _then) = _$ProviderConnectionDtoCopyWithImpl;
@useResult
$Res call({
 String id, String definitionId, String displayName, ProviderConnectionStatus status, ProviderAuthKind authKind, ProviderCredentialOrigin credentialOrigin, bool isDefault, DateTime createdAt, DateTime updatedAt, String? defaultModelId, String? error, CustomProviderConfigDto? customConfig
});


$CustomProviderConfigDtoCopyWith<$Res>? get customConfig;

}
/// @nodoc
class _$ProviderConnectionDtoCopyWithImpl<$Res>
    implements $ProviderConnectionDtoCopyWith<$Res> {
  _$ProviderConnectionDtoCopyWithImpl(this._self, this._then);

  final ProviderConnectionDto _self;
  final $Res Function(ProviderConnectionDto) _then;

/// Create a copy of ProviderConnectionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? definitionId = null,Object? displayName = null,Object? status = null,Object? authKind = null,Object? credentialOrigin = null,Object? isDefault = null,Object? createdAt = null,Object? updatedAt = null,Object? defaultModelId = freezed,Object? error = freezed,Object? customConfig = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,definitionId: null == definitionId ? _self.definitionId : definitionId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProviderConnectionStatus,authKind: null == authKind ? _self.authKind : authKind // ignore: cast_nullable_to_non_nullable
as ProviderAuthKind,credentialOrigin: null == credentialOrigin ? _self.credentialOrigin : credentialOrigin // ignore: cast_nullable_to_non_nullable
as ProviderCredentialOrigin,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,defaultModelId: freezed == defaultModelId ? _self.defaultModelId : defaultModelId // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,customConfig: freezed == customConfig ? _self.customConfig : customConfig // ignore: cast_nullable_to_non_nullable
as CustomProviderConfigDto?,
  ));
}
/// Create a copy of ProviderConnectionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomProviderConfigDtoCopyWith<$Res>? get customConfig {
    if (_self.customConfig == null) {
    return null;
  }

  return $CustomProviderConfigDtoCopyWith<$Res>(_self.customConfig!, (value) {
    return _then(_self.copyWith(customConfig: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProviderConnectionDto].
extension ProviderConnectionDtoPatterns on ProviderConnectionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderConnectionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderConnectionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderConnectionDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderConnectionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderConnectionDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderConnectionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String definitionId,  String displayName,  ProviderConnectionStatus status,  ProviderAuthKind authKind,  ProviderCredentialOrigin credentialOrigin,  bool isDefault,  DateTime createdAt,  DateTime updatedAt,  String? defaultModelId,  String? error,  CustomProviderConfigDto? customConfig)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderConnectionDto() when $default != null:
return $default(_that.id,_that.definitionId,_that.displayName,_that.status,_that.authKind,_that.credentialOrigin,_that.isDefault,_that.createdAt,_that.updatedAt,_that.defaultModelId,_that.error,_that.customConfig);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String definitionId,  String displayName,  ProviderConnectionStatus status,  ProviderAuthKind authKind,  ProviderCredentialOrigin credentialOrigin,  bool isDefault,  DateTime createdAt,  DateTime updatedAt,  String? defaultModelId,  String? error,  CustomProviderConfigDto? customConfig)  $default,) {final _that = this;
switch (_that) {
case _ProviderConnectionDto():
return $default(_that.id,_that.definitionId,_that.displayName,_that.status,_that.authKind,_that.credentialOrigin,_that.isDefault,_that.createdAt,_that.updatedAt,_that.defaultModelId,_that.error,_that.customConfig);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String definitionId,  String displayName,  ProviderConnectionStatus status,  ProviderAuthKind authKind,  ProviderCredentialOrigin credentialOrigin,  bool isDefault,  DateTime createdAt,  DateTime updatedAt,  String? defaultModelId,  String? error,  CustomProviderConfigDto? customConfig)?  $default,) {final _that = this;
switch (_that) {
case _ProviderConnectionDto() when $default != null:
return $default(_that.id,_that.definitionId,_that.displayName,_that.status,_that.authKind,_that.credentialOrigin,_that.isDefault,_that.createdAt,_that.updatedAt,_that.defaultModelId,_that.error,_that.customConfig);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderConnectionDto implements ProviderConnectionDto {
  const _ProviderConnectionDto({required this.id, required this.definitionId, required this.displayName, required this.status, required this.authKind, required this.credentialOrigin, required this.isDefault, required this.createdAt, required this.updatedAt, this.defaultModelId, this.error, this.customConfig});
  factory _ProviderConnectionDto.fromJson(Map<String, dynamic> json) => _$ProviderConnectionDtoFromJson(json);

@override final  String id;
@override final  String definitionId;
@override final  String displayName;
@override final  ProviderConnectionStatus status;
@override final  ProviderAuthKind authKind;
@override final  ProviderCredentialOrigin credentialOrigin;
@override final  bool isDefault;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? defaultModelId;
@override final  String? error;
@override final  CustomProviderConfigDto? customConfig;

/// Create a copy of ProviderConnectionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderConnectionDtoCopyWith<_ProviderConnectionDto> get copyWith => __$ProviderConnectionDtoCopyWithImpl<_ProviderConnectionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderConnectionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderConnectionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.definitionId, definitionId) || other.definitionId == definitionId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.status, status) || other.status == status)&&(identical(other.authKind, authKind) || other.authKind == authKind)&&(identical(other.credentialOrigin, credentialOrigin) || other.credentialOrigin == credentialOrigin)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.defaultModelId, defaultModelId) || other.defaultModelId == defaultModelId)&&(identical(other.error, error) || other.error == error)&&(identical(other.customConfig, customConfig) || other.customConfig == customConfig));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,definitionId,displayName,status,authKind,credentialOrigin,isDefault,createdAt,updatedAt,defaultModelId,error,customConfig);

@override
String toString() {
  return 'ProviderConnectionDto(id: $id, definitionId: $definitionId, displayName: $displayName, status: $status, authKind: $authKind, credentialOrigin: $credentialOrigin, isDefault: $isDefault, createdAt: $createdAt, updatedAt: $updatedAt, defaultModelId: $defaultModelId, error: $error, customConfig: $customConfig)';
}


}

/// @nodoc
abstract mixin class _$ProviderConnectionDtoCopyWith<$Res> implements $ProviderConnectionDtoCopyWith<$Res> {
  factory _$ProviderConnectionDtoCopyWith(_ProviderConnectionDto value, $Res Function(_ProviderConnectionDto) _then) = __$ProviderConnectionDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String definitionId, String displayName, ProviderConnectionStatus status, ProviderAuthKind authKind, ProviderCredentialOrigin credentialOrigin, bool isDefault, DateTime createdAt, DateTime updatedAt, String? defaultModelId, String? error, CustomProviderConfigDto? customConfig
});


@override $CustomProviderConfigDtoCopyWith<$Res>? get customConfig;

}
/// @nodoc
class __$ProviderConnectionDtoCopyWithImpl<$Res>
    implements _$ProviderConnectionDtoCopyWith<$Res> {
  __$ProviderConnectionDtoCopyWithImpl(this._self, this._then);

  final _ProviderConnectionDto _self;
  final $Res Function(_ProviderConnectionDto) _then;

/// Create a copy of ProviderConnectionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? definitionId = null,Object? displayName = null,Object? status = null,Object? authKind = null,Object? credentialOrigin = null,Object? isDefault = null,Object? createdAt = null,Object? updatedAt = null,Object? defaultModelId = freezed,Object? error = freezed,Object? customConfig = freezed,}) {
  return _then(_ProviderConnectionDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,definitionId: null == definitionId ? _self.definitionId : definitionId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProviderConnectionStatus,authKind: null == authKind ? _self.authKind : authKind // ignore: cast_nullable_to_non_nullable
as ProviderAuthKind,credentialOrigin: null == credentialOrigin ? _self.credentialOrigin : credentialOrigin // ignore: cast_nullable_to_non_nullable
as ProviderCredentialOrigin,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,defaultModelId: freezed == defaultModelId ? _self.defaultModelId : defaultModelId // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,customConfig: freezed == customConfig ? _self.customConfig : customConfig // ignore: cast_nullable_to_non_nullable
as CustomProviderConfigDto?,
  ));
}

/// Create a copy of ProviderConnectionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomProviderConfigDtoCopyWith<$Res>? get customConfig {
    if (_self.customConfig == null) {
    return null;
  }

  return $CustomProviderConfigDtoCopyWith<$Res>(_self.customConfig!, (value) {
    return _then(_self.copyWith(customConfig: value));
  });
}
}


/// @nodoc
mixin _$ProviderAuthAttemptDto {

 String get id; String get definitionId; String get methodId; ProviderAuthAttemptStatus get status; String? get authorizationUrl; String? get userCode; String? get instructions; DateTime? get expiresAt; String? get error;
/// Create a copy of ProviderAuthAttemptDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderAuthAttemptDtoCopyWith<ProviderAuthAttemptDto> get copyWith => _$ProviderAuthAttemptDtoCopyWithImpl<ProviderAuthAttemptDto>(this as ProviderAuthAttemptDto, _$identity);

  /// Serializes this ProviderAuthAttemptDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderAuthAttemptDto&&(identical(other.id, id) || other.id == id)&&(identical(other.definitionId, definitionId) || other.definitionId == definitionId)&&(identical(other.methodId, methodId) || other.methodId == methodId)&&(identical(other.status, status) || other.status == status)&&(identical(other.authorizationUrl, authorizationUrl) || other.authorizationUrl == authorizationUrl)&&(identical(other.userCode, userCode) || other.userCode == userCode)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,definitionId,methodId,status,authorizationUrl,userCode,instructions,expiresAt,error);

@override
String toString() {
  return 'ProviderAuthAttemptDto(id: $id, definitionId: $definitionId, methodId: $methodId, status: $status, authorizationUrl: $authorizationUrl, userCode: $userCode, instructions: $instructions, expiresAt: $expiresAt, error: $error)';
}


}

/// @nodoc
abstract mixin class $ProviderAuthAttemptDtoCopyWith<$Res>  {
  factory $ProviderAuthAttemptDtoCopyWith(ProviderAuthAttemptDto value, $Res Function(ProviderAuthAttemptDto) _then) = _$ProviderAuthAttemptDtoCopyWithImpl;
@useResult
$Res call({
 String id, String definitionId, String methodId, ProviderAuthAttemptStatus status, String? authorizationUrl, String? userCode, String? instructions, DateTime? expiresAt, String? error
});




}
/// @nodoc
class _$ProviderAuthAttemptDtoCopyWithImpl<$Res>
    implements $ProviderAuthAttemptDtoCopyWith<$Res> {
  _$ProviderAuthAttemptDtoCopyWithImpl(this._self, this._then);

  final ProviderAuthAttemptDto _self;
  final $Res Function(ProviderAuthAttemptDto) _then;

/// Create a copy of ProviderAuthAttemptDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? definitionId = null,Object? methodId = null,Object? status = null,Object? authorizationUrl = freezed,Object? userCode = freezed,Object? instructions = freezed,Object? expiresAt = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,definitionId: null == definitionId ? _self.definitionId : definitionId // ignore: cast_nullable_to_non_nullable
as String,methodId: null == methodId ? _self.methodId : methodId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProviderAuthAttemptStatus,authorizationUrl: freezed == authorizationUrl ? _self.authorizationUrl : authorizationUrl // ignore: cast_nullable_to_non_nullable
as String?,userCode: freezed == userCode ? _self.userCode : userCode // ignore: cast_nullable_to_non_nullable
as String?,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderAuthAttemptDto].
extension ProviderAuthAttemptDtoPatterns on ProviderAuthAttemptDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderAuthAttemptDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderAuthAttemptDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderAuthAttemptDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderAuthAttemptDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderAuthAttemptDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderAuthAttemptDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String definitionId,  String methodId,  ProviderAuthAttemptStatus status,  String? authorizationUrl,  String? userCode,  String? instructions,  DateTime? expiresAt,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderAuthAttemptDto() when $default != null:
return $default(_that.id,_that.definitionId,_that.methodId,_that.status,_that.authorizationUrl,_that.userCode,_that.instructions,_that.expiresAt,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String definitionId,  String methodId,  ProviderAuthAttemptStatus status,  String? authorizationUrl,  String? userCode,  String? instructions,  DateTime? expiresAt,  String? error)  $default,) {final _that = this;
switch (_that) {
case _ProviderAuthAttemptDto():
return $default(_that.id,_that.definitionId,_that.methodId,_that.status,_that.authorizationUrl,_that.userCode,_that.instructions,_that.expiresAt,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String definitionId,  String methodId,  ProviderAuthAttemptStatus status,  String? authorizationUrl,  String? userCode,  String? instructions,  DateTime? expiresAt,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _ProviderAuthAttemptDto() when $default != null:
return $default(_that.id,_that.definitionId,_that.methodId,_that.status,_that.authorizationUrl,_that.userCode,_that.instructions,_that.expiresAt,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderAuthAttemptDto implements ProviderAuthAttemptDto {
  const _ProviderAuthAttemptDto({required this.id, required this.definitionId, required this.methodId, required this.status, this.authorizationUrl, this.userCode, this.instructions, this.expiresAt, this.error});
  factory _ProviderAuthAttemptDto.fromJson(Map<String, dynamic> json) => _$ProviderAuthAttemptDtoFromJson(json);

@override final  String id;
@override final  String definitionId;
@override final  String methodId;
@override final  ProviderAuthAttemptStatus status;
@override final  String? authorizationUrl;
@override final  String? userCode;
@override final  String? instructions;
@override final  DateTime? expiresAt;
@override final  String? error;

/// Create a copy of ProviderAuthAttemptDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderAuthAttemptDtoCopyWith<_ProviderAuthAttemptDto> get copyWith => __$ProviderAuthAttemptDtoCopyWithImpl<_ProviderAuthAttemptDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderAuthAttemptDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderAuthAttemptDto&&(identical(other.id, id) || other.id == id)&&(identical(other.definitionId, definitionId) || other.definitionId == definitionId)&&(identical(other.methodId, methodId) || other.methodId == methodId)&&(identical(other.status, status) || other.status == status)&&(identical(other.authorizationUrl, authorizationUrl) || other.authorizationUrl == authorizationUrl)&&(identical(other.userCode, userCode) || other.userCode == userCode)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,definitionId,methodId,status,authorizationUrl,userCode,instructions,expiresAt,error);

@override
String toString() {
  return 'ProviderAuthAttemptDto(id: $id, definitionId: $definitionId, methodId: $methodId, status: $status, authorizationUrl: $authorizationUrl, userCode: $userCode, instructions: $instructions, expiresAt: $expiresAt, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ProviderAuthAttemptDtoCopyWith<$Res> implements $ProviderAuthAttemptDtoCopyWith<$Res> {
  factory _$ProviderAuthAttemptDtoCopyWith(_ProviderAuthAttemptDto value, $Res Function(_ProviderAuthAttemptDto) _then) = __$ProviderAuthAttemptDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String definitionId, String methodId, ProviderAuthAttemptStatus status, String? authorizationUrl, String? userCode, String? instructions, DateTime? expiresAt, String? error
});




}
/// @nodoc
class __$ProviderAuthAttemptDtoCopyWithImpl<$Res>
    implements _$ProviderAuthAttemptDtoCopyWith<$Res> {
  __$ProviderAuthAttemptDtoCopyWithImpl(this._self, this._then);

  final _ProviderAuthAttemptDto _self;
  final $Res Function(_ProviderAuthAttemptDto) _then;

/// Create a copy of ProviderAuthAttemptDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? definitionId = null,Object? methodId = null,Object? status = null,Object? authorizationUrl = freezed,Object? userCode = freezed,Object? instructions = freezed,Object? expiresAt = freezed,Object? error = freezed,}) {
  return _then(_ProviderAuthAttemptDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,definitionId: null == definitionId ? _self.definitionId : definitionId // ignore: cast_nullable_to_non_nullable
as String,methodId: null == methodId ? _self.methodId : methodId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProviderAuthAttemptStatus,authorizationUrl: freezed == authorizationUrl ? _self.authorizationUrl : authorizationUrl // ignore: cast_nullable_to_non_nullable
as String?,userCode: freezed == userCode ? _self.userCode : userCode // ignore: cast_nullable_to_non_nullable
as String?,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ProviderModelDto {

 String get connectionId; String get id; String get label; ProviderModelSource get source; ModelCapabilitiesDto get capabilities; ModelPricingDto? get pricing; ModelLimitsDto? get limits; DiagnosticStatus get diagnosticStatus; DateTime? get verifiedAt; String? get diagnosticError;
/// Create a copy of ProviderModelDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderModelDtoCopyWith<ProviderModelDto> get copyWith => _$ProviderModelDtoCopyWithImpl<ProviderModelDto>(this as ProviderModelDto, _$identity);

  /// Serializes this ProviderModelDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderModelDto&&(identical(other.connectionId, connectionId) || other.connectionId == connectionId)&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.source, source) || other.source == source)&&(identical(other.capabilities, capabilities) || other.capabilities == capabilities)&&(identical(other.pricing, pricing) || other.pricing == pricing)&&(identical(other.limits, limits) || other.limits == limits)&&(identical(other.diagnosticStatus, diagnosticStatus) || other.diagnosticStatus == diagnosticStatus)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt)&&(identical(other.diagnosticError, diagnosticError) || other.diagnosticError == diagnosticError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connectionId,id,label,source,capabilities,pricing,limits,diagnosticStatus,verifiedAt,diagnosticError);

@override
String toString() {
  return 'ProviderModelDto(connectionId: $connectionId, id: $id, label: $label, source: $source, capabilities: $capabilities, pricing: $pricing, limits: $limits, diagnosticStatus: $diagnosticStatus, verifiedAt: $verifiedAt, diagnosticError: $diagnosticError)';
}


}

/// @nodoc
abstract mixin class $ProviderModelDtoCopyWith<$Res>  {
  factory $ProviderModelDtoCopyWith(ProviderModelDto value, $Res Function(ProviderModelDto) _then) = _$ProviderModelDtoCopyWithImpl;
@useResult
$Res call({
 String connectionId, String id, String label, ProviderModelSource source, ModelCapabilitiesDto capabilities, ModelPricingDto? pricing, ModelLimitsDto? limits, DiagnosticStatus diagnosticStatus, DateTime? verifiedAt, String? diagnosticError
});


$ModelCapabilitiesDtoCopyWith<$Res> get capabilities;$ModelPricingDtoCopyWith<$Res>? get pricing;$ModelLimitsDtoCopyWith<$Res>? get limits;

}
/// @nodoc
class _$ProviderModelDtoCopyWithImpl<$Res>
    implements $ProviderModelDtoCopyWith<$Res> {
  _$ProviderModelDtoCopyWithImpl(this._self, this._then);

  final ProviderModelDto _self;
  final $Res Function(ProviderModelDto) _then;

/// Create a copy of ProviderModelDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? connectionId = null,Object? id = null,Object? label = null,Object? source = null,Object? capabilities = null,Object? pricing = freezed,Object? limits = freezed,Object? diagnosticStatus = null,Object? verifiedAt = freezed,Object? diagnosticError = freezed,}) {
  return _then(_self.copyWith(
connectionId: null == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ProviderModelSource,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as ModelCapabilitiesDto,pricing: freezed == pricing ? _self.pricing : pricing // ignore: cast_nullable_to_non_nullable
as ModelPricingDto?,limits: freezed == limits ? _self.limits : limits // ignore: cast_nullable_to_non_nullable
as ModelLimitsDto?,diagnosticStatus: null == diagnosticStatus ? _self.diagnosticStatus : diagnosticStatus // ignore: cast_nullable_to_non_nullable
as DiagnosticStatus,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,diagnosticError: freezed == diagnosticError ? _self.diagnosticError : diagnosticError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ProviderModelDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModelCapabilitiesDtoCopyWith<$Res> get capabilities {
  
  return $ModelCapabilitiesDtoCopyWith<$Res>(_self.capabilities, (value) {
    return _then(_self.copyWith(capabilities: value));
  });
}/// Create a copy of ProviderModelDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModelPricingDtoCopyWith<$Res>? get pricing {
    if (_self.pricing == null) {
    return null;
  }

  return $ModelPricingDtoCopyWith<$Res>(_self.pricing!, (value) {
    return _then(_self.copyWith(pricing: value));
  });
}/// Create a copy of ProviderModelDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModelLimitsDtoCopyWith<$Res>? get limits {
    if (_self.limits == null) {
    return null;
  }

  return $ModelLimitsDtoCopyWith<$Res>(_self.limits!, (value) {
    return _then(_self.copyWith(limits: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProviderModelDto].
extension ProviderModelDtoPatterns on ProviderModelDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderModelDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderModelDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderModelDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderModelDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderModelDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderModelDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String connectionId,  String id,  String label,  ProviderModelSource source,  ModelCapabilitiesDto capabilities,  ModelPricingDto? pricing,  ModelLimitsDto? limits,  DiagnosticStatus diagnosticStatus,  DateTime? verifiedAt,  String? diagnosticError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderModelDto() when $default != null:
return $default(_that.connectionId,_that.id,_that.label,_that.source,_that.capabilities,_that.pricing,_that.limits,_that.diagnosticStatus,_that.verifiedAt,_that.diagnosticError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String connectionId,  String id,  String label,  ProviderModelSource source,  ModelCapabilitiesDto capabilities,  ModelPricingDto? pricing,  ModelLimitsDto? limits,  DiagnosticStatus diagnosticStatus,  DateTime? verifiedAt,  String? diagnosticError)  $default,) {final _that = this;
switch (_that) {
case _ProviderModelDto():
return $default(_that.connectionId,_that.id,_that.label,_that.source,_that.capabilities,_that.pricing,_that.limits,_that.diagnosticStatus,_that.verifiedAt,_that.diagnosticError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String connectionId,  String id,  String label,  ProviderModelSource source,  ModelCapabilitiesDto capabilities,  ModelPricingDto? pricing,  ModelLimitsDto? limits,  DiagnosticStatus diagnosticStatus,  DateTime? verifiedAt,  String? diagnosticError)?  $default,) {final _that = this;
switch (_that) {
case _ProviderModelDto() when $default != null:
return $default(_that.connectionId,_that.id,_that.label,_that.source,_that.capabilities,_that.pricing,_that.limits,_that.diagnosticStatus,_that.verifiedAt,_that.diagnosticError);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderModelDto implements ProviderModelDto {
  const _ProviderModelDto({required this.connectionId, required this.id, required this.label, required this.source, required this.capabilities, this.pricing, this.limits, this.diagnosticStatus = DiagnosticStatus.unknown, this.verifiedAt, this.diagnosticError});
  factory _ProviderModelDto.fromJson(Map<String, dynamic> json) => _$ProviderModelDtoFromJson(json);

@override final  String connectionId;
@override final  String id;
@override final  String label;
@override final  ProviderModelSource source;
@override final  ModelCapabilitiesDto capabilities;
@override final  ModelPricingDto? pricing;
@override final  ModelLimitsDto? limits;
@override@JsonKey() final  DiagnosticStatus diagnosticStatus;
@override final  DateTime? verifiedAt;
@override final  String? diagnosticError;

/// Create a copy of ProviderModelDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderModelDtoCopyWith<_ProviderModelDto> get copyWith => __$ProviderModelDtoCopyWithImpl<_ProviderModelDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderModelDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderModelDto&&(identical(other.connectionId, connectionId) || other.connectionId == connectionId)&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.source, source) || other.source == source)&&(identical(other.capabilities, capabilities) || other.capabilities == capabilities)&&(identical(other.pricing, pricing) || other.pricing == pricing)&&(identical(other.limits, limits) || other.limits == limits)&&(identical(other.diagnosticStatus, diagnosticStatus) || other.diagnosticStatus == diagnosticStatus)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt)&&(identical(other.diagnosticError, diagnosticError) || other.diagnosticError == diagnosticError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connectionId,id,label,source,capabilities,pricing,limits,diagnosticStatus,verifiedAt,diagnosticError);

@override
String toString() {
  return 'ProviderModelDto(connectionId: $connectionId, id: $id, label: $label, source: $source, capabilities: $capabilities, pricing: $pricing, limits: $limits, diagnosticStatus: $diagnosticStatus, verifiedAt: $verifiedAt, diagnosticError: $diagnosticError)';
}


}

/// @nodoc
abstract mixin class _$ProviderModelDtoCopyWith<$Res> implements $ProviderModelDtoCopyWith<$Res> {
  factory _$ProviderModelDtoCopyWith(_ProviderModelDto value, $Res Function(_ProviderModelDto) _then) = __$ProviderModelDtoCopyWithImpl;
@override @useResult
$Res call({
 String connectionId, String id, String label, ProviderModelSource source, ModelCapabilitiesDto capabilities, ModelPricingDto? pricing, ModelLimitsDto? limits, DiagnosticStatus diagnosticStatus, DateTime? verifiedAt, String? diagnosticError
});


@override $ModelCapabilitiesDtoCopyWith<$Res> get capabilities;@override $ModelPricingDtoCopyWith<$Res>? get pricing;@override $ModelLimitsDtoCopyWith<$Res>? get limits;

}
/// @nodoc
class __$ProviderModelDtoCopyWithImpl<$Res>
    implements _$ProviderModelDtoCopyWith<$Res> {
  __$ProviderModelDtoCopyWithImpl(this._self, this._then);

  final _ProviderModelDto _self;
  final $Res Function(_ProviderModelDto) _then;

/// Create a copy of ProviderModelDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? connectionId = null,Object? id = null,Object? label = null,Object? source = null,Object? capabilities = null,Object? pricing = freezed,Object? limits = freezed,Object? diagnosticStatus = null,Object? verifiedAt = freezed,Object? diagnosticError = freezed,}) {
  return _then(_ProviderModelDto(
connectionId: null == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ProviderModelSource,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as ModelCapabilitiesDto,pricing: freezed == pricing ? _self.pricing : pricing // ignore: cast_nullable_to_non_nullable
as ModelPricingDto?,limits: freezed == limits ? _self.limits : limits // ignore: cast_nullable_to_non_nullable
as ModelLimitsDto?,diagnosticStatus: null == diagnosticStatus ? _self.diagnosticStatus : diagnosticStatus // ignore: cast_nullable_to_non_nullable
as DiagnosticStatus,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,diagnosticError: freezed == diagnosticError ? _self.diagnosticError : diagnosticError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ProviderModelDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModelCapabilitiesDtoCopyWith<$Res> get capabilities {
  
  return $ModelCapabilitiesDtoCopyWith<$Res>(_self.capabilities, (value) {
    return _then(_self.copyWith(capabilities: value));
  });
}/// Create a copy of ProviderModelDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModelPricingDtoCopyWith<$Res>? get pricing {
    if (_self.pricing == null) {
    return null;
  }

  return $ModelPricingDtoCopyWith<$Res>(_self.pricing!, (value) {
    return _then(_self.copyWith(pricing: value));
  });
}/// Create a copy of ProviderModelDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModelLimitsDtoCopyWith<$Res>? get limits {
    if (_self.limits == null) {
    return null;
  }

  return $ModelLimitsDtoCopyWith<$Res>(_self.limits!, (value) {
    return _then(_self.copyWith(limits: value));
  });
}
}


/// @nodoc
mixin _$ProviderCatalogDto {

 List<ProviderDefinitionDto> get definitions; ProviderCatalogSource get source; DateTime get updatedAt;
/// Create a copy of ProviderCatalogDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderCatalogDtoCopyWith<ProviderCatalogDto> get copyWith => _$ProviderCatalogDtoCopyWithImpl<ProviderCatalogDto>(this as ProviderCatalogDto, _$identity);

  /// Serializes this ProviderCatalogDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderCatalogDto&&const DeepCollectionEquality().equals(other.definitions, definitions)&&(identical(other.source, source) || other.source == source)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(definitions),source,updatedAt);

@override
String toString() {
  return 'ProviderCatalogDto(definitions: $definitions, source: $source, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ProviderCatalogDtoCopyWith<$Res>  {
  factory $ProviderCatalogDtoCopyWith(ProviderCatalogDto value, $Res Function(ProviderCatalogDto) _then) = _$ProviderCatalogDtoCopyWithImpl;
@useResult
$Res call({
 List<ProviderDefinitionDto> definitions, ProviderCatalogSource source, DateTime updatedAt
});




}
/// @nodoc
class _$ProviderCatalogDtoCopyWithImpl<$Res>
    implements $ProviderCatalogDtoCopyWith<$Res> {
  _$ProviderCatalogDtoCopyWithImpl(this._self, this._then);

  final ProviderCatalogDto _self;
  final $Res Function(ProviderCatalogDto) _then;

/// Create a copy of ProviderCatalogDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? definitions = null,Object? source = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
definitions: null == definitions ? _self.definitions : definitions // ignore: cast_nullable_to_non_nullable
as List<ProviderDefinitionDto>,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ProviderCatalogSource,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderCatalogDto].
extension ProviderCatalogDtoPatterns on ProviderCatalogDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderCatalogDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderCatalogDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderCatalogDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderCatalogDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderCatalogDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderCatalogDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ProviderDefinitionDto> definitions,  ProviderCatalogSource source,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderCatalogDto() when $default != null:
return $default(_that.definitions,_that.source,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ProviderDefinitionDto> definitions,  ProviderCatalogSource source,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ProviderCatalogDto():
return $default(_that.definitions,_that.source,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ProviderDefinitionDto> definitions,  ProviderCatalogSource source,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ProviderCatalogDto() when $default != null:
return $default(_that.definitions,_that.source,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderCatalogDto implements ProviderCatalogDto {
  const _ProviderCatalogDto({required final  List<ProviderDefinitionDto> definitions, required this.source, required this.updatedAt}): _definitions = definitions;
  factory _ProviderCatalogDto.fromJson(Map<String, dynamic> json) => _$ProviderCatalogDtoFromJson(json);

 final  List<ProviderDefinitionDto> _definitions;
@override List<ProviderDefinitionDto> get definitions {
  if (_definitions is EqualUnmodifiableListView) return _definitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_definitions);
}

@override final  ProviderCatalogSource source;
@override final  DateTime updatedAt;

/// Create a copy of ProviderCatalogDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderCatalogDtoCopyWith<_ProviderCatalogDto> get copyWith => __$ProviderCatalogDtoCopyWithImpl<_ProviderCatalogDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderCatalogDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderCatalogDto&&const DeepCollectionEquality().equals(other._definitions, _definitions)&&(identical(other.source, source) || other.source == source)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_definitions),source,updatedAt);

@override
String toString() {
  return 'ProviderCatalogDto(definitions: $definitions, source: $source, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ProviderCatalogDtoCopyWith<$Res> implements $ProviderCatalogDtoCopyWith<$Res> {
  factory _$ProviderCatalogDtoCopyWith(_ProviderCatalogDto value, $Res Function(_ProviderCatalogDto) _then) = __$ProviderCatalogDtoCopyWithImpl;
@override @useResult
$Res call({
 List<ProviderDefinitionDto> definitions, ProviderCatalogSource source, DateTime updatedAt
});




}
/// @nodoc
class __$ProviderCatalogDtoCopyWithImpl<$Res>
    implements _$ProviderCatalogDtoCopyWith<$Res> {
  __$ProviderCatalogDtoCopyWithImpl(this._self, this._then);

  final _ProviderCatalogDto _self;
  final $Res Function(_ProviderCatalogDto) _then;

/// Create a copy of ProviderCatalogDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? definitions = null,Object? source = null,Object? updatedAt = null,}) {
  return _then(_ProviderCatalogDto(
definitions: null == definitions ? _self._definitions : definitions // ignore: cast_nullable_to_non_nullable
as List<ProviderDefinitionDto>,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ProviderCatalogSource,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$ProviderDiagnosticDto {

 String get connectionId; String get model; DiagnosticStatus get status; bool get endpointReachable; bool get streaming; bool get toolCalling; DateTime get checkedAt; String? get error;
/// Create a copy of ProviderDiagnosticDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderDiagnosticDtoCopyWith<ProviderDiagnosticDto> get copyWith => _$ProviderDiagnosticDtoCopyWithImpl<ProviderDiagnosticDto>(this as ProviderDiagnosticDto, _$identity);

  /// Serializes this ProviderDiagnosticDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderDiagnosticDto&&(identical(other.connectionId, connectionId) || other.connectionId == connectionId)&&(identical(other.model, model) || other.model == model)&&(identical(other.status, status) || other.status == status)&&(identical(other.endpointReachable, endpointReachable) || other.endpointReachable == endpointReachable)&&(identical(other.streaming, streaming) || other.streaming == streaming)&&(identical(other.toolCalling, toolCalling) || other.toolCalling == toolCalling)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connectionId,model,status,endpointReachable,streaming,toolCalling,checkedAt,error);

@override
String toString() {
  return 'ProviderDiagnosticDto(connectionId: $connectionId, model: $model, status: $status, endpointReachable: $endpointReachable, streaming: $streaming, toolCalling: $toolCalling, checkedAt: $checkedAt, error: $error)';
}


}

/// @nodoc
abstract mixin class $ProviderDiagnosticDtoCopyWith<$Res>  {
  factory $ProviderDiagnosticDtoCopyWith(ProviderDiagnosticDto value, $Res Function(ProviderDiagnosticDto) _then) = _$ProviderDiagnosticDtoCopyWithImpl;
@useResult
$Res call({
 String connectionId, String model, DiagnosticStatus status, bool endpointReachable, bool streaming, bool toolCalling, DateTime checkedAt, String? error
});




}
/// @nodoc
class _$ProviderDiagnosticDtoCopyWithImpl<$Res>
    implements $ProviderDiagnosticDtoCopyWith<$Res> {
  _$ProviderDiagnosticDtoCopyWithImpl(this._self, this._then);

  final ProviderDiagnosticDto _self;
  final $Res Function(ProviderDiagnosticDto) _then;

/// Create a copy of ProviderDiagnosticDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? connectionId = null,Object? model = null,Object? status = null,Object? endpointReachable = null,Object? streaming = null,Object? toolCalling = null,Object? checkedAt = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
connectionId: null == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DiagnosticStatus,endpointReachable: null == endpointReachable ? _self.endpointReachable : endpointReachable // ignore: cast_nullable_to_non_nullable
as bool,streaming: null == streaming ? _self.streaming : streaming // ignore: cast_nullable_to_non_nullable
as bool,toolCalling: null == toolCalling ? _self.toolCalling : toolCalling // ignore: cast_nullable_to_non_nullable
as bool,checkedAt: null == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as DateTime,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderDiagnosticDto].
extension ProviderDiagnosticDtoPatterns on ProviderDiagnosticDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderDiagnosticDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderDiagnosticDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderDiagnosticDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderDiagnosticDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderDiagnosticDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderDiagnosticDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String connectionId,  String model,  DiagnosticStatus status,  bool endpointReachable,  bool streaming,  bool toolCalling,  DateTime checkedAt,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderDiagnosticDto() when $default != null:
return $default(_that.connectionId,_that.model,_that.status,_that.endpointReachable,_that.streaming,_that.toolCalling,_that.checkedAt,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String connectionId,  String model,  DiagnosticStatus status,  bool endpointReachable,  bool streaming,  bool toolCalling,  DateTime checkedAt,  String? error)  $default,) {final _that = this;
switch (_that) {
case _ProviderDiagnosticDto():
return $default(_that.connectionId,_that.model,_that.status,_that.endpointReachable,_that.streaming,_that.toolCalling,_that.checkedAt,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String connectionId,  String model,  DiagnosticStatus status,  bool endpointReachable,  bool streaming,  bool toolCalling,  DateTime checkedAt,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _ProviderDiagnosticDto() when $default != null:
return $default(_that.connectionId,_that.model,_that.status,_that.endpointReachable,_that.streaming,_that.toolCalling,_that.checkedAt,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderDiagnosticDto implements ProviderDiagnosticDto {
  const _ProviderDiagnosticDto({required this.connectionId, required this.model, required this.status, required this.endpointReachable, required this.streaming, required this.toolCalling, required this.checkedAt, this.error});
  factory _ProviderDiagnosticDto.fromJson(Map<String, dynamic> json) => _$ProviderDiagnosticDtoFromJson(json);

@override final  String connectionId;
@override final  String model;
@override final  DiagnosticStatus status;
@override final  bool endpointReachable;
@override final  bool streaming;
@override final  bool toolCalling;
@override final  DateTime checkedAt;
@override final  String? error;

/// Create a copy of ProviderDiagnosticDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderDiagnosticDtoCopyWith<_ProviderDiagnosticDto> get copyWith => __$ProviderDiagnosticDtoCopyWithImpl<_ProviderDiagnosticDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderDiagnosticDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderDiagnosticDto&&(identical(other.connectionId, connectionId) || other.connectionId == connectionId)&&(identical(other.model, model) || other.model == model)&&(identical(other.status, status) || other.status == status)&&(identical(other.endpointReachable, endpointReachable) || other.endpointReachable == endpointReachable)&&(identical(other.streaming, streaming) || other.streaming == streaming)&&(identical(other.toolCalling, toolCalling) || other.toolCalling == toolCalling)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connectionId,model,status,endpointReachable,streaming,toolCalling,checkedAt,error);

@override
String toString() {
  return 'ProviderDiagnosticDto(connectionId: $connectionId, model: $model, status: $status, endpointReachable: $endpointReachable, streaming: $streaming, toolCalling: $toolCalling, checkedAt: $checkedAt, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ProviderDiagnosticDtoCopyWith<$Res> implements $ProviderDiagnosticDtoCopyWith<$Res> {
  factory _$ProviderDiagnosticDtoCopyWith(_ProviderDiagnosticDto value, $Res Function(_ProviderDiagnosticDto) _then) = __$ProviderDiagnosticDtoCopyWithImpl;
@override @useResult
$Res call({
 String connectionId, String model, DiagnosticStatus status, bool endpointReachable, bool streaming, bool toolCalling, DateTime checkedAt, String? error
});




}
/// @nodoc
class __$ProviderDiagnosticDtoCopyWithImpl<$Res>
    implements _$ProviderDiagnosticDtoCopyWith<$Res> {
  __$ProviderDiagnosticDtoCopyWithImpl(this._self, this._then);

  final _ProviderDiagnosticDto _self;
  final $Res Function(_ProviderDiagnosticDto) _then;

/// Create a copy of ProviderDiagnosticDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? connectionId = null,Object? model = null,Object? status = null,Object? endpointReachable = null,Object? streaming = null,Object? toolCalling = null,Object? checkedAt = null,Object? error = freezed,}) {
  return _then(_ProviderDiagnosticDto(
connectionId: null == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DiagnosticStatus,endpointReachable: null == endpointReachable ? _self.endpointReachable : endpointReachable // ignore: cast_nullable_to_non_nullable
as bool,streaming: null == streaming ? _self.streaming : streaming // ignore: cast_nullable_to_non_nullable
as bool,toolCalling: null == toolCalling ? _self.toolCalling : toolCalling // ignore: cast_nullable_to_non_nullable
as bool,checkedAt: null == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as DateTime,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TimelineEventDto {

 String get agentId; int get sequence; String get type; Map<String, dynamic> get data; DateTime get createdAt; String? get turnId;
/// Create a copy of TimelineEventDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimelineEventDtoCopyWith<TimelineEventDto> get copyWith => _$TimelineEventDtoCopyWithImpl<TimelineEventDto>(this as TimelineEventDto, _$identity);

  /// Serializes this TimelineEventDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimelineEventDto&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.sequence, sequence) || other.sequence == sequence)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.turnId, turnId) || other.turnId == turnId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,agentId,sequence,type,const DeepCollectionEquality().hash(data),createdAt,turnId);

@override
String toString() {
  return 'TimelineEventDto(agentId: $agentId, sequence: $sequence, type: $type, data: $data, createdAt: $createdAt, turnId: $turnId)';
}


}

/// @nodoc
abstract mixin class $TimelineEventDtoCopyWith<$Res>  {
  factory $TimelineEventDtoCopyWith(TimelineEventDto value, $Res Function(TimelineEventDto) _then) = _$TimelineEventDtoCopyWithImpl;
@useResult
$Res call({
 String agentId, int sequence, String type, Map<String, dynamic> data, DateTime createdAt, String? turnId
});




}
/// @nodoc
class _$TimelineEventDtoCopyWithImpl<$Res>
    implements $TimelineEventDtoCopyWith<$Res> {
  _$TimelineEventDtoCopyWithImpl(this._self, this._then);

  final TimelineEventDto _self;
  final $Res Function(TimelineEventDto) _then;

/// Create a copy of TimelineEventDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? agentId = null,Object? sequence = null,Object? type = null,Object? data = null,Object? createdAt = null,Object? turnId = freezed,}) {
  return _then(_self.copyWith(
agentId: null == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,turnId: freezed == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TimelineEventDto].
extension TimelineEventDtoPatterns on TimelineEventDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimelineEventDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimelineEventDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimelineEventDto value)  $default,){
final _that = this;
switch (_that) {
case _TimelineEventDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimelineEventDto value)?  $default,){
final _that = this;
switch (_that) {
case _TimelineEventDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String agentId,  int sequence,  String type,  Map<String, dynamic> data,  DateTime createdAt,  String? turnId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimelineEventDto() when $default != null:
return $default(_that.agentId,_that.sequence,_that.type,_that.data,_that.createdAt,_that.turnId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String agentId,  int sequence,  String type,  Map<String, dynamic> data,  DateTime createdAt,  String? turnId)  $default,) {final _that = this;
switch (_that) {
case _TimelineEventDto():
return $default(_that.agentId,_that.sequence,_that.type,_that.data,_that.createdAt,_that.turnId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String agentId,  int sequence,  String type,  Map<String, dynamic> data,  DateTime createdAt,  String? turnId)?  $default,) {final _that = this;
switch (_that) {
case _TimelineEventDto() when $default != null:
return $default(_that.agentId,_that.sequence,_that.type,_that.data,_that.createdAt,_that.turnId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TimelineEventDto implements TimelineEventDto {
  const _TimelineEventDto({required this.agentId, required this.sequence, required this.type, required final  Map<String, dynamic> data, required this.createdAt, this.turnId}): _data = data;
  factory _TimelineEventDto.fromJson(Map<String, dynamic> json) => _$TimelineEventDtoFromJson(json);

@override final  String agentId;
@override final  int sequence;
@override final  String type;
 final  Map<String, dynamic> _data;
@override Map<String, dynamic> get data {
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_data);
}

@override final  DateTime createdAt;
@override final  String? turnId;

/// Create a copy of TimelineEventDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimelineEventDtoCopyWith<_TimelineEventDto> get copyWith => __$TimelineEventDtoCopyWithImpl<_TimelineEventDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TimelineEventDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimelineEventDto&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.sequence, sequence) || other.sequence == sequence)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._data, _data)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.turnId, turnId) || other.turnId == turnId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,agentId,sequence,type,const DeepCollectionEquality().hash(_data),createdAt,turnId);

@override
String toString() {
  return 'TimelineEventDto(agentId: $agentId, sequence: $sequence, type: $type, data: $data, createdAt: $createdAt, turnId: $turnId)';
}


}

/// @nodoc
abstract mixin class _$TimelineEventDtoCopyWith<$Res> implements $TimelineEventDtoCopyWith<$Res> {
  factory _$TimelineEventDtoCopyWith(_TimelineEventDto value, $Res Function(_TimelineEventDto) _then) = __$TimelineEventDtoCopyWithImpl;
@override @useResult
$Res call({
 String agentId, int sequence, String type, Map<String, dynamic> data, DateTime createdAt, String? turnId
});




}
/// @nodoc
class __$TimelineEventDtoCopyWithImpl<$Res>
    implements _$TimelineEventDtoCopyWith<$Res> {
  __$TimelineEventDtoCopyWithImpl(this._self, this._then);

  final _TimelineEventDto _self;
  final $Res Function(_TimelineEventDto) _then;

/// Create a copy of TimelineEventDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? agentId = null,Object? sequence = null,Object? type = null,Object? data = null,Object? createdAt = null,Object? turnId = freezed,}) {
  return _then(_TimelineEventDto(
agentId: null == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,turnId: freezed == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ApprovalRequestDto {

 String get id; String get agentId; String get turnId; String get toolCallId; String get toolName; ToolRisk get risk; Map<String, dynamic> get arguments; ApprovalStatus get status; DateTime get createdAt; String? get preview;
/// Create a copy of ApprovalRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApprovalRequestDtoCopyWith<ApprovalRequestDto> get copyWith => _$ApprovalRequestDtoCopyWithImpl<ApprovalRequestDto>(this as ApprovalRequestDto, _$identity);

  /// Serializes this ApprovalRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApprovalRequestDto&&(identical(other.id, id) || other.id == id)&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.risk, risk) || other.risk == risk)&&const DeepCollectionEquality().equals(other.arguments, arguments)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.preview, preview) || other.preview == preview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,agentId,turnId,toolCallId,toolName,risk,const DeepCollectionEquality().hash(arguments),status,createdAt,preview);

@override
String toString() {
  return 'ApprovalRequestDto(id: $id, agentId: $agentId, turnId: $turnId, toolCallId: $toolCallId, toolName: $toolName, risk: $risk, arguments: $arguments, status: $status, createdAt: $createdAt, preview: $preview)';
}


}

/// @nodoc
abstract mixin class $ApprovalRequestDtoCopyWith<$Res>  {
  factory $ApprovalRequestDtoCopyWith(ApprovalRequestDto value, $Res Function(ApprovalRequestDto) _then) = _$ApprovalRequestDtoCopyWithImpl;
@useResult
$Res call({
 String id, String agentId, String turnId, String toolCallId, String toolName, ToolRisk risk, Map<String, dynamic> arguments, ApprovalStatus status, DateTime createdAt, String? preview
});




}
/// @nodoc
class _$ApprovalRequestDtoCopyWithImpl<$Res>
    implements $ApprovalRequestDtoCopyWith<$Res> {
  _$ApprovalRequestDtoCopyWithImpl(this._self, this._then);

  final ApprovalRequestDto _self;
  final $Res Function(ApprovalRequestDto) _then;

/// Create a copy of ApprovalRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? agentId = null,Object? turnId = null,Object? toolCallId = null,Object? toolName = null,Object? risk = null,Object? arguments = null,Object? status = null,Object? createdAt = null,Object? preview = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,agentId: null == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String,turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,risk: null == risk ? _self.risk : risk // ignore: cast_nullable_to_non_nullable
as ToolRisk,arguments: null == arguments ? _self.arguments : arguments // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ApprovalStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,preview: freezed == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ApprovalRequestDto].
extension ApprovalRequestDtoPatterns on ApprovalRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApprovalRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApprovalRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApprovalRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _ApprovalRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApprovalRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _ApprovalRequestDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String agentId,  String turnId,  String toolCallId,  String toolName,  ToolRisk risk,  Map<String, dynamic> arguments,  ApprovalStatus status,  DateTime createdAt,  String? preview)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApprovalRequestDto() when $default != null:
return $default(_that.id,_that.agentId,_that.turnId,_that.toolCallId,_that.toolName,_that.risk,_that.arguments,_that.status,_that.createdAt,_that.preview);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String agentId,  String turnId,  String toolCallId,  String toolName,  ToolRisk risk,  Map<String, dynamic> arguments,  ApprovalStatus status,  DateTime createdAt,  String? preview)  $default,) {final _that = this;
switch (_that) {
case _ApprovalRequestDto():
return $default(_that.id,_that.agentId,_that.turnId,_that.toolCallId,_that.toolName,_that.risk,_that.arguments,_that.status,_that.createdAt,_that.preview);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String agentId,  String turnId,  String toolCallId,  String toolName,  ToolRisk risk,  Map<String, dynamic> arguments,  ApprovalStatus status,  DateTime createdAt,  String? preview)?  $default,) {final _that = this;
switch (_that) {
case _ApprovalRequestDto() when $default != null:
return $default(_that.id,_that.agentId,_that.turnId,_that.toolCallId,_that.toolName,_that.risk,_that.arguments,_that.status,_that.createdAt,_that.preview);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApprovalRequestDto implements ApprovalRequestDto {
  const _ApprovalRequestDto({required this.id, required this.agentId, required this.turnId, required this.toolCallId, required this.toolName, required this.risk, required final  Map<String, dynamic> arguments, required this.status, required this.createdAt, this.preview}): _arguments = arguments;
  factory _ApprovalRequestDto.fromJson(Map<String, dynamic> json) => _$ApprovalRequestDtoFromJson(json);

@override final  String id;
@override final  String agentId;
@override final  String turnId;
@override final  String toolCallId;
@override final  String toolName;
@override final  ToolRisk risk;
 final  Map<String, dynamic> _arguments;
@override Map<String, dynamic> get arguments {
  if (_arguments is EqualUnmodifiableMapView) return _arguments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_arguments);
}

@override final  ApprovalStatus status;
@override final  DateTime createdAt;
@override final  String? preview;

/// Create a copy of ApprovalRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApprovalRequestDtoCopyWith<_ApprovalRequestDto> get copyWith => __$ApprovalRequestDtoCopyWithImpl<_ApprovalRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApprovalRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApprovalRequestDto&&(identical(other.id, id) || other.id == id)&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.risk, risk) || other.risk == risk)&&const DeepCollectionEquality().equals(other._arguments, _arguments)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.preview, preview) || other.preview == preview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,agentId,turnId,toolCallId,toolName,risk,const DeepCollectionEquality().hash(_arguments),status,createdAt,preview);

@override
String toString() {
  return 'ApprovalRequestDto(id: $id, agentId: $agentId, turnId: $turnId, toolCallId: $toolCallId, toolName: $toolName, risk: $risk, arguments: $arguments, status: $status, createdAt: $createdAt, preview: $preview)';
}


}

/// @nodoc
abstract mixin class _$ApprovalRequestDtoCopyWith<$Res> implements $ApprovalRequestDtoCopyWith<$Res> {
  factory _$ApprovalRequestDtoCopyWith(_ApprovalRequestDto value, $Res Function(_ApprovalRequestDto) _then) = __$ApprovalRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String agentId, String turnId, String toolCallId, String toolName, ToolRisk risk, Map<String, dynamic> arguments, ApprovalStatus status, DateTime createdAt, String? preview
});




}
/// @nodoc
class __$ApprovalRequestDtoCopyWithImpl<$Res>
    implements _$ApprovalRequestDtoCopyWith<$Res> {
  __$ApprovalRequestDtoCopyWithImpl(this._self, this._then);

  final _ApprovalRequestDto _self;
  final $Res Function(_ApprovalRequestDto) _then;

/// Create a copy of ApprovalRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? agentId = null,Object? turnId = null,Object? toolCallId = null,Object? toolName = null,Object? risk = null,Object? arguments = null,Object? status = null,Object? createdAt = null,Object? preview = freezed,}) {
  return _then(_ApprovalRequestDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,agentId: null == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String,turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,risk: null == risk ? _self.risk : risk // ignore: cast_nullable_to_non_nullable
as ToolRisk,arguments: null == arguments ? _self._arguments : arguments // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ApprovalStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,preview: freezed == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ServerInfoDto {

 String get serverId; String get version; int get protocolVersion; Map<String, bool> get features;
/// Create a copy of ServerInfoDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerInfoDtoCopyWith<ServerInfoDto> get copyWith => _$ServerInfoDtoCopyWithImpl<ServerInfoDto>(this as ServerInfoDto, _$identity);

  /// Serializes this ServerInfoDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerInfoDto&&(identical(other.serverId, serverId) || other.serverId == serverId)&&(identical(other.version, version) || other.version == version)&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&const DeepCollectionEquality().equals(other.features, features));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverId,version,protocolVersion,const DeepCollectionEquality().hash(features));

@override
String toString() {
  return 'ServerInfoDto(serverId: $serverId, version: $version, protocolVersion: $protocolVersion, features: $features)';
}


}

/// @nodoc
abstract mixin class $ServerInfoDtoCopyWith<$Res>  {
  factory $ServerInfoDtoCopyWith(ServerInfoDto value, $Res Function(ServerInfoDto) _then) = _$ServerInfoDtoCopyWithImpl;
@useResult
$Res call({
 String serverId, String version, int protocolVersion, Map<String, bool> features
});




}
/// @nodoc
class _$ServerInfoDtoCopyWithImpl<$Res>
    implements $ServerInfoDtoCopyWith<$Res> {
  _$ServerInfoDtoCopyWithImpl(this._self, this._then);

  final ServerInfoDto _self;
  final $Res Function(ServerInfoDto) _then;

/// Create a copy of ServerInfoDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serverId = null,Object? version = null,Object? protocolVersion = null,Object? features = null,}) {
  return _then(_self.copyWith(
serverId: null == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,protocolVersion: null == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as int,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}

}


/// Adds pattern-matching-related methods to [ServerInfoDto].
extension ServerInfoDtoPatterns on ServerInfoDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServerInfoDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServerInfoDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServerInfoDto value)  $default,){
final _that = this;
switch (_that) {
case _ServerInfoDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServerInfoDto value)?  $default,){
final _that = this;
switch (_that) {
case _ServerInfoDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String serverId,  String version,  int protocolVersion,  Map<String, bool> features)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServerInfoDto() when $default != null:
return $default(_that.serverId,_that.version,_that.protocolVersion,_that.features);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String serverId,  String version,  int protocolVersion,  Map<String, bool> features)  $default,) {final _that = this;
switch (_that) {
case _ServerInfoDto():
return $default(_that.serverId,_that.version,_that.protocolVersion,_that.features);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String serverId,  String version,  int protocolVersion,  Map<String, bool> features)?  $default,) {final _that = this;
switch (_that) {
case _ServerInfoDto() when $default != null:
return $default(_that.serverId,_that.version,_that.protocolVersion,_that.features);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServerInfoDto implements ServerInfoDto {
  const _ServerInfoDto({required this.serverId, required this.version, required this.protocolVersion, required final  Map<String, bool> features}): _features = features;
  factory _ServerInfoDto.fromJson(Map<String, dynamic> json) => _$ServerInfoDtoFromJson(json);

@override final  String serverId;
@override final  String version;
@override final  int protocolVersion;
 final  Map<String, bool> _features;
@override Map<String, bool> get features {
  if (_features is EqualUnmodifiableMapView) return _features;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_features);
}


/// Create a copy of ServerInfoDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServerInfoDtoCopyWith<_ServerInfoDto> get copyWith => __$ServerInfoDtoCopyWithImpl<_ServerInfoDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServerInfoDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServerInfoDto&&(identical(other.serverId, serverId) || other.serverId == serverId)&&(identical(other.version, version) || other.version == version)&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&const DeepCollectionEquality().equals(other._features, _features));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverId,version,protocolVersion,const DeepCollectionEquality().hash(_features));

@override
String toString() {
  return 'ServerInfoDto(serverId: $serverId, version: $version, protocolVersion: $protocolVersion, features: $features)';
}


}

/// @nodoc
abstract mixin class _$ServerInfoDtoCopyWith<$Res> implements $ServerInfoDtoCopyWith<$Res> {
  factory _$ServerInfoDtoCopyWith(_ServerInfoDto value, $Res Function(_ServerInfoDto) _then) = __$ServerInfoDtoCopyWithImpl;
@override @useResult
$Res call({
 String serverId, String version, int protocolVersion, Map<String, bool> features
});




}
/// @nodoc
class __$ServerInfoDtoCopyWithImpl<$Res>
    implements _$ServerInfoDtoCopyWith<$Res> {
  __$ServerInfoDtoCopyWithImpl(this._self, this._then);

  final _ServerInfoDto _self;
  final $Res Function(_ServerInfoDto) _then;

/// Create a copy of ServerInfoDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serverId = null,Object? version = null,Object? protocolVersion = null,Object? features = null,}) {
  return _then(_ServerInfoDto(
serverId: null == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,protocolVersion: null == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as int,features: null == features ? _self._features : features // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}


}


/// @nodoc
mixin _$RpcErrorDto {

 String get code; String get message; bool get retryable; Map<String, dynamic>? get details;
/// Create a copy of RpcErrorDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RpcErrorDtoCopyWith<RpcErrorDto> get copyWith => _$RpcErrorDtoCopyWithImpl<RpcErrorDto>(this as RpcErrorDto, _$identity);

  /// Serializes this RpcErrorDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RpcErrorDto&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.retryable, retryable) || other.retryable == retryable)&&const DeepCollectionEquality().equals(other.details, details));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,retryable,const DeepCollectionEquality().hash(details));

@override
String toString() {
  return 'RpcErrorDto(code: $code, message: $message, retryable: $retryable, details: $details)';
}


}

/// @nodoc
abstract mixin class $RpcErrorDtoCopyWith<$Res>  {
  factory $RpcErrorDtoCopyWith(RpcErrorDto value, $Res Function(RpcErrorDto) _then) = _$RpcErrorDtoCopyWithImpl;
@useResult
$Res call({
 String code, String message, bool retryable, Map<String, dynamic>? details
});




}
/// @nodoc
class _$RpcErrorDtoCopyWithImpl<$Res>
    implements $RpcErrorDtoCopyWith<$Res> {
  _$RpcErrorDtoCopyWithImpl(this._self, this._then);

  final RpcErrorDto _self;
  final $Res Function(RpcErrorDto) _then;

/// Create a copy of RpcErrorDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? retryable = null,Object? details = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,retryable: null == retryable ? _self.retryable : retryable // ignore: cast_nullable_to_non_nullable
as bool,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [RpcErrorDto].
extension RpcErrorDtoPatterns on RpcErrorDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RpcErrorDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RpcErrorDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RpcErrorDto value)  $default,){
final _that = this;
switch (_that) {
case _RpcErrorDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RpcErrorDto value)?  $default,){
final _that = this;
switch (_that) {
case _RpcErrorDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String message,  bool retryable,  Map<String, dynamic>? details)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RpcErrorDto() when $default != null:
return $default(_that.code,_that.message,_that.retryable,_that.details);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String message,  bool retryable,  Map<String, dynamic>? details)  $default,) {final _that = this;
switch (_that) {
case _RpcErrorDto():
return $default(_that.code,_that.message,_that.retryable,_that.details);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String message,  bool retryable,  Map<String, dynamic>? details)?  $default,) {final _that = this;
switch (_that) {
case _RpcErrorDto() when $default != null:
return $default(_that.code,_that.message,_that.retryable,_that.details);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RpcErrorDto implements RpcErrorDto {
  const _RpcErrorDto({required this.code, required this.message, required this.retryable, final  Map<String, dynamic>? details}): _details = details;
  factory _RpcErrorDto.fromJson(Map<String, dynamic> json) => _$RpcErrorDtoFromJson(json);

@override final  String code;
@override final  String message;
@override final  bool retryable;
 final  Map<String, dynamic>? _details;
@override Map<String, dynamic>? get details {
  final value = _details;
  if (value == null) return null;
  if (_details is EqualUnmodifiableMapView) return _details;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of RpcErrorDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RpcErrorDtoCopyWith<_RpcErrorDto> get copyWith => __$RpcErrorDtoCopyWithImpl<_RpcErrorDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RpcErrorDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RpcErrorDto&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.retryable, retryable) || other.retryable == retryable)&&const DeepCollectionEquality().equals(other._details, _details));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,retryable,const DeepCollectionEquality().hash(_details));

@override
String toString() {
  return 'RpcErrorDto(code: $code, message: $message, retryable: $retryable, details: $details)';
}


}

/// @nodoc
abstract mixin class _$RpcErrorDtoCopyWith<$Res> implements $RpcErrorDtoCopyWith<$Res> {
  factory _$RpcErrorDtoCopyWith(_RpcErrorDto value, $Res Function(_RpcErrorDto) _then) = __$RpcErrorDtoCopyWithImpl;
@override @useResult
$Res call({
 String code, String message, bool retryable, Map<String, dynamic>? details
});




}
/// @nodoc
class __$RpcErrorDtoCopyWithImpl<$Res>
    implements _$RpcErrorDtoCopyWith<$Res> {
  __$RpcErrorDtoCopyWithImpl(this._self, this._then);

  final _RpcErrorDto _self;
  final $Res Function(_RpcErrorDto) _then;

/// Create a copy of RpcErrorDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? retryable = null,Object? details = freezed,}) {
  return _then(_RpcErrorDto(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,retryable: null == retryable ? _self.retryable : retryable // ignore: cast_nullable_to_non_nullable
as bool,details: freezed == details ? _self._details : details // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
