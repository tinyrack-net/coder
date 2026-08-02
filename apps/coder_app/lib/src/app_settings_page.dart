import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Daemon-independent app settings and remote host management.
class AppSettingsPage extends ConsumerWidget {
  /// Creates the global application settings page.
  const AppSettingsPage({this.embedded = false, super.key});

  /// Whether the unified settings shell supplies navigation chrome.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hostRegistryControllerProvider);
    final supportsEmbedded = ref
        .read(appServicesProvider)
        .supportsEmbeddedDaemon;
    final body = state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('$error')),
      data: (registry) => _settingsBody(
        context,
        ref,
        registry,
        supportsEmbedded: supportsEmbedded,
      ),
    );
    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('앱 설정'),
      ),
      body: body,
    );
  }

  Widget _settingsBody(
    BuildContext context,
    WidgetRef ref,
    HostRegistryState registry, {
    required bool supportsEmbedded,
  }) => ListView(
    padding: const EdgeInsets.all(24),
    children: <Widget>[
      if (supportsEmbedded) ...<Widget>[
        Text(
          '로컬 실행',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: SwitchListTile(
            title: const Text('내장 daemon'),
            subtitle: const Text(
              '앱과 함께 시작하고 앱 종료 시 중지합니다. 시작 실패는 앱 사용을 막지 않습니다.',
            ),
            value: registry.settings.embeddedDaemonEnabled,
            onChanged: (enabled) => _toggleEmbedded(
              context,
              ref,
              currentlyEnabled: registry.settings.embeddedDaemonEnabled,
              enabled: enabled,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
      Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '원격 daemons',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          FilledButton.icon(
            onPressed: () => context.go('/settings/daemons/new'),
            icon: const Icon(Icons.add),
            label: const Text('원격 daemon 추가'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (registry.profiles.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('저장된 원격 daemon이 없습니다.'),
          ),
        ),
      for (final profile in registry.profiles)
        _RemoteHostCard(
          profile: profile,
          runtime: registry.runtimes[profile.id],
        ),
    ],
  );

  Future<void> _toggleEmbedded(
    BuildContext context,
    WidgetRef ref, {
    required bool currentlyEnabled,
    required bool enabled,
  }) async {
    if (currentlyEnabled && !enabled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('내장 daemon을 중지할까요?'),
          content: const Text(
            '이 앱이 소유한 daemon과 연결만 중지합니다. 원격 및 standalone daemon은 영향을 받지 않습니다.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('중지'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ref
        .read(hostRegistryControllerProvider.notifier)
        .setEmbeddedDaemonEnabled(enabled: enabled);
  }
}

class _RemoteHostCard extends ConsumerWidget {
  const _RemoteHostCard({required this.profile, required this.runtime});

  final RemoteDaemonProfile profile;
  final HostRuntimeSnapshot? runtime;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          ListTile(
            leading: Icon(_statusIcon(runtime?.status)),
            title: Text(profile.label),
            subtitle: Text(
              '${profile.websocketUri}\n${_statusText(runtime)}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              tooltip: '연결 편집',
              onPressed: () => context.go('/settings/daemons/${profile.id}'),
              icon: const Icon(Icons.edit_outlined),
            ),
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('앱 시작 시 자동 연결'),
            value: profile.autoConnect,
            onChanged: (enabled) => ref
                .read(hostRegistryControllerProvider.notifier)
                .setRemoteAutoConnect(profile.id, enabled: enabled),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton.icon(
                onPressed: () => ref
                    .read(hostRegistryControllerProvider.notifier)
                    .reconnect(profile.id),
                icon: const Icon(Icons.refresh),
                label: const Text('다시 연결'),
              ),
              if (runtime?.connected == true)
                TextButton.icon(
                  onPressed: () => context.go(
                    '/settings/providers?hostId=${profile.id}',
                  ),
                  icon: const Icon(Icons.hub_outlined),
                  label: const Text('Provider 설정'),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Add/edit form for one remote daemon profile.
class RemoteHostEditPage extends ConsumerStatefulWidget {
  /// Creates an add form when [hostId] is null, otherwise an edit form.
  const RemoteHostEditPage({this.hostId, super.key});

  /// Existing profile ID for edit mode.
  final String? hostId;

  @override
  ConsumerState<RemoteHostEditPage> createState() => _RemoteHostEditPageState();
}

class _RemoteHostEditPageState extends ConsumerState<RemoteHostEditPage> {
  final _label = TextEditingController();
  final _address = TextEditingController();
  final _token = TextEditingController();
  bool _autoConnect = true;
  bool _initialized = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _address.addListener(_addressChanged);
  }

  void _addressChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _address.removeListener(_addressChanged);
    _label.dispose();
    _address.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(hostRegistryControllerProvider).asData?.value;
    final existing = registry?.profiles
        .where((profile) => profile.id == widget.hostId)
        .firstOrNull;
    if (!_initialized && (widget.hostId == null || registry != null)) {
      _initialized = true;
      if (existing != null) {
        _label.text = existing.label;
        _address.text = existing.websocketUri.toString();
        _autoConnect = existing.autoConnect;
      }
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/settings/daemons'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(existing == null ? '원격 daemon 추가' : '원격 daemon 편집'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              TextField(
                key: const ValueKey<String>('remote-host-label'),
                controller: _label,
                decoration: const InputDecoration(
                  labelText: '이름',
                  hintText: 'Production daemon',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey<String>('remote-host-address'),
                controller: _address,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'WebSocket 주소',
                  hintText: 'wss://coder.example.com/ws',
                ),
              ),
              if (_isInsecureRemote(_address.text))
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '경고: 원격 ws:// 연결은 암호화되지 않습니다. reverse proxy에서 TLS를 종료한 wss:// 주소를 권장합니다.',
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey<String>('remote-host-token'),
                controller: _token,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: existing == null
                      ? 'Bearer token'
                      : '새 Bearer token (변경할 때만 입력)',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('앱 시작 시 자동 연결'),
                value: _autoConnect,
                onChanged: (value) => setState(() => _autoConnect = value),
              ),
              if (_error case final error?)
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (existing != null)
                    TextButton(
                      onPressed: _saving ? null : () => _delete(existing),
                      child: const Text('삭제'),
                    ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : () => _save(existing),
                    child: Text(_saving ? '저장 중…' : '저장'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(RemoteDaemonProfile? existing) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final controller = ref.read(hostRegistryControllerProvider.notifier);
      if (existing == null) {
        await controller.addRemote(
          label: _label.text,
          address: _address.text,
          bearerToken: _token.text,
          autoConnect: _autoConnect,
        );
      } else {
        await controller.updateRemote(
          profileId: existing.id,
          label: _label.text,
          address: _address.text,
          autoConnect: _autoConnect,
          replacementBearerToken: _token.text.trim().isEmpty
              ? null
              : _token.text,
        );
      }
      if (mounted) context.go('/settings/daemons');
    } on Exception catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(RemoteDaemonProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${profile.label}을 삭제할까요?'),
        content: const Text('연결과 저장된 bearer token도 이 기기에서 제거됩니다.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(hostRegistryControllerProvider.notifier)
        .removeRemote(profile.id);
    if (mounted) context.go('/');
  }
}

IconData _statusIcon(HostRuntimeStatus? status) => switch (status) {
  HostRuntimeStatus.online => Icons.check_circle_outline,
  HostRuntimeStatus.connecting || HostRuntimeStatus.reconnecting => Icons.sync,
  HostRuntimeStatus.offline => Icons.cloud_off_outlined,
  HostRuntimeStatus.conflict => Icons.call_split,
  HostRuntimeStatus.error => Icons.error_outline,
  HostRuntimeStatus.idle || null => Icons.pause_circle_outline,
};

String _statusText(HostRuntimeSnapshot? runtime) {
  if (runtime == null) return '대기 중';
  return switch (runtime.status) {
    HostRuntimeStatus.online => '온라인',
    HostRuntimeStatus.connecting => '연결 중',
    HostRuntimeStatus.reconnecting => '재연결 중',
    HostRuntimeStatus.offline => runtime.error ?? '오프라인',
    HostRuntimeStatus.error => runtime.error ?? '오류',
    HostRuntimeStatus.conflict => runtime.error ?? '중복 daemon',
    HostRuntimeStatus.idle => '자동 연결 꺼짐',
  };
}

bool _isInsecureRemote(String source) {
  final uri = Uri.tryParse(source.trim());
  if (uri == null || uri.scheme != 'ws') return false;
  return uri.host != 'localhost' &&
      uri.host != '127.0.0.1' &&
      uri.host != '::1';
}
