import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:auto_route/auto_route.dart';

import 'package:eros_n/component/models/comment.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:eros_n/utils/get_utils/extensions/context_extensions.dart';
import 'package:eros_n/utils/logger.dart';
import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/pages/gallery/gallery_view.dart' show CommentAvatar;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../network/app_dio/pdio.dart';
import 'gallery_provider.dart';

@RoutePage()
class CommentsPage extends HookConsumerWidget {
  const CommentsPage({
    Key? key,
    required this.gid,
    this.colorScheme,
  }) : super(key: key);
  final int gid;
  final ColorScheme? colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(galleryProvider(gid).select((g) => g.comments));

    final galleryNotifier =
        useMemoized(() => ref.read(galleryProvider(gid).notifier));

    String? errorText;
    bool isSending = false;

    late StreamSubscription<bool> keyboardSubscription;
    useEffect(() {
      final keyboardVisibilityController = KeyboardVisibilityController();
      keyboardSubscription =
          keyboardVisibilityController.onChange.listen((visible) {
        if (!visible) {
          FocusScope.of(context).requestFocus(FocusNode());
        }
      });
      return () {
        keyboardSubscription.cancel();
      };
    });

    return Theme(
      data: colorScheme == null
          ? Theme.of(context)
          : ThemeConfig.buildTheme(colorScheme!),
      child: Builder(builder: (context) {
        final palette = context.palette;
        final theme = Theme.of(context);
        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  physics: kAppleScrollPhysics,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    AppleSliverNavBar(
                      title: L10n.of(context).comments,
                      heroTag: 'nav_comments_$gid',
                    ),
                    if (comments.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: AppleEmptyState(
                          icon: CupertinoIcons.chat_bubble_2,
                          title: L10n.of(context).no_comments,
                        ),
                      )
                    else
                      CommentsListView(comments: comments),
                  ],
                ),
              ),
              // Composer (iMessage style)
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.bar,
                      border: Border(
                        top: BorderSide(color: palette.separator, width: 0.0),
                      ),
                    ),
                    padding: EdgeInsets.only(
                      left: max(12, context.mediaQueryPadding.left),
                      right: max(8, context.mediaQueryPadding.right),
                      top: 8,
                      bottom: max(8, context.mediaQueryPadding.bottom),
                    ),
                    child: StatefulBuilder(builder: (context, setState) {
                      Future<void> send() async {
                        if (galleryNotifier.commentEditingController.text
                                .trim()
                                .length >
                            10) {
                          try {
                            setState(() {
                              isSending = true;
                            });
                            await galleryNotifier.comment();
                          } on HttpException catch (e) {
                            logger.e('${e.runtimeType} ${e.message}');
                            setState(() {
                              errorText = e.message;
                            });
                          } finally {
                            setState(() {
                              isSending = false;
                            });
                          }
                        } else {
                          setState(() {
                            errorText = L10n.of(context).comment_length_error;
                          });
                        }
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (errorText != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                              child: Text(
                                errorText!,
                                maxLines: 10,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: CupertinoTextField(
                                  enabled: !isSending,
                                  controller:
                                      galleryNotifier.commentEditingController,
                                  placeholder: L10n.of(context).write_comment,
                                  minLines: 1,
                                  maxLines: 5,
                                  style: theme.textTheme.bodyLarge,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: palette.background,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: palette.opaqueSeparator,
                                      width: 0.5,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    if (errorText != null) {
                                      setState(() {
                                        errorText = null;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(36, 36),
                                onPressed: isSending ? null : send,
                                child: isSending
                                    ? const CupertinoActivityIndicator()
                                    : Icon(
                                        CupertinoIcons.arrow_up_circle_fill,
                                        size: 34,
                                        color: theme.colorScheme.primary,
                                      ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class CommentsListView extends StatelessWidget {
  const CommentsListView({
    super.key,
    required this.comments,
  });

  final List<Comment> comments;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      sliver: SliverList.separated(
        itemCount: comments.length,
        itemBuilder: (context, index) {
          final comment = comments[index];
          final date = DateTime.fromMillisecondsSinceEpoch(
              (comment.postDate ?? 0) * 1000);
          final dateFormatted =
              DateFormat('yyyy-MM-dd HH:mm').format(date.toLocal());
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommentAvatar(avatarUrl: comment.poster?.avatarUrl, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              comment.poster?.username ?? '',
                              style: theme.textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateFormatted,
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: ShapeDecoration(
                        color: palette.secondaryBackground,
                        shape: const RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(18),
                          ),
                        ),
                      ),
                      child: SelectableText(
                        comment.commentText ?? '',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(height: 16);
        },
      ),
    );
  }
}
