import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MyUrlLauncher extends StatelessWidget {
  final Widget child;
  final String url;

  const MyUrlLauncher({
    super.key,
    required this.child,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: child,
      ),
    );
  }
}
