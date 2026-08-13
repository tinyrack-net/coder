import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/shared/presentation/tinest_icons.dart';
import 'package:app/src/shared/presentation/tinest_layout_metrics.dart';
import 'package:app/src/shared/presentation/tinest_list_row.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Returns the settings shell's adaptive class without classifying an inner
/// pane's constraints.
///
/// Unified Settings supplies [TRAdaptivePaneScope]. Standalone task routes and
/// focused widget hosts fall back to the logical root viewport, preserving the
/// same window policy without mistaking an already-allocated pane for a
/// smaller window.
TRAdaptiveWidthClass settingsAdaptiveWidthClassOf(BuildContext context) =>
    TRAdaptivePaneScope.maybeOf(context)?.widthClass ??
    TRAdaptiveWidthClass.fromWidth(MediaQuery.sizeOf(context).width);

/// The product-owned content slots supplied to the adaptive pane scaffold.
enum SettingsPaneSlot {
  /// The primary collection or category content.
  collection,

  /// The secondary editor, creator, or item detail.
  detail,
}

/// Read-only navigation state shared by one list-detail settings feature.
///
/// Typed routes own categories. A feature controller owns only its local
/// collection selection, while the settings shell maps that selection onto a
/// [TRPaneRole.secondary] destination in the public Tinyrack navigator.
abstract interface class SettingsPaneCoordinator implements Listenable {
  /// Whether the feature currently has a detail or create destination.
  bool get hasDetail;

  /// Stable identity used by the shared three-pane navigator.
  String? get destinationId;

  /// Whether a desktop collection may choose its first item automatically.
  ///
  /// This is consumed after the first automatic selection or any explicit
  /// navigation. Returning from a detail therefore leaves the collection
  /// visible instead of immediately reopening its first item.
  bool get canAutoSelect;

  /// Returns the feature to its collection destination.
  void showCollection();

  /// Clears local navigation for a different route identity.
  void reset();
}

/// Shares the initial desktop selection contract across Settings features.
abstract class SettingsPaneCoordinatorBase extends ChangeNotifier
    implements SettingsPaneCoordinator {
  bool _autoSelectionConsumed = false;

  @override
  bool get canAutoSelect => !hasDetail && !_autoSelectionConsumed;

  /// Consumes and admits the first desktop selection for this route identity.
  @protected
  bool consumeInitialSelection() {
    if (!canAutoSelect) return false;
    _autoSelectionConsumed = true;
    return true;
  }

  /// Prevents later rebuilds from interpreting explicit navigation as entry.
  @protected
  void consumeExplicitNavigation() {
    _autoSelectionConsumed = true;
  }

  /// Re-enables initial selection after the route identity changes.
  @protected
  void resetInitialSelection() {
    _autoSelectionConsumed = false;
  }
}

/// A typed, product-local selection controller for one settings collection.
class SettingsPaneController<T extends Object>
    extends SettingsPaneCoordinatorBase {
  /// Creates a controller whose local [T] values have stable destination IDs.
  SettingsPaneController({required this.destinationIdFor});

  /// Resolves a stable local navigation identity for one typed destination.
  final String Function(T value) destinationIdFor;
  T? _destination;

  /// The selected item or create destination, when one is active.
  T? get destination => _destination;

  @override
  bool get hasDetail => _destination != null;

  @override
  String? get destinationId {
    final destination = _destination;
    return destination == null ? null : destinationIdFor(destination);
  }

  /// Shows [destination] as the initial desktop detail, at most once per
  /// route identity.
  void showInitialDetail(T destination) {
    if (!consumeInitialSelection()) return;
    _destination = destination;
    notifyListeners();
  }

  /// Shows the detail represented by [destination].
  void showDetail(T destination) {
    consumeExplicitNavigation();
    if (_destination == destination) return;
    _destination = destination;
    notifyListeners();
  }

  @override
  void showCollection() {
    consumeExplicitNavigation();
    if (_destination == null) return;
    _destination = null;
    notifyListeners();
  }

  @override
  void reset() {
    final hadDetail = _destination != null;
    resetInitialSelection();
    _destination = null;
    if (hadDetail) notifyListeners();
  }
}

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
            padding: const EdgeInsets.only(
              left: TRSpacing.extraLarge,
              top: TRSpacing.medium,
              right: TRSpacing.extraLarge,
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

enum _SettingsSkeletonKind { form, collection, detail, overlay }

/// Loading placeholders that preserve the final shape of a settings surface.
///
/// The shell owns navigation and these placeholders own only the data region,
/// so an unavailable daemon or catalog never blocks category navigation.
class SettingsSkeletonLayout extends StatelessWidget {
  /// Creates a settings form placeholder.
  const SettingsSkeletonLayout.form({required this.semanticLabel, super.key})
    : _kind = _SettingsSkeletonKind.form;

  /// Creates a collection-pane placeholder.
  const SettingsSkeletonLayout.collection({
    required this.semanticLabel,
    super.key,
  }) : _kind = _SettingsSkeletonKind.collection;

  /// Creates a detail-pane placeholder.
  const SettingsSkeletonLayout.detail({
    required this.semanticLabel,
    super.key,
  }) : _kind = _SettingsSkeletonKind.detail;

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
        _SettingsSkeletonKind.collection => const _SettingsSkeletonListPane(),
        _SettingsSkeletonKind.detail => const _SettingsSkeletonDetailPane(),
        _SettingsSkeletonKind.overlay => const _SettingsOverlaySkeleton(),
      },
    ),
  );
}

/// Returns the shape-preserving placeholder for one adaptive settings slot.
SettingsSkeletonLayout settingsPaneSkeleton(
  SettingsPaneSlot slot, {
  required String semanticLabel,
}) => switch (slot) {
  SettingsPaneSlot.collection => SettingsSkeletonLayout.collection(
    semanticLabel: semanticLabel,
  ),
  SettingsPaneSlot.detail => SettingsSkeletonLayout.detail(
    semanticLabel: semanticLabel,
  ),
};

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

class _SettingsSkeletonListPane extends StatelessWidget {
  const _SettingsSkeletonListPane()
    : super(key: const ValueKey<String>('settings-skeleton-list-pane'));

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      TRPaneHeader(
        title: TRSkeleton(width: TRMeasurements.measureSm),
      ),
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
  Widget build(BuildContext context) => Padding(
    padding: SettingsRow.resolvedPadding(context, collection: true),
    child: const Column(
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
/// The pane boundary supplies the outer inset while collection rows add the
/// same token-sized inline padding used by tree navigation. This keeps
/// selected, hovered, and focused surfaces away from the pane edge while
/// aligning their content with the collection header.
class SettingsCollectionList extends StatelessWidget {
  /// Creates an inset collection with token-based spacing between [children].
  const SettingsCollectionList({required this.children, super.key});

  /// Rows and collection-local headings shown in display order.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.symmetric(
      horizontal: TRSpacing.medium,
      vertical: TRSpacing.medium,
    ),
    itemCount: children.length,
    itemBuilder: (context, index) => children[index],
    separatorBuilder: (context, index) =>
        const SizedBox(height: TRSpacing.extraSmall),
  );
}

class _SettingsSkeletonDetailPane extends StatelessWidget {
  const _SettingsSkeletonDetailPane()
    : super(key: const ValueKey<String>('settings-skeleton-detail-pane'));

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      TRPaneHeader(
        title: TRSkeleton(width: TRMeasurements.measureSm),
        contentMaxWidth: TinestLayoutMetrics.settingsContentMaxWidth,
      ),
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

/// The scroll container every settings pane uses.
///
/// Page padding, content width, and the gap between sections live here rather
/// than in each page. Eight pages that each laid out their own `ListView` were
/// free to drift apart, and every one of them did.
class SettingsScaffold extends StatefulWidget {
  /// Creates a settings pane showing [children] as its sections.
  const SettingsScaffold({required this.children, super.key});

  /// Sections shown in order.
  final List<Widget> children;

  @override
  State<SettingsScaffold> createState() => _SettingsScaffoldState();
}

class _SettingsScaffoldState extends State<SettingsScaffold> {
  double _bottomInset = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextBottomInset = MediaQuery.viewInsetsOf(context).bottom;
    if (nextBottomInset > _bottomInset) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final focusContext = FocusManager.instance.primaryFocus?.context;
        if (focusContext != null) {
          var targetContext = focusContext;
          focusContext.visitAncestorElements((element) {
            if (element.widget is TRTextField ||
                element.widget is TRNumberField ||
                element.widget is TRTextarea) {
              targetContext = element;
              return false;
            }
            return true;
          });
          Scrollable.ensureVisible(
            targetContext,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
      });
    }
    _bottomInset = nextBottomInset;
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(
      TRSpacing.extraLarge,
      TRSpacing.extraLarge,
      TRSpacing.extraLarge,
      TRSpacing.fourExtraLarge,
    ),
    children: <Widget>[
      // Each section stays its own list child rather than sharing one.
      // Folding them into a single child builds every section eagerly, so
      // a finder resolves a section that is scrolled out of view and a tap
      // on it lands outside the viewport and quietly hits nothing.
      for (final (index, child) in widget.children.indexed)
        Padding(
          // tinyrack-check-ignore-next-line tokens/no-literal -- only later sections receive the inter-section token gap
          padding: index > 0
              ? const EdgeInsets.only(top: TRSpacing.twoExtraLarge)
              : EdgeInsets.zero,
          child: Align(
            // Centred, so a wide window keeps the column balanced rather
            // than stranding it against one edge with a growing void.
            // Below the cap the column fills the pane and this is a no-op.
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: TinestLayoutMetrics.settingsContentMaxWidth,
              ),
              child: child,
            ),
          ),
        ),
    ],
  );
}

/// One optionally titled group of settings.
class SettingsSection extends StatelessWidget {
  /// Creates a section whose [children] are [SettingsRow]s sharing one card.
  const SettingsSection({
    required this.children,
    this.title,
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
    required this.children,
    this.title,
    this.description,
    this.action,
    this.banner,
    super.key,
  }) : _boxed = false;

  /// Optional section heading.
  ///
  /// A task page may already name the form in its pane header. Omitting this
  /// heading prevents the same title from being announced and drawn twice.
  final String? title;

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
  Widget build(BuildContext context) {
    final hasHeading = title != null || action != null;
    final hasDescription = description != null;
    final hasBanner = banner != null;
    final hasPreamble = hasHeading || hasDescription || hasBanner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // A Wrap rather than a Row: on a narrow window, or at a large text
        // scale, a heading and its action do not fit on one line. Wrapping is
        // what keeps the action from overflowing, and spaceBetween still puts
        // it against the trailing edge whenever the two do fit.
        if (hasHeading)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: TRSpacing.large,
            runSpacing: TRSpacing.small,
            children: <Widget>[
              if (title case final title?)
                // Section titles are subordinate to the pane header. The
                // smaller public heading role also keeps a long word intact
                // when the system text scale is enlarged on a compact pane.
                TRText(title, variant: TRTextVariant.headingSm),
              ?action,
            ],
          ),
        if (description case final description?) ...<Widget>[
          if (hasHeading) const SizedBox(height: TRSpacing.medium),
          TRText(
            description,
            variant: TRTextVariant.bodySm,
            color: TRTextColor.muted,
          ),
        ],
        if (banner case final banner?) ...<Widget>[
          if (hasHeading || hasDescription)
            const SizedBox(height: TRSpacing.medium),
          banner,
        ],
        if (hasPreamble) const SizedBox(height: TRSpacing.small),
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
}

/// Selects how a setting's control responds to constrained width.
enum SettingsControlLayout {
  /// Keeps the control trailing at every width.
  inline,

  /// Moves the control below the copy when the copy rail becomes too narrow.
  responsive,
}

/// One setting: its description leading, its control trailing or below.
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
    this.controlLayout = SettingsControlLayout.inline,
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
  /// while its content remains aligned with [TRPaneHeader].
  const SettingsRow.collection({
    required this.title,
    this.control,
    this.controlLayout = SettingsControlLayout.inline,
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

  /// How [control] responds when the row's readable copy width is constrained.
  final SettingsControlLayout controlLayout;

  /// Whether [control] is the row's only tab stop.
  ///
  /// Set this whenever [onTap] only repeats what [control] already does, so
  /// one setting costs one Tab press. See [TinestListRow.controlOwnsFocus].
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
    horizontal: TRSpacing.medium,
    vertical: TRSpacing.medium,
  );

  /// Resolves row insets from the inherited UI density.
  ///
  /// Product composites that align custom content with a settings row use
  /// this instead of freezing the standard-density constants above.
  static EdgeInsetsGeometry resolvedPadding(
    BuildContext context, {
    bool flush = false,
    bool collection = false,
  }) {
    final comfortable = TRUiDensityScope.of(context) == TRUiDensity.comfortable;
    final vertical = comfortable ? TRSpacing.large : TRSpacing.medium;
    if (flush) return EdgeInsets.symmetric(vertical: vertical);
    return EdgeInsets.symmetric(
      horizontal: collection ? TRSpacing.medium : TRSpacing.large,
      vertical: vertical,
    );
  }

  EdgeInsetsGeometry _padding(BuildContext context) => resolvedPadding(
    context,
    flush: flush,
    collection: _collection,
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final padding = _padding(context);
      final narrow =
          constraints.maxWidth - padding.horizontal < TRBreakpoints.small;
      final stacksControl =
          control != null &&
          controlLayout == SettingsControlLayout.responsive &&
          narrow;
      return TinestListRow(
        contentPadding: padding,
        controlOwnsFocus: controlOwnsFocus,
        enabled: enabled,
        hoverEnabled: false,
        isThreeLine: wrapsDescription || unboundedDescription,
        unboundedSubtitle: unboundedDescription || (narrow && wrapsDescription),
        leading: leading,
        onTap: onTap,
        selected: selected,
        selectionAppearance: _collection
            ? TinestListRowSelectionAppearance.navigation
            : TinestListRowSelectionAppearance.standard,
        subtitle: description,
        title: title,
        trailing: control,
        trailingLayout: stacksControl
            ? TinestListRowTrailingLayout.below
            : TinestListRowTrailingLayout.inline,
      );
    },
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
          maxWidth: TinestLayoutMetrics.settingsEmptyStateMaxWidth,
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

/// A blocking Settings load failure with one explicit recovery action.
///
/// Settings providers disable automatic retry: silently replacing an error
/// with a loading skeleton hides the failure and makes every page feel
/// different. This state keeps the failure visible until the user retries.
class SettingsErrorState extends StatelessWidget {
  /// Creates a shared Settings error state.
  const SettingsErrorState({
    required this.error,
    required this.onRetry,
    super.key,
  });

  /// Failure reported by the Settings provider.
  final Object error;

  /// Explicitly starts another load attempt.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SettingsEmptyState(
    title: AppLocalizations.of(context).commonActionFailed,
    description: '$error',
    icon: const Icon(TinestIcons.error),
    action: TRButton(
      intent: TRIntent.primary,
      onPressed: onRetry,
      child: TRText.inherit(AppLocalizations.of(context).commonRetry),
    ),
  );
}

/// A list-detail collection failure that preserves the pane's normal header.
///
/// Loading, empty, populated, and failed collection panes keep the same title
/// rail, so status changes do not make the pane geometry jump.
class SettingsCollectionErrorState extends StatelessWidget {
  /// Creates a collection header followed by a shared error state.
  const SettingsCollectionErrorState({
    required this.title,
    required this.error,
    required this.onRetry,
    super.key,
  });

  /// Collection title shown in every state.
  final String title;

  /// Failure reported by the collection provider.
  final Object error;

  /// Explicitly starts another load attempt.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      TRPaneHeader(title: TRText.inherit(title)),
      Expanded(
        child: SettingsErrorState(error: error, onRetry: onRetry),
      ),
    ],
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
      TRSpacing.extraLarge,
      TRSpacing.large,
      TRSpacing.extraLarge,
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
