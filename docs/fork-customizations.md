# PiliPlus fork 定制改动清单（合并上游后逐条复查）

> 迁移自 fork 自身的 `AGENTS.md`（2026-10-15 版）同名小节，逐条内容完整保留。
> `AGENTS.md` §3 只留复查用的短清单；本文件保留每条改动的完整说明与原因，供合并/排查时展开。

## 1. 动态页只看视频

- `DynamicsTabType` 无 `all`（只有视频 / 番剧 / UP，默认视频）。
- `followDynamic` 的 UP 标签附 `type:'video'`。
- `up_panel.dart` 首项「全部视频」点击即切到视频标签。

## 2. UP 主分页

- `up_panel.dart` 末项触发 `controller.onLoadMore()`，否则第一页 UP 主不续载。

## 3. 动态页布局

- `dynamics/view.dart` 三种停靠模式自绘 Divider（`outlineVariant` α0.1）。
- 布局模式 0/1/2 = 瀑布流 / 网格对齐 / 单列居中；开关 `GlobalData.dynamicLayoutMode`，实现在 `lib/utils/waterfall.dart`。

## 4. 卡片与设置项

- 推荐页卡片显示发布时间（`RcmdVideoItemAppModel.pubdate`）。
- 设置项 `cardSpacing` / `edgePadding`（`SettingBoxKey`）。

## 5. 更新检查

- `lib/utils/update.dart` 指向本仓库 `/releases/latest`。

## 6. 动态类型索引持久化

- `Pref.defaultDynamicTypeIndex` 按 enum `name` 存储、兼容旧 int 索引，防上游增删 tab 后错位。

## 7. 竖屏视频（本 fork 独有，别丢）

上游改读 `card_goto` 后，本 fork 仍接受 `vertical_av`：

- `RcmdOwner`（`rcmd/result.dart`）——不改则作者名退化成「竖屏」角标文案。
- `video_card_v.dart` 与 `video_card_v_member_home.dart` 认 `'av'||'vertical_av'`。
- `app_scheme.dart` 认 `'video'||'story'`，使 story 深链可用。
- 不要为了统一把 `goto` 改成 `av`；`feedDislike` 要原样回传。

## 8. 成员页

- `member/view.dart` TabBar 固定 45 高不滚动。
- `member/controller.dart` 默认选中观看记录。
- 以上属**刻意定制**，别当遗留失误回退。

（2026-10-16 迁移整理）
