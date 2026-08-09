import 'package:daemon/src/features/providers/infrastructure/provider_service.dart';
import 'package:daemon/src/shared/infrastructure/persistence/repositories.dart';
import 'package:daemon/src/transport/rpc/binding.dart';
import 'package:protocol/protocol.dart';

/// Session preference mutations exposed to the daemon transport.
abstract interface class SessionSettingsPort {
  /// Applies an atomic nullable patch to one session.
  Future<SessionDto> updateSettings(
    String sessionId,
    SessionSettingsPatchDto patch,
  );

  /// Switches one session between planning and normal collaboration.
  Future<SessionDto> setMode(String sessionId, SessionMode mode);

  /// Sets or clears the permission override observed at tool boundaries.
  Future<SessionDto> setPermissionMode(
    String sessionId,
    PermissionMode? permissionMode,
  );

  /// Sets or clears the provider and model override used by future turns.
  Future<SessionDto> setModel(
    String sessionId,
    SessionModelSelectionDto? model,
  );
}

/// Applies session settings while enforcing live-turn constraints.
final class SessionSettingsService implements SessionSettingsPort {
  /// Creates the session settings application service.
  const SessionSettingsService({
    required SessionRepository sessions,
    required ProviderModelResolver models,
    required bool Function(String sessionId) hasActiveTurn,
    required void Function(OutboundNotification event) events,
  }) : this._(sessions, models, hasActiveTurn, events);

  const SessionSettingsService._(
    this._sessions,
    this._models,
    this._hasActiveTurn,
    this._events,
  );

  final SessionRepository _sessions;
  final ProviderModelResolver _models;
  final bool Function(String sessionId) _hasActiveTurn;
  final void Function(OutboundNotification event) _events;

  @override
  Future<SessionDto> updateSettings(
    String sessionId,
    SessionSettingsPatchDto patch,
  ) async {
    await _requireSession(sessionId);
    final changesIdleSettings =
        patch.mode != null || patch.hasModel || patch.hasModelControls;
    if (changesIdleSettings) _requireIdle(sessionId, 'settings');
    if (patch.hasModel && patch.model != null) {
      await _models.validateQualifiedModel(patch.model!.qualifiedModelId);
    }

    var session = (await _sessions.getById(sessionId))!;
    final targetModel = patch.hasModel ? patch.model : session.model;
    var targetControls = patch.hasModelControls
        ? patch.modelControls
        : session.modelControls;
    if (targetModel == null) {
      if (patch.hasModelControls && targetControls.isNotEmpty) {
        throw const FormatException(
          'Model controls require an explicit provider model.',
        );
      }
      targetControls = const <String, ModelControlValueDto>{};
    } else if (patch.hasModelControls) {
      await _models.validateQualifiedModelControls(
        targetModel.qualifiedModelId,
        targetControls,
      );
    } else if (patch.hasModel) {
      targetControls = await _models.retainValidQualifiedModelControls(
        targetModel.qualifiedModelId,
        targetControls,
      );
    }
    if (patch.mode != null) {
      session = await _sessions.updateMode(sessionId, patch.mode!);
    }
    if (patch.hasModel || patch.hasModelControls) {
      session = await _sessions.updateModelSettings(
        sessionId,
        hasModel: patch.hasModel,
        model: patch.model,
        modelControls: targetControls,
      );
    }
    if (patch.hasPermissionMode) {
      session = await _sessions.updatePermissionMode(
        sessionId,
        patch.permissionMode,
      );
    }
    return _emit(session);
  }

  @override
  Future<SessionDto> setMode(String sessionId, SessionMode mode) async {
    await _requireSession(sessionId);
    _requireIdle(sessionId, 'mode');
    return _emit(await _sessions.updateMode(sessionId, mode));
  }

  @override
  Future<SessionDto> setPermissionMode(
    String sessionId,
    PermissionMode? permissionMode,
  ) async {
    await _requireSession(sessionId);
    return _emit(
      await _sessions.updatePermissionMode(sessionId, permissionMode),
    );
  }

  @override
  Future<SessionDto> setModel(
    String sessionId,
    SessionModelSelectionDto? model,
  ) async {
    await _requireSession(sessionId);
    _requireIdle(sessionId, 'model');
    if (model != null) {
      await _models.validateQualifiedModel(model.qualifiedModelId);
    }
    final current = (await _sessions.getById(sessionId))!;
    final controls = model == null
        ? const <String, ModelControlValueDto>{}
        : await _models.retainValidQualifiedModelControls(
            model.qualifiedModelId,
            current.modelControls,
          );
    return _emit(
      await _sessions.updateModelSettings(
        sessionId,
        hasModel: true,
        model: model,
        modelControls: controls,
      ),
    );
  }

  Future<void> _requireSession(String sessionId) async {
    if (await _sessions.getById(sessionId) == null) {
      throw StateError('Session not found: $sessionId');
    }
  }

  void _requireIdle(String sessionId, String setting) {
    if (_hasActiveTurn(sessionId)) {
      throw StateError('Cannot change the $setting while a turn is running.');
    }
  }

  SessionDto _emit(SessionDto session) {
    _events(
      OutboundNotification(sessionsUpdatedNotification, session),
    );
    return session;
  }
}
