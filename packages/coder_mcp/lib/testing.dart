/// Test doubles exported to packages that consume the MCP client.
///
/// The scripted server used to exist once per consuming package, and the
/// copies had already drifted apart by one capability. One exported double
/// keeps every consumer testing against the same server behaviour.
library;

export 'src/testing/scripted_mcp_server.dart';
