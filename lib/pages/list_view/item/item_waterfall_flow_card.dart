import 'package:eros_n/common/enum.dart';
import 'package:eros_n/common/extension.dart';
import 'package:eros_n/common/provider/settings_provider.dart';
import 'package:eros_n/component/models/gallery.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/pages/list_view/item/item_base.dart';
import 'package:eros_n/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Masonry tile. The regular variant shows the artwork with the title and
/// tags beneath; the compact variant overlays them on a soft gradient.
class ItemWaterfallFlowCard extends HookConsumerWidget {
  const ItemWaterfallFlowCard({
    Key? key,
    required this.gallery,
    this.index,
    this.page,
    this.tabTag,
    this.compact = false,
  }) : super(key: key);

  final Gallery gallery;
  final int? index;
  final int? page;
  final String? tabTag;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showTags = ref.watch(settingsProvider.select((s) => s.showTags));
    final Widget item = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildCoverImage(context, compact, showTags),
        if (!compact) buildTitle(context),
        if (!compact)
          SimpleTagsView(
            simpleTags: gallery.simpleTags,
            padding: const EdgeInsets.only(left: 2, right: 2, bottom: 4),
          ),
      ],
    );

    return PressableScale(
      onTap: () async {
        await RouteUtil.goGallery(ref, gallery, heroTag: tabTag);
      },
      child: item,
    );
  }

  Widget buildCoverImage(BuildContext context, bool compact, bool showTags) {
    Widget coverImage = CoverImg(
      imgUrl: gallery.thumbUrl ?? '',
      fit: BoxFit.contain,
    );

    if (compact) {
      coverImage = Stack(
        fit: StackFit.expand,
        children: [
          coverImage,
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.45, 1],
                colors: [Colors.transparent, Color(0xB3000000)],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 20,
                  child: SimpleTagsView(
                    simpleTags: gallery.simpleTags,
                    tagLayoutOnItem: TagLayoutOnItem.singleLine,
                    color: Colors.white,
                    borderColor: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: Text(
                    (gallery.title.englishTitle ?? '').prettyTitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Hero(
      tag: '${tabTag ?? ''}_${gallery.thumbUrl}',
      child: AspectRatio(
        aspectRatio: (gallery.images.thumbnail.imgWidth ?? 300) /
            (gallery.images.thumbnail.imgHeight ?? 400),
        child: CoverArtwork(
          radius: 12,
          languageCode: gallery.languageCode,
          child: coverImage,
        ),
      ),
    );
  }

  Widget buildTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
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
    );
  }
}
