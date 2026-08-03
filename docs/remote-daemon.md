# Remote daemon and TLS proxy

Tinyrack Coder's daemon serves plain HTTP/WebSocket only. For a remote host,
keep the daemon on loopback and let an operator-managed reverse proxy provide
DNS, certificates, TLS policy, firewalling, and public reachability. The app
uses the operating system trust store for `wss://`; it does not offer a
self-signed-certificate or certificate-validation bypass.

Start a standalone daemon with an explicit 256-bit access token when
reproducible deployment credentials are required:

```sh
TINYRACK_CODER_LISTEN=127.0.0.1:7337 \
TINYRACK_CODER_TOKEN='<at-least-32-byte-bearer-secret>' \
dart run packages/coder_daemon/bin/coder_daemon.dart
```

The bearer token grants the complete daemon API, including Provider credentials
and Markdown Agent settings. Tinyrack Coder does not implement user roles or
location-based permissions. Anyone who possesses this token can fully control
the daemon.

The desktop app exposes the same choice for its embedded daemon as a
`Network access` toggle: off binds `127.0.0.1`, while on binds `0.0.0.0` and
restarts only the app-owned daemon. Keep it off for a reverse proxy running on
the same machine. If it is on, use an operating-system or network firewall to
prevent clients from bypassing the TLS proxy through the plain daemon port.

## Caddy

Caddy forwards WebSocket upgrades and `Authorization` by default:

```caddyfile
coder.example.com {
  reverse_proxy 127.0.0.1:7337
}
```

Register `wss://coder.example.com/ws` in the app and enter the bearer token.

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
  }
}
```

## Local files and development resets

Daemon bearer, API-key, and OAuth credentials are stored atomically in
`credentials.json`. On POSIX systems the configuration directory is mode
`0700` and the file is mode `0600`; secrets are not stored in SQLite, protocol
payloads, or logs.

This repository is in active development and does not migrate older internal
credential formats. An existing version-3 `credentials.json` produces an
`incompatible_credentials` error with its exact path. Stop the daemon and
explicitly remove that file to reset it. An old `auth.json` is ignored and is
not deleted automatically; remove it manually after confirming it is no longer
needed.

The app accepts both `ws://` and `wss://` profiles without warnings or policy
enforcement. Transport security, network isolation, and TLS are deployment
responsibilities. The app uses the operating system trust store for `wss://`
and does not provide a certificate-validation bypass.
