import 'dart:ui';

import 'package:eros_n/common/enum.dart';
import 'package:eros_n/common/provider/settings_provider.dart';
import 'package:eros_n/component/models/index.dart';
import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/component/widget/blur_image.dart';
import 'package:eros_n/component/widget/eros_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CoverImg extends StatelessWidget {
  const CoverImg({
    Key? key,
    required this.imgUrl,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  final String imgUrl;
  final double? height;
  final double? width;

  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget image() {
      if (imgUrl.isNotEmpty) {
        return ErosCachedNetworkImage(
          imageUrl: imgUrl,
          width: width,
          height: height,
          fit: fit,
        );
      } else {
        return Container();
      }
    }

    return Consumer(
      builder: (context, ref, child) {
        final isCoverBlur = ref
            .watch(settingsProvider.select((settings) => settings.isCoverBlur));
        return BlurImage(
          blur: isCoverBlur,
          sigma: 8,
          child: child!,
        );
      },
      child: image(),
    );
  }
}

class SimpleTagsView extends HookConsumerWidget {
  const SimpleTagsView({
    Key? key,
    required this.simpleTags,
    this.padding = const EdgeInsets.symmetric(horizontal: 6),
    this.tagLayoutOnItem,
    this.color,
    this.borderColor,
  }) : super(key: key);

  final List<Tag> simpleTags;
  final EdgeInsetsGeometry? padding;
  final TagLayoutOnItem? tagLayoutOnItem;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showTags = ref.watch(settingsProvider.select((s) => s.showTags));
    final tagLayoutOnItem =
        ref.watch(settingsProvider.select((s) => s.tagLayoutOnItem));

    if (!showTags || simpleTags.isEmpty) {
      return const SizedBox();
    }

    final tags = simpleTags.take(10).toList();
    // final tags = gallery.simpleTags;

    switch (this.tagLayoutOnItem ?? tagLayoutOnItem) {
      // case TagLayoutOnItem.row:
      //   return SingleChildScrollView(
      //     scrollDirection: Axis.horizontal,
      //     child: Container(
      //       padding: padding,
      //       child: Row(
      //         children: [
      //           ...tags
      //               .where((tag) => tag.name != null)
      //               .map((e) => SimpleTag(tag: e).paddingOnly(right: 4)),
      //         ],
      //       ),
      //     ),
      //   );

      case TagLayoutOnItem.singleLine:
        return SizedBox(
          height: 22,
          child: ListView.builder(
            padding: padding,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final tag = tags[index];

              if (tag.name == null) {
                return const SizedBox();
              }

              return Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.only(right: 4),
                child:
                    SimpleTag(tag: tag, color: color, borderColor: borderColor),
              );
            },
            itemCount: tags.length,
          ),
        );
      case TagLayoutOnItem.wrap:
        return Container(
          padding: padding,
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: tags
                .where((tag) => tag.name != null)
                .map((tag) =>
                    SimpleTag(tag: tag, color: color, borderColor: borderColor))
                .toList(),
          ),
        );
    }
  }
}

class SimpleTag extends HookConsumerWidget {
  const SimpleTag({
    Key? key,
    required this.tag,
    this.color,
    this.borderColor,
  }) : super(key: key);
  final Tag tag;

  /// Text color.
  final Color? color;

  /// Background color of the capsule.
  final Color? borderColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTagTranslate =
        ref.watch(settingsProvider.select((value) => value.isTagTranslate));

    return AppleTagChip(
      dense: true,
      label: isTagTranslate ? tag.translatedName ?? '' : tag.name ?? '',
      textColor: color,
      color: borderColor,
    );
  }
}

/// Small frosted capsule with the gallery language, shown on covers.
class LanguageBadge extends StatelessWidget {
  const LanguageBadge({super.key, required this.languageCode});

  final String? languageCode;

  static bool shouldShow(String? languageCode) =>
      languageCode != null && languageCode != 'ja';

  @override
  Widget build(BuildContext context) {
    if (!shouldShow(languageCode)) {
      return const SizedBox.shrink();
    }
    return ClipRSuperellipse(
      borderRadius: BorderRadius.circular(6),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
          color: Colors.black.withValues(alpha: 0.45),
          child: Text(
            languageCode!.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded cover artwork with a soft shadow and optional language badge.
class CoverArtwork extends StatelessWidget {
  const CoverArtwork({
    super.key,
    required this.child,
    this.languageCode,
    this.radius = 10,
    this.shadow = true,
  });

  final Widget child;
  final String? languageCode;
  final double radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.5 : 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRSuperellipse(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            ColoredBox(
              color: context.palette.secondaryBackground,
              child: child,
            ),
            if (LanguageBadge.shouldShow(languageCode))
              Positioned(
                left: 6,
                top: 6,
                child: LanguageBadge(languageCode: languageCode),
              ),
            // hairline inner border keeps light covers from bleeding into
            // the background
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(radius),
                      side: BorderSide(
                        color: (dark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.08),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
