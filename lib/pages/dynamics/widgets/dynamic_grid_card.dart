import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/num_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:flutter/material.dart';

/// 动态页网格模式使用的紧凑卡片，类似首页推荐 VideoCardV。
class DynamicGridCard extends StatelessWidget {
  final DynamicItemModel item;

  const DynamicGridCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final video = _resolveVideo();
    // 尝试从转发内容或图文内容中提取封面
    final coverUrl = video?.cover ?? _extractCover();
    final stat = video?.stat;
    final pubTs = item.modules.moduleAuthor?.pubTs;

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => PageUtils.pushDynDetail(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === 封面区域 (16:10) ===
            AspectRatio(
              aspectRatio: Style.aspectRatio,
              child: _buildCover(theme, coverUrl, video, stat),
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
                    // 标题 — Expanded 撑满剩余空间
                    Expanded(
                      child: Text(
                        video?.title ?? _contentPreview(),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(height: 1.38),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // 底部操作图标
                    Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.more_horiz,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
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

  /// 从非视频类型中提取封面（转发/图文等）
  String? _extractCover() {
    // 转发 — 查看原动态是否有封面
    if (item.type == 'DYNAMIC_TYPE_FORWARD') {
      return item.orig?.modules.moduleDynamic?.major?.archive?.cover ??
          item.orig?.modules.moduleDynamic?.major?.ugcSeason?.cover ??
          item.orig?.modules.moduleDynamic?.major?.pgc?.cover;
    }
    // 图文动态 — 取第一张图片
    final opus = item.modules.moduleDynamic?.major?.opus;
    final pics = opus?.pics;
    if (pics != null && pics.isNotEmpty) {
      return pics.first.url ?? pics.first.src;
    }
    return null;
  }

  /// 封面区域
  Widget _buildCover(
    ThemeData theme,
    String? coverUrl,
    DynamicArchiveModel? video,
    Stat? stat,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final coverWidth = constraints.maxWidth;
        final coverHeight = constraints.maxHeight;

        if (coverUrl != null) {
          // 有封面图
          return Stack(
            children: [
              NetworkImgLayer(
                src: coverUrl,
                width: coverWidth,
                height: coverHeight,
                quality: 40,
              ),
              // badge（充电专属等）
              if (video?.badge?.text case final badge?)
                PBadge(
                  text: badge,
                  top: 6,
                  right: 8,
                  bottom: null,
                  left: null,
                  type:
                      badge == '充电专属' ? PBadgeType.error : PBadgeType.primary,
                ),
              // 底部信息条：左-播放/弹幕，右-时长
              if (stat != null || video?.durationText != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (pubTs != null && pubTs > 0)
                          Text(
                            DateFormatUtils.dateFormat(pubTs),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        if (pubTs != null && pubTs > 0 && stat != null)
                          const SizedBox(width: 6),
                        if (stat != null) ...[
                          Text(
                            '${NumUtils.numFormat(stat.play)}播放',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${NumUtils.numFormat(stat.danmu)}弹幕',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (video?.durationText case final durationText?)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              durationText,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }

        // 无封面：渐变占位 + 类型图标
        final moduleDynamic = item.modules.moduleDynamic;
        final descText = moduleDynamic?.desc?.text ??
            moduleDynamic?.major?.opus?.summary?.text;

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
                    item.type == 'DYNAMIC_TYPE_FORWARD'
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
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 内容预览文字
  String _contentPreview() {
    final md = item.modules.moduleDynamic;
    final desc = md?.desc?.text ?? md?.major?.opus?.summary?.text;
    if (desc != null && desc.isNotEmpty) return desc;

    if (item.type == 'DYNAMIC_TYPE_FORWARD') {
      // 转发：显示原动态的标题或文字
      final orig = item.orig?.modules.moduleDynamic;
      final origTitle = orig?.major?.archive?.title ??
          orig?.major?.ugcSeason?.title ??
          orig?.major?.pgc?.title;
      if (origTitle != null) return '转发：$origTitle';
      final origDesc = orig?.desc?.text ?? orig?.major?.opus?.summary?.text;
      if (origDesc != null && origDesc.isNotEmpty) return '转发：$origDesc';
      return '转发动态';
    }

    return switch (item.type) {
      'DYNAMIC_TYPE_LIVE' => '直播中',
      'DYNAMIC_TYPE_LIVE_RCMD' => '直播推荐',
      'DYNAMIC_TYPE_SUBSCRIPTION_NEW' => '订阅更新',
      'DYNAMIC_TYPE_WORD' => '图文动态',
      _ => '动态',
    };
  }
}
