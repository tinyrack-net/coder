# coder_app

Cross-platform Flutter client for Tinyrack Coder. The app uses a feature-first
layout with Riverpod application controllers and typed `go_router` navigation.

## Source layout

```text
lib/src/
  app/                       application composition, routes, and cross-feature shells
  features/<feature>/
    application/             Riverpod state and user commands
    domain/                  pure app-owned rules and value types, when needed
    infrastructure/          platform and persistence adapters, when needed
    presentation/            feature-owned pages and widgets
  shared/                    feature-neutral domain and presentation code
```

For developers coming from React, `app/router` is the route table,
`presentation/pages` contains route-level components,
`presentation/widgets` contains feature components, and `application` contains
the feature's typed store and actions. Riverpod also supplies dependency
injection at the composition root.

Cross-feature page and widget composition belongs in `app/presentation`.
Feature-neutral components belong in `shared`; shared code cannot import a
feature. Domain code does not import Flutter or platform packages, and
application controllers do not instantiate transports, filesystems, clocks, or
ID generators.

`CoderApi` and `coder_protocol` DTOs are already transport-neutral boundaries.
Do not wrap them mechanically in repositories or duplicate DTO models. Add a
repository or use-case only when the app owns a source of truth, caching,
retry/merge behavior, or reusable multi-source business logic.

Tests mirror the same ownership under `test/app`, `test/features`, and
`test/shared`. Cross-feature app flows have a small driver in `test/app` with
feature-owned test cases beside the relevant feature tests.
