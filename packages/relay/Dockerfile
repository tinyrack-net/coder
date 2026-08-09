FROM dart:stable AS build
WORKDIR /src
COPY packages/relay/docker/workspace_pubspec.yaml pubspec.yaml
COPY packages/relay/pubspec.yaml relay/pubspec.yaml
COPY packages/relay/bin relay/bin
COPY packages/relay/lib relay/lib
COPY packages/relay_protocol/pubspec.yaml relay_protocol/pubspec.yaml
COPY packages/relay_protocol/lib relay_protocol/lib
RUN dart pub get && mkdir -p /out && dart compile exe relay/bin/coder_relay.dart -o /out/coder-relay

FROM gcr.io/distroless/cc-debian12:nonroot
COPY --from=build /out/coder-relay /coder-relay
EXPOSE 8080
ENTRYPOINT ["/coder-relay"]
