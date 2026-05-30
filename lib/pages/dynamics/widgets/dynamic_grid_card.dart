import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/utils/num_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:flutter/material.dart';

/// 动态页网格模式使用的紧凑卡片，类似首页推荐 VideoCardV。
/// 所有卡片高度统一：16:10 封面/占位区 + 文字信息区
class DynamicGridCard extends StatelessWidget {
  final DynamicItemModel item;

  const DynamicGridCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final video = _resolveVideo();
    final stat = video?.stat;

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => PageUtils.pushDynDetail(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === 封面/占位区域 (16:10) ===
            AspectRatio(
              aspectRatio: Style.aspectRatio,
              child: _buildCover(theme, video),
            ),
            // === 文字信息区 ===
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // UP主名
                    Text(
                      item.modules.moduleAuthor?.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: theme.textTheme.labelSmall?.fontSize,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // 标题/内容预览
                    Expanded(
                      child: Text(
                        video?.title ?? _contentPreview(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(height: 1.38),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // 底部操作行
                    Row(
                      children: [
                        if (stat != null) ...[
                          Text(
                            '${NumUtils.numFormat(stat.play)}播放',
                            style: TextStyle(
                              fontSize: theme.textTheme.labelSmall?.fontSize,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          if (item.type == 'DYNAMIC_TYPE_AV') ...[
                            const SizedBox(width: 4),
                            Text(
                              '${NumUtils.numFormat(stat.danmu)}弹幕',
                              style: TextStyle(
                                fontSize:
                                    theme.textTheme.labelSmall?.fontSize,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ],
                        const Spacer(),
                        Icon(
                          Icons.more_horiz,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取视频信息（视频/合集/番剧/课程）
  DynamicArchiveModel? _resolveVideo() {
    return switch (item.type) {
      'DYNAMIC_TYPE_AV' => item.modules.moduleDynamic?.major?.archive,
      'DYNAMIC_TYPE_UGC_SEASON' =>
        item.modules.moduleDynamic?.major?.ugcSeason,
      'DYNAMIC_TYPE_PGC' || 'DYNAMIC_TYPE_PGC_UNION' =>
        item.modules.moduleDynamic?.major?.pgc,
      'DYNAMIC_TYPE_COURSES_SEASON' =>
        item.modules.moduleDynamic?.major?.courses,
      _ => null,
    };
  }

  /// 封面区域
  Widget _buildCover(ThemeData theme, DynamicArchiveModel? video) {
    if (video?.cover case final cover?) {
      // 视频类型：显示封面
      return Stack(
        children: [
          NetworkImgLayer(
            src: cover,
            width: double.infinity,
            height: double.infinity,
            quality: 40,
          ),
          if (video?.badge?.text case final badge?)
            PBadge(
              text: badge,
              top: 6,
              right: 8,
              bottom: null,
              left: null,
              type: badge == '充电专属' ? PBadgeType.error : PBadgeType.primary,
            ),
          if (video?.durationText case final durationText?)
            PBadge(
              bottom: 6,
              right: 7,
              size: .small,
              type: .gray,
              text: durationText,
            ),
        ],
      );
    }

    // 非视频类型：显示占位色 + 类型图标 + 文字预览
    final moduleDynamic = item.modules.moduleDynamic;
    final descText = moduleDynamic?.desc?.text ??
        moduleDynamic?.major?.opus?.summary?.text;
    final opusPics = moduleDynamic?.major?.opus?.pics;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                opusPics != null && opusPics.isNotEmpty
                    ? Icons.photo_library_outlined
                    : item.type == 'DYNAMIC_TYPE_FORWARD'
                        ? Icons.replay
                        : Icons.article_outlined,
                size: 24,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              if (descText != null && descText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  descText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 非视频类型的内容预览文字
  String _contentPreview() {
    final moduleDynamic = item.modules.moduleDynamic;
    final descText =
        moduleDynamic?.desc?.text ?? moduleDynamic?.major?.opus?.summary?.text;
    if (descText != null && descText.isNotEmpty) return descText;

    return switch (item.type) {
      'DYNAMIC_TYPE_FORWARD' => '转发动态',
      'DYNAMIC_TYPE_LIVE' => '直播中',
      'DYNAMIC_TYPE_LIVE_RCMD' => '直播推荐',
      'DYNAMIC_TYPE_SUBSCRIPTION_NEW' => '订阅更新',
      'DYNAMIC_TYPE_WORD' => '图文动态',
      _ => '动态',
    };
  }
}
