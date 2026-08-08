FROM dart:stable AS build
WORKDIR /src
COPY packages/coder_relay/docker/workspace_pubspec.yaml pubspec.yaml
COPY packages/coder_relay/pubspec.yaml coder_relay/pubspec.yaml
COPY packages/coder_relay/bin coder_relay/bin
COPY packages/coder_relay/lib coder_relay/lib
COPY packages/coder_relay_protocol/pubspec.yaml coder_relay_protocol/pubspec.yaml
COPY packages/coder_relay_protocol/lib coder_relay_protocol/lib
RUN dart pub get && mkdir -p /out && dart compile exe coder_relay/bin/coder_relay.dart -o /out/coder-relay

FROM gcr.io/distroless/cc-debian12:nonroot
COPY --from=build /out/coder-relay /coder-relay
EXPOSE 8080
ENTRYPOINT ["/coder-relay"]
