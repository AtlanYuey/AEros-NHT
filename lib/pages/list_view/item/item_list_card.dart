import 'package:eros_n/common/extension.dart';
import 'package:eros_n/common/provider/settings_provider.dart';
import 'package:eros_n/component/models/gallery.dart';
import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/component/widget/eros_cached_network_image.dart';
import 'package:eros_n/pages/list_view/item/item_base.dart';
import 'package:eros_n/routes/routes.dart';
import 'package:eros_n/utils/get_utils/extensions/export.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const kItemHeight = 172.0;
const kCoverWidth = 112.0;

/// Gallery row in the style of an App Store / Books list entry:
/// rounded artwork on the leading edge, title and tags beside it and an
/// inset hairline separator.
class ItemListCard extends HookConsumerWidget {
  const ItemListCard({
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
    final showTags = ref.watch(settingsProvider.select((s) => s.showTags));
    final palette = context.palette;
    final theme = Theme.of(context);

    final aspectRatio = (gallery.images.thumbnail.imgWidth ?? 300) /
        (gallery.images.thumbnail.imgHeight ?? 400);

    final isBoxFitCover = aspectRatio < 1.2 && aspectRatio > 1 / 2;

    final pages = gallery.images.pages.length;

    return PressableScale(
      scale: 0.98,
      onTap: () async {
        await RouteUtil.goGallery(ref, gallery, heroTag: tabTag);
      },
      child: SizedBox(
        height: kItemHeight,
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  width: kCoverWidth,
                  child: Hero(
                    tag: '${tabTag ?? ''}_${gallery.thumbUrl}',
                    child: CoverArtwork(
                      languageCode: gallery.languageCode,
                      child: ErosCachedNetworkImage(
                        imageUrl: gallery.thumbUrl ?? '',
                        height: gallery.images.thumbnail.imgHeight?.toDouble(),
                        width: gallery.images.thumbnail.imgWidth?.toDouble(),
                        fit: isBoxFitCover ? BoxFit.cover : BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CupertinoActivityIndicator(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: palette.separator, width: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 14, 16, 12),
                    child: ClipRect(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            showTags && context.isPhone
                                ? (gallery.title.englishTitle ?? '').prettyTitle
                                : gallery.title.englishTitle ?? '',
                            textAlign: TextAlign.start,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              height: 1.25,
                            ),
                          ),
                          if (pages > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '$pages P',
                                style: theme.textTheme.labelMedium,
                              ),
                            ),
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.topStart,
                              child: SimpleTagsView(
                                simpleTags: gallery.simpleTags,
                                padding: const EdgeInsets.only(top: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
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
