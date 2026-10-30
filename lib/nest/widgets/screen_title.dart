import 'package:flutter/material.dart';

import '../core/nest_theme.dart';

class ScreenTitle extends StatelessWidget {
  const ScreenTitle({
    super.key,
    required this.lead,
    required this.emphasis,
    this.subtitle,
  });

  final String lead;
  final String emphasis;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: '$lead ',
            children: [
              TextSpan(
                text: emphasis,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: NestColors.cobalt,
                ),
              ),
            ],
          ),
          style: NestText.display(46),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              subtitle!.toUpperCase(),
              style: NestText.label.copyWith(color: NestColors.muted),
            ),
          ),
      ],
    );
  }
}
