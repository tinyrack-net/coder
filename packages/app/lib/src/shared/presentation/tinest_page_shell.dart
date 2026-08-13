import 'package:flutter/widgets.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// The standard Tinest page shell backed by [TRAppShell].
class TinestPageShell extends StatelessWidget {
  /// Creates a page with optional top chrome.
  const TinestPageShell({required this.body, this.appBar, super.key});

  /// Page content.
  final Widget body;

  /// Optional page header.
  final TinestPageHeader? appBar;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.tinyrackTheme.surface,
    child: SafeArea(
      child: TRAppShell(
        header: appBar == null
            ? null
            : TRAppShellHeader(
                borderBottom: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: TRSpacing.small,
                  vertical: TRSpacing.extraSmall,
                ),
                children: [
                  ?appBar!.leading,
                  Expanded(
                    child: DefaultTextStyle.merge(
                      style: TRTypography.resolve(
                        context,
                        TRTextVariant.headingSm,
                      ),
                      softWrap: true,
                      child: appBar!.title,
                    ),
                  ),
                  ...appBar!.actions,
                ],
              ),
        main: TRAppShellMain(child: body),
      ),
    ),
  );
}

/// Declarative content for a [TinestPageShell] header.
class TinestPageHeader {
  /// Creates a page header.
  const TinestPageHeader({
    required this.title,
    this.actions = const [],
    this.leading,
  });

  /// Header title.
  final Widget title;

  /// Optional leading navigation action.
  final Widget? leading;

  /// Trailing page actions.
  final List<Widget> actions;
}
