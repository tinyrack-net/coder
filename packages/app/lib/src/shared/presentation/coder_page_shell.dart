import 'package:flutter/widgets.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// The standard Coder page shell backed by [TRAppShell].
class CoderPageShell extends StatelessWidget {
  /// Creates a page with optional top chrome.
  const CoderPageShell({required this.body, this.appBar, super.key});

  /// Page content.
  final Widget body;

  /// Optional page header.
  final CoderPageHeader? appBar;

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
                      style: TRTypography.headingSm,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

/// Declarative content for a [CoderPageShell] header.
class CoderPageHeader {
  /// Creates a page header.
  const CoderPageHeader({
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
