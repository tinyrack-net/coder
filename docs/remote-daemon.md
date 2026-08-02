# Remote daemon and TLS proxy

Tinyrack Coder's daemon serves plain HTTP/WebSocket only. For a remote host,
keep the daemon on loopback and let an operator-managed reverse proxy provide
DNS, certificates, TLS policy, firewalling, and public reachability. The app
uses the operating system trust store for `wss://`; it does not offer a
self-signed-certificate or certificate-validation bypass.

Start a standalone daemon with explicit 256-bit secrets when reproducible
deployment credentials are required:

```sh
TINYRACK_CODER_LISTEN=127.0.0.1:7337 \
TINYRACK_CODER_TOKEN='<at-least-32-byte-bearer-secret>' \
TINYRACK_CODER_ADMIN_TOKEN='<separate-at-least-32-byte-admin-secret>' \
dart run packages/coder_daemon/bin/coder_daemon.dart
```

The bearer token grants ordinary coding access. The independent admin token
grants provider and credential mutation. Remote GUI profiles accept and store
only the bearer token, so a reverse proxy that makes its upstream peer appear as
loopback cannot accidentally elevate the client. The daemon ignores
`X-Forwarded-For` and other proxy identity headers.

## Caddy

Caddy forwards WebSocket upgrades and `Authorization` by default. This public
configuration explicitly removes any client-supplied admin header:

```caddyfile
coder.example.com {
  reverse_proxy 127.0.0.1:7337 {
    header_up -X-Tinyrack-Coder-Admin
  }
}
```

Register `wss://coder.example.com/ws` in the app and enter the bearer token.
Only a separately protected administrative proxy should preserve
`X-Tinyrack-Coder-Admin` when a trusted CLI workflow specifically needs it.

## Nginx

```nginx
map $http_upgrade $tinyrack_connection_upgrade {
  default upgrade;
  '' close;
}

server {
  listen 443 ssl;
  server_name coder.example.com;

  # ssl_certificate and TLS policy are operator-managed.

  location /ws {
    proxy_pass http://127.0.0.1:7337;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $tinyrack_connection_upgrade;
    proxy_set_header Authorization $http_authorization;
    proxy_set_header X-Tinyrack-Coder-Admin "";
  }
}
```

For a separately secured administrative endpoint, replace the empty admin
header with `$http_x_tinyrack_coder_admin`. Never synthesize an admin token from
an IP address or an identity header.

## Local files and development resets

Daemon bearer, admin, API-key, and OAuth credentials are stored atomically in
`credentials.json`. On POSIX systems the configuration directory is mode
`0700` and the file is mode `0600`; secrets are not stored in SQLite, protocol
payloads, or logs.

This repository is in active development and does not migrate older internal
credential formats. An existing version-2 `credentials.json` produces an
`incompatible_credentials` error with its exact path. Stop the daemon and
explicitly remove that file to reset it. An old `auth.json` is ignored and is
not deleted automatically; remove it manually after confirming it is no longer
needed.

Non-loopback `ws://` profiles remain available for trusted-network development,
but the UI warns that traffic and bearer credentials are unencrypted. Prefer
`wss://` for every remote connection.
