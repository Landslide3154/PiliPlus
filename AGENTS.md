# AGENTS.md — PiliPlus (fork)

PiliPlus（本地路径 `D:\code\PiliPlus`）是用户 fork 维护的 B 站客户端（Flutter + GetX，Android/Win/Linux/macOS/iOS）。
- origin = `Landslide3154/PiliPlus`（fork 版本号 = 上游 baseVersion + 序号）
- upstream = `bggRGjQaUbCoE/PiliPlus`（活跃）
- 当前已发布版本、上游当前版本、上游 Flutter 版本这类**会持续漂移**的数字不写在这里，见 DSH 记忆空间「PiliPlus」（`mnemon_recall` 检索）

## 合并上游

- `git fetch upstream` 后**先检查 upstream/main 是否又前进**（曾出现 fetch 后上游已发新 release 的情况），直接合并到最新而不是旧 head
- 本地未提交工作区（.vscode/.reasonix 删除、.reasonix/、tmp/ 未跟踪）先 stash 再合并（push 只推提交，最后 pop 恢复）
- 合并后必查：CI 冲突、`material_ui` import 一致性、`flutter/material` 残留、上游删除/改名文件导致的悬空 import
- 合并后**要复查本 fork 的定制改动是否被上游覆盖**（上游常把 `all` tab 之类的行为加回来）

## CI 与发布（本地自定义规则，与上游不同）

- push 到 main 触发 Build workflow（Android arm64-v8a-only + Win-x64），成功即用 `softprops/action-gh-release` 自动发布 `v{version}` release
- 上游新 CI 已改为 workflow_dispatch 手动 + 多平台
- **合并上游时 `.github/workflows/build.yml` / `win_x64.yml` 冲突一律保留本地版本**
- `win_x64.yml` 关键步骤：Setup flutter → Apply Patch（patch.ps1 windows，打 Flutter 内部补丁；**缺失会导致 Windows 编译约 85 个 error**，合并冲突时极易丢失，务必核对）→ build.ps1 版本号 → `flutter build windows --pub` → fastforge 打包 → Release

## 版本号规则（`lib/scripts/build.ps1`）

- baseVersion 读 pubspec.yaml 的 version（如 2.1.3），读已有 tag `v{base}.{seq}` 取 max+1 递增（v2.1.3.01 / .02 …）
- CI 需 `fetch-depth: 0` 才能看到 tag
- 失败构建残留的残缺 release 会占号：删除 release 后要**同时删 git refs/tags** 才能恢复序列（2026-08 用户选择删除残缺 release + tag）
- 只改文档/CI 的提交不想触发发布时，可在 commit message 里加 `[skip ci]`

## 已知坑

**Android 依赖 media-kit**：`My-Responsitories/media-kit@version_1.2.5` 的 `media_kit_libs_android_video/build.gradle` 写死 `bggRGjQaUbCoE/libmpv-android-video-build` 的 vnext 资产 MD5（vnext 滚动更新，2026-08-13 更新后 MD5 漂移 → Gradle MD5 verification failed）。重跑构建前可用 curl 下载 jar 算 MD5，与 build.gradle 的 `fileInfo.md5` 对比验证。**ref 的来回变动史（跟随上游即可，但别用错分支）**：2.1.1–2.1.4 用 `bggRGjQaUbCoE/media-kit`（resolved-ref 随上游演进）；2.1.4 tip（`00cb572cc`）升到 `ref: upstream` 的 media_kit_video **2.0.1**；2.1.5 的 `ee148aa64` 部分回退该升级，改回 `My-Responsitories/media-kit@native`（media_kit_video 1.2.5，`media_kit_video` 的 resolved-ref `73771ec3`）——原因是 2.0.1 重写的 `android_video_controller/real.dart` 导致 #2994（暂停→切后台→回前台黑屏）。当前应与上游一致为 `ref: native`。

**material_ui 迁移**：上游 Flutter 3.47 起全库改用 `package:material_ui`（约 487 文件、0 个 flutter/material）。material_ui export flutter/widgets，但其 material 组件类（ThemeData/Scaffold/TabBar 等）与 flutter/material 是**不同声明**——同一文件同时 import 两者会 ambiguous，且两库 Theme 树不互通（跨库 `Theme.of` 运行时报错）。合并上游后：
- 用户改动文件若残留 flutter/material import，要统一改成 material_ui
- 上游新增内部文件（如 sliver_constrained_cross_axis）也要核对用户文件的 import 目标是否仍存在
- 上游 API 改名要跟着改：如 `ReplySortType` 迁移到 `EnumWithLabel`（title→desc、label→descShort、text→label）

**历史上的「假合并」提交把文件整体换成了上游旧版**：`e1f53db0a` 等提交 message 写着「merge: 合并上游 …」但**只有一个父提交**，实际是手动改文件而非真合并，结果把某些文件整体替换成了落后的上游版本，且此后每次合并都被当成「本 fork 定制」保留下来。识别方法：某文件用着上游早已删除的 API（如 `isLocating.value` 这种已改成 bool 的 Rx 写法）、或 `git log -S"<某符号>"` 显示差异全部来自某个单父的「merge」提交——**那是遗留失误，不是定制，直接取上游版本**。2026-09 合并 2.1.4 时 `lib/pages/member_video/view.dart` 就是这种（缺悬浮头与「定位至上次观看」FAB），已取上游版本恢复。

## 本 fork 的定制改动（合并上游后需复查）

- **动态页只看视频**：`DynamicsTabType` 已移除 `all`（tab = 视频/番剧/UP，默认「视频」）；`DynamicsHttp.followDynamic` 的 UP 标签附加 `type: 'video'`；`up_panel.dart` 首项为「全部视频」，点击切到「视频」标签并刷新其内容
- **UP 面板自动加载**：`up_panel.dart` 的 `SliverList` 末项触发 `controller.onLoadMore()`（与 `waterfall.dart` 同一模式），否则第一页约 9 个 UP 主会卡住不续载
- **UP 面板分割线**：`dynamics/view.dart` 在 top/leftFixed/rightFixed 三种停靠模式自绘 Divider（色 `colorScheme.outlineVariant` α0.1）
- **动态页布局模式**：`lib/utils/waterfall.dart` 支持 0 瀑布流 / 1 网格对齐 / 2 单列居中（`GlobalData.dynamicLayoutMode`）
- **推荐页发布时间**：`RcmdVideoItemAppModel` 解析 `pubdate`，卡片右下角显示（`video_card_v.dart` 用 `DateFormat('M-d')`）
- **卡片间距 / 边缘距离**设置项：`SettingBoxKey.cardSpacing` / `edgePadding`（`Pref.cardSpacing`、`Pref.edgePadding`）
- **更新检查**：`lib/utils/update.dart` 指向本仓库 `/releases/latest`
- **默认展示 TAB 存储**：`Pref.defaultDynamicTypeIndex` 按 enum `name` 存储，读取时兼容旧 int 索引（非零左移一位），避免上游增删 tab 后错位
- **竖屏视频 `vertical_av`（2.1.5 起上游已从字段层面修掉，本 fork 只留兜底）**：app 端推荐接口对竖屏视频返回 `goto: 'vertical_av'`（不是 `'av'`），`uri` 为 `bilibili://story/{aid}?cid=…&player_width=…&player_height=…`，其余字段与 `av` 一致。上游 2.1.5 的 `08a9f5509` 改为读 **`card_goto`**（竖屏视频的 card_goto 是 `av`），关掉了 #2996。本 fork 另留两处兜底 + 一处上游没有的能力：`rcmd/result.dart` 的 `RcmdOwner` 除上游的 `card_goto` 外仍接受 `vertical_av`（防 card_goto 也返回 vertical_av 时作者名退化成 `desc_button.text`——那是「竖屏」角标文案）；`video_card_v.dart` 与 `member_home/widgets/video_card_v_member_home.dart` 用 `case 'av' || 'vertical_av'`；`app_scheme.dart` 的 `case 'video' || 'story'` 让 story 深链本身可用（**上游不处理，是本 fork 独有**，合并时别丢）。故意不把 `goto` 改写成 `av`——不感兴趣接口（`feedDislike`）要把 goto 原样回传
- **成员页 TabBar 固定高度不滚动**：`member/view.dart` 把 TabBar 固定 45 高、不随内容滚动（上游是 `DynamicSliverAppBar` + body 内 TabBar 且 `labelPadding: .zero`），`member/controller.dart` 额外「自己的主页默认选中观看记录」。**注意**：该文件也源自 `e1f53db0a` 的手工合并，但这是**刻意的定制**（「固定高度，不滚动」这条注释在上游全库都没出现过），别按「遗留失误」处理成上游版本；上游的 `labelPadding: .zero` 已一并采用

## 验证

本地无 Flutter SDK，验证靠 GitHub Actions（push main 触发）；发布后核对 release assets 齐全（Android APK + Windows ZIP + EXE）。运行时行为（如接口参数是否生效）需用户实机确认。

## 项目记忆（DSH 记忆空间「PiliPlus」）

漂移型状态（已发布版本、上游版本、上游 Flutter 版本、CI 状态、本机有无 Flutter SDK）存在 **DSH 记忆空间「PiliPlus」**，用 `mnemon_recall` 按需召回；每次合并上游或发布后回来更新它。

分工：**每次都要遵守的规则**（合并流程、CI、版本号规则、已知坑、定制改动）写在本文件；**会过时的事实/快照**写进记忆空间。别把规则塞进记忆——两处重复必然一处先过时。
