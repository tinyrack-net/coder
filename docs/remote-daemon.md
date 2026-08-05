# Remote daemon, browsers, and TLS proxy

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

## Browser clients

The web build at `https://coder.tinyrack.net` is a static client with no
server of its own: it connects to a daemon the user runs, exactly as the
desktop and mobile apps do.

Two things differ from a native client, and both are daemon-side.

A browser's `WebSocket` API cannot set request headers, so a web client cannot
send `Authorization`. It presents the same bearer token as a subprotocol
instead, base64url encoded because a subprotocol may only contain RFC 7230
token characters:

```
Sec-WebSocket-Protocol: tinyrack.coder.v2, tinyrack.coder.token.<base64url>
```

The daemon accepts either credential and echoes back only `tinyrack.coder.v2`,
so the token never appears in a response. This is the same secret with the
same complete access; a subprotocol is a transport detail, not a weaker
credential.

Because a browser can now present a credential at all, any web page could
otherwise probe a daemon running on a visitor's own machine. The daemon
therefore checks `Origin` against an allowlist before authenticating:

```sh
TINYRACK_CODER_ALLOWED_ORIGINS='https://coder.tinyrack.net,http://localhost:8080' \
  dart run packages/coder_daemon/bin/coder_daemon.dart
# or: coder_daemon --allowed-origin https://coder.tinyrack.net
```

The default allows the official web app only. Setting the variable to `none`
turns browser access off entirely. **Requests without an `Origin` header are
unaffected**, which is every native client and `coder-cli`, so this gate never
changes their behaviour. The same allowlist drives the CORS headers on
`/health` and `/attachments`.

### Reaching a daemon on your own machine

**The hosted web app cannot connect to a loopback daemon without the browser's
Local Network Access permission.** This is the one case where the web build is
strictly less capable than the desktop app, and it is worth understanding
before choosing between them.

The obstacle is not mixed content. Loopback is a potentially trustworthy
origin, so `ws://127.0.0.1:7337` from an HTTPS page is not blocked as insecure.
What blocks it is Local Network Access: a public page reaching a private
address needs the user's permission. Measured against the deployed app in
Chrome 151:

```
fetch  → blocked by CORS policy: Permission was denied for this request to
         access the `loopback` address space
         (corsError: LocalNetworkAccessPermissionDenied)
ws     → net::ERR_BLOCKED_BY_LOCAL_NETWORK_ACCESS_CHECKS
```

The daemon cannot fix this from its side. The permission is evaluated before
any request is made — with the checks active the daemon receives nothing, not
even a preflight, so no response header changes the outcome. Running the same
probe with `--disable-features=LocalNetworkAccessChecks` connects and completes
the handshake normally, which confirms nothing else is wrong.

Whether accepting the browser's permission prompt is sufficient has not been
verified here: a headless browser denies the prompt automatically, and
granting the permission over the DevTools protocol did not substitute for it.

Three arrangements avoid the problem entirely:

- **Use the desktop app** for a daemon on the same machine. It is the intended
  tool for that case and has no browser in the path.
- **Put the daemon behind a `wss://` reverse proxy** on a routable host, as
  below, and register that address. This is a public-to-public connection, so
  Local Network Access does not apply.
- **Serve the web build from the daemon's own origin** if you are hosting it
  yourself, which makes the request same-origin.

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
