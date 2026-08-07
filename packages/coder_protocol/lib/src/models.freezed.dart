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
mixin _$ShellSpecDto {

 String get executable; List<String> get arguments;
/// Create a copy of ShellSpecDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShellSpecDtoCopyWith<ShellSpecDto> get copyWith => _$ShellSpecDtoCopyWithImpl<ShellSpecDto>(this as ShellSpecDto, _$identity);

  /// Serializes this ShellSpecDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShellSpecDto&&(identical(other.executable, executable) || other.executable == executable)&&const DeepCollectionEquality().equals(other.arguments, arguments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,executable,const DeepCollectionEquality().hash(arguments));

@override
String toString() {
  return 'ShellSpecDto(executable: $executable, arguments: $arguments)';
}


}

/// @nodoc
abstract mixin class $ShellSpecDtoCopyWith<$Res>  {
  factory $ShellSpecDtoCopyWith(ShellSpecDto value, $Res Function(ShellSpecDto) _then) = _$ShellSpecDtoCopyWithImpl;
@useResult
$Res call({
 String executable, List<String> arguments
});




}
/// @nodoc
class _$ShellSpecDtoCopyWithImpl<$Res>
    implements $ShellSpecDtoCopyWith<$Res> {
  _$ShellSpecDtoCopyWithImpl(this._self, this._then);

  final ShellSpecDto _self;
  final $Res Function(ShellSpecDto) _then;

/// Create a copy of ShellSpecDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? executable = null,Object? arguments = null,}) {
  return _then(_self.copyWith(
executable: null == executable ? _self.executable : executable // ignore: cast_nullable_to_non_nullable
as String,arguments: null == arguments ? _self.arguments : arguments // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ShellSpecDto].
extension ShellSpecDtoPatterns on ShellSpecDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShellSpecDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShellSpecDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShellSpecDto value)  $default,){
final _that = this;
switch (_that) {
case _ShellSpecDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShellSpecDto value)?  $default,){
final _that = this;
switch (_that) {
case _ShellSpecDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String executable,  List<String> arguments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShellSpecDto() when $default != null:
return $default(_that.executable,_that.arguments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String executable,  List<String> arguments)  $default,) {final _that = this;
switch (_that) {
case _ShellSpecDto():
return $default(_that.executable,_that.arguments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String executable,  List<String> arguments)?  $default,) {final _that = this;
switch (_that) {
case _ShellSpecDto() when $default != null:
return $default(_that.executable,_that.arguments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShellSpecDto implements ShellSpecDto {
  const _ShellSpecDto({required this.executable, final  List<String> arguments = const <String>[]}): _arguments = arguments;
  factory _ShellSpecDto.fromJson(Map<String, dynamic> json) => _$ShellSpecDtoFromJson(json);

@override final  String executable;
 final  List<String> _arguments;
@override@JsonKey() List<String> get arguments {
  if (_arguments is EqualUnmodifiableListView) return _arguments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_arguments);
}


/// Create a copy of ShellSpecDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShellSpecDtoCopyWith<_ShellSpecDto> get copyWith => __$ShellSpecDtoCopyWithImpl<_ShellSpecDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShellSpecDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShellSpecDto&&(identical(other.executable, executable) || other.executable == executable)&&const DeepCollectionEquality().equals(other._arguments, _arguments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,executable,const DeepCollectionEquality().hash(_arguments));

@override
String toString() {
  return 'ShellSpecDto(executable: $executable, arguments: $arguments)';
}


}

/// @nodoc
abstract mixin class _$ShellSpecDtoCopyWith<$Res> implements $ShellSpecDtoCopyWith<$Res> {
  factory _$ShellSpecDtoCopyWith(_ShellSpecDto value, $Res Function(_ShellSpecDto) _then) = __$ShellSpecDtoCopyWithImpl;
@override @useResult
$Res call({
 String executable, List<String> arguments
});




}
/// @nodoc
class __$ShellSpecDtoCopyWithImpl<$Res>
    implements _$ShellSpecDtoCopyWith<$Res> {
  __$ShellSpecDtoCopyWithImpl(this._self, this._then);

  final _ShellSpecDto _self;
  final $Res Function(_ShellSpecDto) _then;

/// Create a copy of ShellSpecDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? executable = null,Object? arguments = null,}) {
  return _then(_ShellSpecDto(
executable: null == executable ? _self.executable : executable // ignore: cast_nullable_to_non_nullable
as String,arguments: null == arguments ? _self._arguments : arguments // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$TerminalDto {

 String get id; String get worktreeId; String get title; ShellSpecDto get shell; TerminalStatus get status; int get columns; int get rows; int get lastSequence; int? get exitCode; String? get error;
/// Create a copy of TerminalDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TerminalDtoCopyWith<TerminalDto> get copyWith => _$TerminalDtoCopyWithImpl<TerminalDto>(this as TerminalDto, _$identity);

  /// Serializes this TerminalDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TerminalDto&&(identical(other.id, id) || other.id == id)&&(identical(other.worktreeId, worktreeId) || other.worktreeId == worktreeId)&&(identical(other.title, title) || other.title == title)&&(identical(other.shell, shell) || other.shell == shell)&&(identical(other.status, status) || other.status == status)&&(identical(other.columns, columns) || other.columns == columns)&&(identical(other.rows, rows) || other.rows == rows)&&(identical(other.lastSequence, lastSequence) || other.lastSequence == lastSequence)&&(identical(other.exitCode, exitCode) || other.exitCode == exitCode)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,worktreeId,title,shell,status,columns,rows,lastSequence,exitCode,error);

@override
String toString() {
  return 'TerminalDto(id: $id, worktreeId: $worktreeId, title: $title, shell: $shell, status: $status, columns: $columns, rows: $rows, lastSequence: $lastSequence, exitCode: $exitCode, error: $error)';
}


}

/// @nodoc
abstract mixin class $TerminalDtoCopyWith<$Res>  {
  factory $TerminalDtoCopyWith(TerminalDto value, $Res Function(TerminalDto) _then) = _$TerminalDtoCopyWithImpl;
@useResult
$Res call({
 String id, String worktreeId, String title, ShellSpecDto shell, TerminalStatus status, int columns, int rows, int lastSequence, int? exitCode, String? error
});


$ShellSpecDtoCopyWith<$Res> get shell;

}
/// @nodoc
class _$TerminalDtoCopyWithImpl<$Res>
    implements $TerminalDtoCopyWith<$Res> {
  _$TerminalDtoCopyWithImpl(this._self, this._then);

  final TerminalDto _self;
  final $Res Function(TerminalDto) _then;

/// Create a copy of TerminalDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? worktreeId = null,Object? title = null,Object? shell = null,Object? status = null,Object? columns = null,Object? rows = null,Object? lastSequence = null,Object? exitCode = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,worktreeId: null == worktreeId ? _self.worktreeId : worktreeId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,shell: null == shell ? _self.shell : shell // ignore: cast_nullable_to_non_nullable
as ShellSpecDto,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TerminalStatus,columns: null == columns ? _self.columns : columns // ignore: cast_nullable_to_non_nullable
as int,rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as int,lastSequence: null == lastSequence ? _self.lastSequence : lastSequence // ignore: cast_nullable_to_non_nullable
as int,exitCode: freezed == exitCode ? _self.exitCode : exitCode // ignore: cast_nullable_to_non_nullable
as int?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of TerminalDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShellSpecDtoCopyWith<$Res> get shell {
  
  return $ShellSpecDtoCopyWith<$Res>(_self.shell, (value) {
    return _then(_self.copyWith(shell: value));
  });
}
}


/// Adds pattern-matching-related methods to [TerminalDto].
extension TerminalDtoPatterns on TerminalDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TerminalDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TerminalDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TerminalDto value)  $default,){
final _that = this;
switch (_that) {
case _TerminalDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TerminalDto value)?  $default,){
final _that = this;
switch (_that) {
case _TerminalDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String worktreeId,  String title,  ShellSpecDto shell,  TerminalStatus status,  int columns,  int rows,  int lastSequence,  int? exitCode,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TerminalDto() when $default != null:
return $default(_that.id,_that.worktreeId,_that.title,_that.shell,_that.status,_that.columns,_that.rows,_that.lastSequence,_that.exitCode,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String worktreeId,  String title,  ShellSpecDto shell,  TerminalStatus status,  int columns,  int rows,  int lastSequence,  int? exitCode,  String? error)  $default,) {final _that = this;
switch (_that) {
case _TerminalDto():
return $default(_that.id,_that.worktreeId,_that.title,_that.shell,_that.status,_that.columns,_that.rows,_that.lastSequence,_that.exitCode,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String worktreeId,  String title,  ShellSpecDto shell,  TerminalStatus status,  int columns,  int rows,  int lastSequence,  int? exitCode,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _TerminalDto() when $default != null:
return $default(_that.id,_that.worktreeId,_that.title,_that.shell,_that.status,_that.columns,_that.rows,_that.lastSequence,_that.exitCode,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TerminalDto implements TerminalDto {
  const _TerminalDto({required this.id, required this.worktreeId, required this.title, required this.shell, required this.status, required this.columns, required this.rows, required this.lastSequence, this.exitCode, this.error});
  factory _TerminalDto.fromJson(Map<String, dynamic> json) => _$TerminalDtoFromJson(json);

@override final  String id;
@override final  String worktreeId;
@override final  String title;
@override final  ShellSpecDto shell;
@override final  TerminalStatus status;
@override final  int columns;
@override final  int rows;
@override final  int lastSequence;
@override final  int? exitCode;
@override final  String? error;

/// Create a copy of TerminalDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TerminalDtoCopyWith<_TerminalDto> get copyWith => __$TerminalDtoCopyWithImpl<_TerminalDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TerminalDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TerminalDto&&(identical(other.id, id) || other.id == id)&&(identical(other.worktreeId, worktreeId) || other.worktreeId == worktreeId)&&(identical(other.title, title) || other.title == title)&&(identical(other.shell, shell) || other.shell == shell)&&(identical(other.status, status) || other.status == status)&&(identical(other.columns, columns) || other.columns == columns)&&(identical(other.rows, rows) || other.rows == rows)&&(identical(other.lastSequence, lastSequence) || other.lastSequence == lastSequence)&&(identical(other.exitCode, exitCode) || other.exitCode == exitCode)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,worktreeId,title,shell,status,columns,rows,lastSequence,exitCode,error);

@override
String toString() {
  return 'TerminalDto(id: $id, worktreeId: $worktreeId, title: $title, shell: $shell, status: $status, columns: $columns, rows: $rows, lastSequence: $lastSequence, exitCode: $exitCode, error: $error)';
}


}

/// @nodoc
abstract mixin class _$TerminalDtoCopyWith<$Res> implements $TerminalDtoCopyWith<$Res> {
  factory _$TerminalDtoCopyWith(_TerminalDto value, $Res Function(_TerminalDto) _then) = __$TerminalDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String worktreeId, String title, ShellSpecDto shell, TerminalStatus status, int columns, int rows, int lastSequence, int? exitCode, String? error
});


@override $ShellSpecDtoCopyWith<$Res> get shell;

}
/// @nodoc
class __$TerminalDtoCopyWithImpl<$Res>
    implements _$TerminalDtoCopyWith<$Res> {
  __$TerminalDtoCopyWithImpl(this._self, this._then);

  final _TerminalDto _self;
  final $Res Function(_TerminalDto) _then;

/// Create a copy of TerminalDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? worktreeId = null,Object? title = null,Object? shell = null,Object? status = null,Object? columns = null,Object? rows = null,Object? lastSequence = null,Object? exitCode = freezed,Object? error = freezed,}) {
  return _then(_TerminalDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,worktreeId: null == worktreeId ? _self.worktreeId : worktreeId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,shell: null == shell ? _self.shell : shell // ignore: cast_nullable_to_non_nullable
as ShellSpecDto,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TerminalStatus,columns: null == columns ? _self.columns : columns // ignore: cast_nullable_to_non_nullable
as int,rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as int,lastSequence: null == lastSequence ? _self.lastSequence : lastSequence // ignore: cast_nullable_to_non_nullable
as int,exitCode: freezed == exitCode ? _self.exitCode : exitCode // ignore: cast_nullable_to_non_nullable
as int?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of TerminalDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShellSpecDtoCopyWith<$Res> get shell {
  
  return $ShellSpecDtoCopyWith<$Res>(_self.shell, (value) {
    return _then(_self.copyWith(shell: value));
  });
}
}


/// @nodoc
mixin _$TerminalOutputDto {

 String get terminalId; int get sequence; String get data;
/// Create a copy of TerminalOutputDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TerminalOutputDtoCopyWith<TerminalOutputDto> get copyWith => _$TerminalOutputDtoCopyWithImpl<TerminalOutputDto>(this as TerminalOutputDto, _$identity);

  /// Serializes this TerminalOutputDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TerminalOutputDto&&(identical(other.terminalId, terminalId) || other.terminalId == terminalId)&&(identical(other.sequence, sequence) || other.sequence == sequence)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,terminalId,sequence,data);

@override
String toString() {
  return 'TerminalOutputDto(terminalId: $terminalId, sequence: $sequence, data: $data)';
}


}

/// @nodoc
abstract mixin class $TerminalOutputDtoCopyWith<$Res>  {
  factory $TerminalOutputDtoCopyWith(TerminalOutputDto value, $Res Function(TerminalOutputDto) _then) = _$TerminalOutputDtoCopyWithImpl;
@useResult
$Res call({
 String terminalId, int sequence, String data
});




}
/// @nodoc
class _$TerminalOutputDtoCopyWithImpl<$Res>
    implements $TerminalOutputDtoCopyWith<$Res> {
  _$TerminalOutputDtoCopyWithImpl(this._self, this._then);

  final TerminalOutputDto _self;
  final $Res Function(TerminalOutputDto) _then;

/// Create a copy of TerminalOutputDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? terminalId = null,Object? sequence = null,Object? data = null,}) {
  return _then(_self.copyWith(
terminalId: null == terminalId ? _self.terminalId : terminalId // ignore: cast_nullable_to_non_nullable
as String,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TerminalOutputDto].
extension TerminalOutputDtoPatterns on TerminalOutputDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TerminalOutputDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TerminalOutputDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TerminalOutputDto value)  $default,){
final _that = this;
switch (_that) {
case _TerminalOutputDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TerminalOutputDto value)?  $default,){
final _that = this;
switch (_that) {
case _TerminalOutputDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String terminalId,  int sequence,  String data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TerminalOutputDto() when $default != null:
return $default(_that.terminalId,_that.sequence,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String terminalId,  int sequence,  String data)  $default,) {final _that = this;
switch (_that) {
case _TerminalOutputDto():
return $default(_that.terminalId,_that.sequence,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String terminalId,  int sequence,  String data)?  $default,) {final _that = this;
switch (_that) {
case _TerminalOutputDto() when $default != null:
return $default(_that.terminalId,_that.sequence,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TerminalOutputDto implements TerminalOutputDto {
  const _TerminalOutputDto({required this.terminalId, required this.sequence, required this.data});
  factory _TerminalOutputDto.fromJson(Map<String, dynamic> json) => _$TerminalOutputDtoFromJson(json);

@override final  String terminalId;
@override final  int sequence;
@override final  String data;

/// Create a copy of TerminalOutputDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TerminalOutputDtoCopyWith<_TerminalOutputDto> get copyWith => __$TerminalOutputDtoCopyWithImpl<_TerminalOutputDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TerminalOutputDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TerminalOutputDto&&(identical(other.terminalId, terminalId) || other.terminalId == terminalId)&&(identical(other.sequence, sequence) || other.sequence == sequence)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,terminalId,sequence,data);

@override
String toString() {
  return 'TerminalOutputDto(terminalId: $terminalId, sequence: $sequence, data: $data)';
}


}

/// @nodoc
abstract mixin class _$TerminalOutputDtoCopyWith<$Res> implements $TerminalOutputDtoCopyWith<$Res> {
  factory _$TerminalOutputDtoCopyWith(_TerminalOutputDto value, $Res Function(_TerminalOutputDto) _then) = __$TerminalOutputDtoCopyWithImpl;
@override @useResult
$Res call({
 String terminalId, int sequence, String data
});




}
/// @nodoc
class __$TerminalOutputDtoCopyWithImpl<$Res>
    implements _$TerminalOutputDtoCopyWith<$Res> {
  __$TerminalOutputDtoCopyWithImpl(this._self, this._then);

  final _TerminalOutputDto _self;
  final $Res Function(_TerminalOutputDto) _then;

/// Create a copy of TerminalOutputDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? terminalId = null,Object? sequence = null,Object? data = null,}) {
  return _then(_TerminalOutputDto(
terminalId: null == terminalId ? _self.terminalId : terminalId // ignore: cast_nullable_to_non_nullable
as String,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AttachmentDto {

 String get id; String get fileName; String get mimeType; int get byteSize; AttachmentKind get kind; String get sha256; DateTime get createdAt;
/// Create a copy of AttachmentDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttachmentDtoCopyWith<AttachmentDto> get copyWith => _$AttachmentDtoCopyWithImpl<AttachmentDto>(this as AttachmentDto, _$identity);

  /// Serializes this AttachmentDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttachmentDto&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.byteSize, byteSize) || other.byteSize == byteSize)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fileName,mimeType,byteSize,kind,sha256,createdAt);

@override
String toString() {
  return 'AttachmentDto(id: $id, fileName: $fileName, mimeType: $mimeType, byteSize: $byteSize, kind: $kind, sha256: $sha256, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AttachmentDtoCopyWith<$Res>  {
  factory $AttachmentDtoCopyWith(AttachmentDto value, $Res Function(AttachmentDto) _then) = _$AttachmentDtoCopyWithImpl;
@useResult
$Res call({
 String id, String fileName, String mimeType, int byteSize, AttachmentKind kind, String sha256, DateTime createdAt
});




}
/// @nodoc
class _$AttachmentDtoCopyWithImpl<$Res>
    implements $AttachmentDtoCopyWith<$Res> {
  _$AttachmentDtoCopyWithImpl(this._self, this._then);

  final AttachmentDto _self;
  final $Res Function(AttachmentDto) _then;

/// Create a copy of AttachmentDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fileName = null,Object? mimeType = null,Object? byteSize = null,Object? kind = null,Object? sha256 = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,byteSize: null == byteSize ? _self.byteSize : byteSize // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AttachmentKind,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AttachmentDto].
extension AttachmentDtoPatterns on AttachmentDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttachmentDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttachmentDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttachmentDto value)  $default,){
final _that = this;
switch (_that) {
case _AttachmentDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttachmentDto value)?  $default,){
final _that = this;
switch (_that) {
case _AttachmentDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fileName,  String mimeType,  int byteSize,  AttachmentKind kind,  String sha256,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttachmentDto() when $default != null:
return $default(_that.id,_that.fileName,_that.mimeType,_that.byteSize,_that.kind,_that.sha256,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fileName,  String mimeType,  int byteSize,  AttachmentKind kind,  String sha256,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _AttachmentDto():
return $default(_that.id,_that.fileName,_that.mimeType,_that.byteSize,_that.kind,_that.sha256,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fileName,  String mimeType,  int byteSize,  AttachmentKind kind,  String sha256,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AttachmentDto() when $default != null:
return $default(_that.id,_that.fileName,_that.mimeType,_that.byteSize,_that.kind,_that.sha256,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttachmentDto implements AttachmentDto {
  const _AttachmentDto({required this.id, required this.fileName, required this.mimeType, required this.byteSize, required this.kind, required this.sha256, required this.createdAt});
  factory _AttachmentDto.fromJson(Map<String, dynamic> json) => _$AttachmentDtoFromJson(json);

@override final  String id;
@override final  String fileName;
@override final  String mimeType;
@override final  int byteSize;
@override final  AttachmentKind kind;
@override final  String sha256;
@override final  DateTime createdAt;

/// Create a copy of AttachmentDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttachmentDtoCopyWith<_AttachmentDto> get copyWith => __$AttachmentDtoCopyWithImpl<_AttachmentDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttachmentDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttachmentDto&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.byteSize, byteSize) || other.byteSize == byteSize)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fileName,mimeType,byteSize,kind,sha256,createdAt);

@override
String toString() {
  return 'AttachmentDto(id: $id, fileName: $fileName, mimeType: $mimeType, byteSize: $byteSize, kind: $kind, sha256: $sha256, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AttachmentDtoCopyWith<$Res> implements $AttachmentDtoCopyWith<$Res> {
  factory _$AttachmentDtoCopyWith(_AttachmentDto value, $Res Function(_AttachmentDto) _then) = __$AttachmentDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String fileName, String mimeType, int byteSize, AttachmentKind kind, String sha256, DateTime createdAt
});




}
/// @nodoc
class __$AttachmentDtoCopyWithImpl<$Res>
    implements _$AttachmentDtoCopyWith<$Res> {
  __$AttachmentDtoCopyWithImpl(this._self, this._then);

  final _AttachmentDto _self;
  final $Res Function(_AttachmentDto) _then;

/// Create a copy of AttachmentDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fileName = null,Object? mimeType = null,Object? byteSize = null,Object? kind = null,Object? sha256 = null,Object? createdAt = null,}) {
  return _then(_AttachmentDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,byteSize: null == byteSize ? _self.byteSize : byteSize // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AttachmentKind,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


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
mixin _$ProjectSettingsDto {

 List<String> get setup; List<String> get teardown; ShellSpecDto? get shell;
/// Create a copy of ProjectSettingsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectSettingsDtoCopyWith<ProjectSettingsDto> get copyWith => _$ProjectSettingsDtoCopyWithImpl<ProjectSettingsDto>(this as ProjectSettingsDto, _$identity);

  /// Serializes this ProjectSettingsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSettingsDto&&const DeepCollectionEquality().equals(other.setup, setup)&&const DeepCollectionEquality().equals(other.teardown, teardown)&&(identical(other.shell, shell) || other.shell == shell));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(setup),const DeepCollectionEquality().hash(teardown),shell);

@override
String toString() {
  return 'ProjectSettingsDto(setup: $setup, teardown: $teardown, shell: $shell)';
}


}

/// @nodoc
abstract mixin class $ProjectSettingsDtoCopyWith<$Res>  {
  factory $ProjectSettingsDtoCopyWith(ProjectSettingsDto value, $Res Function(ProjectSettingsDto) _then) = _$ProjectSettingsDtoCopyWithImpl;
@useResult
$Res call({
 List<String> setup, List<String> teardown, ShellSpecDto? shell
});


$ShellSpecDtoCopyWith<$Res>? get shell;

}
/// @nodoc
class _$ProjectSettingsDtoCopyWithImpl<$Res>
    implements $ProjectSettingsDtoCopyWith<$Res> {
  _$ProjectSettingsDtoCopyWithImpl(this._self, this._then);

  final ProjectSettingsDto _self;
  final $Res Function(ProjectSettingsDto) _then;

/// Create a copy of ProjectSettingsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? setup = null,Object? teardown = null,Object? shell = freezed,}) {
  return _then(_self.copyWith(
setup: null == setup ? _self.setup : setup // ignore: cast_nullable_to_non_nullable
as List<String>,teardown: null == teardown ? _self.teardown : teardown // ignore: cast_nullable_to_non_nullable
as List<String>,shell: freezed == shell ? _self.shell : shell // ignore: cast_nullable_to_non_nullable
as ShellSpecDto?,
  ));
}
/// Create a copy of ProjectSettingsDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShellSpecDtoCopyWith<$Res>? get shell {
    if (_self.shell == null) {
    return null;
  }

  return $ShellSpecDtoCopyWith<$Res>(_self.shell!, (value) {
    return _then(_self.copyWith(shell: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectSettingsDto].
extension ProjectSettingsDtoPatterns on ProjectSettingsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectSettingsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectSettingsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectSettingsDto value)  $default,){
final _that = this;
switch (_that) {
case _ProjectSettingsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectSettingsDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectSettingsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> setup,  List<String> teardown,  ShellSpecDto? shell)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectSettingsDto() when $default != null:
return $default(_that.setup,_that.teardown,_that.shell);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> setup,  List<String> teardown,  ShellSpecDto? shell)  $default,) {final _that = this;
switch (_that) {
case _ProjectSettingsDto():
return $default(_that.setup,_that.teardown,_that.shell);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> setup,  List<String> teardown,  ShellSpecDto? shell)?  $default,) {final _that = this;
switch (_that) {
case _ProjectSettingsDto() when $default != null:
return $default(_that.setup,_that.teardown,_that.shell);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectSettingsDto implements ProjectSettingsDto {
  const _ProjectSettingsDto({final  List<String> setup = const <String>[], final  List<String> teardown = const <String>[], this.shell}): _setup = setup,_teardown = teardown;
  factory _ProjectSettingsDto.fromJson(Map<String, dynamic> json) => _$ProjectSettingsDtoFromJson(json);

 final  List<String> _setup;
@override@JsonKey() List<String> get setup {
  if (_setup is EqualUnmodifiableListView) return _setup;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_setup);
}

 final  List<String> _teardown;
@override@JsonKey() List<String> get teardown {
  if (_teardown is EqualUnmodifiableListView) return _teardown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_teardown);
}

@override final  ShellSpecDto? shell;

/// Create a copy of ProjectSettingsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectSettingsDtoCopyWith<_ProjectSettingsDto> get copyWith => __$ProjectSettingsDtoCopyWithImpl<_ProjectSettingsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectSettingsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectSettingsDto&&const DeepCollectionEquality().equals(other._setup, _setup)&&const DeepCollectionEquality().equals(other._teardown, _teardown)&&(identical(other.shell, shell) || other.shell == shell));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_setup),const DeepCollectionEquality().hash(_teardown),shell);

@override
String toString() {
  return 'ProjectSettingsDto(setup: $setup, teardown: $teardown, shell: $shell)';
}


}

/// @nodoc
abstract mixin class _$ProjectSettingsDtoCopyWith<$Res> implements $ProjectSettingsDtoCopyWith<$Res> {
  factory _$ProjectSettingsDtoCopyWith(_ProjectSettingsDto value, $Res Function(_ProjectSettingsDto) _then) = __$ProjectSettingsDtoCopyWithImpl;
@override @useResult
$Res call({
 List<String> setup, List<String> teardown, ShellSpecDto? shell
});


@override $ShellSpecDtoCopyWith<$Res>? get shell;

}
/// @nodoc
class __$ProjectSettingsDtoCopyWithImpl<$Res>
    implements _$ProjectSettingsDtoCopyWith<$Res> {
  __$ProjectSettingsDtoCopyWithImpl(this._self, this._then);

  final _ProjectSettingsDto _self;
  final $Res Function(_ProjectSettingsDto) _then;

/// Create a copy of ProjectSettingsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? setup = null,Object? teardown = null,Object? shell = freezed,}) {
  return _then(_ProjectSettingsDto(
setup: null == setup ? _self._setup : setup // ignore: cast_nullable_to_non_nullable
as List<String>,teardown: null == teardown ? _self._teardown : teardown // ignore: cast_nullable_to_non_nullable
as List<String>,shell: freezed == shell ? _self.shell : shell // ignore: cast_nullable_to_non_nullable
as ShellSpecDto?,
  ));
}

/// Create a copy of ProjectSettingsDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShellSpecDtoCopyWith<$Res>? get shell {
    if (_self.shell == null) {
    return null;
  }

  return $ShellSpecDtoCopyWith<$Res>(_self.shell!, (value) {
    return _then(_self.copyWith(shell: value));
  });
}
}


/// @nodoc
mixin _$WorktreeHookRunDto {

 WorktreeHookPhase get phase; String get command; int get exitCode; String get stdout; String get stderr;
/// Create a copy of WorktreeHookRunDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorktreeHookRunDtoCopyWith<WorktreeHookRunDto> get copyWith => _$WorktreeHookRunDtoCopyWithImpl<WorktreeHookRunDto>(this as WorktreeHookRunDto, _$identity);

  /// Serializes this WorktreeHookRunDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorktreeHookRunDto&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.command, command) || other.command == command)&&(identical(other.exitCode, exitCode) || other.exitCode == exitCode)&&(identical(other.stdout, stdout) || other.stdout == stdout)&&(identical(other.stderr, stderr) || other.stderr == stderr));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phase,command,exitCode,stdout,stderr);

@override
String toString() {
  return 'WorktreeHookRunDto(phase: $phase, command: $command, exitCode: $exitCode, stdout: $stdout, stderr: $stderr)';
}


}

/// @nodoc
abstract mixin class $WorktreeHookRunDtoCopyWith<$Res>  {
  factory $WorktreeHookRunDtoCopyWith(WorktreeHookRunDto value, $Res Function(WorktreeHookRunDto) _then) = _$WorktreeHookRunDtoCopyWithImpl;
@useResult
$Res call({
 WorktreeHookPhase phase, String command, int exitCode, String stdout, String stderr
});




}
/// @nodoc
class _$WorktreeHookRunDtoCopyWithImpl<$Res>
    implements $WorktreeHookRunDtoCopyWith<$Res> {
  _$WorktreeHookRunDtoCopyWithImpl(this._self, this._then);

  final WorktreeHookRunDto _self;
  final $Res Function(WorktreeHookRunDto) _then;

/// Create a copy of WorktreeHookRunDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? command = null,Object? exitCode = null,Object? stdout = null,Object? stderr = null,}) {
  return _then(_self.copyWith(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as WorktreeHookPhase,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,exitCode: null == exitCode ? _self.exitCode : exitCode // ignore: cast_nullable_to_non_nullable
as int,stdout: null == stdout ? _self.stdout : stdout // ignore: cast_nullable_to_non_nullable
as String,stderr: null == stderr ? _self.stderr : stderr // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WorktreeHookRunDto].
extension WorktreeHookRunDtoPatterns on WorktreeHookRunDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorktreeHookRunDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorktreeHookRunDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorktreeHookRunDto value)  $default,){
final _that = this;
switch (_that) {
case _WorktreeHookRunDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorktreeHookRunDto value)?  $default,){
final _that = this;
switch (_that) {
case _WorktreeHookRunDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorktreeHookPhase phase,  String command,  int exitCode,  String stdout,  String stderr)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorktreeHookRunDto() when $default != null:
return $default(_that.phase,_that.command,_that.exitCode,_that.stdout,_that.stderr);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorktreeHookPhase phase,  String command,  int exitCode,  String stdout,  String stderr)  $default,) {final _that = this;
switch (_that) {
case _WorktreeHookRunDto():
return $default(_that.phase,_that.command,_that.exitCode,_that.stdout,_that.stderr);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorktreeHookPhase phase,  String command,  int exitCode,  String stdout,  String stderr)?  $default,) {final _that = this;
switch (_that) {
case _WorktreeHookRunDto() when $default != null:
return $default(_that.phase,_that.command,_that.exitCode,_that.stdout,_that.stderr);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorktreeHookRunDto implements WorktreeHookRunDto {
  const _WorktreeHookRunDto({required this.phase, required this.command, required this.exitCode, required this.stdout, required this.stderr});
  factory _WorktreeHookRunDto.fromJson(Map<String, dynamic> json) => _$WorktreeHookRunDtoFromJson(json);

@override final  WorktreeHookPhase phase;
@override final  String command;
@override final  int exitCode;
@override final  String stdout;
@override final  String stderr;

/// Create a copy of WorktreeHookRunDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorktreeHookRunDtoCopyWith<_WorktreeHookRunDto> get copyWith => __$WorktreeHookRunDtoCopyWithImpl<_WorktreeHookRunDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorktreeHookRunDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorktreeHookRunDto&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.command, command) || other.command == command)&&(identical(other.exitCode, exitCode) || other.exitCode == exitCode)&&(identical(other.stdout, stdout) || other.stdout == stdout)&&(identical(other.stderr, stderr) || other.stderr == stderr));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phase,command,exitCode,stdout,stderr);

@override
String toString() {
  return 'WorktreeHookRunDto(phase: $phase, command: $command, exitCode: $exitCode, stdout: $stdout, stderr: $stderr)';
}


}

/// @nodoc
abstract mixin class _$WorktreeHookRunDtoCopyWith<$Res> implements $WorktreeHookRunDtoCopyWith<$Res> {
  factory _$WorktreeHookRunDtoCopyWith(_WorktreeHookRunDto value, $Res Function(_WorktreeHookRunDto) _then) = __$WorktreeHookRunDtoCopyWithImpl;
@override @useResult
$Res call({
 WorktreeHookPhase phase, String command, int exitCode, String stdout, String stderr
});




}
/// @nodoc
class __$WorktreeHookRunDtoCopyWithImpl<$Res>
    implements _$WorktreeHookRunDtoCopyWith<$Res> {
  __$WorktreeHookRunDtoCopyWithImpl(this._self, this._then);

  final _WorktreeHookRunDto _self;
  final $Res Function(_WorktreeHookRunDto) _then;

/// Create a copy of WorktreeHookRunDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? command = null,Object? exitCode = null,Object? stdout = null,Object? stderr = null,}) {
  return _then(_WorktreeHookRunDto(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as WorktreeHookPhase,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,exitCode: null == exitCode ? _self.exitCode : exitCode // ignore: cast_nullable_to_non_nullable
as int,stdout: null == stdout ? _self.stdout : stdout // ignore: cast_nullable_to_non_nullable
as String,stderr: null == stderr ? _self.stderr : stderr // ignore: cast_nullable_to_non_nullable
as String,
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
mixin _$FileMatchDto {

 String get relativePath; String get absolutePath; String get name; bool get isDirectory; int get score;
/// Create a copy of FileMatchDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileMatchDtoCopyWith<FileMatchDto> get copyWith => _$FileMatchDtoCopyWithImpl<FileMatchDto>(this as FileMatchDto, _$identity);

  /// Serializes this FileMatchDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileMatchDto&&(identical(other.relativePath, relativePath) || other.relativePath == relativePath)&&(identical(other.absolutePath, absolutePath) || other.absolutePath == absolutePath)&&(identical(other.name, name) || other.name == name)&&(identical(other.isDirectory, isDirectory) || other.isDirectory == isDirectory)&&(identical(other.score, score) || other.score == score));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,relativePath,absolutePath,name,isDirectory,score);

@override
String toString() {
  return 'FileMatchDto(relativePath: $relativePath, absolutePath: $absolutePath, name: $name, isDirectory: $isDirectory, score: $score)';
}


}

/// @nodoc
abstract mixin class $FileMatchDtoCopyWith<$Res>  {
  factory $FileMatchDtoCopyWith(FileMatchDto value, $Res Function(FileMatchDto) _then) = _$FileMatchDtoCopyWithImpl;
@useResult
$Res call({
 String relativePath, String absolutePath, String name, bool isDirectory, int score
});




}
/// @nodoc
class _$FileMatchDtoCopyWithImpl<$Res>
    implements $FileMatchDtoCopyWith<$Res> {
  _$FileMatchDtoCopyWithImpl(this._self, this._then);

  final FileMatchDto _self;
  final $Res Function(FileMatchDto) _then;

/// Create a copy of FileMatchDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? relativePath = null,Object? absolutePath = null,Object? name = null,Object? isDirectory = null,Object? score = null,}) {
  return _then(_self.copyWith(
relativePath: null == relativePath ? _self.relativePath : relativePath // ignore: cast_nullable_to_non_nullable
as String,absolutePath: null == absolutePath ? _self.absolutePath : absolutePath // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isDirectory: null == isDirectory ? _self.isDirectory : isDirectory // ignore: cast_nullable_to_non_nullable
as bool,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FileMatchDto].
extension FileMatchDtoPatterns on FileMatchDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileMatchDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileMatchDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileMatchDto value)  $default,){
final _that = this;
switch (_that) {
case _FileMatchDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileMatchDto value)?  $default,){
final _that = this;
switch (_that) {
case _FileMatchDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String relativePath,  String absolutePath,  String name,  bool isDirectory,  int score)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileMatchDto() when $default != null:
return $default(_that.relativePath,_that.absolutePath,_that.name,_that.isDirectory,_that.score);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String relativePath,  String absolutePath,  String name,  bool isDirectory,  int score)  $default,) {final _that = this;
switch (_that) {
case _FileMatchDto():
return $default(_that.relativePath,_that.absolutePath,_that.name,_that.isDirectory,_that.score);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String relativePath,  String absolutePath,  String name,  bool isDirectory,  int score)?  $default,) {final _that = this;
switch (_that) {
case _FileMatchDto() when $default != null:
return $default(_that.relativePath,_that.absolutePath,_that.name,_that.isDirectory,_that.score);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FileMatchDto implements FileMatchDto {
  const _FileMatchDto({required this.relativePath, required this.absolutePath, required this.name, required this.isDirectory, this.score = 0});
  factory _FileMatchDto.fromJson(Map<String, dynamic> json) => _$FileMatchDtoFromJson(json);

@override final  String relativePath;
@override final  String absolutePath;
@override final  String name;
@override final  bool isDirectory;
@override@JsonKey() final  int score;

/// Create a copy of FileMatchDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileMatchDtoCopyWith<_FileMatchDto> get copyWith => __$FileMatchDtoCopyWithImpl<_FileMatchDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FileMatchDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileMatchDto&&(identical(other.relativePath, relativePath) || other.relativePath == relativePath)&&(identical(other.absolutePath, absolutePath) || other.absolutePath == absolutePath)&&(identical(other.name, name) || other.name == name)&&(identical(other.isDirectory, isDirectory) || other.isDirectory == isDirectory)&&(identical(other.score, score) || other.score == score));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,relativePath,absolutePath,name,isDirectory,score);

@override
String toString() {
  return 'FileMatchDto(relativePath: $relativePath, absolutePath: $absolutePath, name: $name, isDirectory: $isDirectory, score: $score)';
}


}

/// @nodoc
abstract mixin class _$FileMatchDtoCopyWith<$Res> implements $FileMatchDtoCopyWith<$Res> {
  factory _$FileMatchDtoCopyWith(_FileMatchDto value, $Res Function(_FileMatchDto) _then) = __$FileMatchDtoCopyWithImpl;
@override @useResult
$Res call({
 String relativePath, String absolutePath, String name, bool isDirectory, int score
});




}
/// @nodoc
class __$FileMatchDtoCopyWithImpl<$Res>
    implements _$FileMatchDtoCopyWith<$Res> {
  __$FileMatchDtoCopyWithImpl(this._self, this._then);

  final _FileMatchDto _self;
  final $Res Function(_FileMatchDto) _then;

/// Create a copy of FileMatchDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? relativePath = null,Object? absolutePath = null,Object? name = null,Object? isDirectory = null,Object? score = null,}) {
  return _then(_FileMatchDto(
relativePath: null == relativePath ? _self.relativePath : relativePath // ignore: cast_nullable_to_non_nullable
as String,absolutePath: null == absolutePath ? _self.absolutePath : absolutePath // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isDirectory: null == isDirectory ? _self.isDirectory : isDirectory // ignore: cast_nullable_to_non_nullable
as bool,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$GitBranchDto {

 String get name; bool get current; bool get checkedOut; bool get isRemote; bool get isDefault;
/// Create a copy of GitBranchDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitBranchDtoCopyWith<GitBranchDto> get copyWith => _$GitBranchDtoCopyWithImpl<GitBranchDto>(this as GitBranchDto, _$identity);

  /// Serializes this GitBranchDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitBranchDto&&(identical(other.name, name) || other.name == name)&&(identical(other.current, current) || other.current == current)&&(identical(other.checkedOut, checkedOut) || other.checkedOut == checkedOut)&&(identical(other.isRemote, isRemote) || other.isRemote == isRemote)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,current,checkedOut,isRemote,isDefault);

@override
String toString() {
  return 'GitBranchDto(name: $name, current: $current, checkedOut: $checkedOut, isRemote: $isRemote, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class $GitBranchDtoCopyWith<$Res>  {
  factory $GitBranchDtoCopyWith(GitBranchDto value, $Res Function(GitBranchDto) _then) = _$GitBranchDtoCopyWithImpl;
@useResult
$Res call({
 String name, bool current, bool checkedOut, bool isRemote, bool isDefault
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
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? current = null,Object? checkedOut = null,Object? isRemote = null,Object? isDefault = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as bool,checkedOut: null == checkedOut ? _self.checkedOut : checkedOut // ignore: cast_nullable_to_non_nullable
as bool,isRemote: null == isRemote ? _self.isRemote : isRemote // ignore: cast_nullable_to_non_nullable
as bool,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  bool current,  bool checkedOut,  bool isRemote,  bool isDefault)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitBranchDto() when $default != null:
return $default(_that.name,_that.current,_that.checkedOut,_that.isRemote,_that.isDefault);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  bool current,  bool checkedOut,  bool isRemote,  bool isDefault)  $default,) {final _that = this;
switch (_that) {
case _GitBranchDto():
return $default(_that.name,_that.current,_that.checkedOut,_that.isRemote,_that.isDefault);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  bool current,  bool checkedOut,  bool isRemote,  bool isDefault)?  $default,) {final _that = this;
switch (_that) {
case _GitBranchDto() when $default != null:
return $default(_that.name,_that.current,_that.checkedOut,_that.isRemote,_that.isDefault);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GitBranchDto implements GitBranchDto {
  const _GitBranchDto({required this.name, required this.current, required this.checkedOut, this.isRemote = false, this.isDefault = false});
  factory _GitBranchDto.fromJson(Map<String, dynamic> json) => _$GitBranchDtoFromJson(json);

@override final  String name;
@override final  bool current;
@override final  bool checkedOut;
@override@JsonKey() final  bool isRemote;
@override@JsonKey() final  bool isDefault;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitBranchDto&&(identical(other.name, name) || other.name == name)&&(identical(other.current, current) || other.current == current)&&(identical(other.checkedOut, checkedOut) || other.checkedOut == checkedOut)&&(identical(other.isRemote, isRemote) || other.isRemote == isRemote)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,current,checkedOut,isRemote,isDefault);

@override
String toString() {
  return 'GitBranchDto(name: $name, current: $current, checkedOut: $checkedOut, isRemote: $isRemote, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class _$GitBranchDtoCopyWith<$Res> implements $GitBranchDtoCopyWith<$Res> {
  factory _$GitBranchDtoCopyWith(_GitBranchDto value, $Res Function(_GitBranchDto) _then) = __$GitBranchDtoCopyWithImpl;
@override @useResult
$Res call({
 String name, bool current, bool checkedOut, bool isRemote, bool isDefault
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
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? current = null,Object? checkedOut = null,Object? isRemote = null,Object? isDefault = null,}) {
  return _then(_GitBranchDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as bool,checkedOut: null == checkedOut ? _self.checkedOut : checkedOut // ignore: cast_nullable_to_non_nullable
as bool,isRemote: null == isRemote ? _self.isRemote : isRemote // ignore: cast_nullable_to_non_nullable
as bool,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$AgentModelSelectionDto {

 AgentModelSource get source; String? get providerConnectionId; String? get modelId;
/// Create a copy of AgentModelSelectionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentModelSelectionDtoCopyWith<AgentModelSelectionDto> get copyWith => _$AgentModelSelectionDtoCopyWithImpl<AgentModelSelectionDto>(this as AgentModelSelectionDto, _$identity);

  /// Serializes this AgentModelSelectionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentModelSelectionDto&&(identical(other.source, source) || other.source == source)&&(identical(other.providerConnectionId, providerConnectionId) || other.providerConnectionId == providerConnectionId)&&(identical(other.modelId, modelId) || other.modelId == modelId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,providerConnectionId,modelId);

@override
String toString() {
  return 'AgentModelSelectionDto(source: $source, providerConnectionId: $providerConnectionId, modelId: $modelId)';
}


}

/// @nodoc
abstract mixin class $AgentModelSelectionDtoCopyWith<$Res>  {
  factory $AgentModelSelectionDtoCopyWith(AgentModelSelectionDto value, $Res Function(AgentModelSelectionDto) _then) = _$AgentModelSelectionDtoCopyWithImpl;
@useResult
$Res call({
 AgentModelSource source, String? providerConnectionId, String? modelId
});




}
/// @nodoc
class _$AgentModelSelectionDtoCopyWithImpl<$Res>
    implements $AgentModelSelectionDtoCopyWith<$Res> {
  _$AgentModelSelectionDtoCopyWithImpl(this._self, this._then);

  final AgentModelSelectionDto _self;
  final $Res Function(AgentModelSelectionDto) _then;

/// Create a copy of AgentModelSelectionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? providerConnectionId = freezed,Object? modelId = freezed,}) {
  return _then(_self.copyWith(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as AgentModelSource,providerConnectionId: freezed == providerConnectionId ? _self.providerConnectionId : providerConnectionId // ignore: cast_nullable_to_non_nullable
as String?,modelId: freezed == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentModelSelectionDto].
extension AgentModelSelectionDtoPatterns on AgentModelSelectionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentModelSelectionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentModelSelectionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentModelSelectionDto value)  $default,){
final _that = this;
switch (_that) {
case _AgentModelSelectionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentModelSelectionDto value)?  $default,){
final _that = this;
switch (_that) {
case _AgentModelSelectionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AgentModelSource source,  String? providerConnectionId,  String? modelId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentModelSelectionDto() when $default != null:
return $default(_that.source,_that.providerConnectionId,_that.modelId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AgentModelSource source,  String? providerConnectionId,  String? modelId)  $default,) {final _that = this;
switch (_that) {
case _AgentModelSelectionDto():
return $default(_that.source,_that.providerConnectionId,_that.modelId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AgentModelSource source,  String? providerConnectionId,  String? modelId)?  $default,) {final _that = this;
switch (_that) {
case _AgentModelSelectionDto() when $default != null:
return $default(_that.source,_that.providerConnectionId,_that.modelId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentModelSelectionDto implements AgentModelSelectionDto {
  const _AgentModelSelectionDto({required this.source, this.providerConnectionId, this.modelId});
  factory _AgentModelSelectionDto.fromJson(Map<String, dynamic> json) => _$AgentModelSelectionDtoFromJson(json);

@override final  AgentModelSource source;
@override final  String? providerConnectionId;
@override final  String? modelId;

/// Create a copy of AgentModelSelectionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentModelSelectionDtoCopyWith<_AgentModelSelectionDto> get copyWith => __$AgentModelSelectionDtoCopyWithImpl<_AgentModelSelectionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentModelSelectionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentModelSelectionDto&&(identical(other.source, source) || other.source == source)&&(identical(other.providerConnectionId, providerConnectionId) || other.providerConnectionId == providerConnectionId)&&(identical(other.modelId, modelId) || other.modelId == modelId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,providerConnectionId,modelId);

@override
String toString() {
  return 'AgentModelSelectionDto(source: $source, providerConnectionId: $providerConnectionId, modelId: $modelId)';
}


}

/// @nodoc
abstract mixin class _$AgentModelSelectionDtoCopyWith<$Res> implements $AgentModelSelectionDtoCopyWith<$Res> {
  factory _$AgentModelSelectionDtoCopyWith(_AgentModelSelectionDto value, $Res Function(_AgentModelSelectionDto) _then) = __$AgentModelSelectionDtoCopyWithImpl;
@override @useResult
$Res call({
 AgentModelSource source, String? providerConnectionId, String? modelId
});




}
/// @nodoc
class __$AgentModelSelectionDtoCopyWithImpl<$Res>
    implements _$AgentModelSelectionDtoCopyWith<$Res> {
  __$AgentModelSelectionDtoCopyWithImpl(this._self, this._then);

  final _AgentModelSelectionDto _self;
  final $Res Function(_AgentModelSelectionDto) _then;

/// Create a copy of AgentModelSelectionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? providerConnectionId = freezed,Object? modelId = freezed,}) {
  return _then(_AgentModelSelectionDto(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as AgentModelSource,providerConnectionId: freezed == providerConnectionId ? _self.providerConnectionId : providerConnectionId // ignore: cast_nullable_to_non_nullable
as String?,modelId: freezed == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AgentDefinitionDiagnosticDto {

 String get code; String get message; int? get line; int? get column;
/// Create a copy of AgentDefinitionDiagnosticDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentDefinitionDiagnosticDtoCopyWith<AgentDefinitionDiagnosticDto> get copyWith => _$AgentDefinitionDiagnosticDtoCopyWithImpl<AgentDefinitionDiagnosticDto>(this as AgentDefinitionDiagnosticDto, _$identity);

  /// Serializes this AgentDefinitionDiagnosticDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentDefinitionDiagnosticDto&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.line, line) || other.line == line)&&(identical(other.column, column) || other.column == column));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,line,column);

@override
String toString() {
  return 'AgentDefinitionDiagnosticDto(code: $code, message: $message, line: $line, column: $column)';
}


}

/// @nodoc
abstract mixin class $AgentDefinitionDiagnosticDtoCopyWith<$Res>  {
  factory $AgentDefinitionDiagnosticDtoCopyWith(AgentDefinitionDiagnosticDto value, $Res Function(AgentDefinitionDiagnosticDto) _then) = _$AgentDefinitionDiagnosticDtoCopyWithImpl;
@useResult
$Res call({
 String code, String message, int? line, int? column
});




}
/// @nodoc
class _$AgentDefinitionDiagnosticDtoCopyWithImpl<$Res>
    implements $AgentDefinitionDiagnosticDtoCopyWith<$Res> {
  _$AgentDefinitionDiagnosticDtoCopyWithImpl(this._self, this._then);

  final AgentDefinitionDiagnosticDto _self;
  final $Res Function(AgentDefinitionDiagnosticDto) _then;

/// Create a copy of AgentDefinitionDiagnosticDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? line = freezed,Object? column = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,line: freezed == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as int?,column: freezed == column ? _self.column : column // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentDefinitionDiagnosticDto].
extension AgentDefinitionDiagnosticDtoPatterns on AgentDefinitionDiagnosticDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentDefinitionDiagnosticDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentDefinitionDiagnosticDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentDefinitionDiagnosticDto value)  $default,){
final _that = this;
switch (_that) {
case _AgentDefinitionDiagnosticDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentDefinitionDiagnosticDto value)?  $default,){
final _that = this;
switch (_that) {
case _AgentDefinitionDiagnosticDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String message,  int? line,  int? column)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentDefinitionDiagnosticDto() when $default != null:
return $default(_that.code,_that.message,_that.line,_that.column);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String message,  int? line,  int? column)  $default,) {final _that = this;
switch (_that) {
case _AgentDefinitionDiagnosticDto():
return $default(_that.code,_that.message,_that.line,_that.column);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String message,  int? line,  int? column)?  $default,) {final _that = this;
switch (_that) {
case _AgentDefinitionDiagnosticDto() when $default != null:
return $default(_that.code,_that.message,_that.line,_that.column);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentDefinitionDiagnosticDto implements AgentDefinitionDiagnosticDto {
  const _AgentDefinitionDiagnosticDto({required this.code, required this.message, this.line, this.column});
  factory _AgentDefinitionDiagnosticDto.fromJson(Map<String, dynamic> json) => _$AgentDefinitionDiagnosticDtoFromJson(json);

@override final  String code;
@override final  String message;
@override final  int? line;
@override final  int? column;

/// Create a copy of AgentDefinitionDiagnosticDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentDefinitionDiagnosticDtoCopyWith<_AgentDefinitionDiagnosticDto> get copyWith => __$AgentDefinitionDiagnosticDtoCopyWithImpl<_AgentDefinitionDiagnosticDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentDefinitionDiagnosticDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentDefinitionDiagnosticDto&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.line, line) || other.line == line)&&(identical(other.column, column) || other.column == column));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,line,column);

@override
String toString() {
  return 'AgentDefinitionDiagnosticDto(code: $code, message: $message, line: $line, column: $column)';
}


}

/// @nodoc
abstract mixin class _$AgentDefinitionDiagnosticDtoCopyWith<$Res> implements $AgentDefinitionDiagnosticDtoCopyWith<$Res> {
  factory _$AgentDefinitionDiagnosticDtoCopyWith(_AgentDefinitionDiagnosticDto value, $Res Function(_AgentDefinitionDiagnosticDto) _then) = __$AgentDefinitionDiagnosticDtoCopyWithImpl;
@override @useResult
$Res call({
 String code, String message, int? line, int? column
});




}
/// @nodoc
class __$AgentDefinitionDiagnosticDtoCopyWithImpl<$Res>
    implements _$AgentDefinitionDiagnosticDtoCopyWith<$Res> {
  __$AgentDefinitionDiagnosticDtoCopyWithImpl(this._self, this._then);

  final _AgentDefinitionDiagnosticDto _self;
  final $Res Function(_AgentDefinitionDiagnosticDto) _then;

/// Create a copy of AgentDefinitionDiagnosticDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? line = freezed,Object? column = freezed,}) {
  return _then(_AgentDefinitionDiagnosticDto(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,line: freezed == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as int?,column: freezed == column ? _self.column : column // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$AgentDefinitionDto {

 String get id; String get name; String get description; AgentMode get mode; bool get promptEnabled; String get systemPrompt; AgentModelSelectionDto get model; String get reasoningEffort; List<String> get toolIds; List<String> get callableAgentIds; String get contentHash; String get sourcePath; PermissionMode? get permissionMode; bool get isBuiltIn; bool get isArchived; bool get isStale; List<AgentDefinitionDiagnosticDto> get diagnostics;
/// Create a copy of AgentDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentDefinitionDtoCopyWith<AgentDefinitionDto> get copyWith => _$AgentDefinitionDtoCopyWithImpl<AgentDefinitionDto>(this as AgentDefinitionDto, _$identity);

  /// Serializes this AgentDefinitionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentDefinitionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.promptEnabled, promptEnabled) || other.promptEnabled == promptEnabled)&&(identical(other.systemPrompt, systemPrompt) || other.systemPrompt == systemPrompt)&&(identical(other.model, model) || other.model == model)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort)&&const DeepCollectionEquality().equals(other.toolIds, toolIds)&&const DeepCollectionEquality().equals(other.callableAgentIds, callableAgentIds)&&(identical(other.contentHash, contentHash) || other.contentHash == contentHash)&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath)&&(identical(other.permissionMode, permissionMode) || other.permissionMode == permissionMode)&&(identical(other.isBuiltIn, isBuiltIn) || other.isBuiltIn == isBuiltIn)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.isStale, isStale) || other.isStale == isStale)&&const DeepCollectionEquality().equals(other.diagnostics, diagnostics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,mode,promptEnabled,systemPrompt,model,reasoningEffort,const DeepCollectionEquality().hash(toolIds),const DeepCollectionEquality().hash(callableAgentIds),contentHash,sourcePath,permissionMode,isBuiltIn,isArchived,isStale,const DeepCollectionEquality().hash(diagnostics));

@override
String toString() {
  return 'AgentDefinitionDto(id: $id, name: $name, description: $description, mode: $mode, promptEnabled: $promptEnabled, systemPrompt: $systemPrompt, model: $model, reasoningEffort: $reasoningEffort, toolIds: $toolIds, callableAgentIds: $callableAgentIds, contentHash: $contentHash, sourcePath: $sourcePath, permissionMode: $permissionMode, isBuiltIn: $isBuiltIn, isArchived: $isArchived, isStale: $isStale, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $AgentDefinitionDtoCopyWith<$Res>  {
  factory $AgentDefinitionDtoCopyWith(AgentDefinitionDto value, $Res Function(AgentDefinitionDto) _then) = _$AgentDefinitionDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, AgentMode mode, bool promptEnabled, String systemPrompt, AgentModelSelectionDto model, String reasoningEffort, List<String> toolIds, List<String> callableAgentIds, String contentHash, String sourcePath, PermissionMode? permissionMode, bool isBuiltIn, bool isArchived, bool isStale, List<AgentDefinitionDiagnosticDto> diagnostics
});


$AgentModelSelectionDtoCopyWith<$Res> get model;

}
/// @nodoc
class _$AgentDefinitionDtoCopyWithImpl<$Res>
    implements $AgentDefinitionDtoCopyWith<$Res> {
  _$AgentDefinitionDtoCopyWithImpl(this._self, this._then);

  final AgentDefinitionDto _self;
  final $Res Function(AgentDefinitionDto) _then;

/// Create a copy of AgentDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? mode = null,Object? promptEnabled = null,Object? systemPrompt = null,Object? model = null,Object? reasoningEffort = null,Object? toolIds = null,Object? callableAgentIds = null,Object? contentHash = null,Object? sourcePath = null,Object? permissionMode = freezed,Object? isBuiltIn = null,Object? isArchived = null,Object? isStale = null,Object? diagnostics = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as AgentMode,promptEnabled: null == promptEnabled ? _self.promptEnabled : promptEnabled // ignore: cast_nullable_to_non_nullable
as bool,systemPrompt: null == systemPrompt ? _self.systemPrompt : systemPrompt // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as AgentModelSelectionDto,reasoningEffort: null == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as String,toolIds: null == toolIds ? _self.toolIds : toolIds // ignore: cast_nullable_to_non_nullable
as List<String>,callableAgentIds: null == callableAgentIds ? _self.callableAgentIds : callableAgentIds // ignore: cast_nullable_to_non_nullable
as List<String>,contentHash: null == contentHash ? _self.contentHash : contentHash // ignore: cast_nullable_to_non_nullable
as String,sourcePath: null == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String,permissionMode: freezed == permissionMode ? _self.permissionMode : permissionMode // ignore: cast_nullable_to_non_nullable
as PermissionMode?,isBuiltIn: null == isBuiltIn ? _self.isBuiltIn : isBuiltIn // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<AgentDefinitionDiagnosticDto>,
  ));
}
/// Create a copy of AgentDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AgentModelSelectionDtoCopyWith<$Res> get model {
  
  return $AgentModelSelectionDtoCopyWith<$Res>(_self.model, (value) {
    return _then(_self.copyWith(model: value));
  });
}
}


/// Adds pattern-matching-related methods to [AgentDefinitionDto].
extension AgentDefinitionDtoPatterns on AgentDefinitionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentDefinitionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentDefinitionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentDefinitionDto value)  $default,){
final _that = this;
switch (_that) {
case _AgentDefinitionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentDefinitionDto value)?  $default,){
final _that = this;
switch (_that) {
case _AgentDefinitionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  AgentMode mode,  bool promptEnabled,  String systemPrompt,  AgentModelSelectionDto model,  String reasoningEffort,  List<String> toolIds,  List<String> callableAgentIds,  String contentHash,  String sourcePath,  PermissionMode? permissionMode,  bool isBuiltIn,  bool isArchived,  bool isStale,  List<AgentDefinitionDiagnosticDto> diagnostics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentDefinitionDto() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.mode,_that.promptEnabled,_that.systemPrompt,_that.model,_that.reasoningEffort,_that.toolIds,_that.callableAgentIds,_that.contentHash,_that.sourcePath,_that.permissionMode,_that.isBuiltIn,_that.isArchived,_that.isStale,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  AgentMode mode,  bool promptEnabled,  String systemPrompt,  AgentModelSelectionDto model,  String reasoningEffort,  List<String> toolIds,  List<String> callableAgentIds,  String contentHash,  String sourcePath,  PermissionMode? permissionMode,  bool isBuiltIn,  bool isArchived,  bool isStale,  List<AgentDefinitionDiagnosticDto> diagnostics)  $default,) {final _that = this;
switch (_that) {
case _AgentDefinitionDto():
return $default(_that.id,_that.name,_that.description,_that.mode,_that.promptEnabled,_that.systemPrompt,_that.model,_that.reasoningEffort,_that.toolIds,_that.callableAgentIds,_that.contentHash,_that.sourcePath,_that.permissionMode,_that.isBuiltIn,_that.isArchived,_that.isStale,_that.diagnostics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  AgentMode mode,  bool promptEnabled,  String systemPrompt,  AgentModelSelectionDto model,  String reasoningEffort,  List<String> toolIds,  List<String> callableAgentIds,  String contentHash,  String sourcePath,  PermissionMode? permissionMode,  bool isBuiltIn,  bool isArchived,  bool isStale,  List<AgentDefinitionDiagnosticDto> diagnostics)?  $default,) {final _that = this;
switch (_that) {
case _AgentDefinitionDto() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.mode,_that.promptEnabled,_that.systemPrompt,_that.model,_that.reasoningEffort,_that.toolIds,_that.callableAgentIds,_that.contentHash,_that.sourcePath,_that.permissionMode,_that.isBuiltIn,_that.isArchived,_that.isStale,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentDefinitionDto implements AgentDefinitionDto {
  const _AgentDefinitionDto({required this.id, required this.name, required this.description, required this.mode, required this.promptEnabled, required this.systemPrompt, required this.model, required this.reasoningEffort, required final  List<String> toolIds, required final  List<String> callableAgentIds, required this.contentHash, required this.sourcePath, this.permissionMode, this.isBuiltIn = false, this.isArchived = false, this.isStale = false, final  List<AgentDefinitionDiagnosticDto> diagnostics = const <AgentDefinitionDiagnosticDto>[]}): _toolIds = toolIds,_callableAgentIds = callableAgentIds,_diagnostics = diagnostics;
  factory _AgentDefinitionDto.fromJson(Map<String, dynamic> json) => _$AgentDefinitionDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String description;
@override final  AgentMode mode;
@override final  bool promptEnabled;
@override final  String systemPrompt;
@override final  AgentModelSelectionDto model;
@override final  String reasoningEffort;
 final  List<String> _toolIds;
@override List<String> get toolIds {
  if (_toolIds is EqualUnmodifiableListView) return _toolIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_toolIds);
}

 final  List<String> _callableAgentIds;
@override List<String> get callableAgentIds {
  if (_callableAgentIds is EqualUnmodifiableListView) return _callableAgentIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_callableAgentIds);
}

@override final  String contentHash;
@override final  String sourcePath;
@override final  PermissionMode? permissionMode;
@override@JsonKey() final  bool isBuiltIn;
@override@JsonKey() final  bool isArchived;
@override@JsonKey() final  bool isStale;
 final  List<AgentDefinitionDiagnosticDto> _diagnostics;
@override@JsonKey() List<AgentDefinitionDiagnosticDto> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of AgentDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentDefinitionDtoCopyWith<_AgentDefinitionDto> get copyWith => __$AgentDefinitionDtoCopyWithImpl<_AgentDefinitionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentDefinitionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentDefinitionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.promptEnabled, promptEnabled) || other.promptEnabled == promptEnabled)&&(identical(other.systemPrompt, systemPrompt) || other.systemPrompt == systemPrompt)&&(identical(other.model, model) || other.model == model)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort)&&const DeepCollectionEquality().equals(other._toolIds, _toolIds)&&const DeepCollectionEquality().equals(other._callableAgentIds, _callableAgentIds)&&(identical(other.contentHash, contentHash) || other.contentHash == contentHash)&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath)&&(identical(other.permissionMode, permissionMode) || other.permissionMode == permissionMode)&&(identical(other.isBuiltIn, isBuiltIn) || other.isBuiltIn == isBuiltIn)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.isStale, isStale) || other.isStale == isStale)&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,mode,promptEnabled,systemPrompt,model,reasoningEffort,const DeepCollectionEquality().hash(_toolIds),const DeepCollectionEquality().hash(_callableAgentIds),contentHash,sourcePath,permissionMode,isBuiltIn,isArchived,isStale,const DeepCollectionEquality().hash(_diagnostics));

@override
String toString() {
  return 'AgentDefinitionDto(id: $id, name: $name, description: $description, mode: $mode, promptEnabled: $promptEnabled, systemPrompt: $systemPrompt, model: $model, reasoningEffort: $reasoningEffort, toolIds: $toolIds, callableAgentIds: $callableAgentIds, contentHash: $contentHash, sourcePath: $sourcePath, permissionMode: $permissionMode, isBuiltIn: $isBuiltIn, isArchived: $isArchived, isStale: $isStale, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$AgentDefinitionDtoCopyWith<$Res> implements $AgentDefinitionDtoCopyWith<$Res> {
  factory _$AgentDefinitionDtoCopyWith(_AgentDefinitionDto value, $Res Function(_AgentDefinitionDto) _then) = __$AgentDefinitionDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, AgentMode mode, bool promptEnabled, String systemPrompt, AgentModelSelectionDto model, String reasoningEffort, List<String> toolIds, List<String> callableAgentIds, String contentHash, String sourcePath, PermissionMode? permissionMode, bool isBuiltIn, bool isArchived, bool isStale, List<AgentDefinitionDiagnosticDto> diagnostics
});


@override $AgentModelSelectionDtoCopyWith<$Res> get model;

}
/// @nodoc
class __$AgentDefinitionDtoCopyWithImpl<$Res>
    implements _$AgentDefinitionDtoCopyWith<$Res> {
  __$AgentDefinitionDtoCopyWithImpl(this._self, this._then);

  final _AgentDefinitionDto _self;
  final $Res Function(_AgentDefinitionDto) _then;

/// Create a copy of AgentDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? mode = null,Object? promptEnabled = null,Object? systemPrompt = null,Object? model = null,Object? reasoningEffort = null,Object? toolIds = null,Object? callableAgentIds = null,Object? contentHash = null,Object? sourcePath = null,Object? permissionMode = freezed,Object? isBuiltIn = null,Object? isArchived = null,Object? isStale = null,Object? diagnostics = null,}) {
  return _then(_AgentDefinitionDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as AgentMode,promptEnabled: null == promptEnabled ? _self.promptEnabled : promptEnabled // ignore: cast_nullable_to_non_nullable
as bool,systemPrompt: null == systemPrompt ? _self.systemPrompt : systemPrompt // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as AgentModelSelectionDto,reasoningEffort: null == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as String,toolIds: null == toolIds ? _self._toolIds : toolIds // ignore: cast_nullable_to_non_nullable
as List<String>,callableAgentIds: null == callableAgentIds ? _self._callableAgentIds : callableAgentIds // ignore: cast_nullable_to_non_nullable
as List<String>,contentHash: null == contentHash ? _self.contentHash : contentHash // ignore: cast_nullable_to_non_nullable
as String,sourcePath: null == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String,permissionMode: freezed == permissionMode ? _self.permissionMode : permissionMode // ignore: cast_nullable_to_non_nullable
as PermissionMode?,isBuiltIn: null == isBuiltIn ? _self.isBuiltIn : isBuiltIn // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<AgentDefinitionDiagnosticDto>,
  ));
}

/// Create a copy of AgentDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AgentModelSelectionDtoCopyWith<$Res> get model {
  
  return $AgentModelSelectionDtoCopyWith<$Res>(_self.model, (value) {
    return _then(_self.copyWith(model: value));
  });
}
}


/// @nodoc
mixin _$AgentToolDefinitionDto {

 String get id; String get name; String get description; ToolRisk get risk; bool get available; bool get alwaysOn;
/// Create a copy of AgentToolDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentToolDefinitionDtoCopyWith<AgentToolDefinitionDto> get copyWith => _$AgentToolDefinitionDtoCopyWithImpl<AgentToolDefinitionDto>(this as AgentToolDefinitionDto, _$identity);

  /// Serializes this AgentToolDefinitionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentToolDefinitionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.risk, risk) || other.risk == risk)&&(identical(other.available, available) || other.available == available)&&(identical(other.alwaysOn, alwaysOn) || other.alwaysOn == alwaysOn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,risk,available,alwaysOn);

@override
String toString() {
  return 'AgentToolDefinitionDto(id: $id, name: $name, description: $description, risk: $risk, available: $available, alwaysOn: $alwaysOn)';
}


}

/// @nodoc
abstract mixin class $AgentToolDefinitionDtoCopyWith<$Res>  {
  factory $AgentToolDefinitionDtoCopyWith(AgentToolDefinitionDto value, $Res Function(AgentToolDefinitionDto) _then) = _$AgentToolDefinitionDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, ToolRisk risk, bool available, bool alwaysOn
});




}
/// @nodoc
class _$AgentToolDefinitionDtoCopyWithImpl<$Res>
    implements $AgentToolDefinitionDtoCopyWith<$Res> {
  _$AgentToolDefinitionDtoCopyWithImpl(this._self, this._then);

  final AgentToolDefinitionDto _self;
  final $Res Function(AgentToolDefinitionDto) _then;

/// Create a copy of AgentToolDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? risk = null,Object? available = null,Object? alwaysOn = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,risk: null == risk ? _self.risk : risk // ignore: cast_nullable_to_non_nullable
as ToolRisk,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,alwaysOn: null == alwaysOn ? _self.alwaysOn : alwaysOn // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentToolDefinitionDto].
extension AgentToolDefinitionDtoPatterns on AgentToolDefinitionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentToolDefinitionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentToolDefinitionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentToolDefinitionDto value)  $default,){
final _that = this;
switch (_that) {
case _AgentToolDefinitionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentToolDefinitionDto value)?  $default,){
final _that = this;
switch (_that) {
case _AgentToolDefinitionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  ToolRisk risk,  bool available,  bool alwaysOn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentToolDefinitionDto() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.risk,_that.available,_that.alwaysOn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  ToolRisk risk,  bool available,  bool alwaysOn)  $default,) {final _that = this;
switch (_that) {
case _AgentToolDefinitionDto():
return $default(_that.id,_that.name,_that.description,_that.risk,_that.available,_that.alwaysOn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  ToolRisk risk,  bool available,  bool alwaysOn)?  $default,) {final _that = this;
switch (_that) {
case _AgentToolDefinitionDto() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.risk,_that.available,_that.alwaysOn);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentToolDefinitionDto implements AgentToolDefinitionDto {
  const _AgentToolDefinitionDto({required this.id, required this.name, required this.description, required this.risk, this.available = true, this.alwaysOn = false});
  factory _AgentToolDefinitionDto.fromJson(Map<String, dynamic> json) => _$AgentToolDefinitionDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String description;
@override final  ToolRisk risk;
@override@JsonKey() final  bool available;
@override@JsonKey() final  bool alwaysOn;

/// Create a copy of AgentToolDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentToolDefinitionDtoCopyWith<_AgentToolDefinitionDto> get copyWith => __$AgentToolDefinitionDtoCopyWithImpl<_AgentToolDefinitionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentToolDefinitionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentToolDefinitionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.risk, risk) || other.risk == risk)&&(identical(other.available, available) || other.available == available)&&(identical(other.alwaysOn, alwaysOn) || other.alwaysOn == alwaysOn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,risk,available,alwaysOn);

@override
String toString() {
  return 'AgentToolDefinitionDto(id: $id, name: $name, description: $description, risk: $risk, available: $available, alwaysOn: $alwaysOn)';
}


}

/// @nodoc
abstract mixin class _$AgentToolDefinitionDtoCopyWith<$Res> implements $AgentToolDefinitionDtoCopyWith<$Res> {
  factory _$AgentToolDefinitionDtoCopyWith(_AgentToolDefinitionDto value, $Res Function(_AgentToolDefinitionDto) _then) = __$AgentToolDefinitionDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, ToolRisk risk, bool available, bool alwaysOn
});




}
/// @nodoc
class __$AgentToolDefinitionDtoCopyWithImpl<$Res>
    implements _$AgentToolDefinitionDtoCopyWith<$Res> {
  __$AgentToolDefinitionDtoCopyWithImpl(this._self, this._then);

  final _AgentToolDefinitionDto _self;
  final $Res Function(_AgentToolDefinitionDto) _then;

/// Create a copy of AgentToolDefinitionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? risk = null,Object? available = null,Object? alwaysOn = null,}) {
  return _then(_AgentToolDefinitionDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,risk: null == risk ? _self.risk : risk // ignore: cast_nullable_to_non_nullable
as ToolRisk,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,alwaysOn: null == alwaysOn ? _self.alwaysOn : alwaysOn // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$McpServerConfigDto {

 String get id; McpTransportKind get transport; bool get enabled; String? get command; List<String> get args; Map<String, String> get env; String? get cwd; String? get url; Map<String, String> get headers;
/// Create a copy of McpServerConfigDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpServerConfigDtoCopyWith<McpServerConfigDto> get copyWith => _$McpServerConfigDtoCopyWithImpl<McpServerConfigDto>(this as McpServerConfigDto, _$identity);

  /// Serializes this McpServerConfigDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpServerConfigDto&&(identical(other.id, id) || other.id == id)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.command, command) || other.command == command)&&const DeepCollectionEquality().equals(other.args, args)&&const DeepCollectionEquality().equals(other.env, env)&&(identical(other.cwd, cwd) || other.cwd == cwd)&&(identical(other.url, url) || other.url == url)&&const DeepCollectionEquality().equals(other.headers, headers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,transport,enabled,command,const DeepCollectionEquality().hash(args),const DeepCollectionEquality().hash(env),cwd,url,const DeepCollectionEquality().hash(headers));

@override
String toString() {
  return 'McpServerConfigDto(id: $id, transport: $transport, enabled: $enabled, command: $command, args: $args, env: $env, cwd: $cwd, url: $url, headers: $headers)';
}


}

/// @nodoc
abstract mixin class $McpServerConfigDtoCopyWith<$Res>  {
  factory $McpServerConfigDtoCopyWith(McpServerConfigDto value, $Res Function(McpServerConfigDto) _then) = _$McpServerConfigDtoCopyWithImpl;
@useResult
$Res call({
 String id, McpTransportKind transport, bool enabled, String? command, List<String> args, Map<String, String> env, String? cwd, String? url, Map<String, String> headers
});




}
/// @nodoc
class _$McpServerConfigDtoCopyWithImpl<$Res>
    implements $McpServerConfigDtoCopyWith<$Res> {
  _$McpServerConfigDtoCopyWithImpl(this._self, this._then);

  final McpServerConfigDto _self;
  final $Res Function(McpServerConfigDto) _then;

/// Create a copy of McpServerConfigDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? transport = null,Object? enabled = null,Object? command = freezed,Object? args = null,Object? env = null,Object? cwd = freezed,Object? url = freezed,Object? headers = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as McpTransportKind,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,command: freezed == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String?,args: null == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as List<String>,env: null == env ? _self.env : env // ignore: cast_nullable_to_non_nullable
as Map<String, String>,cwd: freezed == cwd ? _self.cwd : cwd // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,headers: null == headers ? _self.headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [McpServerConfigDto].
extension McpServerConfigDtoPatterns on McpServerConfigDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _McpServerConfigDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _McpServerConfigDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _McpServerConfigDto value)  $default,){
final _that = this;
switch (_that) {
case _McpServerConfigDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _McpServerConfigDto value)?  $default,){
final _that = this;
switch (_that) {
case _McpServerConfigDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  McpTransportKind transport,  bool enabled,  String? command,  List<String> args,  Map<String, String> env,  String? cwd,  String? url,  Map<String, String> headers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _McpServerConfigDto() when $default != null:
return $default(_that.id,_that.transport,_that.enabled,_that.command,_that.args,_that.env,_that.cwd,_that.url,_that.headers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  McpTransportKind transport,  bool enabled,  String? command,  List<String> args,  Map<String, String> env,  String? cwd,  String? url,  Map<String, String> headers)  $default,) {final _that = this;
switch (_that) {
case _McpServerConfigDto():
return $default(_that.id,_that.transport,_that.enabled,_that.command,_that.args,_that.env,_that.cwd,_that.url,_that.headers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  McpTransportKind transport,  bool enabled,  String? command,  List<String> args,  Map<String, String> env,  String? cwd,  String? url,  Map<String, String> headers)?  $default,) {final _that = this;
switch (_that) {
case _McpServerConfigDto() when $default != null:
return $default(_that.id,_that.transport,_that.enabled,_that.command,_that.args,_that.env,_that.cwd,_that.url,_that.headers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _McpServerConfigDto implements McpServerConfigDto {
  const _McpServerConfigDto({required this.id, required this.transport, this.enabled = true, this.command, final  List<String> args = const <String>[], final  Map<String, String> env = const <String, String>{}, this.cwd, this.url, final  Map<String, String> headers = const <String, String>{}}): _args = args,_env = env,_headers = headers;
  factory _McpServerConfigDto.fromJson(Map<String, dynamic> json) => _$McpServerConfigDtoFromJson(json);

@override final  String id;
@override final  McpTransportKind transport;
@override@JsonKey() final  bool enabled;
@override final  String? command;
 final  List<String> _args;
@override@JsonKey() List<String> get args {
  if (_args is EqualUnmodifiableListView) return _args;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_args);
}

 final  Map<String, String> _env;
@override@JsonKey() Map<String, String> get env {
  if (_env is EqualUnmodifiableMapView) return _env;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_env);
}

@override final  String? cwd;
@override final  String? url;
 final  Map<String, String> _headers;
@override@JsonKey() Map<String, String> get headers {
  if (_headers is EqualUnmodifiableMapView) return _headers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_headers);
}


/// Create a copy of McpServerConfigDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$McpServerConfigDtoCopyWith<_McpServerConfigDto> get copyWith => __$McpServerConfigDtoCopyWithImpl<_McpServerConfigDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$McpServerConfigDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _McpServerConfigDto&&(identical(other.id, id) || other.id == id)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.command, command) || other.command == command)&&const DeepCollectionEquality().equals(other._args, _args)&&const DeepCollectionEquality().equals(other._env, _env)&&(identical(other.cwd, cwd) || other.cwd == cwd)&&(identical(other.url, url) || other.url == url)&&const DeepCollectionEquality().equals(other._headers, _headers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,transport,enabled,command,const DeepCollectionEquality().hash(_args),const DeepCollectionEquality().hash(_env),cwd,url,const DeepCollectionEquality().hash(_headers));

@override
String toString() {
  return 'McpServerConfigDto(id: $id, transport: $transport, enabled: $enabled, command: $command, args: $args, env: $env, cwd: $cwd, url: $url, headers: $headers)';
}


}

/// @nodoc
abstract mixin class _$McpServerConfigDtoCopyWith<$Res> implements $McpServerConfigDtoCopyWith<$Res> {
  factory _$McpServerConfigDtoCopyWith(_McpServerConfigDto value, $Res Function(_McpServerConfigDto) _then) = __$McpServerConfigDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, McpTransportKind transport, bool enabled, String? command, List<String> args, Map<String, String> env, String? cwd, String? url, Map<String, String> headers
});




}
/// @nodoc
class __$McpServerConfigDtoCopyWithImpl<$Res>
    implements _$McpServerConfigDtoCopyWith<$Res> {
  __$McpServerConfigDtoCopyWithImpl(this._self, this._then);

  final _McpServerConfigDto _self;
  final $Res Function(_McpServerConfigDto) _then;

/// Create a copy of McpServerConfigDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? transport = null,Object? enabled = null,Object? command = freezed,Object? args = null,Object? env = null,Object? cwd = freezed,Object? url = freezed,Object? headers = null,}) {
  return _then(_McpServerConfigDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as McpTransportKind,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,command: freezed == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String?,args: null == args ? _self._args : args // ignore: cast_nullable_to_non_nullable
as List<String>,env: null == env ? _self._env : env // ignore: cast_nullable_to_non_nullable
as Map<String, String>,cwd: freezed == cwd ? _self.cwd : cwd // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,headers: null == headers ? _self._headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}


/// @nodoc
mixin _$McpToolSummaryDto {

 String get toolId; String get name; String get description; String? get title;
/// Create a copy of McpToolSummaryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpToolSummaryDtoCopyWith<McpToolSummaryDto> get copyWith => _$McpToolSummaryDtoCopyWithImpl<McpToolSummaryDto>(this as McpToolSummaryDto, _$identity);

  /// Serializes this McpToolSummaryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpToolSummaryDto&&(identical(other.toolId, toolId) || other.toolId == toolId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,toolId,name,description,title);

@override
String toString() {
  return 'McpToolSummaryDto(toolId: $toolId, name: $name, description: $description, title: $title)';
}


}

/// @nodoc
abstract mixin class $McpToolSummaryDtoCopyWith<$Res>  {
  factory $McpToolSummaryDtoCopyWith(McpToolSummaryDto value, $Res Function(McpToolSummaryDto) _then) = _$McpToolSummaryDtoCopyWithImpl;
@useResult
$Res call({
 String toolId, String name, String description, String? title
});




}
/// @nodoc
class _$McpToolSummaryDtoCopyWithImpl<$Res>
    implements $McpToolSummaryDtoCopyWith<$Res> {
  _$McpToolSummaryDtoCopyWithImpl(this._self, this._then);

  final McpToolSummaryDto _self;
  final $Res Function(McpToolSummaryDto) _then;

/// Create a copy of McpToolSummaryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? toolId = null,Object? name = null,Object? description = null,Object? title = freezed,}) {
  return _then(_self.copyWith(
toolId: null == toolId ? _self.toolId : toolId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [McpToolSummaryDto].
extension McpToolSummaryDtoPatterns on McpToolSummaryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _McpToolSummaryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _McpToolSummaryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _McpToolSummaryDto value)  $default,){
final _that = this;
switch (_that) {
case _McpToolSummaryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _McpToolSummaryDto value)?  $default,){
final _that = this;
switch (_that) {
case _McpToolSummaryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String toolId,  String name,  String description,  String? title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _McpToolSummaryDto() when $default != null:
return $default(_that.toolId,_that.name,_that.description,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String toolId,  String name,  String description,  String? title)  $default,) {final _that = this;
switch (_that) {
case _McpToolSummaryDto():
return $default(_that.toolId,_that.name,_that.description,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String toolId,  String name,  String description,  String? title)?  $default,) {final _that = this;
switch (_that) {
case _McpToolSummaryDto() when $default != null:
return $default(_that.toolId,_that.name,_that.description,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _McpToolSummaryDto implements McpToolSummaryDto {
  const _McpToolSummaryDto({required this.toolId, required this.name, required this.description, this.title});
  factory _McpToolSummaryDto.fromJson(Map<String, dynamic> json) => _$McpToolSummaryDtoFromJson(json);

@override final  String toolId;
@override final  String name;
@override final  String description;
@override final  String? title;

/// Create a copy of McpToolSummaryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$McpToolSummaryDtoCopyWith<_McpToolSummaryDto> get copyWith => __$McpToolSummaryDtoCopyWithImpl<_McpToolSummaryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$McpToolSummaryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _McpToolSummaryDto&&(identical(other.toolId, toolId) || other.toolId == toolId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,toolId,name,description,title);

@override
String toString() {
  return 'McpToolSummaryDto(toolId: $toolId, name: $name, description: $description, title: $title)';
}


}

/// @nodoc
abstract mixin class _$McpToolSummaryDtoCopyWith<$Res> implements $McpToolSummaryDtoCopyWith<$Res> {
  factory _$McpToolSummaryDtoCopyWith(_McpToolSummaryDto value, $Res Function(_McpToolSummaryDto) _then) = __$McpToolSummaryDtoCopyWithImpl;
@override @useResult
$Res call({
 String toolId, String name, String description, String? title
});




}
/// @nodoc
class __$McpToolSummaryDtoCopyWithImpl<$Res>
    implements _$McpToolSummaryDtoCopyWith<$Res> {
  __$McpToolSummaryDtoCopyWithImpl(this._self, this._then);

  final _McpToolSummaryDto _self;
  final $Res Function(_McpToolSummaryDto) _then;

/// Create a copy of McpToolSummaryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? toolId = null,Object? name = null,Object? description = null,Object? title = freezed,}) {
  return _then(_McpToolSummaryDto(
toolId: null == toolId ? _self.toolId : toolId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$McpResourceSummaryDto {

 String get uri; String? get name; String? get title; String? get description; String? get mimeType; int? get sizeBytes;
/// Create a copy of McpResourceSummaryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpResourceSummaryDtoCopyWith<McpResourceSummaryDto> get copyWith => _$McpResourceSummaryDtoCopyWithImpl<McpResourceSummaryDto>(this as McpResourceSummaryDto, _$identity);

  /// Serializes this McpResourceSummaryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpResourceSummaryDto&&(identical(other.uri, uri) || other.uri == uri)&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uri,name,title,description,mimeType,sizeBytes);

@override
String toString() {
  return 'McpResourceSummaryDto(uri: $uri, name: $name, title: $title, description: $description, mimeType: $mimeType, sizeBytes: $sizeBytes)';
}


}

/// @nodoc
abstract mixin class $McpResourceSummaryDtoCopyWith<$Res>  {
  factory $McpResourceSummaryDtoCopyWith(McpResourceSummaryDto value, $Res Function(McpResourceSummaryDto) _then) = _$McpResourceSummaryDtoCopyWithImpl;
@useResult
$Res call({
 String uri, String? name, String? title, String? description, String? mimeType, int? sizeBytes
});




}
/// @nodoc
class _$McpResourceSummaryDtoCopyWithImpl<$Res>
    implements $McpResourceSummaryDtoCopyWith<$Res> {
  _$McpResourceSummaryDtoCopyWithImpl(this._self, this._then);

  final McpResourceSummaryDto _self;
  final $Res Function(McpResourceSummaryDto) _then;

/// Create a copy of McpResourceSummaryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uri = null,Object? name = freezed,Object? title = freezed,Object? description = freezed,Object? mimeType = freezed,Object? sizeBytes = freezed,}) {
  return _then(_self.copyWith(
uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [McpResourceSummaryDto].
extension McpResourceSummaryDtoPatterns on McpResourceSummaryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _McpResourceSummaryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _McpResourceSummaryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _McpResourceSummaryDto value)  $default,){
final _that = this;
switch (_that) {
case _McpResourceSummaryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _McpResourceSummaryDto value)?  $default,){
final _that = this;
switch (_that) {
case _McpResourceSummaryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uri,  String? name,  String? title,  String? description,  String? mimeType,  int? sizeBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _McpResourceSummaryDto() when $default != null:
return $default(_that.uri,_that.name,_that.title,_that.description,_that.mimeType,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uri,  String? name,  String? title,  String? description,  String? mimeType,  int? sizeBytes)  $default,) {final _that = this;
switch (_that) {
case _McpResourceSummaryDto():
return $default(_that.uri,_that.name,_that.title,_that.description,_that.mimeType,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uri,  String? name,  String? title,  String? description,  String? mimeType,  int? sizeBytes)?  $default,) {final _that = this;
switch (_that) {
case _McpResourceSummaryDto() when $default != null:
return $default(_that.uri,_that.name,_that.title,_that.description,_that.mimeType,_that.sizeBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _McpResourceSummaryDto implements McpResourceSummaryDto {
  const _McpResourceSummaryDto({required this.uri, this.name, this.title, this.description, this.mimeType, this.sizeBytes});
  factory _McpResourceSummaryDto.fromJson(Map<String, dynamic> json) => _$McpResourceSummaryDtoFromJson(json);

@override final  String uri;
@override final  String? name;
@override final  String? title;
@override final  String? description;
@override final  String? mimeType;
@override final  int? sizeBytes;

/// Create a copy of McpResourceSummaryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$McpResourceSummaryDtoCopyWith<_McpResourceSummaryDto> get copyWith => __$McpResourceSummaryDtoCopyWithImpl<_McpResourceSummaryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$McpResourceSummaryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _McpResourceSummaryDto&&(identical(other.uri, uri) || other.uri == uri)&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uri,name,title,description,mimeType,sizeBytes);

@override
String toString() {
  return 'McpResourceSummaryDto(uri: $uri, name: $name, title: $title, description: $description, mimeType: $mimeType, sizeBytes: $sizeBytes)';
}


}

/// @nodoc
abstract mixin class _$McpResourceSummaryDtoCopyWith<$Res> implements $McpResourceSummaryDtoCopyWith<$Res> {
  factory _$McpResourceSummaryDtoCopyWith(_McpResourceSummaryDto value, $Res Function(_McpResourceSummaryDto) _then) = __$McpResourceSummaryDtoCopyWithImpl;
@override @useResult
$Res call({
 String uri, String? name, String? title, String? description, String? mimeType, int? sizeBytes
});




}
/// @nodoc
class __$McpResourceSummaryDtoCopyWithImpl<$Res>
    implements _$McpResourceSummaryDtoCopyWith<$Res> {
  __$McpResourceSummaryDtoCopyWithImpl(this._self, this._then);

  final _McpResourceSummaryDto _self;
  final $Res Function(_McpResourceSummaryDto) _then;

/// Create a copy of McpResourceSummaryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uri = null,Object? name = freezed,Object? title = freezed,Object? description = freezed,Object? mimeType = freezed,Object? sizeBytes = freezed,}) {
  return _then(_McpResourceSummaryDto(
uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$McpResourceTemplateSummaryDto {

 String get uriTemplate; String? get name; String? get title; String? get description; String? get mimeType;
/// Create a copy of McpResourceTemplateSummaryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpResourceTemplateSummaryDtoCopyWith<McpResourceTemplateSummaryDto> get copyWith => _$McpResourceTemplateSummaryDtoCopyWithImpl<McpResourceTemplateSummaryDto>(this as McpResourceTemplateSummaryDto, _$identity);

  /// Serializes this McpResourceTemplateSummaryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpResourceTemplateSummaryDto&&(identical(other.uriTemplate, uriTemplate) || other.uriTemplate == uriTemplate)&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uriTemplate,name,title,description,mimeType);

@override
String toString() {
  return 'McpResourceTemplateSummaryDto(uriTemplate: $uriTemplate, name: $name, title: $title, description: $description, mimeType: $mimeType)';
}


}

/// @nodoc
abstract mixin class $McpResourceTemplateSummaryDtoCopyWith<$Res>  {
  factory $McpResourceTemplateSummaryDtoCopyWith(McpResourceTemplateSummaryDto value, $Res Function(McpResourceTemplateSummaryDto) _then) = _$McpResourceTemplateSummaryDtoCopyWithImpl;
@useResult
$Res call({
 String uriTemplate, String? name, String? title, String? description, String? mimeType
});




}
/// @nodoc
class _$McpResourceTemplateSummaryDtoCopyWithImpl<$Res>
    implements $McpResourceTemplateSummaryDtoCopyWith<$Res> {
  _$McpResourceTemplateSummaryDtoCopyWithImpl(this._self, this._then);

  final McpResourceTemplateSummaryDto _self;
  final $Res Function(McpResourceTemplateSummaryDto) _then;

/// Create a copy of McpResourceTemplateSummaryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uriTemplate = null,Object? name = freezed,Object? title = freezed,Object? description = freezed,Object? mimeType = freezed,}) {
  return _then(_self.copyWith(
uriTemplate: null == uriTemplate ? _self.uriTemplate : uriTemplate // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [McpResourceTemplateSummaryDto].
extension McpResourceTemplateSummaryDtoPatterns on McpResourceTemplateSummaryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _McpResourceTemplateSummaryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _McpResourceTemplateSummaryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _McpResourceTemplateSummaryDto value)  $default,){
final _that = this;
switch (_that) {
case _McpResourceTemplateSummaryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _McpResourceTemplateSummaryDto value)?  $default,){
final _that = this;
switch (_that) {
case _McpResourceTemplateSummaryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uriTemplate,  String? name,  String? title,  String? description,  String? mimeType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _McpResourceTemplateSummaryDto() when $default != null:
return $default(_that.uriTemplate,_that.name,_that.title,_that.description,_that.mimeType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uriTemplate,  String? name,  String? title,  String? description,  String? mimeType)  $default,) {final _that = this;
switch (_that) {
case _McpResourceTemplateSummaryDto():
return $default(_that.uriTemplate,_that.name,_that.title,_that.description,_that.mimeType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uriTemplate,  String? name,  String? title,  String? description,  String? mimeType)?  $default,) {final _that = this;
switch (_that) {
case _McpResourceTemplateSummaryDto() when $default != null:
return $default(_that.uriTemplate,_that.name,_that.title,_that.description,_that.mimeType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _McpResourceTemplateSummaryDto implements McpResourceTemplateSummaryDto {
  const _McpResourceTemplateSummaryDto({required this.uriTemplate, this.name, this.title, this.description, this.mimeType});
  factory _McpResourceTemplateSummaryDto.fromJson(Map<String, dynamic> json) => _$McpResourceTemplateSummaryDtoFromJson(json);

@override final  String uriTemplate;
@override final  String? name;
@override final  String? title;
@override final  String? description;
@override final  String? mimeType;

/// Create a copy of McpResourceTemplateSummaryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$McpResourceTemplateSummaryDtoCopyWith<_McpResourceTemplateSummaryDto> get copyWith => __$McpResourceTemplateSummaryDtoCopyWithImpl<_McpResourceTemplateSummaryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$McpResourceTemplateSummaryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _McpResourceTemplateSummaryDto&&(identical(other.uriTemplate, uriTemplate) || other.uriTemplate == uriTemplate)&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uriTemplate,name,title,description,mimeType);

@override
String toString() {
  return 'McpResourceTemplateSummaryDto(uriTemplate: $uriTemplate, name: $name, title: $title, description: $description, mimeType: $mimeType)';
}


}

/// @nodoc
abstract mixin class _$McpResourceTemplateSummaryDtoCopyWith<$Res> implements $McpResourceTemplateSummaryDtoCopyWith<$Res> {
  factory _$McpResourceTemplateSummaryDtoCopyWith(_McpResourceTemplateSummaryDto value, $Res Function(_McpResourceTemplateSummaryDto) _then) = __$McpResourceTemplateSummaryDtoCopyWithImpl;
@override @useResult
$Res call({
 String uriTemplate, String? name, String? title, String? description, String? mimeType
});




}
/// @nodoc
class __$McpResourceTemplateSummaryDtoCopyWithImpl<$Res>
    implements _$McpResourceTemplateSummaryDtoCopyWith<$Res> {
  __$McpResourceTemplateSummaryDtoCopyWithImpl(this._self, this._then);

  final _McpResourceTemplateSummaryDto _self;
  final $Res Function(_McpResourceTemplateSummaryDto) _then;

/// Create a copy of McpResourceTemplateSummaryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uriTemplate = null,Object? name = freezed,Object? title = freezed,Object? description = freezed,Object? mimeType = freezed,}) {
  return _then(_McpResourceTemplateSummaryDto(
uriTemplate: null == uriTemplate ? _self.uriTemplate : uriTemplate // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$McpServerStateDto {

 McpServerConfigDto get config; McpServerStatus get status; McpConfigScope get scope; String get sourcePath; bool get shadowed; String? get protocolVersion; String? get serverName; String? get serverVersion; List<McpToolSummaryDto> get tools; List<McpResourceSummaryDto> get resources; List<McpResourceTemplateSummaryDto> get resourceTemplates; String? get error; List<String> get diagnostics; DateTime? get lastConnectedAt; DateTime? get nextRetryAt; int get attempt;
/// Create a copy of McpServerStateDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpServerStateDtoCopyWith<McpServerStateDto> get copyWith => _$McpServerStateDtoCopyWithImpl<McpServerStateDto>(this as McpServerStateDto, _$identity);

  /// Serializes this McpServerStateDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpServerStateDto&&(identical(other.config, config) || other.config == config)&&(identical(other.status, status) || other.status == status)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath)&&(identical(other.shadowed, shadowed) || other.shadowed == shadowed)&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&(identical(other.serverName, serverName) || other.serverName == serverName)&&(identical(other.serverVersion, serverVersion) || other.serverVersion == serverVersion)&&const DeepCollectionEquality().equals(other.tools, tools)&&const DeepCollectionEquality().equals(other.resources, resources)&&const DeepCollectionEquality().equals(other.resourceTemplates, resourceTemplates)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other.diagnostics, diagnostics)&&(identical(other.lastConnectedAt, lastConnectedAt) || other.lastConnectedAt == lastConnectedAt)&&(identical(other.nextRetryAt, nextRetryAt) || other.nextRetryAt == nextRetryAt)&&(identical(other.attempt, attempt) || other.attempt == attempt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,config,status,scope,sourcePath,shadowed,protocolVersion,serverName,serverVersion,const DeepCollectionEquality().hash(tools),const DeepCollectionEquality().hash(resources),const DeepCollectionEquality().hash(resourceTemplates),error,const DeepCollectionEquality().hash(diagnostics),lastConnectedAt,nextRetryAt,attempt);

@override
String toString() {
  return 'McpServerStateDto(config: $config, status: $status, scope: $scope, sourcePath: $sourcePath, shadowed: $shadowed, protocolVersion: $protocolVersion, serverName: $serverName, serverVersion: $serverVersion, tools: $tools, resources: $resources, resourceTemplates: $resourceTemplates, error: $error, diagnostics: $diagnostics, lastConnectedAt: $lastConnectedAt, nextRetryAt: $nextRetryAt, attempt: $attempt)';
}


}

/// @nodoc
abstract mixin class $McpServerStateDtoCopyWith<$Res>  {
  factory $McpServerStateDtoCopyWith(McpServerStateDto value, $Res Function(McpServerStateDto) _then) = _$McpServerStateDtoCopyWithImpl;
@useResult
$Res call({
 McpServerConfigDto config, McpServerStatus status, McpConfigScope scope, String sourcePath, bool shadowed, String? protocolVersion, String? serverName, String? serverVersion, List<McpToolSummaryDto> tools, List<McpResourceSummaryDto> resources, List<McpResourceTemplateSummaryDto> resourceTemplates, String? error, List<String> diagnostics, DateTime? lastConnectedAt, DateTime? nextRetryAt, int attempt
});


$McpServerConfigDtoCopyWith<$Res> get config;

}
/// @nodoc
class _$McpServerStateDtoCopyWithImpl<$Res>
    implements $McpServerStateDtoCopyWith<$Res> {
  _$McpServerStateDtoCopyWithImpl(this._self, this._then);

  final McpServerStateDto _self;
  final $Res Function(McpServerStateDto) _then;

/// Create a copy of McpServerStateDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? config = null,Object? status = null,Object? scope = null,Object? sourcePath = null,Object? shadowed = null,Object? protocolVersion = freezed,Object? serverName = freezed,Object? serverVersion = freezed,Object? tools = null,Object? resources = null,Object? resourceTemplates = null,Object? error = freezed,Object? diagnostics = null,Object? lastConnectedAt = freezed,Object? nextRetryAt = freezed,Object? attempt = null,}) {
  return _then(_self.copyWith(
config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as McpServerConfigDto,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as McpServerStatus,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as McpConfigScope,sourcePath: null == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String,shadowed: null == shadowed ? _self.shadowed : shadowed // ignore: cast_nullable_to_non_nullable
as bool,protocolVersion: freezed == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as String?,serverName: freezed == serverName ? _self.serverName : serverName // ignore: cast_nullable_to_non_nullable
as String?,serverVersion: freezed == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as String?,tools: null == tools ? _self.tools : tools // ignore: cast_nullable_to_non_nullable
as List<McpToolSummaryDto>,resources: null == resources ? _self.resources : resources // ignore: cast_nullable_to_non_nullable
as List<McpResourceSummaryDto>,resourceTemplates: null == resourceTemplates ? _self.resourceTemplates : resourceTemplates // ignore: cast_nullable_to_non_nullable
as List<McpResourceTemplateSummaryDto>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<String>,lastConnectedAt: freezed == lastConnectedAt ? _self.lastConnectedAt : lastConnectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,nextRetryAt: freezed == nextRetryAt ? _self.nextRetryAt : nextRetryAt // ignore: cast_nullable_to_non_nullable
as DateTime?,attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of McpServerStateDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$McpServerConfigDtoCopyWith<$Res> get config {
  
  return $McpServerConfigDtoCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}


/// Adds pattern-matching-related methods to [McpServerStateDto].
extension McpServerStateDtoPatterns on McpServerStateDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _McpServerStateDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _McpServerStateDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _McpServerStateDto value)  $default,){
final _that = this;
switch (_that) {
case _McpServerStateDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _McpServerStateDto value)?  $default,){
final _that = this;
switch (_that) {
case _McpServerStateDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( McpServerConfigDto config,  McpServerStatus status,  McpConfigScope scope,  String sourcePath,  bool shadowed,  String? protocolVersion,  String? serverName,  String? serverVersion,  List<McpToolSummaryDto> tools,  List<McpResourceSummaryDto> resources,  List<McpResourceTemplateSummaryDto> resourceTemplates,  String? error,  List<String> diagnostics,  DateTime? lastConnectedAt,  DateTime? nextRetryAt,  int attempt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _McpServerStateDto() when $default != null:
return $default(_that.config,_that.status,_that.scope,_that.sourcePath,_that.shadowed,_that.protocolVersion,_that.serverName,_that.serverVersion,_that.tools,_that.resources,_that.resourceTemplates,_that.error,_that.diagnostics,_that.lastConnectedAt,_that.nextRetryAt,_that.attempt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( McpServerConfigDto config,  McpServerStatus status,  McpConfigScope scope,  String sourcePath,  bool shadowed,  String? protocolVersion,  String? serverName,  String? serverVersion,  List<McpToolSummaryDto> tools,  List<McpResourceSummaryDto> resources,  List<McpResourceTemplateSummaryDto> resourceTemplates,  String? error,  List<String> diagnostics,  DateTime? lastConnectedAt,  DateTime? nextRetryAt,  int attempt)  $default,) {final _that = this;
switch (_that) {
case _McpServerStateDto():
return $default(_that.config,_that.status,_that.scope,_that.sourcePath,_that.shadowed,_that.protocolVersion,_that.serverName,_that.serverVersion,_that.tools,_that.resources,_that.resourceTemplates,_that.error,_that.diagnostics,_that.lastConnectedAt,_that.nextRetryAt,_that.attempt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( McpServerConfigDto config,  McpServerStatus status,  McpConfigScope scope,  String sourcePath,  bool shadowed,  String? protocolVersion,  String? serverName,  String? serverVersion,  List<McpToolSummaryDto> tools,  List<McpResourceSummaryDto> resources,  List<McpResourceTemplateSummaryDto> resourceTemplates,  String? error,  List<String> diagnostics,  DateTime? lastConnectedAt,  DateTime? nextRetryAt,  int attempt)?  $default,) {final _that = this;
switch (_that) {
case _McpServerStateDto() when $default != null:
return $default(_that.config,_that.status,_that.scope,_that.sourcePath,_that.shadowed,_that.protocolVersion,_that.serverName,_that.serverVersion,_that.tools,_that.resources,_that.resourceTemplates,_that.error,_that.diagnostics,_that.lastConnectedAt,_that.nextRetryAt,_that.attempt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _McpServerStateDto implements McpServerStateDto {
  const _McpServerStateDto({required this.config, required this.status, required this.scope, required this.sourcePath, this.shadowed = false, this.protocolVersion, this.serverName, this.serverVersion, final  List<McpToolSummaryDto> tools = const <McpToolSummaryDto>[], final  List<McpResourceSummaryDto> resources = const <McpResourceSummaryDto>[], final  List<McpResourceTemplateSummaryDto> resourceTemplates = const <McpResourceTemplateSummaryDto>[], this.error, final  List<String> diagnostics = const <String>[], this.lastConnectedAt, this.nextRetryAt, this.attempt = 0}): _tools = tools,_resources = resources,_resourceTemplates = resourceTemplates,_diagnostics = diagnostics;
  factory _McpServerStateDto.fromJson(Map<String, dynamic> json) => _$McpServerStateDtoFromJson(json);

@override final  McpServerConfigDto config;
@override final  McpServerStatus status;
@override final  McpConfigScope scope;
@override final  String sourcePath;
@override@JsonKey() final  bool shadowed;
@override final  String? protocolVersion;
@override final  String? serverName;
@override final  String? serverVersion;
 final  List<McpToolSummaryDto> _tools;
@override@JsonKey() List<McpToolSummaryDto> get tools {
  if (_tools is EqualUnmodifiableListView) return _tools;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tools);
}

 final  List<McpResourceSummaryDto> _resources;
@override@JsonKey() List<McpResourceSummaryDto> get resources {
  if (_resources is EqualUnmodifiableListView) return _resources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_resources);
}

 final  List<McpResourceTemplateSummaryDto> _resourceTemplates;
@override@JsonKey() List<McpResourceTemplateSummaryDto> get resourceTemplates {
  if (_resourceTemplates is EqualUnmodifiableListView) return _resourceTemplates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_resourceTemplates);
}

@override final  String? error;
 final  List<String> _diagnostics;
@override@JsonKey() List<String> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}

@override final  DateTime? lastConnectedAt;
@override final  DateTime? nextRetryAt;
@override@JsonKey() final  int attempt;

/// Create a copy of McpServerStateDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$McpServerStateDtoCopyWith<_McpServerStateDto> get copyWith => __$McpServerStateDtoCopyWithImpl<_McpServerStateDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$McpServerStateDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _McpServerStateDto&&(identical(other.config, config) || other.config == config)&&(identical(other.status, status) || other.status == status)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath)&&(identical(other.shadowed, shadowed) || other.shadowed == shadowed)&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&(identical(other.serverName, serverName) || other.serverName == serverName)&&(identical(other.serverVersion, serverVersion) || other.serverVersion == serverVersion)&&const DeepCollectionEquality().equals(other._tools, _tools)&&const DeepCollectionEquality().equals(other._resources, _resources)&&const DeepCollectionEquality().equals(other._resourceTemplates, _resourceTemplates)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics)&&(identical(other.lastConnectedAt, lastConnectedAt) || other.lastConnectedAt == lastConnectedAt)&&(identical(other.nextRetryAt, nextRetryAt) || other.nextRetryAt == nextRetryAt)&&(identical(other.attempt, attempt) || other.attempt == attempt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,config,status,scope,sourcePath,shadowed,protocolVersion,serverName,serverVersion,const DeepCollectionEquality().hash(_tools),const DeepCollectionEquality().hash(_resources),const DeepCollectionEquality().hash(_resourceTemplates),error,const DeepCollectionEquality().hash(_diagnostics),lastConnectedAt,nextRetryAt,attempt);

@override
String toString() {
  return 'McpServerStateDto(config: $config, status: $status, scope: $scope, sourcePath: $sourcePath, shadowed: $shadowed, protocolVersion: $protocolVersion, serverName: $serverName, serverVersion: $serverVersion, tools: $tools, resources: $resources, resourceTemplates: $resourceTemplates, error: $error, diagnostics: $diagnostics, lastConnectedAt: $lastConnectedAt, nextRetryAt: $nextRetryAt, attempt: $attempt)';
}


}

/// @nodoc
abstract mixin class _$McpServerStateDtoCopyWith<$Res> implements $McpServerStateDtoCopyWith<$Res> {
  factory _$McpServerStateDtoCopyWith(_McpServerStateDto value, $Res Function(_McpServerStateDto) _then) = __$McpServerStateDtoCopyWithImpl;
@override @useResult
$Res call({
 McpServerConfigDto config, McpServerStatus status, McpConfigScope scope, String sourcePath, bool shadowed, String? protocolVersion, String? serverName, String? serverVersion, List<McpToolSummaryDto> tools, List<McpResourceSummaryDto> resources, List<McpResourceTemplateSummaryDto> resourceTemplates, String? error, List<String> diagnostics, DateTime? lastConnectedAt, DateTime? nextRetryAt, int attempt
});


@override $McpServerConfigDtoCopyWith<$Res> get config;

}
/// @nodoc
class __$McpServerStateDtoCopyWithImpl<$Res>
    implements _$McpServerStateDtoCopyWith<$Res> {
  __$McpServerStateDtoCopyWithImpl(this._self, this._then);

  final _McpServerStateDto _self;
  final $Res Function(_McpServerStateDto) _then;

/// Create a copy of McpServerStateDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? config = null,Object? status = null,Object? scope = null,Object? sourcePath = null,Object? shadowed = null,Object? protocolVersion = freezed,Object? serverName = freezed,Object? serverVersion = freezed,Object? tools = null,Object? resources = null,Object? resourceTemplates = null,Object? error = freezed,Object? diagnostics = null,Object? lastConnectedAt = freezed,Object? nextRetryAt = freezed,Object? attempt = null,}) {
  return _then(_McpServerStateDto(
config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as McpServerConfigDto,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as McpServerStatus,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as McpConfigScope,sourcePath: null == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String,shadowed: null == shadowed ? _self.shadowed : shadowed // ignore: cast_nullable_to_non_nullable
as bool,protocolVersion: freezed == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as String?,serverName: freezed == serverName ? _self.serverName : serverName // ignore: cast_nullable_to_non_nullable
as String?,serverVersion: freezed == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as String?,tools: null == tools ? _self._tools : tools // ignore: cast_nullable_to_non_nullable
as List<McpToolSummaryDto>,resources: null == resources ? _self._resources : resources // ignore: cast_nullable_to_non_nullable
as List<McpResourceSummaryDto>,resourceTemplates: null == resourceTemplates ? _self._resourceTemplates : resourceTemplates // ignore: cast_nullable_to_non_nullable
as List<McpResourceTemplateSummaryDto>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<String>,lastConnectedAt: freezed == lastConnectedAt ? _self.lastConnectedAt : lastConnectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,nextRetryAt: freezed == nextRetryAt ? _self.nextRetryAt : nextRetryAt // ignore: cast_nullable_to_non_nullable
as DateTime?,attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of McpServerStateDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$McpServerConfigDtoCopyWith<$Res> get config {
  
  return $McpServerConfigDtoCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}


/// @nodoc
mixin _$AgentCommandDto {

 String get id; String get name; String get description; AgentCommandSource get source; String get sourcePath; String get body; String? get argumentHint;
/// Create a copy of AgentCommandDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentCommandDtoCopyWith<AgentCommandDto> get copyWith => _$AgentCommandDtoCopyWithImpl<AgentCommandDto>(this as AgentCommandDto, _$identity);

  /// Serializes this AgentCommandDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentCommandDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath)&&(identical(other.body, body) || other.body == body)&&(identical(other.argumentHint, argumentHint) || other.argumentHint == argumentHint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,source,sourcePath,body,argumentHint);

@override
String toString() {
  return 'AgentCommandDto(id: $id, name: $name, description: $description, source: $source, sourcePath: $sourcePath, body: $body, argumentHint: $argumentHint)';
}


}

/// @nodoc
abstract mixin class $AgentCommandDtoCopyWith<$Res>  {
  factory $AgentCommandDtoCopyWith(AgentCommandDto value, $Res Function(AgentCommandDto) _then) = _$AgentCommandDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, AgentCommandSource source, String sourcePath, String body, String? argumentHint
});




}
/// @nodoc
class _$AgentCommandDtoCopyWithImpl<$Res>
    implements $AgentCommandDtoCopyWith<$Res> {
  _$AgentCommandDtoCopyWithImpl(this._self, this._then);

  final AgentCommandDto _self;
  final $Res Function(AgentCommandDto) _then;

/// Create a copy of AgentCommandDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? source = null,Object? sourcePath = null,Object? body = null,Object? argumentHint = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as AgentCommandSource,sourcePath: null == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,argumentHint: freezed == argumentHint ? _self.argumentHint : argumentHint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentCommandDto].
extension AgentCommandDtoPatterns on AgentCommandDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentCommandDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentCommandDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentCommandDto value)  $default,){
final _that = this;
switch (_that) {
case _AgentCommandDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentCommandDto value)?  $default,){
final _that = this;
switch (_that) {
case _AgentCommandDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  AgentCommandSource source,  String sourcePath,  String body,  String? argumentHint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentCommandDto() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.source,_that.sourcePath,_that.body,_that.argumentHint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  AgentCommandSource source,  String sourcePath,  String body,  String? argumentHint)  $default,) {final _that = this;
switch (_that) {
case _AgentCommandDto():
return $default(_that.id,_that.name,_that.description,_that.source,_that.sourcePath,_that.body,_that.argumentHint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  AgentCommandSource source,  String sourcePath,  String body,  String? argumentHint)?  $default,) {final _that = this;
switch (_that) {
case _AgentCommandDto() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.source,_that.sourcePath,_that.body,_that.argumentHint);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentCommandDto implements AgentCommandDto {
  const _AgentCommandDto({required this.id, required this.name, required this.description, required this.source, required this.sourcePath, required this.body, this.argumentHint});
  factory _AgentCommandDto.fromJson(Map<String, dynamic> json) => _$AgentCommandDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String description;
@override final  AgentCommandSource source;
@override final  String sourcePath;
@override final  String body;
@override final  String? argumentHint;

/// Create a copy of AgentCommandDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentCommandDtoCopyWith<_AgentCommandDto> get copyWith => __$AgentCommandDtoCopyWithImpl<_AgentCommandDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentCommandDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentCommandDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath)&&(identical(other.body, body) || other.body == body)&&(identical(other.argumentHint, argumentHint) || other.argumentHint == argumentHint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,source,sourcePath,body,argumentHint);

@override
String toString() {
  return 'AgentCommandDto(id: $id, name: $name, description: $description, source: $source, sourcePath: $sourcePath, body: $body, argumentHint: $argumentHint)';
}


}

/// @nodoc
abstract mixin class _$AgentCommandDtoCopyWith<$Res> implements $AgentCommandDtoCopyWith<$Res> {
  factory _$AgentCommandDtoCopyWith(_AgentCommandDto value, $Res Function(_AgentCommandDto) _then) = __$AgentCommandDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, AgentCommandSource source, String sourcePath, String body, String? argumentHint
});




}
/// @nodoc
class __$AgentCommandDtoCopyWithImpl<$Res>
    implements _$AgentCommandDtoCopyWith<$Res> {
  __$AgentCommandDtoCopyWithImpl(this._self, this._then);

  final _AgentCommandDto _self;
  final $Res Function(_AgentCommandDto) _then;

/// Create a copy of AgentCommandDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? source = null,Object? sourcePath = null,Object? body = null,Object? argumentHint = freezed,}) {
  return _then(_AgentCommandDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as AgentCommandSource,sourcePath: null == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,argumentHint: freezed == argumentHint ? _self.argumentHint : argumentHint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SkillDiagnosticDto {

 String get code; String get message;
/// Create a copy of SkillDiagnosticDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillDiagnosticDtoCopyWith<SkillDiagnosticDto> get copyWith => _$SkillDiagnosticDtoCopyWithImpl<SkillDiagnosticDto>(this as SkillDiagnosticDto, _$identity);

  /// Serializes this SkillDiagnosticDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillDiagnosticDto&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'SkillDiagnosticDto(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class $SkillDiagnosticDtoCopyWith<$Res>  {
  factory $SkillDiagnosticDtoCopyWith(SkillDiagnosticDto value, $Res Function(SkillDiagnosticDto) _then) = _$SkillDiagnosticDtoCopyWithImpl;
@useResult
$Res call({
 String code, String message
});




}
/// @nodoc
class _$SkillDiagnosticDtoCopyWithImpl<$Res>
    implements $SkillDiagnosticDtoCopyWith<$Res> {
  _$SkillDiagnosticDtoCopyWithImpl(this._self, this._then);

  final SkillDiagnosticDto _self;
  final $Res Function(SkillDiagnosticDto) _then;

/// Create a copy of SkillDiagnosticDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillDiagnosticDto].
extension SkillDiagnosticDtoPatterns on SkillDiagnosticDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillDiagnosticDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillDiagnosticDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillDiagnosticDto value)  $default,){
final _that = this;
switch (_that) {
case _SkillDiagnosticDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillDiagnosticDto value)?  $default,){
final _that = this;
switch (_that) {
case _SkillDiagnosticDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillDiagnosticDto() when $default != null:
return $default(_that.code,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String message)  $default,) {final _that = this;
switch (_that) {
case _SkillDiagnosticDto():
return $default(_that.code,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String message)?  $default,) {final _that = this;
switch (_that) {
case _SkillDiagnosticDto() when $default != null:
return $default(_that.code,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SkillDiagnosticDto implements SkillDiagnosticDto {
  const _SkillDiagnosticDto({required this.code, required this.message});
  factory _SkillDiagnosticDto.fromJson(Map<String, dynamic> json) => _$SkillDiagnosticDtoFromJson(json);

@override final  String code;
@override final  String message;

/// Create a copy of SkillDiagnosticDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillDiagnosticDtoCopyWith<_SkillDiagnosticDto> get copyWith => __$SkillDiagnosticDtoCopyWithImpl<_SkillDiagnosticDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SkillDiagnosticDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillDiagnosticDto&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'SkillDiagnosticDto(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class _$SkillDiagnosticDtoCopyWith<$Res> implements $SkillDiagnosticDtoCopyWith<$Res> {
  factory _$SkillDiagnosticDtoCopyWith(_SkillDiagnosticDto value, $Res Function(_SkillDiagnosticDto) _then) = __$SkillDiagnosticDtoCopyWithImpl;
@override @useResult
$Res call({
 String code, String message
});




}
/// @nodoc
class __$SkillDiagnosticDtoCopyWithImpl<$Res>
    implements _$SkillDiagnosticDtoCopyWith<$Res> {
  __$SkillDiagnosticDtoCopyWithImpl(this._self, this._then);

  final _SkillDiagnosticDto _self;
  final $Res Function(_SkillDiagnosticDto) _then;

/// Create a copy of SkillDiagnosticDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,}) {
  return _then(_SkillDiagnosticDto(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SkillResourceDto {

 String get path; int get sizeBytes;
/// Create a copy of SkillResourceDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillResourceDtoCopyWith<SkillResourceDto> get copyWith => _$SkillResourceDtoCopyWithImpl<SkillResourceDto>(this as SkillResourceDto, _$identity);

  /// Serializes this SkillResourceDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillResourceDto&&(identical(other.path, path) || other.path == path)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,sizeBytes);

@override
String toString() {
  return 'SkillResourceDto(path: $path, sizeBytes: $sizeBytes)';
}


}

/// @nodoc
abstract mixin class $SkillResourceDtoCopyWith<$Res>  {
  factory $SkillResourceDtoCopyWith(SkillResourceDto value, $Res Function(SkillResourceDto) _then) = _$SkillResourceDtoCopyWithImpl;
@useResult
$Res call({
 String path, int sizeBytes
});




}
/// @nodoc
class _$SkillResourceDtoCopyWithImpl<$Res>
    implements $SkillResourceDtoCopyWith<$Res> {
  _$SkillResourceDtoCopyWithImpl(this._self, this._then);

  final SkillResourceDto _self;
  final $Res Function(SkillResourceDto) _then;

/// Create a copy of SkillResourceDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? sizeBytes = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillResourceDto].
extension SkillResourceDtoPatterns on SkillResourceDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillResourceDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillResourceDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillResourceDto value)  $default,){
final _that = this;
switch (_that) {
case _SkillResourceDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillResourceDto value)?  $default,){
final _that = this;
switch (_that) {
case _SkillResourceDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  int sizeBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillResourceDto() when $default != null:
return $default(_that.path,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  int sizeBytes)  $default,) {final _that = this;
switch (_that) {
case _SkillResourceDto():
return $default(_that.path,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  int sizeBytes)?  $default,) {final _that = this;
switch (_that) {
case _SkillResourceDto() when $default != null:
return $default(_that.path,_that.sizeBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SkillResourceDto implements SkillResourceDto {
  const _SkillResourceDto({required this.path, required this.sizeBytes});
  factory _SkillResourceDto.fromJson(Map<String, dynamic> json) => _$SkillResourceDtoFromJson(json);

@override final  String path;
@override final  int sizeBytes;

/// Create a copy of SkillResourceDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillResourceDtoCopyWith<_SkillResourceDto> get copyWith => __$SkillResourceDtoCopyWithImpl<_SkillResourceDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SkillResourceDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillResourceDto&&(identical(other.path, path) || other.path == path)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,sizeBytes);

@override
String toString() {
  return 'SkillResourceDto(path: $path, sizeBytes: $sizeBytes)';
}


}

/// @nodoc
abstract mixin class _$SkillResourceDtoCopyWith<$Res> implements $SkillResourceDtoCopyWith<$Res> {
  factory _$SkillResourceDtoCopyWith(_SkillResourceDto value, $Res Function(_SkillResourceDto) _then) = __$SkillResourceDtoCopyWithImpl;
@override @useResult
$Res call({
 String path, int sizeBytes
});




}
/// @nodoc
class __$SkillResourceDtoCopyWithImpl<$Res>
    implements _$SkillResourceDtoCopyWith<$Res> {
  __$SkillResourceDtoCopyWithImpl(this._self, this._then);

  final _SkillResourceDto _self;
  final $Res Function(_SkillResourceDto) _then;

/// Create a copy of SkillResourceDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? sizeBytes = null,}) {
  return _then(_SkillResourceDto(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SkillDto {

 String get id; String get name; String get description; SkillSource get source; String get sourcePath; String get contentHash; String get body; List<SkillResourceDto> get resources; bool get isEnabled; bool get isMandatory; bool get isEditable; bool get isShadowed; bool get isStale; List<SkillDiagnosticDto> get diagnostics;
/// Create a copy of SkillDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillDtoCopyWith<SkillDto> get copyWith => _$SkillDtoCopyWithImpl<SkillDto>(this as SkillDto, _$identity);

  /// Serializes this SkillDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath)&&(identical(other.contentHash, contentHash) || other.contentHash == contentHash)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other.resources, resources)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.isMandatory, isMandatory) || other.isMandatory == isMandatory)&&(identical(other.isEditable, isEditable) || other.isEditable == isEditable)&&(identical(other.isShadowed, isShadowed) || other.isShadowed == isShadowed)&&(identical(other.isStale, isStale) || other.isStale == isStale)&&const DeepCollectionEquality().equals(other.diagnostics, diagnostics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,source,sourcePath,contentHash,body,const DeepCollectionEquality().hash(resources),isEnabled,isMandatory,isEditable,isShadowed,isStale,const DeepCollectionEquality().hash(diagnostics));

@override
String toString() {
  return 'SkillDto(id: $id, name: $name, description: $description, source: $source, sourcePath: $sourcePath, contentHash: $contentHash, body: $body, resources: $resources, isEnabled: $isEnabled, isMandatory: $isMandatory, isEditable: $isEditable, isShadowed: $isShadowed, isStale: $isStale, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $SkillDtoCopyWith<$Res>  {
  factory $SkillDtoCopyWith(SkillDto value, $Res Function(SkillDto) _then) = _$SkillDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, SkillSource source, String sourcePath, String contentHash, String body, List<SkillResourceDto> resources, bool isEnabled, bool isMandatory, bool isEditable, bool isShadowed, bool isStale, List<SkillDiagnosticDto> diagnostics
});




}
/// @nodoc
class _$SkillDtoCopyWithImpl<$Res>
    implements $SkillDtoCopyWith<$Res> {
  _$SkillDtoCopyWithImpl(this._self, this._then);

  final SkillDto _self;
  final $Res Function(SkillDto) _then;

/// Create a copy of SkillDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? source = null,Object? sourcePath = null,Object? contentHash = null,Object? body = null,Object? resources = null,Object? isEnabled = null,Object? isMandatory = null,Object? isEditable = null,Object? isShadowed = null,Object? isStale = null,Object? diagnostics = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SkillSource,sourcePath: null == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String,contentHash: null == contentHash ? _self.contentHash : contentHash // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,resources: null == resources ? _self.resources : resources // ignore: cast_nullable_to_non_nullable
as List<SkillResourceDto>,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,isMandatory: null == isMandatory ? _self.isMandatory : isMandatory // ignore: cast_nullable_to_non_nullable
as bool,isEditable: null == isEditable ? _self.isEditable : isEditable // ignore: cast_nullable_to_non_nullable
as bool,isShadowed: null == isShadowed ? _self.isShadowed : isShadowed // ignore: cast_nullable_to_non_nullable
as bool,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<SkillDiagnosticDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillDto].
extension SkillDtoPatterns on SkillDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillDto value)  $default,){
final _that = this;
switch (_that) {
case _SkillDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillDto value)?  $default,){
final _that = this;
switch (_that) {
case _SkillDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  SkillSource source,  String sourcePath,  String contentHash,  String body,  List<SkillResourceDto> resources,  bool isEnabled,  bool isMandatory,  bool isEditable,  bool isShadowed,  bool isStale,  List<SkillDiagnosticDto> diagnostics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillDto() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.source,_that.sourcePath,_that.contentHash,_that.body,_that.resources,_that.isEnabled,_that.isMandatory,_that.isEditable,_that.isShadowed,_that.isStale,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  SkillSource source,  String sourcePath,  String contentHash,  String body,  List<SkillResourceDto> resources,  bool isEnabled,  bool isMandatory,  bool isEditable,  bool isShadowed,  bool isStale,  List<SkillDiagnosticDto> diagnostics)  $default,) {final _that = this;
switch (_that) {
case _SkillDto():
return $default(_that.id,_that.name,_that.description,_that.source,_that.sourcePath,_that.contentHash,_that.body,_that.resources,_that.isEnabled,_that.isMandatory,_that.isEditable,_that.isShadowed,_that.isStale,_that.diagnostics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  SkillSource source,  String sourcePath,  String contentHash,  String body,  List<SkillResourceDto> resources,  bool isEnabled,  bool isMandatory,  bool isEditable,  bool isShadowed,  bool isStale,  List<SkillDiagnosticDto> diagnostics)?  $default,) {final _that = this;
switch (_that) {
case _SkillDto() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.source,_that.sourcePath,_that.contentHash,_that.body,_that.resources,_that.isEnabled,_that.isMandatory,_that.isEditable,_that.isShadowed,_that.isStale,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SkillDto implements SkillDto {
  const _SkillDto({required this.id, required this.name, required this.description, required this.source, required this.sourcePath, required this.contentHash, required this.body, final  List<SkillResourceDto> resources = const <SkillResourceDto>[], this.isEnabled = true, this.isMandatory = false, this.isEditable = false, this.isShadowed = false, this.isStale = false, final  List<SkillDiagnosticDto> diagnostics = const <SkillDiagnosticDto>[]}): _resources = resources,_diagnostics = diagnostics;
  factory _SkillDto.fromJson(Map<String, dynamic> json) => _$SkillDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String description;
@override final  SkillSource source;
@override final  String sourcePath;
@override final  String contentHash;
@override final  String body;
 final  List<SkillResourceDto> _resources;
@override@JsonKey() List<SkillResourceDto> get resources {
  if (_resources is EqualUnmodifiableListView) return _resources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_resources);
}

@override@JsonKey() final  bool isEnabled;
@override@JsonKey() final  bool isMandatory;
@override@JsonKey() final  bool isEditable;
@override@JsonKey() final  bool isShadowed;
@override@JsonKey() final  bool isStale;
 final  List<SkillDiagnosticDto> _diagnostics;
@override@JsonKey() List<SkillDiagnosticDto> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of SkillDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillDtoCopyWith<_SkillDto> get copyWith => __$SkillDtoCopyWithImpl<_SkillDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SkillDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath)&&(identical(other.contentHash, contentHash) || other.contentHash == contentHash)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other._resources, _resources)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.isMandatory, isMandatory) || other.isMandatory == isMandatory)&&(identical(other.isEditable, isEditable) || other.isEditable == isEditable)&&(identical(other.isShadowed, isShadowed) || other.isShadowed == isShadowed)&&(identical(other.isStale, isStale) || other.isStale == isStale)&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,source,sourcePath,contentHash,body,const DeepCollectionEquality().hash(_resources),isEnabled,isMandatory,isEditable,isShadowed,isStale,const DeepCollectionEquality().hash(_diagnostics));

@override
String toString() {
  return 'SkillDto(id: $id, name: $name, description: $description, source: $source, sourcePath: $sourcePath, contentHash: $contentHash, body: $body, resources: $resources, isEnabled: $isEnabled, isMandatory: $isMandatory, isEditable: $isEditable, isShadowed: $isShadowed, isStale: $isStale, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$SkillDtoCopyWith<$Res> implements $SkillDtoCopyWith<$Res> {
  factory _$SkillDtoCopyWith(_SkillDto value, $Res Function(_SkillDto) _then) = __$SkillDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, SkillSource source, String sourcePath, String contentHash, String body, List<SkillResourceDto> resources, bool isEnabled, bool isMandatory, bool isEditable, bool isShadowed, bool isStale, List<SkillDiagnosticDto> diagnostics
});




}
/// @nodoc
class __$SkillDtoCopyWithImpl<$Res>
    implements _$SkillDtoCopyWith<$Res> {
  __$SkillDtoCopyWithImpl(this._self, this._then);

  final _SkillDto _self;
  final $Res Function(_SkillDto) _then;

/// Create a copy of SkillDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? source = null,Object? sourcePath = null,Object? contentHash = null,Object? body = null,Object? resources = null,Object? isEnabled = null,Object? isMandatory = null,Object? isEditable = null,Object? isShadowed = null,Object? isStale = null,Object? diagnostics = null,}) {
  return _then(_SkillDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SkillSource,sourcePath: null == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String,contentHash: null == contentHash ? _self.contentHash : contentHash // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,resources: null == resources ? _self._resources : resources // ignore: cast_nullable_to_non_nullable
as List<SkillResourceDto>,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,isMandatory: null == isMandatory ? _self.isMandatory : isMandatory // ignore: cast_nullable_to_non_nullable
as bool,isEditable: null == isEditable ? _self.isEditable : isEditable // ignore: cast_nullable_to_non_nullable
as bool,isShadowed: null == isShadowed ? _self.isShadowed : isShadowed // ignore: cast_nullable_to_non_nullable
as bool,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<SkillDiagnosticDto>,
  ));
}


}


/// @nodoc
mixin _$SessionModelSelectionDto {

 String get providerConnectionId; String get modelId;
/// Create a copy of SessionModelSelectionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionModelSelectionDtoCopyWith<SessionModelSelectionDto> get copyWith => _$SessionModelSelectionDtoCopyWithImpl<SessionModelSelectionDto>(this as SessionModelSelectionDto, _$identity);

  /// Serializes this SessionModelSelectionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionModelSelectionDto&&(identical(other.providerConnectionId, providerConnectionId) || other.providerConnectionId == providerConnectionId)&&(identical(other.modelId, modelId) || other.modelId == modelId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerConnectionId,modelId);

@override
String toString() {
  return 'SessionModelSelectionDto(providerConnectionId: $providerConnectionId, modelId: $modelId)';
}


}

/// @nodoc
abstract mixin class $SessionModelSelectionDtoCopyWith<$Res>  {
  factory $SessionModelSelectionDtoCopyWith(SessionModelSelectionDto value, $Res Function(SessionModelSelectionDto) _then) = _$SessionModelSelectionDtoCopyWithImpl;
@useResult
$Res call({
 String providerConnectionId, String modelId
});




}
/// @nodoc
class _$SessionModelSelectionDtoCopyWithImpl<$Res>
    implements $SessionModelSelectionDtoCopyWith<$Res> {
  _$SessionModelSelectionDtoCopyWithImpl(this._self, this._then);

  final SessionModelSelectionDto _self;
  final $Res Function(SessionModelSelectionDto) _then;

/// Create a copy of SessionModelSelectionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? providerConnectionId = null,Object? modelId = null,}) {
  return _then(_self.copyWith(
providerConnectionId: null == providerConnectionId ? _self.providerConnectionId : providerConnectionId // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionModelSelectionDto].
extension SessionModelSelectionDtoPatterns on SessionModelSelectionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionModelSelectionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionModelSelectionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionModelSelectionDto value)  $default,){
final _that = this;
switch (_that) {
case _SessionModelSelectionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionModelSelectionDto value)?  $default,){
final _that = this;
switch (_that) {
case _SessionModelSelectionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String providerConnectionId,  String modelId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionModelSelectionDto() when $default != null:
return $default(_that.providerConnectionId,_that.modelId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String providerConnectionId,  String modelId)  $default,) {final _that = this;
switch (_that) {
case _SessionModelSelectionDto():
return $default(_that.providerConnectionId,_that.modelId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String providerConnectionId,  String modelId)?  $default,) {final _that = this;
switch (_that) {
case _SessionModelSelectionDto() when $default != null:
return $default(_that.providerConnectionId,_that.modelId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionModelSelectionDto implements SessionModelSelectionDto {
  const _SessionModelSelectionDto({required this.providerConnectionId, required this.modelId});
  factory _SessionModelSelectionDto.fromJson(Map<String, dynamic> json) => _$SessionModelSelectionDtoFromJson(json);

@override final  String providerConnectionId;
@override final  String modelId;

/// Create a copy of SessionModelSelectionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionModelSelectionDtoCopyWith<_SessionModelSelectionDto> get copyWith => __$SessionModelSelectionDtoCopyWithImpl<_SessionModelSelectionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionModelSelectionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionModelSelectionDto&&(identical(other.providerConnectionId, providerConnectionId) || other.providerConnectionId == providerConnectionId)&&(identical(other.modelId, modelId) || other.modelId == modelId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerConnectionId,modelId);

@override
String toString() {
  return 'SessionModelSelectionDto(providerConnectionId: $providerConnectionId, modelId: $modelId)';
}


}

/// @nodoc
abstract mixin class _$SessionModelSelectionDtoCopyWith<$Res> implements $SessionModelSelectionDtoCopyWith<$Res> {
  factory _$SessionModelSelectionDtoCopyWith(_SessionModelSelectionDto value, $Res Function(_SessionModelSelectionDto) _then) = __$SessionModelSelectionDtoCopyWithImpl;
@override @useResult
$Res call({
 String providerConnectionId, String modelId
});




}
/// @nodoc
class __$SessionModelSelectionDtoCopyWithImpl<$Res>
    implements _$SessionModelSelectionDtoCopyWith<$Res> {
  __$SessionModelSelectionDtoCopyWithImpl(this._self, this._then);

  final _SessionModelSelectionDto _self;
  final $Res Function(_SessionModelSelectionDto) _then;

/// Create a copy of SessionModelSelectionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? providerConnectionId = null,Object? modelId = null,}) {
  return _then(_SessionModelSelectionDto(
providerConnectionId: null == providerConnectionId ? _self.providerConnectionId : providerConnectionId // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SessionDto {

 String get id; String get worktreeId; String get title; String get agentDefinitionId; SessionOrigin get origin; SessionStatus get status; DateTime get createdAt; DateTime get updatedAt; SessionMode get mode; SessionModelSelectionDto? get model;/// Overrides the reasoning effort of the agent definition; null inherits.
 String? get reasoningEffort;/// Overrides the permission mode of the agent definition; null inherits.
 PermissionMode? get permissionMode;/// Provider service tier for this session; null uses the provider default.
 String? get serviceTier; String? get parentSessionId;/// Leaf task name of a spawned subagent, e.g. `task_3`; null for roots.
 String? get taskName;/// Canonical collaboration path, e.g. `/root/task1/task_3`; null for
/// manually created root sessions (implicitly `/root`).
 String? get agentPath;/// Root session of the collaboration tree; null for root sessions.
 String? get rootSessionId;/// Collaboration lifecycle; null for sessions outside a tree.
 AgentLifecycle? get lifecycle; String? get activeTurnId; String? get lastError;/// Tokens the last response reported for the live context window.
 int get contextTokens;/// Context window of the resolved model; null when it is not advertised.
 int? get contextWindow;
/// Create a copy of SessionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionDtoCopyWith<SessionDto> get copyWith => _$SessionDtoCopyWithImpl<SessionDto>(this as SessionDto, _$identity);

  /// Serializes this SessionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.worktreeId, worktreeId) || other.worktreeId == worktreeId)&&(identical(other.title, title) || other.title == title)&&(identical(other.agentDefinitionId, agentDefinitionId) || other.agentDefinitionId == agentDefinitionId)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.model, model) || other.model == model)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort)&&(identical(other.permissionMode, permissionMode) || other.permissionMode == permissionMode)&&(identical(other.serviceTier, serviceTier) || other.serviceTier == serviceTier)&&(identical(other.parentSessionId, parentSessionId) || other.parentSessionId == parentSessionId)&&(identical(other.taskName, taskName) || other.taskName == taskName)&&(identical(other.agentPath, agentPath) || other.agentPath == agentPath)&&(identical(other.rootSessionId, rootSessionId) || other.rootSessionId == rootSessionId)&&(identical(other.lifecycle, lifecycle) || other.lifecycle == lifecycle)&&(identical(other.activeTurnId, activeTurnId) || other.activeTurnId == activeTurnId)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.contextTokens, contextTokens) || other.contextTokens == contextTokens)&&(identical(other.contextWindow, contextWindow) || other.contextWindow == contextWindow));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,worktreeId,title,agentDefinitionId,origin,status,createdAt,updatedAt,mode,model,reasoningEffort,permissionMode,serviceTier,parentSessionId,taskName,agentPath,rootSessionId,lifecycle,activeTurnId,lastError,contextTokens,contextWindow]);

@override
String toString() {
  return 'SessionDto(id: $id, worktreeId: $worktreeId, title: $title, agentDefinitionId: $agentDefinitionId, origin: $origin, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, mode: $mode, model: $model, reasoningEffort: $reasoningEffort, permissionMode: $permissionMode, serviceTier: $serviceTier, parentSessionId: $parentSessionId, taskName: $taskName, agentPath: $agentPath, rootSessionId: $rootSessionId, lifecycle: $lifecycle, activeTurnId: $activeTurnId, lastError: $lastError, contextTokens: $contextTokens, contextWindow: $contextWindow)';
}


}

/// @nodoc
abstract mixin class $SessionDtoCopyWith<$Res>  {
  factory $SessionDtoCopyWith(SessionDto value, $Res Function(SessionDto) _then) = _$SessionDtoCopyWithImpl;
@useResult
$Res call({
 String id, String worktreeId, String title, String agentDefinitionId, SessionOrigin origin, SessionStatus status, DateTime createdAt, DateTime updatedAt, SessionMode mode, SessionModelSelectionDto? model, String? reasoningEffort, PermissionMode? permissionMode, String? serviceTier, String? parentSessionId, String? taskName, String? agentPath, String? rootSessionId, AgentLifecycle? lifecycle, String? activeTurnId, String? lastError, int contextTokens, int? contextWindow
});


$SessionModelSelectionDtoCopyWith<$Res>? get model;

}
/// @nodoc
class _$SessionDtoCopyWithImpl<$Res>
    implements $SessionDtoCopyWith<$Res> {
  _$SessionDtoCopyWithImpl(this._self, this._then);

  final SessionDto _self;
  final $Res Function(SessionDto) _then;

/// Create a copy of SessionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? worktreeId = null,Object? title = null,Object? agentDefinitionId = null,Object? origin = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,Object? mode = null,Object? model = freezed,Object? reasoningEffort = freezed,Object? permissionMode = freezed,Object? serviceTier = freezed,Object? parentSessionId = freezed,Object? taskName = freezed,Object? agentPath = freezed,Object? rootSessionId = freezed,Object? lifecycle = freezed,Object? activeTurnId = freezed,Object? lastError = freezed,Object? contextTokens = null,Object? contextWindow = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,worktreeId: null == worktreeId ? _self.worktreeId : worktreeId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,agentDefinitionId: null == agentDefinitionId ? _self.agentDefinitionId : agentDefinitionId // ignore: cast_nullable_to_non_nullable
as String,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as SessionOrigin,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as SessionMode,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as SessionModelSelectionDto?,reasoningEffort: freezed == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as String?,permissionMode: freezed == permissionMode ? _self.permissionMode : permissionMode // ignore: cast_nullable_to_non_nullable
as PermissionMode?,serviceTier: freezed == serviceTier ? _self.serviceTier : serviceTier // ignore: cast_nullable_to_non_nullable
as String?,parentSessionId: freezed == parentSessionId ? _self.parentSessionId : parentSessionId // ignore: cast_nullable_to_non_nullable
as String?,taskName: freezed == taskName ? _self.taskName : taskName // ignore: cast_nullable_to_non_nullable
as String?,agentPath: freezed == agentPath ? _self.agentPath : agentPath // ignore: cast_nullable_to_non_nullable
as String?,rootSessionId: freezed == rootSessionId ? _self.rootSessionId : rootSessionId // ignore: cast_nullable_to_non_nullable
as String?,lifecycle: freezed == lifecycle ? _self.lifecycle : lifecycle // ignore: cast_nullable_to_non_nullable
as AgentLifecycle?,activeTurnId: freezed == activeTurnId ? _self.activeTurnId : activeTurnId // ignore: cast_nullable_to_non_nullable
as String?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,contextTokens: null == contextTokens ? _self.contextTokens : contextTokens // ignore: cast_nullable_to_non_nullable
as int,contextWindow: freezed == contextWindow ? _self.contextWindow : contextWindow // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of SessionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionModelSelectionDtoCopyWith<$Res>? get model {
    if (_self.model == null) {
    return null;
  }

  return $SessionModelSelectionDtoCopyWith<$Res>(_self.model!, (value) {
    return _then(_self.copyWith(model: value));
  });
}
}


/// Adds pattern-matching-related methods to [SessionDto].
extension SessionDtoPatterns on SessionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionDto value)  $default,){
final _that = this;
switch (_that) {
case _SessionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionDto value)?  $default,){
final _that = this;
switch (_that) {
case _SessionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String worktreeId,  String title,  String agentDefinitionId,  SessionOrigin origin,  SessionStatus status,  DateTime createdAt,  DateTime updatedAt,  SessionMode mode,  SessionModelSelectionDto? model,  String? reasoningEffort,  PermissionMode? permissionMode,  String? serviceTier,  String? parentSessionId,  String? taskName,  String? agentPath,  String? rootSessionId,  AgentLifecycle? lifecycle,  String? activeTurnId,  String? lastError,  int contextTokens,  int? contextWindow)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionDto() when $default != null:
return $default(_that.id,_that.worktreeId,_that.title,_that.agentDefinitionId,_that.origin,_that.status,_that.createdAt,_that.updatedAt,_that.mode,_that.model,_that.reasoningEffort,_that.permissionMode,_that.serviceTier,_that.parentSessionId,_that.taskName,_that.agentPath,_that.rootSessionId,_that.lifecycle,_that.activeTurnId,_that.lastError,_that.contextTokens,_that.contextWindow);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String worktreeId,  String title,  String agentDefinitionId,  SessionOrigin origin,  SessionStatus status,  DateTime createdAt,  DateTime updatedAt,  SessionMode mode,  SessionModelSelectionDto? model,  String? reasoningEffort,  PermissionMode? permissionMode,  String? serviceTier,  String? parentSessionId,  String? taskName,  String? agentPath,  String? rootSessionId,  AgentLifecycle? lifecycle,  String? activeTurnId,  String? lastError,  int contextTokens,  int? contextWindow)  $default,) {final _that = this;
switch (_that) {
case _SessionDto():
return $default(_that.id,_that.worktreeId,_that.title,_that.agentDefinitionId,_that.origin,_that.status,_that.createdAt,_that.updatedAt,_that.mode,_that.model,_that.reasoningEffort,_that.permissionMode,_that.serviceTier,_that.parentSessionId,_that.taskName,_that.agentPath,_that.rootSessionId,_that.lifecycle,_that.activeTurnId,_that.lastError,_that.contextTokens,_that.contextWindow);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String worktreeId,  String title,  String agentDefinitionId,  SessionOrigin origin,  SessionStatus status,  DateTime createdAt,  DateTime updatedAt,  SessionMode mode,  SessionModelSelectionDto? model,  String? reasoningEffort,  PermissionMode? permissionMode,  String? serviceTier,  String? parentSessionId,  String? taskName,  String? agentPath,  String? rootSessionId,  AgentLifecycle? lifecycle,  String? activeTurnId,  String? lastError,  int contextTokens,  int? contextWindow)?  $default,) {final _that = this;
switch (_that) {
case _SessionDto() when $default != null:
return $default(_that.id,_that.worktreeId,_that.title,_that.agentDefinitionId,_that.origin,_that.status,_that.createdAt,_that.updatedAt,_that.mode,_that.model,_that.reasoningEffort,_that.permissionMode,_that.serviceTier,_that.parentSessionId,_that.taskName,_that.agentPath,_that.rootSessionId,_that.lifecycle,_that.activeTurnId,_that.lastError,_that.contextTokens,_that.contextWindow);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionDto implements SessionDto {
  const _SessionDto({required this.id, required this.worktreeId, required this.title, required this.agentDefinitionId, required this.origin, required this.status, required this.createdAt, required this.updatedAt, this.mode = SessionMode.normal, this.model, this.reasoningEffort, this.permissionMode, this.serviceTier, this.parentSessionId, this.taskName, this.agentPath, this.rootSessionId, this.lifecycle, this.activeTurnId, this.lastError, this.contextTokens = 0, this.contextWindow});
  factory _SessionDto.fromJson(Map<String, dynamic> json) => _$SessionDtoFromJson(json);

@override final  String id;
@override final  String worktreeId;
@override final  String title;
@override final  String agentDefinitionId;
@override final  SessionOrigin origin;
@override final  SessionStatus status;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override@JsonKey() final  SessionMode mode;
@override final  SessionModelSelectionDto? model;
/// Overrides the reasoning effort of the agent definition; null inherits.
@override final  String? reasoningEffort;
/// Overrides the permission mode of the agent definition; null inherits.
@override final  PermissionMode? permissionMode;
/// Provider service tier for this session; null uses the provider default.
@override final  String? serviceTier;
@override final  String? parentSessionId;
/// Leaf task name of a spawned subagent, e.g. `task_3`; null for roots.
@override final  String? taskName;
/// Canonical collaboration path, e.g. `/root/task1/task_3`; null for
/// manually created root sessions (implicitly `/root`).
@override final  String? agentPath;
/// Root session of the collaboration tree; null for root sessions.
@override final  String? rootSessionId;
/// Collaboration lifecycle; null for sessions outside a tree.
@override final  AgentLifecycle? lifecycle;
@override final  String? activeTurnId;
@override final  String? lastError;
/// Tokens the last response reported for the live context window.
@override@JsonKey() final  int contextTokens;
/// Context window of the resolved model; null when it is not advertised.
@override final  int? contextWindow;

/// Create a copy of SessionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionDtoCopyWith<_SessionDto> get copyWith => __$SessionDtoCopyWithImpl<_SessionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.worktreeId, worktreeId) || other.worktreeId == worktreeId)&&(identical(other.title, title) || other.title == title)&&(identical(other.agentDefinitionId, agentDefinitionId) || other.agentDefinitionId == agentDefinitionId)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.model, model) || other.model == model)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort)&&(identical(other.permissionMode, permissionMode) || other.permissionMode == permissionMode)&&(identical(other.serviceTier, serviceTier) || other.serviceTier == serviceTier)&&(identical(other.parentSessionId, parentSessionId) || other.parentSessionId == parentSessionId)&&(identical(other.taskName, taskName) || other.taskName == taskName)&&(identical(other.agentPath, agentPath) || other.agentPath == agentPath)&&(identical(other.rootSessionId, rootSessionId) || other.rootSessionId == rootSessionId)&&(identical(other.lifecycle, lifecycle) || other.lifecycle == lifecycle)&&(identical(other.activeTurnId, activeTurnId) || other.activeTurnId == activeTurnId)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.contextTokens, contextTokens) || other.contextTokens == contextTokens)&&(identical(other.contextWindow, contextWindow) || other.contextWindow == contextWindow));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,worktreeId,title,agentDefinitionId,origin,status,createdAt,updatedAt,mode,model,reasoningEffort,permissionMode,serviceTier,parentSessionId,taskName,agentPath,rootSessionId,lifecycle,activeTurnId,lastError,contextTokens,contextWindow]);

@override
String toString() {
  return 'SessionDto(id: $id, worktreeId: $worktreeId, title: $title, agentDefinitionId: $agentDefinitionId, origin: $origin, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, mode: $mode, model: $model, reasoningEffort: $reasoningEffort, permissionMode: $permissionMode, serviceTier: $serviceTier, parentSessionId: $parentSessionId, taskName: $taskName, agentPath: $agentPath, rootSessionId: $rootSessionId, lifecycle: $lifecycle, activeTurnId: $activeTurnId, lastError: $lastError, contextTokens: $contextTokens, contextWindow: $contextWindow)';
}


}

/// @nodoc
abstract mixin class _$SessionDtoCopyWith<$Res> implements $SessionDtoCopyWith<$Res> {
  factory _$SessionDtoCopyWith(_SessionDto value, $Res Function(_SessionDto) _then) = __$SessionDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String worktreeId, String title, String agentDefinitionId, SessionOrigin origin, SessionStatus status, DateTime createdAt, DateTime updatedAt, SessionMode mode, SessionModelSelectionDto? model, String? reasoningEffort, PermissionMode? permissionMode, String? serviceTier, String? parentSessionId, String? taskName, String? agentPath, String? rootSessionId, AgentLifecycle? lifecycle, String? activeTurnId, String? lastError, int contextTokens, int? contextWindow
});


@override $SessionModelSelectionDtoCopyWith<$Res>? get model;

}
/// @nodoc
class __$SessionDtoCopyWithImpl<$Res>
    implements _$SessionDtoCopyWith<$Res> {
  __$SessionDtoCopyWithImpl(this._self, this._then);

  final _SessionDto _self;
  final $Res Function(_SessionDto) _then;

/// Create a copy of SessionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? worktreeId = null,Object? title = null,Object? agentDefinitionId = null,Object? origin = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,Object? mode = null,Object? model = freezed,Object? reasoningEffort = freezed,Object? permissionMode = freezed,Object? serviceTier = freezed,Object? parentSessionId = freezed,Object? taskName = freezed,Object? agentPath = freezed,Object? rootSessionId = freezed,Object? lifecycle = freezed,Object? activeTurnId = freezed,Object? lastError = freezed,Object? contextTokens = null,Object? contextWindow = freezed,}) {
  return _then(_SessionDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,worktreeId: null == worktreeId ? _self.worktreeId : worktreeId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,agentDefinitionId: null == agentDefinitionId ? _self.agentDefinitionId : agentDefinitionId // ignore: cast_nullable_to_non_nullable
as String,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as SessionOrigin,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as SessionMode,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as SessionModelSelectionDto?,reasoningEffort: freezed == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as String?,permissionMode: freezed == permissionMode ? _self.permissionMode : permissionMode // ignore: cast_nullable_to_non_nullable
as PermissionMode?,serviceTier: freezed == serviceTier ? _self.serviceTier : serviceTier // ignore: cast_nullable_to_non_nullable
as String?,parentSessionId: freezed == parentSessionId ? _self.parentSessionId : parentSessionId // ignore: cast_nullable_to_non_nullable
as String?,taskName: freezed == taskName ? _self.taskName : taskName // ignore: cast_nullable_to_non_nullable
as String?,agentPath: freezed == agentPath ? _self.agentPath : agentPath // ignore: cast_nullable_to_non_nullable
as String?,rootSessionId: freezed == rootSessionId ? _self.rootSessionId : rootSessionId // ignore: cast_nullable_to_non_nullable
as String?,lifecycle: freezed == lifecycle ? _self.lifecycle : lifecycle // ignore: cast_nullable_to_non_nullable
as AgentLifecycle?,activeTurnId: freezed == activeTurnId ? _self.activeTurnId : activeTurnId // ignore: cast_nullable_to_non_nullable
as String?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,contextTokens: null == contextTokens ? _self.contextTokens : contextTokens // ignore: cast_nullable_to_non_nullable
as int,contextWindow: freezed == contextWindow ? _self.contextWindow : contextWindow // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of SessionDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionModelSelectionDtoCopyWith<$Res>? get model {
    if (_self.model == null) {
    return null;
  }

  return $SessionModelSelectionDtoCopyWith<$Res>(_self.model!, (value) {
    return _then(_self.copyWith(model: value));
  });
}
}


/// @nodoc
mixin _$AgentMailboxMessageDto {

 String get id;/// Recipient session.
 String get sessionId; String get senderPath; String get recipientPath; InterAgentMessageType get type; String get payload; DateTime get createdAt;/// Sender session; null when the daemon itself authored the message.
 String? get senderSessionId;/// When the message was folded into a recipient turn; null while queued.
 DateTime? get deliveredAt;
/// Create a copy of AgentMailboxMessageDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentMailboxMessageDtoCopyWith<AgentMailboxMessageDto> get copyWith => _$AgentMailboxMessageDtoCopyWithImpl<AgentMailboxMessageDto>(this as AgentMailboxMessageDto, _$identity);

  /// Serializes this AgentMailboxMessageDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentMailboxMessageDto&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.senderPath, senderPath) || other.senderPath == senderPath)&&(identical(other.recipientPath, recipientPath) || other.recipientPath == recipientPath)&&(identical(other.type, type) || other.type == type)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.senderSessionId, senderSessionId) || other.senderSessionId == senderSessionId)&&(identical(other.deliveredAt, deliveredAt) || other.deliveredAt == deliveredAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,senderPath,recipientPath,type,payload,createdAt,senderSessionId,deliveredAt);

@override
String toString() {
  return 'AgentMailboxMessageDto(id: $id, sessionId: $sessionId, senderPath: $senderPath, recipientPath: $recipientPath, type: $type, payload: $payload, createdAt: $createdAt, senderSessionId: $senderSessionId, deliveredAt: $deliveredAt)';
}


}

/// @nodoc
abstract mixin class $AgentMailboxMessageDtoCopyWith<$Res>  {
  factory $AgentMailboxMessageDtoCopyWith(AgentMailboxMessageDto value, $Res Function(AgentMailboxMessageDto) _then) = _$AgentMailboxMessageDtoCopyWithImpl;
@useResult
$Res call({
 String id, String sessionId, String senderPath, String recipientPath, InterAgentMessageType type, String payload, DateTime createdAt, String? senderSessionId, DateTime? deliveredAt
});




}
/// @nodoc
class _$AgentMailboxMessageDtoCopyWithImpl<$Res>
    implements $AgentMailboxMessageDtoCopyWith<$Res> {
  _$AgentMailboxMessageDtoCopyWithImpl(this._self, this._then);

  final AgentMailboxMessageDto _self;
  final $Res Function(AgentMailboxMessageDto) _then;

/// Create a copy of AgentMailboxMessageDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? senderPath = null,Object? recipientPath = null,Object? type = null,Object? payload = null,Object? createdAt = null,Object? senderSessionId = freezed,Object? deliveredAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,senderPath: null == senderPath ? _self.senderPath : senderPath // ignore: cast_nullable_to_non_nullable
as String,recipientPath: null == recipientPath ? _self.recipientPath : recipientPath // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as InterAgentMessageType,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,senderSessionId: freezed == senderSessionId ? _self.senderSessionId : senderSessionId // ignore: cast_nullable_to_non_nullable
as String?,deliveredAt: freezed == deliveredAt ? _self.deliveredAt : deliveredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentMailboxMessageDto].
extension AgentMailboxMessageDtoPatterns on AgentMailboxMessageDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentMailboxMessageDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentMailboxMessageDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentMailboxMessageDto value)  $default,){
final _that = this;
switch (_that) {
case _AgentMailboxMessageDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentMailboxMessageDto value)?  $default,){
final _that = this;
switch (_that) {
case _AgentMailboxMessageDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sessionId,  String senderPath,  String recipientPath,  InterAgentMessageType type,  String payload,  DateTime createdAt,  String? senderSessionId,  DateTime? deliveredAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentMailboxMessageDto() when $default != null:
return $default(_that.id,_that.sessionId,_that.senderPath,_that.recipientPath,_that.type,_that.payload,_that.createdAt,_that.senderSessionId,_that.deliveredAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sessionId,  String senderPath,  String recipientPath,  InterAgentMessageType type,  String payload,  DateTime createdAt,  String? senderSessionId,  DateTime? deliveredAt)  $default,) {final _that = this;
switch (_that) {
case _AgentMailboxMessageDto():
return $default(_that.id,_that.sessionId,_that.senderPath,_that.recipientPath,_that.type,_that.payload,_that.createdAt,_that.senderSessionId,_that.deliveredAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sessionId,  String senderPath,  String recipientPath,  InterAgentMessageType type,  String payload,  DateTime createdAt,  String? senderSessionId,  DateTime? deliveredAt)?  $default,) {final _that = this;
switch (_that) {
case _AgentMailboxMessageDto() when $default != null:
return $default(_that.id,_that.sessionId,_that.senderPath,_that.recipientPath,_that.type,_that.payload,_that.createdAt,_that.senderSessionId,_that.deliveredAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentMailboxMessageDto implements AgentMailboxMessageDto {
  const _AgentMailboxMessageDto({required this.id, required this.sessionId, required this.senderPath, required this.recipientPath, required this.type, required this.payload, required this.createdAt, this.senderSessionId, this.deliveredAt});
  factory _AgentMailboxMessageDto.fromJson(Map<String, dynamic> json) => _$AgentMailboxMessageDtoFromJson(json);

@override final  String id;
/// Recipient session.
@override final  String sessionId;
@override final  String senderPath;
@override final  String recipientPath;
@override final  InterAgentMessageType type;
@override final  String payload;
@override final  DateTime createdAt;
/// Sender session; null when the daemon itself authored the message.
@override final  String? senderSessionId;
/// When the message was folded into a recipient turn; null while queued.
@override final  DateTime? deliveredAt;

/// Create a copy of AgentMailboxMessageDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentMailboxMessageDtoCopyWith<_AgentMailboxMessageDto> get copyWith => __$AgentMailboxMessageDtoCopyWithImpl<_AgentMailboxMessageDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentMailboxMessageDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentMailboxMessageDto&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.senderPath, senderPath) || other.senderPath == senderPath)&&(identical(other.recipientPath, recipientPath) || other.recipientPath == recipientPath)&&(identical(other.type, type) || other.type == type)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.senderSessionId, senderSessionId) || other.senderSessionId == senderSessionId)&&(identical(other.deliveredAt, deliveredAt) || other.deliveredAt == deliveredAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,senderPath,recipientPath,type,payload,createdAt,senderSessionId,deliveredAt);

@override
String toString() {
  return 'AgentMailboxMessageDto(id: $id, sessionId: $sessionId, senderPath: $senderPath, recipientPath: $recipientPath, type: $type, payload: $payload, createdAt: $createdAt, senderSessionId: $senderSessionId, deliveredAt: $deliveredAt)';
}


}

/// @nodoc
abstract mixin class _$AgentMailboxMessageDtoCopyWith<$Res> implements $AgentMailboxMessageDtoCopyWith<$Res> {
  factory _$AgentMailboxMessageDtoCopyWith(_AgentMailboxMessageDto value, $Res Function(_AgentMailboxMessageDto) _then) = __$AgentMailboxMessageDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String sessionId, String senderPath, String recipientPath, InterAgentMessageType type, String payload, DateTime createdAt, String? senderSessionId, DateTime? deliveredAt
});




}
/// @nodoc
class __$AgentMailboxMessageDtoCopyWithImpl<$Res>
    implements _$AgentMailboxMessageDtoCopyWith<$Res> {
  __$AgentMailboxMessageDtoCopyWithImpl(this._self, this._then);

  final _AgentMailboxMessageDto _self;
  final $Res Function(_AgentMailboxMessageDto) _then;

/// Create a copy of AgentMailboxMessageDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? senderPath = null,Object? recipientPath = null,Object? type = null,Object? payload = null,Object? createdAt = null,Object? senderSessionId = freezed,Object? deliveredAt = freezed,}) {
  return _then(_AgentMailboxMessageDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,senderPath: null == senderPath ? _self.senderPath : senderPath // ignore: cast_nullable_to_non_nullable
as String,recipientPath: null == recipientPath ? _self.recipientPath : recipientPath // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as InterAgentMessageType,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,senderSessionId: freezed == senderSessionId ? _self.senderSessionId : senderSessionId // ignore: cast_nullable_to_non_nullable
as String?,deliveredAt: freezed == deliveredAt ? _self.deliveredAt : deliveredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ModelCapabilitiesDto {

 CapabilitySupport get streaming; CapabilitySupport get toolCalling; CapabilitySupport get reasoningEffort; CapabilitySupport get imageInput; CapabilitySupport get fileInput; CapabilitySupport get serviceTier; List<String> get supportedReasoningEfforts; List<String> get supportedServiceTiers; CapabilitySource get source;
/// Create a copy of ModelCapabilitiesDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelCapabilitiesDtoCopyWith<ModelCapabilitiesDto> get copyWith => _$ModelCapabilitiesDtoCopyWithImpl<ModelCapabilitiesDto>(this as ModelCapabilitiesDto, _$identity);

  /// Serializes this ModelCapabilitiesDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelCapabilitiesDto&&(identical(other.streaming, streaming) || other.streaming == streaming)&&(identical(other.toolCalling, toolCalling) || other.toolCalling == toolCalling)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort)&&(identical(other.imageInput, imageInput) || other.imageInput == imageInput)&&(identical(other.fileInput, fileInput) || other.fileInput == fileInput)&&(identical(other.serviceTier, serviceTier) || other.serviceTier == serviceTier)&&const DeepCollectionEquality().equals(other.supportedReasoningEfforts, supportedReasoningEfforts)&&const DeepCollectionEquality().equals(other.supportedServiceTiers, supportedServiceTiers)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streaming,toolCalling,reasoningEffort,imageInput,fileInput,serviceTier,const DeepCollectionEquality().hash(supportedReasoningEfforts),const DeepCollectionEquality().hash(supportedServiceTiers),source);

@override
String toString() {
  return 'ModelCapabilitiesDto(streaming: $streaming, toolCalling: $toolCalling, reasoningEffort: $reasoningEffort, imageInput: $imageInput, fileInput: $fileInput, serviceTier: $serviceTier, supportedReasoningEfforts: $supportedReasoningEfforts, supportedServiceTiers: $supportedServiceTiers, source: $source)';
}


}

/// @nodoc
abstract mixin class $ModelCapabilitiesDtoCopyWith<$Res>  {
  factory $ModelCapabilitiesDtoCopyWith(ModelCapabilitiesDto value, $Res Function(ModelCapabilitiesDto) _then) = _$ModelCapabilitiesDtoCopyWithImpl;
@useResult
$Res call({
 CapabilitySupport streaming, CapabilitySupport toolCalling, CapabilitySupport reasoningEffort, CapabilitySupport imageInput, CapabilitySupport fileInput, CapabilitySupport serviceTier, List<String> supportedReasoningEfforts, List<String> supportedServiceTiers, CapabilitySource source
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
@pragma('vm:prefer-inline') @override $Res call({Object? streaming = null,Object? toolCalling = null,Object? reasoningEffort = null,Object? imageInput = null,Object? fileInput = null,Object? serviceTier = null,Object? supportedReasoningEfforts = null,Object? supportedServiceTiers = null,Object? source = null,}) {
  return _then(_self.copyWith(
streaming: null == streaming ? _self.streaming : streaming // ignore: cast_nullable_to_non_nullable
as CapabilitySupport,toolCalling: null == toolCalling ? _self.toolCalling : toolCalling // ignore: cast_nullable_to_non_nullable
as CapabilitySupport,reasoningEffort: null == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as CapabilitySupport,imageInput: null == imageInput ? _self.imageInput : imageInput // ignore: cast_nullable_to_non_nullable
as CapabilitySupport,fileInput: null == fileInput ? _self.fileInput : fileInput // ignore: cast_nullable_to_non_nullable
as CapabilitySupport,serviceTier: null == serviceTier ? _self.serviceTier : serviceTier // ignore: cast_nullable_to_non_nullable
as CapabilitySupport,supportedReasoningEfforts: null == supportedReasoningEfforts ? _self.supportedReasoningEfforts : supportedReasoningEfforts // ignore: cast_nullable_to_non_nullable
as List<String>,supportedServiceTiers: null == supportedServiceTiers ? _self.supportedServiceTiers : supportedServiceTiers // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CapabilitySupport streaming,  CapabilitySupport toolCalling,  CapabilitySupport reasoningEffort,  CapabilitySupport imageInput,  CapabilitySupport fileInput,  CapabilitySupport serviceTier,  List<String> supportedReasoningEfforts,  List<String> supportedServiceTiers,  CapabilitySource source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModelCapabilitiesDto() when $default != null:
return $default(_that.streaming,_that.toolCalling,_that.reasoningEffort,_that.imageInput,_that.fileInput,_that.serviceTier,_that.supportedReasoningEfforts,_that.supportedServiceTiers,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CapabilitySupport streaming,  CapabilitySupport toolCalling,  CapabilitySupport reasoningEffort,  CapabilitySupport imageInput,  CapabilitySupport fileInput,  CapabilitySupport serviceTier,  List<String> supportedReasoningEfforts,  List<String> supportedServiceTiers,  CapabilitySource source)  $default,) {final _that = this;
switch (_that) {
case _ModelCapabilitiesDto():
return $default(_that.streaming,_that.toolCalling,_that.reasoningEffort,_that.imageInput,_that.fileInput,_that.serviceTier,_that.supportedReasoningEfforts,_that.supportedServiceTiers,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CapabilitySupport streaming,  CapabilitySupport toolCalling,  CapabilitySupport reasoningEffort,  CapabilitySupport imageInput,  CapabilitySupport fileInput,  CapabilitySupport serviceTier,  List<String> supportedReasoningEfforts,  List<String> supportedServiceTiers,  CapabilitySource source)?  $default,) {final _that = this;
switch (_that) {
case _ModelCapabilitiesDto() when $default != null:
return $default(_that.streaming,_that.toolCalling,_that.reasoningEffort,_that.imageInput,_that.fileInput,_that.serviceTier,_that.supportedReasoningEfforts,_that.supportedServiceTiers,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModelCapabilitiesDto implements ModelCapabilitiesDto {
  const _ModelCapabilitiesDto({this.streaming = CapabilitySupport.unknown, this.toolCalling = CapabilitySupport.unknown, this.reasoningEffort = CapabilitySupport.unknown, this.imageInput = CapabilitySupport.unknown, this.fileInput = CapabilitySupport.unknown, this.serviceTier = CapabilitySupport.unknown, final  List<String> supportedReasoningEfforts = const <String>[], final  List<String> supportedServiceTiers = const <String>[], this.source = CapabilitySource.unknown}): _supportedReasoningEfforts = supportedReasoningEfforts,_supportedServiceTiers = supportedServiceTiers;
  factory _ModelCapabilitiesDto.fromJson(Map<String, dynamic> json) => _$ModelCapabilitiesDtoFromJson(json);

@override@JsonKey() final  CapabilitySupport streaming;
@override@JsonKey() final  CapabilitySupport toolCalling;
@override@JsonKey() final  CapabilitySupport reasoningEffort;
@override@JsonKey() final  CapabilitySupport imageInput;
@override@JsonKey() final  CapabilitySupport fileInput;
@override@JsonKey() final  CapabilitySupport serviceTier;
 final  List<String> _supportedReasoningEfforts;
@override@JsonKey() List<String> get supportedReasoningEfforts {
  if (_supportedReasoningEfforts is EqualUnmodifiableListView) return _supportedReasoningEfforts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_supportedReasoningEfforts);
}

 final  List<String> _supportedServiceTiers;
@override@JsonKey() List<String> get supportedServiceTiers {
  if (_supportedServiceTiers is EqualUnmodifiableListView) return _supportedServiceTiers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_supportedServiceTiers);
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModelCapabilitiesDto&&(identical(other.streaming, streaming) || other.streaming == streaming)&&(identical(other.toolCalling, toolCalling) || other.toolCalling == toolCalling)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort)&&(identical(other.imageInput, imageInput) || other.imageInput == imageInput)&&(identical(other.fileInput, fileInput) || other.fileInput == fileInput)&&(identical(other.serviceTier, serviceTier) || other.serviceTier == serviceTier)&&const DeepCollectionEquality().equals(other._supportedReasoningEfforts, _supportedReasoningEfforts)&&const DeepCollectionEquality().equals(other._supportedServiceTiers, _supportedServiceTiers)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streaming,toolCalling,reasoningEffort,imageInput,fileInput,serviceTier,const DeepCollectionEquality().hash(_supportedReasoningEfforts),const DeepCollectionEquality().hash(_supportedServiceTiers),source);

@override
String toString() {
  return 'ModelCapabilitiesDto(streaming: $streaming, toolCalling: $toolCalling, reasoningEffort: $reasoningEffort, imageInput: $imageInput, fileInput: $fileInput, serviceTier: $serviceTier, supportedReasoningEfforts: $supportedReasoningEfforts, supportedServiceTiers: $supportedServiceTiers, source: $source)';
}


}

/// @nodoc
abstract mixin class _$ModelCapabilitiesDtoCopyWith<$Res> implements $ModelCapabilitiesDtoCopyWith<$Res> {
  factory _$ModelCapabilitiesDtoCopyWith(_ModelCapabilitiesDto value, $Res Function(_ModelCapabilitiesDto) _then) = __$ModelCapabilitiesDtoCopyWithImpl;
@override @useResult
$Res call({
 CapabilitySupport streaming, CapabilitySupport toolCalling, CapabilitySupport reasoningEffort, CapabilitySupport imageInput, CapabilitySupport fileInput, CapabilitySupport serviceTier, List<String> supportedReasoningEfforts, List<String> supportedServiceTiers, CapabilitySource source
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
@override @pragma('vm:prefer-inline') $Res call({Object? streaming = null,Object? toolCalling = null,Object? reasoningEffort = null,Object? imageInput = null,Object? fileInput = null,Object? serviceTier = null,Object? supportedReasoningEfforts = null,Object? supportedServiceTiers = null,Object? source = null,}) {
  return _then(_ModelCapabilitiesDto(
streaming: null == streaming ? _self.streaming : streaming // ignore: cast_nullable_to_non_nullable
as CapabilitySupport,toolCalling: null == toolCalling ? _self.toolCalling : toolCalling // ignore: cast_nullable_to_non_nullable
as CapabilitySupport,reasoningEffort: null == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as CapabilitySupport,imageInput: null == imageInput ? _self.imageInput : imageInput // ignore: cast_nullable_to_non_nullable
as CapabilitySupport,fileInput: null == fileInput ? _self.fileInput : fileInput // ignore: cast_nullable_to_non_nullable
as CapabilitySupport,serviceTier: null == serviceTier ? _self.serviceTier : serviceTier // ignore: cast_nullable_to_non_nullable
as CapabilitySupport,supportedReasoningEfforts: null == supportedReasoningEfforts ? _self._supportedReasoningEfforts : supportedReasoningEfforts // ignore: cast_nullable_to_non_nullable
as List<String>,supportedServiceTiers: null == supportedServiceTiers ? _self._supportedServiceTiers : supportedServiceTiers // ignore: cast_nullable_to_non_nullable
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

 String get id; String get definitionId; String get displayName; ProviderConnectionStatus get status; ProviderAuthKind get authKind; ProviderCredentialOrigin get credentialOrigin; DateTime get createdAt; DateTime get updatedAt; String? get error; CustomProviderConfigDto? get customConfig;
/// Create a copy of ProviderConnectionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderConnectionDtoCopyWith<ProviderConnectionDto> get copyWith => _$ProviderConnectionDtoCopyWithImpl<ProviderConnectionDto>(this as ProviderConnectionDto, _$identity);

  /// Serializes this ProviderConnectionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderConnectionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.definitionId, definitionId) || other.definitionId == definitionId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.status, status) || other.status == status)&&(identical(other.authKind, authKind) || other.authKind == authKind)&&(identical(other.credentialOrigin, credentialOrigin) || other.credentialOrigin == credentialOrigin)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.error, error) || other.error == error)&&(identical(other.customConfig, customConfig) || other.customConfig == customConfig));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,definitionId,displayName,status,authKind,credentialOrigin,createdAt,updatedAt,error,customConfig);

@override
String toString() {
  return 'ProviderConnectionDto(id: $id, definitionId: $definitionId, displayName: $displayName, status: $status, authKind: $authKind, credentialOrigin: $credentialOrigin, createdAt: $createdAt, updatedAt: $updatedAt, error: $error, customConfig: $customConfig)';
}


}

/// @nodoc
abstract mixin class $ProviderConnectionDtoCopyWith<$Res>  {
  factory $ProviderConnectionDtoCopyWith(ProviderConnectionDto value, $Res Function(ProviderConnectionDto) _then) = _$ProviderConnectionDtoCopyWithImpl;
@useResult
$Res call({
 String id, String definitionId, String displayName, ProviderConnectionStatus status, ProviderAuthKind authKind, ProviderCredentialOrigin credentialOrigin, DateTime createdAt, DateTime updatedAt, String? error, CustomProviderConfigDto? customConfig
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? definitionId = null,Object? displayName = null,Object? status = null,Object? authKind = null,Object? credentialOrigin = null,Object? createdAt = null,Object? updatedAt = null,Object? error = freezed,Object? customConfig = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,definitionId: null == definitionId ? _self.definitionId : definitionId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProviderConnectionStatus,authKind: null == authKind ? _self.authKind : authKind // ignore: cast_nullable_to_non_nullable
as ProviderAuthKind,credentialOrigin: null == credentialOrigin ? _self.credentialOrigin : credentialOrigin // ignore: cast_nullable_to_non_nullable
as ProviderCredentialOrigin,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String definitionId,  String displayName,  ProviderConnectionStatus status,  ProviderAuthKind authKind,  ProviderCredentialOrigin credentialOrigin,  DateTime createdAt,  DateTime updatedAt,  String? error,  CustomProviderConfigDto? customConfig)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderConnectionDto() when $default != null:
return $default(_that.id,_that.definitionId,_that.displayName,_that.status,_that.authKind,_that.credentialOrigin,_that.createdAt,_that.updatedAt,_that.error,_that.customConfig);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String definitionId,  String displayName,  ProviderConnectionStatus status,  ProviderAuthKind authKind,  ProviderCredentialOrigin credentialOrigin,  DateTime createdAt,  DateTime updatedAt,  String? error,  CustomProviderConfigDto? customConfig)  $default,) {final _that = this;
switch (_that) {
case _ProviderConnectionDto():
return $default(_that.id,_that.definitionId,_that.displayName,_that.status,_that.authKind,_that.credentialOrigin,_that.createdAt,_that.updatedAt,_that.error,_that.customConfig);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String definitionId,  String displayName,  ProviderConnectionStatus status,  ProviderAuthKind authKind,  ProviderCredentialOrigin credentialOrigin,  DateTime createdAt,  DateTime updatedAt,  String? error,  CustomProviderConfigDto? customConfig)?  $default,) {final _that = this;
switch (_that) {
case _ProviderConnectionDto() when $default != null:
return $default(_that.id,_that.definitionId,_that.displayName,_that.status,_that.authKind,_that.credentialOrigin,_that.createdAt,_that.updatedAt,_that.error,_that.customConfig);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderConnectionDto implements ProviderConnectionDto {
  const _ProviderConnectionDto({required this.id, required this.definitionId, required this.displayName, required this.status, required this.authKind, required this.credentialOrigin, required this.createdAt, required this.updatedAt, this.error, this.customConfig});
  factory _ProviderConnectionDto.fromJson(Map<String, dynamic> json) => _$ProviderConnectionDtoFromJson(json);

@override final  String id;
@override final  String definitionId;
@override final  String displayName;
@override final  ProviderConnectionStatus status;
@override final  ProviderAuthKind authKind;
@override final  ProviderCredentialOrigin credentialOrigin;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderConnectionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.definitionId, definitionId) || other.definitionId == definitionId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.status, status) || other.status == status)&&(identical(other.authKind, authKind) || other.authKind == authKind)&&(identical(other.credentialOrigin, credentialOrigin) || other.credentialOrigin == credentialOrigin)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.error, error) || other.error == error)&&(identical(other.customConfig, customConfig) || other.customConfig == customConfig));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,definitionId,displayName,status,authKind,credentialOrigin,createdAt,updatedAt,error,customConfig);

@override
String toString() {
  return 'ProviderConnectionDto(id: $id, definitionId: $definitionId, displayName: $displayName, status: $status, authKind: $authKind, credentialOrigin: $credentialOrigin, createdAt: $createdAt, updatedAt: $updatedAt, error: $error, customConfig: $customConfig)';
}


}

/// @nodoc
abstract mixin class _$ProviderConnectionDtoCopyWith<$Res> implements $ProviderConnectionDtoCopyWith<$Res> {
  factory _$ProviderConnectionDtoCopyWith(_ProviderConnectionDto value, $Res Function(_ProviderConnectionDto) _then) = __$ProviderConnectionDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String definitionId, String displayName, ProviderConnectionStatus status, ProviderAuthKind authKind, ProviderCredentialOrigin credentialOrigin, DateTime createdAt, DateTime updatedAt, String? error, CustomProviderConfigDto? customConfig
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? definitionId = null,Object? displayName = null,Object? status = null,Object? authKind = null,Object? credentialOrigin = null,Object? createdAt = null,Object? updatedAt = null,Object? error = freezed,Object? customConfig = freezed,}) {
  return _then(_ProviderConnectionDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,definitionId: null == definitionId ? _self.definitionId : definitionId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProviderConnectionStatus,authKind: null == authKind ? _self.authKind : authKind // ignore: cast_nullable_to_non_nullable
as ProviderAuthKind,credentialOrigin: null == credentialOrigin ? _self.credentialOrigin : credentialOrigin // ignore: cast_nullable_to_non_nullable
as ProviderCredentialOrigin,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
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

 String get sessionId; int get sequence; String get type; Map<String, dynamic> get data; DateTime get createdAt; String? get turnId;
/// Create a copy of TimelineEventDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimelineEventDtoCopyWith<TimelineEventDto> get copyWith => _$TimelineEventDtoCopyWithImpl<TimelineEventDto>(this as TimelineEventDto, _$identity);

  /// Serializes this TimelineEventDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimelineEventDto&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.sequence, sequence) || other.sequence == sequence)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.turnId, turnId) || other.turnId == turnId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,sequence,type,const DeepCollectionEquality().hash(data),createdAt,turnId);

@override
String toString() {
  return 'TimelineEventDto(sessionId: $sessionId, sequence: $sequence, type: $type, data: $data, createdAt: $createdAt, turnId: $turnId)';
}


}

/// @nodoc
abstract mixin class $TimelineEventDtoCopyWith<$Res>  {
  factory $TimelineEventDtoCopyWith(TimelineEventDto value, $Res Function(TimelineEventDto) _then) = _$TimelineEventDtoCopyWithImpl;
@useResult
$Res call({
 String sessionId, int sequence, String type, Map<String, dynamic> data, DateTime createdAt, String? turnId
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
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? sequence = null,Object? type = null,Object? data = null,Object? createdAt = null,Object? turnId = freezed,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  int sequence,  String type,  Map<String, dynamic> data,  DateTime createdAt,  String? turnId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimelineEventDto() when $default != null:
return $default(_that.sessionId,_that.sequence,_that.type,_that.data,_that.createdAt,_that.turnId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  int sequence,  String type,  Map<String, dynamic> data,  DateTime createdAt,  String? turnId)  $default,) {final _that = this;
switch (_that) {
case _TimelineEventDto():
return $default(_that.sessionId,_that.sequence,_that.type,_that.data,_that.createdAt,_that.turnId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  int sequence,  String type,  Map<String, dynamic> data,  DateTime createdAt,  String? turnId)?  $default,) {final _that = this;
switch (_that) {
case _TimelineEventDto() when $default != null:
return $default(_that.sessionId,_that.sequence,_that.type,_that.data,_that.createdAt,_that.turnId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TimelineEventDto implements TimelineEventDto {
  const _TimelineEventDto({required this.sessionId, required this.sequence, required this.type, required final  Map<String, dynamic> data, required this.createdAt, this.turnId}): _data = data;
  factory _TimelineEventDto.fromJson(Map<String, dynamic> json) => _$TimelineEventDtoFromJson(json);

@override final  String sessionId;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimelineEventDto&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.sequence, sequence) || other.sequence == sequence)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._data, _data)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.turnId, turnId) || other.turnId == turnId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,sequence,type,const DeepCollectionEquality().hash(_data),createdAt,turnId);

@override
String toString() {
  return 'TimelineEventDto(sessionId: $sessionId, sequence: $sequence, type: $type, data: $data, createdAt: $createdAt, turnId: $turnId)';
}


}

/// @nodoc
abstract mixin class _$TimelineEventDtoCopyWith<$Res> implements $TimelineEventDtoCopyWith<$Res> {
  factory _$TimelineEventDtoCopyWith(_TimelineEventDto value, $Res Function(_TimelineEventDto) _then) = __$TimelineEventDtoCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, int sequence, String type, Map<String, dynamic> data, DateTime createdAt, String? turnId
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
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? sequence = null,Object? type = null,Object? data = null,Object? createdAt = null,Object? turnId = freezed,}) {
  return _then(_TimelineEventDto(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
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

 String get id; String get sessionId; String get turnId; String get toolCallId; String get toolName; ToolRisk get risk; Map<String, dynamic> get arguments; ApprovalStatus get status; DateTime get createdAt; String? get preview;
/// Create a copy of ApprovalRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApprovalRequestDtoCopyWith<ApprovalRequestDto> get copyWith => _$ApprovalRequestDtoCopyWithImpl<ApprovalRequestDto>(this as ApprovalRequestDto, _$identity);

  /// Serializes this ApprovalRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApprovalRequestDto&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.risk, risk) || other.risk == risk)&&const DeepCollectionEquality().equals(other.arguments, arguments)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.preview, preview) || other.preview == preview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,turnId,toolCallId,toolName,risk,const DeepCollectionEquality().hash(arguments),status,createdAt,preview);

@override
String toString() {
  return 'ApprovalRequestDto(id: $id, sessionId: $sessionId, turnId: $turnId, toolCallId: $toolCallId, toolName: $toolName, risk: $risk, arguments: $arguments, status: $status, createdAt: $createdAt, preview: $preview)';
}


}

/// @nodoc
abstract mixin class $ApprovalRequestDtoCopyWith<$Res>  {
  factory $ApprovalRequestDtoCopyWith(ApprovalRequestDto value, $Res Function(ApprovalRequestDto) _then) = _$ApprovalRequestDtoCopyWithImpl;
@useResult
$Res call({
 String id, String sessionId, String turnId, String toolCallId, String toolName, ToolRisk risk, Map<String, dynamic> arguments, ApprovalStatus status, DateTime createdAt, String? preview
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? turnId = null,Object? toolCallId = null,Object? toolName = null,Object? risk = null,Object? arguments = null,Object? status = null,Object? createdAt = null,Object? preview = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sessionId,  String turnId,  String toolCallId,  String toolName,  ToolRisk risk,  Map<String, dynamic> arguments,  ApprovalStatus status,  DateTime createdAt,  String? preview)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApprovalRequestDto() when $default != null:
return $default(_that.id,_that.sessionId,_that.turnId,_that.toolCallId,_that.toolName,_that.risk,_that.arguments,_that.status,_that.createdAt,_that.preview);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sessionId,  String turnId,  String toolCallId,  String toolName,  ToolRisk risk,  Map<String, dynamic> arguments,  ApprovalStatus status,  DateTime createdAt,  String? preview)  $default,) {final _that = this;
switch (_that) {
case _ApprovalRequestDto():
return $default(_that.id,_that.sessionId,_that.turnId,_that.toolCallId,_that.toolName,_that.risk,_that.arguments,_that.status,_that.createdAt,_that.preview);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sessionId,  String turnId,  String toolCallId,  String toolName,  ToolRisk risk,  Map<String, dynamic> arguments,  ApprovalStatus status,  DateTime createdAt,  String? preview)?  $default,) {final _that = this;
switch (_that) {
case _ApprovalRequestDto() when $default != null:
return $default(_that.id,_that.sessionId,_that.turnId,_that.toolCallId,_that.toolName,_that.risk,_that.arguments,_that.status,_that.createdAt,_that.preview);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApprovalRequestDto implements ApprovalRequestDto {
  const _ApprovalRequestDto({required this.id, required this.sessionId, required this.turnId, required this.toolCallId, required this.toolName, required this.risk, required final  Map<String, dynamic> arguments, required this.status, required this.createdAt, this.preview}): _arguments = arguments;
  factory _ApprovalRequestDto.fromJson(Map<String, dynamic> json) => _$ApprovalRequestDtoFromJson(json);

@override final  String id;
@override final  String sessionId;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApprovalRequestDto&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.risk, risk) || other.risk == risk)&&const DeepCollectionEquality().equals(other._arguments, _arguments)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.preview, preview) || other.preview == preview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,turnId,toolCallId,toolName,risk,const DeepCollectionEquality().hash(_arguments),status,createdAt,preview);

@override
String toString() {
  return 'ApprovalRequestDto(id: $id, sessionId: $sessionId, turnId: $turnId, toolCallId: $toolCallId, toolName: $toolName, risk: $risk, arguments: $arguments, status: $status, createdAt: $createdAt, preview: $preview)';
}


}

/// @nodoc
abstract mixin class _$ApprovalRequestDtoCopyWith<$Res> implements $ApprovalRequestDtoCopyWith<$Res> {
  factory _$ApprovalRequestDtoCopyWith(_ApprovalRequestDto value, $Res Function(_ApprovalRequestDto) _then) = __$ApprovalRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String sessionId, String turnId, String toolCallId, String toolName, ToolRisk risk, Map<String, dynamic> arguments, ApprovalStatus status, DateTime createdAt, String? preview
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? turnId = null,Object? toolCallId = null,Object? toolName = null,Object? risk = null,Object? arguments = null,Object? status = null,Object? createdAt = null,Object? preview = freezed,}) {
  return _then(_ApprovalRequestDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
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
mixin _$UserQuestionOptionDto {

 String get label; String get description;
/// Create a copy of UserQuestionOptionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserQuestionOptionDtoCopyWith<UserQuestionOptionDto> get copyWith => _$UserQuestionOptionDtoCopyWithImpl<UserQuestionOptionDto>(this as UserQuestionOptionDto, _$identity);

  /// Serializes this UserQuestionOptionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserQuestionOptionDto&&(identical(other.label, label) || other.label == label)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,description);

@override
String toString() {
  return 'UserQuestionOptionDto(label: $label, description: $description)';
}


}

/// @nodoc
abstract mixin class $UserQuestionOptionDtoCopyWith<$Res>  {
  factory $UserQuestionOptionDtoCopyWith(UserQuestionOptionDto value, $Res Function(UserQuestionOptionDto) _then) = _$UserQuestionOptionDtoCopyWithImpl;
@useResult
$Res call({
 String label, String description
});




}
/// @nodoc
class _$UserQuestionOptionDtoCopyWithImpl<$Res>
    implements $UserQuestionOptionDtoCopyWith<$Res> {
  _$UserQuestionOptionDtoCopyWithImpl(this._self, this._then);

  final UserQuestionOptionDto _self;
  final $Res Function(UserQuestionOptionDto) _then;

/// Create a copy of UserQuestionOptionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? description = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UserQuestionOptionDto].
extension UserQuestionOptionDtoPatterns on UserQuestionOptionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserQuestionOptionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserQuestionOptionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserQuestionOptionDto value)  $default,){
final _that = this;
switch (_that) {
case _UserQuestionOptionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserQuestionOptionDto value)?  $default,){
final _that = this;
switch (_that) {
case _UserQuestionOptionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserQuestionOptionDto() when $default != null:
return $default(_that.label,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String description)  $default,) {final _that = this;
switch (_that) {
case _UserQuestionOptionDto():
return $default(_that.label,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String description)?  $default,) {final _that = this;
switch (_that) {
case _UserQuestionOptionDto() when $default != null:
return $default(_that.label,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserQuestionOptionDto implements UserQuestionOptionDto {
  const _UserQuestionOptionDto({required this.label, required this.description});
  factory _UserQuestionOptionDto.fromJson(Map<String, dynamic> json) => _$UserQuestionOptionDtoFromJson(json);

@override final  String label;
@override final  String description;

/// Create a copy of UserQuestionOptionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserQuestionOptionDtoCopyWith<_UserQuestionOptionDto> get copyWith => __$UserQuestionOptionDtoCopyWithImpl<_UserQuestionOptionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserQuestionOptionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserQuestionOptionDto&&(identical(other.label, label) || other.label == label)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,description);

@override
String toString() {
  return 'UserQuestionOptionDto(label: $label, description: $description)';
}


}

/// @nodoc
abstract mixin class _$UserQuestionOptionDtoCopyWith<$Res> implements $UserQuestionOptionDtoCopyWith<$Res> {
  factory _$UserQuestionOptionDtoCopyWith(_UserQuestionOptionDto value, $Res Function(_UserQuestionOptionDto) _then) = __$UserQuestionOptionDtoCopyWithImpl;
@override @useResult
$Res call({
 String label, String description
});




}
/// @nodoc
class __$UserQuestionOptionDtoCopyWithImpl<$Res>
    implements _$UserQuestionOptionDtoCopyWith<$Res> {
  __$UserQuestionOptionDtoCopyWithImpl(this._self, this._then);

  final _UserQuestionOptionDto _self;
  final $Res Function(_UserQuestionOptionDto) _then;

/// Create a copy of UserQuestionOptionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? description = null,}) {
  return _then(_UserQuestionOptionDto(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$UserQuestionItemDto {

 String get id; String get header; String get question; List<UserQuestionOptionDto> get options;
/// Create a copy of UserQuestionItemDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserQuestionItemDtoCopyWith<UserQuestionItemDto> get copyWith => _$UserQuestionItemDtoCopyWithImpl<UserQuestionItemDto>(this as UserQuestionItemDto, _$identity);

  /// Serializes this UserQuestionItemDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserQuestionItemDto&&(identical(other.id, id) || other.id == id)&&(identical(other.header, header) || other.header == header)&&(identical(other.question, question) || other.question == question)&&const DeepCollectionEquality().equals(other.options, options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,header,question,const DeepCollectionEquality().hash(options));

@override
String toString() {
  return 'UserQuestionItemDto(id: $id, header: $header, question: $question, options: $options)';
}


}

/// @nodoc
abstract mixin class $UserQuestionItemDtoCopyWith<$Res>  {
  factory $UserQuestionItemDtoCopyWith(UserQuestionItemDto value, $Res Function(UserQuestionItemDto) _then) = _$UserQuestionItemDtoCopyWithImpl;
@useResult
$Res call({
 String id, String header, String question, List<UserQuestionOptionDto> options
});




}
/// @nodoc
class _$UserQuestionItemDtoCopyWithImpl<$Res>
    implements $UserQuestionItemDtoCopyWith<$Res> {
  _$UserQuestionItemDtoCopyWithImpl(this._self, this._then);

  final UserQuestionItemDto _self;
  final $Res Function(UserQuestionItemDto) _then;

/// Create a copy of UserQuestionItemDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? header = null,Object? question = null,Object? options = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,header: null == header ? _self.header : header // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<UserQuestionOptionDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [UserQuestionItemDto].
extension UserQuestionItemDtoPatterns on UserQuestionItemDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserQuestionItemDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserQuestionItemDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserQuestionItemDto value)  $default,){
final _that = this;
switch (_that) {
case _UserQuestionItemDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserQuestionItemDto value)?  $default,){
final _that = this;
switch (_that) {
case _UserQuestionItemDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String header,  String question,  List<UserQuestionOptionDto> options)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserQuestionItemDto() when $default != null:
return $default(_that.id,_that.header,_that.question,_that.options);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String header,  String question,  List<UserQuestionOptionDto> options)  $default,) {final _that = this;
switch (_that) {
case _UserQuestionItemDto():
return $default(_that.id,_that.header,_that.question,_that.options);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String header,  String question,  List<UserQuestionOptionDto> options)?  $default,) {final _that = this;
switch (_that) {
case _UserQuestionItemDto() when $default != null:
return $default(_that.id,_that.header,_that.question,_that.options);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserQuestionItemDto implements UserQuestionItemDto {
  const _UserQuestionItemDto({required this.id, required this.header, required this.question, required final  List<UserQuestionOptionDto> options}): _options = options;
  factory _UserQuestionItemDto.fromJson(Map<String, dynamic> json) => _$UserQuestionItemDtoFromJson(json);

@override final  String id;
@override final  String header;
@override final  String question;
 final  List<UserQuestionOptionDto> _options;
@override List<UserQuestionOptionDto> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}


/// Create a copy of UserQuestionItemDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserQuestionItemDtoCopyWith<_UserQuestionItemDto> get copyWith => __$UserQuestionItemDtoCopyWithImpl<_UserQuestionItemDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserQuestionItemDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserQuestionItemDto&&(identical(other.id, id) || other.id == id)&&(identical(other.header, header) || other.header == header)&&(identical(other.question, question) || other.question == question)&&const DeepCollectionEquality().equals(other._options, _options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,header,question,const DeepCollectionEquality().hash(_options));

@override
String toString() {
  return 'UserQuestionItemDto(id: $id, header: $header, question: $question, options: $options)';
}


}

/// @nodoc
abstract mixin class _$UserQuestionItemDtoCopyWith<$Res> implements $UserQuestionItemDtoCopyWith<$Res> {
  factory _$UserQuestionItemDtoCopyWith(_UserQuestionItemDto value, $Res Function(_UserQuestionItemDto) _then) = __$UserQuestionItemDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String header, String question, List<UserQuestionOptionDto> options
});




}
/// @nodoc
class __$UserQuestionItemDtoCopyWithImpl<$Res>
    implements _$UserQuestionItemDtoCopyWith<$Res> {
  __$UserQuestionItemDtoCopyWithImpl(this._self, this._then);

  final _UserQuestionItemDto _self;
  final $Res Function(_UserQuestionItemDto) _then;

/// Create a copy of UserQuestionItemDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? header = null,Object? question = null,Object? options = null,}) {
  return _then(_UserQuestionItemDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,header: null == header ? _self.header : header // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<UserQuestionOptionDto>,
  ));
}


}


/// @nodoc
mixin _$UserQuestionAnswerDto {

 String get questionId; String get answer; bool get isFreeForm;
/// Create a copy of UserQuestionAnswerDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserQuestionAnswerDtoCopyWith<UserQuestionAnswerDto> get copyWith => _$UserQuestionAnswerDtoCopyWithImpl<UserQuestionAnswerDto>(this as UserQuestionAnswerDto, _$identity);

  /// Serializes this UserQuestionAnswerDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserQuestionAnswerDto&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.answer, answer) || other.answer == answer)&&(identical(other.isFreeForm, isFreeForm) || other.isFreeForm == isFreeForm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,questionId,answer,isFreeForm);

@override
String toString() {
  return 'UserQuestionAnswerDto(questionId: $questionId, answer: $answer, isFreeForm: $isFreeForm)';
}


}

/// @nodoc
abstract mixin class $UserQuestionAnswerDtoCopyWith<$Res>  {
  factory $UserQuestionAnswerDtoCopyWith(UserQuestionAnswerDto value, $Res Function(UserQuestionAnswerDto) _then) = _$UserQuestionAnswerDtoCopyWithImpl;
@useResult
$Res call({
 String questionId, String answer, bool isFreeForm
});




}
/// @nodoc
class _$UserQuestionAnswerDtoCopyWithImpl<$Res>
    implements $UserQuestionAnswerDtoCopyWith<$Res> {
  _$UserQuestionAnswerDtoCopyWithImpl(this._self, this._then);

  final UserQuestionAnswerDto _self;
  final $Res Function(UserQuestionAnswerDto) _then;

/// Create a copy of UserQuestionAnswerDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? questionId = null,Object? answer = null,Object? isFreeForm = null,}) {
  return _then(_self.copyWith(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String,isFreeForm: null == isFreeForm ? _self.isFreeForm : isFreeForm // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserQuestionAnswerDto].
extension UserQuestionAnswerDtoPatterns on UserQuestionAnswerDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserQuestionAnswerDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserQuestionAnswerDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserQuestionAnswerDto value)  $default,){
final _that = this;
switch (_that) {
case _UserQuestionAnswerDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserQuestionAnswerDto value)?  $default,){
final _that = this;
switch (_that) {
case _UserQuestionAnswerDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String questionId,  String answer,  bool isFreeForm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserQuestionAnswerDto() when $default != null:
return $default(_that.questionId,_that.answer,_that.isFreeForm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String questionId,  String answer,  bool isFreeForm)  $default,) {final _that = this;
switch (_that) {
case _UserQuestionAnswerDto():
return $default(_that.questionId,_that.answer,_that.isFreeForm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String questionId,  String answer,  bool isFreeForm)?  $default,) {final _that = this;
switch (_that) {
case _UserQuestionAnswerDto() when $default != null:
return $default(_that.questionId,_that.answer,_that.isFreeForm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserQuestionAnswerDto implements UserQuestionAnswerDto {
  const _UserQuestionAnswerDto({required this.questionId, required this.answer, required this.isFreeForm});
  factory _UserQuestionAnswerDto.fromJson(Map<String, dynamic> json) => _$UserQuestionAnswerDtoFromJson(json);

@override final  String questionId;
@override final  String answer;
@override final  bool isFreeForm;

/// Create a copy of UserQuestionAnswerDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserQuestionAnswerDtoCopyWith<_UserQuestionAnswerDto> get copyWith => __$UserQuestionAnswerDtoCopyWithImpl<_UserQuestionAnswerDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserQuestionAnswerDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserQuestionAnswerDto&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.answer, answer) || other.answer == answer)&&(identical(other.isFreeForm, isFreeForm) || other.isFreeForm == isFreeForm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,questionId,answer,isFreeForm);

@override
String toString() {
  return 'UserQuestionAnswerDto(questionId: $questionId, answer: $answer, isFreeForm: $isFreeForm)';
}


}

/// @nodoc
abstract mixin class _$UserQuestionAnswerDtoCopyWith<$Res> implements $UserQuestionAnswerDtoCopyWith<$Res> {
  factory _$UserQuestionAnswerDtoCopyWith(_UserQuestionAnswerDto value, $Res Function(_UserQuestionAnswerDto) _then) = __$UserQuestionAnswerDtoCopyWithImpl;
@override @useResult
$Res call({
 String questionId, String answer, bool isFreeForm
});




}
/// @nodoc
class __$UserQuestionAnswerDtoCopyWithImpl<$Res>
    implements _$UserQuestionAnswerDtoCopyWith<$Res> {
  __$UserQuestionAnswerDtoCopyWithImpl(this._self, this._then);

  final _UserQuestionAnswerDto _self;
  final $Res Function(_UserQuestionAnswerDto) _then;

/// Create a copy of UserQuestionAnswerDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? questionId = null,Object? answer = null,Object? isFreeForm = null,}) {
  return _then(_UserQuestionAnswerDto(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String,isFreeForm: null == isFreeForm ? _self.isFreeForm : isFreeForm // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$UserQuestionRequestDto {

 String get id; String get sessionId; String get turnId; String get toolCallId; List<UserQuestionItemDto> get questions; UserQuestionStatus get status; DateTime get createdAt; List<UserQuestionAnswerDto> get answers;
/// Create a copy of UserQuestionRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserQuestionRequestDtoCopyWith<UserQuestionRequestDto> get copyWith => _$UserQuestionRequestDtoCopyWithImpl<UserQuestionRequestDto>(this as UserQuestionRequestDto, _$identity);

  /// Serializes this UserQuestionRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserQuestionRequestDto&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&const DeepCollectionEquality().equals(other.questions, questions)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.answers, answers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,turnId,toolCallId,const DeepCollectionEquality().hash(questions),status,createdAt,const DeepCollectionEquality().hash(answers));

@override
String toString() {
  return 'UserQuestionRequestDto(id: $id, sessionId: $sessionId, turnId: $turnId, toolCallId: $toolCallId, questions: $questions, status: $status, createdAt: $createdAt, answers: $answers)';
}


}

/// @nodoc
abstract mixin class $UserQuestionRequestDtoCopyWith<$Res>  {
  factory $UserQuestionRequestDtoCopyWith(UserQuestionRequestDto value, $Res Function(UserQuestionRequestDto) _then) = _$UserQuestionRequestDtoCopyWithImpl;
@useResult
$Res call({
 String id, String sessionId, String turnId, String toolCallId, List<UserQuestionItemDto> questions, UserQuestionStatus status, DateTime createdAt, List<UserQuestionAnswerDto> answers
});




}
/// @nodoc
class _$UserQuestionRequestDtoCopyWithImpl<$Res>
    implements $UserQuestionRequestDtoCopyWith<$Res> {
  _$UserQuestionRequestDtoCopyWithImpl(this._self, this._then);

  final UserQuestionRequestDto _self;
  final $Res Function(UserQuestionRequestDto) _then;

/// Create a copy of UserQuestionRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? turnId = null,Object? toolCallId = null,Object? questions = null,Object? status = null,Object? createdAt = null,Object? answers = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as List<UserQuestionItemDto>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UserQuestionStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,answers: null == answers ? _self.answers : answers // ignore: cast_nullable_to_non_nullable
as List<UserQuestionAnswerDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [UserQuestionRequestDto].
extension UserQuestionRequestDtoPatterns on UserQuestionRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserQuestionRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserQuestionRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserQuestionRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _UserQuestionRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserQuestionRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _UserQuestionRequestDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sessionId,  String turnId,  String toolCallId,  List<UserQuestionItemDto> questions,  UserQuestionStatus status,  DateTime createdAt,  List<UserQuestionAnswerDto> answers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserQuestionRequestDto() when $default != null:
return $default(_that.id,_that.sessionId,_that.turnId,_that.toolCallId,_that.questions,_that.status,_that.createdAt,_that.answers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sessionId,  String turnId,  String toolCallId,  List<UserQuestionItemDto> questions,  UserQuestionStatus status,  DateTime createdAt,  List<UserQuestionAnswerDto> answers)  $default,) {final _that = this;
switch (_that) {
case _UserQuestionRequestDto():
return $default(_that.id,_that.sessionId,_that.turnId,_that.toolCallId,_that.questions,_that.status,_that.createdAt,_that.answers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sessionId,  String turnId,  String toolCallId,  List<UserQuestionItemDto> questions,  UserQuestionStatus status,  DateTime createdAt,  List<UserQuestionAnswerDto> answers)?  $default,) {final _that = this;
switch (_that) {
case _UserQuestionRequestDto() when $default != null:
return $default(_that.id,_that.sessionId,_that.turnId,_that.toolCallId,_that.questions,_that.status,_that.createdAt,_that.answers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserQuestionRequestDto implements UserQuestionRequestDto {
  const _UserQuestionRequestDto({required this.id, required this.sessionId, required this.turnId, required this.toolCallId, required final  List<UserQuestionItemDto> questions, required this.status, required this.createdAt, final  List<UserQuestionAnswerDto> answers = const <UserQuestionAnswerDto>[]}): _questions = questions,_answers = answers;
  factory _UserQuestionRequestDto.fromJson(Map<String, dynamic> json) => _$UserQuestionRequestDtoFromJson(json);

@override final  String id;
@override final  String sessionId;
@override final  String turnId;
@override final  String toolCallId;
 final  List<UserQuestionItemDto> _questions;
@override List<UserQuestionItemDto> get questions {
  if (_questions is EqualUnmodifiableListView) return _questions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_questions);
}

@override final  UserQuestionStatus status;
@override final  DateTime createdAt;
 final  List<UserQuestionAnswerDto> _answers;
@override@JsonKey() List<UserQuestionAnswerDto> get answers {
  if (_answers is EqualUnmodifiableListView) return _answers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_answers);
}


/// Create a copy of UserQuestionRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserQuestionRequestDtoCopyWith<_UserQuestionRequestDto> get copyWith => __$UserQuestionRequestDtoCopyWithImpl<_UserQuestionRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserQuestionRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserQuestionRequestDto&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&const DeepCollectionEquality().equals(other._questions, _questions)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._answers, _answers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,turnId,toolCallId,const DeepCollectionEquality().hash(_questions),status,createdAt,const DeepCollectionEquality().hash(_answers));

@override
String toString() {
  return 'UserQuestionRequestDto(id: $id, sessionId: $sessionId, turnId: $turnId, toolCallId: $toolCallId, questions: $questions, status: $status, createdAt: $createdAt, answers: $answers)';
}


}

/// @nodoc
abstract mixin class _$UserQuestionRequestDtoCopyWith<$Res> implements $UserQuestionRequestDtoCopyWith<$Res> {
  factory _$UserQuestionRequestDtoCopyWith(_UserQuestionRequestDto value, $Res Function(_UserQuestionRequestDto) _then) = __$UserQuestionRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String sessionId, String turnId, String toolCallId, List<UserQuestionItemDto> questions, UserQuestionStatus status, DateTime createdAt, List<UserQuestionAnswerDto> answers
});




}
/// @nodoc
class __$UserQuestionRequestDtoCopyWithImpl<$Res>
    implements _$UserQuestionRequestDtoCopyWith<$Res> {
  __$UserQuestionRequestDtoCopyWithImpl(this._self, this._then);

  final _UserQuestionRequestDto _self;
  final $Res Function(_UserQuestionRequestDto) _then;

/// Create a copy of UserQuestionRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? turnId = null,Object? toolCallId = null,Object? questions = null,Object? status = null,Object? createdAt = null,Object? answers = null,}) {
  return _then(_UserQuestionRequestDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,questions: null == questions ? _self._questions : questions // ignore: cast_nullable_to_non_nullable
as List<UserQuestionItemDto>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UserQuestionStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,answers: null == answers ? _self._answers : answers // ignore: cast_nullable_to_non_nullable
as List<UserQuestionAnswerDto>,
  ));
}


}


/// @nodoc
mixin _$ServerInfoDto {

 String get serverId; String get version; int get protocolVersion; Map<String, bool> get features; String? get homeDirectory;
/// Create a copy of ServerInfoDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerInfoDtoCopyWith<ServerInfoDto> get copyWith => _$ServerInfoDtoCopyWithImpl<ServerInfoDto>(this as ServerInfoDto, _$identity);

  /// Serializes this ServerInfoDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerInfoDto&&(identical(other.serverId, serverId) || other.serverId == serverId)&&(identical(other.version, version) || other.version == version)&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&const DeepCollectionEquality().equals(other.features, features)&&(identical(other.homeDirectory, homeDirectory) || other.homeDirectory == homeDirectory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverId,version,protocolVersion,const DeepCollectionEquality().hash(features),homeDirectory);

@override
String toString() {
  return 'ServerInfoDto(serverId: $serverId, version: $version, protocolVersion: $protocolVersion, features: $features, homeDirectory: $homeDirectory)';
}


}

/// @nodoc
abstract mixin class $ServerInfoDtoCopyWith<$Res>  {
  factory $ServerInfoDtoCopyWith(ServerInfoDto value, $Res Function(ServerInfoDto) _then) = _$ServerInfoDtoCopyWithImpl;
@useResult
$Res call({
 String serverId, String version, int protocolVersion, Map<String, bool> features, String? homeDirectory
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
@pragma('vm:prefer-inline') @override $Res call({Object? serverId = null,Object? version = null,Object? protocolVersion = null,Object? features = null,Object? homeDirectory = freezed,}) {
  return _then(_self.copyWith(
serverId: null == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,protocolVersion: null == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as int,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,homeDirectory: freezed == homeDirectory ? _self.homeDirectory : homeDirectory // ignore: cast_nullable_to_non_nullable
as String?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String serverId,  String version,  int protocolVersion,  Map<String, bool> features,  String? homeDirectory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServerInfoDto() when $default != null:
return $default(_that.serverId,_that.version,_that.protocolVersion,_that.features,_that.homeDirectory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String serverId,  String version,  int protocolVersion,  Map<String, bool> features,  String? homeDirectory)  $default,) {final _that = this;
switch (_that) {
case _ServerInfoDto():
return $default(_that.serverId,_that.version,_that.protocolVersion,_that.features,_that.homeDirectory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String serverId,  String version,  int protocolVersion,  Map<String, bool> features,  String? homeDirectory)?  $default,) {final _that = this;
switch (_that) {
case _ServerInfoDto() when $default != null:
return $default(_that.serverId,_that.version,_that.protocolVersion,_that.features,_that.homeDirectory);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServerInfoDto implements ServerInfoDto {
  const _ServerInfoDto({required this.serverId, required this.version, required this.protocolVersion, required final  Map<String, bool> features, this.homeDirectory}): _features = features;
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

@override final  String? homeDirectory;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServerInfoDto&&(identical(other.serverId, serverId) || other.serverId == serverId)&&(identical(other.version, version) || other.version == version)&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&const DeepCollectionEquality().equals(other._features, _features)&&(identical(other.homeDirectory, homeDirectory) || other.homeDirectory == homeDirectory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverId,version,protocolVersion,const DeepCollectionEquality().hash(_features),homeDirectory);

@override
String toString() {
  return 'ServerInfoDto(serverId: $serverId, version: $version, protocolVersion: $protocolVersion, features: $features, homeDirectory: $homeDirectory)';
}


}

/// @nodoc
abstract mixin class _$ServerInfoDtoCopyWith<$Res> implements $ServerInfoDtoCopyWith<$Res> {
  factory _$ServerInfoDtoCopyWith(_ServerInfoDto value, $Res Function(_ServerInfoDto) _then) = __$ServerInfoDtoCopyWithImpl;
@override @useResult
$Res call({
 String serverId, String version, int protocolVersion, Map<String, bool> features, String? homeDirectory
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
@override @pragma('vm:prefer-inline') $Res call({Object? serverId = null,Object? version = null,Object? protocolVersion = null,Object? features = null,Object? homeDirectory = freezed,}) {
  return _then(_ServerInfoDto(
serverId: null == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,protocolVersion: null == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as int,features: null == features ? _self._features : features // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,homeDirectory: freezed == homeDirectory ? _self.homeDirectory : homeDirectory // ignore: cast_nullable_to_non_nullable
as String?,
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
