import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:math_keyboard_demo/data/strings.dart';
import 'package:math_keyboard_demo/widgets/editable_mixed_text_field.dart';
import 'package:math_keyboard_demo/widgets/link_button.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
        child: SvgPicture.network(pubBadgeUrl),
      ),
      LinkButton(
        label: gitHubLabel,
        url: gitHubUrl,
        child: Stack(
          children: [
            // Always insert both icons into the tree in order to prevent the
            // layout from jumping around when changing the brightness (because
            // the dark version would need to be loaded later).
            Image.network(darkGitHubIconUrl),
            if (!darkMode) Image.network(lightGitHubIconUrl),
          ],
        ),
      ),
      const LinkButton(
        label: docsLabel,
        url: docsUrl,
      ),
    ];

    SystemChrome.setSystemUIOverlayStyle(
        darkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);

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
                    // IconButton(
                    //   tooltip: brightnessSwitchTooltip,
                    //   onPressed: onToggleBrightness,
                    //   splashRadius: 20,
                    //   icon: Icon(darkMode
                    //       ? Icons.brightness_6_outlined
                    //       : Icons.brightness_2_outlined),
                    // ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 3,
                        bottom: 3,
                      ),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            launchUrlString(gitHubUrl);
                          },
                          child: Text(
                            header,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
        // body: Material(
        //   child: Padding(
        //     padding: EdgeInsets.only(
        //       top: 32,
        //     ),
        //     child: EditableMixedTextField(),
        //   ),
        // ),
        // bottomNavigationBar: SizedBox(
        //   height: 42 + 16 * 2,
        //   child: Column(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       const Divider(
        //         thickness: 1,
        //         height: 0,
        //       ),
        //       MouseRegion(
        //         cursor: SystemMouseCursors.click,
        //         child: GestureDetector(
        //           onTap: () {
        //             launchUrlString(organizationUrl);
        //           },
        //           child: Padding(
        //             padding: const EdgeInsets.all(16),
        //             child: Image.network(
        //               darkMode ? darkLogoUrl : lightLogoUrl,
        //               height: 42,
        //             ),
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ),
    );
  }
}
