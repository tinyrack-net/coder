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

 String get id; String get name; String get rootPath; DateTime get createdAt;
/// Create a copy of WorkspaceDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceDtoCopyWith<WorkspaceDto> get copyWith => _$WorkspaceDtoCopyWithImpl<WorkspaceDto>(this as WorkspaceDto, _$identity);

  /// Serializes this WorkspaceDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,rootPath,createdAt);

@override
String toString() {
  return 'WorkspaceDto(id: $id, name: $name, rootPath: $rootPath, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $WorkspaceDtoCopyWith<$Res>  {
  factory $WorkspaceDtoCopyWith(WorkspaceDto value, $Res Function(WorkspaceDto) _then) = _$WorkspaceDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String rootPath, DateTime createdAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? rootPath = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rootPath: null == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String rootPath,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceDto() when $default != null:
return $default(_that.id,_that.name,_that.rootPath,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String rootPath,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceDto():
return $default(_that.id,_that.name,_that.rootPath,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String rootPath,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceDto() when $default != null:
return $default(_that.id,_that.name,_that.rootPath,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkspaceDto implements WorkspaceDto {
  const _WorkspaceDto({required this.id, required this.name, required this.rootPath, required this.createdAt});
  factory _WorkspaceDto.fromJson(Map<String, dynamic> json) => _$WorkspaceDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String rootPath;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,rootPath,createdAt);

@override
String toString() {
  return 'WorkspaceDto(id: $id, name: $name, rootPath: $rootPath, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceDtoCopyWith<$Res> implements $WorkspaceDtoCopyWith<$Res> {
  factory _$WorkspaceDtoCopyWith(_WorkspaceDto value, $Res Function(_WorkspaceDto) _then) = __$WorkspaceDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String rootPath, DateTime createdAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? rootPath = null,Object? createdAt = null,}) {
  return _then(_WorkspaceDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rootPath: null == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$AgentDto {

 String get id; String get workspaceId; String get title; String get providerId; String get model; String get reasoningEffort; AgentStatus get status; PermissionMode get permissionMode; DateTime get createdAt; DateTime get updatedAt; String? get activeTurnId; String? get lastError;
/// Create a copy of AgentDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentDtoCopyWith<AgentDto> get copyWith => _$AgentDtoCopyWithImpl<AgentDto>(this as AgentDto, _$identity);

  /// Serializes this AgentDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentDto&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.title, title) || other.title == title)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.model, model) || other.model == model)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort)&&(identical(other.status, status) || other.status == status)&&(identical(other.permissionMode, permissionMode) || other.permissionMode == permissionMode)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.activeTurnId, activeTurnId) || other.activeTurnId == activeTurnId)&&(identical(other.lastError, lastError) || other.lastError == lastError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,title,providerId,model,reasoningEffort,status,permissionMode,createdAt,updatedAt,activeTurnId,lastError);

@override
String toString() {
  return 'AgentDto(id: $id, workspaceId: $workspaceId, title: $title, providerId: $providerId, model: $model, reasoningEffort: $reasoningEffort, status: $status, permissionMode: $permissionMode, createdAt: $createdAt, updatedAt: $updatedAt, activeTurnId: $activeTurnId, lastError: $lastError)';
}


}

/// @nodoc
abstract mixin class $AgentDtoCopyWith<$Res>  {
  factory $AgentDtoCopyWith(AgentDto value, $Res Function(AgentDto) _then) = _$AgentDtoCopyWithImpl;
@useResult
$Res call({
 String id, String workspaceId, String title, String providerId, String model, String reasoningEffort, AgentStatus status, PermissionMode permissionMode, DateTime createdAt, DateTime updatedAt, String? activeTurnId, String? lastError
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workspaceId = null,Object? title = null,Object? providerId = null,Object? model = null,Object? reasoningEffort = null,Object? status = null,Object? permissionMode = null,Object? createdAt = null,Object? updatedAt = null,Object? activeTurnId = freezed,Object? lastError = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,reasoningEffort: null == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AgentStatus,permissionMode: null == permissionMode ? _self.permissionMode : permissionMode // ignore: cast_nullable_to_non_nullable
as PermissionMode,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,activeTurnId: freezed == activeTurnId ? _self.activeTurnId : activeTurnId // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String title,  String providerId,  String model,  String reasoningEffort,  AgentStatus status,  PermissionMode permissionMode,  DateTime createdAt,  DateTime updatedAt,  String? activeTurnId,  String? lastError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentDto() when $default != null:
return $default(_that.id,_that.workspaceId,_that.title,_that.providerId,_that.model,_that.reasoningEffort,_that.status,_that.permissionMode,_that.createdAt,_that.updatedAt,_that.activeTurnId,_that.lastError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String title,  String providerId,  String model,  String reasoningEffort,  AgentStatus status,  PermissionMode permissionMode,  DateTime createdAt,  DateTime updatedAt,  String? activeTurnId,  String? lastError)  $default,) {final _that = this;
switch (_that) {
case _AgentDto():
return $default(_that.id,_that.workspaceId,_that.title,_that.providerId,_that.model,_that.reasoningEffort,_that.status,_that.permissionMode,_that.createdAt,_that.updatedAt,_that.activeTurnId,_that.lastError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workspaceId,  String title,  String providerId,  String model,  String reasoningEffort,  AgentStatus status,  PermissionMode permissionMode,  DateTime createdAt,  DateTime updatedAt,  String? activeTurnId,  String? lastError)?  $default,) {final _that = this;
switch (_that) {
case _AgentDto() when $default != null:
return $default(_that.id,_that.workspaceId,_that.title,_that.providerId,_that.model,_that.reasoningEffort,_that.status,_that.permissionMode,_that.createdAt,_that.updatedAt,_that.activeTurnId,_that.lastError);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentDto implements AgentDto {
  const _AgentDto({required this.id, required this.workspaceId, required this.title, required this.providerId, required this.model, this.reasoningEffort = 'medium', required this.status, required this.permissionMode, required this.createdAt, required this.updatedAt, this.activeTurnId, this.lastError});
  factory _AgentDto.fromJson(Map<String, dynamic> json) => _$AgentDtoFromJson(json);

@override final  String id;
@override final  String workspaceId;
@override final  String title;
@override final  String providerId;
@override final  String model;
@override@JsonKey() final  String reasoningEffort;
@override final  AgentStatus status;
@override final  PermissionMode permissionMode;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentDto&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.title, title) || other.title == title)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.model, model) || other.model == model)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort)&&(identical(other.status, status) || other.status == status)&&(identical(other.permissionMode, permissionMode) || other.permissionMode == permissionMode)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.activeTurnId, activeTurnId) || other.activeTurnId == activeTurnId)&&(identical(other.lastError, lastError) || other.lastError == lastError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,title,providerId,model,reasoningEffort,status,permissionMode,createdAt,updatedAt,activeTurnId,lastError);

@override
String toString() {
  return 'AgentDto(id: $id, workspaceId: $workspaceId, title: $title, providerId: $providerId, model: $model, reasoningEffort: $reasoningEffort, status: $status, permissionMode: $permissionMode, createdAt: $createdAt, updatedAt: $updatedAt, activeTurnId: $activeTurnId, lastError: $lastError)';
}


}

/// @nodoc
abstract mixin class _$AgentDtoCopyWith<$Res> implements $AgentDtoCopyWith<$Res> {
  factory _$AgentDtoCopyWith(_AgentDto value, $Res Function(_AgentDto) _then) = __$AgentDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String workspaceId, String title, String providerId, String model, String reasoningEffort, AgentStatus status, PermissionMode permissionMode, DateTime createdAt, DateTime updatedAt, String? activeTurnId, String? lastError
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workspaceId = null,Object? title = null,Object? providerId = null,Object? model = null,Object? reasoningEffort = null,Object? status = null,Object? permissionMode = null,Object? createdAt = null,Object? updatedAt = null,Object? activeTurnId = freezed,Object? lastError = freezed,}) {
  return _then(_AgentDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,reasoningEffort: null == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AgentStatus,permissionMode: null == permissionMode ? _self.permissionMode : permissionMode // ignore: cast_nullable_to_non_nullable
as PermissionMode,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,activeTurnId: freezed == activeTurnId ? _self.activeTurnId : activeTurnId // ignore: cast_nullable_to_non_nullable
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
mixin _$ApiProviderDto {

 String get id; String get name; String get presetId; String get baseUrl; ApiTransport get transport; CredentialSource get credentialSource; bool get credentialConfigured; bool get enabled; bool get strictToolSchema; DateTime get createdAt; DateTime get updatedAt; String? get environmentVariable; String? get defaultModelId; List<String> get visibleModelIds;
/// Create a copy of ApiProviderDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiProviderDtoCopyWith<ApiProviderDto> get copyWith => _$ApiProviderDtoCopyWithImpl<ApiProviderDto>(this as ApiProviderDto, _$identity);

  /// Serializes this ApiProviderDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiProviderDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.presetId, presetId) || other.presetId == presetId)&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.credentialSource, credentialSource) || other.credentialSource == credentialSource)&&(identical(other.credentialConfigured, credentialConfigured) || other.credentialConfigured == credentialConfigured)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.strictToolSchema, strictToolSchema) || other.strictToolSchema == strictToolSchema)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.environmentVariable, environmentVariable) || other.environmentVariable == environmentVariable)&&(identical(other.defaultModelId, defaultModelId) || other.defaultModelId == defaultModelId)&&const DeepCollectionEquality().equals(other.visibleModelIds, visibleModelIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,presetId,baseUrl,transport,credentialSource,credentialConfigured,enabled,strictToolSchema,createdAt,updatedAt,environmentVariable,defaultModelId,const DeepCollectionEquality().hash(visibleModelIds));

@override
String toString() {
  return 'ApiProviderDto(id: $id, name: $name, presetId: $presetId, baseUrl: $baseUrl, transport: $transport, credentialSource: $credentialSource, credentialConfigured: $credentialConfigured, enabled: $enabled, strictToolSchema: $strictToolSchema, createdAt: $createdAt, updatedAt: $updatedAt, environmentVariable: $environmentVariable, defaultModelId: $defaultModelId, visibleModelIds: $visibleModelIds)';
}


}

/// @nodoc
abstract mixin class $ApiProviderDtoCopyWith<$Res>  {
  factory $ApiProviderDtoCopyWith(ApiProviderDto value, $Res Function(ApiProviderDto) _then) = _$ApiProviderDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String presetId, String baseUrl, ApiTransport transport, CredentialSource credentialSource, bool credentialConfigured, bool enabled, bool strictToolSchema, DateTime createdAt, DateTime updatedAt, String? environmentVariable, String? defaultModelId, List<String> visibleModelIds
});




}
/// @nodoc
class _$ApiProviderDtoCopyWithImpl<$Res>
    implements $ApiProviderDtoCopyWith<$Res> {
  _$ApiProviderDtoCopyWithImpl(this._self, this._then);

  final ApiProviderDto _self;
  final $Res Function(ApiProviderDto) _then;

/// Create a copy of ApiProviderDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? presetId = null,Object? baseUrl = null,Object? transport = null,Object? credentialSource = null,Object? credentialConfigured = null,Object? enabled = null,Object? strictToolSchema = null,Object? createdAt = null,Object? updatedAt = null,Object? environmentVariable = freezed,Object? defaultModelId = freezed,Object? visibleModelIds = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,presetId: null == presetId ? _self.presetId : presetId // ignore: cast_nullable_to_non_nullable
as String,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as ApiTransport,credentialSource: null == credentialSource ? _self.credentialSource : credentialSource // ignore: cast_nullable_to_non_nullable
as CredentialSource,credentialConfigured: null == credentialConfigured ? _self.credentialConfigured : credentialConfigured // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,strictToolSchema: null == strictToolSchema ? _self.strictToolSchema : strictToolSchema // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,environmentVariable: freezed == environmentVariable ? _self.environmentVariable : environmentVariable // ignore: cast_nullable_to_non_nullable
as String?,defaultModelId: freezed == defaultModelId ? _self.defaultModelId : defaultModelId // ignore: cast_nullable_to_non_nullable
as String?,visibleModelIds: null == visibleModelIds ? _self.visibleModelIds : visibleModelIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ApiProviderDto].
extension ApiProviderDtoPatterns on ApiProviderDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApiProviderDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApiProviderDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApiProviderDto value)  $default,){
final _that = this;
switch (_that) {
case _ApiProviderDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApiProviderDto value)?  $default,){
final _that = this;
switch (_that) {
case _ApiProviderDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String presetId,  String baseUrl,  ApiTransport transport,  CredentialSource credentialSource,  bool credentialConfigured,  bool enabled,  bool strictToolSchema,  DateTime createdAt,  DateTime updatedAt,  String? environmentVariable,  String? defaultModelId,  List<String> visibleModelIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApiProviderDto() when $default != null:
return $default(_that.id,_that.name,_that.presetId,_that.baseUrl,_that.transport,_that.credentialSource,_that.credentialConfigured,_that.enabled,_that.strictToolSchema,_that.createdAt,_that.updatedAt,_that.environmentVariable,_that.defaultModelId,_that.visibleModelIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String presetId,  String baseUrl,  ApiTransport transport,  CredentialSource credentialSource,  bool credentialConfigured,  bool enabled,  bool strictToolSchema,  DateTime createdAt,  DateTime updatedAt,  String? environmentVariable,  String? defaultModelId,  List<String> visibleModelIds)  $default,) {final _that = this;
switch (_that) {
case _ApiProviderDto():
return $default(_that.id,_that.name,_that.presetId,_that.baseUrl,_that.transport,_that.credentialSource,_that.credentialConfigured,_that.enabled,_that.strictToolSchema,_that.createdAt,_that.updatedAt,_that.environmentVariable,_that.defaultModelId,_that.visibleModelIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String presetId,  String baseUrl,  ApiTransport transport,  CredentialSource credentialSource,  bool credentialConfigured,  bool enabled,  bool strictToolSchema,  DateTime createdAt,  DateTime updatedAt,  String? environmentVariable,  String? defaultModelId,  List<String> visibleModelIds)?  $default,) {final _that = this;
switch (_that) {
case _ApiProviderDto() when $default != null:
return $default(_that.id,_that.name,_that.presetId,_that.baseUrl,_that.transport,_that.credentialSource,_that.credentialConfigured,_that.enabled,_that.strictToolSchema,_that.createdAt,_that.updatedAt,_that.environmentVariable,_that.defaultModelId,_that.visibleModelIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApiProviderDto implements ApiProviderDto {
  const _ApiProviderDto({required this.id, required this.name, required this.presetId, required this.baseUrl, required this.transport, required this.credentialSource, required this.credentialConfigured, required this.enabled, required this.strictToolSchema, required this.createdAt, required this.updatedAt, this.environmentVariable, this.defaultModelId, final  List<String> visibleModelIds = const <String>[]}): _visibleModelIds = visibleModelIds;
  factory _ApiProviderDto.fromJson(Map<String, dynamic> json) => _$ApiProviderDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String presetId;
@override final  String baseUrl;
@override final  ApiTransport transport;
@override final  CredentialSource credentialSource;
@override final  bool credentialConfigured;
@override final  bool enabled;
@override final  bool strictToolSchema;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? environmentVariable;
@override final  String? defaultModelId;
 final  List<String> _visibleModelIds;
@override@JsonKey() List<String> get visibleModelIds {
  if (_visibleModelIds is EqualUnmodifiableListView) return _visibleModelIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_visibleModelIds);
}


/// Create a copy of ApiProviderDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApiProviderDtoCopyWith<_ApiProviderDto> get copyWith => __$ApiProviderDtoCopyWithImpl<_ApiProviderDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApiProviderDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApiProviderDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.presetId, presetId) || other.presetId == presetId)&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.credentialSource, credentialSource) || other.credentialSource == credentialSource)&&(identical(other.credentialConfigured, credentialConfigured) || other.credentialConfigured == credentialConfigured)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.strictToolSchema, strictToolSchema) || other.strictToolSchema == strictToolSchema)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.environmentVariable, environmentVariable) || other.environmentVariable == environmentVariable)&&(identical(other.defaultModelId, defaultModelId) || other.defaultModelId == defaultModelId)&&const DeepCollectionEquality().equals(other._visibleModelIds, _visibleModelIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,presetId,baseUrl,transport,credentialSource,credentialConfigured,enabled,strictToolSchema,createdAt,updatedAt,environmentVariable,defaultModelId,const DeepCollectionEquality().hash(_visibleModelIds));

@override
String toString() {
  return 'ApiProviderDto(id: $id, name: $name, presetId: $presetId, baseUrl: $baseUrl, transport: $transport, credentialSource: $credentialSource, credentialConfigured: $credentialConfigured, enabled: $enabled, strictToolSchema: $strictToolSchema, createdAt: $createdAt, updatedAt: $updatedAt, environmentVariable: $environmentVariable, defaultModelId: $defaultModelId, visibleModelIds: $visibleModelIds)';
}


}

/// @nodoc
abstract mixin class _$ApiProviderDtoCopyWith<$Res> implements $ApiProviderDtoCopyWith<$Res> {
  factory _$ApiProviderDtoCopyWith(_ApiProviderDto value, $Res Function(_ApiProviderDto) _then) = __$ApiProviderDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String presetId, String baseUrl, ApiTransport transport, CredentialSource credentialSource, bool credentialConfigured, bool enabled, bool strictToolSchema, DateTime createdAt, DateTime updatedAt, String? environmentVariable, String? defaultModelId, List<String> visibleModelIds
});




}
/// @nodoc
class __$ApiProviderDtoCopyWithImpl<$Res>
    implements _$ApiProviderDtoCopyWith<$Res> {
  __$ApiProviderDtoCopyWithImpl(this._self, this._then);

  final _ApiProviderDto _self;
  final $Res Function(_ApiProviderDto) _then;

/// Create a copy of ApiProviderDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? presetId = null,Object? baseUrl = null,Object? transport = null,Object? credentialSource = null,Object? credentialConfigured = null,Object? enabled = null,Object? strictToolSchema = null,Object? createdAt = null,Object? updatedAt = null,Object? environmentVariable = freezed,Object? defaultModelId = freezed,Object? visibleModelIds = null,}) {
  return _then(_ApiProviderDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,presetId: null == presetId ? _self.presetId : presetId // ignore: cast_nullable_to_non_nullable
as String,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as ApiTransport,credentialSource: null == credentialSource ? _self.credentialSource : credentialSource // ignore: cast_nullable_to_non_nullable
as CredentialSource,credentialConfigured: null == credentialConfigured ? _self.credentialConfigured : credentialConfigured // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,strictToolSchema: null == strictToolSchema ? _self.strictToolSchema : strictToolSchema // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,environmentVariable: freezed == environmentVariable ? _self.environmentVariable : environmentVariable // ignore: cast_nullable_to_non_nullable
as String?,defaultModelId: freezed == defaultModelId ? _self.defaultModelId : defaultModelId // ignore: cast_nullable_to_non_nullable
as String?,visibleModelIds: null == visibleModelIds ? _self._visibleModelIds : visibleModelIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$ProviderPresetDto {

 String get id; String get name; String get defaultBaseUrl; ApiTransport get defaultTransport; CredentialSource get defaultCredentialSource; bool get strictToolSchema; String? get defaultEnvironmentVariable; String? get defaultModelId; List<String> get modelIds;
/// Create a copy of ProviderPresetDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderPresetDtoCopyWith<ProviderPresetDto> get copyWith => _$ProviderPresetDtoCopyWithImpl<ProviderPresetDto>(this as ProviderPresetDto, _$identity);

  /// Serializes this ProviderPresetDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderPresetDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.defaultBaseUrl, defaultBaseUrl) || other.defaultBaseUrl == defaultBaseUrl)&&(identical(other.defaultTransport, defaultTransport) || other.defaultTransport == defaultTransport)&&(identical(other.defaultCredentialSource, defaultCredentialSource) || other.defaultCredentialSource == defaultCredentialSource)&&(identical(other.strictToolSchema, strictToolSchema) || other.strictToolSchema == strictToolSchema)&&(identical(other.defaultEnvironmentVariable, defaultEnvironmentVariable) || other.defaultEnvironmentVariable == defaultEnvironmentVariable)&&(identical(other.defaultModelId, defaultModelId) || other.defaultModelId == defaultModelId)&&const DeepCollectionEquality().equals(other.modelIds, modelIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,defaultBaseUrl,defaultTransport,defaultCredentialSource,strictToolSchema,defaultEnvironmentVariable,defaultModelId,const DeepCollectionEquality().hash(modelIds));

@override
String toString() {
  return 'ProviderPresetDto(id: $id, name: $name, defaultBaseUrl: $defaultBaseUrl, defaultTransport: $defaultTransport, defaultCredentialSource: $defaultCredentialSource, strictToolSchema: $strictToolSchema, defaultEnvironmentVariable: $defaultEnvironmentVariable, defaultModelId: $defaultModelId, modelIds: $modelIds)';
}


}

/// @nodoc
abstract mixin class $ProviderPresetDtoCopyWith<$Res>  {
  factory $ProviderPresetDtoCopyWith(ProviderPresetDto value, $Res Function(ProviderPresetDto) _then) = _$ProviderPresetDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String defaultBaseUrl, ApiTransport defaultTransport, CredentialSource defaultCredentialSource, bool strictToolSchema, String? defaultEnvironmentVariable, String? defaultModelId, List<String> modelIds
});




}
/// @nodoc
class _$ProviderPresetDtoCopyWithImpl<$Res>
    implements $ProviderPresetDtoCopyWith<$Res> {
  _$ProviderPresetDtoCopyWithImpl(this._self, this._then);

  final ProviderPresetDto _self;
  final $Res Function(ProviderPresetDto) _then;

/// Create a copy of ProviderPresetDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? defaultBaseUrl = null,Object? defaultTransport = null,Object? defaultCredentialSource = null,Object? strictToolSchema = null,Object? defaultEnvironmentVariable = freezed,Object? defaultModelId = freezed,Object? modelIds = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,defaultBaseUrl: null == defaultBaseUrl ? _self.defaultBaseUrl : defaultBaseUrl // ignore: cast_nullable_to_non_nullable
as String,defaultTransport: null == defaultTransport ? _self.defaultTransport : defaultTransport // ignore: cast_nullable_to_non_nullable
as ApiTransport,defaultCredentialSource: null == defaultCredentialSource ? _self.defaultCredentialSource : defaultCredentialSource // ignore: cast_nullable_to_non_nullable
as CredentialSource,strictToolSchema: null == strictToolSchema ? _self.strictToolSchema : strictToolSchema // ignore: cast_nullable_to_non_nullable
as bool,defaultEnvironmentVariable: freezed == defaultEnvironmentVariable ? _self.defaultEnvironmentVariable : defaultEnvironmentVariable // ignore: cast_nullable_to_non_nullable
as String?,defaultModelId: freezed == defaultModelId ? _self.defaultModelId : defaultModelId // ignore: cast_nullable_to_non_nullable
as String?,modelIds: null == modelIds ? _self.modelIds : modelIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderPresetDto].
extension ProviderPresetDtoPatterns on ProviderPresetDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderPresetDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderPresetDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderPresetDto value)  $default,){
final _that = this;
switch (_that) {
case _ProviderPresetDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderPresetDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderPresetDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String defaultBaseUrl,  ApiTransport defaultTransport,  CredentialSource defaultCredentialSource,  bool strictToolSchema,  String? defaultEnvironmentVariable,  String? defaultModelId,  List<String> modelIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderPresetDto() when $default != null:
return $default(_that.id,_that.name,_that.defaultBaseUrl,_that.defaultTransport,_that.defaultCredentialSource,_that.strictToolSchema,_that.defaultEnvironmentVariable,_that.defaultModelId,_that.modelIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String defaultBaseUrl,  ApiTransport defaultTransport,  CredentialSource defaultCredentialSource,  bool strictToolSchema,  String? defaultEnvironmentVariable,  String? defaultModelId,  List<String> modelIds)  $default,) {final _that = this;
switch (_that) {
case _ProviderPresetDto():
return $default(_that.id,_that.name,_that.defaultBaseUrl,_that.defaultTransport,_that.defaultCredentialSource,_that.strictToolSchema,_that.defaultEnvironmentVariable,_that.defaultModelId,_that.modelIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String defaultBaseUrl,  ApiTransport defaultTransport,  CredentialSource defaultCredentialSource,  bool strictToolSchema,  String? defaultEnvironmentVariable,  String? defaultModelId,  List<String> modelIds)?  $default,) {final _that = this;
switch (_that) {
case _ProviderPresetDto() when $default != null:
return $default(_that.id,_that.name,_that.defaultBaseUrl,_that.defaultTransport,_that.defaultCredentialSource,_that.strictToolSchema,_that.defaultEnvironmentVariable,_that.defaultModelId,_that.modelIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderPresetDto implements ProviderPresetDto {
  const _ProviderPresetDto({required this.id, required this.name, required this.defaultBaseUrl, required this.defaultTransport, required this.defaultCredentialSource, required this.strictToolSchema, this.defaultEnvironmentVariable, this.defaultModelId, final  List<String> modelIds = const <String>[]}): _modelIds = modelIds;
  factory _ProviderPresetDto.fromJson(Map<String, dynamic> json) => _$ProviderPresetDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String defaultBaseUrl;
@override final  ApiTransport defaultTransport;
@override final  CredentialSource defaultCredentialSource;
@override final  bool strictToolSchema;
@override final  String? defaultEnvironmentVariable;
@override final  String? defaultModelId;
 final  List<String> _modelIds;
@override@JsonKey() List<String> get modelIds {
  if (_modelIds is EqualUnmodifiableListView) return _modelIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modelIds);
}


/// Create a copy of ProviderPresetDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderPresetDtoCopyWith<_ProviderPresetDto> get copyWith => __$ProviderPresetDtoCopyWithImpl<_ProviderPresetDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderPresetDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderPresetDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.defaultBaseUrl, defaultBaseUrl) || other.defaultBaseUrl == defaultBaseUrl)&&(identical(other.defaultTransport, defaultTransport) || other.defaultTransport == defaultTransport)&&(identical(other.defaultCredentialSource, defaultCredentialSource) || other.defaultCredentialSource == defaultCredentialSource)&&(identical(other.strictToolSchema, strictToolSchema) || other.strictToolSchema == strictToolSchema)&&(identical(other.defaultEnvironmentVariable, defaultEnvironmentVariable) || other.defaultEnvironmentVariable == defaultEnvironmentVariable)&&(identical(other.defaultModelId, defaultModelId) || other.defaultModelId == defaultModelId)&&const DeepCollectionEquality().equals(other._modelIds, _modelIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,defaultBaseUrl,defaultTransport,defaultCredentialSource,strictToolSchema,defaultEnvironmentVariable,defaultModelId,const DeepCollectionEquality().hash(_modelIds));

@override
String toString() {
  return 'ProviderPresetDto(id: $id, name: $name, defaultBaseUrl: $defaultBaseUrl, defaultTransport: $defaultTransport, defaultCredentialSource: $defaultCredentialSource, strictToolSchema: $strictToolSchema, defaultEnvironmentVariable: $defaultEnvironmentVariable, defaultModelId: $defaultModelId, modelIds: $modelIds)';
}


}

/// @nodoc
abstract mixin class _$ProviderPresetDtoCopyWith<$Res> implements $ProviderPresetDtoCopyWith<$Res> {
  factory _$ProviderPresetDtoCopyWith(_ProviderPresetDto value, $Res Function(_ProviderPresetDto) _then) = __$ProviderPresetDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String defaultBaseUrl, ApiTransport defaultTransport, CredentialSource defaultCredentialSource, bool strictToolSchema, String? defaultEnvironmentVariable, String? defaultModelId, List<String> modelIds
});




}
/// @nodoc
class __$ProviderPresetDtoCopyWithImpl<$Res>
    implements _$ProviderPresetDtoCopyWith<$Res> {
  __$ProviderPresetDtoCopyWithImpl(this._self, this._then);

  final _ProviderPresetDto _self;
  final $Res Function(_ProviderPresetDto) _then;

/// Create a copy of ProviderPresetDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? defaultBaseUrl = null,Object? defaultTransport = null,Object? defaultCredentialSource = null,Object? strictToolSchema = null,Object? defaultEnvironmentVariable = freezed,Object? defaultModelId = freezed,Object? modelIds = null,}) {
  return _then(_ProviderPresetDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,defaultBaseUrl: null == defaultBaseUrl ? _self.defaultBaseUrl : defaultBaseUrl // ignore: cast_nullable_to_non_nullable
as String,defaultTransport: null == defaultTransport ? _self.defaultTransport : defaultTransport // ignore: cast_nullable_to_non_nullable
as ApiTransport,defaultCredentialSource: null == defaultCredentialSource ? _self.defaultCredentialSource : defaultCredentialSource // ignore: cast_nullable_to_non_nullable
as CredentialSource,strictToolSchema: null == strictToolSchema ? _self.strictToolSchema : strictToolSchema // ignore: cast_nullable_to_non_nullable
as bool,defaultEnvironmentVariable: freezed == defaultEnvironmentVariable ? _self.defaultEnvironmentVariable : defaultEnvironmentVariable // ignore: cast_nullable_to_non_nullable
as String?,defaultModelId: freezed == defaultModelId ? _self.defaultModelId : defaultModelId // ignore: cast_nullable_to_non_nullable
as String?,modelIds: null == modelIds ? _self._modelIds : modelIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$ProviderModelDto {

 String get providerId; String get id; String get label; ProviderModelSource get source; ModelCapabilitiesDto get capabilities; DiagnosticStatus get diagnosticStatus; DateTime? get verifiedAt; String? get diagnosticError;
/// Create a copy of ProviderModelDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderModelDtoCopyWith<ProviderModelDto> get copyWith => _$ProviderModelDtoCopyWithImpl<ProviderModelDto>(this as ProviderModelDto, _$identity);

  /// Serializes this ProviderModelDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderModelDto&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.source, source) || other.source == source)&&(identical(other.capabilities, capabilities) || other.capabilities == capabilities)&&(identical(other.diagnosticStatus, diagnosticStatus) || other.diagnosticStatus == diagnosticStatus)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt)&&(identical(other.diagnosticError, diagnosticError) || other.diagnosticError == diagnosticError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerId,id,label,source,capabilities,diagnosticStatus,verifiedAt,diagnosticError);

@override
String toString() {
  return 'ProviderModelDto(providerId: $providerId, id: $id, label: $label, source: $source, capabilities: $capabilities, diagnosticStatus: $diagnosticStatus, verifiedAt: $verifiedAt, diagnosticError: $diagnosticError)';
}


}

/// @nodoc
abstract mixin class $ProviderModelDtoCopyWith<$Res>  {
  factory $ProviderModelDtoCopyWith(ProviderModelDto value, $Res Function(ProviderModelDto) _then) = _$ProviderModelDtoCopyWithImpl;
@useResult
$Res call({
 String providerId, String id, String label, ProviderModelSource source, ModelCapabilitiesDto capabilities, DiagnosticStatus diagnosticStatus, DateTime? verifiedAt, String? diagnosticError
});


$ModelCapabilitiesDtoCopyWith<$Res> get capabilities;

}
/// @nodoc
class _$ProviderModelDtoCopyWithImpl<$Res>
    implements $ProviderModelDtoCopyWith<$Res> {
  _$ProviderModelDtoCopyWithImpl(this._self, this._then);

  final ProviderModelDto _self;
  final $Res Function(ProviderModelDto) _then;

/// Create a copy of ProviderModelDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? providerId = null,Object? id = null,Object? label = null,Object? source = null,Object? capabilities = null,Object? diagnosticStatus = null,Object? verifiedAt = freezed,Object? diagnosticError = freezed,}) {
  return _then(_self.copyWith(
providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ProviderModelSource,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as ModelCapabilitiesDto,diagnosticStatus: null == diagnosticStatus ? _self.diagnosticStatus : diagnosticStatus // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String providerId,  String id,  String label,  ProviderModelSource source,  ModelCapabilitiesDto capabilities,  DiagnosticStatus diagnosticStatus,  DateTime? verifiedAt,  String? diagnosticError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderModelDto() when $default != null:
return $default(_that.providerId,_that.id,_that.label,_that.source,_that.capabilities,_that.diagnosticStatus,_that.verifiedAt,_that.diagnosticError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String providerId,  String id,  String label,  ProviderModelSource source,  ModelCapabilitiesDto capabilities,  DiagnosticStatus diagnosticStatus,  DateTime? verifiedAt,  String? diagnosticError)  $default,) {final _that = this;
switch (_that) {
case _ProviderModelDto():
return $default(_that.providerId,_that.id,_that.label,_that.source,_that.capabilities,_that.diagnosticStatus,_that.verifiedAt,_that.diagnosticError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String providerId,  String id,  String label,  ProviderModelSource source,  ModelCapabilitiesDto capabilities,  DiagnosticStatus diagnosticStatus,  DateTime? verifiedAt,  String? diagnosticError)?  $default,) {final _that = this;
switch (_that) {
case _ProviderModelDto() when $default != null:
return $default(_that.providerId,_that.id,_that.label,_that.source,_that.capabilities,_that.diagnosticStatus,_that.verifiedAt,_that.diagnosticError);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderModelDto implements ProviderModelDto {
  const _ProviderModelDto({required this.providerId, required this.id, required this.label, required this.source, required this.capabilities, this.diagnosticStatus = DiagnosticStatus.unknown, this.verifiedAt, this.diagnosticError});
  factory _ProviderModelDto.fromJson(Map<String, dynamic> json) => _$ProviderModelDtoFromJson(json);

@override final  String providerId;
@override final  String id;
@override final  String label;
@override final  ProviderModelSource source;
@override final  ModelCapabilitiesDto capabilities;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderModelDto&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.source, source) || other.source == source)&&(identical(other.capabilities, capabilities) || other.capabilities == capabilities)&&(identical(other.diagnosticStatus, diagnosticStatus) || other.diagnosticStatus == diagnosticStatus)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt)&&(identical(other.diagnosticError, diagnosticError) || other.diagnosticError == diagnosticError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerId,id,label,source,capabilities,diagnosticStatus,verifiedAt,diagnosticError);

@override
String toString() {
  return 'ProviderModelDto(providerId: $providerId, id: $id, label: $label, source: $source, capabilities: $capabilities, diagnosticStatus: $diagnosticStatus, verifiedAt: $verifiedAt, diagnosticError: $diagnosticError)';
}


}

/// @nodoc
abstract mixin class _$ProviderModelDtoCopyWith<$Res> implements $ProviderModelDtoCopyWith<$Res> {
  factory _$ProviderModelDtoCopyWith(_ProviderModelDto value, $Res Function(_ProviderModelDto) _then) = __$ProviderModelDtoCopyWithImpl;
@override @useResult
$Res call({
 String providerId, String id, String label, ProviderModelSource source, ModelCapabilitiesDto capabilities, DiagnosticStatus diagnosticStatus, DateTime? verifiedAt, String? diagnosticError
});


@override $ModelCapabilitiesDtoCopyWith<$Res> get capabilities;

}
/// @nodoc
class __$ProviderModelDtoCopyWithImpl<$Res>
    implements _$ProviderModelDtoCopyWith<$Res> {
  __$ProviderModelDtoCopyWithImpl(this._self, this._then);

  final _ProviderModelDto _self;
  final $Res Function(_ProviderModelDto) _then;

/// Create a copy of ProviderModelDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? providerId = null,Object? id = null,Object? label = null,Object? source = null,Object? capabilities = null,Object? diagnosticStatus = null,Object? verifiedAt = freezed,Object? diagnosticError = freezed,}) {
  return _then(_ProviderModelDto(
providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ProviderModelSource,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as ModelCapabilitiesDto,diagnosticStatus: null == diagnosticStatus ? _self.diagnosticStatus : diagnosticStatus // ignore: cast_nullable_to_non_nullable
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
}
}


/// @nodoc
mixin _$ProviderCatalogDto {

 List<ApiProviderDto> get providers; List<ProviderPresetDto> get presets; String? get defaultProviderId;
/// Create a copy of ProviderCatalogDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderCatalogDtoCopyWith<ProviderCatalogDto> get copyWith => _$ProviderCatalogDtoCopyWithImpl<ProviderCatalogDto>(this as ProviderCatalogDto, _$identity);

  /// Serializes this ProviderCatalogDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderCatalogDto&&const DeepCollectionEquality().equals(other.providers, providers)&&const DeepCollectionEquality().equals(other.presets, presets)&&(identical(other.defaultProviderId, defaultProviderId) || other.defaultProviderId == defaultProviderId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(providers),const DeepCollectionEquality().hash(presets),defaultProviderId);

@override
String toString() {
  return 'ProviderCatalogDto(providers: $providers, presets: $presets, defaultProviderId: $defaultProviderId)';
}


}

/// @nodoc
abstract mixin class $ProviderCatalogDtoCopyWith<$Res>  {
  factory $ProviderCatalogDtoCopyWith(ProviderCatalogDto value, $Res Function(ProviderCatalogDto) _then) = _$ProviderCatalogDtoCopyWithImpl;
@useResult
$Res call({
 List<ApiProviderDto> providers, List<ProviderPresetDto> presets, String? defaultProviderId
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
@pragma('vm:prefer-inline') @override $Res call({Object? providers = null,Object? presets = null,Object? defaultProviderId = freezed,}) {
  return _then(_self.copyWith(
providers: null == providers ? _self.providers : providers // ignore: cast_nullable_to_non_nullable
as List<ApiProviderDto>,presets: null == presets ? _self.presets : presets // ignore: cast_nullable_to_non_nullable
as List<ProviderPresetDto>,defaultProviderId: freezed == defaultProviderId ? _self.defaultProviderId : defaultProviderId // ignore: cast_nullable_to_non_nullable
as String?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ApiProviderDto> providers,  List<ProviderPresetDto> presets,  String? defaultProviderId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderCatalogDto() when $default != null:
return $default(_that.providers,_that.presets,_that.defaultProviderId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ApiProviderDto> providers,  List<ProviderPresetDto> presets,  String? defaultProviderId)  $default,) {final _that = this;
switch (_that) {
case _ProviderCatalogDto():
return $default(_that.providers,_that.presets,_that.defaultProviderId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ApiProviderDto> providers,  List<ProviderPresetDto> presets,  String? defaultProviderId)?  $default,) {final _that = this;
switch (_that) {
case _ProviderCatalogDto() when $default != null:
return $default(_that.providers,_that.presets,_that.defaultProviderId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderCatalogDto implements ProviderCatalogDto {
  const _ProviderCatalogDto({required final  List<ApiProviderDto> providers, required final  List<ProviderPresetDto> presets, this.defaultProviderId}): _providers = providers,_presets = presets;
  factory _ProviderCatalogDto.fromJson(Map<String, dynamic> json) => _$ProviderCatalogDtoFromJson(json);

 final  List<ApiProviderDto> _providers;
@override List<ApiProviderDto> get providers {
  if (_providers is EqualUnmodifiableListView) return _providers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_providers);
}

 final  List<ProviderPresetDto> _presets;
@override List<ProviderPresetDto> get presets {
  if (_presets is EqualUnmodifiableListView) return _presets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_presets);
}

@override final  String? defaultProviderId;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderCatalogDto&&const DeepCollectionEquality().equals(other._providers, _providers)&&const DeepCollectionEquality().equals(other._presets, _presets)&&(identical(other.defaultProviderId, defaultProviderId) || other.defaultProviderId == defaultProviderId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_providers),const DeepCollectionEquality().hash(_presets),defaultProviderId);

@override
String toString() {
  return 'ProviderCatalogDto(providers: $providers, presets: $presets, defaultProviderId: $defaultProviderId)';
}


}

/// @nodoc
abstract mixin class _$ProviderCatalogDtoCopyWith<$Res> implements $ProviderCatalogDtoCopyWith<$Res> {
  factory _$ProviderCatalogDtoCopyWith(_ProviderCatalogDto value, $Res Function(_ProviderCatalogDto) _then) = __$ProviderCatalogDtoCopyWithImpl;
@override @useResult
$Res call({
 List<ApiProviderDto> providers, List<ProviderPresetDto> presets, String? defaultProviderId
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
@override @pragma('vm:prefer-inline') $Res call({Object? providers = null,Object? presets = null,Object? defaultProviderId = freezed,}) {
  return _then(_ProviderCatalogDto(
providers: null == providers ? _self._providers : providers // ignore: cast_nullable_to_non_nullable
as List<ApiProviderDto>,presets: null == presets ? _self._presets : presets // ignore: cast_nullable_to_non_nullable
as List<ProviderPresetDto>,defaultProviderId: freezed == defaultProviderId ? _self.defaultProviderId : defaultProviderId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ProviderDiagnosticDto {

 String get providerId; String get model; DiagnosticStatus get status; bool get endpointReachable; bool get streaming; bool get toolCalling; DateTime get checkedAt; String? get error;
/// Create a copy of ProviderDiagnosticDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderDiagnosticDtoCopyWith<ProviderDiagnosticDto> get copyWith => _$ProviderDiagnosticDtoCopyWithImpl<ProviderDiagnosticDto>(this as ProviderDiagnosticDto, _$identity);

  /// Serializes this ProviderDiagnosticDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderDiagnosticDto&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.model, model) || other.model == model)&&(identical(other.status, status) || other.status == status)&&(identical(other.endpointReachable, endpointReachable) || other.endpointReachable == endpointReachable)&&(identical(other.streaming, streaming) || other.streaming == streaming)&&(identical(other.toolCalling, toolCalling) || other.toolCalling == toolCalling)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerId,model,status,endpointReachable,streaming,toolCalling,checkedAt,error);

@override
String toString() {
  return 'ProviderDiagnosticDto(providerId: $providerId, model: $model, status: $status, endpointReachable: $endpointReachable, streaming: $streaming, toolCalling: $toolCalling, checkedAt: $checkedAt, error: $error)';
}


}

/// @nodoc
abstract mixin class $ProviderDiagnosticDtoCopyWith<$Res>  {
  factory $ProviderDiagnosticDtoCopyWith(ProviderDiagnosticDto value, $Res Function(ProviderDiagnosticDto) _then) = _$ProviderDiagnosticDtoCopyWithImpl;
@useResult
$Res call({
 String providerId, String model, DiagnosticStatus status, bool endpointReachable, bool streaming, bool toolCalling, DateTime checkedAt, String? error
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
@pragma('vm:prefer-inline') @override $Res call({Object? providerId = null,Object? model = null,Object? status = null,Object? endpointReachable = null,Object? streaming = null,Object? toolCalling = null,Object? checkedAt = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String providerId,  String model,  DiagnosticStatus status,  bool endpointReachable,  bool streaming,  bool toolCalling,  DateTime checkedAt,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderDiagnosticDto() when $default != null:
return $default(_that.providerId,_that.model,_that.status,_that.endpointReachable,_that.streaming,_that.toolCalling,_that.checkedAt,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String providerId,  String model,  DiagnosticStatus status,  bool endpointReachable,  bool streaming,  bool toolCalling,  DateTime checkedAt,  String? error)  $default,) {final _that = this;
switch (_that) {
case _ProviderDiagnosticDto():
return $default(_that.providerId,_that.model,_that.status,_that.endpointReachable,_that.streaming,_that.toolCalling,_that.checkedAt,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String providerId,  String model,  DiagnosticStatus status,  bool endpointReachable,  bool streaming,  bool toolCalling,  DateTime checkedAt,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _ProviderDiagnosticDto() when $default != null:
return $default(_that.providerId,_that.model,_that.status,_that.endpointReachable,_that.streaming,_that.toolCalling,_that.checkedAt,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderDiagnosticDto implements ProviderDiagnosticDto {
  const _ProviderDiagnosticDto({required this.providerId, required this.model, required this.status, required this.endpointReachable, required this.streaming, required this.toolCalling, required this.checkedAt, this.error});
  factory _ProviderDiagnosticDto.fromJson(Map<String, dynamic> json) => _$ProviderDiagnosticDtoFromJson(json);

@override final  String providerId;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderDiagnosticDto&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.model, model) || other.model == model)&&(identical(other.status, status) || other.status == status)&&(identical(other.endpointReachable, endpointReachable) || other.endpointReachable == endpointReachable)&&(identical(other.streaming, streaming) || other.streaming == streaming)&&(identical(other.toolCalling, toolCalling) || other.toolCalling == toolCalling)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerId,model,status,endpointReachable,streaming,toolCalling,checkedAt,error);

@override
String toString() {
  return 'ProviderDiagnosticDto(providerId: $providerId, model: $model, status: $status, endpointReachable: $endpointReachable, streaming: $streaming, toolCalling: $toolCalling, checkedAt: $checkedAt, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ProviderDiagnosticDtoCopyWith<$Res> implements $ProviderDiagnosticDtoCopyWith<$Res> {
  factory _$ProviderDiagnosticDtoCopyWith(_ProviderDiagnosticDto value, $Res Function(_ProviderDiagnosticDto) _then) = __$ProviderDiagnosticDtoCopyWithImpl;
@override @useResult
$Res call({
 String providerId, String model, DiagnosticStatus status, bool endpointReachable, bool streaming, bool toolCalling, DateTime checkedAt, String? error
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
@override @pragma('vm:prefer-inline') $Res call({Object? providerId = null,Object? model = null,Object? status = null,Object? endpointReachable = null,Object? streaming = null,Object? toolCalling = null,Object? checkedAt = null,Object? error = freezed,}) {
  return _then(_ProviderDiagnosticDto(
providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
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
