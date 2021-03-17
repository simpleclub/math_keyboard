import 'package:flutter/material.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:math_keyboard_demo/data/strings.dart';
import 'package:math_keyboard_demo/widgets/link_button.dart';
import 'package:math_keyboard_demo/widgets/page_view.dart';
import 'package:url_launcher/url_launcher.dart';

/// Scaffold for the demo page.
class DemoScaffold extends StatelessWidget {
  /// Creates a [DemoScaffold] widget.
  const DemoScaffold({
    Key? key,
    required this.onToggleBrightness,
  }) : super(key: key);

  /// Called when the brightness toggle is tapped.
  final void Function() onToggleBrightness;

  @override
  Widget build(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    final buttons = [
      LinkButton(
        label: pubLabel,
        url: pubUrl,
        child: Image.network(pubBadgeUrl),
      ),
      LinkButton(
        label: gitHubLabel,
        url: gitHubUrl,
        child: Image.network(darkMode ? darkGitHubIconUrl : lightGitHubIconUrl),
      ),
      const LinkButton(
        label: docsLabel,
        url: docsUrl,
      ),
    ];

    return MathKeyboardViewInsets(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size(0, 42 + 16 * 2),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: brightnessSwitchTooltip,
                      onPressed: onToggleBrightness,
                      splashRadius: 20,
                      icon: Icon(darkMode
                          ? Icons.brightness_6_outlined
                          : Icons.brightness_2_outlined),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 3,
                        bottom: 3,
                      ),
                      child: MouseRegion(
                        cursor: MaterialStateMouseCursor.clickable,
                        child: GestureDetector(
                          onTap: () {
                            launch(gitHubUrl);
                          },
                          child: Text(
                            header,
                            style:
                                Theme.of(context).textTheme.headline5?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                thickness: 1,
                height: 0,
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Material(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 64,
                                right: 64,
                                bottom: 8,
                              ),
                              child: Text.rich(
                                TextSpan(
                                  children: const [
                                    TextSpan(
                                      text: descriptionPrefix,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' $description',
                                    ),
                                  ],
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline5
                                      ?.copyWith(
                                        fontSize: 28,
                                      ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (constraints.maxWidth < 6e2) ...[
                              for (final button in buttons)
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: button,
                                ),
                            ] else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (final button in buttons)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 16,
                                      ),
                                      child: button,
                                    ),
                                ],
                              ),
                            const Padding(
                              padding: EdgeInsets.only(
                                top: 32,
                              ),
                              child: DemoPageView(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SizedBox(
          height: 42 + 16 * 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(
                thickness: 1,
                height: 0,
              ),
              MouseRegion(
                cursor: MaterialStateMouseCursor.clickable,
                child: GestureDetector(
                  onTap: () {
                    launch(organizationUrl);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Image.network(
                      darkMode ? darkLogoUrl : lightLogoUrl,
                      height: 42,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
