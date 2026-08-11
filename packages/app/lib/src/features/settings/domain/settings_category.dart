/// Top-level settings categories.
enum SettingsCategory {
  /// App-wide preferences that do not belong to any single daemon.
  general,

  /// Worktree lifecycle hooks stored in each project's `.tinest/config.json`.
  project,

  /// Markdown-backed agent definitions owned by one daemon.
  agent,

  /// External MCP servers owned by one daemon.
  mcp,

  /// Transport, relay pairing, and approved devices for one daemon.
  connection,

  /// Skills merged from built-in, user, config, and project sources.
  skill,

  /// API provider connections owned by one daemon.
  provider,

  /// Default agent permissions owned by one daemon.
  permission,

  /// Embedded and remote daemon connections.
  daemon,

  /// Developer maintenance, including erasing every stored value.
  advanced,
}

/// Whether a settings category belongs to the app or to one daemon.
enum SettingsCategoryScope {
  /// Applies to the whole app regardless of which daemon is active.
  app,

  /// Reads and writes state owned by the selected daemon.
  daemon,
}

/// Groups settings categories into the sidebar sections that carry them.
extension SettingsCategoryScopeX on SettingsCategory {
  /// The sidebar section this category belongs to.
  ///
  /// Daemon connection management is app-wide even though it is about
  /// daemons, so it sits with General rather than under the daemon picker.
  SettingsCategoryScope get scope => switch (this) {
    SettingsCategory.general ||
    SettingsCategory.daemon ||
    SettingsCategory.advanced => SettingsCategoryScope.app,
    SettingsCategory.project ||
    SettingsCategory.agent ||
    SettingsCategory.mcp ||
    SettingsCategory.connection ||
    SettingsCategory.skill ||
    SettingsCategory.permission ||
    SettingsCategory.provider => SettingsCategoryScope.daemon,
  };
}
