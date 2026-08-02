// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rpc_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HelloParamsDto {

 String get clientId; String get clientKind; int get protocolVersion; Map<String, bool> get capabilities;
/// Create a copy of HelloParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HelloParamsDtoCopyWith<HelloParamsDto> get copyWith => _$HelloParamsDtoCopyWithImpl<HelloParamsDto>(this as HelloParamsDto, _$identity);

  /// Serializes this HelloParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HelloParamsDto&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.clientKind, clientKind) || other.clientKind == clientKind)&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&const DeepCollectionEquality().equals(other.capabilities, capabilities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientId,clientKind,protocolVersion,const DeepCollectionEquality().hash(capabilities));

@override
String toString() {
  return 'HelloParamsDto(clientId: $clientId, clientKind: $clientKind, protocolVersion: $protocolVersion, capabilities: $capabilities)';
}


}

/// @nodoc
abstract mixin class $HelloParamsDtoCopyWith<$Res>  {
  factory $HelloParamsDtoCopyWith(HelloParamsDto value, $Res Function(HelloParamsDto) _then) = _$HelloParamsDtoCopyWithImpl;
@useResult
$Res call({
 String clientId, String clientKind, int protocolVersion, Map<String, bool> capabilities
});




}
/// @nodoc
class _$HelloParamsDtoCopyWithImpl<$Res>
    implements $HelloParamsDtoCopyWith<$Res> {
  _$HelloParamsDtoCopyWithImpl(this._self, this._then);

  final HelloParamsDto _self;
  final $Res Function(HelloParamsDto) _then;

/// Create a copy of HelloParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientId = null,Object? clientKind = null,Object? protocolVersion = null,Object? capabilities = null,}) {
  return _then(_self.copyWith(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,clientKind: null == clientKind ? _self.clientKind : clientKind // ignore: cast_nullable_to_non_nullable
as String,protocolVersion: null == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as int,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}

}


/// Adds pattern-matching-related methods to [HelloParamsDto].
extension HelloParamsDtoPatterns on HelloParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HelloParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HelloParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HelloParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _HelloParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HelloParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _HelloParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientId,  String clientKind,  int protocolVersion,  Map<String, bool> capabilities)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HelloParamsDto() when $default != null:
return $default(_that.clientId,_that.clientKind,_that.protocolVersion,_that.capabilities);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientId,  String clientKind,  int protocolVersion,  Map<String, bool> capabilities)  $default,) {final _that = this;
switch (_that) {
case _HelloParamsDto():
return $default(_that.clientId,_that.clientKind,_that.protocolVersion,_that.capabilities);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientId,  String clientKind,  int protocolVersion,  Map<String, bool> capabilities)?  $default,) {final _that = this;
switch (_that) {
case _HelloParamsDto() when $default != null:
return $default(_that.clientId,_that.clientKind,_that.protocolVersion,_that.capabilities);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HelloParamsDto implements HelloParamsDto {
  const _HelloParamsDto({required this.clientId, required this.clientKind, required this.protocolVersion, required final  Map<String, bool> capabilities}): _capabilities = capabilities;
  factory _HelloParamsDto.fromJson(Map<String, dynamic> json) => _$HelloParamsDtoFromJson(json);

@override final  String clientId;
@override final  String clientKind;
@override final  int protocolVersion;
 final  Map<String, bool> _capabilities;
@override Map<String, bool> get capabilities {
  if (_capabilities is EqualUnmodifiableMapView) return _capabilities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_capabilities);
}


/// Create a copy of HelloParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HelloParamsDtoCopyWith<_HelloParamsDto> get copyWith => __$HelloParamsDtoCopyWithImpl<_HelloParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HelloParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HelloParamsDto&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.clientKind, clientKind) || other.clientKind == clientKind)&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&const DeepCollectionEquality().equals(other._capabilities, _capabilities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientId,clientKind,protocolVersion,const DeepCollectionEquality().hash(_capabilities));

@override
String toString() {
  return 'HelloParamsDto(clientId: $clientId, clientKind: $clientKind, protocolVersion: $protocolVersion, capabilities: $capabilities)';
}


}

/// @nodoc
abstract mixin class _$HelloParamsDtoCopyWith<$Res> implements $HelloParamsDtoCopyWith<$Res> {
  factory _$HelloParamsDtoCopyWith(_HelloParamsDto value, $Res Function(_HelloParamsDto) _then) = __$HelloParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String clientId, String clientKind, int protocolVersion, Map<String, bool> capabilities
});




}
/// @nodoc
class __$HelloParamsDtoCopyWithImpl<$Res>
    implements _$HelloParamsDtoCopyWith<$Res> {
  __$HelloParamsDtoCopyWithImpl(this._self, this._then);

  final _HelloParamsDto _self;
  final $Res Function(_HelloParamsDto) _then;

/// Create a copy of HelloParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientId = null,Object? clientKind = null,Object? protocolVersion = null,Object? capabilities = null,}) {
  return _then(_HelloParamsDto(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,clientKind: null == clientKind ? _self.clientKind : clientKind // ignore: cast_nullable_to_non_nullable
as String,protocolVersion: null == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as int,capabilities: null == capabilities ? _self._capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}


}


/// @nodoc
mixin _$WorkspaceRegisterParamsDto {

 String get id; String get rootPath; String get name;
/// Create a copy of WorkspaceRegisterParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceRegisterParamsDtoCopyWith<WorkspaceRegisterParamsDto> get copyWith => _$WorkspaceRegisterParamsDtoCopyWithImpl<WorkspaceRegisterParamsDto>(this as WorkspaceRegisterParamsDto, _$identity);

  /// Serializes this WorkspaceRegisterParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceRegisterParamsDto&&(identical(other.id, id) || other.id == id)&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,rootPath,name);

@override
String toString() {
  return 'WorkspaceRegisterParamsDto(id: $id, rootPath: $rootPath, name: $name)';
}


}

/// @nodoc
abstract mixin class $WorkspaceRegisterParamsDtoCopyWith<$Res>  {
  factory $WorkspaceRegisterParamsDtoCopyWith(WorkspaceRegisterParamsDto value, $Res Function(WorkspaceRegisterParamsDto) _then) = _$WorkspaceRegisterParamsDtoCopyWithImpl;
@useResult
$Res call({
 String id, String rootPath, String name
});




}
/// @nodoc
class _$WorkspaceRegisterParamsDtoCopyWithImpl<$Res>
    implements $WorkspaceRegisterParamsDtoCopyWith<$Res> {
  _$WorkspaceRegisterParamsDtoCopyWithImpl(this._self, this._then);

  final WorkspaceRegisterParamsDto _self;
  final $Res Function(WorkspaceRegisterParamsDto) _then;

/// Create a copy of WorkspaceRegisterParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? rootPath = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rootPath: null == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkspaceRegisterParamsDto].
extension WorkspaceRegisterParamsDtoPatterns on WorkspaceRegisterParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceRegisterParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceRegisterParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceRegisterParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceRegisterParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceRegisterParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceRegisterParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String rootPath,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceRegisterParamsDto() when $default != null:
return $default(_that.id,_that.rootPath,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String rootPath,  String name)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceRegisterParamsDto():
return $default(_that.id,_that.rootPath,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String rootPath,  String name)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceRegisterParamsDto() when $default != null:
return $default(_that.id,_that.rootPath,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkspaceRegisterParamsDto implements WorkspaceRegisterParamsDto {
  const _WorkspaceRegisterParamsDto({required this.id, required this.rootPath, required this.name});
  factory _WorkspaceRegisterParamsDto.fromJson(Map<String, dynamic> json) => _$WorkspaceRegisterParamsDtoFromJson(json);

@override final  String id;
@override final  String rootPath;
@override final  String name;

/// Create a copy of WorkspaceRegisterParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceRegisterParamsDtoCopyWith<_WorkspaceRegisterParamsDto> get copyWith => __$WorkspaceRegisterParamsDtoCopyWithImpl<_WorkspaceRegisterParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkspaceRegisterParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceRegisterParamsDto&&(identical(other.id, id) || other.id == id)&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,rootPath,name);

@override
String toString() {
  return 'WorkspaceRegisterParamsDto(id: $id, rootPath: $rootPath, name: $name)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceRegisterParamsDtoCopyWith<$Res> implements $WorkspaceRegisterParamsDtoCopyWith<$Res> {
  factory _$WorkspaceRegisterParamsDtoCopyWith(_WorkspaceRegisterParamsDto value, $Res Function(_WorkspaceRegisterParamsDto) _then) = __$WorkspaceRegisterParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String rootPath, String name
});




}
/// @nodoc
class __$WorkspaceRegisterParamsDtoCopyWithImpl<$Res>
    implements _$WorkspaceRegisterParamsDtoCopyWith<$Res> {
  __$WorkspaceRegisterParamsDtoCopyWithImpl(this._self, this._then);

  final _WorkspaceRegisterParamsDto _self;
  final $Res Function(_WorkspaceRegisterParamsDto) _then;

/// Create a copy of WorkspaceRegisterParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? rootPath = null,Object? name = null,}) {
  return _then(_WorkspaceRegisterParamsDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rootPath: null == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AgentListParamsDto {

 String? get workspaceId;
/// Create a copy of AgentListParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentListParamsDtoCopyWith<AgentListParamsDto> get copyWith => _$AgentListParamsDtoCopyWithImpl<AgentListParamsDto>(this as AgentListParamsDto, _$identity);

  /// Serializes this AgentListParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentListParamsDto&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workspaceId);

@override
String toString() {
  return 'AgentListParamsDto(workspaceId: $workspaceId)';
}


}

/// @nodoc
abstract mixin class $AgentListParamsDtoCopyWith<$Res>  {
  factory $AgentListParamsDtoCopyWith(AgentListParamsDto value, $Res Function(AgentListParamsDto) _then) = _$AgentListParamsDtoCopyWithImpl;
@useResult
$Res call({
 String? workspaceId
});




}
/// @nodoc
class _$AgentListParamsDtoCopyWithImpl<$Res>
    implements $AgentListParamsDtoCopyWith<$Res> {
  _$AgentListParamsDtoCopyWithImpl(this._self, this._then);

  final AgentListParamsDto _self;
  final $Res Function(AgentListParamsDto) _then;

/// Create a copy of AgentListParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workspaceId = freezed,}) {
  return _then(_self.copyWith(
workspaceId: freezed == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentListParamsDto].
extension AgentListParamsDtoPatterns on AgentListParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentListParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentListParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentListParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _AgentListParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentListParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _AgentListParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? workspaceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentListParamsDto() when $default != null:
return $default(_that.workspaceId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? workspaceId)  $default,) {final _that = this;
switch (_that) {
case _AgentListParamsDto():
return $default(_that.workspaceId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? workspaceId)?  $default,) {final _that = this;
switch (_that) {
case _AgentListParamsDto() when $default != null:
return $default(_that.workspaceId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentListParamsDto implements AgentListParamsDto {
  const _AgentListParamsDto({this.workspaceId});
  factory _AgentListParamsDto.fromJson(Map<String, dynamic> json) => _$AgentListParamsDtoFromJson(json);

@override final  String? workspaceId;

/// Create a copy of AgentListParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentListParamsDtoCopyWith<_AgentListParamsDto> get copyWith => __$AgentListParamsDtoCopyWithImpl<_AgentListParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentListParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentListParamsDto&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workspaceId);

@override
String toString() {
  return 'AgentListParamsDto(workspaceId: $workspaceId)';
}


}

/// @nodoc
abstract mixin class _$AgentListParamsDtoCopyWith<$Res> implements $AgentListParamsDtoCopyWith<$Res> {
  factory _$AgentListParamsDtoCopyWith(_AgentListParamsDto value, $Res Function(_AgentListParamsDto) _then) = __$AgentListParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String? workspaceId
});




}
/// @nodoc
class __$AgentListParamsDtoCopyWithImpl<$Res>
    implements _$AgentListParamsDtoCopyWith<$Res> {
  __$AgentListParamsDtoCopyWithImpl(this._self, this._then);

  final _AgentListParamsDto _self;
  final $Res Function(_AgentListParamsDto) _then;

/// Create a copy of AgentListParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workspaceId = freezed,}) {
  return _then(_AgentListParamsDto(
workspaceId: freezed == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AgentCreateParamsDto {

 String get id; String get workspaceId; String get title; String get providerId; String get model; String get reasoningEffort; PermissionMode get permissionMode;
/// Create a copy of AgentCreateParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentCreateParamsDtoCopyWith<AgentCreateParamsDto> get copyWith => _$AgentCreateParamsDtoCopyWithImpl<AgentCreateParamsDto>(this as AgentCreateParamsDto, _$identity);

  /// Serializes this AgentCreateParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentCreateParamsDto&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.title, title) || other.title == title)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.model, model) || other.model == model)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort)&&(identical(other.permissionMode, permissionMode) || other.permissionMode == permissionMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,title,providerId,model,reasoningEffort,permissionMode);

@override
String toString() {
  return 'AgentCreateParamsDto(id: $id, workspaceId: $workspaceId, title: $title, providerId: $providerId, model: $model, reasoningEffort: $reasoningEffort, permissionMode: $permissionMode)';
}


}

/// @nodoc
abstract mixin class $AgentCreateParamsDtoCopyWith<$Res>  {
  factory $AgentCreateParamsDtoCopyWith(AgentCreateParamsDto value, $Res Function(AgentCreateParamsDto) _then) = _$AgentCreateParamsDtoCopyWithImpl;
@useResult
$Res call({
 String id, String workspaceId, String title, String providerId, String model, String reasoningEffort, PermissionMode permissionMode
});




}
/// @nodoc
class _$AgentCreateParamsDtoCopyWithImpl<$Res>
    implements $AgentCreateParamsDtoCopyWith<$Res> {
  _$AgentCreateParamsDtoCopyWithImpl(this._self, this._then);

  final AgentCreateParamsDto _self;
  final $Res Function(AgentCreateParamsDto) _then;

/// Create a copy of AgentCreateParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workspaceId = null,Object? title = null,Object? providerId = null,Object? model = null,Object? reasoningEffort = null,Object? permissionMode = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,reasoningEffort: null == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as String,permissionMode: null == permissionMode ? _self.permissionMode : permissionMode // ignore: cast_nullable_to_non_nullable
as PermissionMode,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentCreateParamsDto].
extension AgentCreateParamsDtoPatterns on AgentCreateParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentCreateParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentCreateParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentCreateParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _AgentCreateParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentCreateParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _AgentCreateParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String title,  String providerId,  String model,  String reasoningEffort,  PermissionMode permissionMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentCreateParamsDto() when $default != null:
return $default(_that.id,_that.workspaceId,_that.title,_that.providerId,_that.model,_that.reasoningEffort,_that.permissionMode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String title,  String providerId,  String model,  String reasoningEffort,  PermissionMode permissionMode)  $default,) {final _that = this;
switch (_that) {
case _AgentCreateParamsDto():
return $default(_that.id,_that.workspaceId,_that.title,_that.providerId,_that.model,_that.reasoningEffort,_that.permissionMode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workspaceId,  String title,  String providerId,  String model,  String reasoningEffort,  PermissionMode permissionMode)?  $default,) {final _that = this;
switch (_that) {
case _AgentCreateParamsDto() when $default != null:
return $default(_that.id,_that.workspaceId,_that.title,_that.providerId,_that.model,_that.reasoningEffort,_that.permissionMode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentCreateParamsDto implements AgentCreateParamsDto {
  const _AgentCreateParamsDto({required this.id, required this.workspaceId, required this.title, required this.providerId, required this.model, required this.reasoningEffort, required this.permissionMode});
  factory _AgentCreateParamsDto.fromJson(Map<String, dynamic> json) => _$AgentCreateParamsDtoFromJson(json);

@override final  String id;
@override final  String workspaceId;
@override final  String title;
@override final  String providerId;
@override final  String model;
@override final  String reasoningEffort;
@override final  PermissionMode permissionMode;

/// Create a copy of AgentCreateParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentCreateParamsDtoCopyWith<_AgentCreateParamsDto> get copyWith => __$AgentCreateParamsDtoCopyWithImpl<_AgentCreateParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentCreateParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentCreateParamsDto&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.title, title) || other.title == title)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.model, model) || other.model == model)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort)&&(identical(other.permissionMode, permissionMode) || other.permissionMode == permissionMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,title,providerId,model,reasoningEffort,permissionMode);

@override
String toString() {
  return 'AgentCreateParamsDto(id: $id, workspaceId: $workspaceId, title: $title, providerId: $providerId, model: $model, reasoningEffort: $reasoningEffort, permissionMode: $permissionMode)';
}


}

/// @nodoc
abstract mixin class _$AgentCreateParamsDtoCopyWith<$Res> implements $AgentCreateParamsDtoCopyWith<$Res> {
  factory _$AgentCreateParamsDtoCopyWith(_AgentCreateParamsDto value, $Res Function(_AgentCreateParamsDto) _then) = __$AgentCreateParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String workspaceId, String title, String providerId, String model, String reasoningEffort, PermissionMode permissionMode
});




}
/// @nodoc
class __$AgentCreateParamsDtoCopyWithImpl<$Res>
    implements _$AgentCreateParamsDtoCopyWith<$Res> {
  __$AgentCreateParamsDtoCopyWithImpl(this._self, this._then);

  final _AgentCreateParamsDto _self;
  final $Res Function(_AgentCreateParamsDto) _then;

/// Create a copy of AgentCreateParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workspaceId = null,Object? title = null,Object? providerId = null,Object? model = null,Object? reasoningEffort = null,Object? permissionMode = null,}) {
  return _then(_AgentCreateParamsDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,reasoningEffort: null == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as String,permissionMode: null == permissionMode ? _self.permissionMode : permissionMode // ignore: cast_nullable_to_non_nullable
as PermissionMode,
  ));
}


}


/// @nodoc
mixin _$AgentConfigurationUpdateParamsDto {

 String get agentId; String get providerId; String get model; String get reasoningEffort;
/// Create a copy of AgentConfigurationUpdateParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentConfigurationUpdateParamsDtoCopyWith<AgentConfigurationUpdateParamsDto> get copyWith => _$AgentConfigurationUpdateParamsDtoCopyWithImpl<AgentConfigurationUpdateParamsDto>(this as AgentConfigurationUpdateParamsDto, _$identity);

  /// Serializes this AgentConfigurationUpdateParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentConfigurationUpdateParamsDto&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.model, model) || other.model == model)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,agentId,providerId,model,reasoningEffort);

@override
String toString() {
  return 'AgentConfigurationUpdateParamsDto(agentId: $agentId, providerId: $providerId, model: $model, reasoningEffort: $reasoningEffort)';
}


}

/// @nodoc
abstract mixin class $AgentConfigurationUpdateParamsDtoCopyWith<$Res>  {
  factory $AgentConfigurationUpdateParamsDtoCopyWith(AgentConfigurationUpdateParamsDto value, $Res Function(AgentConfigurationUpdateParamsDto) _then) = _$AgentConfigurationUpdateParamsDtoCopyWithImpl;
@useResult
$Res call({
 String agentId, String providerId, String model, String reasoningEffort
});




}
/// @nodoc
class _$AgentConfigurationUpdateParamsDtoCopyWithImpl<$Res>
    implements $AgentConfigurationUpdateParamsDtoCopyWith<$Res> {
  _$AgentConfigurationUpdateParamsDtoCopyWithImpl(this._self, this._then);

  final AgentConfigurationUpdateParamsDto _self;
  final $Res Function(AgentConfigurationUpdateParamsDto) _then;

/// Create a copy of AgentConfigurationUpdateParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? agentId = null,Object? providerId = null,Object? model = null,Object? reasoningEffort = null,}) {
  return _then(_self.copyWith(
agentId: null == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,reasoningEffort: null == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentConfigurationUpdateParamsDto].
extension AgentConfigurationUpdateParamsDtoPatterns on AgentConfigurationUpdateParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentConfigurationUpdateParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentConfigurationUpdateParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentConfigurationUpdateParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _AgentConfigurationUpdateParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentConfigurationUpdateParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _AgentConfigurationUpdateParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String agentId,  String providerId,  String model,  String reasoningEffort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentConfigurationUpdateParamsDto() when $default != null:
return $default(_that.agentId,_that.providerId,_that.model,_that.reasoningEffort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String agentId,  String providerId,  String model,  String reasoningEffort)  $default,) {final _that = this;
switch (_that) {
case _AgentConfigurationUpdateParamsDto():
return $default(_that.agentId,_that.providerId,_that.model,_that.reasoningEffort);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String agentId,  String providerId,  String model,  String reasoningEffort)?  $default,) {final _that = this;
switch (_that) {
case _AgentConfigurationUpdateParamsDto() when $default != null:
return $default(_that.agentId,_that.providerId,_that.model,_that.reasoningEffort);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentConfigurationUpdateParamsDto implements AgentConfigurationUpdateParamsDto {
  const _AgentConfigurationUpdateParamsDto({required this.agentId, required this.providerId, required this.model, required this.reasoningEffort});
  factory _AgentConfigurationUpdateParamsDto.fromJson(Map<String, dynamic> json) => _$AgentConfigurationUpdateParamsDtoFromJson(json);

@override final  String agentId;
@override final  String providerId;
@override final  String model;
@override final  String reasoningEffort;

/// Create a copy of AgentConfigurationUpdateParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentConfigurationUpdateParamsDtoCopyWith<_AgentConfigurationUpdateParamsDto> get copyWith => __$AgentConfigurationUpdateParamsDtoCopyWithImpl<_AgentConfigurationUpdateParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentConfigurationUpdateParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentConfigurationUpdateParamsDto&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.model, model) || other.model == model)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,agentId,providerId,model,reasoningEffort);

@override
String toString() {
  return 'AgentConfigurationUpdateParamsDto(agentId: $agentId, providerId: $providerId, model: $model, reasoningEffort: $reasoningEffort)';
}


}

/// @nodoc
abstract mixin class _$AgentConfigurationUpdateParamsDtoCopyWith<$Res> implements $AgentConfigurationUpdateParamsDtoCopyWith<$Res> {
  factory _$AgentConfigurationUpdateParamsDtoCopyWith(_AgentConfigurationUpdateParamsDto value, $Res Function(_AgentConfigurationUpdateParamsDto) _then) = __$AgentConfigurationUpdateParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String agentId, String providerId, String model, String reasoningEffort
});




}
/// @nodoc
class __$AgentConfigurationUpdateParamsDtoCopyWithImpl<$Res>
    implements _$AgentConfigurationUpdateParamsDtoCopyWith<$Res> {
  __$AgentConfigurationUpdateParamsDtoCopyWithImpl(this._self, this._then);

  final _AgentConfigurationUpdateParamsDto _self;
  final $Res Function(_AgentConfigurationUpdateParamsDto) _then;

/// Create a copy of AgentConfigurationUpdateParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? agentId = null,Object? providerId = null,Object? model = null,Object? reasoningEffort = null,}) {
  return _then(_AgentConfigurationUpdateParamsDto(
agentId: null == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,reasoningEffort: null == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProviderUpsertParamsDto {

 ApiProviderDto get provider; bool get makeDefault;
/// Create a copy of ProviderUpsertParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderUpsertParamsDtoCopyWith<ProviderUpsertParamsDto> get copyWith => _$ProviderUpsertParamsDtoCopyWithImpl<ProviderUpsertParamsDto>(this as ProviderUpsertParamsDto, _$identity);

  /// Serializes this ProviderUpsertParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderUpsertParamsDto&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.makeDefault, makeDefault) || other.makeDefault == makeDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,makeDefault);

@override
String toString() {
  return 'ProviderUpsertParamsDto(provider: $provider, makeDefault: $makeDefault)';
}


}

/// @nodoc
abstract mixin class $ProviderUpsertParamsDtoCopyWith<$Res>  {
  factory $ProviderUpsertParamsDtoCopyWith(ProviderUpsertParamsDto value, $Res Function(ProviderUpsertParamsDto) _then) = _$ProviderUpsertParamsDtoCopyWithImpl;
@useResult
$Res call({
 ApiProviderDto provider, bool makeDefault
});


$ApiProviderDtoCopyWith<$Res> get provider;

}
/// @nodoc
class _$ProviderUpsertParamsDtoCopyWithImpl<$Res>
    implements $ProviderUpsertParamsDtoCopyWith<$Res> {
  _$ProviderUpsertParamsDtoCopyWithImpl(this._self, this._then);

  final ProviderUpsertParamsDto _self;
  final $Res Function(ProviderUpsertParamsDto) _then;

/// Create a copy of ProviderUpsertParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provider = null,Object? makeDefault = null,}) {
  return _then(_self.copyWith(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as ApiProviderDto,makeDefault: null == makeDefault ? _self.makeDefault : makeDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ProviderUpsertParamsDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiProviderDtoCopyWith<$Res> get provider {
  
  return $ApiProviderDtoCopyWith<$Res>(_self.provider, (value) {
    return _then(_self.copyWith(provider: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProviderUpsertParamsDto].
extension ProviderUpsertParamsDtoPatterns on ProviderUpsertParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderUpsertParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderUpsertParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderUpsertParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderUpsertParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderUpsertParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderUpsertParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ApiProviderDto provider,  bool makeDefault)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderUpsertParamsDto() when $default != null:
return $default(_that.provider,_that.makeDefault);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ApiProviderDto provider,  bool makeDefault)  $default,) {final _that = this;
switch (_that) {
case _ProviderUpsertParamsDto():
return $default(_that.provider,_that.makeDefault);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ApiProviderDto provider,  bool makeDefault)?  $default,) {final _that = this;
switch (_that) {
case _ProviderUpsertParamsDto() when $default != null:
return $default(_that.provider,_that.makeDefault);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderUpsertParamsDto implements ProviderUpsertParamsDto {
  const _ProviderUpsertParamsDto({required this.provider, required this.makeDefault});
  factory _ProviderUpsertParamsDto.fromJson(Map<String, dynamic> json) => _$ProviderUpsertParamsDtoFromJson(json);

@override final  ApiProviderDto provider;
@override final  bool makeDefault;

/// Create a copy of ProviderUpsertParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderUpsertParamsDtoCopyWith<_ProviderUpsertParamsDto> get copyWith => __$ProviderUpsertParamsDtoCopyWithImpl<_ProviderUpsertParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderUpsertParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderUpsertParamsDto&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.makeDefault, makeDefault) || other.makeDefault == makeDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,makeDefault);

@override
String toString() {
  return 'ProviderUpsertParamsDto(provider: $provider, makeDefault: $makeDefault)';
}


}

/// @nodoc
abstract mixin class _$ProviderUpsertParamsDtoCopyWith<$Res> implements $ProviderUpsertParamsDtoCopyWith<$Res> {
  factory _$ProviderUpsertParamsDtoCopyWith(_ProviderUpsertParamsDto value, $Res Function(_ProviderUpsertParamsDto) _then) = __$ProviderUpsertParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 ApiProviderDto provider, bool makeDefault
});


@override $ApiProviderDtoCopyWith<$Res> get provider;

}
/// @nodoc
class __$ProviderUpsertParamsDtoCopyWithImpl<$Res>
    implements _$ProviderUpsertParamsDtoCopyWith<$Res> {
  __$ProviderUpsertParamsDtoCopyWithImpl(this._self, this._then);

  final _ProviderUpsertParamsDto _self;
  final $Res Function(_ProviderUpsertParamsDto) _then;

/// Create a copy of ProviderUpsertParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? makeDefault = null,}) {
  return _then(_ProviderUpsertParamsDto(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as ApiProviderDto,makeDefault: null == makeDefault ? _self.makeDefault : makeDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ProviderUpsertParamsDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiProviderDtoCopyWith<$Res> get provider {
  
  return $ApiProviderDtoCopyWith<$Res>(_self.provider, (value) {
    return _then(_self.copyWith(provider: value));
  });
}
}


/// @nodoc
mixin _$ProviderIdParamsDto {

 String get providerId;
/// Create a copy of ProviderIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderIdParamsDtoCopyWith<ProviderIdParamsDto> get copyWith => _$ProviderIdParamsDtoCopyWithImpl<ProviderIdParamsDto>(this as ProviderIdParamsDto, _$identity);

  /// Serializes this ProviderIdParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderIdParamsDto&&(identical(other.providerId, providerId) || other.providerId == providerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerId);

@override
String toString() {
  return 'ProviderIdParamsDto(providerId: $providerId)';
}


}

/// @nodoc
abstract mixin class $ProviderIdParamsDtoCopyWith<$Res>  {
  factory $ProviderIdParamsDtoCopyWith(ProviderIdParamsDto value, $Res Function(ProviderIdParamsDto) _then) = _$ProviderIdParamsDtoCopyWithImpl;
@useResult
$Res call({
 String providerId
});




}
/// @nodoc
class _$ProviderIdParamsDtoCopyWithImpl<$Res>
    implements $ProviderIdParamsDtoCopyWith<$Res> {
  _$ProviderIdParamsDtoCopyWithImpl(this._self, this._then);

  final ProviderIdParamsDto _self;
  final $Res Function(ProviderIdParamsDto) _then;

/// Create a copy of ProviderIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? providerId = null,}) {
  return _then(_self.copyWith(
providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderIdParamsDto].
extension ProviderIdParamsDtoPatterns on ProviderIdParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderIdParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderIdParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderIdParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderIdParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderIdParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderIdParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String providerId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderIdParamsDto() when $default != null:
return $default(_that.providerId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String providerId)  $default,) {final _that = this;
switch (_that) {
case _ProviderIdParamsDto():
return $default(_that.providerId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String providerId)?  $default,) {final _that = this;
switch (_that) {
case _ProviderIdParamsDto() when $default != null:
return $default(_that.providerId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderIdParamsDto implements ProviderIdParamsDto {
  const _ProviderIdParamsDto({required this.providerId});
  factory _ProviderIdParamsDto.fromJson(Map<String, dynamic> json) => _$ProviderIdParamsDtoFromJson(json);

@override final  String providerId;

/// Create a copy of ProviderIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderIdParamsDtoCopyWith<_ProviderIdParamsDto> get copyWith => __$ProviderIdParamsDtoCopyWithImpl<_ProviderIdParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderIdParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderIdParamsDto&&(identical(other.providerId, providerId) || other.providerId == providerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerId);

@override
String toString() {
  return 'ProviderIdParamsDto(providerId: $providerId)';
}


}

/// @nodoc
abstract mixin class _$ProviderIdParamsDtoCopyWith<$Res> implements $ProviderIdParamsDtoCopyWith<$Res> {
  factory _$ProviderIdParamsDtoCopyWith(_ProviderIdParamsDto value, $Res Function(_ProviderIdParamsDto) _then) = __$ProviderIdParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String providerId
});




}
/// @nodoc
class __$ProviderIdParamsDtoCopyWithImpl<$Res>
    implements _$ProviderIdParamsDtoCopyWith<$Res> {
  __$ProviderIdParamsDtoCopyWithImpl(this._self, this._then);

  final _ProviderIdParamsDto _self;
  final $Res Function(_ProviderIdParamsDto) _then;

/// Create a copy of ProviderIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? providerId = null,}) {
  return _then(_ProviderIdParamsDto(
providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProviderModelParamsDto {

 String get providerId; String get modelId;
/// Create a copy of ProviderModelParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderModelParamsDtoCopyWith<ProviderModelParamsDto> get copyWith => _$ProviderModelParamsDtoCopyWithImpl<ProviderModelParamsDto>(this as ProviderModelParamsDto, _$identity);

  /// Serializes this ProviderModelParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderModelParamsDto&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.modelId, modelId) || other.modelId == modelId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerId,modelId);

@override
String toString() {
  return 'ProviderModelParamsDto(providerId: $providerId, modelId: $modelId)';
}


}

/// @nodoc
abstract mixin class $ProviderModelParamsDtoCopyWith<$Res>  {
  factory $ProviderModelParamsDtoCopyWith(ProviderModelParamsDto value, $Res Function(ProviderModelParamsDto) _then) = _$ProviderModelParamsDtoCopyWithImpl;
@useResult
$Res call({
 String providerId, String modelId
});




}
/// @nodoc
class _$ProviderModelParamsDtoCopyWithImpl<$Res>
    implements $ProviderModelParamsDtoCopyWith<$Res> {
  _$ProviderModelParamsDtoCopyWithImpl(this._self, this._then);

  final ProviderModelParamsDto _self;
  final $Res Function(ProviderModelParamsDto) _then;

/// Create a copy of ProviderModelParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? providerId = null,Object? modelId = null,}) {
  return _then(_self.copyWith(
providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderModelParamsDto].
extension ProviderModelParamsDtoPatterns on ProviderModelParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderModelParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderModelParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderModelParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderModelParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderModelParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderModelParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String providerId,  String modelId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderModelParamsDto() when $default != null:
return $default(_that.providerId,_that.modelId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String providerId,  String modelId)  $default,) {final _that = this;
switch (_that) {
case _ProviderModelParamsDto():
return $default(_that.providerId,_that.modelId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String providerId,  String modelId)?  $default,) {final _that = this;
switch (_that) {
case _ProviderModelParamsDto() when $default != null:
return $default(_that.providerId,_that.modelId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderModelParamsDto implements ProviderModelParamsDto {
  const _ProviderModelParamsDto({required this.providerId, required this.modelId});
  factory _ProviderModelParamsDto.fromJson(Map<String, dynamic> json) => _$ProviderModelParamsDtoFromJson(json);

@override final  String providerId;
@override final  String modelId;

/// Create a copy of ProviderModelParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderModelParamsDtoCopyWith<_ProviderModelParamsDto> get copyWith => __$ProviderModelParamsDtoCopyWithImpl<_ProviderModelParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderModelParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderModelParamsDto&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.modelId, modelId) || other.modelId == modelId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerId,modelId);

@override
String toString() {
  return 'ProviderModelParamsDto(providerId: $providerId, modelId: $modelId)';
}


}

/// @nodoc
abstract mixin class _$ProviderModelParamsDtoCopyWith<$Res> implements $ProviderModelParamsDtoCopyWith<$Res> {
  factory _$ProviderModelParamsDtoCopyWith(_ProviderModelParamsDto value, $Res Function(_ProviderModelParamsDto) _then) = __$ProviderModelParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String providerId, String modelId
});




}
/// @nodoc
class __$ProviderModelParamsDtoCopyWithImpl<$Res>
    implements _$ProviderModelParamsDtoCopyWith<$Res> {
  __$ProviderModelParamsDtoCopyWithImpl(this._self, this._then);

  final _ProviderModelParamsDto _self;
  final $Res Function(_ProviderModelParamsDto) _then;

/// Create a copy of ProviderModelParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? providerId = null,Object? modelId = null,}) {
  return _then(_ProviderModelParamsDto(
providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProviderModelUpsertParamsDto {

 ProviderModelDto get model;
/// Create a copy of ProviderModelUpsertParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderModelUpsertParamsDtoCopyWith<ProviderModelUpsertParamsDto> get copyWith => _$ProviderModelUpsertParamsDtoCopyWithImpl<ProviderModelUpsertParamsDto>(this as ProviderModelUpsertParamsDto, _$identity);

  /// Serializes this ProviderModelUpsertParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderModelUpsertParamsDto&&(identical(other.model, model) || other.model == model));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,model);

@override
String toString() {
  return 'ProviderModelUpsertParamsDto(model: $model)';
}


}

/// @nodoc
abstract mixin class $ProviderModelUpsertParamsDtoCopyWith<$Res>  {
  factory $ProviderModelUpsertParamsDtoCopyWith(ProviderModelUpsertParamsDto value, $Res Function(ProviderModelUpsertParamsDto) _then) = _$ProviderModelUpsertParamsDtoCopyWithImpl;
@useResult
$Res call({
 ProviderModelDto model
});


$ProviderModelDtoCopyWith<$Res> get model;

}
/// @nodoc
class _$ProviderModelUpsertParamsDtoCopyWithImpl<$Res>
    implements $ProviderModelUpsertParamsDtoCopyWith<$Res> {
  _$ProviderModelUpsertParamsDtoCopyWithImpl(this._self, this._then);

  final ProviderModelUpsertParamsDto _self;
  final $Res Function(ProviderModelUpsertParamsDto) _then;

/// Create a copy of ProviderModelUpsertParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? model = null,}) {
  return _then(_self.copyWith(
model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as ProviderModelDto,
  ));
}
/// Create a copy of ProviderModelUpsertParamsDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderModelDtoCopyWith<$Res> get model {
  
  return $ProviderModelDtoCopyWith<$Res>(_self.model, (value) {
    return _then(_self.copyWith(model: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProviderModelUpsertParamsDto].
extension ProviderModelUpsertParamsDtoPatterns on ProviderModelUpsertParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderModelUpsertParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderModelUpsertParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderModelUpsertParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderModelUpsertParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderModelUpsertParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderModelUpsertParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProviderModelDto model)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderModelUpsertParamsDto() when $default != null:
return $default(_that.model);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProviderModelDto model)  $default,) {final _that = this;
switch (_that) {
case _ProviderModelUpsertParamsDto():
return $default(_that.model);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProviderModelDto model)?  $default,) {final _that = this;
switch (_that) {
case _ProviderModelUpsertParamsDto() when $default != null:
return $default(_that.model);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderModelUpsertParamsDto implements ProviderModelUpsertParamsDto {
  const _ProviderModelUpsertParamsDto({required this.model});
  factory _ProviderModelUpsertParamsDto.fromJson(Map<String, dynamic> json) => _$ProviderModelUpsertParamsDtoFromJson(json);

@override final  ProviderModelDto model;

/// Create a copy of ProviderModelUpsertParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderModelUpsertParamsDtoCopyWith<_ProviderModelUpsertParamsDto> get copyWith => __$ProviderModelUpsertParamsDtoCopyWithImpl<_ProviderModelUpsertParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderModelUpsertParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderModelUpsertParamsDto&&(identical(other.model, model) || other.model == model));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,model);

@override
String toString() {
  return 'ProviderModelUpsertParamsDto(model: $model)';
}


}

/// @nodoc
abstract mixin class _$ProviderModelUpsertParamsDtoCopyWith<$Res> implements $ProviderModelUpsertParamsDtoCopyWith<$Res> {
  factory _$ProviderModelUpsertParamsDtoCopyWith(_ProviderModelUpsertParamsDto value, $Res Function(_ProviderModelUpsertParamsDto) _then) = __$ProviderModelUpsertParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 ProviderModelDto model
});


@override $ProviderModelDtoCopyWith<$Res> get model;

}
/// @nodoc
class __$ProviderModelUpsertParamsDtoCopyWithImpl<$Res>
    implements _$ProviderModelUpsertParamsDtoCopyWith<$Res> {
  __$ProviderModelUpsertParamsDtoCopyWithImpl(this._self, this._then);

  final _ProviderModelUpsertParamsDto _self;
  final $Res Function(_ProviderModelUpsertParamsDto) _then;

/// Create a copy of ProviderModelUpsertParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? model = null,}) {
  return _then(_ProviderModelUpsertParamsDto(
model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as ProviderModelDto,
  ));
}

/// Create a copy of ProviderModelUpsertParamsDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderModelDtoCopyWith<$Res> get model {
  
  return $ProviderModelDtoCopyWith<$Res>(_self.model, (value) {
    return _then(_self.copyWith(model: value));
  });
}
}


/// @nodoc
mixin _$ProviderCredentialSetParamsDto {

 String get providerId; String get apiKey;
/// Create a copy of ProviderCredentialSetParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderCredentialSetParamsDtoCopyWith<ProviderCredentialSetParamsDto> get copyWith => _$ProviderCredentialSetParamsDtoCopyWithImpl<ProviderCredentialSetParamsDto>(this as ProviderCredentialSetParamsDto, _$identity);

  /// Serializes this ProviderCredentialSetParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderCredentialSetParamsDto&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerId,apiKey);

@override
String toString() {
  return 'ProviderCredentialSetParamsDto(providerId: $providerId, apiKey: $apiKey)';
}


}

/// @nodoc
abstract mixin class $ProviderCredentialSetParamsDtoCopyWith<$Res>  {
  factory $ProviderCredentialSetParamsDtoCopyWith(ProviderCredentialSetParamsDto value, $Res Function(ProviderCredentialSetParamsDto) _then) = _$ProviderCredentialSetParamsDtoCopyWithImpl;
@useResult
$Res call({
 String providerId, String apiKey
});




}
/// @nodoc
class _$ProviderCredentialSetParamsDtoCopyWithImpl<$Res>
    implements $ProviderCredentialSetParamsDtoCopyWith<$Res> {
  _$ProviderCredentialSetParamsDtoCopyWithImpl(this._self, this._then);

  final ProviderCredentialSetParamsDto _self;
  final $Res Function(ProviderCredentialSetParamsDto) _then;

/// Create a copy of ProviderCredentialSetParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? providerId = null,Object? apiKey = null,}) {
  return _then(_self.copyWith(
providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderCredentialSetParamsDto].
extension ProviderCredentialSetParamsDtoPatterns on ProviderCredentialSetParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderCredentialSetParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderCredentialSetParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderCredentialSetParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderCredentialSetParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderCredentialSetParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderCredentialSetParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String providerId,  String apiKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderCredentialSetParamsDto() when $default != null:
return $default(_that.providerId,_that.apiKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String providerId,  String apiKey)  $default,) {final _that = this;
switch (_that) {
case _ProviderCredentialSetParamsDto():
return $default(_that.providerId,_that.apiKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String providerId,  String apiKey)?  $default,) {final _that = this;
switch (_that) {
case _ProviderCredentialSetParamsDto() when $default != null:
return $default(_that.providerId,_that.apiKey);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderCredentialSetParamsDto implements ProviderCredentialSetParamsDto {
  const _ProviderCredentialSetParamsDto({required this.providerId, required this.apiKey});
  factory _ProviderCredentialSetParamsDto.fromJson(Map<String, dynamic> json) => _$ProviderCredentialSetParamsDtoFromJson(json);

@override final  String providerId;
@override final  String apiKey;

/// Create a copy of ProviderCredentialSetParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderCredentialSetParamsDtoCopyWith<_ProviderCredentialSetParamsDto> get copyWith => __$ProviderCredentialSetParamsDtoCopyWithImpl<_ProviderCredentialSetParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderCredentialSetParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderCredentialSetParamsDto&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerId,apiKey);

@override
String toString() {
  return 'ProviderCredentialSetParamsDto(providerId: $providerId, apiKey: $apiKey)';
}


}

/// @nodoc
abstract mixin class _$ProviderCredentialSetParamsDtoCopyWith<$Res> implements $ProviderCredentialSetParamsDtoCopyWith<$Res> {
  factory _$ProviderCredentialSetParamsDtoCopyWith(_ProviderCredentialSetParamsDto value, $Res Function(_ProviderCredentialSetParamsDto) _then) = __$ProviderCredentialSetParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String providerId, String apiKey
});




}
/// @nodoc
class __$ProviderCredentialSetParamsDtoCopyWithImpl<$Res>
    implements _$ProviderCredentialSetParamsDtoCopyWith<$Res> {
  __$ProviderCredentialSetParamsDtoCopyWithImpl(this._self, this._then);

  final _ProviderCredentialSetParamsDto _self;
  final $Res Function(_ProviderCredentialSetParamsDto) _then;

/// Create a copy of ProviderCredentialSetParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? providerId = null,Object? apiKey = null,}) {
  return _then(_ProviderCredentialSetParamsDto(
providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TurnStartParamsDto {

 String get agentId; String get turnId; String get prompt;
/// Create a copy of TurnStartParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TurnStartParamsDtoCopyWith<TurnStartParamsDto> get copyWith => _$TurnStartParamsDtoCopyWithImpl<TurnStartParamsDto>(this as TurnStartParamsDto, _$identity);

  /// Serializes this TurnStartParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TurnStartParamsDto&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.prompt, prompt) || other.prompt == prompt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,agentId,turnId,prompt);

@override
String toString() {
  return 'TurnStartParamsDto(agentId: $agentId, turnId: $turnId, prompt: $prompt)';
}


}

/// @nodoc
abstract mixin class $TurnStartParamsDtoCopyWith<$Res>  {
  factory $TurnStartParamsDtoCopyWith(TurnStartParamsDto value, $Res Function(TurnStartParamsDto) _then) = _$TurnStartParamsDtoCopyWithImpl;
@useResult
$Res call({
 String agentId, String turnId, String prompt
});




}
/// @nodoc
class _$TurnStartParamsDtoCopyWithImpl<$Res>
    implements $TurnStartParamsDtoCopyWith<$Res> {
  _$TurnStartParamsDtoCopyWithImpl(this._self, this._then);

  final TurnStartParamsDto _self;
  final $Res Function(TurnStartParamsDto) _then;

/// Create a copy of TurnStartParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? agentId = null,Object? turnId = null,Object? prompt = null,}) {
  return _then(_self.copyWith(
agentId: null == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String,turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TurnStartParamsDto].
extension TurnStartParamsDtoPatterns on TurnStartParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TurnStartParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TurnStartParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TurnStartParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _TurnStartParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TurnStartParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _TurnStartParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String agentId,  String turnId,  String prompt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TurnStartParamsDto() when $default != null:
return $default(_that.agentId,_that.turnId,_that.prompt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String agentId,  String turnId,  String prompt)  $default,) {final _that = this;
switch (_that) {
case _TurnStartParamsDto():
return $default(_that.agentId,_that.turnId,_that.prompt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String agentId,  String turnId,  String prompt)?  $default,) {final _that = this;
switch (_that) {
case _TurnStartParamsDto() when $default != null:
return $default(_that.agentId,_that.turnId,_that.prompt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TurnStartParamsDto implements TurnStartParamsDto {
  const _TurnStartParamsDto({required this.agentId, required this.turnId, required this.prompt});
  factory _TurnStartParamsDto.fromJson(Map<String, dynamic> json) => _$TurnStartParamsDtoFromJson(json);

@override final  String agentId;
@override final  String turnId;
@override final  String prompt;

/// Create a copy of TurnStartParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TurnStartParamsDtoCopyWith<_TurnStartParamsDto> get copyWith => __$TurnStartParamsDtoCopyWithImpl<_TurnStartParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TurnStartParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TurnStartParamsDto&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.prompt, prompt) || other.prompt == prompt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,agentId,turnId,prompt);

@override
String toString() {
  return 'TurnStartParamsDto(agentId: $agentId, turnId: $turnId, prompt: $prompt)';
}


}

/// @nodoc
abstract mixin class _$TurnStartParamsDtoCopyWith<$Res> implements $TurnStartParamsDtoCopyWith<$Res> {
  factory _$TurnStartParamsDtoCopyWith(_TurnStartParamsDto value, $Res Function(_TurnStartParamsDto) _then) = __$TurnStartParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String agentId, String turnId, String prompt
});




}
/// @nodoc
class __$TurnStartParamsDtoCopyWithImpl<$Res>
    implements _$TurnStartParamsDtoCopyWith<$Res> {
  __$TurnStartParamsDtoCopyWithImpl(this._self, this._then);

  final _TurnStartParamsDto _self;
  final $Res Function(_TurnStartParamsDto) _then;

/// Create a copy of TurnStartParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? agentId = null,Object? turnId = null,Object? prompt = null,}) {
  return _then(_TurnStartParamsDto(
agentId: null == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String,turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AgentIdParamsDto {

 String get agentId;
/// Create a copy of AgentIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentIdParamsDtoCopyWith<AgentIdParamsDto> get copyWith => _$AgentIdParamsDtoCopyWithImpl<AgentIdParamsDto>(this as AgentIdParamsDto, _$identity);

  /// Serializes this AgentIdParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentIdParamsDto&&(identical(other.agentId, agentId) || other.agentId == agentId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,agentId);

@override
String toString() {
  return 'AgentIdParamsDto(agentId: $agentId)';
}


}

/// @nodoc
abstract mixin class $AgentIdParamsDtoCopyWith<$Res>  {
  factory $AgentIdParamsDtoCopyWith(AgentIdParamsDto value, $Res Function(AgentIdParamsDto) _then) = _$AgentIdParamsDtoCopyWithImpl;
@useResult
$Res call({
 String agentId
});




}
/// @nodoc
class _$AgentIdParamsDtoCopyWithImpl<$Res>
    implements $AgentIdParamsDtoCopyWith<$Res> {
  _$AgentIdParamsDtoCopyWithImpl(this._self, this._then);

  final AgentIdParamsDto _self;
  final $Res Function(AgentIdParamsDto) _then;

/// Create a copy of AgentIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? agentId = null,}) {
  return _then(_self.copyWith(
agentId: null == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentIdParamsDto].
extension AgentIdParamsDtoPatterns on AgentIdParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentIdParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentIdParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentIdParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _AgentIdParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentIdParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _AgentIdParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String agentId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentIdParamsDto() when $default != null:
return $default(_that.agentId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String agentId)  $default,) {final _that = this;
switch (_that) {
case _AgentIdParamsDto():
return $default(_that.agentId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String agentId)?  $default,) {final _that = this;
switch (_that) {
case _AgentIdParamsDto() when $default != null:
return $default(_that.agentId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentIdParamsDto implements AgentIdParamsDto {
  const _AgentIdParamsDto({required this.agentId});
  factory _AgentIdParamsDto.fromJson(Map<String, dynamic> json) => _$AgentIdParamsDtoFromJson(json);

@override final  String agentId;

/// Create a copy of AgentIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentIdParamsDtoCopyWith<_AgentIdParamsDto> get copyWith => __$AgentIdParamsDtoCopyWithImpl<_AgentIdParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentIdParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentIdParamsDto&&(identical(other.agentId, agentId) || other.agentId == agentId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,agentId);

@override
String toString() {
  return 'AgentIdParamsDto(agentId: $agentId)';
}


}

/// @nodoc
abstract mixin class _$AgentIdParamsDtoCopyWith<$Res> implements $AgentIdParamsDtoCopyWith<$Res> {
  factory _$AgentIdParamsDtoCopyWith(_AgentIdParamsDto value, $Res Function(_AgentIdParamsDto) _then) = __$AgentIdParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String agentId
});




}
/// @nodoc
class __$AgentIdParamsDtoCopyWithImpl<$Res>
    implements _$AgentIdParamsDtoCopyWith<$Res> {
  __$AgentIdParamsDtoCopyWithImpl(this._self, this._then);

  final _AgentIdParamsDto _self;
  final $Res Function(_AgentIdParamsDto) _then;

/// Create a copy of AgentIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? agentId = null,}) {
  return _then(_AgentIdParamsDto(
agentId: null == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ApprovalResolveParamsDto {

 String get approvalId; bool get approved;
/// Create a copy of ApprovalResolveParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApprovalResolveParamsDtoCopyWith<ApprovalResolveParamsDto> get copyWith => _$ApprovalResolveParamsDtoCopyWithImpl<ApprovalResolveParamsDto>(this as ApprovalResolveParamsDto, _$identity);

  /// Serializes this ApprovalResolveParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApprovalResolveParamsDto&&(identical(other.approvalId, approvalId) || other.approvalId == approvalId)&&(identical(other.approved, approved) || other.approved == approved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,approvalId,approved);

@override
String toString() {
  return 'ApprovalResolveParamsDto(approvalId: $approvalId, approved: $approved)';
}


}

/// @nodoc
abstract mixin class $ApprovalResolveParamsDtoCopyWith<$Res>  {
  factory $ApprovalResolveParamsDtoCopyWith(ApprovalResolveParamsDto value, $Res Function(ApprovalResolveParamsDto) _then) = _$ApprovalResolveParamsDtoCopyWithImpl;
@useResult
$Res call({
 String approvalId, bool approved
});




}
/// @nodoc
class _$ApprovalResolveParamsDtoCopyWithImpl<$Res>
    implements $ApprovalResolveParamsDtoCopyWith<$Res> {
  _$ApprovalResolveParamsDtoCopyWithImpl(this._self, this._then);

  final ApprovalResolveParamsDto _self;
  final $Res Function(ApprovalResolveParamsDto) _then;

/// Create a copy of ApprovalResolveParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? approvalId = null,Object? approved = null,}) {
  return _then(_self.copyWith(
approvalId: null == approvalId ? _self.approvalId : approvalId // ignore: cast_nullable_to_non_nullable
as String,approved: null == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ApprovalResolveParamsDto].
extension ApprovalResolveParamsDtoPatterns on ApprovalResolveParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApprovalResolveParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApprovalResolveParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApprovalResolveParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _ApprovalResolveParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApprovalResolveParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _ApprovalResolveParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String approvalId,  bool approved)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApprovalResolveParamsDto() when $default != null:
return $default(_that.approvalId,_that.approved);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String approvalId,  bool approved)  $default,) {final _that = this;
switch (_that) {
case _ApprovalResolveParamsDto():
return $default(_that.approvalId,_that.approved);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String approvalId,  bool approved)?  $default,) {final _that = this;
switch (_that) {
case _ApprovalResolveParamsDto() when $default != null:
return $default(_that.approvalId,_that.approved);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApprovalResolveParamsDto implements ApprovalResolveParamsDto {
  const _ApprovalResolveParamsDto({required this.approvalId, required this.approved});
  factory _ApprovalResolveParamsDto.fromJson(Map<String, dynamic> json) => _$ApprovalResolveParamsDtoFromJson(json);

@override final  String approvalId;
@override final  bool approved;

/// Create a copy of ApprovalResolveParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApprovalResolveParamsDtoCopyWith<_ApprovalResolveParamsDto> get copyWith => __$ApprovalResolveParamsDtoCopyWithImpl<_ApprovalResolveParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApprovalResolveParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApprovalResolveParamsDto&&(identical(other.approvalId, approvalId) || other.approvalId == approvalId)&&(identical(other.approved, approved) || other.approved == approved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,approvalId,approved);

@override
String toString() {
  return 'ApprovalResolveParamsDto(approvalId: $approvalId, approved: $approved)';
}


}

/// @nodoc
abstract mixin class _$ApprovalResolveParamsDtoCopyWith<$Res> implements $ApprovalResolveParamsDtoCopyWith<$Res> {
  factory _$ApprovalResolveParamsDtoCopyWith(_ApprovalResolveParamsDto value, $Res Function(_ApprovalResolveParamsDto) _then) = __$ApprovalResolveParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String approvalId, bool approved
});




}
/// @nodoc
class __$ApprovalResolveParamsDtoCopyWithImpl<$Res>
    implements _$ApprovalResolveParamsDtoCopyWith<$Res> {
  __$ApprovalResolveParamsDtoCopyWithImpl(this._self, this._then);

  final _ApprovalResolveParamsDto _self;
  final $Res Function(_ApprovalResolveParamsDto) _then;

/// Create a copy of ApprovalResolveParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? approvalId = null,Object? approved = null,}) {
  return _then(_ApprovalResolveParamsDto(
approvalId: null == approvalId ? _self.approvalId : approvalId // ignore: cast_nullable_to_non_nullable
as String,approved: null == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$TimelineSubscribeParamsDto {

 String get agentId; int get afterSequence;
/// Create a copy of TimelineSubscribeParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimelineSubscribeParamsDtoCopyWith<TimelineSubscribeParamsDto> get copyWith => _$TimelineSubscribeParamsDtoCopyWithImpl<TimelineSubscribeParamsDto>(this as TimelineSubscribeParamsDto, _$identity);

  /// Serializes this TimelineSubscribeParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimelineSubscribeParamsDto&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.afterSequence, afterSequence) || other.afterSequence == afterSequence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,agentId,afterSequence);

@override
String toString() {
  return 'TimelineSubscribeParamsDto(agentId: $agentId, afterSequence: $afterSequence)';
}


}

/// @nodoc
abstract mixin class $TimelineSubscribeParamsDtoCopyWith<$Res>  {
  factory $TimelineSubscribeParamsDtoCopyWith(TimelineSubscribeParamsDto value, $Res Function(TimelineSubscribeParamsDto) _then) = _$TimelineSubscribeParamsDtoCopyWithImpl;
@useResult
$Res call({
 String agentId, int afterSequence
});




}
/// @nodoc
class _$TimelineSubscribeParamsDtoCopyWithImpl<$Res>
    implements $TimelineSubscribeParamsDtoCopyWith<$Res> {
  _$TimelineSubscribeParamsDtoCopyWithImpl(this._self, this._then);

  final TimelineSubscribeParamsDto _self;
  final $Res Function(TimelineSubscribeParamsDto) _then;

/// Create a copy of TimelineSubscribeParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? agentId = null,Object? afterSequence = null,}) {
  return _then(_self.copyWith(
agentId: null == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String,afterSequence: null == afterSequence ? _self.afterSequence : afterSequence // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TimelineSubscribeParamsDto].
extension TimelineSubscribeParamsDtoPatterns on TimelineSubscribeParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimelineSubscribeParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimelineSubscribeParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimelineSubscribeParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _TimelineSubscribeParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimelineSubscribeParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _TimelineSubscribeParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String agentId,  int afterSequence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimelineSubscribeParamsDto() when $default != null:
return $default(_that.agentId,_that.afterSequence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String agentId,  int afterSequence)  $default,) {final _that = this;
switch (_that) {
case _TimelineSubscribeParamsDto():
return $default(_that.agentId,_that.afterSequence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String agentId,  int afterSequence)?  $default,) {final _that = this;
switch (_that) {
case _TimelineSubscribeParamsDto() when $default != null:
return $default(_that.agentId,_that.afterSequence);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TimelineSubscribeParamsDto implements TimelineSubscribeParamsDto {
  const _TimelineSubscribeParamsDto({required this.agentId, required this.afterSequence});
  factory _TimelineSubscribeParamsDto.fromJson(Map<String, dynamic> json) => _$TimelineSubscribeParamsDtoFromJson(json);

@override final  String agentId;
@override final  int afterSequence;

/// Create a copy of TimelineSubscribeParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimelineSubscribeParamsDtoCopyWith<_TimelineSubscribeParamsDto> get copyWith => __$TimelineSubscribeParamsDtoCopyWithImpl<_TimelineSubscribeParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TimelineSubscribeParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimelineSubscribeParamsDto&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.afterSequence, afterSequence) || other.afterSequence == afterSequence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,agentId,afterSequence);

@override
String toString() {
  return 'TimelineSubscribeParamsDto(agentId: $agentId, afterSequence: $afterSequence)';
}


}

/// @nodoc
abstract mixin class _$TimelineSubscribeParamsDtoCopyWith<$Res> implements $TimelineSubscribeParamsDtoCopyWith<$Res> {
  factory _$TimelineSubscribeParamsDtoCopyWith(_TimelineSubscribeParamsDto value, $Res Function(_TimelineSubscribeParamsDto) _then) = __$TimelineSubscribeParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String agentId, int afterSequence
});




}
/// @nodoc
class __$TimelineSubscribeParamsDtoCopyWithImpl<$Res>
    implements _$TimelineSubscribeParamsDtoCopyWith<$Res> {
  __$TimelineSubscribeParamsDtoCopyWithImpl(this._self, this._then);

  final _TimelineSubscribeParamsDto _self;
  final $Res Function(_TimelineSubscribeParamsDto) _then;

/// Create a copy of TimelineSubscribeParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? agentId = null,Object? afterSequence = null,}) {
  return _then(_TimelineSubscribeParamsDto(
agentId: null == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String,afterSequence: null == afterSequence ? _self.afterSequence : afterSequence // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$WorkspaceListResultDto {

 List<WorkspaceDto> get workspaces;
/// Create a copy of WorkspaceListResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceListResultDtoCopyWith<WorkspaceListResultDto> get copyWith => _$WorkspaceListResultDtoCopyWithImpl<WorkspaceListResultDto>(this as WorkspaceListResultDto, _$identity);

  /// Serializes this WorkspaceListResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceListResultDto&&const DeepCollectionEquality().equals(other.workspaces, workspaces));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(workspaces));

@override
String toString() {
  return 'WorkspaceListResultDto(workspaces: $workspaces)';
}


}

/// @nodoc
abstract mixin class $WorkspaceListResultDtoCopyWith<$Res>  {
  factory $WorkspaceListResultDtoCopyWith(WorkspaceListResultDto value, $Res Function(WorkspaceListResultDto) _then) = _$WorkspaceListResultDtoCopyWithImpl;
@useResult
$Res call({
 List<WorkspaceDto> workspaces
});




}
/// @nodoc
class _$WorkspaceListResultDtoCopyWithImpl<$Res>
    implements $WorkspaceListResultDtoCopyWith<$Res> {
  _$WorkspaceListResultDtoCopyWithImpl(this._self, this._then);

  final WorkspaceListResultDto _self;
  final $Res Function(WorkspaceListResultDto) _then;

/// Create a copy of WorkspaceListResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workspaces = null,}) {
  return _then(_self.copyWith(
workspaces: null == workspaces ? _self.workspaces : workspaces // ignore: cast_nullable_to_non_nullable
as List<WorkspaceDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkspaceListResultDto].
extension WorkspaceListResultDtoPatterns on WorkspaceListResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceListResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceListResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceListResultDto value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceListResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceListResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceListResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<WorkspaceDto> workspaces)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceListResultDto() when $default != null:
return $default(_that.workspaces);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<WorkspaceDto> workspaces)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceListResultDto():
return $default(_that.workspaces);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<WorkspaceDto> workspaces)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceListResultDto() when $default != null:
return $default(_that.workspaces);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkspaceListResultDto implements WorkspaceListResultDto {
  const _WorkspaceListResultDto({required final  List<WorkspaceDto> workspaces}): _workspaces = workspaces;
  factory _WorkspaceListResultDto.fromJson(Map<String, dynamic> json) => _$WorkspaceListResultDtoFromJson(json);

 final  List<WorkspaceDto> _workspaces;
@override List<WorkspaceDto> get workspaces {
  if (_workspaces is EqualUnmodifiableListView) return _workspaces;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_workspaces);
}


/// Create a copy of WorkspaceListResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceListResultDtoCopyWith<_WorkspaceListResultDto> get copyWith => __$WorkspaceListResultDtoCopyWithImpl<_WorkspaceListResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkspaceListResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceListResultDto&&const DeepCollectionEquality().equals(other._workspaces, _workspaces));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_workspaces));

@override
String toString() {
  return 'WorkspaceListResultDto(workspaces: $workspaces)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceListResultDtoCopyWith<$Res> implements $WorkspaceListResultDtoCopyWith<$Res> {
  factory _$WorkspaceListResultDtoCopyWith(_WorkspaceListResultDto value, $Res Function(_WorkspaceListResultDto) _then) = __$WorkspaceListResultDtoCopyWithImpl;
@override @useResult
$Res call({
 List<WorkspaceDto> workspaces
});




}
/// @nodoc
class __$WorkspaceListResultDtoCopyWithImpl<$Res>
    implements _$WorkspaceListResultDtoCopyWith<$Res> {
  __$WorkspaceListResultDtoCopyWithImpl(this._self, this._then);

  final _WorkspaceListResultDto _self;
  final $Res Function(_WorkspaceListResultDto) _then;

/// Create a copy of WorkspaceListResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workspaces = null,}) {
  return _then(_WorkspaceListResultDto(
workspaces: null == workspaces ? _self._workspaces : workspaces // ignore: cast_nullable_to_non_nullable
as List<WorkspaceDto>,
  ));
}


}


/// @nodoc
mixin _$WorkspaceResultDto {

 WorkspaceDto get workspace;
/// Create a copy of WorkspaceResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceResultDtoCopyWith<WorkspaceResultDto> get copyWith => _$WorkspaceResultDtoCopyWithImpl<WorkspaceResultDto>(this as WorkspaceResultDto, _$identity);

  /// Serializes this WorkspaceResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceResultDto&&(identical(other.workspace, workspace) || other.workspace == workspace));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workspace);

@override
String toString() {
  return 'WorkspaceResultDto(workspace: $workspace)';
}


}

/// @nodoc
abstract mixin class $WorkspaceResultDtoCopyWith<$Res>  {
  factory $WorkspaceResultDtoCopyWith(WorkspaceResultDto value, $Res Function(WorkspaceResultDto) _then) = _$WorkspaceResultDtoCopyWithImpl;
@useResult
$Res call({
 WorkspaceDto workspace
});


$WorkspaceDtoCopyWith<$Res> get workspace;

}
/// @nodoc
class _$WorkspaceResultDtoCopyWithImpl<$Res>
    implements $WorkspaceResultDtoCopyWith<$Res> {
  _$WorkspaceResultDtoCopyWithImpl(this._self, this._then);

  final WorkspaceResultDto _self;
  final $Res Function(WorkspaceResultDto) _then;

/// Create a copy of WorkspaceResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workspace = null,}) {
  return _then(_self.copyWith(
workspace: null == workspace ? _self.workspace : workspace // ignore: cast_nullable_to_non_nullable
as WorkspaceDto,
  ));
}
/// Create a copy of WorkspaceResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkspaceDtoCopyWith<$Res> get workspace {
  
  return $WorkspaceDtoCopyWith<$Res>(_self.workspace, (value) {
    return _then(_self.copyWith(workspace: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorkspaceResultDto].
extension WorkspaceResultDtoPatterns on WorkspaceResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceResultDto value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkspaceDto workspace)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceResultDto() when $default != null:
return $default(_that.workspace);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkspaceDto workspace)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceResultDto():
return $default(_that.workspace);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkspaceDto workspace)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceResultDto() when $default != null:
return $default(_that.workspace);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkspaceResultDto implements WorkspaceResultDto {
  const _WorkspaceResultDto({required this.workspace});
  factory _WorkspaceResultDto.fromJson(Map<String, dynamic> json) => _$WorkspaceResultDtoFromJson(json);

@override final  WorkspaceDto workspace;

/// Create a copy of WorkspaceResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceResultDtoCopyWith<_WorkspaceResultDto> get copyWith => __$WorkspaceResultDtoCopyWithImpl<_WorkspaceResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkspaceResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceResultDto&&(identical(other.workspace, workspace) || other.workspace == workspace));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workspace);

@override
String toString() {
  return 'WorkspaceResultDto(workspace: $workspace)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceResultDtoCopyWith<$Res> implements $WorkspaceResultDtoCopyWith<$Res> {
  factory _$WorkspaceResultDtoCopyWith(_WorkspaceResultDto value, $Res Function(_WorkspaceResultDto) _then) = __$WorkspaceResultDtoCopyWithImpl;
@override @useResult
$Res call({
 WorkspaceDto workspace
});


@override $WorkspaceDtoCopyWith<$Res> get workspace;

}
/// @nodoc
class __$WorkspaceResultDtoCopyWithImpl<$Res>
    implements _$WorkspaceResultDtoCopyWith<$Res> {
  __$WorkspaceResultDtoCopyWithImpl(this._self, this._then);

  final _WorkspaceResultDto _self;
  final $Res Function(_WorkspaceResultDto) _then;

/// Create a copy of WorkspaceResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workspace = null,}) {
  return _then(_WorkspaceResultDto(
workspace: null == workspace ? _self.workspace : workspace // ignore: cast_nullable_to_non_nullable
as WorkspaceDto,
  ));
}

/// Create a copy of WorkspaceResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkspaceDtoCopyWith<$Res> get workspace {
  
  return $WorkspaceDtoCopyWith<$Res>(_self.workspace, (value) {
    return _then(_self.copyWith(workspace: value));
  });
}
}


/// @nodoc
mixin _$AgentListResultDto {

 List<AgentDto> get agents;
/// Create a copy of AgentListResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentListResultDtoCopyWith<AgentListResultDto> get copyWith => _$AgentListResultDtoCopyWithImpl<AgentListResultDto>(this as AgentListResultDto, _$identity);

  /// Serializes this AgentListResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentListResultDto&&const DeepCollectionEquality().equals(other.agents, agents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(agents));

@override
String toString() {
  return 'AgentListResultDto(agents: $agents)';
}


}

/// @nodoc
abstract mixin class $AgentListResultDtoCopyWith<$Res>  {
  factory $AgentListResultDtoCopyWith(AgentListResultDto value, $Res Function(AgentListResultDto) _then) = _$AgentListResultDtoCopyWithImpl;
@useResult
$Res call({
 List<AgentDto> agents
});




}
/// @nodoc
class _$AgentListResultDtoCopyWithImpl<$Res>
    implements $AgentListResultDtoCopyWith<$Res> {
  _$AgentListResultDtoCopyWithImpl(this._self, this._then);

  final AgentListResultDto _self;
  final $Res Function(AgentListResultDto) _then;

/// Create a copy of AgentListResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? agents = null,}) {
  return _then(_self.copyWith(
agents: null == agents ? _self.agents : agents // ignore: cast_nullable_to_non_nullable
as List<AgentDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentListResultDto].
extension AgentListResultDtoPatterns on AgentListResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentListResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentListResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentListResultDto value)  $default,){
final _that = this;
switch (_that) {
case _AgentListResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentListResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _AgentListResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AgentDto> agents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentListResultDto() when $default != null:
return $default(_that.agents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AgentDto> agents)  $default,) {final _that = this;
switch (_that) {
case _AgentListResultDto():
return $default(_that.agents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AgentDto> agents)?  $default,) {final _that = this;
switch (_that) {
case _AgentListResultDto() when $default != null:
return $default(_that.agents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentListResultDto implements AgentListResultDto {
  const _AgentListResultDto({required final  List<AgentDto> agents}): _agents = agents;
  factory _AgentListResultDto.fromJson(Map<String, dynamic> json) => _$AgentListResultDtoFromJson(json);

 final  List<AgentDto> _agents;
@override List<AgentDto> get agents {
  if (_agents is EqualUnmodifiableListView) return _agents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_agents);
}


/// Create a copy of AgentListResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentListResultDtoCopyWith<_AgentListResultDto> get copyWith => __$AgentListResultDtoCopyWithImpl<_AgentListResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentListResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentListResultDto&&const DeepCollectionEquality().equals(other._agents, _agents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_agents));

@override
String toString() {
  return 'AgentListResultDto(agents: $agents)';
}


}

/// @nodoc
abstract mixin class _$AgentListResultDtoCopyWith<$Res> implements $AgentListResultDtoCopyWith<$Res> {
  factory _$AgentListResultDtoCopyWith(_AgentListResultDto value, $Res Function(_AgentListResultDto) _then) = __$AgentListResultDtoCopyWithImpl;
@override @useResult
$Res call({
 List<AgentDto> agents
});




}
/// @nodoc
class __$AgentListResultDtoCopyWithImpl<$Res>
    implements _$AgentListResultDtoCopyWith<$Res> {
  __$AgentListResultDtoCopyWithImpl(this._self, this._then);

  final _AgentListResultDto _self;
  final $Res Function(_AgentListResultDto) _then;

/// Create a copy of AgentListResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? agents = null,}) {
  return _then(_AgentListResultDto(
agents: null == agents ? _self._agents : agents // ignore: cast_nullable_to_non_nullable
as List<AgentDto>,
  ));
}


}


/// @nodoc
mixin _$AgentResultDto {

 AgentDto get agent;
/// Create a copy of AgentResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentResultDtoCopyWith<AgentResultDto> get copyWith => _$AgentResultDtoCopyWithImpl<AgentResultDto>(this as AgentResultDto, _$identity);

  /// Serializes this AgentResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentResultDto&&(identical(other.agent, agent) || other.agent == agent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,agent);

@override
String toString() {
  return 'AgentResultDto(agent: $agent)';
}


}

/// @nodoc
abstract mixin class $AgentResultDtoCopyWith<$Res>  {
  factory $AgentResultDtoCopyWith(AgentResultDto value, $Res Function(AgentResultDto) _then) = _$AgentResultDtoCopyWithImpl;
@useResult
$Res call({
 AgentDto agent
});


$AgentDtoCopyWith<$Res> get agent;

}
/// @nodoc
class _$AgentResultDtoCopyWithImpl<$Res>
    implements $AgentResultDtoCopyWith<$Res> {
  _$AgentResultDtoCopyWithImpl(this._self, this._then);

  final AgentResultDto _self;
  final $Res Function(AgentResultDto) _then;

/// Create a copy of AgentResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? agent = null,}) {
  return _then(_self.copyWith(
agent: null == agent ? _self.agent : agent // ignore: cast_nullable_to_non_nullable
as AgentDto,
  ));
}
/// Create a copy of AgentResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AgentDtoCopyWith<$Res> get agent {
  
  return $AgentDtoCopyWith<$Res>(_self.agent, (value) {
    return _then(_self.copyWith(agent: value));
  });
}
}


/// Adds pattern-matching-related methods to [AgentResultDto].
extension AgentResultDtoPatterns on AgentResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentResultDto value)  $default,){
final _that = this;
switch (_that) {
case _AgentResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _AgentResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AgentDto agent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentResultDto() when $default != null:
return $default(_that.agent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AgentDto agent)  $default,) {final _that = this;
switch (_that) {
case _AgentResultDto():
return $default(_that.agent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AgentDto agent)?  $default,) {final _that = this;
switch (_that) {
case _AgentResultDto() when $default != null:
return $default(_that.agent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentResultDto implements AgentResultDto {
  const _AgentResultDto({required this.agent});
  factory _AgentResultDto.fromJson(Map<String, dynamic> json) => _$AgentResultDtoFromJson(json);

@override final  AgentDto agent;

/// Create a copy of AgentResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentResultDtoCopyWith<_AgentResultDto> get copyWith => __$AgentResultDtoCopyWithImpl<_AgentResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentResultDto&&(identical(other.agent, agent) || other.agent == agent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,agent);

@override
String toString() {
  return 'AgentResultDto(agent: $agent)';
}


}

/// @nodoc
abstract mixin class _$AgentResultDtoCopyWith<$Res> implements $AgentResultDtoCopyWith<$Res> {
  factory _$AgentResultDtoCopyWith(_AgentResultDto value, $Res Function(_AgentResultDto) _then) = __$AgentResultDtoCopyWithImpl;
@override @useResult
$Res call({
 AgentDto agent
});


@override $AgentDtoCopyWith<$Res> get agent;

}
/// @nodoc
class __$AgentResultDtoCopyWithImpl<$Res>
    implements _$AgentResultDtoCopyWith<$Res> {
  __$AgentResultDtoCopyWithImpl(this._self, this._then);

  final _AgentResultDto _self;
  final $Res Function(_AgentResultDto) _then;

/// Create a copy of AgentResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? agent = null,}) {
  return _then(_AgentResultDto(
agent: null == agent ? _self.agent : agent // ignore: cast_nullable_to_non_nullable
as AgentDto,
  ));
}

/// Create a copy of AgentResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AgentDtoCopyWith<$Res> get agent {
  
  return $AgentDtoCopyWith<$Res>(_self.agent, (value) {
    return _then(_self.copyWith(agent: value));
  });
}
}


/// @nodoc
mixin _$ProviderCatalogResultDto {

 ProviderCatalogDto get catalog;
/// Create a copy of ProviderCatalogResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderCatalogResultDtoCopyWith<ProviderCatalogResultDto> get copyWith => _$ProviderCatalogResultDtoCopyWithImpl<ProviderCatalogResultDto>(this as ProviderCatalogResultDto, _$identity);

  /// Serializes this ProviderCatalogResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderCatalogResultDto&&(identical(other.catalog, catalog) || other.catalog == catalog));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,catalog);

@override
String toString() {
  return 'ProviderCatalogResultDto(catalog: $catalog)';
}


}

/// @nodoc
abstract mixin class $ProviderCatalogResultDtoCopyWith<$Res>  {
  factory $ProviderCatalogResultDtoCopyWith(ProviderCatalogResultDto value, $Res Function(ProviderCatalogResultDto) _then) = _$ProviderCatalogResultDtoCopyWithImpl;
@useResult
$Res call({
 ProviderCatalogDto catalog
});


$ProviderCatalogDtoCopyWith<$Res> get catalog;

}
/// @nodoc
class _$ProviderCatalogResultDtoCopyWithImpl<$Res>
    implements $ProviderCatalogResultDtoCopyWith<$Res> {
  _$ProviderCatalogResultDtoCopyWithImpl(this._self, this._then);

  final ProviderCatalogResultDto _self;
  final $Res Function(ProviderCatalogResultDto) _then;

/// Create a copy of ProviderCatalogResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? catalog = null,}) {
  return _then(_self.copyWith(
catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as ProviderCatalogDto,
  ));
}
/// Create a copy of ProviderCatalogResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderCatalogDtoCopyWith<$Res> get catalog {
  
  return $ProviderCatalogDtoCopyWith<$Res>(_self.catalog, (value) {
    return _then(_self.copyWith(catalog: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProviderCatalogResultDto].
extension ProviderCatalogResultDtoPatterns on ProviderCatalogResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderCatalogResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderCatalogResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderCatalogResultDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderCatalogResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderCatalogResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderCatalogResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProviderCatalogDto catalog)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderCatalogResultDto() when $default != null:
return $default(_that.catalog);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProviderCatalogDto catalog)  $default,) {final _that = this;
switch (_that) {
case _ProviderCatalogResultDto():
return $default(_that.catalog);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProviderCatalogDto catalog)?  $default,) {final _that = this;
switch (_that) {
case _ProviderCatalogResultDto() when $default != null:
return $default(_that.catalog);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderCatalogResultDto implements ProviderCatalogResultDto {
  const _ProviderCatalogResultDto({required this.catalog});
  factory _ProviderCatalogResultDto.fromJson(Map<String, dynamic> json) => _$ProviderCatalogResultDtoFromJson(json);

@override final  ProviderCatalogDto catalog;

/// Create a copy of ProviderCatalogResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderCatalogResultDtoCopyWith<_ProviderCatalogResultDto> get copyWith => __$ProviderCatalogResultDtoCopyWithImpl<_ProviderCatalogResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderCatalogResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderCatalogResultDto&&(identical(other.catalog, catalog) || other.catalog == catalog));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,catalog);

@override
String toString() {
  return 'ProviderCatalogResultDto(catalog: $catalog)';
}


}

/// @nodoc
abstract mixin class _$ProviderCatalogResultDtoCopyWith<$Res> implements $ProviderCatalogResultDtoCopyWith<$Res> {
  factory _$ProviderCatalogResultDtoCopyWith(_ProviderCatalogResultDto value, $Res Function(_ProviderCatalogResultDto) _then) = __$ProviderCatalogResultDtoCopyWithImpl;
@override @useResult
$Res call({
 ProviderCatalogDto catalog
});


@override $ProviderCatalogDtoCopyWith<$Res> get catalog;

}
/// @nodoc
class __$ProviderCatalogResultDtoCopyWithImpl<$Res>
    implements _$ProviderCatalogResultDtoCopyWith<$Res> {
  __$ProviderCatalogResultDtoCopyWithImpl(this._self, this._then);

  final _ProviderCatalogResultDto _self;
  final $Res Function(_ProviderCatalogResultDto) _then;

/// Create a copy of ProviderCatalogResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? catalog = null,}) {
  return _then(_ProviderCatalogResultDto(
catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as ProviderCatalogDto,
  ));
}

/// Create a copy of ProviderCatalogResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderCatalogDtoCopyWith<$Res> get catalog {
  
  return $ProviderCatalogDtoCopyWith<$Res>(_self.catalog, (value) {
    return _then(_self.copyWith(catalog: value));
  });
}
}


/// @nodoc
mixin _$ProviderResultDto {

 ApiProviderDto get provider;
/// Create a copy of ProviderResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderResultDtoCopyWith<ProviderResultDto> get copyWith => _$ProviderResultDtoCopyWithImpl<ProviderResultDto>(this as ProviderResultDto, _$identity);

  /// Serializes this ProviderResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderResultDto&&(identical(other.provider, provider) || other.provider == provider));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider);

@override
String toString() {
  return 'ProviderResultDto(provider: $provider)';
}


}

/// @nodoc
abstract mixin class $ProviderResultDtoCopyWith<$Res>  {
  factory $ProviderResultDtoCopyWith(ProviderResultDto value, $Res Function(ProviderResultDto) _then) = _$ProviderResultDtoCopyWithImpl;
@useResult
$Res call({
 ApiProviderDto provider
});


$ApiProviderDtoCopyWith<$Res> get provider;

}
/// @nodoc
class _$ProviderResultDtoCopyWithImpl<$Res>
    implements $ProviderResultDtoCopyWith<$Res> {
  _$ProviderResultDtoCopyWithImpl(this._self, this._then);

  final ProviderResultDto _self;
  final $Res Function(ProviderResultDto) _then;

/// Create a copy of ProviderResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provider = null,}) {
  return _then(_self.copyWith(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as ApiProviderDto,
  ));
}
/// Create a copy of ProviderResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiProviderDtoCopyWith<$Res> get provider {
  
  return $ApiProviderDtoCopyWith<$Res>(_self.provider, (value) {
    return _then(_self.copyWith(provider: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProviderResultDto].
extension ProviderResultDtoPatterns on ProviderResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderResultDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ApiProviderDto provider)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderResultDto() when $default != null:
return $default(_that.provider);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ApiProviderDto provider)  $default,) {final _that = this;
switch (_that) {
case _ProviderResultDto():
return $default(_that.provider);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ApiProviderDto provider)?  $default,) {final _that = this;
switch (_that) {
case _ProviderResultDto() when $default != null:
return $default(_that.provider);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderResultDto implements ProviderResultDto {
  const _ProviderResultDto({required this.provider});
  factory _ProviderResultDto.fromJson(Map<String, dynamic> json) => _$ProviderResultDtoFromJson(json);

@override final  ApiProviderDto provider;

/// Create a copy of ProviderResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderResultDtoCopyWith<_ProviderResultDto> get copyWith => __$ProviderResultDtoCopyWithImpl<_ProviderResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderResultDto&&(identical(other.provider, provider) || other.provider == provider));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider);

@override
String toString() {
  return 'ProviderResultDto(provider: $provider)';
}


}

/// @nodoc
abstract mixin class _$ProviderResultDtoCopyWith<$Res> implements $ProviderResultDtoCopyWith<$Res> {
  factory _$ProviderResultDtoCopyWith(_ProviderResultDto value, $Res Function(_ProviderResultDto) _then) = __$ProviderResultDtoCopyWithImpl;
@override @useResult
$Res call({
 ApiProviderDto provider
});


@override $ApiProviderDtoCopyWith<$Res> get provider;

}
/// @nodoc
class __$ProviderResultDtoCopyWithImpl<$Res>
    implements _$ProviderResultDtoCopyWith<$Res> {
  __$ProviderResultDtoCopyWithImpl(this._self, this._then);

  final _ProviderResultDto _self;
  final $Res Function(_ProviderResultDto) _then;

/// Create a copy of ProviderResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,}) {
  return _then(_ProviderResultDto(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as ApiProviderDto,
  ));
}

/// Create a copy of ProviderResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiProviderDtoCopyWith<$Res> get provider {
  
  return $ApiProviderDtoCopyWith<$Res>(_self.provider, (value) {
    return _then(_self.copyWith(provider: value));
  });
}
}


/// @nodoc
mixin _$ProviderModelsResultDto {

 List<ProviderModelDto> get models;
/// Create a copy of ProviderModelsResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderModelsResultDtoCopyWith<ProviderModelsResultDto> get copyWith => _$ProviderModelsResultDtoCopyWithImpl<ProviderModelsResultDto>(this as ProviderModelsResultDto, _$identity);

  /// Serializes this ProviderModelsResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderModelsResultDto&&const DeepCollectionEquality().equals(other.models, models));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(models));

@override
String toString() {
  return 'ProviderModelsResultDto(models: $models)';
}


}

/// @nodoc
abstract mixin class $ProviderModelsResultDtoCopyWith<$Res>  {
  factory $ProviderModelsResultDtoCopyWith(ProviderModelsResultDto value, $Res Function(ProviderModelsResultDto) _then) = _$ProviderModelsResultDtoCopyWithImpl;
@useResult
$Res call({
 List<ProviderModelDto> models
});




}
/// @nodoc
class _$ProviderModelsResultDtoCopyWithImpl<$Res>
    implements $ProviderModelsResultDtoCopyWith<$Res> {
  _$ProviderModelsResultDtoCopyWithImpl(this._self, this._then);

  final ProviderModelsResultDto _self;
  final $Res Function(ProviderModelsResultDto) _then;

/// Create a copy of ProviderModelsResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? models = null,}) {
  return _then(_self.copyWith(
models: null == models ? _self.models : models // ignore: cast_nullable_to_non_nullable
as List<ProviderModelDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderModelsResultDto].
extension ProviderModelsResultDtoPatterns on ProviderModelsResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderModelsResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderModelsResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderModelsResultDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderModelsResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderModelsResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderModelsResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ProviderModelDto> models)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderModelsResultDto() when $default != null:
return $default(_that.models);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ProviderModelDto> models)  $default,) {final _that = this;
switch (_that) {
case _ProviderModelsResultDto():
return $default(_that.models);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ProviderModelDto> models)?  $default,) {final _that = this;
switch (_that) {
case _ProviderModelsResultDto() when $default != null:
return $default(_that.models);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderModelsResultDto implements ProviderModelsResultDto {
  const _ProviderModelsResultDto({required final  List<ProviderModelDto> models}): _models = models;
  factory _ProviderModelsResultDto.fromJson(Map<String, dynamic> json) => _$ProviderModelsResultDtoFromJson(json);

 final  List<ProviderModelDto> _models;
@override List<ProviderModelDto> get models {
  if (_models is EqualUnmodifiableListView) return _models;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_models);
}


/// Create a copy of ProviderModelsResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderModelsResultDtoCopyWith<_ProviderModelsResultDto> get copyWith => __$ProviderModelsResultDtoCopyWithImpl<_ProviderModelsResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderModelsResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderModelsResultDto&&const DeepCollectionEquality().equals(other._models, _models));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_models));

@override
String toString() {
  return 'ProviderModelsResultDto(models: $models)';
}


}

/// @nodoc
abstract mixin class _$ProviderModelsResultDtoCopyWith<$Res> implements $ProviderModelsResultDtoCopyWith<$Res> {
  factory _$ProviderModelsResultDtoCopyWith(_ProviderModelsResultDto value, $Res Function(_ProviderModelsResultDto) _then) = __$ProviderModelsResultDtoCopyWithImpl;
@override @useResult
$Res call({
 List<ProviderModelDto> models
});




}
/// @nodoc
class __$ProviderModelsResultDtoCopyWithImpl<$Res>
    implements _$ProviderModelsResultDtoCopyWith<$Res> {
  __$ProviderModelsResultDtoCopyWithImpl(this._self, this._then);

  final _ProviderModelsResultDto _self;
  final $Res Function(_ProviderModelsResultDto) _then;

/// Create a copy of ProviderModelsResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? models = null,}) {
  return _then(_ProviderModelsResultDto(
models: null == models ? _self._models : models // ignore: cast_nullable_to_non_nullable
as List<ProviderModelDto>,
  ));
}


}


/// @nodoc
mixin _$ProviderModelResultDto {

 ProviderModelDto get model;
/// Create a copy of ProviderModelResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderModelResultDtoCopyWith<ProviderModelResultDto> get copyWith => _$ProviderModelResultDtoCopyWithImpl<ProviderModelResultDto>(this as ProviderModelResultDto, _$identity);

  /// Serializes this ProviderModelResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderModelResultDto&&(identical(other.model, model) || other.model == model));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,model);

@override
String toString() {
  return 'ProviderModelResultDto(model: $model)';
}


}

/// @nodoc
abstract mixin class $ProviderModelResultDtoCopyWith<$Res>  {
  factory $ProviderModelResultDtoCopyWith(ProviderModelResultDto value, $Res Function(ProviderModelResultDto) _then) = _$ProviderModelResultDtoCopyWithImpl;
@useResult
$Res call({
 ProviderModelDto model
});


$ProviderModelDtoCopyWith<$Res> get model;

}
/// @nodoc
class _$ProviderModelResultDtoCopyWithImpl<$Res>
    implements $ProviderModelResultDtoCopyWith<$Res> {
  _$ProviderModelResultDtoCopyWithImpl(this._self, this._then);

  final ProviderModelResultDto _self;
  final $Res Function(ProviderModelResultDto) _then;

/// Create a copy of ProviderModelResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? model = null,}) {
  return _then(_self.copyWith(
model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as ProviderModelDto,
  ));
}
/// Create a copy of ProviderModelResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderModelDtoCopyWith<$Res> get model {
  
  return $ProviderModelDtoCopyWith<$Res>(_self.model, (value) {
    return _then(_self.copyWith(model: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProviderModelResultDto].
extension ProviderModelResultDtoPatterns on ProviderModelResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderModelResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderModelResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderModelResultDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderModelResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderModelResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderModelResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProviderModelDto model)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderModelResultDto() when $default != null:
return $default(_that.model);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProviderModelDto model)  $default,) {final _that = this;
switch (_that) {
case _ProviderModelResultDto():
return $default(_that.model);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProviderModelDto model)?  $default,) {final _that = this;
switch (_that) {
case _ProviderModelResultDto() when $default != null:
return $default(_that.model);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderModelResultDto implements ProviderModelResultDto {
  const _ProviderModelResultDto({required this.model});
  factory _ProviderModelResultDto.fromJson(Map<String, dynamic> json) => _$ProviderModelResultDtoFromJson(json);

@override final  ProviderModelDto model;

/// Create a copy of ProviderModelResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderModelResultDtoCopyWith<_ProviderModelResultDto> get copyWith => __$ProviderModelResultDtoCopyWithImpl<_ProviderModelResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderModelResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderModelResultDto&&(identical(other.model, model) || other.model == model));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,model);

@override
String toString() {
  return 'ProviderModelResultDto(model: $model)';
}


}

/// @nodoc
abstract mixin class _$ProviderModelResultDtoCopyWith<$Res> implements $ProviderModelResultDtoCopyWith<$Res> {
  factory _$ProviderModelResultDtoCopyWith(_ProviderModelResultDto value, $Res Function(_ProviderModelResultDto) _then) = __$ProviderModelResultDtoCopyWithImpl;
@override @useResult
$Res call({
 ProviderModelDto model
});


@override $ProviderModelDtoCopyWith<$Res> get model;

}
/// @nodoc
class __$ProviderModelResultDtoCopyWithImpl<$Res>
    implements _$ProviderModelResultDtoCopyWith<$Res> {
  __$ProviderModelResultDtoCopyWithImpl(this._self, this._then);

  final _ProviderModelResultDto _self;
  final $Res Function(_ProviderModelResultDto) _then;

/// Create a copy of ProviderModelResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? model = null,}) {
  return _then(_ProviderModelResultDto(
model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as ProviderModelDto,
  ));
}

/// Create a copy of ProviderModelResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderModelDtoCopyWith<$Res> get model {
  
  return $ProviderModelDtoCopyWith<$Res>(_self.model, (value) {
    return _then(_self.copyWith(model: value));
  });
}
}


/// @nodoc
mixin _$ProviderDiagnosticResultDto {

 ProviderDiagnosticDto get diagnostic;
/// Create a copy of ProviderDiagnosticResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderDiagnosticResultDtoCopyWith<ProviderDiagnosticResultDto> get copyWith => _$ProviderDiagnosticResultDtoCopyWithImpl<ProviderDiagnosticResultDto>(this as ProviderDiagnosticResultDto, _$identity);

  /// Serializes this ProviderDiagnosticResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderDiagnosticResultDto&&(identical(other.diagnostic, diagnostic) || other.diagnostic == diagnostic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,diagnostic);

@override
String toString() {
  return 'ProviderDiagnosticResultDto(diagnostic: $diagnostic)';
}


}

/// @nodoc
abstract mixin class $ProviderDiagnosticResultDtoCopyWith<$Res>  {
  factory $ProviderDiagnosticResultDtoCopyWith(ProviderDiagnosticResultDto value, $Res Function(ProviderDiagnosticResultDto) _then) = _$ProviderDiagnosticResultDtoCopyWithImpl;
@useResult
$Res call({
 ProviderDiagnosticDto diagnostic
});


$ProviderDiagnosticDtoCopyWith<$Res> get diagnostic;

}
/// @nodoc
class _$ProviderDiagnosticResultDtoCopyWithImpl<$Res>
    implements $ProviderDiagnosticResultDtoCopyWith<$Res> {
  _$ProviderDiagnosticResultDtoCopyWithImpl(this._self, this._then);

  final ProviderDiagnosticResultDto _self;
  final $Res Function(ProviderDiagnosticResultDto) _then;

/// Create a copy of ProviderDiagnosticResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? diagnostic = null,}) {
  return _then(_self.copyWith(
diagnostic: null == diagnostic ? _self.diagnostic : diagnostic // ignore: cast_nullable_to_non_nullable
as ProviderDiagnosticDto,
  ));
}
/// Create a copy of ProviderDiagnosticResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderDiagnosticDtoCopyWith<$Res> get diagnostic {
  
  return $ProviderDiagnosticDtoCopyWith<$Res>(_self.diagnostic, (value) {
    return _then(_self.copyWith(diagnostic: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProviderDiagnosticResultDto].
extension ProviderDiagnosticResultDtoPatterns on ProviderDiagnosticResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderDiagnosticResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderDiagnosticResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderDiagnosticResultDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderDiagnosticResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderDiagnosticResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderDiagnosticResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProviderDiagnosticDto diagnostic)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderDiagnosticResultDto() when $default != null:
return $default(_that.diagnostic);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProviderDiagnosticDto diagnostic)  $default,) {final _that = this;
switch (_that) {
case _ProviderDiagnosticResultDto():
return $default(_that.diagnostic);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProviderDiagnosticDto diagnostic)?  $default,) {final _that = this;
switch (_that) {
case _ProviderDiagnosticResultDto() when $default != null:
return $default(_that.diagnostic);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderDiagnosticResultDto implements ProviderDiagnosticResultDto {
  const _ProviderDiagnosticResultDto({required this.diagnostic});
  factory _ProviderDiagnosticResultDto.fromJson(Map<String, dynamic> json) => _$ProviderDiagnosticResultDtoFromJson(json);

@override final  ProviderDiagnosticDto diagnostic;

/// Create a copy of ProviderDiagnosticResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderDiagnosticResultDtoCopyWith<_ProviderDiagnosticResultDto> get copyWith => __$ProviderDiagnosticResultDtoCopyWithImpl<_ProviderDiagnosticResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderDiagnosticResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderDiagnosticResultDto&&(identical(other.diagnostic, diagnostic) || other.diagnostic == diagnostic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,diagnostic);

@override
String toString() {
  return 'ProviderDiagnosticResultDto(diagnostic: $diagnostic)';
}


}

/// @nodoc
abstract mixin class _$ProviderDiagnosticResultDtoCopyWith<$Res> implements $ProviderDiagnosticResultDtoCopyWith<$Res> {
  factory _$ProviderDiagnosticResultDtoCopyWith(_ProviderDiagnosticResultDto value, $Res Function(_ProviderDiagnosticResultDto) _then) = __$ProviderDiagnosticResultDtoCopyWithImpl;
@override @useResult
$Res call({
 ProviderDiagnosticDto diagnostic
});


@override $ProviderDiagnosticDtoCopyWith<$Res> get diagnostic;

}
/// @nodoc
class __$ProviderDiagnosticResultDtoCopyWithImpl<$Res>
    implements _$ProviderDiagnosticResultDtoCopyWith<$Res> {
  __$ProviderDiagnosticResultDtoCopyWithImpl(this._self, this._then);

  final _ProviderDiagnosticResultDto _self;
  final $Res Function(_ProviderDiagnosticResultDto) _then;

/// Create a copy of ProviderDiagnosticResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? diagnostic = null,}) {
  return _then(_ProviderDiagnosticResultDto(
diagnostic: null == diagnostic ? _self.diagnostic : diagnostic // ignore: cast_nullable_to_non_nullable
as ProviderDiagnosticDto,
  ));
}

/// Create a copy of ProviderDiagnosticResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderDiagnosticDtoCopyWith<$Res> get diagnostic {
  
  return $ProviderDiagnosticDtoCopyWith<$Res>(_self.diagnostic, (value) {
    return _then(_self.copyWith(diagnostic: value));
  });
}
}


/// @nodoc
mixin _$TurnStartResultDto {

 bool get created;
/// Create a copy of TurnStartResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TurnStartResultDtoCopyWith<TurnStartResultDto> get copyWith => _$TurnStartResultDtoCopyWithImpl<TurnStartResultDto>(this as TurnStartResultDto, _$identity);

  /// Serializes this TurnStartResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TurnStartResultDto&&(identical(other.created, created) || other.created == created));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,created);

@override
String toString() {
  return 'TurnStartResultDto(created: $created)';
}


}

/// @nodoc
abstract mixin class $TurnStartResultDtoCopyWith<$Res>  {
  factory $TurnStartResultDtoCopyWith(TurnStartResultDto value, $Res Function(TurnStartResultDto) _then) = _$TurnStartResultDtoCopyWithImpl;
@useResult
$Res call({
 bool created
});




}
/// @nodoc
class _$TurnStartResultDtoCopyWithImpl<$Res>
    implements $TurnStartResultDtoCopyWith<$Res> {
  _$TurnStartResultDtoCopyWithImpl(this._self, this._then);

  final TurnStartResultDto _self;
  final $Res Function(TurnStartResultDto) _then;

/// Create a copy of TurnStartResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? created = null,}) {
  return _then(_self.copyWith(
created: null == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TurnStartResultDto].
extension TurnStartResultDtoPatterns on TurnStartResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TurnStartResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TurnStartResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TurnStartResultDto value)  $default,){
final _that = this;
switch (_that) {
case _TurnStartResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TurnStartResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _TurnStartResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool created)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TurnStartResultDto() when $default != null:
return $default(_that.created);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool created)  $default,) {final _that = this;
switch (_that) {
case _TurnStartResultDto():
return $default(_that.created);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool created)?  $default,) {final _that = this;
switch (_that) {
case _TurnStartResultDto() when $default != null:
return $default(_that.created);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TurnStartResultDto implements TurnStartResultDto {
  const _TurnStartResultDto({required this.created});
  factory _TurnStartResultDto.fromJson(Map<String, dynamic> json) => _$TurnStartResultDtoFromJson(json);

@override final  bool created;

/// Create a copy of TurnStartResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TurnStartResultDtoCopyWith<_TurnStartResultDto> get copyWith => __$TurnStartResultDtoCopyWithImpl<_TurnStartResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TurnStartResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TurnStartResultDto&&(identical(other.created, created) || other.created == created));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,created);

@override
String toString() {
  return 'TurnStartResultDto(created: $created)';
}


}

/// @nodoc
abstract mixin class _$TurnStartResultDtoCopyWith<$Res> implements $TurnStartResultDtoCopyWith<$Res> {
  factory _$TurnStartResultDtoCopyWith(_TurnStartResultDto value, $Res Function(_TurnStartResultDto) _then) = __$TurnStartResultDtoCopyWithImpl;
@override @useResult
$Res call({
 bool created
});




}
/// @nodoc
class __$TurnStartResultDtoCopyWithImpl<$Res>
    implements _$TurnStartResultDtoCopyWith<$Res> {
  __$TurnStartResultDtoCopyWithImpl(this._self, this._then);

  final _TurnStartResultDto _self;
  final $Res Function(_TurnStartResultDto) _then;

/// Create a copy of TurnStartResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? created = null,}) {
  return _then(_TurnStartResultDto(
created: null == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ApprovalResultDto {

 ApprovalRequestDto get approval;
/// Create a copy of ApprovalResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApprovalResultDtoCopyWith<ApprovalResultDto> get copyWith => _$ApprovalResultDtoCopyWithImpl<ApprovalResultDto>(this as ApprovalResultDto, _$identity);

  /// Serializes this ApprovalResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApprovalResultDto&&(identical(other.approval, approval) || other.approval == approval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,approval);

@override
String toString() {
  return 'ApprovalResultDto(approval: $approval)';
}


}

/// @nodoc
abstract mixin class $ApprovalResultDtoCopyWith<$Res>  {
  factory $ApprovalResultDtoCopyWith(ApprovalResultDto value, $Res Function(ApprovalResultDto) _then) = _$ApprovalResultDtoCopyWithImpl;
@useResult
$Res call({
 ApprovalRequestDto approval
});


$ApprovalRequestDtoCopyWith<$Res> get approval;

}
/// @nodoc
class _$ApprovalResultDtoCopyWithImpl<$Res>
    implements $ApprovalResultDtoCopyWith<$Res> {
  _$ApprovalResultDtoCopyWithImpl(this._self, this._then);

  final ApprovalResultDto _self;
  final $Res Function(ApprovalResultDto) _then;

/// Create a copy of ApprovalResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? approval = null,}) {
  return _then(_self.copyWith(
approval: null == approval ? _self.approval : approval // ignore: cast_nullable_to_non_nullable
as ApprovalRequestDto,
  ));
}
/// Create a copy of ApprovalResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApprovalRequestDtoCopyWith<$Res> get approval {
  
  return $ApprovalRequestDtoCopyWith<$Res>(_self.approval, (value) {
    return _then(_self.copyWith(approval: value));
  });
}
}


/// Adds pattern-matching-related methods to [ApprovalResultDto].
extension ApprovalResultDtoPatterns on ApprovalResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApprovalResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApprovalResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApprovalResultDto value)  $default,){
final _that = this;
switch (_that) {
case _ApprovalResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApprovalResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _ApprovalResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ApprovalRequestDto approval)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApprovalResultDto() when $default != null:
return $default(_that.approval);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ApprovalRequestDto approval)  $default,) {final _that = this;
switch (_that) {
case _ApprovalResultDto():
return $default(_that.approval);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ApprovalRequestDto approval)?  $default,) {final _that = this;
switch (_that) {
case _ApprovalResultDto() when $default != null:
return $default(_that.approval);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApprovalResultDto implements ApprovalResultDto {
  const _ApprovalResultDto({required this.approval});
  factory _ApprovalResultDto.fromJson(Map<String, dynamic> json) => _$ApprovalResultDtoFromJson(json);

@override final  ApprovalRequestDto approval;

/// Create a copy of ApprovalResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApprovalResultDtoCopyWith<_ApprovalResultDto> get copyWith => __$ApprovalResultDtoCopyWithImpl<_ApprovalResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApprovalResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApprovalResultDto&&(identical(other.approval, approval) || other.approval == approval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,approval);

@override
String toString() {
  return 'ApprovalResultDto(approval: $approval)';
}


}

/// @nodoc
abstract mixin class _$ApprovalResultDtoCopyWith<$Res> implements $ApprovalResultDtoCopyWith<$Res> {
  factory _$ApprovalResultDtoCopyWith(_ApprovalResultDto value, $Res Function(_ApprovalResultDto) _then) = __$ApprovalResultDtoCopyWithImpl;
@override @useResult
$Res call({
 ApprovalRequestDto approval
});


@override $ApprovalRequestDtoCopyWith<$Res> get approval;

}
/// @nodoc
class __$ApprovalResultDtoCopyWithImpl<$Res>
    implements _$ApprovalResultDtoCopyWith<$Res> {
  __$ApprovalResultDtoCopyWithImpl(this._self, this._then);

  final _ApprovalResultDto _self;
  final $Res Function(_ApprovalResultDto) _then;

/// Create a copy of ApprovalResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? approval = null,}) {
  return _then(_ApprovalResultDto(
approval: null == approval ? _self.approval : approval // ignore: cast_nullable_to_non_nullable
as ApprovalRequestDto,
  ));
}

/// Create a copy of ApprovalResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApprovalRequestDtoCopyWith<$Res> get approval {
  
  return $ApprovalRequestDtoCopyWith<$Res>(_self.approval, (value) {
    return _then(_self.copyWith(approval: value));
  });
}
}


/// @nodoc
mixin _$TimelineResultDto {

 List<TimelineEventDto> get events;
/// Create a copy of TimelineResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimelineResultDtoCopyWith<TimelineResultDto> get copyWith => _$TimelineResultDtoCopyWithImpl<TimelineResultDto>(this as TimelineResultDto, _$identity);

  /// Serializes this TimelineResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimelineResultDto&&const DeepCollectionEquality().equals(other.events, events));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(events));

@override
String toString() {
  return 'TimelineResultDto(events: $events)';
}


}

/// @nodoc
abstract mixin class $TimelineResultDtoCopyWith<$Res>  {
  factory $TimelineResultDtoCopyWith(TimelineResultDto value, $Res Function(TimelineResultDto) _then) = _$TimelineResultDtoCopyWithImpl;
@useResult
$Res call({
 List<TimelineEventDto> events
});




}
/// @nodoc
class _$TimelineResultDtoCopyWithImpl<$Res>
    implements $TimelineResultDtoCopyWith<$Res> {
  _$TimelineResultDtoCopyWithImpl(this._self, this._then);

  final TimelineResultDto _self;
  final $Res Function(TimelineResultDto) _then;

/// Create a copy of TimelineResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? events = null,}) {
  return _then(_self.copyWith(
events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<TimelineEventDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [TimelineResultDto].
extension TimelineResultDtoPatterns on TimelineResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimelineResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimelineResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimelineResultDto value)  $default,){
final _that = this;
switch (_that) {
case _TimelineResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimelineResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _TimelineResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TimelineEventDto> events)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimelineResultDto() when $default != null:
return $default(_that.events);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TimelineEventDto> events)  $default,) {final _that = this;
switch (_that) {
case _TimelineResultDto():
return $default(_that.events);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TimelineEventDto> events)?  $default,) {final _that = this;
switch (_that) {
case _TimelineResultDto() when $default != null:
return $default(_that.events);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TimelineResultDto implements TimelineResultDto {
  const _TimelineResultDto({required final  List<TimelineEventDto> events}): _events = events;
  factory _TimelineResultDto.fromJson(Map<String, dynamic> json) => _$TimelineResultDtoFromJson(json);

 final  List<TimelineEventDto> _events;
@override List<TimelineEventDto> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}


/// Create a copy of TimelineResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimelineResultDtoCopyWith<_TimelineResultDto> get copyWith => __$TimelineResultDtoCopyWithImpl<_TimelineResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TimelineResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimelineResultDto&&const DeepCollectionEquality().equals(other._events, _events));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_events));

@override
String toString() {
  return 'TimelineResultDto(events: $events)';
}


}

/// @nodoc
abstract mixin class _$TimelineResultDtoCopyWith<$Res> implements $TimelineResultDtoCopyWith<$Res> {
  factory _$TimelineResultDtoCopyWith(_TimelineResultDto value, $Res Function(_TimelineResultDto) _then) = __$TimelineResultDtoCopyWithImpl;
@override @useResult
$Res call({
 List<TimelineEventDto> events
});




}
/// @nodoc
class __$TimelineResultDtoCopyWithImpl<$Res>
    implements _$TimelineResultDtoCopyWith<$Res> {
  __$TimelineResultDtoCopyWithImpl(this._self, this._then);

  final _TimelineResultDto _self;
  final $Res Function(_TimelineResultDto) _then;

/// Create a copy of TimelineResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? events = null,}) {
  return _then(_TimelineResultDto(
events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<TimelineEventDto>,
  ));
}


}

// dart format on
