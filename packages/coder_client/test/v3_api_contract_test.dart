import 'package:coder_client/coder_client.dart';
import 'package:test/test.dart';

void main() {
  test('CoderApi exposes the v3 feature boundaries', () {
    final api = _ApiShapeProbe();

    expect(api.workspaces, isA<WorkspacesApi>());
    expect(api.sessions, isA<SessionsApi>());
    expect(api.agents, isA<AgentsApi>());
    expect(api.prompts, isA<PromptsApi>());
    expect(api.providers, isA<ProvidersApi>());
    expect(api.mcp, isA<McpApi>());
    expect(api.terminals, isA<TerminalsApi>());
    expect(api.attachments, isA<AttachmentsApi>());
  });
}

final class _ApiShapeProbe
    implements
        CoderApi,
        WorkspacesApi,
        SessionsApi,
        AgentsApi,
        PromptsApi,
        ProvidersApi,
        McpApi,
        TerminalsApi,
        AttachmentsApi {
  @override
  WorkspacesApi get workspaces => this;

  @override
  SessionsApi get sessions => this;

  @override
  AgentsApi get agents => this;

  @override
  PromptsApi get prompts => this;

  @override
  ProvidersApi get providers => this;

  @override
  McpApi get mcp => this;

  @override
  TerminalsApi get terminals => this;

  @override
  AttachmentsApi get attachments => this;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
