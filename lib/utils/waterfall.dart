import 'package:PiliPlus/common/skeleton/dynamic_card.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/utils/global_data.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SliverConstraints;
import 'package:waterfall_flow/waterfall_flow.dart'
    show SliverWaterfallFlowDelegate, SliverWaterfallFlow;

/// 动态页布局模式
/// 0 = 瀑布流（不等高，自动列数）
/// 1 = 网格对齐（等高，可调列数）
/// 2 = 单列列表
int _layoutMode() => GlobalData().dynamicLayoutMode;
bool _isGrid() => _layoutMode() == 1;

mixin DynMixin {
  late final dynGridDelegate =
      SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: Grid.smallCardWidth * 2,
        crossAxisSpacing: 4,
      );

  Widget buildPage(Widget child) {
    // 瀑布流和网格模式：加左右 12px 内边距
    if (_layoutMode() != 2) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: Style.safeSpace),
        sliver: child,
      );
    }
    // 单列列表模式：居中
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.crossAxisExtent;
        final cardWidth = Grid.smallCardWidth * 2;
        final flag = cardWidth < maxWidth;
        return SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: flag ? (maxWidth - cardWidth) / 2 : Style.safeSpace,
          ),
          sliver: child,
        );
      },
    );
  }

  late final skeDelegate = SliverGridDelegateWithExtentAndRatio(
    crossAxisSpacing: 4,
    mainAxisSpacing: 4,
    maxCrossAxisExtent: Grid.smallCardWidth * 2,
    childAspectRatio: Style.aspectRatio,
    mainAxisExtent: 50,
  );

  Widget get dynSkeleton {
    if (_isGrid()) {
      return SliverGrid(
        gridDelegate: SliverGridDelegateWithExtentAndRatio(
          maxCrossAxisExtent: Pref.recommendCardWidth,
          mainAxisSpacing: Style.cardSpace,
          crossAxisSpacing: Style.cardSpace,
          childAspectRatio: Style.aspectRatio,
          mainAxisExtent: 78,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, _) => const DynamicCardSkeleton(),
          childCount: 10,
        ),
      );
    }
    if (GlobalData().dynamicsWaterfallFlow) {
      return SliverGrid.builder(
        gridDelegate: skeDelegate,
        itemBuilder: (_, _) => const DynamicCardSkeleton(),
        itemCount: 10,
      );
    }
    return SliverPrototypeExtentList.builder(
      prototypeItem: const DynamicCardSkeleton(),
      itemBuilder: (_, _) => const DynamicCardSkeleton(),
      itemCount: 10,
    );
  }

  /// 统一构建动态列表内容（瀑布流 / 网格对齐 / 单列）
  Widget buildDynamicContent({
    required BuildContext context,
    required int itemCount,
    required NullableIndexedWidgetBuilder itemBuilder,
    NullableIndexedWidgetBuilder? gridItemBuilder,
    VoidCallback? onLoadMore,
  }) {
    final g = GlobalData();
    switch (g.dynamicLayoutMode) {
      case 0: // 瀑布流
        return SliverWaterfallFlow(
          gridDelegate: dynGridDelegate,
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == itemCount - 1) onLoadMore?.call();
              return itemBuilder(context, index);
            },
            childCount: itemCount,
          ),
        );
      case 1: // 网格对齐
        // 高度 = 16:10 封面 + 文字信息区
        const spacing = 20.0;
        final textAreaHeight = MediaQuery.textScalerOf(context).scale(78.0);
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithExtentAndRatio(
            maxCrossAxisExtent: Pref.recommendCardWidth,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: Style.aspectRatio,
            mainAxisExtent: textAreaHeight,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == itemCount - 1) onLoadMore?.call();
              // 网格模式使用专用紧凑卡片
              return (gridItemBuilder ?? itemBuilder)(context, index);
            },
            childCount: itemCount,
          ),
        );
      case 2: // 单列列表
      default:
        return SliverList.builder(
          itemBuilder: (context, index) {
            if (index == itemCount - 1) onLoadMore?.call();
            return itemBuilder(context, index);
          },
          itemCount: itemCount,
        );
    }
  }
}

class SliverWaterfallFlowDelegateWithMaxCrossAxisExtent
    extends SliverWaterfallFlowDelegate {
  /// Creates a delegate that makes masonry layouts with tiles that have a maximum
  /// cross-axis extent.
  ///
  /// All of the arguments must not be null. The [maxCrossAxisExtent],
  /// [mainAxisSpacing], and [crossAxisSpacing] arguments must not be negative.
  SliverWaterfallFlowDelegateWithMaxCrossAxisExtent({
    required this.maxCrossAxisExtent,
    super.mainAxisSpacing,
    super.crossAxisSpacing,
    super.lastChildLayoutTypeBuilder,
    super.collectGarbage,
    super.viewportBuilder,
    super.closeToTrailing,
  }) : assert(maxCrossAxisExtent >= 0);

  /// The maximum extent of tiles in the cross axis.
  ///
  /// This delegate will select a cross-axis extent for the tiles that is as
  /// large as possible subject to the following conditions:
  ///
  ///  - The extent evenly divides the cross-axis extent of the grid.
  ///  - The extent is at most [maxCrossAxisExtent].
  ///
  /// For example, if the grid is vertical, the grid is 500.0 pixels wide, and
  /// [maxCrossAxisExtent] is 150.0, this delegate will create a grid with 4
  /// columns that are 125.0 pixels wide.
  final double maxCrossAxisExtent;

  int? crossAxisCount;
  double? crossAxisExtent;

  @override
  int getCrossAxisCount(SliverConstraints constraints) {
    final crossAxisExtent = constraints.crossAxisExtent;
    if (crossAxisCount != null && this.crossAxisExtent == crossAxisExtent) {
      return crossAxisCount!;
    }
    this.crossAxisExtent = crossAxisExtent;
    crossAxisCount = (crossAxisExtent / (maxCrossAxisExtent + crossAxisSpacing))
        .ceil();
    return crossAxisCount!;
  }

  @override
  bool shouldRelayout(SliverWaterfallFlowDelegate oldDelegate) {
    final flag =
        (oldDelegate.runtimeType != runtimeType) ||
        (oldDelegate is SliverWaterfallFlowDelegateWithMaxCrossAxisExtent &&
            (oldDelegate.maxCrossAxisExtent != maxCrossAxisExtent ||
                super.shouldRelayout(oldDelegate)));
    if (flag) {
      crossAxisCount = null;
    }
    return flag;
  }
}
