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

 String get workspaceId; String get checkoutId; String get rootPath; String get name;
/// Create a copy of WorkspaceRegisterParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceRegisterParamsDtoCopyWith<WorkspaceRegisterParamsDto> get copyWith => _$WorkspaceRegisterParamsDtoCopyWithImpl<WorkspaceRegisterParamsDto>(this as WorkspaceRegisterParamsDto, _$identity);

  /// Serializes this WorkspaceRegisterParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceRegisterParamsDto&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.checkoutId, checkoutId) || other.checkoutId == checkoutId)&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workspaceId,checkoutId,rootPath,name);

@override
String toString() {
  return 'WorkspaceRegisterParamsDto(workspaceId: $workspaceId, checkoutId: $checkoutId, rootPath: $rootPath, name: $name)';
}


}

/// @nodoc
abstract mixin class $WorkspaceRegisterParamsDtoCopyWith<$Res>  {
  factory $WorkspaceRegisterParamsDtoCopyWith(WorkspaceRegisterParamsDto value, $Res Function(WorkspaceRegisterParamsDto) _then) = _$WorkspaceRegisterParamsDtoCopyWithImpl;
@useResult
$Res call({
 String workspaceId, String checkoutId, String rootPath, String name
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
@pragma('vm:prefer-inline') @override $Res call({Object? workspaceId = null,Object? checkoutId = null,Object? rootPath = null,Object? name = null,}) {
  return _then(_self.copyWith(
workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,checkoutId: null == checkoutId ? _self.checkoutId : checkoutId // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String workspaceId,  String checkoutId,  String rootPath,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceRegisterParamsDto() when $default != null:
return $default(_that.workspaceId,_that.checkoutId,_that.rootPath,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String workspaceId,  String checkoutId,  String rootPath,  String name)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceRegisterParamsDto():
return $default(_that.workspaceId,_that.checkoutId,_that.rootPath,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String workspaceId,  String checkoutId,  String rootPath,  String name)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceRegisterParamsDto() when $default != null:
return $default(_that.workspaceId,_that.checkoutId,_that.rootPath,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkspaceRegisterParamsDto implements WorkspaceRegisterParamsDto {
  const _WorkspaceRegisterParamsDto({required this.workspaceId, required this.checkoutId, required this.rootPath, required this.name});
  factory _WorkspaceRegisterParamsDto.fromJson(Map<String, dynamic> json) => _$WorkspaceRegisterParamsDtoFromJson(json);

@override final  String workspaceId;
@override final  String checkoutId;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceRegisterParamsDto&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.checkoutId, checkoutId) || other.checkoutId == checkoutId)&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workspaceId,checkoutId,rootPath,name);

@override
String toString() {
  return 'WorkspaceRegisterParamsDto(workspaceId: $workspaceId, checkoutId: $checkoutId, rootPath: $rootPath, name: $name)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceRegisterParamsDtoCopyWith<$Res> implements $WorkspaceRegisterParamsDtoCopyWith<$Res> {
  factory _$WorkspaceRegisterParamsDtoCopyWith(_WorkspaceRegisterParamsDto value, $Res Function(_WorkspaceRegisterParamsDto) _then) = __$WorkspaceRegisterParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String workspaceId, String checkoutId, String rootPath, String name
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
@override @pragma('vm:prefer-inline') $Res call({Object? workspaceId = null,Object? checkoutId = null,Object? rootPath = null,Object? name = null,}) {
  return _then(_WorkspaceRegisterParamsDto(
workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,checkoutId: null == checkoutId ? _self.checkoutId : checkoutId // ignore: cast_nullable_to_non_nullable
as String,rootPath: null == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WorkspaceIdParamsDto {

 String get workspaceId;
/// Create a copy of WorkspaceIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceIdParamsDtoCopyWith<WorkspaceIdParamsDto> get copyWith => _$WorkspaceIdParamsDtoCopyWithImpl<WorkspaceIdParamsDto>(this as WorkspaceIdParamsDto, _$identity);

  /// Serializes this WorkspaceIdParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceIdParamsDto&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workspaceId);

@override
String toString() {
  return 'WorkspaceIdParamsDto(workspaceId: $workspaceId)';
}


}

/// @nodoc
abstract mixin class $WorkspaceIdParamsDtoCopyWith<$Res>  {
  factory $WorkspaceIdParamsDtoCopyWith(WorkspaceIdParamsDto value, $Res Function(WorkspaceIdParamsDto) _then) = _$WorkspaceIdParamsDtoCopyWithImpl;
@useResult
$Res call({
 String workspaceId
});




}
/// @nodoc
class _$WorkspaceIdParamsDtoCopyWithImpl<$Res>
    implements $WorkspaceIdParamsDtoCopyWith<$Res> {
  _$WorkspaceIdParamsDtoCopyWithImpl(this._self, this._then);

  final WorkspaceIdParamsDto _self;
  final $Res Function(WorkspaceIdParamsDto) _then;

/// Create a copy of WorkspaceIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workspaceId = null,}) {
  return _then(_self.copyWith(
workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkspaceIdParamsDto].
extension WorkspaceIdParamsDtoPatterns on WorkspaceIdParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceIdParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceIdParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceIdParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceIdParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceIdParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceIdParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String workspaceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceIdParamsDto() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String workspaceId)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceIdParamsDto():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String workspaceId)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceIdParamsDto() when $default != null:
return $default(_that.workspaceId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkspaceIdParamsDto implements WorkspaceIdParamsDto {
  const _WorkspaceIdParamsDto({required this.workspaceId});
  factory _WorkspaceIdParamsDto.fromJson(Map<String, dynamic> json) => _$WorkspaceIdParamsDtoFromJson(json);

@override final  String workspaceId;

/// Create a copy of WorkspaceIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceIdParamsDtoCopyWith<_WorkspaceIdParamsDto> get copyWith => __$WorkspaceIdParamsDtoCopyWithImpl<_WorkspaceIdParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkspaceIdParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceIdParamsDto&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workspaceId);

@override
String toString() {
  return 'WorkspaceIdParamsDto(workspaceId: $workspaceId)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceIdParamsDtoCopyWith<$Res> implements $WorkspaceIdParamsDtoCopyWith<$Res> {
  factory _$WorkspaceIdParamsDtoCopyWith(_WorkspaceIdParamsDto value, $Res Function(_WorkspaceIdParamsDto) _then) = __$WorkspaceIdParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String workspaceId
});




}
/// @nodoc
class __$WorkspaceIdParamsDtoCopyWithImpl<$Res>
    implements _$WorkspaceIdParamsDtoCopyWith<$Res> {
  __$WorkspaceIdParamsDtoCopyWithImpl(this._self, this._then);

  final _WorkspaceIdParamsDto _self;
  final $Res Function(_WorkspaceIdParamsDto) _then;

/// Create a copy of WorkspaceIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workspaceId = null,}) {
  return _then(_WorkspaceIdParamsDto(
workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DirectorySuggestParamsDto {

 String get query; int get limit;
/// Create a copy of DirectorySuggestParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DirectorySuggestParamsDtoCopyWith<DirectorySuggestParamsDto> get copyWith => _$DirectorySuggestParamsDtoCopyWithImpl<DirectorySuggestParamsDto>(this as DirectorySuggestParamsDto, _$identity);

  /// Serializes this DirectorySuggestParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DirectorySuggestParamsDto&&(identical(other.query, query) || other.query == query)&&(identical(other.limit, limit) || other.limit == limit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,limit);

@override
String toString() {
  return 'DirectorySuggestParamsDto(query: $query, limit: $limit)';
}


}

/// @nodoc
abstract mixin class $DirectorySuggestParamsDtoCopyWith<$Res>  {
  factory $DirectorySuggestParamsDtoCopyWith(DirectorySuggestParamsDto value, $Res Function(DirectorySuggestParamsDto) _then) = _$DirectorySuggestParamsDtoCopyWithImpl;
@useResult
$Res call({
 String query, int limit
});




}
/// @nodoc
class _$DirectorySuggestParamsDtoCopyWithImpl<$Res>
    implements $DirectorySuggestParamsDtoCopyWith<$Res> {
  _$DirectorySuggestParamsDtoCopyWithImpl(this._self, this._then);

  final DirectorySuggestParamsDto _self;
  final $Res Function(DirectorySuggestParamsDto) _then;

/// Create a copy of DirectorySuggestParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? limit = null,}) {
  return _then(_self.copyWith(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DirectorySuggestParamsDto].
extension DirectorySuggestParamsDtoPatterns on DirectorySuggestParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DirectorySuggestParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DirectorySuggestParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DirectorySuggestParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _DirectorySuggestParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DirectorySuggestParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _DirectorySuggestParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  int limit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DirectorySuggestParamsDto() when $default != null:
return $default(_that.query,_that.limit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  int limit)  $default,) {final _that = this;
switch (_that) {
case _DirectorySuggestParamsDto():
return $default(_that.query,_that.limit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  int limit)?  $default,) {final _that = this;
switch (_that) {
case _DirectorySuggestParamsDto() when $default != null:
return $default(_that.query,_that.limit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DirectorySuggestParamsDto implements DirectorySuggestParamsDto {
  const _DirectorySuggestParamsDto({required this.query, this.limit = 30});
  factory _DirectorySuggestParamsDto.fromJson(Map<String, dynamic> json) => _$DirectorySuggestParamsDtoFromJson(json);

@override final  String query;
@override@JsonKey() final  int limit;

/// Create a copy of DirectorySuggestParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DirectorySuggestParamsDtoCopyWith<_DirectorySuggestParamsDto> get copyWith => __$DirectorySuggestParamsDtoCopyWithImpl<_DirectorySuggestParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DirectorySuggestParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DirectorySuggestParamsDto&&(identical(other.query, query) || other.query == query)&&(identical(other.limit, limit) || other.limit == limit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,limit);

@override
String toString() {
  return 'DirectorySuggestParamsDto(query: $query, limit: $limit)';
}


}

/// @nodoc
abstract mixin class _$DirectorySuggestParamsDtoCopyWith<$Res> implements $DirectorySuggestParamsDtoCopyWith<$Res> {
  factory _$DirectorySuggestParamsDtoCopyWith(_DirectorySuggestParamsDto value, $Res Function(_DirectorySuggestParamsDto) _then) = __$DirectorySuggestParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String query, int limit
});




}
/// @nodoc
class __$DirectorySuggestParamsDtoCopyWithImpl<$Res>
    implements _$DirectorySuggestParamsDtoCopyWith<$Res> {
  __$DirectorySuggestParamsDtoCopyWithImpl(this._self, this._then);

  final _DirectorySuggestParamsDto _self;
  final $Res Function(_DirectorySuggestParamsDto) _then;

/// Create a copy of DirectorySuggestParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? limit = null,}) {
  return _then(_DirectorySuggestParamsDto(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$GitBranchesListParamsDto {

 String get workspaceId;
/// Create a copy of GitBranchesListParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitBranchesListParamsDtoCopyWith<GitBranchesListParamsDto> get copyWith => _$GitBranchesListParamsDtoCopyWithImpl<GitBranchesListParamsDto>(this as GitBranchesListParamsDto, _$identity);

  /// Serializes this GitBranchesListParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitBranchesListParamsDto&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workspaceId);

@override
String toString() {
  return 'GitBranchesListParamsDto(workspaceId: $workspaceId)';
}


}

/// @nodoc
abstract mixin class $GitBranchesListParamsDtoCopyWith<$Res>  {
  factory $GitBranchesListParamsDtoCopyWith(GitBranchesListParamsDto value, $Res Function(GitBranchesListParamsDto) _then) = _$GitBranchesListParamsDtoCopyWithImpl;
@useResult
$Res call({
 String workspaceId
});




}
/// @nodoc
class _$GitBranchesListParamsDtoCopyWithImpl<$Res>
    implements $GitBranchesListParamsDtoCopyWith<$Res> {
  _$GitBranchesListParamsDtoCopyWithImpl(this._self, this._then);

  final GitBranchesListParamsDto _self;
  final $Res Function(GitBranchesListParamsDto) _then;

/// Create a copy of GitBranchesListParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workspaceId = null,}) {
  return _then(_self.copyWith(
workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GitBranchesListParamsDto].
extension GitBranchesListParamsDtoPatterns on GitBranchesListParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitBranchesListParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitBranchesListParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitBranchesListParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _GitBranchesListParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitBranchesListParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _GitBranchesListParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String workspaceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitBranchesListParamsDto() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String workspaceId)  $default,) {final _that = this;
switch (_that) {
case _GitBranchesListParamsDto():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String workspaceId)?  $default,) {final _that = this;
switch (_that) {
case _GitBranchesListParamsDto() when $default != null:
return $default(_that.workspaceId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GitBranchesListParamsDto implements GitBranchesListParamsDto {
  const _GitBranchesListParamsDto({required this.workspaceId});
  factory _GitBranchesListParamsDto.fromJson(Map<String, dynamic> json) => _$GitBranchesListParamsDtoFromJson(json);

@override final  String workspaceId;

/// Create a copy of GitBranchesListParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitBranchesListParamsDtoCopyWith<_GitBranchesListParamsDto> get copyWith => __$GitBranchesListParamsDtoCopyWithImpl<_GitBranchesListParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GitBranchesListParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitBranchesListParamsDto&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workspaceId);

@override
String toString() {
  return 'GitBranchesListParamsDto(workspaceId: $workspaceId)';
}


}

/// @nodoc
abstract mixin class _$GitBranchesListParamsDtoCopyWith<$Res> implements $GitBranchesListParamsDtoCopyWith<$Res> {
  factory _$GitBranchesListParamsDtoCopyWith(_GitBranchesListParamsDto value, $Res Function(_GitBranchesListParamsDto) _then) = __$GitBranchesListParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String workspaceId
});




}
/// @nodoc
class __$GitBranchesListParamsDtoCopyWithImpl<$Res>
    implements _$GitBranchesListParamsDtoCopyWith<$Res> {
  __$GitBranchesListParamsDtoCopyWithImpl(this._self, this._then);

  final _GitBranchesListParamsDto _self;
  final $Res Function(_GitBranchesListParamsDto) _then;

/// Create a copy of GitBranchesListParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workspaceId = null,}) {
  return _then(_GitBranchesListParamsDto(
workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WorktreeCreateParamsDto {

 String get id; String get workspaceId; WorktreeCreateMode get mode; String get branchName; String? get baseBranch;
/// Create a copy of WorktreeCreateParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorktreeCreateParamsDtoCopyWith<WorktreeCreateParamsDto> get copyWith => _$WorktreeCreateParamsDtoCopyWithImpl<WorktreeCreateParamsDto>(this as WorktreeCreateParamsDto, _$identity);

  /// Serializes this WorktreeCreateParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorktreeCreateParamsDto&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.branchName, branchName) || other.branchName == branchName)&&(identical(other.baseBranch, baseBranch) || other.baseBranch == baseBranch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,mode,branchName,baseBranch);

@override
String toString() {
  return 'WorktreeCreateParamsDto(id: $id, workspaceId: $workspaceId, mode: $mode, branchName: $branchName, baseBranch: $baseBranch)';
}


}

/// @nodoc
abstract mixin class $WorktreeCreateParamsDtoCopyWith<$Res>  {
  factory $WorktreeCreateParamsDtoCopyWith(WorktreeCreateParamsDto value, $Res Function(WorktreeCreateParamsDto) _then) = _$WorktreeCreateParamsDtoCopyWithImpl;
@useResult
$Res call({
 String id, String workspaceId, WorktreeCreateMode mode, String branchName, String? baseBranch
});




}
/// @nodoc
class _$WorktreeCreateParamsDtoCopyWithImpl<$Res>
    implements $WorktreeCreateParamsDtoCopyWith<$Res> {
  _$WorktreeCreateParamsDtoCopyWithImpl(this._self, this._then);

  final WorktreeCreateParamsDto _self;
  final $Res Function(WorktreeCreateParamsDto) _then;

/// Create a copy of WorktreeCreateParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workspaceId = null,Object? mode = null,Object? branchName = null,Object? baseBranch = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as WorktreeCreateMode,branchName: null == branchName ? _self.branchName : branchName // ignore: cast_nullable_to_non_nullable
as String,baseBranch: freezed == baseBranch ? _self.baseBranch : baseBranch // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorktreeCreateParamsDto].
extension WorktreeCreateParamsDtoPatterns on WorktreeCreateParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorktreeCreateParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorktreeCreateParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorktreeCreateParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _WorktreeCreateParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorktreeCreateParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _WorktreeCreateParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workspaceId,  WorktreeCreateMode mode,  String branchName,  String? baseBranch)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorktreeCreateParamsDto() when $default != null:
return $default(_that.id,_that.workspaceId,_that.mode,_that.branchName,_that.baseBranch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workspaceId,  WorktreeCreateMode mode,  String branchName,  String? baseBranch)  $default,) {final _that = this;
switch (_that) {
case _WorktreeCreateParamsDto():
return $default(_that.id,_that.workspaceId,_that.mode,_that.branchName,_that.baseBranch);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workspaceId,  WorktreeCreateMode mode,  String branchName,  String? baseBranch)?  $default,) {final _that = this;
switch (_that) {
case _WorktreeCreateParamsDto() when $default != null:
return $default(_that.id,_that.workspaceId,_that.mode,_that.branchName,_that.baseBranch);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorktreeCreateParamsDto implements WorktreeCreateParamsDto {
  const _WorktreeCreateParamsDto({required this.id, required this.workspaceId, required this.mode, required this.branchName, this.baseBranch});
  factory _WorktreeCreateParamsDto.fromJson(Map<String, dynamic> json) => _$WorktreeCreateParamsDtoFromJson(json);

@override final  String id;
@override final  String workspaceId;
@override final  WorktreeCreateMode mode;
@override final  String branchName;
@override final  String? baseBranch;

/// Create a copy of WorktreeCreateParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorktreeCreateParamsDtoCopyWith<_WorktreeCreateParamsDto> get copyWith => __$WorktreeCreateParamsDtoCopyWithImpl<_WorktreeCreateParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorktreeCreateParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorktreeCreateParamsDto&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.branchName, branchName) || other.branchName == branchName)&&(identical(other.baseBranch, baseBranch) || other.baseBranch == baseBranch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,mode,branchName,baseBranch);

@override
String toString() {
  return 'WorktreeCreateParamsDto(id: $id, workspaceId: $workspaceId, mode: $mode, branchName: $branchName, baseBranch: $baseBranch)';
}


}

/// @nodoc
abstract mixin class _$WorktreeCreateParamsDtoCopyWith<$Res> implements $WorktreeCreateParamsDtoCopyWith<$Res> {
  factory _$WorktreeCreateParamsDtoCopyWith(_WorktreeCreateParamsDto value, $Res Function(_WorktreeCreateParamsDto) _then) = __$WorktreeCreateParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String workspaceId, WorktreeCreateMode mode, String branchName, String? baseBranch
});




}
/// @nodoc
class __$WorktreeCreateParamsDtoCopyWithImpl<$Res>
    implements _$WorktreeCreateParamsDtoCopyWith<$Res> {
  __$WorktreeCreateParamsDtoCopyWithImpl(this._self, this._then);

  final _WorktreeCreateParamsDto _self;
  final $Res Function(_WorktreeCreateParamsDto) _then;

/// Create a copy of WorktreeCreateParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workspaceId = null,Object? mode = null,Object? branchName = null,Object? baseBranch = freezed,}) {
  return _then(_WorktreeCreateParamsDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as WorktreeCreateMode,branchName: null == branchName ? _self.branchName : branchName // ignore: cast_nullable_to_non_nullable
as String,baseBranch: freezed == baseBranch ? _self.baseBranch : baseBranch // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$WorktreeIdParamsDto {

 String get worktreeId;
/// Create a copy of WorktreeIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorktreeIdParamsDtoCopyWith<WorktreeIdParamsDto> get copyWith => _$WorktreeIdParamsDtoCopyWithImpl<WorktreeIdParamsDto>(this as WorktreeIdParamsDto, _$identity);

  /// Serializes this WorktreeIdParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorktreeIdParamsDto&&(identical(other.worktreeId, worktreeId) || other.worktreeId == worktreeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,worktreeId);

@override
String toString() {
  return 'WorktreeIdParamsDto(worktreeId: $worktreeId)';
}


}

/// @nodoc
abstract mixin class $WorktreeIdParamsDtoCopyWith<$Res>  {
  factory $WorktreeIdParamsDtoCopyWith(WorktreeIdParamsDto value, $Res Function(WorktreeIdParamsDto) _then) = _$WorktreeIdParamsDtoCopyWithImpl;
@useResult
$Res call({
 String worktreeId
});




}
/// @nodoc
class _$WorktreeIdParamsDtoCopyWithImpl<$Res>
    implements $WorktreeIdParamsDtoCopyWith<$Res> {
  _$WorktreeIdParamsDtoCopyWithImpl(this._self, this._then);

  final WorktreeIdParamsDto _self;
  final $Res Function(WorktreeIdParamsDto) _then;

/// Create a copy of WorktreeIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? worktreeId = null,}) {
  return _then(_self.copyWith(
worktreeId: null == worktreeId ? _self.worktreeId : worktreeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WorktreeIdParamsDto].
extension WorktreeIdParamsDtoPatterns on WorktreeIdParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorktreeIdParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorktreeIdParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorktreeIdParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _WorktreeIdParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorktreeIdParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _WorktreeIdParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String worktreeId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorktreeIdParamsDto() when $default != null:
return $default(_that.worktreeId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String worktreeId)  $default,) {final _that = this;
switch (_that) {
case _WorktreeIdParamsDto():
return $default(_that.worktreeId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String worktreeId)?  $default,) {final _that = this;
switch (_that) {
case _WorktreeIdParamsDto() when $default != null:
return $default(_that.worktreeId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorktreeIdParamsDto implements WorktreeIdParamsDto {
  const _WorktreeIdParamsDto({required this.worktreeId});
  factory _WorktreeIdParamsDto.fromJson(Map<String, dynamic> json) => _$WorktreeIdParamsDtoFromJson(json);

@override final  String worktreeId;

/// Create a copy of WorktreeIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorktreeIdParamsDtoCopyWith<_WorktreeIdParamsDto> get copyWith => __$WorktreeIdParamsDtoCopyWithImpl<_WorktreeIdParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorktreeIdParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorktreeIdParamsDto&&(identical(other.worktreeId, worktreeId) || other.worktreeId == worktreeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,worktreeId);

@override
String toString() {
  return 'WorktreeIdParamsDto(worktreeId: $worktreeId)';
}


}

/// @nodoc
abstract mixin class _$WorktreeIdParamsDtoCopyWith<$Res> implements $WorktreeIdParamsDtoCopyWith<$Res> {
  factory _$WorktreeIdParamsDtoCopyWith(_WorktreeIdParamsDto value, $Res Function(_WorktreeIdParamsDto) _then) = __$WorktreeIdParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String worktreeId
});




}
/// @nodoc
class __$WorktreeIdParamsDtoCopyWithImpl<$Res>
    implements _$WorktreeIdParamsDtoCopyWith<$Res> {
  __$WorktreeIdParamsDtoCopyWithImpl(this._self, this._then);

  final _WorktreeIdParamsDto _self;
  final $Res Function(_WorktreeIdParamsDto) _then;

/// Create a copy of WorktreeIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? worktreeId = null,}) {
  return _then(_WorktreeIdParamsDto(
worktreeId: null == worktreeId ? _self.worktreeId : worktreeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WorktreeArchiveParamsDto {

 String get worktreeId; bool get force;
/// Create a copy of WorktreeArchiveParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorktreeArchiveParamsDtoCopyWith<WorktreeArchiveParamsDto> get copyWith => _$WorktreeArchiveParamsDtoCopyWithImpl<WorktreeArchiveParamsDto>(this as WorktreeArchiveParamsDto, _$identity);

  /// Serializes this WorktreeArchiveParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorktreeArchiveParamsDto&&(identical(other.worktreeId, worktreeId) || other.worktreeId == worktreeId)&&(identical(other.force, force) || other.force == force));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,worktreeId,force);

@override
String toString() {
  return 'WorktreeArchiveParamsDto(worktreeId: $worktreeId, force: $force)';
}


}

/// @nodoc
abstract mixin class $WorktreeArchiveParamsDtoCopyWith<$Res>  {
  factory $WorktreeArchiveParamsDtoCopyWith(WorktreeArchiveParamsDto value, $Res Function(WorktreeArchiveParamsDto) _then) = _$WorktreeArchiveParamsDtoCopyWithImpl;
@useResult
$Res call({
 String worktreeId, bool force
});




}
/// @nodoc
class _$WorktreeArchiveParamsDtoCopyWithImpl<$Res>
    implements $WorktreeArchiveParamsDtoCopyWith<$Res> {
  _$WorktreeArchiveParamsDtoCopyWithImpl(this._self, this._then);

  final WorktreeArchiveParamsDto _self;
  final $Res Function(WorktreeArchiveParamsDto) _then;

/// Create a copy of WorktreeArchiveParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? worktreeId = null,Object? force = null,}) {
  return _then(_self.copyWith(
worktreeId: null == worktreeId ? _self.worktreeId : worktreeId // ignore: cast_nullable_to_non_nullable
as String,force: null == force ? _self.force : force // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WorktreeArchiveParamsDto].
extension WorktreeArchiveParamsDtoPatterns on WorktreeArchiveParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorktreeArchiveParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorktreeArchiveParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorktreeArchiveParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _WorktreeArchiveParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorktreeArchiveParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _WorktreeArchiveParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String worktreeId,  bool force)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorktreeArchiveParamsDto() when $default != null:
return $default(_that.worktreeId,_that.force);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String worktreeId,  bool force)  $default,) {final _that = this;
switch (_that) {
case _WorktreeArchiveParamsDto():
return $default(_that.worktreeId,_that.force);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String worktreeId,  bool force)?  $default,) {final _that = this;
switch (_that) {
case _WorktreeArchiveParamsDto() when $default != null:
return $default(_that.worktreeId,_that.force);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorktreeArchiveParamsDto implements WorktreeArchiveParamsDto {
  const _WorktreeArchiveParamsDto({required this.worktreeId, required this.force});
  factory _WorktreeArchiveParamsDto.fromJson(Map<String, dynamic> json) => _$WorktreeArchiveParamsDtoFromJson(json);

@override final  String worktreeId;
@override final  bool force;

/// Create a copy of WorktreeArchiveParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorktreeArchiveParamsDtoCopyWith<_WorktreeArchiveParamsDto> get copyWith => __$WorktreeArchiveParamsDtoCopyWithImpl<_WorktreeArchiveParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorktreeArchiveParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorktreeArchiveParamsDto&&(identical(other.worktreeId, worktreeId) || other.worktreeId == worktreeId)&&(identical(other.force, force) || other.force == force));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,worktreeId,force);

@override
String toString() {
  return 'WorktreeArchiveParamsDto(worktreeId: $worktreeId, force: $force)';
}


}

/// @nodoc
abstract mixin class _$WorktreeArchiveParamsDtoCopyWith<$Res> implements $WorktreeArchiveParamsDtoCopyWith<$Res> {
  factory _$WorktreeArchiveParamsDtoCopyWith(_WorktreeArchiveParamsDto value, $Res Function(_WorktreeArchiveParamsDto) _then) = __$WorktreeArchiveParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String worktreeId, bool force
});




}
/// @nodoc
class __$WorktreeArchiveParamsDtoCopyWithImpl<$Res>
    implements _$WorktreeArchiveParamsDtoCopyWith<$Res> {
  __$WorktreeArchiveParamsDtoCopyWithImpl(this._self, this._then);

  final _WorktreeArchiveParamsDto _self;
  final $Res Function(_WorktreeArchiveParamsDto) _then;

/// Create a copy of WorktreeArchiveParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? worktreeId = null,Object? force = null,}) {
  return _then(_WorktreeArchiveParamsDto(
worktreeId: null == worktreeId ? _self.worktreeId : worktreeId // ignore: cast_nullable_to_non_nullable
as String,force: null == force ? _self.force : force // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$AgentListParamsDto {

 String? get worktreeId;
/// Create a copy of AgentListParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentListParamsDtoCopyWith<AgentListParamsDto> get copyWith => _$AgentListParamsDtoCopyWithImpl<AgentListParamsDto>(this as AgentListParamsDto, _$identity);

  /// Serializes this AgentListParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentListParamsDto&&(identical(other.worktreeId, worktreeId) || other.worktreeId == worktreeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,worktreeId);

@override
String toString() {
  return 'AgentListParamsDto(worktreeId: $worktreeId)';
}


}

/// @nodoc
abstract mixin class $AgentListParamsDtoCopyWith<$Res>  {
  factory $AgentListParamsDtoCopyWith(AgentListParamsDto value, $Res Function(AgentListParamsDto) _then) = _$AgentListParamsDtoCopyWithImpl;
@useResult
$Res call({
 String? worktreeId
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
@pragma('vm:prefer-inline') @override $Res call({Object? worktreeId = freezed,}) {
  return _then(_self.copyWith(
worktreeId: freezed == worktreeId ? _self.worktreeId : worktreeId // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? worktreeId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentListParamsDto() when $default != null:
return $default(_that.worktreeId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? worktreeId)  $default,) {final _that = this;
switch (_that) {
case _AgentListParamsDto():
return $default(_that.worktreeId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? worktreeId)?  $default,) {final _that = this;
switch (_that) {
case _AgentListParamsDto() when $default != null:
return $default(_that.worktreeId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentListParamsDto implements AgentListParamsDto {
  const _AgentListParamsDto({this.worktreeId});
  factory _AgentListParamsDto.fromJson(Map<String, dynamic> json) => _$AgentListParamsDtoFromJson(json);

@override final  String? worktreeId;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentListParamsDto&&(identical(other.worktreeId, worktreeId) || other.worktreeId == worktreeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,worktreeId);

@override
String toString() {
  return 'AgentListParamsDto(worktreeId: $worktreeId)';
}


}

/// @nodoc
abstract mixin class _$AgentListParamsDtoCopyWith<$Res> implements $AgentListParamsDtoCopyWith<$Res> {
  factory _$AgentListParamsDtoCopyWith(_AgentListParamsDto value, $Res Function(_AgentListParamsDto) _then) = __$AgentListParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String? worktreeId
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
@override @pragma('vm:prefer-inline') $Res call({Object? worktreeId = freezed,}) {
  return _then(_AgentListParamsDto(
worktreeId: freezed == worktreeId ? _self.worktreeId : worktreeId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AgentCreateParamsDto {

 String get id; String get worktreeId; String get title; String get providerConnectionId; String get model; String get reasoningEffort; PermissionMode get permissionMode;
/// Create a copy of AgentCreateParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentCreateParamsDtoCopyWith<AgentCreateParamsDto> get copyWith => _$AgentCreateParamsDtoCopyWithImpl<AgentCreateParamsDto>(this as AgentCreateParamsDto, _$identity);

  /// Serializes this AgentCreateParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentCreateParamsDto&&(identical(other.id, id) || other.id == id)&&(identical(other.worktreeId, worktreeId) || other.worktreeId == worktreeId)&&(identical(other.title, title) || other.title == title)&&(identical(other.providerConnectionId, providerConnectionId) || other.providerConnectionId == providerConnectionId)&&(identical(other.model, model) || other.model == model)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort)&&(identical(other.permissionMode, permissionMode) || other.permissionMode == permissionMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,worktreeId,title,providerConnectionId,model,reasoningEffort,permissionMode);

@override
String toString() {
  return 'AgentCreateParamsDto(id: $id, worktreeId: $worktreeId, title: $title, providerConnectionId: $providerConnectionId, model: $model, reasoningEffort: $reasoningEffort, permissionMode: $permissionMode)';
}


}

/// @nodoc
abstract mixin class $AgentCreateParamsDtoCopyWith<$Res>  {
  factory $AgentCreateParamsDtoCopyWith(AgentCreateParamsDto value, $Res Function(AgentCreateParamsDto) _then) = _$AgentCreateParamsDtoCopyWithImpl;
@useResult
$Res call({
 String id, String worktreeId, String title, String providerConnectionId, String model, String reasoningEffort, PermissionMode permissionMode
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? worktreeId = null,Object? title = null,Object? providerConnectionId = null,Object? model = null,Object? reasoningEffort = null,Object? permissionMode = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,worktreeId: null == worktreeId ? _self.worktreeId : worktreeId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,providerConnectionId: null == providerConnectionId ? _self.providerConnectionId : providerConnectionId // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String worktreeId,  String title,  String providerConnectionId,  String model,  String reasoningEffort,  PermissionMode permissionMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentCreateParamsDto() when $default != null:
return $default(_that.id,_that.worktreeId,_that.title,_that.providerConnectionId,_that.model,_that.reasoningEffort,_that.permissionMode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String worktreeId,  String title,  String providerConnectionId,  String model,  String reasoningEffort,  PermissionMode permissionMode)  $default,) {final _that = this;
switch (_that) {
case _AgentCreateParamsDto():
return $default(_that.id,_that.worktreeId,_that.title,_that.providerConnectionId,_that.model,_that.reasoningEffort,_that.permissionMode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String worktreeId,  String title,  String providerConnectionId,  String model,  String reasoningEffort,  PermissionMode permissionMode)?  $default,) {final _that = this;
switch (_that) {
case _AgentCreateParamsDto() when $default != null:
return $default(_that.id,_that.worktreeId,_that.title,_that.providerConnectionId,_that.model,_that.reasoningEffort,_that.permissionMode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentCreateParamsDto implements AgentCreateParamsDto {
  const _AgentCreateParamsDto({required this.id, required this.worktreeId, required this.title, required this.providerConnectionId, required this.model, required this.reasoningEffort, required this.permissionMode});
  factory _AgentCreateParamsDto.fromJson(Map<String, dynamic> json) => _$AgentCreateParamsDtoFromJson(json);

@override final  String id;
@override final  String worktreeId;
@override final  String title;
@override final  String providerConnectionId;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentCreateParamsDto&&(identical(other.id, id) || other.id == id)&&(identical(other.worktreeId, worktreeId) || other.worktreeId == worktreeId)&&(identical(other.title, title) || other.title == title)&&(identical(other.providerConnectionId, providerConnectionId) || other.providerConnectionId == providerConnectionId)&&(identical(other.model, model) || other.model == model)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort)&&(identical(other.permissionMode, permissionMode) || other.permissionMode == permissionMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,worktreeId,title,providerConnectionId,model,reasoningEffort,permissionMode);

@override
String toString() {
  return 'AgentCreateParamsDto(id: $id, worktreeId: $worktreeId, title: $title, providerConnectionId: $providerConnectionId, model: $model, reasoningEffort: $reasoningEffort, permissionMode: $permissionMode)';
}


}

/// @nodoc
abstract mixin class _$AgentCreateParamsDtoCopyWith<$Res> implements $AgentCreateParamsDtoCopyWith<$Res> {
  factory _$AgentCreateParamsDtoCopyWith(_AgentCreateParamsDto value, $Res Function(_AgentCreateParamsDto) _then) = __$AgentCreateParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String worktreeId, String title, String providerConnectionId, String model, String reasoningEffort, PermissionMode permissionMode
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? worktreeId = null,Object? title = null,Object? providerConnectionId = null,Object? model = null,Object? reasoningEffort = null,Object? permissionMode = null,}) {
  return _then(_AgentCreateParamsDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,worktreeId: null == worktreeId ? _self.worktreeId : worktreeId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,providerConnectionId: null == providerConnectionId ? _self.providerConnectionId : providerConnectionId // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,reasoningEffort: null == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as String,permissionMode: null == permissionMode ? _self.permissionMode : permissionMode // ignore: cast_nullable_to_non_nullable
as PermissionMode,
  ));
}


}


/// @nodoc
mixin _$AgentConfigurationUpdateParamsDto {

 String get agentId; String get providerConnectionId; String get model; String get reasoningEffort;
/// Create a copy of AgentConfigurationUpdateParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentConfigurationUpdateParamsDtoCopyWith<AgentConfigurationUpdateParamsDto> get copyWith => _$AgentConfigurationUpdateParamsDtoCopyWithImpl<AgentConfigurationUpdateParamsDto>(this as AgentConfigurationUpdateParamsDto, _$identity);

  /// Serializes this AgentConfigurationUpdateParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentConfigurationUpdateParamsDto&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.providerConnectionId, providerConnectionId) || other.providerConnectionId == providerConnectionId)&&(identical(other.model, model) || other.model == model)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,agentId,providerConnectionId,model,reasoningEffort);

@override
String toString() {
  return 'AgentConfigurationUpdateParamsDto(agentId: $agentId, providerConnectionId: $providerConnectionId, model: $model, reasoningEffort: $reasoningEffort)';
}


}

/// @nodoc
abstract mixin class $AgentConfigurationUpdateParamsDtoCopyWith<$Res>  {
  factory $AgentConfigurationUpdateParamsDtoCopyWith(AgentConfigurationUpdateParamsDto value, $Res Function(AgentConfigurationUpdateParamsDto) _then) = _$AgentConfigurationUpdateParamsDtoCopyWithImpl;
@useResult
$Res call({
 String agentId, String providerConnectionId, String model, String reasoningEffort
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
@pragma('vm:prefer-inline') @override $Res call({Object? agentId = null,Object? providerConnectionId = null,Object? model = null,Object? reasoningEffort = null,}) {
  return _then(_self.copyWith(
agentId: null == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String,providerConnectionId: null == providerConnectionId ? _self.providerConnectionId : providerConnectionId // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String agentId,  String providerConnectionId,  String model,  String reasoningEffort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentConfigurationUpdateParamsDto() when $default != null:
return $default(_that.agentId,_that.providerConnectionId,_that.model,_that.reasoningEffort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String agentId,  String providerConnectionId,  String model,  String reasoningEffort)  $default,) {final _that = this;
switch (_that) {
case _AgentConfigurationUpdateParamsDto():
return $default(_that.agentId,_that.providerConnectionId,_that.model,_that.reasoningEffort);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String agentId,  String providerConnectionId,  String model,  String reasoningEffort)?  $default,) {final _that = this;
switch (_that) {
case _AgentConfigurationUpdateParamsDto() when $default != null:
return $default(_that.agentId,_that.providerConnectionId,_that.model,_that.reasoningEffort);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentConfigurationUpdateParamsDto implements AgentConfigurationUpdateParamsDto {
  const _AgentConfigurationUpdateParamsDto({required this.agentId, required this.providerConnectionId, required this.model, required this.reasoningEffort});
  factory _AgentConfigurationUpdateParamsDto.fromJson(Map<String, dynamic> json) => _$AgentConfigurationUpdateParamsDtoFromJson(json);

@override final  String agentId;
@override final  String providerConnectionId;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentConfigurationUpdateParamsDto&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.providerConnectionId, providerConnectionId) || other.providerConnectionId == providerConnectionId)&&(identical(other.model, model) || other.model == model)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,agentId,providerConnectionId,model,reasoningEffort);

@override
String toString() {
  return 'AgentConfigurationUpdateParamsDto(agentId: $agentId, providerConnectionId: $providerConnectionId, model: $model, reasoningEffort: $reasoningEffort)';
}


}

/// @nodoc
abstract mixin class _$AgentConfigurationUpdateParamsDtoCopyWith<$Res> implements $AgentConfigurationUpdateParamsDtoCopyWith<$Res> {
  factory _$AgentConfigurationUpdateParamsDtoCopyWith(_AgentConfigurationUpdateParamsDto value, $Res Function(_AgentConfigurationUpdateParamsDto) _then) = __$AgentConfigurationUpdateParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String agentId, String providerConnectionId, String model, String reasoningEffort
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
@override @pragma('vm:prefer-inline') $Res call({Object? agentId = null,Object? providerConnectionId = null,Object? model = null,Object? reasoningEffort = null,}) {
  return _then(_AgentConfigurationUpdateParamsDto(
agentId: null == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String,providerConnectionId: null == providerConnectionId ? _self.providerConnectionId : providerConnectionId // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,reasoningEffort: null == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProviderConnectApiKeyParamsDto {

 String get definitionId; String get apiKey; bool get makeDefault;
/// Create a copy of ProviderConnectApiKeyParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderConnectApiKeyParamsDtoCopyWith<ProviderConnectApiKeyParamsDto> get copyWith => _$ProviderConnectApiKeyParamsDtoCopyWithImpl<ProviderConnectApiKeyParamsDto>(this as ProviderConnectApiKeyParamsDto, _$identity);

  /// Serializes this ProviderConnectApiKeyParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderConnectApiKeyParamsDto&&(identical(other.definitionId, definitionId) || other.definitionId == definitionId)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey)&&(identical(other.makeDefault, makeDefault) || other.makeDefault == makeDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,definitionId,apiKey,makeDefault);

@override
String toString() {
  return 'ProviderConnectApiKeyParamsDto(definitionId: $definitionId, apiKey: $apiKey, makeDefault: $makeDefault)';
}


}

/// @nodoc
abstract mixin class $ProviderConnectApiKeyParamsDtoCopyWith<$Res>  {
  factory $ProviderConnectApiKeyParamsDtoCopyWith(ProviderConnectApiKeyParamsDto value, $Res Function(ProviderConnectApiKeyParamsDto) _then) = _$ProviderConnectApiKeyParamsDtoCopyWithImpl;
@useResult
$Res call({
 String definitionId, String apiKey, bool makeDefault
});




}
/// @nodoc
class _$ProviderConnectApiKeyParamsDtoCopyWithImpl<$Res>
    implements $ProviderConnectApiKeyParamsDtoCopyWith<$Res> {
  _$ProviderConnectApiKeyParamsDtoCopyWithImpl(this._self, this._then);

  final ProviderConnectApiKeyParamsDto _self;
  final $Res Function(ProviderConnectApiKeyParamsDto) _then;

/// Create a copy of ProviderConnectApiKeyParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? definitionId = null,Object? apiKey = null,Object? makeDefault = null,}) {
  return _then(_self.copyWith(
definitionId: null == definitionId ? _self.definitionId : definitionId // ignore: cast_nullable_to_non_nullable
as String,apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,makeDefault: null == makeDefault ? _self.makeDefault : makeDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderConnectApiKeyParamsDto].
extension ProviderConnectApiKeyParamsDtoPatterns on ProviderConnectApiKeyParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderConnectApiKeyParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderConnectApiKeyParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderConnectApiKeyParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderConnectApiKeyParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderConnectApiKeyParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderConnectApiKeyParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String definitionId,  String apiKey,  bool makeDefault)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderConnectApiKeyParamsDto() when $default != null:
return $default(_that.definitionId,_that.apiKey,_that.makeDefault);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String definitionId,  String apiKey,  bool makeDefault)  $default,) {final _that = this;
switch (_that) {
case _ProviderConnectApiKeyParamsDto():
return $default(_that.definitionId,_that.apiKey,_that.makeDefault);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String definitionId,  String apiKey,  bool makeDefault)?  $default,) {final _that = this;
switch (_that) {
case _ProviderConnectApiKeyParamsDto() when $default != null:
return $default(_that.definitionId,_that.apiKey,_that.makeDefault);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderConnectApiKeyParamsDto implements ProviderConnectApiKeyParamsDto {
  const _ProviderConnectApiKeyParamsDto({required this.definitionId, required this.apiKey, required this.makeDefault});
  factory _ProviderConnectApiKeyParamsDto.fromJson(Map<String, dynamic> json) => _$ProviderConnectApiKeyParamsDtoFromJson(json);

@override final  String definitionId;
@override final  String apiKey;
@override final  bool makeDefault;

/// Create a copy of ProviderConnectApiKeyParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderConnectApiKeyParamsDtoCopyWith<_ProviderConnectApiKeyParamsDto> get copyWith => __$ProviderConnectApiKeyParamsDtoCopyWithImpl<_ProviderConnectApiKeyParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderConnectApiKeyParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderConnectApiKeyParamsDto&&(identical(other.definitionId, definitionId) || other.definitionId == definitionId)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey)&&(identical(other.makeDefault, makeDefault) || other.makeDefault == makeDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,definitionId,apiKey,makeDefault);

@override
String toString() {
  return 'ProviderConnectApiKeyParamsDto(definitionId: $definitionId, apiKey: $apiKey, makeDefault: $makeDefault)';
}


}

/// @nodoc
abstract mixin class _$ProviderConnectApiKeyParamsDtoCopyWith<$Res> implements $ProviderConnectApiKeyParamsDtoCopyWith<$Res> {
  factory _$ProviderConnectApiKeyParamsDtoCopyWith(_ProviderConnectApiKeyParamsDto value, $Res Function(_ProviderConnectApiKeyParamsDto) _then) = __$ProviderConnectApiKeyParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String definitionId, String apiKey, bool makeDefault
});




}
/// @nodoc
class __$ProviderConnectApiKeyParamsDtoCopyWithImpl<$Res>
    implements _$ProviderConnectApiKeyParamsDtoCopyWith<$Res> {
  __$ProviderConnectApiKeyParamsDtoCopyWithImpl(this._self, this._then);

  final _ProviderConnectApiKeyParamsDto _self;
  final $Res Function(_ProviderConnectApiKeyParamsDto) _then;

/// Create a copy of ProviderConnectApiKeyParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? definitionId = null,Object? apiKey = null,Object? makeDefault = null,}) {
  return _then(_ProviderConnectApiKeyParamsDto(
definitionId: null == definitionId ? _self.definitionId : definitionId // ignore: cast_nullable_to_non_nullable
as String,apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,makeDefault: null == makeDefault ? _self.makeDefault : makeDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ProviderConnectNoneParamsDto {

 String get definitionId; bool get makeDefault;
/// Create a copy of ProviderConnectNoneParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderConnectNoneParamsDtoCopyWith<ProviderConnectNoneParamsDto> get copyWith => _$ProviderConnectNoneParamsDtoCopyWithImpl<ProviderConnectNoneParamsDto>(this as ProviderConnectNoneParamsDto, _$identity);

  /// Serializes this ProviderConnectNoneParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderConnectNoneParamsDto&&(identical(other.definitionId, definitionId) || other.definitionId == definitionId)&&(identical(other.makeDefault, makeDefault) || other.makeDefault == makeDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,definitionId,makeDefault);

@override
String toString() {
  return 'ProviderConnectNoneParamsDto(definitionId: $definitionId, makeDefault: $makeDefault)';
}


}

/// @nodoc
abstract mixin class $ProviderConnectNoneParamsDtoCopyWith<$Res>  {
  factory $ProviderConnectNoneParamsDtoCopyWith(ProviderConnectNoneParamsDto value, $Res Function(ProviderConnectNoneParamsDto) _then) = _$ProviderConnectNoneParamsDtoCopyWithImpl;
@useResult
$Res call({
 String definitionId, bool makeDefault
});




}
/// @nodoc
class _$ProviderConnectNoneParamsDtoCopyWithImpl<$Res>
    implements $ProviderConnectNoneParamsDtoCopyWith<$Res> {
  _$ProviderConnectNoneParamsDtoCopyWithImpl(this._self, this._then);

  final ProviderConnectNoneParamsDto _self;
  final $Res Function(ProviderConnectNoneParamsDto) _then;

/// Create a copy of ProviderConnectNoneParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? definitionId = null,Object? makeDefault = null,}) {
  return _then(_self.copyWith(
definitionId: null == definitionId ? _self.definitionId : definitionId // ignore: cast_nullable_to_non_nullable
as String,makeDefault: null == makeDefault ? _self.makeDefault : makeDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderConnectNoneParamsDto].
extension ProviderConnectNoneParamsDtoPatterns on ProviderConnectNoneParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderConnectNoneParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderConnectNoneParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderConnectNoneParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderConnectNoneParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderConnectNoneParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderConnectNoneParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String definitionId,  bool makeDefault)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderConnectNoneParamsDto() when $default != null:
return $default(_that.definitionId,_that.makeDefault);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String definitionId,  bool makeDefault)  $default,) {final _that = this;
switch (_that) {
case _ProviderConnectNoneParamsDto():
return $default(_that.definitionId,_that.makeDefault);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String definitionId,  bool makeDefault)?  $default,) {final _that = this;
switch (_that) {
case _ProviderConnectNoneParamsDto() when $default != null:
return $default(_that.definitionId,_that.makeDefault);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderConnectNoneParamsDto implements ProviderConnectNoneParamsDto {
  const _ProviderConnectNoneParamsDto({required this.definitionId, required this.makeDefault});
  factory _ProviderConnectNoneParamsDto.fromJson(Map<String, dynamic> json) => _$ProviderConnectNoneParamsDtoFromJson(json);

@override final  String definitionId;
@override final  bool makeDefault;

/// Create a copy of ProviderConnectNoneParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderConnectNoneParamsDtoCopyWith<_ProviderConnectNoneParamsDto> get copyWith => __$ProviderConnectNoneParamsDtoCopyWithImpl<_ProviderConnectNoneParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderConnectNoneParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderConnectNoneParamsDto&&(identical(other.definitionId, definitionId) || other.definitionId == definitionId)&&(identical(other.makeDefault, makeDefault) || other.makeDefault == makeDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,definitionId,makeDefault);

@override
String toString() {
  return 'ProviderConnectNoneParamsDto(definitionId: $definitionId, makeDefault: $makeDefault)';
}


}

/// @nodoc
abstract mixin class _$ProviderConnectNoneParamsDtoCopyWith<$Res> implements $ProviderConnectNoneParamsDtoCopyWith<$Res> {
  factory _$ProviderConnectNoneParamsDtoCopyWith(_ProviderConnectNoneParamsDto value, $Res Function(_ProviderConnectNoneParamsDto) _then) = __$ProviderConnectNoneParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String definitionId, bool makeDefault
});




}
/// @nodoc
class __$ProviderConnectNoneParamsDtoCopyWithImpl<$Res>
    implements _$ProviderConnectNoneParamsDtoCopyWith<$Res> {
  __$ProviderConnectNoneParamsDtoCopyWithImpl(this._self, this._then);

  final _ProviderConnectNoneParamsDto _self;
  final $Res Function(_ProviderConnectNoneParamsDto) _then;

/// Create a copy of ProviderConnectNoneParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? definitionId = null,Object? makeDefault = null,}) {
  return _then(_ProviderConnectNoneParamsDto(
definitionId: null == definitionId ? _self.definitionId : definitionId // ignore: cast_nullable_to_non_nullable
as String,makeDefault: null == makeDefault ? _self.makeDefault : makeDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ProviderConnectionIdParamsDto {

 String get connectionId;
/// Create a copy of ProviderConnectionIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderConnectionIdParamsDtoCopyWith<ProviderConnectionIdParamsDto> get copyWith => _$ProviderConnectionIdParamsDtoCopyWithImpl<ProviderConnectionIdParamsDto>(this as ProviderConnectionIdParamsDto, _$identity);

  /// Serializes this ProviderConnectionIdParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderConnectionIdParamsDto&&(identical(other.connectionId, connectionId) || other.connectionId == connectionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connectionId);

@override
String toString() {
  return 'ProviderConnectionIdParamsDto(connectionId: $connectionId)';
}


}

/// @nodoc
abstract mixin class $ProviderConnectionIdParamsDtoCopyWith<$Res>  {
  factory $ProviderConnectionIdParamsDtoCopyWith(ProviderConnectionIdParamsDto value, $Res Function(ProviderConnectionIdParamsDto) _then) = _$ProviderConnectionIdParamsDtoCopyWithImpl;
@useResult
$Res call({
 String connectionId
});




}
/// @nodoc
class _$ProviderConnectionIdParamsDtoCopyWithImpl<$Res>
    implements $ProviderConnectionIdParamsDtoCopyWith<$Res> {
  _$ProviderConnectionIdParamsDtoCopyWithImpl(this._self, this._then);

  final ProviderConnectionIdParamsDto _self;
  final $Res Function(ProviderConnectionIdParamsDto) _then;

/// Create a copy of ProviderConnectionIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? connectionId = null,}) {
  return _then(_self.copyWith(
connectionId: null == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderConnectionIdParamsDto].
extension ProviderConnectionIdParamsDtoPatterns on ProviderConnectionIdParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderConnectionIdParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderConnectionIdParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderConnectionIdParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderConnectionIdParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderConnectionIdParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderConnectionIdParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String connectionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderConnectionIdParamsDto() when $default != null:
return $default(_that.connectionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String connectionId)  $default,) {final _that = this;
switch (_that) {
case _ProviderConnectionIdParamsDto():
return $default(_that.connectionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String connectionId)?  $default,) {final _that = this;
switch (_that) {
case _ProviderConnectionIdParamsDto() when $default != null:
return $default(_that.connectionId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderConnectionIdParamsDto implements ProviderConnectionIdParamsDto {
  const _ProviderConnectionIdParamsDto({required this.connectionId});
  factory _ProviderConnectionIdParamsDto.fromJson(Map<String, dynamic> json) => _$ProviderConnectionIdParamsDtoFromJson(json);

@override final  String connectionId;

/// Create a copy of ProviderConnectionIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderConnectionIdParamsDtoCopyWith<_ProviderConnectionIdParamsDto> get copyWith => __$ProviderConnectionIdParamsDtoCopyWithImpl<_ProviderConnectionIdParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderConnectionIdParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderConnectionIdParamsDto&&(identical(other.connectionId, connectionId) || other.connectionId == connectionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connectionId);

@override
String toString() {
  return 'ProviderConnectionIdParamsDto(connectionId: $connectionId)';
}


}

/// @nodoc
abstract mixin class _$ProviderConnectionIdParamsDtoCopyWith<$Res> implements $ProviderConnectionIdParamsDtoCopyWith<$Res> {
  factory _$ProviderConnectionIdParamsDtoCopyWith(_ProviderConnectionIdParamsDto value, $Res Function(_ProviderConnectionIdParamsDto) _then) = __$ProviderConnectionIdParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String connectionId
});




}
/// @nodoc
class __$ProviderConnectionIdParamsDtoCopyWithImpl<$Res>
    implements _$ProviderConnectionIdParamsDtoCopyWith<$Res> {
  __$ProviderConnectionIdParamsDtoCopyWithImpl(this._self, this._then);

  final _ProviderConnectionIdParamsDto _self;
  final $Res Function(_ProviderConnectionIdParamsDto) _then;

/// Create a copy of ProviderConnectionIdParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? connectionId = null,}) {
  return _then(_ProviderConnectionIdParamsDto(
connectionId: null == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProviderModelParamsDto {

 String get connectionId; String get modelId;
/// Create a copy of ProviderModelParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderModelParamsDtoCopyWith<ProviderModelParamsDto> get copyWith => _$ProviderModelParamsDtoCopyWithImpl<ProviderModelParamsDto>(this as ProviderModelParamsDto, _$identity);

  /// Serializes this ProviderModelParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderModelParamsDto&&(identical(other.connectionId, connectionId) || other.connectionId == connectionId)&&(identical(other.modelId, modelId) || other.modelId == modelId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connectionId,modelId);

@override
String toString() {
  return 'ProviderModelParamsDto(connectionId: $connectionId, modelId: $modelId)';
}


}

/// @nodoc
abstract mixin class $ProviderModelParamsDtoCopyWith<$Res>  {
  factory $ProviderModelParamsDtoCopyWith(ProviderModelParamsDto value, $Res Function(ProviderModelParamsDto) _then) = _$ProviderModelParamsDtoCopyWithImpl;
@useResult
$Res call({
 String connectionId, String modelId
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
@pragma('vm:prefer-inline') @override $Res call({Object? connectionId = null,Object? modelId = null,}) {
  return _then(_self.copyWith(
connectionId: null == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String connectionId,  String modelId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderModelParamsDto() when $default != null:
return $default(_that.connectionId,_that.modelId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String connectionId,  String modelId)  $default,) {final _that = this;
switch (_that) {
case _ProviderModelParamsDto():
return $default(_that.connectionId,_that.modelId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String connectionId,  String modelId)?  $default,) {final _that = this;
switch (_that) {
case _ProviderModelParamsDto() when $default != null:
return $default(_that.connectionId,_that.modelId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderModelParamsDto implements ProviderModelParamsDto {
  const _ProviderModelParamsDto({required this.connectionId, required this.modelId});
  factory _ProviderModelParamsDto.fromJson(Map<String, dynamic> json) => _$ProviderModelParamsDtoFromJson(json);

@override final  String connectionId;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderModelParamsDto&&(identical(other.connectionId, connectionId) || other.connectionId == connectionId)&&(identical(other.modelId, modelId) || other.modelId == modelId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connectionId,modelId);

@override
String toString() {
  return 'ProviderModelParamsDto(connectionId: $connectionId, modelId: $modelId)';
}


}

/// @nodoc
abstract mixin class _$ProviderModelParamsDtoCopyWith<$Res> implements $ProviderModelParamsDtoCopyWith<$Res> {
  factory _$ProviderModelParamsDtoCopyWith(_ProviderModelParamsDto value, $Res Function(_ProviderModelParamsDto) _then) = __$ProviderModelParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String connectionId, String modelId
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
@override @pragma('vm:prefer-inline') $Res call({Object? connectionId = null,Object? modelId = null,}) {
  return _then(_ProviderModelParamsDto(
connectionId: null == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProviderAuthStartParamsDto {

 String get definitionId; String get methodId; bool get makeDefault;
/// Create a copy of ProviderAuthStartParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderAuthStartParamsDtoCopyWith<ProviderAuthStartParamsDto> get copyWith => _$ProviderAuthStartParamsDtoCopyWithImpl<ProviderAuthStartParamsDto>(this as ProviderAuthStartParamsDto, _$identity);

  /// Serializes this ProviderAuthStartParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderAuthStartParamsDto&&(identical(other.definitionId, definitionId) || other.definitionId == definitionId)&&(identical(other.methodId, methodId) || other.methodId == methodId)&&(identical(other.makeDefault, makeDefault) || other.makeDefault == makeDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,definitionId,methodId,makeDefault);

@override
String toString() {
  return 'ProviderAuthStartParamsDto(definitionId: $definitionId, methodId: $methodId, makeDefault: $makeDefault)';
}


}

/// @nodoc
abstract mixin class $ProviderAuthStartParamsDtoCopyWith<$Res>  {
  factory $ProviderAuthStartParamsDtoCopyWith(ProviderAuthStartParamsDto value, $Res Function(ProviderAuthStartParamsDto) _then) = _$ProviderAuthStartParamsDtoCopyWithImpl;
@useResult
$Res call({
 String definitionId, String methodId, bool makeDefault
});




}
/// @nodoc
class _$ProviderAuthStartParamsDtoCopyWithImpl<$Res>
    implements $ProviderAuthStartParamsDtoCopyWith<$Res> {
  _$ProviderAuthStartParamsDtoCopyWithImpl(this._self, this._then);

  final ProviderAuthStartParamsDto _self;
  final $Res Function(ProviderAuthStartParamsDto) _then;

/// Create a copy of ProviderAuthStartParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? definitionId = null,Object? methodId = null,Object? makeDefault = null,}) {
  return _then(_self.copyWith(
definitionId: null == definitionId ? _self.definitionId : definitionId // ignore: cast_nullable_to_non_nullable
as String,methodId: null == methodId ? _self.methodId : methodId // ignore: cast_nullable_to_non_nullable
as String,makeDefault: null == makeDefault ? _self.makeDefault : makeDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderAuthStartParamsDto].
extension ProviderAuthStartParamsDtoPatterns on ProviderAuthStartParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderAuthStartParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderAuthStartParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderAuthStartParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderAuthStartParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderAuthStartParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderAuthStartParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String definitionId,  String methodId,  bool makeDefault)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderAuthStartParamsDto() when $default != null:
return $default(_that.definitionId,_that.methodId,_that.makeDefault);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String definitionId,  String methodId,  bool makeDefault)  $default,) {final _that = this;
switch (_that) {
case _ProviderAuthStartParamsDto():
return $default(_that.definitionId,_that.methodId,_that.makeDefault);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String definitionId,  String methodId,  bool makeDefault)?  $default,) {final _that = this;
switch (_that) {
case _ProviderAuthStartParamsDto() when $default != null:
return $default(_that.definitionId,_that.methodId,_that.makeDefault);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderAuthStartParamsDto implements ProviderAuthStartParamsDto {
  const _ProviderAuthStartParamsDto({required this.definitionId, required this.methodId, required this.makeDefault});
  factory _ProviderAuthStartParamsDto.fromJson(Map<String, dynamic> json) => _$ProviderAuthStartParamsDtoFromJson(json);

@override final  String definitionId;
@override final  String methodId;
@override final  bool makeDefault;

/// Create a copy of ProviderAuthStartParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderAuthStartParamsDtoCopyWith<_ProviderAuthStartParamsDto> get copyWith => __$ProviderAuthStartParamsDtoCopyWithImpl<_ProviderAuthStartParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderAuthStartParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderAuthStartParamsDto&&(identical(other.definitionId, definitionId) || other.definitionId == definitionId)&&(identical(other.methodId, methodId) || other.methodId == methodId)&&(identical(other.makeDefault, makeDefault) || other.makeDefault == makeDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,definitionId,methodId,makeDefault);

@override
String toString() {
  return 'ProviderAuthStartParamsDto(definitionId: $definitionId, methodId: $methodId, makeDefault: $makeDefault)';
}


}

/// @nodoc
abstract mixin class _$ProviderAuthStartParamsDtoCopyWith<$Res> implements $ProviderAuthStartParamsDtoCopyWith<$Res> {
  factory _$ProviderAuthStartParamsDtoCopyWith(_ProviderAuthStartParamsDto value, $Res Function(_ProviderAuthStartParamsDto) _then) = __$ProviderAuthStartParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String definitionId, String methodId, bool makeDefault
});




}
/// @nodoc
class __$ProviderAuthStartParamsDtoCopyWithImpl<$Res>
    implements _$ProviderAuthStartParamsDtoCopyWith<$Res> {
  __$ProviderAuthStartParamsDtoCopyWithImpl(this._self, this._then);

  final _ProviderAuthStartParamsDto _self;
  final $Res Function(_ProviderAuthStartParamsDto) _then;

/// Create a copy of ProviderAuthStartParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? definitionId = null,Object? methodId = null,Object? makeDefault = null,}) {
  return _then(_ProviderAuthStartParamsDto(
definitionId: null == definitionId ? _self.definitionId : definitionId // ignore: cast_nullable_to_non_nullable
as String,methodId: null == methodId ? _self.methodId : methodId // ignore: cast_nullable_to_non_nullable
as String,makeDefault: null == makeDefault ? _self.makeDefault : makeDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ProviderAuthAttemptParamsDto {

 String get attemptId;
/// Create a copy of ProviderAuthAttemptParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderAuthAttemptParamsDtoCopyWith<ProviderAuthAttemptParamsDto> get copyWith => _$ProviderAuthAttemptParamsDtoCopyWithImpl<ProviderAuthAttemptParamsDto>(this as ProviderAuthAttemptParamsDto, _$identity);

  /// Serializes this ProviderAuthAttemptParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderAuthAttemptParamsDto&&(identical(other.attemptId, attemptId) || other.attemptId == attemptId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attemptId);

@override
String toString() {
  return 'ProviderAuthAttemptParamsDto(attemptId: $attemptId)';
}


}

/// @nodoc
abstract mixin class $ProviderAuthAttemptParamsDtoCopyWith<$Res>  {
  factory $ProviderAuthAttemptParamsDtoCopyWith(ProviderAuthAttemptParamsDto value, $Res Function(ProviderAuthAttemptParamsDto) _then) = _$ProviderAuthAttemptParamsDtoCopyWithImpl;
@useResult
$Res call({
 String attemptId
});




}
/// @nodoc
class _$ProviderAuthAttemptParamsDtoCopyWithImpl<$Res>
    implements $ProviderAuthAttemptParamsDtoCopyWith<$Res> {
  _$ProviderAuthAttemptParamsDtoCopyWithImpl(this._self, this._then);

  final ProviderAuthAttemptParamsDto _self;
  final $Res Function(ProviderAuthAttemptParamsDto) _then;

/// Create a copy of ProviderAuthAttemptParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? attemptId = null,}) {
  return _then(_self.copyWith(
attemptId: null == attemptId ? _self.attemptId : attemptId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderAuthAttemptParamsDto].
extension ProviderAuthAttemptParamsDtoPatterns on ProviderAuthAttemptParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderAuthAttemptParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderAuthAttemptParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderAuthAttemptParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderAuthAttemptParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderAuthAttemptParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderAuthAttemptParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String attemptId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderAuthAttemptParamsDto() when $default != null:
return $default(_that.attemptId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String attemptId)  $default,) {final _that = this;
switch (_that) {
case _ProviderAuthAttemptParamsDto():
return $default(_that.attemptId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String attemptId)?  $default,) {final _that = this;
switch (_that) {
case _ProviderAuthAttemptParamsDto() when $default != null:
return $default(_that.attemptId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderAuthAttemptParamsDto implements ProviderAuthAttemptParamsDto {
  const _ProviderAuthAttemptParamsDto({required this.attemptId});
  factory _ProviderAuthAttemptParamsDto.fromJson(Map<String, dynamic> json) => _$ProviderAuthAttemptParamsDtoFromJson(json);

@override final  String attemptId;

/// Create a copy of ProviderAuthAttemptParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderAuthAttemptParamsDtoCopyWith<_ProviderAuthAttemptParamsDto> get copyWith => __$ProviderAuthAttemptParamsDtoCopyWithImpl<_ProviderAuthAttemptParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderAuthAttemptParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderAuthAttemptParamsDto&&(identical(other.attemptId, attemptId) || other.attemptId == attemptId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attemptId);

@override
String toString() {
  return 'ProviderAuthAttemptParamsDto(attemptId: $attemptId)';
}


}

/// @nodoc
abstract mixin class _$ProviderAuthAttemptParamsDtoCopyWith<$Res> implements $ProviderAuthAttemptParamsDtoCopyWith<$Res> {
  factory _$ProviderAuthAttemptParamsDtoCopyWith(_ProviderAuthAttemptParamsDto value, $Res Function(_ProviderAuthAttemptParamsDto) _then) = __$ProviderAuthAttemptParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String attemptId
});




}
/// @nodoc
class __$ProviderAuthAttemptParamsDtoCopyWithImpl<$Res>
    implements _$ProviderAuthAttemptParamsDtoCopyWith<$Res> {
  __$ProviderAuthAttemptParamsDtoCopyWithImpl(this._self, this._then);

  final _ProviderAuthAttemptParamsDto _self;
  final $Res Function(_ProviderAuthAttemptParamsDto) _then;

/// Create a copy of ProviderAuthAttemptParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? attemptId = null,}) {
  return _then(_ProviderAuthAttemptParamsDto(
attemptId: null == attemptId ? _self.attemptId : attemptId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProviderDefaultSetParamsDto {

 String get connectionId;
/// Create a copy of ProviderDefaultSetParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderDefaultSetParamsDtoCopyWith<ProviderDefaultSetParamsDto> get copyWith => _$ProviderDefaultSetParamsDtoCopyWithImpl<ProviderDefaultSetParamsDto>(this as ProviderDefaultSetParamsDto, _$identity);

  /// Serializes this ProviderDefaultSetParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderDefaultSetParamsDto&&(identical(other.connectionId, connectionId) || other.connectionId == connectionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connectionId);

@override
String toString() {
  return 'ProviderDefaultSetParamsDto(connectionId: $connectionId)';
}


}

/// @nodoc
abstract mixin class $ProviderDefaultSetParamsDtoCopyWith<$Res>  {
  factory $ProviderDefaultSetParamsDtoCopyWith(ProviderDefaultSetParamsDto value, $Res Function(ProviderDefaultSetParamsDto) _then) = _$ProviderDefaultSetParamsDtoCopyWithImpl;
@useResult
$Res call({
 String connectionId
});




}
/// @nodoc
class _$ProviderDefaultSetParamsDtoCopyWithImpl<$Res>
    implements $ProviderDefaultSetParamsDtoCopyWith<$Res> {
  _$ProviderDefaultSetParamsDtoCopyWithImpl(this._self, this._then);

  final ProviderDefaultSetParamsDto _self;
  final $Res Function(ProviderDefaultSetParamsDto) _then;

/// Create a copy of ProviderDefaultSetParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? connectionId = null,}) {
  return _then(_self.copyWith(
connectionId: null == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderDefaultSetParamsDto].
extension ProviderDefaultSetParamsDtoPatterns on ProviderDefaultSetParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderDefaultSetParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderDefaultSetParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderDefaultSetParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderDefaultSetParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderDefaultSetParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderDefaultSetParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String connectionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderDefaultSetParamsDto() when $default != null:
return $default(_that.connectionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String connectionId)  $default,) {final _that = this;
switch (_that) {
case _ProviderDefaultSetParamsDto():
return $default(_that.connectionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String connectionId)?  $default,) {final _that = this;
switch (_that) {
case _ProviderDefaultSetParamsDto() when $default != null:
return $default(_that.connectionId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderDefaultSetParamsDto implements ProviderDefaultSetParamsDto {
  const _ProviderDefaultSetParamsDto({required this.connectionId});
  factory _ProviderDefaultSetParamsDto.fromJson(Map<String, dynamic> json) => _$ProviderDefaultSetParamsDtoFromJson(json);

@override final  String connectionId;

/// Create a copy of ProviderDefaultSetParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderDefaultSetParamsDtoCopyWith<_ProviderDefaultSetParamsDto> get copyWith => __$ProviderDefaultSetParamsDtoCopyWithImpl<_ProviderDefaultSetParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderDefaultSetParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderDefaultSetParamsDto&&(identical(other.connectionId, connectionId) || other.connectionId == connectionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connectionId);

@override
String toString() {
  return 'ProviderDefaultSetParamsDto(connectionId: $connectionId)';
}


}

/// @nodoc
abstract mixin class _$ProviderDefaultSetParamsDtoCopyWith<$Res> implements $ProviderDefaultSetParamsDtoCopyWith<$Res> {
  factory _$ProviderDefaultSetParamsDtoCopyWith(_ProviderDefaultSetParamsDto value, $Res Function(_ProviderDefaultSetParamsDto) _then) = __$ProviderDefaultSetParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String connectionId
});




}
/// @nodoc
class __$ProviderDefaultSetParamsDtoCopyWithImpl<$Res>
    implements _$ProviderDefaultSetParamsDtoCopyWith<$Res> {
  __$ProviderDefaultSetParamsDtoCopyWithImpl(this._self, this._then);

  final _ProviderDefaultSetParamsDto _self;
  final $Res Function(_ProviderDefaultSetParamsDto) _then;

/// Create a copy of ProviderDefaultSetParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? connectionId = null,}) {
  return _then(_ProviderDefaultSetParamsDto(
connectionId: null == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProviderDefaultModelSetParamsDto {

 String get connectionId; String get modelId;
/// Create a copy of ProviderDefaultModelSetParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderDefaultModelSetParamsDtoCopyWith<ProviderDefaultModelSetParamsDto> get copyWith => _$ProviderDefaultModelSetParamsDtoCopyWithImpl<ProviderDefaultModelSetParamsDto>(this as ProviderDefaultModelSetParamsDto, _$identity);

  /// Serializes this ProviderDefaultModelSetParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderDefaultModelSetParamsDto&&(identical(other.connectionId, connectionId) || other.connectionId == connectionId)&&(identical(other.modelId, modelId) || other.modelId == modelId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connectionId,modelId);

@override
String toString() {
  return 'ProviderDefaultModelSetParamsDto(connectionId: $connectionId, modelId: $modelId)';
}


}

/// @nodoc
abstract mixin class $ProviderDefaultModelSetParamsDtoCopyWith<$Res>  {
  factory $ProviderDefaultModelSetParamsDtoCopyWith(ProviderDefaultModelSetParamsDto value, $Res Function(ProviderDefaultModelSetParamsDto) _then) = _$ProviderDefaultModelSetParamsDtoCopyWithImpl;
@useResult
$Res call({
 String connectionId, String modelId
});




}
/// @nodoc
class _$ProviderDefaultModelSetParamsDtoCopyWithImpl<$Res>
    implements $ProviderDefaultModelSetParamsDtoCopyWith<$Res> {
  _$ProviderDefaultModelSetParamsDtoCopyWithImpl(this._self, this._then);

  final ProviderDefaultModelSetParamsDto _self;
  final $Res Function(ProviderDefaultModelSetParamsDto) _then;

/// Create a copy of ProviderDefaultModelSetParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? connectionId = null,Object? modelId = null,}) {
  return _then(_self.copyWith(
connectionId: null == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderDefaultModelSetParamsDto].
extension ProviderDefaultModelSetParamsDtoPatterns on ProviderDefaultModelSetParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderDefaultModelSetParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderDefaultModelSetParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderDefaultModelSetParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderDefaultModelSetParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderDefaultModelSetParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderDefaultModelSetParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String connectionId,  String modelId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderDefaultModelSetParamsDto() when $default != null:
return $default(_that.connectionId,_that.modelId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String connectionId,  String modelId)  $default,) {final _that = this;
switch (_that) {
case _ProviderDefaultModelSetParamsDto():
return $default(_that.connectionId,_that.modelId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String connectionId,  String modelId)?  $default,) {final _that = this;
switch (_that) {
case _ProviderDefaultModelSetParamsDto() when $default != null:
return $default(_that.connectionId,_that.modelId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderDefaultModelSetParamsDto implements ProviderDefaultModelSetParamsDto {
  const _ProviderDefaultModelSetParamsDto({required this.connectionId, required this.modelId});
  factory _ProviderDefaultModelSetParamsDto.fromJson(Map<String, dynamic> json) => _$ProviderDefaultModelSetParamsDtoFromJson(json);

@override final  String connectionId;
@override final  String modelId;

/// Create a copy of ProviderDefaultModelSetParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderDefaultModelSetParamsDtoCopyWith<_ProviderDefaultModelSetParamsDto> get copyWith => __$ProviderDefaultModelSetParamsDtoCopyWithImpl<_ProviderDefaultModelSetParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderDefaultModelSetParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderDefaultModelSetParamsDto&&(identical(other.connectionId, connectionId) || other.connectionId == connectionId)&&(identical(other.modelId, modelId) || other.modelId == modelId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connectionId,modelId);

@override
String toString() {
  return 'ProviderDefaultModelSetParamsDto(connectionId: $connectionId, modelId: $modelId)';
}


}

/// @nodoc
abstract mixin class _$ProviderDefaultModelSetParamsDtoCopyWith<$Res> implements $ProviderDefaultModelSetParamsDtoCopyWith<$Res> {
  factory _$ProviderDefaultModelSetParamsDtoCopyWith(_ProviderDefaultModelSetParamsDto value, $Res Function(_ProviderDefaultModelSetParamsDto) _then) = __$ProviderDefaultModelSetParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String connectionId, String modelId
});




}
/// @nodoc
class __$ProviderDefaultModelSetParamsDtoCopyWithImpl<$Res>
    implements _$ProviderDefaultModelSetParamsDtoCopyWith<$Res> {
  __$ProviderDefaultModelSetParamsDtoCopyWithImpl(this._self, this._then);

  final _ProviderDefaultModelSetParamsDto _self;
  final $Res Function(_ProviderDefaultModelSetParamsDto) _then;

/// Create a copy of ProviderDefaultModelSetParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? connectionId = null,Object? modelId = null,}) {
  return _then(_ProviderDefaultModelSetParamsDto(
connectionId: null == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProviderCustomCreateParamsDto {

 String get id; CustomProviderConfigDto get config; bool get makeDefault; String? get apiKey;
/// Create a copy of ProviderCustomCreateParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderCustomCreateParamsDtoCopyWith<ProviderCustomCreateParamsDto> get copyWith => _$ProviderCustomCreateParamsDtoCopyWithImpl<ProviderCustomCreateParamsDto>(this as ProviderCustomCreateParamsDto, _$identity);

  /// Serializes this ProviderCustomCreateParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderCustomCreateParamsDto&&(identical(other.id, id) || other.id == id)&&(identical(other.config, config) || other.config == config)&&(identical(other.makeDefault, makeDefault) || other.makeDefault == makeDefault)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,config,makeDefault,apiKey);

@override
String toString() {
  return 'ProviderCustomCreateParamsDto(id: $id, config: $config, makeDefault: $makeDefault, apiKey: $apiKey)';
}


}

/// @nodoc
abstract mixin class $ProviderCustomCreateParamsDtoCopyWith<$Res>  {
  factory $ProviderCustomCreateParamsDtoCopyWith(ProviderCustomCreateParamsDto value, $Res Function(ProviderCustomCreateParamsDto) _then) = _$ProviderCustomCreateParamsDtoCopyWithImpl;
@useResult
$Res call({
 String id, CustomProviderConfigDto config, bool makeDefault, String? apiKey
});


$CustomProviderConfigDtoCopyWith<$Res> get config;

}
/// @nodoc
class _$ProviderCustomCreateParamsDtoCopyWithImpl<$Res>
    implements $ProviderCustomCreateParamsDtoCopyWith<$Res> {
  _$ProviderCustomCreateParamsDtoCopyWithImpl(this._self, this._then);

  final ProviderCustomCreateParamsDto _self;
  final $Res Function(ProviderCustomCreateParamsDto) _then;

/// Create a copy of ProviderCustomCreateParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? config = null,Object? makeDefault = null,Object? apiKey = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as CustomProviderConfigDto,makeDefault: null == makeDefault ? _self.makeDefault : makeDefault // ignore: cast_nullable_to_non_nullable
as bool,apiKey: freezed == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ProviderCustomCreateParamsDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomProviderConfigDtoCopyWith<$Res> get config {
  
  return $CustomProviderConfigDtoCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProviderCustomCreateParamsDto].
extension ProviderCustomCreateParamsDtoPatterns on ProviderCustomCreateParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderCustomCreateParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderCustomCreateParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderCustomCreateParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderCustomCreateParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderCustomCreateParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderCustomCreateParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  CustomProviderConfigDto config,  bool makeDefault,  String? apiKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderCustomCreateParamsDto() when $default != null:
return $default(_that.id,_that.config,_that.makeDefault,_that.apiKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  CustomProviderConfigDto config,  bool makeDefault,  String? apiKey)  $default,) {final _that = this;
switch (_that) {
case _ProviderCustomCreateParamsDto():
return $default(_that.id,_that.config,_that.makeDefault,_that.apiKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  CustomProviderConfigDto config,  bool makeDefault,  String? apiKey)?  $default,) {final _that = this;
switch (_that) {
case _ProviderCustomCreateParamsDto() when $default != null:
return $default(_that.id,_that.config,_that.makeDefault,_that.apiKey);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderCustomCreateParamsDto implements ProviderCustomCreateParamsDto {
  const _ProviderCustomCreateParamsDto({required this.id, required this.config, required this.makeDefault, this.apiKey});
  factory _ProviderCustomCreateParamsDto.fromJson(Map<String, dynamic> json) => _$ProviderCustomCreateParamsDtoFromJson(json);

@override final  String id;
@override final  CustomProviderConfigDto config;
@override final  bool makeDefault;
@override final  String? apiKey;

/// Create a copy of ProviderCustomCreateParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderCustomCreateParamsDtoCopyWith<_ProviderCustomCreateParamsDto> get copyWith => __$ProviderCustomCreateParamsDtoCopyWithImpl<_ProviderCustomCreateParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderCustomCreateParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderCustomCreateParamsDto&&(identical(other.id, id) || other.id == id)&&(identical(other.config, config) || other.config == config)&&(identical(other.makeDefault, makeDefault) || other.makeDefault == makeDefault)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,config,makeDefault,apiKey);

@override
String toString() {
  return 'ProviderCustomCreateParamsDto(id: $id, config: $config, makeDefault: $makeDefault, apiKey: $apiKey)';
}


}

/// @nodoc
abstract mixin class _$ProviderCustomCreateParamsDtoCopyWith<$Res> implements $ProviderCustomCreateParamsDtoCopyWith<$Res> {
  factory _$ProviderCustomCreateParamsDtoCopyWith(_ProviderCustomCreateParamsDto value, $Res Function(_ProviderCustomCreateParamsDto) _then) = __$ProviderCustomCreateParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, CustomProviderConfigDto config, bool makeDefault, String? apiKey
});


@override $CustomProviderConfigDtoCopyWith<$Res> get config;

}
/// @nodoc
class __$ProviderCustomCreateParamsDtoCopyWithImpl<$Res>
    implements _$ProviderCustomCreateParamsDtoCopyWith<$Res> {
  __$ProviderCustomCreateParamsDtoCopyWithImpl(this._self, this._then);

  final _ProviderCustomCreateParamsDto _self;
  final $Res Function(_ProviderCustomCreateParamsDto) _then;

/// Create a copy of ProviderCustomCreateParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? config = null,Object? makeDefault = null,Object? apiKey = freezed,}) {
  return _then(_ProviderCustomCreateParamsDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as CustomProviderConfigDto,makeDefault: null == makeDefault ? _self.makeDefault : makeDefault // ignore: cast_nullable_to_non_nullable
as bool,apiKey: freezed == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ProviderCustomCreateParamsDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomProviderConfigDtoCopyWith<$Res> get config {
  
  return $CustomProviderConfigDtoCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}


/// @nodoc
mixin _$ProviderCustomUpdateParamsDto {

 String get connectionId; CustomProviderConfigDto get config; String? get apiKey;
/// Create a copy of ProviderCustomUpdateParamsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderCustomUpdateParamsDtoCopyWith<ProviderCustomUpdateParamsDto> get copyWith => _$ProviderCustomUpdateParamsDtoCopyWithImpl<ProviderCustomUpdateParamsDto>(this as ProviderCustomUpdateParamsDto, _$identity);

  /// Serializes this ProviderCustomUpdateParamsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderCustomUpdateParamsDto&&(identical(other.connectionId, connectionId) || other.connectionId == connectionId)&&(identical(other.config, config) || other.config == config)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connectionId,config,apiKey);

@override
String toString() {
  return 'ProviderCustomUpdateParamsDto(connectionId: $connectionId, config: $config, apiKey: $apiKey)';
}


}

/// @nodoc
abstract mixin class $ProviderCustomUpdateParamsDtoCopyWith<$Res>  {
  factory $ProviderCustomUpdateParamsDtoCopyWith(ProviderCustomUpdateParamsDto value, $Res Function(ProviderCustomUpdateParamsDto) _then) = _$ProviderCustomUpdateParamsDtoCopyWithImpl;
@useResult
$Res call({
 String connectionId, CustomProviderConfigDto config, String? apiKey
});


$CustomProviderConfigDtoCopyWith<$Res> get config;

}
/// @nodoc
class _$ProviderCustomUpdateParamsDtoCopyWithImpl<$Res>
    implements $ProviderCustomUpdateParamsDtoCopyWith<$Res> {
  _$ProviderCustomUpdateParamsDtoCopyWithImpl(this._self, this._then);

  final ProviderCustomUpdateParamsDto _self;
  final $Res Function(ProviderCustomUpdateParamsDto) _then;

/// Create a copy of ProviderCustomUpdateParamsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? connectionId = null,Object? config = null,Object? apiKey = freezed,}) {
  return _then(_self.copyWith(
connectionId: null == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
as String,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as CustomProviderConfigDto,apiKey: freezed == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ProviderCustomUpdateParamsDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomProviderConfigDtoCopyWith<$Res> get config {
  
  return $CustomProviderConfigDtoCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProviderCustomUpdateParamsDto].
extension ProviderCustomUpdateParamsDtoPatterns on ProviderCustomUpdateParamsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderCustomUpdateParamsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderCustomUpdateParamsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderCustomUpdateParamsDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderCustomUpdateParamsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderCustomUpdateParamsDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderCustomUpdateParamsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String connectionId,  CustomProviderConfigDto config,  String? apiKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderCustomUpdateParamsDto() when $default != null:
return $default(_that.connectionId,_that.config,_that.apiKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String connectionId,  CustomProviderConfigDto config,  String? apiKey)  $default,) {final _that = this;
switch (_that) {
case _ProviderCustomUpdateParamsDto():
return $default(_that.connectionId,_that.config,_that.apiKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String connectionId,  CustomProviderConfigDto config,  String? apiKey)?  $default,) {final _that = this;
switch (_that) {
case _ProviderCustomUpdateParamsDto() when $default != null:
return $default(_that.connectionId,_that.config,_that.apiKey);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderCustomUpdateParamsDto implements ProviderCustomUpdateParamsDto {
  const _ProviderCustomUpdateParamsDto({required this.connectionId, required this.config, this.apiKey});
  factory _ProviderCustomUpdateParamsDto.fromJson(Map<String, dynamic> json) => _$ProviderCustomUpdateParamsDtoFromJson(json);

@override final  String connectionId;
@override final  CustomProviderConfigDto config;
@override final  String? apiKey;

/// Create a copy of ProviderCustomUpdateParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderCustomUpdateParamsDtoCopyWith<_ProviderCustomUpdateParamsDto> get copyWith => __$ProviderCustomUpdateParamsDtoCopyWithImpl<_ProviderCustomUpdateParamsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderCustomUpdateParamsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderCustomUpdateParamsDto&&(identical(other.connectionId, connectionId) || other.connectionId == connectionId)&&(identical(other.config, config) || other.config == config)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connectionId,config,apiKey);

@override
String toString() {
  return 'ProviderCustomUpdateParamsDto(connectionId: $connectionId, config: $config, apiKey: $apiKey)';
}


}

/// @nodoc
abstract mixin class _$ProviderCustomUpdateParamsDtoCopyWith<$Res> implements $ProviderCustomUpdateParamsDtoCopyWith<$Res> {
  factory _$ProviderCustomUpdateParamsDtoCopyWith(_ProviderCustomUpdateParamsDto value, $Res Function(_ProviderCustomUpdateParamsDto) _then) = __$ProviderCustomUpdateParamsDtoCopyWithImpl;
@override @useResult
$Res call({
 String connectionId, CustomProviderConfigDto config, String? apiKey
});


@override $CustomProviderConfigDtoCopyWith<$Res> get config;

}
/// @nodoc
class __$ProviderCustomUpdateParamsDtoCopyWithImpl<$Res>
    implements _$ProviderCustomUpdateParamsDtoCopyWith<$Res> {
  __$ProviderCustomUpdateParamsDtoCopyWithImpl(this._self, this._then);

  final _ProviderCustomUpdateParamsDto _self;
  final $Res Function(_ProviderCustomUpdateParamsDto) _then;

/// Create a copy of ProviderCustomUpdateParamsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? connectionId = null,Object? config = null,Object? apiKey = freezed,}) {
  return _then(_ProviderCustomUpdateParamsDto(
connectionId: null == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
as String,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as CustomProviderConfigDto,apiKey: freezed == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ProviderCustomUpdateParamsDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomProviderConfigDtoCopyWith<$Res> get config {
  
  return $CustomProviderConfigDtoCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
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
mixin _$WorkspaceCatalogResultDto {

 WorkspaceCatalogDto get catalog;
/// Create a copy of WorkspaceCatalogResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceCatalogResultDtoCopyWith<WorkspaceCatalogResultDto> get copyWith => _$WorkspaceCatalogResultDtoCopyWithImpl<WorkspaceCatalogResultDto>(this as WorkspaceCatalogResultDto, _$identity);

  /// Serializes this WorkspaceCatalogResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceCatalogResultDto&&(identical(other.catalog, catalog) || other.catalog == catalog));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,catalog);

@override
String toString() {
  return 'WorkspaceCatalogResultDto(catalog: $catalog)';
}


}

/// @nodoc
abstract mixin class $WorkspaceCatalogResultDtoCopyWith<$Res>  {
  factory $WorkspaceCatalogResultDtoCopyWith(WorkspaceCatalogResultDto value, $Res Function(WorkspaceCatalogResultDto) _then) = _$WorkspaceCatalogResultDtoCopyWithImpl;
@useResult
$Res call({
 WorkspaceCatalogDto catalog
});


$WorkspaceCatalogDtoCopyWith<$Res> get catalog;

}
/// @nodoc
class _$WorkspaceCatalogResultDtoCopyWithImpl<$Res>
    implements $WorkspaceCatalogResultDtoCopyWith<$Res> {
  _$WorkspaceCatalogResultDtoCopyWithImpl(this._self, this._then);

  final WorkspaceCatalogResultDto _self;
  final $Res Function(WorkspaceCatalogResultDto) _then;

/// Create a copy of WorkspaceCatalogResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? catalog = null,}) {
  return _then(_self.copyWith(
catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as WorkspaceCatalogDto,
  ));
}
/// Create a copy of WorkspaceCatalogResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkspaceCatalogDtoCopyWith<$Res> get catalog {
  
  return $WorkspaceCatalogDtoCopyWith<$Res>(_self.catalog, (value) {
    return _then(_self.copyWith(catalog: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorkspaceCatalogResultDto].
extension WorkspaceCatalogResultDtoPatterns on WorkspaceCatalogResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceCatalogResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceCatalogResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceCatalogResultDto value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceCatalogResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceCatalogResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceCatalogResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkspaceCatalogDto catalog)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceCatalogResultDto() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkspaceCatalogDto catalog)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceCatalogResultDto():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkspaceCatalogDto catalog)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceCatalogResultDto() when $default != null:
return $default(_that.catalog);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkspaceCatalogResultDto implements WorkspaceCatalogResultDto {
  const _WorkspaceCatalogResultDto({required this.catalog});
  factory _WorkspaceCatalogResultDto.fromJson(Map<String, dynamic> json) => _$WorkspaceCatalogResultDtoFromJson(json);

@override final  WorkspaceCatalogDto catalog;

/// Create a copy of WorkspaceCatalogResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceCatalogResultDtoCopyWith<_WorkspaceCatalogResultDto> get copyWith => __$WorkspaceCatalogResultDtoCopyWithImpl<_WorkspaceCatalogResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkspaceCatalogResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceCatalogResultDto&&(identical(other.catalog, catalog) || other.catalog == catalog));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,catalog);

@override
String toString() {
  return 'WorkspaceCatalogResultDto(catalog: $catalog)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceCatalogResultDtoCopyWith<$Res> implements $WorkspaceCatalogResultDtoCopyWith<$Res> {
  factory _$WorkspaceCatalogResultDtoCopyWith(_WorkspaceCatalogResultDto value, $Res Function(_WorkspaceCatalogResultDto) _then) = __$WorkspaceCatalogResultDtoCopyWithImpl;
@override @useResult
$Res call({
 WorkspaceCatalogDto catalog
});


@override $WorkspaceCatalogDtoCopyWith<$Res> get catalog;

}
/// @nodoc
class __$WorkspaceCatalogResultDtoCopyWithImpl<$Res>
    implements _$WorkspaceCatalogResultDtoCopyWith<$Res> {
  __$WorkspaceCatalogResultDtoCopyWithImpl(this._self, this._then);

  final _WorkspaceCatalogResultDto _self;
  final $Res Function(_WorkspaceCatalogResultDto) _then;

/// Create a copy of WorkspaceCatalogResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? catalog = null,}) {
  return _then(_WorkspaceCatalogResultDto(
catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as WorkspaceCatalogDto,
  ));
}

/// Create a copy of WorkspaceCatalogResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkspaceCatalogDtoCopyWith<$Res> get catalog {
  
  return $WorkspaceCatalogDtoCopyWith<$Res>(_self.catalog, (value) {
    return _then(_self.copyWith(catalog: value));
  });
}
}


/// @nodoc
mixin _$WorkspaceRegisterResultDto {

 WorkspaceDto get workspace; List<WorktreeDto> get worktrees;
/// Create a copy of WorkspaceRegisterResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceRegisterResultDtoCopyWith<WorkspaceRegisterResultDto> get copyWith => _$WorkspaceRegisterResultDtoCopyWithImpl<WorkspaceRegisterResultDto>(this as WorkspaceRegisterResultDto, _$identity);

  /// Serializes this WorkspaceRegisterResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceRegisterResultDto&&(identical(other.workspace, workspace) || other.workspace == workspace)&&const DeepCollectionEquality().equals(other.worktrees, worktrees));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workspace,const DeepCollectionEquality().hash(worktrees));

@override
String toString() {
  return 'WorkspaceRegisterResultDto(workspace: $workspace, worktrees: $worktrees)';
}


}

/// @nodoc
abstract mixin class $WorkspaceRegisterResultDtoCopyWith<$Res>  {
  factory $WorkspaceRegisterResultDtoCopyWith(WorkspaceRegisterResultDto value, $Res Function(WorkspaceRegisterResultDto) _then) = _$WorkspaceRegisterResultDtoCopyWithImpl;
@useResult
$Res call({
 WorkspaceDto workspace, List<WorktreeDto> worktrees
});


$WorkspaceDtoCopyWith<$Res> get workspace;

}
/// @nodoc
class _$WorkspaceRegisterResultDtoCopyWithImpl<$Res>
    implements $WorkspaceRegisterResultDtoCopyWith<$Res> {
  _$WorkspaceRegisterResultDtoCopyWithImpl(this._self, this._then);

  final WorkspaceRegisterResultDto _self;
  final $Res Function(WorkspaceRegisterResultDto) _then;

/// Create a copy of WorkspaceRegisterResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workspace = null,Object? worktrees = null,}) {
  return _then(_self.copyWith(
workspace: null == workspace ? _self.workspace : workspace // ignore: cast_nullable_to_non_nullable
as WorkspaceDto,worktrees: null == worktrees ? _self.worktrees : worktrees // ignore: cast_nullable_to_non_nullable
as List<WorktreeDto>,
  ));
}
/// Create a copy of WorkspaceRegisterResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkspaceDtoCopyWith<$Res> get workspace {
  
  return $WorkspaceDtoCopyWith<$Res>(_self.workspace, (value) {
    return _then(_self.copyWith(workspace: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorkspaceRegisterResultDto].
extension WorkspaceRegisterResultDtoPatterns on WorkspaceRegisterResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceRegisterResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceRegisterResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceRegisterResultDto value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceRegisterResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceRegisterResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceRegisterResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkspaceDto workspace,  List<WorktreeDto> worktrees)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceRegisterResultDto() when $default != null:
return $default(_that.workspace,_that.worktrees);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkspaceDto workspace,  List<WorktreeDto> worktrees)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceRegisterResultDto():
return $default(_that.workspace,_that.worktrees);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkspaceDto workspace,  List<WorktreeDto> worktrees)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceRegisterResultDto() when $default != null:
return $default(_that.workspace,_that.worktrees);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkspaceRegisterResultDto implements WorkspaceRegisterResultDto {
  const _WorkspaceRegisterResultDto({required this.workspace, required final  List<WorktreeDto> worktrees}): _worktrees = worktrees;
  factory _WorkspaceRegisterResultDto.fromJson(Map<String, dynamic> json) => _$WorkspaceRegisterResultDtoFromJson(json);

@override final  WorkspaceDto workspace;
 final  List<WorktreeDto> _worktrees;
@override List<WorktreeDto> get worktrees {
  if (_worktrees is EqualUnmodifiableListView) return _worktrees;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_worktrees);
}


/// Create a copy of WorkspaceRegisterResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceRegisterResultDtoCopyWith<_WorkspaceRegisterResultDto> get copyWith => __$WorkspaceRegisterResultDtoCopyWithImpl<_WorkspaceRegisterResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkspaceRegisterResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceRegisterResultDto&&(identical(other.workspace, workspace) || other.workspace == workspace)&&const DeepCollectionEquality().equals(other._worktrees, _worktrees));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workspace,const DeepCollectionEquality().hash(_worktrees));

@override
String toString() {
  return 'WorkspaceRegisterResultDto(workspace: $workspace, worktrees: $worktrees)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceRegisterResultDtoCopyWith<$Res> implements $WorkspaceRegisterResultDtoCopyWith<$Res> {
  factory _$WorkspaceRegisterResultDtoCopyWith(_WorkspaceRegisterResultDto value, $Res Function(_WorkspaceRegisterResultDto) _then) = __$WorkspaceRegisterResultDtoCopyWithImpl;
@override @useResult
$Res call({
 WorkspaceDto workspace, List<WorktreeDto> worktrees
});


@override $WorkspaceDtoCopyWith<$Res> get workspace;

}
/// @nodoc
class __$WorkspaceRegisterResultDtoCopyWithImpl<$Res>
    implements _$WorkspaceRegisterResultDtoCopyWith<$Res> {
  __$WorkspaceRegisterResultDtoCopyWithImpl(this._self, this._then);

  final _WorkspaceRegisterResultDto _self;
  final $Res Function(_WorkspaceRegisterResultDto) _then;

/// Create a copy of WorkspaceRegisterResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workspace = null,Object? worktrees = null,}) {
  return _then(_WorkspaceRegisterResultDto(
workspace: null == workspace ? _self.workspace : workspace // ignore: cast_nullable_to_non_nullable
as WorkspaceDto,worktrees: null == worktrees ? _self._worktrees : worktrees // ignore: cast_nullable_to_non_nullable
as List<WorktreeDto>,
  ));
}

/// Create a copy of WorkspaceRegisterResultDto
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
mixin _$WorkspaceUnregisterResultDto {

 bool get unregistered;
/// Create a copy of WorkspaceUnregisterResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceUnregisterResultDtoCopyWith<WorkspaceUnregisterResultDto> get copyWith => _$WorkspaceUnregisterResultDtoCopyWithImpl<WorkspaceUnregisterResultDto>(this as WorkspaceUnregisterResultDto, _$identity);

  /// Serializes this WorkspaceUnregisterResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceUnregisterResultDto&&(identical(other.unregistered, unregistered) || other.unregistered == unregistered));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,unregistered);

@override
String toString() {
  return 'WorkspaceUnregisterResultDto(unregistered: $unregistered)';
}


}

/// @nodoc
abstract mixin class $WorkspaceUnregisterResultDtoCopyWith<$Res>  {
  factory $WorkspaceUnregisterResultDtoCopyWith(WorkspaceUnregisterResultDto value, $Res Function(WorkspaceUnregisterResultDto) _then) = _$WorkspaceUnregisterResultDtoCopyWithImpl;
@useResult
$Res call({
 bool unregistered
});




}
/// @nodoc
class _$WorkspaceUnregisterResultDtoCopyWithImpl<$Res>
    implements $WorkspaceUnregisterResultDtoCopyWith<$Res> {
  _$WorkspaceUnregisterResultDtoCopyWithImpl(this._self, this._then);

  final WorkspaceUnregisterResultDto _self;
  final $Res Function(WorkspaceUnregisterResultDto) _then;

/// Create a copy of WorkspaceUnregisterResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? unregistered = null,}) {
  return _then(_self.copyWith(
unregistered: null == unregistered ? _self.unregistered : unregistered // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkspaceUnregisterResultDto].
extension WorkspaceUnregisterResultDtoPatterns on WorkspaceUnregisterResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceUnregisterResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceUnregisterResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceUnregisterResultDto value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceUnregisterResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceUnregisterResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceUnregisterResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool unregistered)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceUnregisterResultDto() when $default != null:
return $default(_that.unregistered);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool unregistered)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceUnregisterResultDto():
return $default(_that.unregistered);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool unregistered)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceUnregisterResultDto() when $default != null:
return $default(_that.unregistered);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkspaceUnregisterResultDto implements WorkspaceUnregisterResultDto {
  const _WorkspaceUnregisterResultDto({required this.unregistered});
  factory _WorkspaceUnregisterResultDto.fromJson(Map<String, dynamic> json) => _$WorkspaceUnregisterResultDtoFromJson(json);

@override final  bool unregistered;

/// Create a copy of WorkspaceUnregisterResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceUnregisterResultDtoCopyWith<_WorkspaceUnregisterResultDto> get copyWith => __$WorkspaceUnregisterResultDtoCopyWithImpl<_WorkspaceUnregisterResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkspaceUnregisterResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceUnregisterResultDto&&(identical(other.unregistered, unregistered) || other.unregistered == unregistered));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,unregistered);

@override
String toString() {
  return 'WorkspaceUnregisterResultDto(unregistered: $unregistered)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceUnregisterResultDtoCopyWith<$Res> implements $WorkspaceUnregisterResultDtoCopyWith<$Res> {
  factory _$WorkspaceUnregisterResultDtoCopyWith(_WorkspaceUnregisterResultDto value, $Res Function(_WorkspaceUnregisterResultDto) _then) = __$WorkspaceUnregisterResultDtoCopyWithImpl;
@override @useResult
$Res call({
 bool unregistered
});




}
/// @nodoc
class __$WorkspaceUnregisterResultDtoCopyWithImpl<$Res>
    implements _$WorkspaceUnregisterResultDtoCopyWith<$Res> {
  __$WorkspaceUnregisterResultDtoCopyWithImpl(this._self, this._then);

  final _WorkspaceUnregisterResultDto _self;
  final $Res Function(_WorkspaceUnregisterResultDto) _then;

/// Create a copy of WorkspaceUnregisterResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? unregistered = null,}) {
  return _then(_WorkspaceUnregisterResultDto(
unregistered: null == unregistered ? _self.unregistered : unregistered // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$DirectorySuggestResultDto {

 List<DirectorySuggestionDto> get suggestions;
/// Create a copy of DirectorySuggestResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DirectorySuggestResultDtoCopyWith<DirectorySuggestResultDto> get copyWith => _$DirectorySuggestResultDtoCopyWithImpl<DirectorySuggestResultDto>(this as DirectorySuggestResultDto, _$identity);

  /// Serializes this DirectorySuggestResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DirectorySuggestResultDto&&const DeepCollectionEquality().equals(other.suggestions, suggestions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(suggestions));

@override
String toString() {
  return 'DirectorySuggestResultDto(suggestions: $suggestions)';
}


}

/// @nodoc
abstract mixin class $DirectorySuggestResultDtoCopyWith<$Res>  {
  factory $DirectorySuggestResultDtoCopyWith(DirectorySuggestResultDto value, $Res Function(DirectorySuggestResultDto) _then) = _$DirectorySuggestResultDtoCopyWithImpl;
@useResult
$Res call({
 List<DirectorySuggestionDto> suggestions
});




}
/// @nodoc
class _$DirectorySuggestResultDtoCopyWithImpl<$Res>
    implements $DirectorySuggestResultDtoCopyWith<$Res> {
  _$DirectorySuggestResultDtoCopyWithImpl(this._self, this._then);

  final DirectorySuggestResultDto _self;
  final $Res Function(DirectorySuggestResultDto) _then;

/// Create a copy of DirectorySuggestResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? suggestions = null,}) {
  return _then(_self.copyWith(
suggestions: null == suggestions ? _self.suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<DirectorySuggestionDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [DirectorySuggestResultDto].
extension DirectorySuggestResultDtoPatterns on DirectorySuggestResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DirectorySuggestResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DirectorySuggestResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DirectorySuggestResultDto value)  $default,){
final _that = this;
switch (_that) {
case _DirectorySuggestResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DirectorySuggestResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _DirectorySuggestResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<DirectorySuggestionDto> suggestions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DirectorySuggestResultDto() when $default != null:
return $default(_that.suggestions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<DirectorySuggestionDto> suggestions)  $default,) {final _that = this;
switch (_that) {
case _DirectorySuggestResultDto():
return $default(_that.suggestions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<DirectorySuggestionDto> suggestions)?  $default,) {final _that = this;
switch (_that) {
case _DirectorySuggestResultDto() when $default != null:
return $default(_that.suggestions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DirectorySuggestResultDto implements DirectorySuggestResultDto {
  const _DirectorySuggestResultDto({required final  List<DirectorySuggestionDto> suggestions}): _suggestions = suggestions;
  factory _DirectorySuggestResultDto.fromJson(Map<String, dynamic> json) => _$DirectorySuggestResultDtoFromJson(json);

 final  List<DirectorySuggestionDto> _suggestions;
@override List<DirectorySuggestionDto> get suggestions {
  if (_suggestions is EqualUnmodifiableListView) return _suggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_suggestions);
}


/// Create a copy of DirectorySuggestResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DirectorySuggestResultDtoCopyWith<_DirectorySuggestResultDto> get copyWith => __$DirectorySuggestResultDtoCopyWithImpl<_DirectorySuggestResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DirectorySuggestResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DirectorySuggestResultDto&&const DeepCollectionEquality().equals(other._suggestions, _suggestions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_suggestions));

@override
String toString() {
  return 'DirectorySuggestResultDto(suggestions: $suggestions)';
}


}

/// @nodoc
abstract mixin class _$DirectorySuggestResultDtoCopyWith<$Res> implements $DirectorySuggestResultDtoCopyWith<$Res> {
  factory _$DirectorySuggestResultDtoCopyWith(_DirectorySuggestResultDto value, $Res Function(_DirectorySuggestResultDto) _then) = __$DirectorySuggestResultDtoCopyWithImpl;
@override @useResult
$Res call({
 List<DirectorySuggestionDto> suggestions
});




}
/// @nodoc
class __$DirectorySuggestResultDtoCopyWithImpl<$Res>
    implements _$DirectorySuggestResultDtoCopyWith<$Res> {
  __$DirectorySuggestResultDtoCopyWithImpl(this._self, this._then);

  final _DirectorySuggestResultDto _self;
  final $Res Function(_DirectorySuggestResultDto) _then;

/// Create a copy of DirectorySuggestResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? suggestions = null,}) {
  return _then(_DirectorySuggestResultDto(
suggestions: null == suggestions ? _self._suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<DirectorySuggestionDto>,
  ));
}


}


/// @nodoc
mixin _$GitBranchesListResultDto {

 List<GitBranchDto> get branches;
/// Create a copy of GitBranchesListResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitBranchesListResultDtoCopyWith<GitBranchesListResultDto> get copyWith => _$GitBranchesListResultDtoCopyWithImpl<GitBranchesListResultDto>(this as GitBranchesListResultDto, _$identity);

  /// Serializes this GitBranchesListResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitBranchesListResultDto&&const DeepCollectionEquality().equals(other.branches, branches));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(branches));

@override
String toString() {
  return 'GitBranchesListResultDto(branches: $branches)';
}


}

/// @nodoc
abstract mixin class $GitBranchesListResultDtoCopyWith<$Res>  {
  factory $GitBranchesListResultDtoCopyWith(GitBranchesListResultDto value, $Res Function(GitBranchesListResultDto) _then) = _$GitBranchesListResultDtoCopyWithImpl;
@useResult
$Res call({
 List<GitBranchDto> branches
});




}
/// @nodoc
class _$GitBranchesListResultDtoCopyWithImpl<$Res>
    implements $GitBranchesListResultDtoCopyWith<$Res> {
  _$GitBranchesListResultDtoCopyWithImpl(this._self, this._then);

  final GitBranchesListResultDto _self;
  final $Res Function(GitBranchesListResultDto) _then;

/// Create a copy of GitBranchesListResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? branches = null,}) {
  return _then(_self.copyWith(
branches: null == branches ? _self.branches : branches // ignore: cast_nullable_to_non_nullable
as List<GitBranchDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [GitBranchesListResultDto].
extension GitBranchesListResultDtoPatterns on GitBranchesListResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitBranchesListResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitBranchesListResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitBranchesListResultDto value)  $default,){
final _that = this;
switch (_that) {
case _GitBranchesListResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitBranchesListResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _GitBranchesListResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<GitBranchDto> branches)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitBranchesListResultDto() when $default != null:
return $default(_that.branches);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<GitBranchDto> branches)  $default,) {final _that = this;
switch (_that) {
case _GitBranchesListResultDto():
return $default(_that.branches);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<GitBranchDto> branches)?  $default,) {final _that = this;
switch (_that) {
case _GitBranchesListResultDto() when $default != null:
return $default(_that.branches);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GitBranchesListResultDto implements GitBranchesListResultDto {
  const _GitBranchesListResultDto({required final  List<GitBranchDto> branches}): _branches = branches;
  factory _GitBranchesListResultDto.fromJson(Map<String, dynamic> json) => _$GitBranchesListResultDtoFromJson(json);

 final  List<GitBranchDto> _branches;
@override List<GitBranchDto> get branches {
  if (_branches is EqualUnmodifiableListView) return _branches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_branches);
}


/// Create a copy of GitBranchesListResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitBranchesListResultDtoCopyWith<_GitBranchesListResultDto> get copyWith => __$GitBranchesListResultDtoCopyWithImpl<_GitBranchesListResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GitBranchesListResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitBranchesListResultDto&&const DeepCollectionEquality().equals(other._branches, _branches));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_branches));

@override
String toString() {
  return 'GitBranchesListResultDto(branches: $branches)';
}


}

/// @nodoc
abstract mixin class _$GitBranchesListResultDtoCopyWith<$Res> implements $GitBranchesListResultDtoCopyWith<$Res> {
  factory _$GitBranchesListResultDtoCopyWith(_GitBranchesListResultDto value, $Res Function(_GitBranchesListResultDto) _then) = __$GitBranchesListResultDtoCopyWithImpl;
@override @useResult
$Res call({
 List<GitBranchDto> branches
});




}
/// @nodoc
class __$GitBranchesListResultDtoCopyWithImpl<$Res>
    implements _$GitBranchesListResultDtoCopyWith<$Res> {
  __$GitBranchesListResultDtoCopyWithImpl(this._self, this._then);

  final _GitBranchesListResultDto _self;
  final $Res Function(_GitBranchesListResultDto) _then;

/// Create a copy of GitBranchesListResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? branches = null,}) {
  return _then(_GitBranchesListResultDto(
branches: null == branches ? _self._branches : branches // ignore: cast_nullable_to_non_nullable
as List<GitBranchDto>,
  ));
}


}


/// @nodoc
mixin _$WorktreeResultDto {

 WorktreeDto get worktree;
/// Create a copy of WorktreeResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorktreeResultDtoCopyWith<WorktreeResultDto> get copyWith => _$WorktreeResultDtoCopyWithImpl<WorktreeResultDto>(this as WorktreeResultDto, _$identity);

  /// Serializes this WorktreeResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorktreeResultDto&&(identical(other.worktree, worktree) || other.worktree == worktree));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,worktree);

@override
String toString() {
  return 'WorktreeResultDto(worktree: $worktree)';
}


}

/// @nodoc
abstract mixin class $WorktreeResultDtoCopyWith<$Res>  {
  factory $WorktreeResultDtoCopyWith(WorktreeResultDto value, $Res Function(WorktreeResultDto) _then) = _$WorktreeResultDtoCopyWithImpl;
@useResult
$Res call({
 WorktreeDto worktree
});


$WorktreeDtoCopyWith<$Res> get worktree;

}
/// @nodoc
class _$WorktreeResultDtoCopyWithImpl<$Res>
    implements $WorktreeResultDtoCopyWith<$Res> {
  _$WorktreeResultDtoCopyWithImpl(this._self, this._then);

  final WorktreeResultDto _self;
  final $Res Function(WorktreeResultDto) _then;

/// Create a copy of WorktreeResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? worktree = null,}) {
  return _then(_self.copyWith(
worktree: null == worktree ? _self.worktree : worktree // ignore: cast_nullable_to_non_nullable
as WorktreeDto,
  ));
}
/// Create a copy of WorktreeResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorktreeDtoCopyWith<$Res> get worktree {
  
  return $WorktreeDtoCopyWith<$Res>(_self.worktree, (value) {
    return _then(_self.copyWith(worktree: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorktreeResultDto].
extension WorktreeResultDtoPatterns on WorktreeResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorktreeResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorktreeResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorktreeResultDto value)  $default,){
final _that = this;
switch (_that) {
case _WorktreeResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorktreeResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _WorktreeResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorktreeDto worktree)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorktreeResultDto() when $default != null:
return $default(_that.worktree);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorktreeDto worktree)  $default,) {final _that = this;
switch (_that) {
case _WorktreeResultDto():
return $default(_that.worktree);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorktreeDto worktree)?  $default,) {final _that = this;
switch (_that) {
case _WorktreeResultDto() when $default != null:
return $default(_that.worktree);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorktreeResultDto implements WorktreeResultDto {
  const _WorktreeResultDto({required this.worktree});
  factory _WorktreeResultDto.fromJson(Map<String, dynamic> json) => _$WorktreeResultDtoFromJson(json);

@override final  WorktreeDto worktree;

/// Create a copy of WorktreeResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorktreeResultDtoCopyWith<_WorktreeResultDto> get copyWith => __$WorktreeResultDtoCopyWithImpl<_WorktreeResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorktreeResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorktreeResultDto&&(identical(other.worktree, worktree) || other.worktree == worktree));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,worktree);

@override
String toString() {
  return 'WorktreeResultDto(worktree: $worktree)';
}


}

/// @nodoc
abstract mixin class _$WorktreeResultDtoCopyWith<$Res> implements $WorktreeResultDtoCopyWith<$Res> {
  factory _$WorktreeResultDtoCopyWith(_WorktreeResultDto value, $Res Function(_WorktreeResultDto) _then) = __$WorktreeResultDtoCopyWithImpl;
@override @useResult
$Res call({
 WorktreeDto worktree
});


@override $WorktreeDtoCopyWith<$Res> get worktree;

}
/// @nodoc
class __$WorktreeResultDtoCopyWithImpl<$Res>
    implements _$WorktreeResultDtoCopyWith<$Res> {
  __$WorktreeResultDtoCopyWithImpl(this._self, this._then);

  final _WorktreeResultDto _self;
  final $Res Function(_WorktreeResultDto) _then;

/// Create a copy of WorktreeResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? worktree = null,}) {
  return _then(_WorktreeResultDto(
worktree: null == worktree ? _self.worktree : worktree // ignore: cast_nullable_to_non_nullable
as WorktreeDto,
  ));
}

/// Create a copy of WorktreeResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorktreeDtoCopyWith<$Res> get worktree {
  
  return $WorktreeDtoCopyWith<$Res>(_self.worktree, (value) {
    return _then(_self.copyWith(worktree: value));
  });
}
}


/// @nodoc
mixin _$WorktreeArchivePreviewResultDto {

 WorktreeArchivePreviewDto get preview;
/// Create a copy of WorktreeArchivePreviewResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorktreeArchivePreviewResultDtoCopyWith<WorktreeArchivePreviewResultDto> get copyWith => _$WorktreeArchivePreviewResultDtoCopyWithImpl<WorktreeArchivePreviewResultDto>(this as WorktreeArchivePreviewResultDto, _$identity);

  /// Serializes this WorktreeArchivePreviewResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorktreeArchivePreviewResultDto&&(identical(other.preview, preview) || other.preview == preview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,preview);

@override
String toString() {
  return 'WorktreeArchivePreviewResultDto(preview: $preview)';
}


}

/// @nodoc
abstract mixin class $WorktreeArchivePreviewResultDtoCopyWith<$Res>  {
  factory $WorktreeArchivePreviewResultDtoCopyWith(WorktreeArchivePreviewResultDto value, $Res Function(WorktreeArchivePreviewResultDto) _then) = _$WorktreeArchivePreviewResultDtoCopyWithImpl;
@useResult
$Res call({
 WorktreeArchivePreviewDto preview
});


$WorktreeArchivePreviewDtoCopyWith<$Res> get preview;

}
/// @nodoc
class _$WorktreeArchivePreviewResultDtoCopyWithImpl<$Res>
    implements $WorktreeArchivePreviewResultDtoCopyWith<$Res> {
  _$WorktreeArchivePreviewResultDtoCopyWithImpl(this._self, this._then);

  final WorktreeArchivePreviewResultDto _self;
  final $Res Function(WorktreeArchivePreviewResultDto) _then;

/// Create a copy of WorktreeArchivePreviewResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? preview = null,}) {
  return _then(_self.copyWith(
preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as WorktreeArchivePreviewDto,
  ));
}
/// Create a copy of WorktreeArchivePreviewResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorktreeArchivePreviewDtoCopyWith<$Res> get preview {
  
  return $WorktreeArchivePreviewDtoCopyWith<$Res>(_self.preview, (value) {
    return _then(_self.copyWith(preview: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorktreeArchivePreviewResultDto].
extension WorktreeArchivePreviewResultDtoPatterns on WorktreeArchivePreviewResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorktreeArchivePreviewResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorktreeArchivePreviewResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorktreeArchivePreviewResultDto value)  $default,){
final _that = this;
switch (_that) {
case _WorktreeArchivePreviewResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorktreeArchivePreviewResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _WorktreeArchivePreviewResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorktreeArchivePreviewDto preview)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorktreeArchivePreviewResultDto() when $default != null:
return $default(_that.preview);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorktreeArchivePreviewDto preview)  $default,) {final _that = this;
switch (_that) {
case _WorktreeArchivePreviewResultDto():
return $default(_that.preview);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorktreeArchivePreviewDto preview)?  $default,) {final _that = this;
switch (_that) {
case _WorktreeArchivePreviewResultDto() when $default != null:
return $default(_that.preview);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorktreeArchivePreviewResultDto implements WorktreeArchivePreviewResultDto {
  const _WorktreeArchivePreviewResultDto({required this.preview});
  factory _WorktreeArchivePreviewResultDto.fromJson(Map<String, dynamic> json) => _$WorktreeArchivePreviewResultDtoFromJson(json);

@override final  WorktreeArchivePreviewDto preview;

/// Create a copy of WorktreeArchivePreviewResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorktreeArchivePreviewResultDtoCopyWith<_WorktreeArchivePreviewResultDto> get copyWith => __$WorktreeArchivePreviewResultDtoCopyWithImpl<_WorktreeArchivePreviewResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorktreeArchivePreviewResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorktreeArchivePreviewResultDto&&(identical(other.preview, preview) || other.preview == preview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,preview);

@override
String toString() {
  return 'WorktreeArchivePreviewResultDto(preview: $preview)';
}


}

/// @nodoc
abstract mixin class _$WorktreeArchivePreviewResultDtoCopyWith<$Res> implements $WorktreeArchivePreviewResultDtoCopyWith<$Res> {
  factory _$WorktreeArchivePreviewResultDtoCopyWith(_WorktreeArchivePreviewResultDto value, $Res Function(_WorktreeArchivePreviewResultDto) _then) = __$WorktreeArchivePreviewResultDtoCopyWithImpl;
@override @useResult
$Res call({
 WorktreeArchivePreviewDto preview
});


@override $WorktreeArchivePreviewDtoCopyWith<$Res> get preview;

}
/// @nodoc
class __$WorktreeArchivePreviewResultDtoCopyWithImpl<$Res>
    implements _$WorktreeArchivePreviewResultDtoCopyWith<$Res> {
  __$WorktreeArchivePreviewResultDtoCopyWithImpl(this._self, this._then);

  final _WorktreeArchivePreviewResultDto _self;
  final $Res Function(_WorktreeArchivePreviewResultDto) _then;

/// Create a copy of WorktreeArchivePreviewResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? preview = null,}) {
  return _then(_WorktreeArchivePreviewResultDto(
preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as WorktreeArchivePreviewDto,
  ));
}

/// Create a copy of WorktreeArchivePreviewResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorktreeArchivePreviewDtoCopyWith<$Res> get preview {
  
  return $WorktreeArchivePreviewDtoCopyWith<$Res>(_self.preview, (value) {
    return _then(_self.copyWith(preview: value));
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
mixin _$ProviderConnectionsResultDto {

 List<ProviderConnectionDto> get connections;
/// Create a copy of ProviderConnectionsResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderConnectionsResultDtoCopyWith<ProviderConnectionsResultDto> get copyWith => _$ProviderConnectionsResultDtoCopyWithImpl<ProviderConnectionsResultDto>(this as ProviderConnectionsResultDto, _$identity);

  /// Serializes this ProviderConnectionsResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderConnectionsResultDto&&const DeepCollectionEquality().equals(other.connections, connections));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(connections));

@override
String toString() {
  return 'ProviderConnectionsResultDto(connections: $connections)';
}


}

/// @nodoc
abstract mixin class $ProviderConnectionsResultDtoCopyWith<$Res>  {
  factory $ProviderConnectionsResultDtoCopyWith(ProviderConnectionsResultDto value, $Res Function(ProviderConnectionsResultDto) _then) = _$ProviderConnectionsResultDtoCopyWithImpl;
@useResult
$Res call({
 List<ProviderConnectionDto> connections
});




}
/// @nodoc
class _$ProviderConnectionsResultDtoCopyWithImpl<$Res>
    implements $ProviderConnectionsResultDtoCopyWith<$Res> {
  _$ProviderConnectionsResultDtoCopyWithImpl(this._self, this._then);

  final ProviderConnectionsResultDto _self;
  final $Res Function(ProviderConnectionsResultDto) _then;

/// Create a copy of ProviderConnectionsResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? connections = null,}) {
  return _then(_self.copyWith(
connections: null == connections ? _self.connections : connections // ignore: cast_nullable_to_non_nullable
as List<ProviderConnectionDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderConnectionsResultDto].
extension ProviderConnectionsResultDtoPatterns on ProviderConnectionsResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderConnectionsResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderConnectionsResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderConnectionsResultDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderConnectionsResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderConnectionsResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderConnectionsResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ProviderConnectionDto> connections)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderConnectionsResultDto() when $default != null:
return $default(_that.connections);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ProviderConnectionDto> connections)  $default,) {final _that = this;
switch (_that) {
case _ProviderConnectionsResultDto():
return $default(_that.connections);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ProviderConnectionDto> connections)?  $default,) {final _that = this;
switch (_that) {
case _ProviderConnectionsResultDto() when $default != null:
return $default(_that.connections);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderConnectionsResultDto implements ProviderConnectionsResultDto {
  const _ProviderConnectionsResultDto({required final  List<ProviderConnectionDto> connections}): _connections = connections;
  factory _ProviderConnectionsResultDto.fromJson(Map<String, dynamic> json) => _$ProviderConnectionsResultDtoFromJson(json);

 final  List<ProviderConnectionDto> _connections;
@override List<ProviderConnectionDto> get connections {
  if (_connections is EqualUnmodifiableListView) return _connections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_connections);
}


/// Create a copy of ProviderConnectionsResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderConnectionsResultDtoCopyWith<_ProviderConnectionsResultDto> get copyWith => __$ProviderConnectionsResultDtoCopyWithImpl<_ProviderConnectionsResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderConnectionsResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderConnectionsResultDto&&const DeepCollectionEquality().equals(other._connections, _connections));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_connections));

@override
String toString() {
  return 'ProviderConnectionsResultDto(connections: $connections)';
}


}

/// @nodoc
abstract mixin class _$ProviderConnectionsResultDtoCopyWith<$Res> implements $ProviderConnectionsResultDtoCopyWith<$Res> {
  factory _$ProviderConnectionsResultDtoCopyWith(_ProviderConnectionsResultDto value, $Res Function(_ProviderConnectionsResultDto) _then) = __$ProviderConnectionsResultDtoCopyWithImpl;
@override @useResult
$Res call({
 List<ProviderConnectionDto> connections
});




}
/// @nodoc
class __$ProviderConnectionsResultDtoCopyWithImpl<$Res>
    implements _$ProviderConnectionsResultDtoCopyWith<$Res> {
  __$ProviderConnectionsResultDtoCopyWithImpl(this._self, this._then);

  final _ProviderConnectionsResultDto _self;
  final $Res Function(_ProviderConnectionsResultDto) _then;

/// Create a copy of ProviderConnectionsResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? connections = null,}) {
  return _then(_ProviderConnectionsResultDto(
connections: null == connections ? _self._connections : connections // ignore: cast_nullable_to_non_nullable
as List<ProviderConnectionDto>,
  ));
}


}


/// @nodoc
mixin _$ProviderConnectionResultDto {

 ProviderConnectionDto get connection;
/// Create a copy of ProviderConnectionResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderConnectionResultDtoCopyWith<ProviderConnectionResultDto> get copyWith => _$ProviderConnectionResultDtoCopyWithImpl<ProviderConnectionResultDto>(this as ProviderConnectionResultDto, _$identity);

  /// Serializes this ProviderConnectionResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderConnectionResultDto&&(identical(other.connection, connection) || other.connection == connection));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connection);

@override
String toString() {
  return 'ProviderConnectionResultDto(connection: $connection)';
}


}

/// @nodoc
abstract mixin class $ProviderConnectionResultDtoCopyWith<$Res>  {
  factory $ProviderConnectionResultDtoCopyWith(ProviderConnectionResultDto value, $Res Function(ProviderConnectionResultDto) _then) = _$ProviderConnectionResultDtoCopyWithImpl;
@useResult
$Res call({
 ProviderConnectionDto connection
});


$ProviderConnectionDtoCopyWith<$Res> get connection;

}
/// @nodoc
class _$ProviderConnectionResultDtoCopyWithImpl<$Res>
    implements $ProviderConnectionResultDtoCopyWith<$Res> {
  _$ProviderConnectionResultDtoCopyWithImpl(this._self, this._then);

  final ProviderConnectionResultDto _self;
  final $Res Function(ProviderConnectionResultDto) _then;

/// Create a copy of ProviderConnectionResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? connection = null,}) {
  return _then(_self.copyWith(
connection: null == connection ? _self.connection : connection // ignore: cast_nullable_to_non_nullable
as ProviderConnectionDto,
  ));
}
/// Create a copy of ProviderConnectionResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderConnectionDtoCopyWith<$Res> get connection {
  
  return $ProviderConnectionDtoCopyWith<$Res>(_self.connection, (value) {
    return _then(_self.copyWith(connection: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProviderConnectionResultDto].
extension ProviderConnectionResultDtoPatterns on ProviderConnectionResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderConnectionResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderConnectionResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderConnectionResultDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderConnectionResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderConnectionResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderConnectionResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProviderConnectionDto connection)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderConnectionResultDto() when $default != null:
return $default(_that.connection);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProviderConnectionDto connection)  $default,) {final _that = this;
switch (_that) {
case _ProviderConnectionResultDto():
return $default(_that.connection);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProviderConnectionDto connection)?  $default,) {final _that = this;
switch (_that) {
case _ProviderConnectionResultDto() when $default != null:
return $default(_that.connection);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderConnectionResultDto implements ProviderConnectionResultDto {
  const _ProviderConnectionResultDto({required this.connection});
  factory _ProviderConnectionResultDto.fromJson(Map<String, dynamic> json) => _$ProviderConnectionResultDtoFromJson(json);

@override final  ProviderConnectionDto connection;

/// Create a copy of ProviderConnectionResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderConnectionResultDtoCopyWith<_ProviderConnectionResultDto> get copyWith => __$ProviderConnectionResultDtoCopyWithImpl<_ProviderConnectionResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderConnectionResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderConnectionResultDto&&(identical(other.connection, connection) || other.connection == connection));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connection);

@override
String toString() {
  return 'ProviderConnectionResultDto(connection: $connection)';
}


}

/// @nodoc
abstract mixin class _$ProviderConnectionResultDtoCopyWith<$Res> implements $ProviderConnectionResultDtoCopyWith<$Res> {
  factory _$ProviderConnectionResultDtoCopyWith(_ProviderConnectionResultDto value, $Res Function(_ProviderConnectionResultDto) _then) = __$ProviderConnectionResultDtoCopyWithImpl;
@override @useResult
$Res call({
 ProviderConnectionDto connection
});


@override $ProviderConnectionDtoCopyWith<$Res> get connection;

}
/// @nodoc
class __$ProviderConnectionResultDtoCopyWithImpl<$Res>
    implements _$ProviderConnectionResultDtoCopyWith<$Res> {
  __$ProviderConnectionResultDtoCopyWithImpl(this._self, this._then);

  final _ProviderConnectionResultDto _self;
  final $Res Function(_ProviderConnectionResultDto) _then;

/// Create a copy of ProviderConnectionResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? connection = null,}) {
  return _then(_ProviderConnectionResultDto(
connection: null == connection ? _self.connection : connection // ignore: cast_nullable_to_non_nullable
as ProviderConnectionDto,
  ));
}

/// Create a copy of ProviderConnectionResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderConnectionDtoCopyWith<$Res> get connection {
  
  return $ProviderConnectionDtoCopyWith<$Res>(_self.connection, (value) {
    return _then(_self.copyWith(connection: value));
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
mixin _$ProviderAuthAttemptResultDto {

 ProviderAuthAttemptDto get attempt;
/// Create a copy of ProviderAuthAttemptResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderAuthAttemptResultDtoCopyWith<ProviderAuthAttemptResultDto> get copyWith => _$ProviderAuthAttemptResultDtoCopyWithImpl<ProviderAuthAttemptResultDto>(this as ProviderAuthAttemptResultDto, _$identity);

  /// Serializes this ProviderAuthAttemptResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderAuthAttemptResultDto&&(identical(other.attempt, attempt) || other.attempt == attempt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attempt);

@override
String toString() {
  return 'ProviderAuthAttemptResultDto(attempt: $attempt)';
}


}

/// @nodoc
abstract mixin class $ProviderAuthAttemptResultDtoCopyWith<$Res>  {
  factory $ProviderAuthAttemptResultDtoCopyWith(ProviderAuthAttemptResultDto value, $Res Function(ProviderAuthAttemptResultDto) _then) = _$ProviderAuthAttemptResultDtoCopyWithImpl;
@useResult
$Res call({
 ProviderAuthAttemptDto attempt
});


$ProviderAuthAttemptDtoCopyWith<$Res> get attempt;

}
/// @nodoc
class _$ProviderAuthAttemptResultDtoCopyWithImpl<$Res>
    implements $ProviderAuthAttemptResultDtoCopyWith<$Res> {
  _$ProviderAuthAttemptResultDtoCopyWithImpl(this._self, this._then);

  final ProviderAuthAttemptResultDto _self;
  final $Res Function(ProviderAuthAttemptResultDto) _then;

/// Create a copy of ProviderAuthAttemptResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? attempt = null,}) {
  return _then(_self.copyWith(
attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as ProviderAuthAttemptDto,
  ));
}
/// Create a copy of ProviderAuthAttemptResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderAuthAttemptDtoCopyWith<$Res> get attempt {
  
  return $ProviderAuthAttemptDtoCopyWith<$Res>(_self.attempt, (value) {
    return _then(_self.copyWith(attempt: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProviderAuthAttemptResultDto].
extension ProviderAuthAttemptResultDtoPatterns on ProviderAuthAttemptResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderAuthAttemptResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderAuthAttemptResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderAuthAttemptResultDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderAuthAttemptResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderAuthAttemptResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderAuthAttemptResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProviderAuthAttemptDto attempt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderAuthAttemptResultDto() when $default != null:
return $default(_that.attempt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProviderAuthAttemptDto attempt)  $default,) {final _that = this;
switch (_that) {
case _ProviderAuthAttemptResultDto():
return $default(_that.attempt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProviderAuthAttemptDto attempt)?  $default,) {final _that = this;
switch (_that) {
case _ProviderAuthAttemptResultDto() when $default != null:
return $default(_that.attempt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderAuthAttemptResultDto implements ProviderAuthAttemptResultDto {
  const _ProviderAuthAttemptResultDto({required this.attempt});
  factory _ProviderAuthAttemptResultDto.fromJson(Map<String, dynamic> json) => _$ProviderAuthAttemptResultDtoFromJson(json);

@override final  ProviderAuthAttemptDto attempt;

/// Create a copy of ProviderAuthAttemptResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderAuthAttemptResultDtoCopyWith<_ProviderAuthAttemptResultDto> get copyWith => __$ProviderAuthAttemptResultDtoCopyWithImpl<_ProviderAuthAttemptResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderAuthAttemptResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderAuthAttemptResultDto&&(identical(other.attempt, attempt) || other.attempt == attempt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attempt);

@override
String toString() {
  return 'ProviderAuthAttemptResultDto(attempt: $attempt)';
}


}

/// @nodoc
abstract mixin class _$ProviderAuthAttemptResultDtoCopyWith<$Res> implements $ProviderAuthAttemptResultDtoCopyWith<$Res> {
  factory _$ProviderAuthAttemptResultDtoCopyWith(_ProviderAuthAttemptResultDto value, $Res Function(_ProviderAuthAttemptResultDto) _then) = __$ProviderAuthAttemptResultDtoCopyWithImpl;
@override @useResult
$Res call({
 ProviderAuthAttemptDto attempt
});


@override $ProviderAuthAttemptDtoCopyWith<$Res> get attempt;

}
/// @nodoc
class __$ProviderAuthAttemptResultDtoCopyWithImpl<$Res>
    implements _$ProviderAuthAttemptResultDtoCopyWith<$Res> {
  __$ProviderAuthAttemptResultDtoCopyWithImpl(this._self, this._then);

  final _ProviderAuthAttemptResultDto _self;
  final $Res Function(_ProviderAuthAttemptResultDto) _then;

/// Create a copy of ProviderAuthAttemptResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? attempt = null,}) {
  return _then(_ProviderAuthAttemptResultDto(
attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as ProviderAuthAttemptDto,
  ));
}

/// Create a copy of ProviderAuthAttemptResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderAuthAttemptDtoCopyWith<$Res> get attempt {
  
  return $ProviderAuthAttemptDtoCopyWith<$Res>(_self.attempt, (value) {
    return _then(_self.copyWith(attempt: value));
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
