import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/nest_theme.dart';

/// Photo that fades in. Works with bundled assets and with files saved on
/// the phone (paths starting with "/"). If the image is missing, shows a
/// colored placeholder (with the expected filename in debug builds).
class NestImage extends StatelessWidget {
  const NestImage({
    super.key,
    required this.asset,
    required this.tone,
    required this.icon,
    this.cacheWidth = 720,
  });

  final String asset;
  final Color tone;
  final IconData icon;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    final isFile = asset.startsWith('/');

    Widget frame(
      BuildContext context,
      Widget child,
      int? frame,
      bool wasSynchronouslyLoaded,
    ) {
      if (wasSynchronouslyLoaded) return child;
      return AnimatedOpacity(
        opacity: frame == null ? 0 : 1,
        duration: NestMotion.base,
        curve: Curves.easeOut,
        child: child,
      );
    }

    Widget missing(BuildContext context, Object error, StackTrace? stack) =>
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 44,
                  color: NestColors.charcoal.withValues(alpha: 0.35),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 8),
                  Text(
                    asset.split('/').last,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: NestText.label.copyWith(
                      fontSize: 9,
                      letterSpacing: 0.4,
                      color: NestColors.charcoal.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

    return ColoredBox(
      color: tone,
      child: isFile
          ? Image.file(
              File(asset),
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              cacheWidth: cacheWidth,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              frameBuilder: frame,
              errorBuilder: missing,
            )
          : Image.asset(
              asset,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              cacheWidth: cacheWidth,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              frameBuilder: frame,
              errorBuilder: missing,
            ),
    );
  }
}
