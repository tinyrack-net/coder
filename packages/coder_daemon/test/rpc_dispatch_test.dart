import 'package:coder_daemon/src/transport/rpc/rpc_dispatch.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('every authenticated RPC method has one feature owner', () {
    expect(
      daemonRpcMethodGroups.keys,
      <String>[
        'workspace',
        'agents',
        'mcp',
        'prompts',
        'sessions',
        'terminal',
        'providers',
      ],
    );
    expect(daemonRpcMethods.toSet(), hasLength(daemonRpcMethods.length));
    expect(
      daemonRpcMethodGroups['workspace'],
      containsAll(<String>[
        RpcMethod.workspaceCatalog,
        RpcMethod.worktreeCreate,
      ]),
    );
    expect(
      daemonRpcMethodGroups['sessions'],
      containsAll(<String>[
        RpcMethod.sessionCreate,
        RpcMethod.turnStart,
        RpcMethod.approvalResolve,
      ]),
    );
    expect(
      daemonRpcMethodGroups['providers'],
      containsAll(<String>[
        RpcMethod.providerCatalog,
        RpcMethod.providerCustomDelete,
      ]),
    );
  });
}
