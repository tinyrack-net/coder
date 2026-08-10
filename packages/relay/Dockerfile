FROM dart:3.12.2@sha256:5ac89dbcae4327278b257920e2786df0f22c87adc630017266b67cfcceef8348 AS build
WORKDIR /src
COPY packages/relay/docker/workspace_pubspec.yaml pubspec.yaml
COPY packages/relay/docker/pubspec.lock pubspec.lock
COPY packages/relay/pubspec.yaml relay/pubspec.yaml
COPY packages/relay/bin relay/bin
COPY packages/relay/lib relay/lib
COPY packages/relay_protocol/pubspec.yaml relay_protocol/pubspec.yaml
COPY packages/relay_protocol/lib relay_protocol/lib
RUN dart pub get --enforce-lockfile \
    && mkdir -p /out \
    && dart compile exe relay/bin/coder_relay.dart -o /out/coder-relay

FROM gcr.io/distroless/cc-debian12:nonroot@sha256:fccdbb0a547c14e23fcf4ce8ad62ca5d43b4faae8d22cd292f490fef9946c96e
COPY --from=build /out/coder-relay /coder-relay
EXPOSE 8080
ENTRYPOINT ["/coder-relay"]
