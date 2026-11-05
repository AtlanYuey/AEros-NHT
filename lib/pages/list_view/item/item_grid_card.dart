import 'package:eros_n/common/extension.dart';
import 'package:eros_n/component/models/gallery.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/component/widget/eros_cached_network_image.dart';
import 'package:eros_n/pages/list_view/item/item_base.dart';
import 'package:eros_n/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Grid视图参数
const double gridCrossAxisSpacing = 12.0;
const double gridMainAxisSpacing = 16.0;
const double gridMaxCrossAxisExtent = 150.0;
const double gridChildAspectRatio = 1 / 1.72;

/// Artwork-first grid tile (Apple Books / Photos style): a rounded cover
/// with the title below it and no card chrome.
class ItemGridCard extends HookConsumerWidget {
  const ItemGridCard({
    Key? key,
    required this.gallery,
    this.index,
    this.page,
    this.tabTag,
  }) : super(key: key);

  final Gallery gallery;
  final int? index;
  final int? page;
  final String? tabTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aspectRatio = (gallery.images.thumbnail.imgWidth ?? 300) /
        (gallery.images.thumbnail.imgHeight ?? 400);

    final isBoxFitCover = aspectRatio < 1.2 && aspectRatio > 1 / 2;

    return PressableScale(
      onTap: () async {
        await RouteUtil.goGallery(ref, gallery, heroTag: tabTag);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Hero(
              tag: '${tabTag ?? ''}_${gallery.thumbUrl}',
              child: CoverArtwork(
                languageCode: gallery.languageCode,
                child: ErosCachedNetworkImage(
                  imageUrl: gallery.thumbUrl ?? '',
                  height: gallery.images.thumbnail.imgHeight?.toDouble(),
                  width: gallery.images.thumbnail.imgWidth?.toDouble(),
                  fit: isBoxFitCover ? BoxFit.cover : BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: Text(
              (gallery.title.englishTitle ?? '').prettyTitle,
              textAlign: TextAlign.start,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
