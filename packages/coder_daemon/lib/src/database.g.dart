// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $WorkspacesTable extends Workspaces
    with TableInfo<$WorkspacesTable, Workspace> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkspacesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _rootPathMeta = const VerificationMeta(
    'rootPath',
  );
  @override
  late final GeneratedColumn<String> rootPath = GeneratedColumn<String>(
    'root_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [id, name, rootPath, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspaces';
  @override
  VerificationContext validateIntegrity(
    Insertable<Workspace> instance, {
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
    if (data.containsKey('root_path')) {
      context.handle(
        _rootPathMeta,
        rootPath.isAcceptableOrUnknown(data['root_path']!, _rootPathMeta),
      );
    } else if (isInserting) {
      context.missing(_rootPathMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Workspace map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Workspace(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      rootPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root_path'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WorkspacesTable createAlias(String alias) {
    return $WorkspacesTable(attachedDatabase, alias);
  }
}

class Workspace extends DataClass implements Insertable<Workspace> {
  /// The id public API member.
  final String id;

  /// The name public API member.
  final String name;

  /// The rootPath public API member.
  final String rootPath;

  /// The createdAt public API member.
  final DateTime createdAt;
  const Workspace({
    required this.id,
    required this.name,
    required this.rootPath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['root_path'] = Variable<String>(rootPath);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WorkspacesCompanion toCompanion(bool nullToAbsent) {
    return WorkspacesCompanion(
      id: Value(id),
      name: Value(name),
      rootPath: Value(rootPath),
      createdAt: Value(createdAt),
    );
  }

  factory Workspace.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Workspace(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      rootPath: serializer.fromJson<String>(json['rootPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'rootPath': serializer.toJson<String>(rootPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Workspace copyWith({
    String? id,
    String? name,
    String? rootPath,
    DateTime? createdAt,
  }) => Workspace(
    id: id ?? this.id,
    name: name ?? this.name,
    rootPath: rootPath ?? this.rootPath,
    createdAt: createdAt ?? this.createdAt,
  );
  Workspace copyWithCompanion(WorkspacesCompanion data) {
    return Workspace(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      rootPath: data.rootPath.present ? data.rootPath.value : this.rootPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Workspace(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rootPath: $rootPath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, rootPath, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Workspace &&
          other.id == this.id &&
          other.name == this.name &&
          other.rootPath == this.rootPath &&
          other.createdAt == this.createdAt);
}

class WorkspacesCompanion extends UpdateCompanion<Workspace> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> rootPath;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const WorkspacesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rootPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspacesCompanion.insert({
    required String id,
    required String name,
    required String rootPath,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       rootPath = Value(rootPath),
       createdAt = Value(createdAt);
  static Insertable<Workspace> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? rootPath,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rootPath != null) 'root_path': rootPath,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspacesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? rootPath,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return WorkspacesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rootPath: rootPath ?? this.rootPath,
      createdAt: createdAt ?? this.createdAt,
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
    if (rootPath.present) {
      map['root_path'] = Variable<String>(rootPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspacesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rootPath: $rootPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AgentsTable extends Agents with TableInfo<$AgentsTable, Agent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id)',
    ),
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
  static const VerificationMeta _providerConnectionIdMeta =
      const VerificationMeta('providerConnectionId');
  @override
  late final GeneratedColumn<String> providerConnectionId =
      GeneratedColumn<String>(
        'provider_connection_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasoningEffortMeta = const VerificationMeta(
    'reasoningEffort',
  );
  @override
  late final GeneratedColumn<String> reasoningEffort = GeneratedColumn<String>(
    'reasoning_effort',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _permissionModeMeta = const VerificationMeta(
    'permissionMode',
  );
  @override
  late final GeneratedColumn<String> permissionMode = GeneratedColumn<String>(
    'permission_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeTurnIdMeta = const VerificationMeta(
    'activeTurnId',
  );
  @override
  late final GeneratedColumn<String> activeTurnId = GeneratedColumn<String>(
    'active_turn_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    title,
    providerConnectionId,
    model,
    reasoningEffort,
    status,
    permissionMode,
    activeTurnId,
    lastError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agents';
  @override
  VerificationContext validateIntegrity(
    Insertable<Agent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('provider_connection_id')) {
      context.handle(
        _providerConnectionIdMeta,
        providerConnectionId.isAcceptableOrUnknown(
          data['provider_connection_id']!,
          _providerConnectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerConnectionIdMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('reasoning_effort')) {
      context.handle(
        _reasoningEffortMeta,
        reasoningEffort.isAcceptableOrUnknown(
          data['reasoning_effort']!,
          _reasoningEffortMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('permission_mode')) {
      context.handle(
        _permissionModeMeta,
        permissionMode.isAcceptableOrUnknown(
          data['permission_mode']!,
          _permissionModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_permissionModeMeta);
    }
    if (data.containsKey('active_turn_id')) {
      context.handle(
        _activeTurnIdMeta,
        activeTurnId.isAcceptableOrUnknown(
          data['active_turn_id']!,
          _activeTurnIdMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
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
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Agent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Agent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      providerConnectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_connection_id'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      reasoningEffort: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reasoning_effort'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      permissionMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permission_mode'],
      )!,
      activeTurnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_turn_id'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AgentsTable createAlias(String alias) {
    return $AgentsTable(attachedDatabase, alias);
  }
}

class Agent extends DataClass implements Insertable<Agent> {
  /// The id public API member.
  final String id;

  /// The workspaceId public API member.
  final String workspaceId;

  /// The title public API member.
  final String title;

  /// Provider connection selected for this agent.
  final String providerConnectionId;

  /// The model public API member.
  final String model;

  /// The reasoningEffort public API member.
  final String reasoningEffort;

  /// The status public API member.
  final String status;

  /// The permissionMode public API member.
  final String permissionMode;

  /// The activeTurnId public API member.
  final String? activeTurnId;

  /// The lastError public API member.
  final String? lastError;

  /// The createdAt public API member.
  final DateTime createdAt;

  /// The updatedAt public API member.
  final DateTime updatedAt;
  const Agent({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.providerConnectionId,
    required this.model,
    required this.reasoningEffort,
    required this.status,
    required this.permissionMode,
    this.activeTurnId,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['title'] = Variable<String>(title);
    map['provider_connection_id'] = Variable<String>(providerConnectionId);
    map['model'] = Variable<String>(model);
    map['reasoning_effort'] = Variable<String>(reasoningEffort);
    map['status'] = Variable<String>(status);
    map['permission_mode'] = Variable<String>(permissionMode);
    if (!nullToAbsent || activeTurnId != null) {
      map['active_turn_id'] = Variable<String>(activeTurnId);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AgentsCompanion toCompanion(bool nullToAbsent) {
    return AgentsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      title: Value(title),
      providerConnectionId: Value(providerConnectionId),
      model: Value(model),
      reasoningEffort: Value(reasoningEffort),
      status: Value(status),
      permissionMode: Value(permissionMode),
      activeTurnId: activeTurnId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeTurnId),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Agent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Agent(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      title: serializer.fromJson<String>(json['title']),
      providerConnectionId: serializer.fromJson<String>(
        json['providerConnectionId'],
      ),
      model: serializer.fromJson<String>(json['model']),
      reasoningEffort: serializer.fromJson<String>(json['reasoningEffort']),
      status: serializer.fromJson<String>(json['status']),
      permissionMode: serializer.fromJson<String>(json['permissionMode']),
      activeTurnId: serializer.fromJson<String?>(json['activeTurnId']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'title': serializer.toJson<String>(title),
      'providerConnectionId': serializer.toJson<String>(providerConnectionId),
      'model': serializer.toJson<String>(model),
      'reasoningEffort': serializer.toJson<String>(reasoningEffort),
      'status': serializer.toJson<String>(status),
      'permissionMode': serializer.toJson<String>(permissionMode),
      'activeTurnId': serializer.toJson<String?>(activeTurnId),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Agent copyWith({
    String? id,
    String? workspaceId,
    String? title,
    String? providerConnectionId,
    String? model,
    String? reasoningEffort,
    String? status,
    String? permissionMode,
    Value<String?> activeTurnId = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Agent(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    title: title ?? this.title,
    providerConnectionId: providerConnectionId ?? this.providerConnectionId,
    model: model ?? this.model,
    reasoningEffort: reasoningEffort ?? this.reasoningEffort,
    status: status ?? this.status,
    permissionMode: permissionMode ?? this.permissionMode,
    activeTurnId: activeTurnId.present ? activeTurnId.value : this.activeTurnId,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Agent copyWithCompanion(AgentsCompanion data) {
    return Agent(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      title: data.title.present ? data.title.value : this.title,
      providerConnectionId: data.providerConnectionId.present
          ? data.providerConnectionId.value
          : this.providerConnectionId,
      model: data.model.present ? data.model.value : this.model,
      reasoningEffort: data.reasoningEffort.present
          ? data.reasoningEffort.value
          : this.reasoningEffort,
      status: data.status.present ? data.status.value : this.status,
      permissionMode: data.permissionMode.present
          ? data.permissionMode.value
          : this.permissionMode,
      activeTurnId: data.activeTurnId.present
          ? data.activeTurnId.value
          : this.activeTurnId,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Agent(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('title: $title, ')
          ..write('providerConnectionId: $providerConnectionId, ')
          ..write('model: $model, ')
          ..write('reasoningEffort: $reasoningEffort, ')
          ..write('status: $status, ')
          ..write('permissionMode: $permissionMode, ')
          ..write('activeTurnId: $activeTurnId, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    title,
    providerConnectionId,
    model,
    reasoningEffort,
    status,
    permissionMode,
    activeTurnId,
    lastError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Agent &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.title == this.title &&
          other.providerConnectionId == this.providerConnectionId &&
          other.model == this.model &&
          other.reasoningEffort == this.reasoningEffort &&
          other.status == this.status &&
          other.permissionMode == this.permissionMode &&
          other.activeTurnId == this.activeTurnId &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AgentsCompanion extends UpdateCompanion<Agent> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> title;
  final Value<String> providerConnectionId;
  final Value<String> model;
  final Value<String> reasoningEffort;
  final Value<String> status;
  final Value<String> permissionMode;
  final Value<String?> activeTurnId;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AgentsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.title = const Value.absent(),
    this.providerConnectionId = const Value.absent(),
    this.model = const Value.absent(),
    this.reasoningEffort = const Value.absent(),
    this.status = const Value.absent(),
    this.permissionMode = const Value.absent(),
    this.activeTurnId = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentsCompanion.insert({
    required String id,
    required String workspaceId,
    required String title,
    required String providerConnectionId,
    required String model,
    this.reasoningEffort = const Value.absent(),
    required String status,
    required String permissionMode,
    this.activeTurnId = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       title = Value(title),
       providerConnectionId = Value(providerConnectionId),
       model = Value(model),
       status = Value(status),
       permissionMode = Value(permissionMode),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Agent> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? title,
    Expression<String>? providerConnectionId,
    Expression<String>? model,
    Expression<String>? reasoningEffort,
    Expression<String>? status,
    Expression<String>? permissionMode,
    Expression<String>? activeTurnId,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (title != null) 'title': title,
      if (providerConnectionId != null)
        'provider_connection_id': providerConnectionId,
      if (model != null) 'model': model,
      if (reasoningEffort != null) 'reasoning_effort': reasoningEffort,
      if (status != null) 'status': status,
      if (permissionMode != null) 'permission_mode': permissionMode,
      if (activeTurnId != null) 'active_turn_id': activeTurnId,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? title,
    Value<String>? providerConnectionId,
    Value<String>? model,
    Value<String>? reasoningEffort,
    Value<String>? status,
    Value<String>? permissionMode,
    Value<String?>? activeTurnId,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AgentsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      providerConnectionId: providerConnectionId ?? this.providerConnectionId,
      model: model ?? this.model,
      reasoningEffort: reasoningEffort ?? this.reasoningEffort,
      status: status ?? this.status,
      permissionMode: permissionMode ?? this.permissionMode,
      activeTurnId: activeTurnId ?? this.activeTurnId,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (providerConnectionId.present) {
      map['provider_connection_id'] = Variable<String>(
        providerConnectionId.value,
      );
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (reasoningEffort.present) {
      map['reasoning_effort'] = Variable<String>(reasoningEffort.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (permissionMode.present) {
      map['permission_mode'] = Variable<String>(permissionMode.value);
    }
    if (activeTurnId.present) {
      map['active_turn_id'] = Variable<String>(activeTurnId.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('title: $title, ')
          ..write('providerConnectionId: $providerConnectionId, ')
          ..write('model: $model, ')
          ..write('reasoningEffort: $reasoningEffort, ')
          ..write('status: $status, ')
          ..write('permissionMode: $permissionMode, ')
          ..write('activeTurnId: $activeTurnId, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TurnsTable extends Turns with TableInfo<$TurnsTable, Turn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TurnsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agentIdMeta = const VerificationMeta(
    'agentId',
  );
  @override
  late final GeneratedColumn<String> agentId = GeneratedColumn<String>(
    'agent_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES agents (id)',
    ),
  );
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
    'prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    agentId,
    prompt,
    status,
    error,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'turns';
  @override
  VerificationContext validateIntegrity(
    Insertable<Turn> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('agent_id')) {
      context.handle(
        _agentIdMeta,
        agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_agentIdMeta);
    }
    if (data.containsKey('prompt')) {
      context.handle(
        _promptMeta,
        prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta),
      );
    } else if (isInserting) {
      context.missing(_promptMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
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
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Turn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Turn(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      agentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_id'],
      )!,
      prompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TurnsTable createAlias(String alias) {
    return $TurnsTable(attachedDatabase, alias);
  }
}

class Turn extends DataClass implements Insertable<Turn> {
  /// The id public API member.
  final String id;

  /// The agentId public API member.
  final String agentId;

  /// The prompt public API member.
  final String prompt;

  /// The status public API member.
  final String status;

  /// The error public API member.
  final String? error;

  /// The createdAt public API member.
  final DateTime createdAt;

  /// The updatedAt public API member.
  final DateTime updatedAt;
  const Turn({
    required this.id,
    required this.agentId,
    required this.prompt,
    required this.status,
    this.error,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['agent_id'] = Variable<String>(agentId);
    map['prompt'] = Variable<String>(prompt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TurnsCompanion toCompanion(bool nullToAbsent) {
    return TurnsCompanion(
      id: Value(id),
      agentId: Value(agentId),
      prompt: Value(prompt),
      status: Value(status),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Turn.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Turn(
      id: serializer.fromJson<String>(json['id']),
      agentId: serializer.fromJson<String>(json['agentId']),
      prompt: serializer.fromJson<String>(json['prompt']),
      status: serializer.fromJson<String>(json['status']),
      error: serializer.fromJson<String?>(json['error']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'agentId': serializer.toJson<String>(agentId),
      'prompt': serializer.toJson<String>(prompt),
      'status': serializer.toJson<String>(status),
      'error': serializer.toJson<String?>(error),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Turn copyWith({
    String? id,
    String? agentId,
    String? prompt,
    String? status,
    Value<String?> error = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Turn(
    id: id ?? this.id,
    agentId: agentId ?? this.agentId,
    prompt: prompt ?? this.prompt,
    status: status ?? this.status,
    error: error.present ? error.value : this.error,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Turn copyWithCompanion(TurnsCompanion data) {
    return Turn(
      id: data.id.present ? data.id.value : this.id,
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      status: data.status.present ? data.status.value : this.status,
      error: data.error.present ? data.error.value : this.error,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Turn(')
          ..write('id: $id, ')
          ..write('agentId: $agentId, ')
          ..write('prompt: $prompt, ')
          ..write('status: $status, ')
          ..write('error: $error, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, agentId, prompt, status, error, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Turn &&
          other.id == this.id &&
          other.agentId == this.agentId &&
          other.prompt == this.prompt &&
          other.status == this.status &&
          other.error == this.error &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TurnsCompanion extends UpdateCompanion<Turn> {
  final Value<String> id;
  final Value<String> agentId;
  final Value<String> prompt;
  final Value<String> status;
  final Value<String?> error;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TurnsCompanion({
    this.id = const Value.absent(),
    this.agentId = const Value.absent(),
    this.prompt = const Value.absent(),
    this.status = const Value.absent(),
    this.error = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TurnsCompanion.insert({
    required String id,
    required String agentId,
    required String prompt,
    required String status,
    this.error = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       agentId = Value(agentId),
       prompt = Value(prompt),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Turn> custom({
    Expression<String>? id,
    Expression<String>? agentId,
    Expression<String>? prompt,
    Expression<String>? status,
    Expression<String>? error,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (agentId != null) 'agent_id': agentId,
      if (prompt != null) 'prompt': prompt,
      if (status != null) 'status': status,
      if (error != null) 'error': error,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TurnsCompanion copyWith({
    Value<String>? id,
    Value<String>? agentId,
    Value<String>? prompt,
    Value<String>? status,
    Value<String?>? error,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TurnsCompanion(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      prompt: prompt ?? this.prompt,
      status: status ?? this.status,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (agentId.present) {
      map['agent_id'] = Variable<String>(agentId.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TurnsCompanion(')
          ..write('id: $id, ')
          ..write('agentId: $agentId, ')
          ..write('prompt: $prompt, ')
          ..write('status: $status, ')
          ..write('error: $error, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimelineEventsTable extends TimelineEvents
    with TableInfo<$TimelineEventsTable, TimelineEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimelineEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _agentIdMeta = const VerificationMeta(
    'agentId',
  );
  @override
  late final GeneratedColumn<String> agentId = GeneratedColumn<String>(
    'agent_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES agents (id)',
    ),
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _turnIdMeta = const VerificationMeta('turnId');
  @override
  late final GeneratedColumn<String> turnId = GeneratedColumn<String>(
    'turn_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    agentId,
    sequence,
    turnId,
    type,
    dataJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timeline_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimelineEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('agent_id')) {
      context.handle(
        _agentIdMeta,
        agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_agentIdMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('turn_id')) {
      context.handle(
        _turnIdMeta,
        turnId.isAcceptableOrUnknown(data['turn_id']!, _turnIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {agentId, sequence};
  @override
  TimelineEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimelineEvent(
      agentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_id'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      turnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}turn_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TimelineEventsTable createAlias(String alias) {
    return $TimelineEventsTable(attachedDatabase, alias);
  }
}

class TimelineEvent extends DataClass implements Insertable<TimelineEvent> {
  /// The agentId public API member.
  final String agentId;

  /// The sequence public API member.
  final int sequence;

  /// The turnId public API member.
  final String? turnId;

  /// The type public API member.
  final String type;

  /// The dataJson public API member.
  final String dataJson;

  /// The createdAt public API member.
  final DateTime createdAt;
  const TimelineEvent({
    required this.agentId,
    required this.sequence,
    this.turnId,
    required this.type,
    required this.dataJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['agent_id'] = Variable<String>(agentId);
    map['sequence'] = Variable<int>(sequence);
    if (!nullToAbsent || turnId != null) {
      map['turn_id'] = Variable<String>(turnId);
    }
    map['type'] = Variable<String>(type);
    map['data_json'] = Variable<String>(dataJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TimelineEventsCompanion toCompanion(bool nullToAbsent) {
    return TimelineEventsCompanion(
      agentId: Value(agentId),
      sequence: Value(sequence),
      turnId: turnId == null && nullToAbsent
          ? const Value.absent()
          : Value(turnId),
      type: Value(type),
      dataJson: Value(dataJson),
      createdAt: Value(createdAt),
    );
  }

  factory TimelineEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimelineEvent(
      agentId: serializer.fromJson<String>(json['agentId']),
      sequence: serializer.fromJson<int>(json['sequence']),
      turnId: serializer.fromJson<String?>(json['turnId']),
      type: serializer.fromJson<String>(json['type']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'agentId': serializer.toJson<String>(agentId),
      'sequence': serializer.toJson<int>(sequence),
      'turnId': serializer.toJson<String?>(turnId),
      'type': serializer.toJson<String>(type),
      'dataJson': serializer.toJson<String>(dataJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TimelineEvent copyWith({
    String? agentId,
    int? sequence,
    Value<String?> turnId = const Value.absent(),
    String? type,
    String? dataJson,
    DateTime? createdAt,
  }) => TimelineEvent(
    agentId: agentId ?? this.agentId,
    sequence: sequence ?? this.sequence,
    turnId: turnId.present ? turnId.value : this.turnId,
    type: type ?? this.type,
    dataJson: dataJson ?? this.dataJson,
    createdAt: createdAt ?? this.createdAt,
  );
  TimelineEvent copyWithCompanion(TimelineEventsCompanion data) {
    return TimelineEvent(
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      turnId: data.turnId.present ? data.turnId.value : this.turnId,
      type: data.type.present ? data.type.value : this.type,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimelineEvent(')
          ..write('agentId: $agentId, ')
          ..write('sequence: $sequence, ')
          ..write('turnId: $turnId, ')
          ..write('type: $type, ')
          ..write('dataJson: $dataJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(agentId, sequence, turnId, type, dataJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimelineEvent &&
          other.agentId == this.agentId &&
          other.sequence == this.sequence &&
          other.turnId == this.turnId &&
          other.type == this.type &&
          other.dataJson == this.dataJson &&
          other.createdAt == this.createdAt);
}

class TimelineEventsCompanion extends UpdateCompanion<TimelineEvent> {
  final Value<String> agentId;
  final Value<int> sequence;
  final Value<String?> turnId;
  final Value<String> type;
  final Value<String> dataJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TimelineEventsCompanion({
    this.agentId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.turnId = const Value.absent(),
    this.type = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimelineEventsCompanion.insert({
    required String agentId,
    required int sequence,
    this.turnId = const Value.absent(),
    required String type,
    required String dataJson,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : agentId = Value(agentId),
       sequence = Value(sequence),
       type = Value(type),
       dataJson = Value(dataJson),
       createdAt = Value(createdAt);
  static Insertable<TimelineEvent> custom({
    Expression<String>? agentId,
    Expression<int>? sequence,
    Expression<String>? turnId,
    Expression<String>? type,
    Expression<String>? dataJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (agentId != null) 'agent_id': agentId,
      if (sequence != null) 'sequence': sequence,
      if (turnId != null) 'turn_id': turnId,
      if (type != null) 'type': type,
      if (dataJson != null) 'data_json': dataJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimelineEventsCompanion copyWith({
    Value<String>? agentId,
    Value<int>? sequence,
    Value<String?>? turnId,
    Value<String>? type,
    Value<String>? dataJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TimelineEventsCompanion(
      agentId: agentId ?? this.agentId,
      sequence: sequence ?? this.sequence,
      turnId: turnId ?? this.turnId,
      type: type ?? this.type,
      dataJson: dataJson ?? this.dataJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (agentId.present) {
      map['agent_id'] = Variable<String>(agentId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (turnId.present) {
      map['turn_id'] = Variable<String>(turnId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimelineEventsCompanion(')
          ..write('agentId: $agentId, ')
          ..write('sequence: $sequence, ')
          ..write('turnId: $turnId, ')
          ..write('type: $type, ')
          ..write('dataJson: $dataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ApprovalRequestsTable extends ApprovalRequests
    with TableInfo<$ApprovalRequestsTable, ApprovalRequest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApprovalRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agentIdMeta = const VerificationMeta(
    'agentId',
  );
  @override
  late final GeneratedColumn<String> agentId = GeneratedColumn<String>(
    'agent_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES agents (id)',
    ),
  );
  static const VerificationMeta _turnIdMeta = const VerificationMeta('turnId');
  @override
  late final GeneratedColumn<String> turnId = GeneratedColumn<String>(
    'turn_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES turns (id)',
    ),
  );
  static const VerificationMeta _toolCallIdMeta = const VerificationMeta(
    'toolCallId',
  );
  @override
  late final GeneratedColumn<String> toolCallId = GeneratedColumn<String>(
    'tool_call_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toolNameMeta = const VerificationMeta(
    'toolName',
  );
  @override
  late final GeneratedColumn<String> toolName = GeneratedColumn<String>(
    'tool_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _riskMeta = const VerificationMeta('risk');
  @override
  late final GeneratedColumn<String> risk = GeneratedColumn<String>(
    'risk',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _argumentsJsonMeta = const VerificationMeta(
    'argumentsJson',
  );
  @override
  late final GeneratedColumn<String> argumentsJson = GeneratedColumn<String>(
    'arguments_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previewMeta = const VerificationMeta(
    'preview',
  );
  @override
  late final GeneratedColumn<String> preview = GeneratedColumn<String>(
    'preview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    agentId,
    turnId,
    toolCallId,
    toolName,
    risk,
    argumentsJson,
    preview,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'approval_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<ApprovalRequest> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('agent_id')) {
      context.handle(
        _agentIdMeta,
        agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_agentIdMeta);
    }
    if (data.containsKey('turn_id')) {
      context.handle(
        _turnIdMeta,
        turnId.isAcceptableOrUnknown(data['turn_id']!, _turnIdMeta),
      );
    } else if (isInserting) {
      context.missing(_turnIdMeta);
    }
    if (data.containsKey('tool_call_id')) {
      context.handle(
        _toolCallIdMeta,
        toolCallId.isAcceptableOrUnknown(
          data['tool_call_id']!,
          _toolCallIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_toolCallIdMeta);
    }
    if (data.containsKey('tool_name')) {
      context.handle(
        _toolNameMeta,
        toolName.isAcceptableOrUnknown(data['tool_name']!, _toolNameMeta),
      );
    } else if (isInserting) {
      context.missing(_toolNameMeta);
    }
    if (data.containsKey('risk')) {
      context.handle(
        _riskMeta,
        risk.isAcceptableOrUnknown(data['risk']!, _riskMeta),
      );
    } else if (isInserting) {
      context.missing(_riskMeta);
    }
    if (data.containsKey('arguments_json')) {
      context.handle(
        _argumentsJsonMeta,
        argumentsJson.isAcceptableOrUnknown(
          data['arguments_json']!,
          _argumentsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_argumentsJsonMeta);
    }
    if (data.containsKey('preview')) {
      context.handle(
        _previewMeta,
        preview.isAcceptableOrUnknown(data['preview']!, _previewMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ApprovalRequest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApprovalRequest(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      agentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_id'],
      )!,
      turnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}turn_id'],
      )!,
      toolCallId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_call_id'],
      )!,
      toolName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_name'],
      )!,
      risk: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}risk'],
      )!,
      argumentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arguments_json'],
      )!,
      preview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preview'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ApprovalRequestsTable createAlias(String alias) {
    return $ApprovalRequestsTable(attachedDatabase, alias);
  }
}

class ApprovalRequest extends DataClass implements Insertable<ApprovalRequest> {
  /// The id public API member.
  final String id;

  /// The agentId public API member.
  final String agentId;

  /// The turnId public API member.
  final String turnId;

  /// The toolCallId public API member.
  final String toolCallId;

  /// The toolName public API member.
  final String toolName;

  /// The risk public API member.
  final String risk;

  /// The argumentsJson public API member.
  final String argumentsJson;

  /// The preview public API member.
  final String? preview;

  /// The status public API member.
  final String status;

  /// The createdAt public API member.
  final DateTime createdAt;
  const ApprovalRequest({
    required this.id,
    required this.agentId,
    required this.turnId,
    required this.toolCallId,
    required this.toolName,
    required this.risk,
    required this.argumentsJson,
    this.preview,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['agent_id'] = Variable<String>(agentId);
    map['turn_id'] = Variable<String>(turnId);
    map['tool_call_id'] = Variable<String>(toolCallId);
    map['tool_name'] = Variable<String>(toolName);
    map['risk'] = Variable<String>(risk);
    map['arguments_json'] = Variable<String>(argumentsJson);
    if (!nullToAbsent || preview != null) {
      map['preview'] = Variable<String>(preview);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ApprovalRequestsCompanion toCompanion(bool nullToAbsent) {
    return ApprovalRequestsCompanion(
      id: Value(id),
      agentId: Value(agentId),
      turnId: Value(turnId),
      toolCallId: Value(toolCallId),
      toolName: Value(toolName),
      risk: Value(risk),
      argumentsJson: Value(argumentsJson),
      preview: preview == null && nullToAbsent
          ? const Value.absent()
          : Value(preview),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory ApprovalRequest.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApprovalRequest(
      id: serializer.fromJson<String>(json['id']),
      agentId: serializer.fromJson<String>(json['agentId']),
      turnId: serializer.fromJson<String>(json['turnId']),
      toolCallId: serializer.fromJson<String>(json['toolCallId']),
      toolName: serializer.fromJson<String>(json['toolName']),
      risk: serializer.fromJson<String>(json['risk']),
      argumentsJson: serializer.fromJson<String>(json['argumentsJson']),
      preview: serializer.fromJson<String?>(json['preview']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'agentId': serializer.toJson<String>(agentId),
      'turnId': serializer.toJson<String>(turnId),
      'toolCallId': serializer.toJson<String>(toolCallId),
      'toolName': serializer.toJson<String>(toolName),
      'risk': serializer.toJson<String>(risk),
      'argumentsJson': serializer.toJson<String>(argumentsJson),
      'preview': serializer.toJson<String?>(preview),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ApprovalRequest copyWith({
    String? id,
    String? agentId,
    String? turnId,
    String? toolCallId,
    String? toolName,
    String? risk,
    String? argumentsJson,
    Value<String?> preview = const Value.absent(),
    String? status,
    DateTime? createdAt,
  }) => ApprovalRequest(
    id: id ?? this.id,
    agentId: agentId ?? this.agentId,
    turnId: turnId ?? this.turnId,
    toolCallId: toolCallId ?? this.toolCallId,
    toolName: toolName ?? this.toolName,
    risk: risk ?? this.risk,
    argumentsJson: argumentsJson ?? this.argumentsJson,
    preview: preview.present ? preview.value : this.preview,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  ApprovalRequest copyWithCompanion(ApprovalRequestsCompanion data) {
    return ApprovalRequest(
      id: data.id.present ? data.id.value : this.id,
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      turnId: data.turnId.present ? data.turnId.value : this.turnId,
      toolCallId: data.toolCallId.present
          ? data.toolCallId.value
          : this.toolCallId,
      toolName: data.toolName.present ? data.toolName.value : this.toolName,
      risk: data.risk.present ? data.risk.value : this.risk,
      argumentsJson: data.argumentsJson.present
          ? data.argumentsJson.value
          : this.argumentsJson,
      preview: data.preview.present ? data.preview.value : this.preview,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApprovalRequest(')
          ..write('id: $id, ')
          ..write('agentId: $agentId, ')
          ..write('turnId: $turnId, ')
          ..write('toolCallId: $toolCallId, ')
          ..write('toolName: $toolName, ')
          ..write('risk: $risk, ')
          ..write('argumentsJson: $argumentsJson, ')
          ..write('preview: $preview, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    agentId,
    turnId,
    toolCallId,
    toolName,
    risk,
    argumentsJson,
    preview,
    status,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApprovalRequest &&
          other.id == this.id &&
          other.agentId == this.agentId &&
          other.turnId == this.turnId &&
          other.toolCallId == this.toolCallId &&
          other.toolName == this.toolName &&
          other.risk == this.risk &&
          other.argumentsJson == this.argumentsJson &&
          other.preview == this.preview &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class ApprovalRequestsCompanion extends UpdateCompanion<ApprovalRequest> {
  final Value<String> id;
  final Value<String> agentId;
  final Value<String> turnId;
  final Value<String> toolCallId;
  final Value<String> toolName;
  final Value<String> risk;
  final Value<String> argumentsJson;
  final Value<String?> preview;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ApprovalRequestsCompanion({
    this.id = const Value.absent(),
    this.agentId = const Value.absent(),
    this.turnId = const Value.absent(),
    this.toolCallId = const Value.absent(),
    this.toolName = const Value.absent(),
    this.risk = const Value.absent(),
    this.argumentsJson = const Value.absent(),
    this.preview = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApprovalRequestsCompanion.insert({
    required String id,
    required String agentId,
    required String turnId,
    required String toolCallId,
    required String toolName,
    required String risk,
    required String argumentsJson,
    this.preview = const Value.absent(),
    required String status,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       agentId = Value(agentId),
       turnId = Value(turnId),
       toolCallId = Value(toolCallId),
       toolName = Value(toolName),
       risk = Value(risk),
       argumentsJson = Value(argumentsJson),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<ApprovalRequest> custom({
    Expression<String>? id,
    Expression<String>? agentId,
    Expression<String>? turnId,
    Expression<String>? toolCallId,
    Expression<String>? toolName,
    Expression<String>? risk,
    Expression<String>? argumentsJson,
    Expression<String>? preview,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (agentId != null) 'agent_id': agentId,
      if (turnId != null) 'turn_id': turnId,
      if (toolCallId != null) 'tool_call_id': toolCallId,
      if (toolName != null) 'tool_name': toolName,
      if (risk != null) 'risk': risk,
      if (argumentsJson != null) 'arguments_json': argumentsJson,
      if (preview != null) 'preview': preview,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApprovalRequestsCompanion copyWith({
    Value<String>? id,
    Value<String>? agentId,
    Value<String>? turnId,
    Value<String>? toolCallId,
    Value<String>? toolName,
    Value<String>? risk,
    Value<String>? argumentsJson,
    Value<String?>? preview,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ApprovalRequestsCompanion(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      turnId: turnId ?? this.turnId,
      toolCallId: toolCallId ?? this.toolCallId,
      toolName: toolName ?? this.toolName,
      risk: risk ?? this.risk,
      argumentsJson: argumentsJson ?? this.argumentsJson,
      preview: preview ?? this.preview,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (agentId.present) {
      map['agent_id'] = Variable<String>(agentId.value);
    }
    if (turnId.present) {
      map['turn_id'] = Variable<String>(turnId.value);
    }
    if (toolCallId.present) {
      map['tool_call_id'] = Variable<String>(toolCallId.value);
    }
    if (toolName.present) {
      map['tool_name'] = Variable<String>(toolName.value);
    }
    if (risk.present) {
      map['risk'] = Variable<String>(risk.value);
    }
    if (argumentsJson.present) {
      map['arguments_json'] = Variable<String>(argumentsJson.value);
    }
    if (preview.present) {
      map['preview'] = Variable<String>(preview.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApprovalRequestsCompanion(')
          ..write('id: $id, ')
          ..write('agentId: $agentId, ')
          ..write('turnId: $turnId, ')
          ..write('toolCallId: $toolCallId, ')
          ..write('toolName: $toolName, ')
          ..write('risk: $risk, ')
          ..write('argumentsJson: $argumentsJson, ')
          ..write('preview: $preview, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProviderStatesTable extends ProviderStates
    with TableInfo<$ProviderStatesTable, ProviderState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _agentIdMeta = const VerificationMeta(
    'agentId',
  );
  @override
  late final GeneratedColumn<String> agentId = GeneratedColumn<String>(
    'agent_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES agents (id)',
    ),
  );
  static const VerificationMeta _ordinalMeta = const VerificationMeta(
    'ordinal',
  );
  @override
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
    'ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemJsonMeta = const VerificationMeta(
    'itemJson',
  );
  @override
  late final GeneratedColumn<String> itemJson = GeneratedColumn<String>(
    'item_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [agentId, ordinal, itemJson, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('agent_id')) {
      context.handle(
        _agentIdMeta,
        agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_agentIdMeta);
    }
    if (data.containsKey('ordinal')) {
      context.handle(
        _ordinalMeta,
        ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta),
      );
    } else if (isInserting) {
      context.missing(_ordinalMeta);
    }
    if (data.containsKey('item_json')) {
      context.handle(
        _itemJsonMeta,
        itemJson.isAcceptableOrUnknown(data['item_json']!, _itemJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_itemJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {agentId, ordinal};
  @override
  ProviderState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderState(
      agentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_id'],
      )!,
      ordinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal'],
      )!,
      itemJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProviderStatesTable createAlias(String alias) {
    return $ProviderStatesTable(attachedDatabase, alias);
  }
}

class ProviderState extends DataClass implements Insertable<ProviderState> {
  /// The agentId public API member.
  final String agentId;

  /// The ordinal public API member.
  final int ordinal;

  /// The itemJson public API member.
  final String itemJson;

  /// The createdAt public API member.
  final DateTime createdAt;
  const ProviderState({
    required this.agentId,
    required this.ordinal,
    required this.itemJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['agent_id'] = Variable<String>(agentId);
    map['ordinal'] = Variable<int>(ordinal);
    map['item_json'] = Variable<String>(itemJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProviderStatesCompanion toCompanion(bool nullToAbsent) {
    return ProviderStatesCompanion(
      agentId: Value(agentId),
      ordinal: Value(ordinal),
      itemJson: Value(itemJson),
      createdAt: Value(createdAt),
    );
  }

  factory ProviderState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderState(
      agentId: serializer.fromJson<String>(json['agentId']),
      ordinal: serializer.fromJson<int>(json['ordinal']),
      itemJson: serializer.fromJson<String>(json['itemJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'agentId': serializer.toJson<String>(agentId),
      'ordinal': serializer.toJson<int>(ordinal),
      'itemJson': serializer.toJson<String>(itemJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProviderState copyWith({
    String? agentId,
    int? ordinal,
    String? itemJson,
    DateTime? createdAt,
  }) => ProviderState(
    agentId: agentId ?? this.agentId,
    ordinal: ordinal ?? this.ordinal,
    itemJson: itemJson ?? this.itemJson,
    createdAt: createdAt ?? this.createdAt,
  );
  ProviderState copyWithCompanion(ProviderStatesCompanion data) {
    return ProviderState(
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
      itemJson: data.itemJson.present ? data.itemJson.value : this.itemJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderState(')
          ..write('agentId: $agentId, ')
          ..write('ordinal: $ordinal, ')
          ..write('itemJson: $itemJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(agentId, ordinal, itemJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderState &&
          other.agentId == this.agentId &&
          other.ordinal == this.ordinal &&
          other.itemJson == this.itemJson &&
          other.createdAt == this.createdAt);
}

class ProviderStatesCompanion extends UpdateCompanion<ProviderState> {
  final Value<String> agentId;
  final Value<int> ordinal;
  final Value<String> itemJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProviderStatesCompanion({
    this.agentId = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.itemJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProviderStatesCompanion.insert({
    required String agentId,
    required int ordinal,
    required String itemJson,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : agentId = Value(agentId),
       ordinal = Value(ordinal),
       itemJson = Value(itemJson),
       createdAt = Value(createdAt);
  static Insertable<ProviderState> custom({
    Expression<String>? agentId,
    Expression<int>? ordinal,
    Expression<String>? itemJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (agentId != null) 'agent_id': agentId,
      if (ordinal != null) 'ordinal': ordinal,
      if (itemJson != null) 'item_json': itemJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProviderStatesCompanion copyWith({
    Value<String>? agentId,
    Value<int>? ordinal,
    Value<String>? itemJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ProviderStatesCompanion(
      agentId: agentId ?? this.agentId,
      ordinal: ordinal ?? this.ordinal,
      itemJson: itemJson ?? this.itemJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (agentId.present) {
      map['agent_id'] = Variable<String>(agentId.value);
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (itemJson.present) {
      map['item_json'] = Variable<String>(itemJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderStatesCompanion(')
          ..write('agentId: $agentId, ')
          ..write('ordinal: $ordinal, ')
          ..write('itemJson: $itemJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
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
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
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
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  /// The key public API member.
  final String key;

  /// The value public API member.
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
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

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
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
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
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

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
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
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProviderConnectionsTable extends ProviderConnections
    with TableInfo<$ProviderConnectionsTable, ProviderConnection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderConnectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _definitionIdMeta = const VerificationMeta(
    'definitionId',
  );
  @override
  late final GeneratedColumn<String> definitionId = GeneratedColumn<String>(
    'definition_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authKindMeta = const VerificationMeta(
    'authKind',
  );
  @override
  late final GeneratedColumn<String> authKind = GeneratedColumn<String>(
    'auth_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _credentialOriginMeta = const VerificationMeta(
    'credentialOrigin',
  );
  @override
  late final GeneratedColumn<String> credentialOrigin = GeneratedColumn<String>(
    'credential_origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _defaultModelIdMeta = const VerificationMeta(
    'defaultModelId',
  );
  @override
  late final GeneratedColumn<String> defaultModelId = GeneratedColumn<String>(
    'default_model_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customConfigJsonMeta = const VerificationMeta(
    'customConfigJson',
  );
  @override
  late final GeneratedColumn<String> customConfigJson = GeneratedColumn<String>(
    'custom_config_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    definitionId,
    displayName,
    status,
    authKind,
    credentialOrigin,
    isDefault,
    defaultModelId,
    error,
    customConfigJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_connections';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderConnection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('definition_id')) {
      context.handle(
        _definitionIdMeta,
        definitionId.isAcceptableOrUnknown(
          data['definition_id']!,
          _definitionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_definitionIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('auth_kind')) {
      context.handle(
        _authKindMeta,
        authKind.isAcceptableOrUnknown(data['auth_kind']!, _authKindMeta),
      );
    } else if (isInserting) {
      context.missing(_authKindMeta);
    }
    if (data.containsKey('credential_origin')) {
      context.handle(
        _credentialOriginMeta,
        credentialOrigin.isAcceptableOrUnknown(
          data['credential_origin']!,
          _credentialOriginMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_credentialOriginMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('default_model_id')) {
      context.handle(
        _defaultModelIdMeta,
        defaultModelId.isAcceptableOrUnknown(
          data['default_model_id']!,
          _defaultModelIdMeta,
        ),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('custom_config_json')) {
      context.handle(
        _customConfigJsonMeta,
        customConfigJson.isAcceptableOrUnknown(
          data['custom_config_json']!,
          _customConfigJsonMeta,
        ),
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
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProviderConnection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderConnection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      definitionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definition_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      authKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_kind'],
      )!,
      credentialOrigin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credential_origin'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      defaultModelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_model_id'],
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      customConfigJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_config_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProviderConnectionsTable createAlias(String alias) {
    return $ProviderConnectionsTable(attachedDatabase, alias);
  }
}

class ProviderConnection extends DataClass
    implements Insertable<ProviderConnection> {
  /// The id public API member.
  final String id;

  /// Built-in definition identifier, or `custom`.
  final String definitionId;

  /// Human-readable connection name.
  final String displayName;

  /// Current connection state.
  final String status;

  /// Active authentication kind.
  final String authKind;

  /// Non-secret credential origin.
  final String credentialOrigin;

  /// Whether this is the daemon-wide default connection.
  final bool isDefault;

  /// The defaultModelId public API member.
  final String? defaultModelId;

  /// Last user-safe connection error.
  final String? error;

  /// Advanced custom configuration, never used by built-in definitions.
  final String? customConfigJson;

  /// The createdAt public API member.
  final DateTime createdAt;

  /// The updatedAt public API member.
  final DateTime updatedAt;
  const ProviderConnection({
    required this.id,
    required this.definitionId,
    required this.displayName,
    required this.status,
    required this.authKind,
    required this.credentialOrigin,
    required this.isDefault,
    this.defaultModelId,
    this.error,
    this.customConfigJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['definition_id'] = Variable<String>(definitionId);
    map['display_name'] = Variable<String>(displayName);
    map['status'] = Variable<String>(status);
    map['auth_kind'] = Variable<String>(authKind);
    map['credential_origin'] = Variable<String>(credentialOrigin);
    map['is_default'] = Variable<bool>(isDefault);
    if (!nullToAbsent || defaultModelId != null) {
      map['default_model_id'] = Variable<String>(defaultModelId);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    if (!nullToAbsent || customConfigJson != null) {
      map['custom_config_json'] = Variable<String>(customConfigJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProviderConnectionsCompanion toCompanion(bool nullToAbsent) {
    return ProviderConnectionsCompanion(
      id: Value(id),
      definitionId: Value(definitionId),
      displayName: Value(displayName),
      status: Value(status),
      authKind: Value(authKind),
      credentialOrigin: Value(credentialOrigin),
      isDefault: Value(isDefault),
      defaultModelId: defaultModelId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultModelId),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      customConfigJson: customConfigJson == null && nullToAbsent
          ? const Value.absent()
          : Value(customConfigJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProviderConnection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderConnection(
      id: serializer.fromJson<String>(json['id']),
      definitionId: serializer.fromJson<String>(json['definitionId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      status: serializer.fromJson<String>(json['status']),
      authKind: serializer.fromJson<String>(json['authKind']),
      credentialOrigin: serializer.fromJson<String>(json['credentialOrigin']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      defaultModelId: serializer.fromJson<String?>(json['defaultModelId']),
      error: serializer.fromJson<String?>(json['error']),
      customConfigJson: serializer.fromJson<String?>(json['customConfigJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'definitionId': serializer.toJson<String>(definitionId),
      'displayName': serializer.toJson<String>(displayName),
      'status': serializer.toJson<String>(status),
      'authKind': serializer.toJson<String>(authKind),
      'credentialOrigin': serializer.toJson<String>(credentialOrigin),
      'isDefault': serializer.toJson<bool>(isDefault),
      'defaultModelId': serializer.toJson<String?>(defaultModelId),
      'error': serializer.toJson<String?>(error),
      'customConfigJson': serializer.toJson<String?>(customConfigJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProviderConnection copyWith({
    String? id,
    String? definitionId,
    String? displayName,
    String? status,
    String? authKind,
    String? credentialOrigin,
    bool? isDefault,
    Value<String?> defaultModelId = const Value.absent(),
    Value<String?> error = const Value.absent(),
    Value<String?> customConfigJson = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProviderConnection(
    id: id ?? this.id,
    definitionId: definitionId ?? this.definitionId,
    displayName: displayName ?? this.displayName,
    status: status ?? this.status,
    authKind: authKind ?? this.authKind,
    credentialOrigin: credentialOrigin ?? this.credentialOrigin,
    isDefault: isDefault ?? this.isDefault,
    defaultModelId: defaultModelId.present
        ? defaultModelId.value
        : this.defaultModelId,
    error: error.present ? error.value : this.error,
    customConfigJson: customConfigJson.present
        ? customConfigJson.value
        : this.customConfigJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProviderConnection copyWithCompanion(ProviderConnectionsCompanion data) {
    return ProviderConnection(
      id: data.id.present ? data.id.value : this.id,
      definitionId: data.definitionId.present
          ? data.definitionId.value
          : this.definitionId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      status: data.status.present ? data.status.value : this.status,
      authKind: data.authKind.present ? data.authKind.value : this.authKind,
      credentialOrigin: data.credentialOrigin.present
          ? data.credentialOrigin.value
          : this.credentialOrigin,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      defaultModelId: data.defaultModelId.present
          ? data.defaultModelId.value
          : this.defaultModelId,
      error: data.error.present ? data.error.value : this.error,
      customConfigJson: data.customConfigJson.present
          ? data.customConfigJson.value
          : this.customConfigJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderConnection(')
          ..write('id: $id, ')
          ..write('definitionId: $definitionId, ')
          ..write('displayName: $displayName, ')
          ..write('status: $status, ')
          ..write('authKind: $authKind, ')
          ..write('credentialOrigin: $credentialOrigin, ')
          ..write('isDefault: $isDefault, ')
          ..write('defaultModelId: $defaultModelId, ')
          ..write('error: $error, ')
          ..write('customConfigJson: $customConfigJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    definitionId,
    displayName,
    status,
    authKind,
    credentialOrigin,
    isDefault,
    defaultModelId,
    error,
    customConfigJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderConnection &&
          other.id == this.id &&
          other.definitionId == this.definitionId &&
          other.displayName == this.displayName &&
          other.status == this.status &&
          other.authKind == this.authKind &&
          other.credentialOrigin == this.credentialOrigin &&
          other.isDefault == this.isDefault &&
          other.defaultModelId == this.defaultModelId &&
          other.error == this.error &&
          other.customConfigJson == this.customConfigJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProviderConnectionsCompanion extends UpdateCompanion<ProviderConnection> {
  final Value<String> id;
  final Value<String> definitionId;
  final Value<String> displayName;
  final Value<String> status;
  final Value<String> authKind;
  final Value<String> credentialOrigin;
  final Value<bool> isDefault;
  final Value<String?> defaultModelId;
  final Value<String?> error;
  final Value<String?> customConfigJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProviderConnectionsCompanion({
    this.id = const Value.absent(),
    this.definitionId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.status = const Value.absent(),
    this.authKind = const Value.absent(),
    this.credentialOrigin = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.defaultModelId = const Value.absent(),
    this.error = const Value.absent(),
    this.customConfigJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProviderConnectionsCompanion.insert({
    required String id,
    required String definitionId,
    required String displayName,
    required String status,
    required String authKind,
    required String credentialOrigin,
    this.isDefault = const Value.absent(),
    this.defaultModelId = const Value.absent(),
    this.error = const Value.absent(),
    this.customConfigJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       definitionId = Value(definitionId),
       displayName = Value(displayName),
       status = Value(status),
       authKind = Value(authKind),
       credentialOrigin = Value(credentialOrigin),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProviderConnection> custom({
    Expression<String>? id,
    Expression<String>? definitionId,
    Expression<String>? displayName,
    Expression<String>? status,
    Expression<String>? authKind,
    Expression<String>? credentialOrigin,
    Expression<bool>? isDefault,
    Expression<String>? defaultModelId,
    Expression<String>? error,
    Expression<String>? customConfigJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (definitionId != null) 'definition_id': definitionId,
      if (displayName != null) 'display_name': displayName,
      if (status != null) 'status': status,
      if (authKind != null) 'auth_kind': authKind,
      if (credentialOrigin != null) 'credential_origin': credentialOrigin,
      if (isDefault != null) 'is_default': isDefault,
      if (defaultModelId != null) 'default_model_id': defaultModelId,
      if (error != null) 'error': error,
      if (customConfigJson != null) 'custom_config_json': customConfigJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProviderConnectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? definitionId,
    Value<String>? displayName,
    Value<String>? status,
    Value<String>? authKind,
    Value<String>? credentialOrigin,
    Value<bool>? isDefault,
    Value<String?>? defaultModelId,
    Value<String?>? error,
    Value<String?>? customConfigJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProviderConnectionsCompanion(
      id: id ?? this.id,
      definitionId: definitionId ?? this.definitionId,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      authKind: authKind ?? this.authKind,
      credentialOrigin: credentialOrigin ?? this.credentialOrigin,
      isDefault: isDefault ?? this.isDefault,
      defaultModelId: defaultModelId ?? this.defaultModelId,
      error: error ?? this.error,
      customConfigJson: customConfigJson ?? this.customConfigJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (definitionId.present) {
      map['definition_id'] = Variable<String>(definitionId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (authKind.present) {
      map['auth_kind'] = Variable<String>(authKind.value);
    }
    if (credentialOrigin.present) {
      map['credential_origin'] = Variable<String>(credentialOrigin.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (defaultModelId.present) {
      map['default_model_id'] = Variable<String>(defaultModelId.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (customConfigJson.present) {
      map['custom_config_json'] = Variable<String>(customConfigJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderConnectionsCompanion(')
          ..write('id: $id, ')
          ..write('definitionId: $definitionId, ')
          ..write('displayName: $displayName, ')
          ..write('status: $status, ')
          ..write('authKind: $authKind, ')
          ..write('credentialOrigin: $credentialOrigin, ')
          ..write('isDefault: $isDefault, ')
          ..write('defaultModelId: $defaultModelId, ')
          ..write('error: $error, ')
          ..write('customConfigJson: $customConfigJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProviderModelsTable extends ProviderModels
    with TableInfo<$ProviderModelsTable, ProviderModel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _connectionIdMeta = const VerificationMeta(
    'connectionId',
  );
  @override
  late final GeneratedColumn<String> connectionId = GeneratedColumn<String>(
    'connection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES provider_connections (id)',
    ),
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
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
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capabilitiesJsonMeta = const VerificationMeta(
    'capabilitiesJson',
  );
  @override
  late final GeneratedColumn<String> capabilitiesJson = GeneratedColumn<String>(
    'capabilities_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pricingJsonMeta = const VerificationMeta(
    'pricingJson',
  );
  @override
  late final GeneratedColumn<String> pricingJson = GeneratedColumn<String>(
    'pricing_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _limitsJsonMeta = const VerificationMeta(
    'limitsJson',
  );
  @override
  late final GeneratedColumn<String> limitsJson = GeneratedColumn<String>(
    'limits_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _diagnosticStatusMeta = const VerificationMeta(
    'diagnosticStatus',
  );
  @override
  late final GeneratedColumn<String> diagnosticStatus = GeneratedColumn<String>(
    'diagnostic_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unknown'),
  );
  static const VerificationMeta _verifiedAtMeta = const VerificationMeta(
    'verifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> verifiedAt = GeneratedColumn<DateTime>(
    'verified_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _diagnosticErrorMeta = const VerificationMeta(
    'diagnosticError',
  );
  @override
  late final GeneratedColumn<String> diagnosticError = GeneratedColumn<String>(
    'diagnostic_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    connectionId,
    modelId,
    label,
    source,
    capabilitiesJson,
    pricingJson,
    limitsJson,
    diagnosticStatus,
    verifiedAt,
    diagnosticError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_models';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderModel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('connection_id')) {
      context.handle(
        _connectionIdMeta,
        connectionId.isAcceptableOrUnknown(
          data['connection_id']!,
          _connectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_connectionIdMeta);
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('capabilities_json')) {
      context.handle(
        _capabilitiesJsonMeta,
        capabilitiesJson.isAcceptableOrUnknown(
          data['capabilities_json']!,
          _capabilitiesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_capabilitiesJsonMeta);
    }
    if (data.containsKey('pricing_json')) {
      context.handle(
        _pricingJsonMeta,
        pricingJson.isAcceptableOrUnknown(
          data['pricing_json']!,
          _pricingJsonMeta,
        ),
      );
    }
    if (data.containsKey('limits_json')) {
      context.handle(
        _limitsJsonMeta,
        limitsJson.isAcceptableOrUnknown(data['limits_json']!, _limitsJsonMeta),
      );
    }
    if (data.containsKey('diagnostic_status')) {
      context.handle(
        _diagnosticStatusMeta,
        diagnosticStatus.isAcceptableOrUnknown(
          data['diagnostic_status']!,
          _diagnosticStatusMeta,
        ),
      );
    }
    if (data.containsKey('verified_at')) {
      context.handle(
        _verifiedAtMeta,
        verifiedAt.isAcceptableOrUnknown(data['verified_at']!, _verifiedAtMeta),
      );
    }
    if (data.containsKey('diagnostic_error')) {
      context.handle(
        _diagnosticErrorMeta,
        diagnosticError.isAcceptableOrUnknown(
          data['diagnostic_error']!,
          _diagnosticErrorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {connectionId, modelId};
  @override
  ProviderModel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderModel(
      connectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}connection_id'],
      )!,
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      capabilitiesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}capabilities_json'],
      )!,
      pricingJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pricing_json'],
      ),
      limitsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}limits_json'],
      ),
      diagnosticStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diagnostic_status'],
      )!,
      verifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}verified_at'],
      ),
      diagnosticError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diagnostic_error'],
      ),
    );
  }

  @override
  $ProviderModelsTable createAlias(String alias) {
    return $ProviderModelsTable(attachedDatabase, alias);
  }
}

class ProviderModel extends DataClass implements Insertable<ProviderModel> {
  /// Owning provider connection.
  final String connectionId;

  /// The modelId public API member.
  final String modelId;

  /// The label public API member.
  final String label;

  /// The source public API member.
  final String source;

  /// The capabilitiesJson public API member.
  final String capabilitiesJson;

  /// Optional model pricing metadata.
  final String? pricingJson;

  /// Optional model token-limit metadata.
  final String? limitsJson;

  /// The diagnosticStatus public API member.
  final String diagnosticStatus;

  /// The verifiedAt public API member.
  final DateTime? verifiedAt;

  /// The diagnosticError public API member.
  final String? diagnosticError;
  const ProviderModel({
    required this.connectionId,
    required this.modelId,
    required this.label,
    required this.source,
    required this.capabilitiesJson,
    this.pricingJson,
    this.limitsJson,
    required this.diagnosticStatus,
    this.verifiedAt,
    this.diagnosticError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['connection_id'] = Variable<String>(connectionId);
    map['model_id'] = Variable<String>(modelId);
    map['label'] = Variable<String>(label);
    map['source'] = Variable<String>(source);
    map['capabilities_json'] = Variable<String>(capabilitiesJson);
    if (!nullToAbsent || pricingJson != null) {
      map['pricing_json'] = Variable<String>(pricingJson);
    }
    if (!nullToAbsent || limitsJson != null) {
      map['limits_json'] = Variable<String>(limitsJson);
    }
    map['diagnostic_status'] = Variable<String>(diagnosticStatus);
    if (!nullToAbsent || verifiedAt != null) {
      map['verified_at'] = Variable<DateTime>(verifiedAt);
    }
    if (!nullToAbsent || diagnosticError != null) {
      map['diagnostic_error'] = Variable<String>(diagnosticError);
    }
    return map;
  }

  ProviderModelsCompanion toCompanion(bool nullToAbsent) {
    return ProviderModelsCompanion(
      connectionId: Value(connectionId),
      modelId: Value(modelId),
      label: Value(label),
      source: Value(source),
      capabilitiesJson: Value(capabilitiesJson),
      pricingJson: pricingJson == null && nullToAbsent
          ? const Value.absent()
          : Value(pricingJson),
      limitsJson: limitsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(limitsJson),
      diagnosticStatus: Value(diagnosticStatus),
      verifiedAt: verifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedAt),
      diagnosticError: diagnosticError == null && nullToAbsent
          ? const Value.absent()
          : Value(diagnosticError),
    );
  }

  factory ProviderModel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderModel(
      connectionId: serializer.fromJson<String>(json['connectionId']),
      modelId: serializer.fromJson<String>(json['modelId']),
      label: serializer.fromJson<String>(json['label']),
      source: serializer.fromJson<String>(json['source']),
      capabilitiesJson: serializer.fromJson<String>(json['capabilitiesJson']),
      pricingJson: serializer.fromJson<String?>(json['pricingJson']),
      limitsJson: serializer.fromJson<String?>(json['limitsJson']),
      diagnosticStatus: serializer.fromJson<String>(json['diagnosticStatus']),
      verifiedAt: serializer.fromJson<DateTime?>(json['verifiedAt']),
      diagnosticError: serializer.fromJson<String?>(json['diagnosticError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'connectionId': serializer.toJson<String>(connectionId),
      'modelId': serializer.toJson<String>(modelId),
      'label': serializer.toJson<String>(label),
      'source': serializer.toJson<String>(source),
      'capabilitiesJson': serializer.toJson<String>(capabilitiesJson),
      'pricingJson': serializer.toJson<String?>(pricingJson),
      'limitsJson': serializer.toJson<String?>(limitsJson),
      'diagnosticStatus': serializer.toJson<String>(diagnosticStatus),
      'verifiedAt': serializer.toJson<DateTime?>(verifiedAt),
      'diagnosticError': serializer.toJson<String?>(diagnosticError),
    };
  }

  ProviderModel copyWith({
    String? connectionId,
    String? modelId,
    String? label,
    String? source,
    String? capabilitiesJson,
    Value<String?> pricingJson = const Value.absent(),
    Value<String?> limitsJson = const Value.absent(),
    String? diagnosticStatus,
    Value<DateTime?> verifiedAt = const Value.absent(),
    Value<String?> diagnosticError = const Value.absent(),
  }) => ProviderModel(
    connectionId: connectionId ?? this.connectionId,
    modelId: modelId ?? this.modelId,
    label: label ?? this.label,
    source: source ?? this.source,
    capabilitiesJson: capabilitiesJson ?? this.capabilitiesJson,
    pricingJson: pricingJson.present ? pricingJson.value : this.pricingJson,
    limitsJson: limitsJson.present ? limitsJson.value : this.limitsJson,
    diagnosticStatus: diagnosticStatus ?? this.diagnosticStatus,
    verifiedAt: verifiedAt.present ? verifiedAt.value : this.verifiedAt,
    diagnosticError: diagnosticError.present
        ? diagnosticError.value
        : this.diagnosticError,
  );
  ProviderModel copyWithCompanion(ProviderModelsCompanion data) {
    return ProviderModel(
      connectionId: data.connectionId.present
          ? data.connectionId.value
          : this.connectionId,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      label: data.label.present ? data.label.value : this.label,
      source: data.source.present ? data.source.value : this.source,
      capabilitiesJson: data.capabilitiesJson.present
          ? data.capabilitiesJson.value
          : this.capabilitiesJson,
      pricingJson: data.pricingJson.present
          ? data.pricingJson.value
          : this.pricingJson,
      limitsJson: data.limitsJson.present
          ? data.limitsJson.value
          : this.limitsJson,
      diagnosticStatus: data.diagnosticStatus.present
          ? data.diagnosticStatus.value
          : this.diagnosticStatus,
      verifiedAt: data.verifiedAt.present
          ? data.verifiedAt.value
          : this.verifiedAt,
      diagnosticError: data.diagnosticError.present
          ? data.diagnosticError.value
          : this.diagnosticError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderModel(')
          ..write('connectionId: $connectionId, ')
          ..write('modelId: $modelId, ')
          ..write('label: $label, ')
          ..write('source: $source, ')
          ..write('capabilitiesJson: $capabilitiesJson, ')
          ..write('pricingJson: $pricingJson, ')
          ..write('limitsJson: $limitsJson, ')
          ..write('diagnosticStatus: $diagnosticStatus, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('diagnosticError: $diagnosticError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    connectionId,
    modelId,
    label,
    source,
    capabilitiesJson,
    pricingJson,
    limitsJson,
    diagnosticStatus,
    verifiedAt,
    diagnosticError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderModel &&
          other.connectionId == this.connectionId &&
          other.modelId == this.modelId &&
          other.label == this.label &&
          other.source == this.source &&
          other.capabilitiesJson == this.capabilitiesJson &&
          other.pricingJson == this.pricingJson &&
          other.limitsJson == this.limitsJson &&
          other.diagnosticStatus == this.diagnosticStatus &&
          other.verifiedAt == this.verifiedAt &&
          other.diagnosticError == this.diagnosticError);
}

class ProviderModelsCompanion extends UpdateCompanion<ProviderModel> {
  final Value<String> connectionId;
  final Value<String> modelId;
  final Value<String> label;
  final Value<String> source;
  final Value<String> capabilitiesJson;
  final Value<String?> pricingJson;
  final Value<String?> limitsJson;
  final Value<String> diagnosticStatus;
  final Value<DateTime?> verifiedAt;
  final Value<String?> diagnosticError;
  final Value<int> rowid;
  const ProviderModelsCompanion({
    this.connectionId = const Value.absent(),
    this.modelId = const Value.absent(),
    this.label = const Value.absent(),
    this.source = const Value.absent(),
    this.capabilitiesJson = const Value.absent(),
    this.pricingJson = const Value.absent(),
    this.limitsJson = const Value.absent(),
    this.diagnosticStatus = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.diagnosticError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProviderModelsCompanion.insert({
    required String connectionId,
    required String modelId,
    required String label,
    required String source,
    required String capabilitiesJson,
    this.pricingJson = const Value.absent(),
    this.limitsJson = const Value.absent(),
    this.diagnosticStatus = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.diagnosticError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : connectionId = Value(connectionId),
       modelId = Value(modelId),
       label = Value(label),
       source = Value(source),
       capabilitiesJson = Value(capabilitiesJson);
  static Insertable<ProviderModel> custom({
    Expression<String>? connectionId,
    Expression<String>? modelId,
    Expression<String>? label,
    Expression<String>? source,
    Expression<String>? capabilitiesJson,
    Expression<String>? pricingJson,
    Expression<String>? limitsJson,
    Expression<String>? diagnosticStatus,
    Expression<DateTime>? verifiedAt,
    Expression<String>? diagnosticError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (connectionId != null) 'connection_id': connectionId,
      if (modelId != null) 'model_id': modelId,
      if (label != null) 'label': label,
      if (source != null) 'source': source,
      if (capabilitiesJson != null) 'capabilities_json': capabilitiesJson,
      if (pricingJson != null) 'pricing_json': pricingJson,
      if (limitsJson != null) 'limits_json': limitsJson,
      if (diagnosticStatus != null) 'diagnostic_status': diagnosticStatus,
      if (verifiedAt != null) 'verified_at': verifiedAt,
      if (diagnosticError != null) 'diagnostic_error': diagnosticError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProviderModelsCompanion copyWith({
    Value<String>? connectionId,
    Value<String>? modelId,
    Value<String>? label,
    Value<String>? source,
    Value<String>? capabilitiesJson,
    Value<String?>? pricingJson,
    Value<String?>? limitsJson,
    Value<String>? diagnosticStatus,
    Value<DateTime?>? verifiedAt,
    Value<String?>? diagnosticError,
    Value<int>? rowid,
  }) {
    return ProviderModelsCompanion(
      connectionId: connectionId ?? this.connectionId,
      modelId: modelId ?? this.modelId,
      label: label ?? this.label,
      source: source ?? this.source,
      capabilitiesJson: capabilitiesJson ?? this.capabilitiesJson,
      pricingJson: pricingJson ?? this.pricingJson,
      limitsJson: limitsJson ?? this.limitsJson,
      diagnosticStatus: diagnosticStatus ?? this.diagnosticStatus,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      diagnosticError: diagnosticError ?? this.diagnosticError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (connectionId.present) {
      map['connection_id'] = Variable<String>(connectionId.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (capabilitiesJson.present) {
      map['capabilities_json'] = Variable<String>(capabilitiesJson.value);
    }
    if (pricingJson.present) {
      map['pricing_json'] = Variable<String>(pricingJson.value);
    }
    if (limitsJson.present) {
      map['limits_json'] = Variable<String>(limitsJson.value);
    }
    if (diagnosticStatus.present) {
      map['diagnostic_status'] = Variable<String>(diagnosticStatus.value);
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<DateTime>(verifiedAt.value);
    }
    if (diagnosticError.present) {
      map['diagnostic_error'] = Variable<String>(diagnosticError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderModelsCompanion(')
          ..write('connectionId: $connectionId, ')
          ..write('modelId: $modelId, ')
          ..write('label: $label, ')
          ..write('source: $source, ')
          ..write('capabilitiesJson: $capabilitiesJson, ')
          ..write('pricingJson: $pricingJson, ')
          ..write('limitsJson: $limitsJson, ')
          ..write('diagnosticStatus: $diagnosticStatus, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('diagnosticError: $diagnosticError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CoderDatabase extends GeneratedDatabase {
  _$CoderDatabase(QueryExecutor e) : super(e);
  $CoderDatabaseManager get managers => $CoderDatabaseManager(this);
  late final $WorkspacesTable workspaces = $WorkspacesTable(this);
  late final $AgentsTable agents = $AgentsTable(this);
  late final $TurnsTable turns = $TurnsTable(this);
  late final $TimelineEventsTable timelineEvents = $TimelineEventsTable(this);
  late final $ApprovalRequestsTable approvalRequests = $ApprovalRequestsTable(
    this,
  );
  late final $ProviderStatesTable providerStates = $ProviderStatesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $ProviderConnectionsTable providerConnections =
      $ProviderConnectionsTable(this);
  late final $ProviderModelsTable providerModels = $ProviderModelsTable(this);
  late final SettingsDao settingsDao = SettingsDao(this as CoderDatabase);
  late final WorkspaceDao workspaceDao = WorkspaceDao(this as CoderDatabase);
  late final AgentDao agentDao = AgentDao(this as CoderDatabase);
  late final TimelineDao timelineDao = TimelineDao(this as CoderDatabase);
  late final ProviderDao providerDao = ProviderDao(this as CoderDatabase);
  late final RuntimeDao runtimeDao = RuntimeDao(this as CoderDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    workspaces,
    agents,
    turns,
    timelineEvents,
    approvalRequests,
    providerStates,
    settings,
    providerConnections,
    providerModels,
  ];
}

typedef $$WorkspacesTableCreateCompanionBuilder =
    WorkspacesCompanion Function({
      required String id,
      required String name,
      required String rootPath,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$WorkspacesTableUpdateCompanionBuilder =
    WorkspacesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> rootPath,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$WorkspacesTableReferences
    extends BaseReferences<_$CoderDatabase, $WorkspacesTable, Workspace> {
  $$WorkspacesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AgentsTable, List<Agent>> _agentsRefsTable(
    _$CoderDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.agents,
    aliasName: 'workspaces__id__agents__workspace_id',
  );

  $$AgentsTableProcessedTableManager get agentsRefs {
    final manager = $$AgentsTableTableManager(
      $_db,
      $_db.agents,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_agentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkspacesTableFilterComposer
    extends Composer<_$CoderDatabase, $WorkspacesTable> {
  $$WorkspacesTableFilterComposer({
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

  ColumnFilters<String> get rootPath => $composableBuilder(
    column: $table.rootPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> agentsRefs(
    Expression<bool> Function($$AgentsTableFilterComposer f) f,
  ) {
    final $$AgentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agents,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentsTableFilterComposer(
            $db: $db,
            $table: $db.agents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkspacesTableOrderingComposer
    extends Composer<_$CoderDatabase, $WorkspacesTable> {
  $$WorkspacesTableOrderingComposer({
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

  ColumnOrderings<String> get rootPath => $composableBuilder(
    column: $table.rootPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkspacesTableAnnotationComposer
    extends Composer<_$CoderDatabase, $WorkspacesTable> {
  $$WorkspacesTableAnnotationComposer({
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

  GeneratedColumn<String> get rootPath =>
      $composableBuilder(column: $table.rootPath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> agentsRefs<T extends Object>(
    Expression<T> Function($$AgentsTableAnnotationComposer a) f,
  ) {
    final $$AgentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agents,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentsTableAnnotationComposer(
            $db: $db,
            $table: $db.agents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkspacesTableTableManager
    extends
        RootTableManager<
          _$CoderDatabase,
          $WorkspacesTable,
          Workspace,
          $$WorkspacesTableFilterComposer,
          $$WorkspacesTableOrderingComposer,
          $$WorkspacesTableAnnotationComposer,
          $$WorkspacesTableCreateCompanionBuilder,
          $$WorkspacesTableUpdateCompanionBuilder,
          (Workspace, $$WorkspacesTableReferences),
          Workspace,
          PrefetchHooks Function({bool agentsRefs})
        > {
  $$WorkspacesTableTableManager(_$CoderDatabase db, $WorkspacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkspacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkspacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkspacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> rootPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion(
                id: id,
                name: name,
                rootPath: rootPath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String rootPath,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion.insert(
                id: id,
                name: name,
                rootPath: rootPath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkspacesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({agentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (agentsRefs) db.agents],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (agentsRefs)
                    await $_getPrefetchedData<
                      Workspace,
                      $WorkspacesTable,
                      Agent
                    >(
                      currentTable: table,
                      referencedTable: $$WorkspacesTableReferences
                          ._agentsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$WorkspacesTableReferences(db, table, p0).agentsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.workspaceId == item.id,
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

typedef $$WorkspacesTableProcessedTableManager =
    ProcessedTableManager<
      _$CoderDatabase,
      $WorkspacesTable,
      Workspace,
      $$WorkspacesTableFilterComposer,
      $$WorkspacesTableOrderingComposer,
      $$WorkspacesTableAnnotationComposer,
      $$WorkspacesTableCreateCompanionBuilder,
      $$WorkspacesTableUpdateCompanionBuilder,
      (Workspace, $$WorkspacesTableReferences),
      Workspace,
      PrefetchHooks Function({bool agentsRefs})
    >;
typedef $$AgentsTableCreateCompanionBuilder =
    AgentsCompanion Function({
      required String id,
      required String workspaceId,
      required String title,
      required String providerConnectionId,
      required String model,
      Value<String> reasoningEffort,
      required String status,
      required String permissionMode,
      Value<String?> activeTurnId,
      Value<String?> lastError,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AgentsTableUpdateCompanionBuilder =
    AgentsCompanion Function({
      Value<String> id,
      Value<String> workspaceId,
      Value<String> title,
      Value<String> providerConnectionId,
      Value<String> model,
      Value<String> reasoningEffort,
      Value<String> status,
      Value<String> permissionMode,
      Value<String?> activeTurnId,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$AgentsTableReferences
    extends BaseReferences<_$CoderDatabase, $AgentsTable, Agent> {
  $$AgentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkspacesTable _workspaceIdTable(_$CoderDatabase db) =>
      db.workspaces.createAlias('agents__workspace_id__workspaces__id');

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TurnsTable, List<Turn>> _turnsRefsTable(
    _$CoderDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.turns,
    aliasName: 'agents__id__turns__agent_id',
  );

  $$TurnsTableProcessedTableManager get turnsRefs {
    final manager = $$TurnsTableTableManager(
      $_db,
      $_db.turns,
    ).filter((f) => f.agentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_turnsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TimelineEventsTable, List<TimelineEvent>>
  _timelineEventsRefsTable(_$CoderDatabase db) => MultiTypedResultKey.fromTable(
    db.timelineEvents,
    aliasName: 'agents__id__timeline_events__agent_id',
  );

  $$TimelineEventsTableProcessedTableManager get timelineEventsRefs {
    final manager = $$TimelineEventsTableTableManager(
      $_db,
      $_db.timelineEvents,
    ).filter((f) => f.agentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_timelineEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ApprovalRequestsTable, List<ApprovalRequest>>
  _approvalRequestsRefsTable(_$CoderDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.approvalRequests,
        aliasName: 'agents__id__approval_requests__agent_id',
      );

  $$ApprovalRequestsTableProcessedTableManager get approvalRequestsRefs {
    final manager = $$ApprovalRequestsTableTableManager(
      $_db,
      $_db.approvalRequests,
    ).filter((f) => f.agentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _approvalRequestsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProviderStatesTable, List<ProviderState>>
  _providerStatesRefsTable(_$CoderDatabase db) => MultiTypedResultKey.fromTable(
    db.providerStates,
    aliasName: 'agents__id__provider_states__agent_id',
  );

  $$ProviderStatesTableProcessedTableManager get providerStatesRefs {
    final manager = $$ProviderStatesTableTableManager(
      $_db,
      $_db.providerStates,
    ).filter((f) => f.agentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_providerStatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AgentsTableFilterComposer
    extends Composer<_$CoderDatabase, $AgentsTable> {
  $$AgentsTableFilterComposer({
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

  ColumnFilters<String> get providerConnectionId => $composableBuilder(
    column: $table.providerConnectionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasoningEffort => $composableBuilder(
    column: $table.reasoningEffort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permissionMode => $composableBuilder(
    column: $table.permissionMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeTurnId => $composableBuilder(
    column: $table.activeTurnId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
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

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> turnsRefs(
    Expression<bool> Function($$TurnsTableFilterComposer f) f,
  ) {
    final $$TurnsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.turns,
      getReferencedColumn: (t) => t.agentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnsTableFilterComposer(
            $db: $db,
            $table: $db.turns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> timelineEventsRefs(
    Expression<bool> Function($$TimelineEventsTableFilterComposer f) f,
  ) {
    final $$TimelineEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timelineEvents,
      getReferencedColumn: (t) => t.agentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimelineEventsTableFilterComposer(
            $db: $db,
            $table: $db.timelineEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> approvalRequestsRefs(
    Expression<bool> Function($$ApprovalRequestsTableFilterComposer f) f,
  ) {
    final $$ApprovalRequestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.approvalRequests,
      getReferencedColumn: (t) => t.agentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ApprovalRequestsTableFilterComposer(
            $db: $db,
            $table: $db.approvalRequests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> providerStatesRefs(
    Expression<bool> Function($$ProviderStatesTableFilterComposer f) f,
  ) {
    final $$ProviderStatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.providerStates,
      getReferencedColumn: (t) => t.agentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderStatesTableFilterComposer(
            $db: $db,
            $table: $db.providerStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AgentsTableOrderingComposer
    extends Composer<_$CoderDatabase, $AgentsTable> {
  $$AgentsTableOrderingComposer({
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

  ColumnOrderings<String> get providerConnectionId => $composableBuilder(
    column: $table.providerConnectionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasoningEffort => $composableBuilder(
    column: $table.reasoningEffort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permissionMode => $composableBuilder(
    column: $table.permissionMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeTurnId => $composableBuilder(
    column: $table.activeTurnId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
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

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AgentsTableAnnotationComposer
    extends Composer<_$CoderDatabase, $AgentsTable> {
  $$AgentsTableAnnotationComposer({
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

  GeneratedColumn<String> get providerConnectionId => $composableBuilder(
    column: $table.providerConnectionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get reasoningEffort => $composableBuilder(
    column: $table.reasoningEffort,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get permissionMode => $composableBuilder(
    column: $table.permissionMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activeTurnId => $composableBuilder(
    column: $table.activeTurnId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> turnsRefs<T extends Object>(
    Expression<T> Function($$TurnsTableAnnotationComposer a) f,
  ) {
    final $$TurnsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.turns,
      getReferencedColumn: (t) => t.agentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnsTableAnnotationComposer(
            $db: $db,
            $table: $db.turns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> timelineEventsRefs<T extends Object>(
    Expression<T> Function($$TimelineEventsTableAnnotationComposer a) f,
  ) {
    final $$TimelineEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timelineEvents,
      getReferencedColumn: (t) => t.agentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimelineEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.timelineEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> approvalRequestsRefs<T extends Object>(
    Expression<T> Function($$ApprovalRequestsTableAnnotationComposer a) f,
  ) {
    final $$ApprovalRequestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.approvalRequests,
      getReferencedColumn: (t) => t.agentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ApprovalRequestsTableAnnotationComposer(
            $db: $db,
            $table: $db.approvalRequests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> providerStatesRefs<T extends Object>(
    Expression<T> Function($$ProviderStatesTableAnnotationComposer a) f,
  ) {
    final $$ProviderStatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.providerStates,
      getReferencedColumn: (t) => t.agentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderStatesTableAnnotationComposer(
            $db: $db,
            $table: $db.providerStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AgentsTableTableManager
    extends
        RootTableManager<
          _$CoderDatabase,
          $AgentsTable,
          Agent,
          $$AgentsTableFilterComposer,
          $$AgentsTableOrderingComposer,
          $$AgentsTableAnnotationComposer,
          $$AgentsTableCreateCompanionBuilder,
          $$AgentsTableUpdateCompanionBuilder,
          (Agent, $$AgentsTableReferences),
          Agent,
          PrefetchHooks Function({
            bool workspaceId,
            bool turnsRefs,
            bool timelineEventsRefs,
            bool approvalRequestsRefs,
            bool providerStatesRefs,
          })
        > {
  $$AgentsTableTableManager(_$CoderDatabase db, $AgentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> providerConnectionId = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String> reasoningEffort = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> permissionMode = const Value.absent(),
                Value<String?> activeTurnId = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentsCompanion(
                id: id,
                workspaceId: workspaceId,
                title: title,
                providerConnectionId: providerConnectionId,
                model: model,
                reasoningEffort: reasoningEffort,
                status: status,
                permissionMode: permissionMode,
                activeTurnId: activeTurnId,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String title,
                required String providerConnectionId,
                required String model,
                Value<String> reasoningEffort = const Value.absent(),
                required String status,
                required String permissionMode,
                Value<String?> activeTurnId = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AgentsCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                title: title,
                providerConnectionId: providerConnectionId,
                model: model,
                reasoningEffort: reasoningEffort,
                status: status,
                permissionMode: permissionMode,
                activeTurnId: activeTurnId,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$AgentsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                workspaceId = false,
                turnsRefs = false,
                timelineEventsRefs = false,
                approvalRequestsRefs = false,
                providerStatesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (turnsRefs) db.turns,
                    if (timelineEventsRefs) db.timelineEvents,
                    if (approvalRequestsRefs) db.approvalRequests,
                    if (providerStatesRefs) db.providerStates,
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
                        if (workspaceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workspaceId,
                                    referencedTable: $$AgentsTableReferences
                                        ._workspaceIdTable(db),
                                    referencedColumn: $$AgentsTableReferences
                                        ._workspaceIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (turnsRefs)
                        await $_getPrefetchedData<Agent, $AgentsTable, Turn>(
                          currentTable: table,
                          referencedTable: $$AgentsTableReferences
                              ._turnsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AgentsTableReferences(db, table, p0).turnsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.agentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (timelineEventsRefs)
                        await $_getPrefetchedData<
                          Agent,
                          $AgentsTable,
                          TimelineEvent
                        >(
                          currentTable: table,
                          referencedTable: $$AgentsTableReferences
                              ._timelineEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AgentsTableReferences(
                                db,
                                table,
                                p0,
                              ).timelineEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.agentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (approvalRequestsRefs)
                        await $_getPrefetchedData<
                          Agent,
                          $AgentsTable,
                          ApprovalRequest
                        >(
                          currentTable: table,
                          referencedTable: $$AgentsTableReferences
                              ._approvalRequestsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AgentsTableReferences(
                                db,
                                table,
                                p0,
                              ).approvalRequestsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.agentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (providerStatesRefs)
                        await $_getPrefetchedData<
                          Agent,
                          $AgentsTable,
                          ProviderState
                        >(
                          currentTable: table,
                          referencedTable: $$AgentsTableReferences
                              ._providerStatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AgentsTableReferences(
                                db,
                                table,
                                p0,
                              ).providerStatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.agentId == item.id,
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

typedef $$AgentsTableProcessedTableManager =
    ProcessedTableManager<
      _$CoderDatabase,
      $AgentsTable,
      Agent,
      $$AgentsTableFilterComposer,
      $$AgentsTableOrderingComposer,
      $$AgentsTableAnnotationComposer,
      $$AgentsTableCreateCompanionBuilder,
      $$AgentsTableUpdateCompanionBuilder,
      (Agent, $$AgentsTableReferences),
      Agent,
      PrefetchHooks Function({
        bool workspaceId,
        bool turnsRefs,
        bool timelineEventsRefs,
        bool approvalRequestsRefs,
        bool providerStatesRefs,
      })
    >;
typedef $$TurnsTableCreateCompanionBuilder =
    TurnsCompanion Function({
      required String id,
      required String agentId,
      required String prompt,
      required String status,
      Value<String?> error,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$TurnsTableUpdateCompanionBuilder =
    TurnsCompanion Function({
      Value<String> id,
      Value<String> agentId,
      Value<String> prompt,
      Value<String> status,
      Value<String?> error,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$TurnsTableReferences
    extends BaseReferences<_$CoderDatabase, $TurnsTable, Turn> {
  $$TurnsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AgentsTable _agentIdTable(_$CoderDatabase db) =>
      db.agents.createAlias('turns__agent_id__agents__id');

  $$AgentsTableProcessedTableManager get agentId {
    final $_column = $_itemColumn<String>('agent_id')!;

    final manager = $$AgentsTableTableManager(
      $_db,
      $_db.agents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_agentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ApprovalRequestsTable, List<ApprovalRequest>>
  _approvalRequestsRefsTable(_$CoderDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.approvalRequests,
        aliasName: 'turns__id__approval_requests__turn_id',
      );

  $$ApprovalRequestsTableProcessedTableManager get approvalRequestsRefs {
    final manager = $$ApprovalRequestsTableTableManager(
      $_db,
      $_db.approvalRequests,
    ).filter((f) => f.turnId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _approvalRequestsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TurnsTableFilterComposer
    extends Composer<_$CoderDatabase, $TurnsTable> {
  $$TurnsTableFilterComposer({
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

  ColumnFilters<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
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

  $$AgentsTableFilterComposer get agentId {
    final $$AgentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agentId,
      referencedTable: $db.agents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentsTableFilterComposer(
            $db: $db,
            $table: $db.agents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> approvalRequestsRefs(
    Expression<bool> Function($$ApprovalRequestsTableFilterComposer f) f,
  ) {
    final $$ApprovalRequestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.approvalRequests,
      getReferencedColumn: (t) => t.turnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ApprovalRequestsTableFilterComposer(
            $db: $db,
            $table: $db.approvalRequests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TurnsTableOrderingComposer
    extends Composer<_$CoderDatabase, $TurnsTable> {
  $$TurnsTableOrderingComposer({
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

  ColumnOrderings<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
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

  $$AgentsTableOrderingComposer get agentId {
    final $$AgentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agentId,
      referencedTable: $db.agents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentsTableOrderingComposer(
            $db: $db,
            $table: $db.agents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TurnsTableAnnotationComposer
    extends Composer<_$CoderDatabase, $TurnsTable> {
  $$TurnsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AgentsTableAnnotationComposer get agentId {
    final $$AgentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agentId,
      referencedTable: $db.agents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentsTableAnnotationComposer(
            $db: $db,
            $table: $db.agents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> approvalRequestsRefs<T extends Object>(
    Expression<T> Function($$ApprovalRequestsTableAnnotationComposer a) f,
  ) {
    final $$ApprovalRequestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.approvalRequests,
      getReferencedColumn: (t) => t.turnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ApprovalRequestsTableAnnotationComposer(
            $db: $db,
            $table: $db.approvalRequests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TurnsTableTableManager
    extends
        RootTableManager<
          _$CoderDatabase,
          $TurnsTable,
          Turn,
          $$TurnsTableFilterComposer,
          $$TurnsTableOrderingComposer,
          $$TurnsTableAnnotationComposer,
          $$TurnsTableCreateCompanionBuilder,
          $$TurnsTableUpdateCompanionBuilder,
          (Turn, $$TurnsTableReferences),
          Turn,
          PrefetchHooks Function({bool agentId, bool approvalRequestsRefs})
        > {
  $$TurnsTableTableManager(_$CoderDatabase db, $TurnsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TurnsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TurnsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TurnsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> agentId = const Value.absent(),
                Value<String> prompt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TurnsCompanion(
                id: id,
                agentId: agentId,
                prompt: prompt,
                status: status,
                error: error,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String agentId,
                required String prompt,
                required String status,
                Value<String?> error = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TurnsCompanion.insert(
                id: id,
                agentId: agentId,
                prompt: prompt,
                status: status,
                error: error,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TurnsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({agentId = false, approvalRequestsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (approvalRequestsRefs) db.approvalRequests,
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
                        if (agentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.agentId,
                                    referencedTable: $$TurnsTableReferences
                                        ._agentIdTable(db),
                                    referencedColumn: $$TurnsTableReferences
                                        ._agentIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (approvalRequestsRefs)
                        await $_getPrefetchedData<
                          Turn,
                          $TurnsTable,
                          ApprovalRequest
                        >(
                          currentTable: table,
                          referencedTable: $$TurnsTableReferences
                              ._approvalRequestsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TurnsTableReferences(
                                db,
                                table,
                                p0,
                              ).approvalRequestsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.turnId == item.id,
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

typedef $$TurnsTableProcessedTableManager =
    ProcessedTableManager<
      _$CoderDatabase,
      $TurnsTable,
      Turn,
      $$TurnsTableFilterComposer,
      $$TurnsTableOrderingComposer,
      $$TurnsTableAnnotationComposer,
      $$TurnsTableCreateCompanionBuilder,
      $$TurnsTableUpdateCompanionBuilder,
      (Turn, $$TurnsTableReferences),
      Turn,
      PrefetchHooks Function({bool agentId, bool approvalRequestsRefs})
    >;
typedef $$TimelineEventsTableCreateCompanionBuilder =
    TimelineEventsCompanion Function({
      required String agentId,
      required int sequence,
      Value<String?> turnId,
      required String type,
      required String dataJson,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$TimelineEventsTableUpdateCompanionBuilder =
    TimelineEventsCompanion Function({
      Value<String> agentId,
      Value<int> sequence,
      Value<String?> turnId,
      Value<String> type,
      Value<String> dataJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$TimelineEventsTableReferences
    extends
        BaseReferences<_$CoderDatabase, $TimelineEventsTable, TimelineEvent> {
  $$TimelineEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AgentsTable _agentIdTable(_$CoderDatabase db) =>
      db.agents.createAlias('timeline_events__agent_id__agents__id');

  $$AgentsTableProcessedTableManager get agentId {
    final $_column = $_itemColumn<String>('agent_id')!;

    final manager = $$AgentsTableTableManager(
      $_db,
      $_db.agents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_agentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TimelineEventsTableFilterComposer
    extends Composer<_$CoderDatabase, $TimelineEventsTable> {
  $$TimelineEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get turnId => $composableBuilder(
    column: $table.turnId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AgentsTableFilterComposer get agentId {
    final $$AgentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agentId,
      referencedTable: $db.agents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentsTableFilterComposer(
            $db: $db,
            $table: $db.agents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimelineEventsTableOrderingComposer
    extends Composer<_$CoderDatabase, $TimelineEventsTable> {
  $$TimelineEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get turnId => $composableBuilder(
    column: $table.turnId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AgentsTableOrderingComposer get agentId {
    final $$AgentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agentId,
      referencedTable: $db.agents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentsTableOrderingComposer(
            $db: $db,
            $table: $db.agents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimelineEventsTableAnnotationComposer
    extends Composer<_$CoderDatabase, $TimelineEventsTable> {
  $$TimelineEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get turnId =>
      $composableBuilder(column: $table.turnId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AgentsTableAnnotationComposer get agentId {
    final $$AgentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agentId,
      referencedTable: $db.agents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentsTableAnnotationComposer(
            $db: $db,
            $table: $db.agents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimelineEventsTableTableManager
    extends
        RootTableManager<
          _$CoderDatabase,
          $TimelineEventsTable,
          TimelineEvent,
          $$TimelineEventsTableFilterComposer,
          $$TimelineEventsTableOrderingComposer,
          $$TimelineEventsTableAnnotationComposer,
          $$TimelineEventsTableCreateCompanionBuilder,
          $$TimelineEventsTableUpdateCompanionBuilder,
          (TimelineEvent, $$TimelineEventsTableReferences),
          TimelineEvent,
          PrefetchHooks Function({bool agentId})
        > {
  $$TimelineEventsTableTableManager(
    _$CoderDatabase db,
    $TimelineEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimelineEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimelineEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimelineEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> agentId = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<String?> turnId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimelineEventsCompanion(
                agentId: agentId,
                sequence: sequence,
                turnId: turnId,
                type: type,
                dataJson: dataJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String agentId,
                required int sequence,
                Value<String?> turnId = const Value.absent(),
                required String type,
                required String dataJson,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TimelineEventsCompanion.insert(
                agentId: agentId,
                sequence: sequence,
                turnId: turnId,
                type: type,
                dataJson: dataJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TimelineEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({agentId = false}) {
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
                    if (agentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.agentId,
                                referencedTable: $$TimelineEventsTableReferences
                                    ._agentIdTable(db),
                                referencedColumn:
                                    $$TimelineEventsTableReferences
                                        ._agentIdTable(db)
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

typedef $$TimelineEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$CoderDatabase,
      $TimelineEventsTable,
      TimelineEvent,
      $$TimelineEventsTableFilterComposer,
      $$TimelineEventsTableOrderingComposer,
      $$TimelineEventsTableAnnotationComposer,
      $$TimelineEventsTableCreateCompanionBuilder,
      $$TimelineEventsTableUpdateCompanionBuilder,
      (TimelineEvent, $$TimelineEventsTableReferences),
      TimelineEvent,
      PrefetchHooks Function({bool agentId})
    >;
typedef $$ApprovalRequestsTableCreateCompanionBuilder =
    ApprovalRequestsCompanion Function({
      required String id,
      required String agentId,
      required String turnId,
      required String toolCallId,
      required String toolName,
      required String risk,
      required String argumentsJson,
      Value<String?> preview,
      required String status,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ApprovalRequestsTableUpdateCompanionBuilder =
    ApprovalRequestsCompanion Function({
      Value<String> id,
      Value<String> agentId,
      Value<String> turnId,
      Value<String> toolCallId,
      Value<String> toolName,
      Value<String> risk,
      Value<String> argumentsJson,
      Value<String?> preview,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ApprovalRequestsTableReferences
    extends
        BaseReferences<
          _$CoderDatabase,
          $ApprovalRequestsTable,
          ApprovalRequest
        > {
  $$ApprovalRequestsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AgentsTable _agentIdTable(_$CoderDatabase db) =>
      db.agents.createAlias('approval_requests__agent_id__agents__id');

  $$AgentsTableProcessedTableManager get agentId {
    final $_column = $_itemColumn<String>('agent_id')!;

    final manager = $$AgentsTableTableManager(
      $_db,
      $_db.agents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_agentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TurnsTable _turnIdTable(_$CoderDatabase db) =>
      db.turns.createAlias('approval_requests__turn_id__turns__id');

  $$TurnsTableProcessedTableManager get turnId {
    final $_column = $_itemColumn<String>('turn_id')!;

    final manager = $$TurnsTableTableManager(
      $_db,
      $_db.turns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_turnIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ApprovalRequestsTableFilterComposer
    extends Composer<_$CoderDatabase, $ApprovalRequestsTable> {
  $$ApprovalRequestsTableFilterComposer({
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

  ColumnFilters<String> get toolCallId => $composableBuilder(
    column: $table.toolCallId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toolName => $composableBuilder(
    column: $table.toolName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get risk => $composableBuilder(
    column: $table.risk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get argumentsJson => $composableBuilder(
    column: $table.argumentsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preview => $composableBuilder(
    column: $table.preview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AgentsTableFilterComposer get agentId {
    final $$AgentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agentId,
      referencedTable: $db.agents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentsTableFilterComposer(
            $db: $db,
            $table: $db.agents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TurnsTableFilterComposer get turnId {
    final $$TurnsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.turnId,
      referencedTable: $db.turns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnsTableFilterComposer(
            $db: $db,
            $table: $db.turns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ApprovalRequestsTableOrderingComposer
    extends Composer<_$CoderDatabase, $ApprovalRequestsTable> {
  $$ApprovalRequestsTableOrderingComposer({
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

  ColumnOrderings<String> get toolCallId => $composableBuilder(
    column: $table.toolCallId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toolName => $composableBuilder(
    column: $table.toolName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get risk => $composableBuilder(
    column: $table.risk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get argumentsJson => $composableBuilder(
    column: $table.argumentsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preview => $composableBuilder(
    column: $table.preview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AgentsTableOrderingComposer get agentId {
    final $$AgentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agentId,
      referencedTable: $db.agents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentsTableOrderingComposer(
            $db: $db,
            $table: $db.agents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TurnsTableOrderingComposer get turnId {
    final $$TurnsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.turnId,
      referencedTable: $db.turns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnsTableOrderingComposer(
            $db: $db,
            $table: $db.turns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ApprovalRequestsTableAnnotationComposer
    extends Composer<_$CoderDatabase, $ApprovalRequestsTable> {
  $$ApprovalRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get toolCallId => $composableBuilder(
    column: $table.toolCallId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toolName =>
      $composableBuilder(column: $table.toolName, builder: (column) => column);

  GeneratedColumn<String> get risk =>
      $composableBuilder(column: $table.risk, builder: (column) => column);

  GeneratedColumn<String> get argumentsJson => $composableBuilder(
    column: $table.argumentsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preview =>
      $composableBuilder(column: $table.preview, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AgentsTableAnnotationComposer get agentId {
    final $$AgentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agentId,
      referencedTable: $db.agents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentsTableAnnotationComposer(
            $db: $db,
            $table: $db.agents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TurnsTableAnnotationComposer get turnId {
    final $$TurnsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.turnId,
      referencedTable: $db.turns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnsTableAnnotationComposer(
            $db: $db,
            $table: $db.turns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ApprovalRequestsTableTableManager
    extends
        RootTableManager<
          _$CoderDatabase,
          $ApprovalRequestsTable,
          ApprovalRequest,
          $$ApprovalRequestsTableFilterComposer,
          $$ApprovalRequestsTableOrderingComposer,
          $$ApprovalRequestsTableAnnotationComposer,
          $$ApprovalRequestsTableCreateCompanionBuilder,
          $$ApprovalRequestsTableUpdateCompanionBuilder,
          (ApprovalRequest, $$ApprovalRequestsTableReferences),
          ApprovalRequest,
          PrefetchHooks Function({bool agentId, bool turnId})
        > {
  $$ApprovalRequestsTableTableManager(
    _$CoderDatabase db,
    $ApprovalRequestsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApprovalRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApprovalRequestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ApprovalRequestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> agentId = const Value.absent(),
                Value<String> turnId = const Value.absent(),
                Value<String> toolCallId = const Value.absent(),
                Value<String> toolName = const Value.absent(),
                Value<String> risk = const Value.absent(),
                Value<String> argumentsJson = const Value.absent(),
                Value<String?> preview = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApprovalRequestsCompanion(
                id: id,
                agentId: agentId,
                turnId: turnId,
                toolCallId: toolCallId,
                toolName: toolName,
                risk: risk,
                argumentsJson: argumentsJson,
                preview: preview,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String agentId,
                required String turnId,
                required String toolCallId,
                required String toolName,
                required String risk,
                required String argumentsJson,
                Value<String?> preview = const Value.absent(),
                required String status,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ApprovalRequestsCompanion.insert(
                id: id,
                agentId: agentId,
                turnId: turnId,
                toolCallId: toolCallId,
                toolName: toolName,
                risk: risk,
                argumentsJson: argumentsJson,
                preview: preview,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ApprovalRequestsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({agentId = false, turnId = false}) {
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
                    if (agentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.agentId,
                                referencedTable:
                                    $$ApprovalRequestsTableReferences
                                        ._agentIdTable(db),
                                referencedColumn:
                                    $$ApprovalRequestsTableReferences
                                        ._agentIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (turnId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.turnId,
                                referencedTable:
                                    $$ApprovalRequestsTableReferences
                                        ._turnIdTable(db),
                                referencedColumn:
                                    $$ApprovalRequestsTableReferences
                                        ._turnIdTable(db)
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

typedef $$ApprovalRequestsTableProcessedTableManager =
    ProcessedTableManager<
      _$CoderDatabase,
      $ApprovalRequestsTable,
      ApprovalRequest,
      $$ApprovalRequestsTableFilterComposer,
      $$ApprovalRequestsTableOrderingComposer,
      $$ApprovalRequestsTableAnnotationComposer,
      $$ApprovalRequestsTableCreateCompanionBuilder,
      $$ApprovalRequestsTableUpdateCompanionBuilder,
      (ApprovalRequest, $$ApprovalRequestsTableReferences),
      ApprovalRequest,
      PrefetchHooks Function({bool agentId, bool turnId})
    >;
typedef $$ProviderStatesTableCreateCompanionBuilder =
    ProviderStatesCompanion Function({
      required String agentId,
      required int ordinal,
      required String itemJson,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ProviderStatesTableUpdateCompanionBuilder =
    ProviderStatesCompanion Function({
      Value<String> agentId,
      Value<int> ordinal,
      Value<String> itemJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ProviderStatesTableReferences
    extends
        BaseReferences<_$CoderDatabase, $ProviderStatesTable, ProviderState> {
  $$ProviderStatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AgentsTable _agentIdTable(_$CoderDatabase db) =>
      db.agents.createAlias('provider_states__agent_id__agents__id');

  $$AgentsTableProcessedTableManager get agentId {
    final $_column = $_itemColumn<String>('agent_id')!;

    final manager = $$AgentsTableTableManager(
      $_db,
      $_db.agents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_agentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProviderStatesTableFilterComposer
    extends Composer<_$CoderDatabase, $ProviderStatesTable> {
  $$ProviderStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemJson => $composableBuilder(
    column: $table.itemJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AgentsTableFilterComposer get agentId {
    final $$AgentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agentId,
      referencedTable: $db.agents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentsTableFilterComposer(
            $db: $db,
            $table: $db.agents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProviderStatesTableOrderingComposer
    extends Composer<_$CoderDatabase, $ProviderStatesTable> {
  $$ProviderStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemJson => $composableBuilder(
    column: $table.itemJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AgentsTableOrderingComposer get agentId {
    final $$AgentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agentId,
      referencedTable: $db.agents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentsTableOrderingComposer(
            $db: $db,
            $table: $db.agents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProviderStatesTableAnnotationComposer
    extends Composer<_$CoderDatabase, $ProviderStatesTable> {
  $$ProviderStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ordinal =>
      $composableBuilder(column: $table.ordinal, builder: (column) => column);

  GeneratedColumn<String> get itemJson =>
      $composableBuilder(column: $table.itemJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AgentsTableAnnotationComposer get agentId {
    final $$AgentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agentId,
      referencedTable: $db.agents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentsTableAnnotationComposer(
            $db: $db,
            $table: $db.agents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProviderStatesTableTableManager
    extends
        RootTableManager<
          _$CoderDatabase,
          $ProviderStatesTable,
          ProviderState,
          $$ProviderStatesTableFilterComposer,
          $$ProviderStatesTableOrderingComposer,
          $$ProviderStatesTableAnnotationComposer,
          $$ProviderStatesTableCreateCompanionBuilder,
          $$ProviderStatesTableUpdateCompanionBuilder,
          (ProviderState, $$ProviderStatesTableReferences),
          ProviderState,
          PrefetchHooks Function({bool agentId})
        > {
  $$ProviderStatesTableTableManager(
    _$CoderDatabase db,
    $ProviderStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProviderStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProviderStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> agentId = const Value.absent(),
                Value<int> ordinal = const Value.absent(),
                Value<String> itemJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderStatesCompanion(
                agentId: agentId,
                ordinal: ordinal,
                itemJson: itemJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String agentId,
                required int ordinal,
                required String itemJson,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ProviderStatesCompanion.insert(
                agentId: agentId,
                ordinal: ordinal,
                itemJson: itemJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProviderStatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({agentId = false}) {
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
                    if (agentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.agentId,
                                referencedTable: $$ProviderStatesTableReferences
                                    ._agentIdTable(db),
                                referencedColumn:
                                    $$ProviderStatesTableReferences
                                        ._agentIdTable(db)
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

typedef $$ProviderStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$CoderDatabase,
      $ProviderStatesTable,
      ProviderState,
      $$ProviderStatesTableFilterComposer,
      $$ProviderStatesTableOrderingComposer,
      $$ProviderStatesTableAnnotationComposer,
      $$ProviderStatesTableCreateCompanionBuilder,
      $$ProviderStatesTableUpdateCompanionBuilder,
      (ProviderState, $$ProviderStatesTableReferences),
      ProviderState,
      PrefetchHooks Function({bool agentId})
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$CoderDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
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

class $$SettingsTableOrderingComposer
    extends Composer<_$CoderDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
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

class $$SettingsTableAnnotationComposer
    extends Composer<_$CoderDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
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

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$CoderDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$CoderDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$CoderDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
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

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$CoderDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$CoderDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$ProviderConnectionsTableCreateCompanionBuilder =
    ProviderConnectionsCompanion Function({
      required String id,
      required String definitionId,
      required String displayName,
      required String status,
      required String authKind,
      required String credentialOrigin,
      Value<bool> isDefault,
      Value<String?> defaultModelId,
      Value<String?> error,
      Value<String?> customConfigJson,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ProviderConnectionsTableUpdateCompanionBuilder =
    ProviderConnectionsCompanion Function({
      Value<String> id,
      Value<String> definitionId,
      Value<String> displayName,
      Value<String> status,
      Value<String> authKind,
      Value<String> credentialOrigin,
      Value<bool> isDefault,
      Value<String?> defaultModelId,
      Value<String?> error,
      Value<String?> customConfigJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ProviderConnectionsTableReferences
    extends
        BaseReferences<
          _$CoderDatabase,
          $ProviderConnectionsTable,
          ProviderConnection
        > {
  $$ProviderConnectionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ProviderModelsTable, List<ProviderModel>>
  _providerModelsRefsTable(_$CoderDatabase db) => MultiTypedResultKey.fromTable(
    db.providerModels,
    aliasName: 'provider_connections__id__provider_models__connection_id',
  );

  $$ProviderModelsTableProcessedTableManager get providerModelsRefs {
    final manager = $$ProviderModelsTableTableManager(
      $_db,
      $_db.providerModels,
    ).filter((f) => f.connectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_providerModelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProviderConnectionsTableFilterComposer
    extends Composer<_$CoderDatabase, $ProviderConnectionsTable> {
  $$ProviderConnectionsTableFilterComposer({
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

  ColumnFilters<String> get definitionId => $composableBuilder(
    column: $table.definitionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authKind => $composableBuilder(
    column: $table.authKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credentialOrigin => $composableBuilder(
    column: $table.credentialOrigin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultModelId => $composableBuilder(
    column: $table.defaultModelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customConfigJson => $composableBuilder(
    column: $table.customConfigJson,
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

  Expression<bool> providerModelsRefs(
    Expression<bool> Function($$ProviderModelsTableFilterComposer f) f,
  ) {
    final $$ProviderModelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.providerModels,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderModelsTableFilterComposer(
            $db: $db,
            $table: $db.providerModels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProviderConnectionsTableOrderingComposer
    extends Composer<_$CoderDatabase, $ProviderConnectionsTable> {
  $$ProviderConnectionsTableOrderingComposer({
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

  ColumnOrderings<String> get definitionId => $composableBuilder(
    column: $table.definitionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authKind => $composableBuilder(
    column: $table.authKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credentialOrigin => $composableBuilder(
    column: $table.credentialOrigin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultModelId => $composableBuilder(
    column: $table.defaultModelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customConfigJson => $composableBuilder(
    column: $table.customConfigJson,
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
}

class $$ProviderConnectionsTableAnnotationComposer
    extends Composer<_$CoderDatabase, $ProviderConnectionsTable> {
  $$ProviderConnectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get definitionId => $composableBuilder(
    column: $table.definitionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get authKind =>
      $composableBuilder(column: $table.authKind, builder: (column) => column);

  GeneratedColumn<String> get credentialOrigin => $composableBuilder(
    column: $table.credentialOrigin,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<String> get defaultModelId => $composableBuilder(
    column: $table.defaultModelId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<String> get customConfigJson => $composableBuilder(
    column: $table.customConfigJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> providerModelsRefs<T extends Object>(
    Expression<T> Function($$ProviderModelsTableAnnotationComposer a) f,
  ) {
    final $$ProviderModelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.providerModels,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderModelsTableAnnotationComposer(
            $db: $db,
            $table: $db.providerModels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProviderConnectionsTableTableManager
    extends
        RootTableManager<
          _$CoderDatabase,
          $ProviderConnectionsTable,
          ProviderConnection,
          $$ProviderConnectionsTableFilterComposer,
          $$ProviderConnectionsTableOrderingComposer,
          $$ProviderConnectionsTableAnnotationComposer,
          $$ProviderConnectionsTableCreateCompanionBuilder,
          $$ProviderConnectionsTableUpdateCompanionBuilder,
          (ProviderConnection, $$ProviderConnectionsTableReferences),
          ProviderConnection,
          PrefetchHooks Function({bool providerModelsRefs})
        > {
  $$ProviderConnectionsTableTableManager(
    _$CoderDatabase db,
    $ProviderConnectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderConnectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProviderConnectionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProviderConnectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> definitionId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> authKind = const Value.absent(),
                Value<String> credentialOrigin = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<String?> defaultModelId = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String?> customConfigJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderConnectionsCompanion(
                id: id,
                definitionId: definitionId,
                displayName: displayName,
                status: status,
                authKind: authKind,
                credentialOrigin: credentialOrigin,
                isDefault: isDefault,
                defaultModelId: defaultModelId,
                error: error,
                customConfigJson: customConfigJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String definitionId,
                required String displayName,
                required String status,
                required String authKind,
                required String credentialOrigin,
                Value<bool> isDefault = const Value.absent(),
                Value<String?> defaultModelId = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String?> customConfigJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProviderConnectionsCompanion.insert(
                id: id,
                definitionId: definitionId,
                displayName: displayName,
                status: status,
                authKind: authKind,
                credentialOrigin: credentialOrigin,
                isDefault: isDefault,
                defaultModelId: defaultModelId,
                error: error,
                customConfigJson: customConfigJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProviderConnectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerModelsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (providerModelsRefs) db.providerModels,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (providerModelsRefs)
                    await $_getPrefetchedData<
                      ProviderConnection,
                      $ProviderConnectionsTable,
                      ProviderModel
                    >(
                      currentTable: table,
                      referencedTable: $$ProviderConnectionsTableReferences
                          ._providerModelsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ProviderConnectionsTableReferences(
                            db,
                            table,
                            p0,
                          ).providerModelsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.connectionId == item.id,
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

typedef $$ProviderConnectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$CoderDatabase,
      $ProviderConnectionsTable,
      ProviderConnection,
      $$ProviderConnectionsTableFilterComposer,
      $$ProviderConnectionsTableOrderingComposer,
      $$ProviderConnectionsTableAnnotationComposer,
      $$ProviderConnectionsTableCreateCompanionBuilder,
      $$ProviderConnectionsTableUpdateCompanionBuilder,
      (ProviderConnection, $$ProviderConnectionsTableReferences),
      ProviderConnection,
      PrefetchHooks Function({bool providerModelsRefs})
    >;
typedef $$ProviderModelsTableCreateCompanionBuilder =
    ProviderModelsCompanion Function({
      required String connectionId,
      required String modelId,
      required String label,
      required String source,
      required String capabilitiesJson,
      Value<String?> pricingJson,
      Value<String?> limitsJson,
      Value<String> diagnosticStatus,
      Value<DateTime?> verifiedAt,
      Value<String?> diagnosticError,
      Value<int> rowid,
    });
typedef $$ProviderModelsTableUpdateCompanionBuilder =
    ProviderModelsCompanion Function({
      Value<String> connectionId,
      Value<String> modelId,
      Value<String> label,
      Value<String> source,
      Value<String> capabilitiesJson,
      Value<String?> pricingJson,
      Value<String?> limitsJson,
      Value<String> diagnosticStatus,
      Value<DateTime?> verifiedAt,
      Value<String?> diagnosticError,
      Value<int> rowid,
    });

final class $$ProviderModelsTableReferences
    extends
        BaseReferences<_$CoderDatabase, $ProviderModelsTable, ProviderModel> {
  $$ProviderModelsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProviderConnectionsTable _connectionIdTable(_$CoderDatabase db) => db
      .providerConnections
      .createAlias('provider_models__connection_id__provider_connections__id');

  $$ProviderConnectionsTableProcessedTableManager get connectionId {
    final $_column = $_itemColumn<String>('connection_id')!;

    final manager = $$ProviderConnectionsTableTableManager(
      $_db,
      $_db.providerConnections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_connectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProviderModelsTableFilterComposer
    extends Composer<_$CoderDatabase, $ProviderModelsTable> {
  $$ProviderModelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get capabilitiesJson => $composableBuilder(
    column: $table.capabilitiesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pricingJson => $composableBuilder(
    column: $table.pricingJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get limitsJson => $composableBuilder(
    column: $table.limitsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get diagnosticStatus => $composableBuilder(
    column: $table.diagnosticStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get diagnosticError => $composableBuilder(
    column: $table.diagnosticError,
    builder: (column) => ColumnFilters(column),
  );

  $$ProviderConnectionsTableFilterComposer get connectionId {
    final $$ProviderConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.providerConnections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.providerConnections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProviderModelsTableOrderingComposer
    extends Composer<_$CoderDatabase, $ProviderModelsTable> {
  $$ProviderModelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get capabilitiesJson => $composableBuilder(
    column: $table.capabilitiesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pricingJson => $composableBuilder(
    column: $table.pricingJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get limitsJson => $composableBuilder(
    column: $table.limitsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get diagnosticStatus => $composableBuilder(
    column: $table.diagnosticStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get diagnosticError => $composableBuilder(
    column: $table.diagnosticError,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProviderConnectionsTableOrderingComposer get connectionId {
    final $$ProviderConnectionsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.connectionId,
          referencedTable: $db.providerConnections,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProviderConnectionsTableOrderingComposer(
                $db: $db,
                $table: $db.providerConnections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ProviderModelsTableAnnotationComposer
    extends Composer<_$CoderDatabase, $ProviderModelsTable> {
  $$ProviderModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get capabilitiesJson => $composableBuilder(
    column: $table.capabilitiesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pricingJson => $composableBuilder(
    column: $table.pricingJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get limitsJson => $composableBuilder(
    column: $table.limitsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get diagnosticStatus => $composableBuilder(
    column: $table.diagnosticStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get diagnosticError => $composableBuilder(
    column: $table.diagnosticError,
    builder: (column) => column,
  );

  $$ProviderConnectionsTableAnnotationComposer get connectionId {
    final $$ProviderConnectionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.connectionId,
          referencedTable: $db.providerConnections,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProviderConnectionsTableAnnotationComposer(
                $db: $db,
                $table: $db.providerConnections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ProviderModelsTableTableManager
    extends
        RootTableManager<
          _$CoderDatabase,
          $ProviderModelsTable,
          ProviderModel,
          $$ProviderModelsTableFilterComposer,
          $$ProviderModelsTableOrderingComposer,
          $$ProviderModelsTableAnnotationComposer,
          $$ProviderModelsTableCreateCompanionBuilder,
          $$ProviderModelsTableUpdateCompanionBuilder,
          (ProviderModel, $$ProviderModelsTableReferences),
          ProviderModel,
          PrefetchHooks Function({bool connectionId})
        > {
  $$ProviderModelsTableTableManager(
    _$CoderDatabase db,
    $ProviderModelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderModelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProviderModelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProviderModelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> connectionId = const Value.absent(),
                Value<String> modelId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> capabilitiesJson = const Value.absent(),
                Value<String?> pricingJson = const Value.absent(),
                Value<String?> limitsJson = const Value.absent(),
                Value<String> diagnosticStatus = const Value.absent(),
                Value<DateTime?> verifiedAt = const Value.absent(),
                Value<String?> diagnosticError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderModelsCompanion(
                connectionId: connectionId,
                modelId: modelId,
                label: label,
                source: source,
                capabilitiesJson: capabilitiesJson,
                pricingJson: pricingJson,
                limitsJson: limitsJson,
                diagnosticStatus: diagnosticStatus,
                verifiedAt: verifiedAt,
                diagnosticError: diagnosticError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String connectionId,
                required String modelId,
                required String label,
                required String source,
                required String capabilitiesJson,
                Value<String?> pricingJson = const Value.absent(),
                Value<String?> limitsJson = const Value.absent(),
                Value<String> diagnosticStatus = const Value.absent(),
                Value<DateTime?> verifiedAt = const Value.absent(),
                Value<String?> diagnosticError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderModelsCompanion.insert(
                connectionId: connectionId,
                modelId: modelId,
                label: label,
                source: source,
                capabilitiesJson: capabilitiesJson,
                pricingJson: pricingJson,
                limitsJson: limitsJson,
                diagnosticStatus: diagnosticStatus,
                verifiedAt: verifiedAt,
                diagnosticError: diagnosticError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProviderModelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({connectionId = false}) {
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
                    if (connectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.connectionId,
                                referencedTable: $$ProviderModelsTableReferences
                                    ._connectionIdTable(db),
                                referencedColumn:
                                    $$ProviderModelsTableReferences
                                        ._connectionIdTable(db)
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

typedef $$ProviderModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$CoderDatabase,
      $ProviderModelsTable,
      ProviderModel,
      $$ProviderModelsTableFilterComposer,
      $$ProviderModelsTableOrderingComposer,
      $$ProviderModelsTableAnnotationComposer,
      $$ProviderModelsTableCreateCompanionBuilder,
      $$ProviderModelsTableUpdateCompanionBuilder,
      (ProviderModel, $$ProviderModelsTableReferences),
      ProviderModel,
      PrefetchHooks Function({bool connectionId})
    >;

class $CoderDatabaseManager {
  final _$CoderDatabase _db;
  $CoderDatabaseManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db, _db.workspaces);
  $$AgentsTableTableManager get agents =>
      $$AgentsTableTableManager(_db, _db.agents);
  $$TurnsTableTableManager get turns =>
      $$TurnsTableTableManager(_db, _db.turns);
  $$TimelineEventsTableTableManager get timelineEvents =>
      $$TimelineEventsTableTableManager(_db, _db.timelineEvents);
  $$ApprovalRequestsTableTableManager get approvalRequests =>
      $$ApprovalRequestsTableTableManager(_db, _db.approvalRequests);
  $$ProviderStatesTableTableManager get providerStates =>
      $$ProviderStatesTableTableManager(_db, _db.providerStates);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$ProviderConnectionsTableTableManager get providerConnections =>
      $$ProviderConnectionsTableTableManager(_db, _db.providerConnections);
  $$ProviderModelsTableTableManager get providerModels =>
      $$ProviderModelsTableTableManager(_db, _db.providerModels);
}
