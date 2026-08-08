import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/shared/presentation/coder_layout_metrics.dart';
import 'package:coder_app/src/shared/presentation/coder_list_row.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Applies one loading, stale-data, and error policy to settings reads.
class SettingsAsyncContent<T> extends StatelessWidget {
  /// Creates a settings data boundary.
  const SettingsAsyncContent({
    required this.state,
    required this.loading,
    required this.data,
    required this.error,
    super.key,
  });

  /// Current asynchronous state.
  final AsyncValue<T> state;

  /// Shape-preserving placeholder used before the first value.
  final Widget loading;

  /// Builds the usable surface from the newest available value.
  final Widget Function(T value) data;

  /// Builds a blocking error only when no value has ever loaded.
  final Widget Function(Object error, StackTrace stackTrace) error;

  @override
  Widget build(BuildContext context) {
    if (state.hasValue) {
      final child = data(state.requireValue);
      if (!state.hasError) return child;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TRSpacing.extraLarge,
              TRSpacing.medium,
              TRSpacing.extraLarge,
              0,
            ),
            child: TRAlert(
              key: const ValueKey<String>('settings-refresh-error'),
              variant: TRStatusVariant.danger,
              title: TRText.inherit(
                AppLocalizations.of(
                  context,
                ).settingsRefreshFailed('${state.error}'),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      );
    }
    if (state.isLoading) return loading;
    return error(state.error!, state.stackTrace!);
  }
}

enum _SettingsSkeletonKind { form, listDetail, overlay }

/// Loading placeholders that preserve the final shape of a settings surface.
///
/// The shell owns navigation and these placeholders own only the data region,
/// so an unavailable daemon or catalog never blocks category navigation.
class SettingsSkeletonLayout extends StatelessWidget {
  /// Creates a settings form placeholder.
  const SettingsSkeletonLayout.form({required this.semanticLabel, super.key})
    : _kind = _SettingsSkeletonKind.form;

  /// Creates a responsive collection-and-detail placeholder.
  const SettingsSkeletonLayout.listDetail({
    required this.semanticLabel,
    super.key,
  }) : _kind = _SettingsSkeletonKind.listDetail;

  /// Creates a compact overlay placeholder.
  const SettingsSkeletonLayout.overlay({
    required this.semanticLabel,
    super.key,
  }) : _kind = _SettingsSkeletonKind.overlay;

  /// Accessible description announced once for the complete placeholder.
  final String semanticLabel;

  final _SettingsSkeletonKind _kind;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    container: true,
    liveRegion: true,
    child: ExcludeSemantics(
      child: switch (_kind) {
        _SettingsSkeletonKind.form => const _SettingsFormSkeleton(),
        _SettingsSkeletonKind.listDetail => const _SettingsListDetailSkeleton(),
        _SettingsSkeletonKind.overlay => const _SettingsOverlaySkeleton(),
      },
    ),
  );
}

class _SettingsFormSkeleton extends StatelessWidget {
  const _SettingsFormSkeleton();

  @override
  Widget build(BuildContext context) => const SettingsScaffold(
    key: ValueKey<String>('settings-skeleton-form'),
    children: <Widget>[
      _SettingsSkeletonSection(rowCount: 2),
      _SettingsSkeletonSection(rowCount: 3),
    ],
  );
}

class _SettingsListDetailSkeleton extends StatelessWidget {
  const _SettingsListDetailSkeleton();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < CoderLayoutMetrics.compactBreakpoint) {
        return const _SettingsSkeletonListPane(
          key: ValueKey<String>('settings-skeleton-list-pane'),
        );
      }
      return const Row(
        children: <Widget>[
          SizedBox(
            width: CoderLayoutMetrics.settingsCollectionWidth,
            child: _SettingsSkeletonListPane(
              key: ValueKey<String>('settings-skeleton-list-pane'),
            ),
          ),
          TRSeparator(
            orientation: TRSeparatorOrientation.vertical,
            variant: TRSeparatorVariant.muted,
          ),
          Expanded(
            key: ValueKey<String>('settings-skeleton-detail-pane'),
            child: _SettingsSkeletonDetailPane(),
          ),
        ],
      );
    },
  );
}

class _SettingsSkeletonListPane extends StatelessWidget {
  const _SettingsSkeletonListPane({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Padding(
        padding: SettingsRow.contentPadding,
        child: TRSkeleton(width: TRMeasurements.measureSm),
      ),
      TRSeparator(variant: TRSeparatorVariant.muted),
      Expanded(
        child: SettingsCollectionList(
          children: <Widget>[
            _SettingsSkeletonListRow(),
            _SettingsSkeletonListRow(),
            _SettingsSkeletonListRow(),
            _SettingsSkeletonListRow(),
          ],
        ),
      ),
    ],
  );
}

class _SettingsSkeletonListRow extends StatelessWidget {
  const _SettingsSkeletonListRow();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: SettingsRow.collectionContentPadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TRSkeleton(width: TRMeasurements.measureSm),
        SizedBox(height: TRSpacing.extraSmall),
        TRSkeleton(width: TRMeasurements.measureMd),
      ],
    ),
  );
}

/// A scrollable collection pane whose rows share the settings sidebar rhythm.
///
/// The pane boundary supplies the outer inset while collection rows reduce
/// their own inline padding by the same amount. This keeps selected, hovered,
/// and focused surfaces away from the pane edge without moving the content
/// away from the header's leading alignment line.
class SettingsCollectionList extends StatelessWidget {
  /// Creates an inset collection with token-based spacing between [children].
  const SettingsCollectionList({required this.children, super.key});

  /// Rows and collection-local headings shown in display order.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.symmetric(
      horizontal: TRSpacing.medium,
      vertical: TRSpacing.extraSmall,
    ),
    itemCount: children.length,
    itemBuilder: (context, index) => children[index],
    separatorBuilder: (context, index) =>
        const SizedBox(height: TRSpacing.extraSmall),
  );
}

class _SettingsSkeletonDetailPane extends StatelessWidget {
  const _SettingsSkeletonDetailPane();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: TRSpacing.extraLarge,
          vertical: TRSpacing.medium,
        ),
        child: TRSkeleton(width: TRMeasurements.measureSm),
      ),
      TRSeparator(variant: TRSeparatorVariant.muted),
      Expanded(child: _SettingsFormSkeleton()),
    ],
  );
}

class _SettingsSkeletonSection extends StatelessWidget {
  const _SettingsSkeletonSection({required this.rowCount});

  final int rowCount;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const TRSkeleton(width: TRMeasurements.measureSm),
      const SizedBox(height: TRSpacing.small),
      TRCard(
        padding: TRCardPadding.none,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (var index = 0; index < rowCount; index++) ...<Widget>[
              if (index > 0)
                const TRSeparator(variant: TRSeparatorVariant.muted),
              const _SettingsSkeletonListRow(),
            ],
          ],
        ),
      ),
    ],
  );
}

class _SettingsOverlaySkeleton extends StatelessWidget {
  const _SettingsOverlaySkeleton();

  @override
  Widget build(BuildContext context) => const SizedBox(
    key: ValueKey<String>('settings-skeleton-overlay'),
    width: TRMeasurements.overlayWidthMd,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TRSkeleton(width: TRMeasurements.measureSm),
        SizedBox(height: TRSpacing.large),
        TRSkeleton(shape: TRSkeletonShape.rectangle),
        SizedBox(height: TRSpacing.small),
        TRSkeleton(shape: TRSkeletonShape.rectangle),
        SizedBox(height: TRSpacing.small),
        TRSkeleton(shape: TRSkeletonShape.rectangle),
      ],
    ),
  );
}

/// Coordinates a compact settings page's deepest locally managed pane.
///
/// The typed router owns settings categories, while list-detail features own
/// their selected item. This controller lets the shared page header offer one
/// Back affordance for both layers without moving feature state into routing.
class SettingsPaneNavigationController extends ChangeNotifier {
  Object? _owner;
  VoidCallback? _onBack;

  /// Whether a descendant currently has a local pane to leave.
  bool get canGoBack => _onBack != null;

  /// Registers [onBack] as the action for [owner]'s visible detail pane.
  void setBackHandler(Object owner, VoidCallback onBack) {
    if (identical(_owner, owner)) {
      _onBack = onBack;
      return;
    }
    _owner = owner;
    _onBack = onBack;
    notifyListeners();
  }

  /// Removes the handler when [owner] returns to its list pane or disposes.
  void clearBackHandler(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _onBack = null;
    notifyListeners();
  }

  /// Leaves the deepest locally managed pane.
  void goBack() => _onBack?.call();
}

/// Supplies the compact settings pane coordinator to list-detail features.
class SettingsPaneNavigationScope extends InheritedWidget {
  /// Creates a settings pane navigation scope.
  const SettingsPaneNavigationScope({
    required this.controller,
    required super.child,
    super.key,
  });

  /// Controller shared with the settings page header.
  final SettingsPaneNavigationController controller;

  /// Returns the nearest controller, when hosted by the unified settings page.
  static SettingsPaneNavigationController? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<SettingsPaneNavigationScope>()
          ?.controller;

  @override
  bool updateShouldNotify(SettingsPaneNavigationScope oldWidget) =>
      !identical(controller, oldWidget.controller);
}

/// Synchronizes a list-detail feature with the shared compact page header.
void syncSettingsPaneBackHandler(
  BuildContext context, {
  required Object owner,
  required bool active,
  required VoidCallback onBack,
}) {
  final controller = SettingsPaneNavigationScope.maybeOf(context);
  if (controller == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (active) {
      controller.setBackHandler(owner, onBack);
    } else {
      controller.clearBackHandler(owner);
    }
  });
}

/// The responsive collection-and-detail structure used by list settings.
///
/// On a wide surface both panes remain visible. On a compact surface the
/// detail replaces the collection and registers itself with the settings
/// shell's shared Back action.
class SettingsListDetailLayout extends StatefulWidget {
  /// Creates a settings collection-and-detail layout.
  const SettingsListDetailLayout({
    required this.collection,
    required this.detail,
    required this.detailVisible,
    required this.onBack,
    super.key,
  });

  /// The middle settings pane containing the item collection.
  final Widget collection;

  /// The trailing pane containing an editor, creator, or empty state.
  final Widget detail;

  /// Whether compact layouts should show [detail] instead of [collection].
  final bool detailVisible;

  /// Returns a compact layout to its collection.
  final VoidCallback onBack;

  @override
  State<SettingsListDetailLayout> createState() =>
      _SettingsListDetailLayoutState();
}

class _SettingsListDetailLayoutState extends State<SettingsListDetailLayout> {
  SettingsPaneNavigationController? _navigation;

  @override
  void dispose() {
    _navigation?.clearBackHandler(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < CoderLayoutMetrics.compactBreakpoint;
      _navigation = SettingsPaneNavigationScope.maybeOf(context);
      syncSettingsPaneBackHandler(
        context,
        owner: this,
        active: compact && widget.detailVisible,
        onBack: widget.onBack,
      );
      if (compact) {
        return widget.detailVisible ? widget.detail : widget.collection;
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: CoderLayoutMetrics.settingsCollectionWidth,
            child: widget.collection,
          ),
          const TRSeparator(
            orientation: TRSeparatorOrientation.vertical,
            variant: TRSeparatorVariant.muted,
          ),
          Expanded(child: widget.detail),
        ],
      );
    },
  );
}

/// The scroll container every settings pane uses.
///
/// Page padding, content width, and the gap between sections live here rather
/// than in each page. Eight pages that each laid out their own `ListView` were
/// free to drift apart, and every one of them did.
class SettingsScaffold extends StatelessWidget {
  /// Creates a settings pane showing [children] as its sections.
  const SettingsScaffold({required this.children, super.key});

  /// Sections shown in order.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(TRSpacing.extraLarge),
    children: <Widget>[
      // Each section stays its own list child rather than sharing one. Folding
      // them into a single child builds every section eagerly, so a finder
      // resolves a section that is scrolled out of view and a tap on it lands
      // outside the viewport and quietly hits nothing.
      for (final (index, child) in children.indexed)
        Padding(
          padding: EdgeInsets.only(
            top: index > 0 ? TRSpacing.twoExtraLarge : 0,
          ),
          child: Align(
            // Centred, so a wide window keeps the column balanced rather than
            // stranding it against one edge with a growing void beside it.
            // Below the cap the column fills the pane and this is a no-op.
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: CoderLayoutMetrics.settingsContentMaxWidth,
              ),
              child: child,
            ),
          ),
        ),
    ],
  );
}

/// One titled group of settings.
class SettingsSection extends StatelessWidget {
  /// Creates a section whose [children] are [SettingsRow]s sharing one card.
  const SettingsSection({
    required this.title,
    required this.children,
    this.description,
    this.action,
    this.banner,
    super.key,
  }) : _boxed = true;

  /// Creates a section whose [children] are form controls that draw their own
  /// frame, laid out without a surrounding card.
  ///
  /// A multi-line editor cannot sit in a trailing rail, so it keeps the
  /// stacked label-above-control shape `TRField` defines instead of being
  /// forced into a row.
  const SettingsSection.form({
    required this.title,
    required this.children,
    this.description,
    this.action,
    this.banner,
    super.key,
  }) : _boxed = false;

  /// Section heading.
  final String title;

  /// Optional supporting line under the heading.
  final String? description;

  /// Optional action rendered opposite the heading.
  final Widget? action;

  /// Optional status banner shown between the heading and the content.
  ///
  /// A save result, a connection failure, or a parse diagnostic belongs to its
  /// section rather than to the page, so it sits inside the section's spacing
  /// instead of being stacked above it as another top-level block.
  final Widget? banner;

  /// Section content.
  final List<Widget> children;

  /// Whether the content shares one card.
  final bool _boxed;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      // A Wrap rather than a Row: on a narrow window, or at a large text
      // scale, a heading and its action do not fit on one line. Wrapping is
      // what keeps the action from overflowing, and spaceBetween still puts
      // it against the trailing edge whenever the two do fit.
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: TRSpacing.large,
        runSpacing: TRSpacing.small,
        children: <Widget>[
          TRText(title, variant: TRTextVariant.headingMd),
          ?action,
        ],
      ),
      if (description case final description?) ...<Widget>[
        const SizedBox(height: TRSpacing.extraSmall),
        TRText(
          description,
          variant: TRTextVariant.bodySm,
          color: TRTextColor.muted,
        ),
      ],
      if (banner case final banner?) ...<Widget>[
        const SizedBox(height: TRSpacing.medium),
        banner,
      ],
      const SizedBox(height: TRSpacing.small),
      if (_boxed)
        TRCard(
          padding: TRCardPadding.none,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final (index, child) in children.indexed) ...<Widget>[
                if (index > 0)
                  // Muted, so a divider inside a card matches the card's own
                  // border. The default variant is borderStrong, which is the
                  // weight a control draws at, not a surface.
                  const TRSeparator(variant: TRSeparatorVariant.muted),
                child,
              ],
            ],
          ),
        )
      else
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final (index, child) in children.indexed) ...<Widget>[
              if (index > 0) const SizedBox(height: TRSpacing.large),
              child,
            ],
          ],
        ),
    ],
  );
}

/// One setting: its description leading, its control trailing.
///
/// Every switch, checkbox, select, button, and single-line input in settings
/// goes through here, so the inset a setting draws at is decided once. The
/// padding is deliberately not overridable: rows that could set their own were
/// how one card ended up with two alignment lines.
class SettingsRow extends StatelessWidget {
  /// Creates a settings row.
  const SettingsRow({
    required this.title,
    this.control,
    this.controlOwnsFocus = false,
    this.description,
    this.leading,
    this.onTap,
    this.enabled = true,
    this.selected = false,
    this.wrapsDescription = false,
    this.unboundedDescription = false,
    this.flush = false,
    super.key,
  }) : _collection = false;

  /// Creates a row inside a [SettingsCollectionList].
  ///
  /// Its selected, hover, and focus surface is inset by the surrounding list,
  /// while its content remains aligned with [SettingsPaneHeader.list].
  const SettingsRow.collection({
    required this.title,
    this.control,
    this.controlOwnsFocus = false,
    this.description,
    this.leading,
    this.onTap,
    this.enabled = true,
    this.selected = false,
    this.wrapsDescription = false,
    this.unboundedDescription = false,
    super.key,
  }) : flush = false,
       _collection = true;

  /// Primary label.
  final Widget title;

  /// Optional supporting text under the label.
  final Widget? description;

  /// Optional leading visual.
  final Widget? leading;

  /// Optional trailing control.
  final Widget? control;

  /// Whether [control] is the row's only tab stop.
  ///
  /// Set this whenever [onTap] only repeats what [control] already does, so
  /// one setting costs one Tab press. See [CoderListRow.controlOwnsFocus].
  final bool controlOwnsFocus;

  /// Invoked when the row is activated.
  final VoidCallback? onTap;

  /// Whether the row accepts activation.
  final bool enabled;

  /// Whether the row reads as selected.
  final bool selected;

  /// Whether the description may occupy a second line.
  final bool wrapsDescription;

  /// Whether the description may run to as many lines as it needs.
  ///
  /// For a description that is prose rather than a status line: two lines cut
  /// it mid-sentence on a narrow window.
  final bool unboundedDescription;

  /// Whether the surrounding container already supplies the inline inset.
  ///
  /// A dialog pads its own content, so a row inside one would otherwise sit a
  /// step further in than the fields above it. Collection panes use the
  /// explicit [SettingsRow.collection] constructor instead, because their
  /// outer inset also defines the selected and focus surface boundary.
  final bool flush;

  final bool _collection;

  /// The inset every settings row draws its content at.
  static const contentPadding = EdgeInsets.symmetric(
    horizontal: TRSpacing.large,
    vertical: TRSpacing.medium,
  );

  /// The inset a row draws at inside a container that supplies its own.
  static const flushPadding = EdgeInsets.symmetric(vertical: TRSpacing.medium);

  /// Content inset used after the collection supplies its outer pane inset.
  static const collectionContentPadding = EdgeInsets.symmetric(
    horizontal: TRSpacing.extraSmall,
    vertical: TRSpacing.medium,
  );

  @override
  Widget build(BuildContext context) => CoderListRow(
    contentPadding: _collection
        ? collectionContentPadding
        : flush
        ? flushPadding
        : contentPadding,
    controlOwnsFocus: controlOwnsFocus,
    enabled: enabled,
    isThreeLine: wrapsDescription || unboundedDescription,
    unboundedSubtitle: unboundedDescription,
    leading: leading,
    onTap: onTap,
    selected: selected,
    subtitle: description,
    title: title,
    trailing: control,
  );
}

/// The header of one pane in a settings list-detail layout.
class SettingsPaneHeader extends StatelessWidget {
  /// Creates the header of the list pane, inset to match its rows.
  const SettingsPaneHeader.list({
    required this.title,
    this.subtitle,
    this.actions = const <Widget>[],
    this.leading,
    super.key,
  }) : _padding = SettingsRow.contentPadding;

  /// Creates the header of the detail pane, inset to match its body.
  ///
  /// The detail body is a [SettingsScaffold], which pads by a wider step than
  /// a row does. A header that took the row inset left the pane with two
  /// competing leading edges.
  const SettingsPaneHeader.detail({
    required this.title,
    this.subtitle,
    this.actions = const <Widget>[],
    this.leading,
    super.key,
  }) : _padding = const EdgeInsets.symmetric(
         horizontal: TRSpacing.extraLarge,
         vertical: TRSpacing.medium,
       );

  /// Pane title.
  final String title;

  /// Optional supporting line, such as a count or a source path.
  final String? subtitle;

  /// Optional leading action, such as a back button.
  final Widget? leading;

  /// Trailing actions.
  final List<Widget> actions;

  /// Inset matching the content this header sits above.
  final EdgeInsets _padding;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Padding(
        padding: _padding,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: TRSpacing.large,
          runSpacing: TRSpacing.small,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (leading case final leading?) ...<Widget>[
                  leading,
                  const SizedBox(width: TRSpacing.small),
                ],
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TRText(title, maxLines: 1, truncate: true),
                      if (subtitle case final subtitle?) ...<Widget>[
                        const SizedBox(height: TRSpacing.extraSmall),
                        TRText(
                          subtitle,
                          variant: TRTextVariant.bodySm,
                          color: TRTextColor.muted,
                          maxLines: 1,
                          truncate: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (actions.isNotEmpty)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: TRSpacing.small,
                runSpacing: TRSpacing.small,
                children: actions,
              ),
          ],
        ),
      ),
      const TRSeparator(variant: TRSeparatorVariant.muted),
    ],
  );
}

/// A consistent empty or unselected state for settings panes.
///
/// The content is intentionally centred as one compact reading group. Plain
/// `Center(child: Text(...))` states had no shared hierarchy and drifted from
/// each other as pages added icons or actions independently.
class SettingsEmptyState extends StatelessWidget {
  /// Creates a settings empty state.
  const SettingsEmptyState({
    required this.title,
    this.description,
    this.icon,
    this.action,
    super.key,
  });

  /// Primary empty-state message.
  final String title;

  /// Optional explanation or next step.
  final String? description;

  /// Optional semantic visual.
  final Widget? icon;

  /// Optional action resolving the empty state.
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(TRSpacing.extraLarge),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: CoderLayoutMetrics.settingsEmptyStateMaxWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon case final icon?) ...<Widget>[
              icon,
              const SizedBox(height: TRSpacing.medium),
            ],
            TRText(
              title,
              variant: TRTextVariant.headingSm,
              align: TRTextAlign.center,
            ),
            if (description case final description?) ...<Widget>[
              const SizedBox(height: TRSpacing.extraSmall),
              TRText(
                description,
                variant: TRTextVariant.bodySm,
                color: TRTextColor.muted,
                align: TRTextAlign.center,
              ),
            ],
            if (action case final action?) ...<Widget>[
              const SizedBox(height: TRSpacing.large),
              action,
            ],
          ],
        ),
      ),
    ),
  );
}

/// The shared field rhythm and width for settings dialogs.
class SettingsDialogForm extends StatelessWidget {
  /// Creates a settings dialog form.
  const SettingsDialogForm({
    required this.children,
    this.width = TRMeasurements.overlayWidthMd,
    super.key,
  });

  /// Fields, notices, and other form content in reading order.
  final List<Widget> children;

  /// Public Tinyrack overlay measurement used by this dialog.
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final (index, child) in children.indexed) ...<Widget>[
          if (index > 0) const SizedBox(height: TRSpacing.large),
          child,
        ],
      ],
    ),
  );
}

/// The stacked selects shown above a settings pane on a narrow window.
///
/// The category, daemon, and project selects used to render at three different
/// widths and alignments because only one of them was told to fill the pane.
/// The width reaches each control through [builder] rather than through a
/// stretching parent: a `TRSelect` keeps an intrinsic-width trigger unless it
/// is given a width, so stretching only the surrounding box leaves a narrow
/// trigger sitting in a wide empty field.
class SettingsCompactToolbar extends StatelessWidget {
  /// Creates a compact settings toolbar whose controls fill the given width.
  const SettingsCompactToolbar({required this.builder, super.key});

  /// Builds the controls, in order, for the width available to them.
  final List<Widget> Function(double width) builder;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      TRSpacing.large,
      TRSpacing.large,
      TRSpacing.large,
      TRSpacing.medium,
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final children = builder(constraints.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final (index, child) in children.indexed) ...<Widget>[
              if (index > 0) const SizedBox(height: TRSpacing.small),
              child,
            ],
          ],
        );
      },
    ),
  );
}
