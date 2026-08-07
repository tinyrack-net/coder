import 'package:coder_daemon/src/features/providers/infrastructure/provider_service.dart';
import 'package:coder_daemon/src/shared/infrastructure/persistence/repositories.dart';
import 'package:coder_daemon/src/transport/rpc/binding.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Session preference mutations exposed to the daemon transport.
abstract interface class SessionSettingsPort {
  /// Applies an atomic nullable patch to one session.
  Future<SessionDto> updateSettings(
    String sessionId,
    SessionSettingsPatchDto patch,
  );

  /// Switches one session between planning and normal collaboration.
  Future<SessionDto> setMode(String sessionId, SessionMode mode);

  /// Sets or clears the reasoning effort inherited by future turns.
  Future<SessionDto> setReasoningEffort(
    String sessionId,
    String? reasoningEffort,
  );

  /// Sets or clears the permission override observed at tool boundaries.
  Future<SessionDto> setPermissionMode(
    String sessionId,
    PermissionMode? permissionMode,
  );

  /// Sets or clears the provider service tier used by future turns.
  Future<SessionDto> setServiceTier(String sessionId, String? serviceTier);

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
        patch.mode != null ||
        patch.hasModel ||
        patch.hasReasoningEffort ||
        patch.hasServiceTier;
    if (changesIdleSettings) _requireIdle(sessionId, 'settings');
    if (patch.hasModel && patch.model != null) {
      await _models.validateAgentModel(
        patch.model!.providerConnectionId,
        patch.model!.modelId,
      );
    }

    var session = (await _sessions.getById(sessionId))!;
    if (patch.mode != null) {
      session = await _sessions.updateMode(sessionId, patch.mode!);
    }
    if (patch.hasModel) {
      session = await _sessions.updateModel(sessionId, patch.model);
    }
    if (patch.hasReasoningEffort) {
      session = await _sessions.updateReasoningEffort(
        sessionId,
        patch.reasoningEffort,
      );
    }
    if (patch.hasPermissionMode) {
      session = await _sessions.updatePermissionMode(
        sessionId,
        patch.permissionMode,
      );
    }
    if (patch.hasServiceTier) {
      session = await _sessions.updateServiceTier(
        sessionId,
        patch.serviceTier,
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
  Future<SessionDto> setReasoningEffort(
    String sessionId,
    String? reasoningEffort,
  ) async {
    await _requireSession(sessionId);
    _requireIdle(sessionId, 'reasoning effort');
    return _emit(
      await _sessions.updateReasoningEffort(sessionId, reasoningEffort),
    );
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
  Future<SessionDto> setServiceTier(
    String sessionId,
    String? serviceTier,
  ) async {
    await _requireSession(sessionId);
    _requireIdle(sessionId, 'service tier');
    return _emit(await _sessions.updateServiceTier(sessionId, serviceTier));
  }

  @override
  Future<SessionDto> setModel(
    String sessionId,
    SessionModelSelectionDto? model,
  ) async {
    await _requireSession(sessionId);
    _requireIdle(sessionId, 'model');
    if (model != null) {
      await _models.validateAgentModel(
        model.providerConnectionId,
        model.modelId,
      );
    }
    return _emit(await _sessions.updateModel(sessionId, model));
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
