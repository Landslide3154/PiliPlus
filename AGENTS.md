# PiliPlus — 开发约定

> 通用规则见全局 `C:\Users\godis\.dsh\AGENTS.md`，本文件只写本 fork 独有的东西。

## 1. 这个项目是什么

B 站第三方客户端 PiliPlus 的个人 fork（Flutter + GetX，多平台）；origin `Landslide3154/PiliPlus`，upstream `bggRGjQaUbCoE/PiliPlus`，fork 版本号 = 上游 baseVersion + 序号。

关键位置：`lib/scripts/{build,patch}.ps1`（版本号 / Flutter 补丁）、`.github/workflows/{build,win_x64}.yml`（CI 与发布）、`lib/`（定制改动集中处）。

## 2. 常用命令（可直接复制执行）

| 目的 | 命令 |
| --- | --- |
| 取/查上游 | `git -C D:\code\PiliPlus fetch upstream; git -C D:\code\PiliPlus log --oneline -5 upstream/main` |
| 本地算版本号（会改写 `pubspec.yaml`） | 在 `D:\code\PiliPlus` 下跑 `pwsh -File lib\scripts\build.ps1`，需已设 `$env:GITHUB_ENV` |
| 打 Flutter 补丁 | `pwsh -File D:\code\PiliPlus\lib\scripts\patch.ps1 windows`（或 `android`） |
| 构建 / 打包 / 发布 | 不在本地做，push main 触发 GitHub Actions（见 §5） |

## 3. 硬约束（必须 / 禁止）

- **必须**：合并上游前先 `git fetch upstream` 并确认 `upstream/main` 是否又前进（曾出现 fetch 后上游已发新 release），直接合到最新 head。
- **必须**：合并冲突时 `.github/workflows/build.yml`、`win_x64.yml` **一律保留本地版本**。
- **必须**：`win_x64.yml` 里 `patch.ps1 windows` 步骤不能丢（缺失会导致 Windows 编译报大量 error）。
- **必须**：合并后逐条复查「本 fork 定制改动」是否被上游覆盖，并检查 CI 冲突、`material_ui` import 一致性、`flutter/material` 残留。
- **禁止**：未复查完就 push main（push 会自动触发发布）。
- 只想改文档/CI 而不发版：commit message 加 `[skip ci]`。

**本 fork 定制改动（合并上游后逐条复查，别被上游改回去）**

- 动态页只看视频：`DynamicsTabType` 无 `all`（视频/番剧/UP，默认视频）；`followDynamic` 的 UP 标签附 `type:'video'`；`up_panel.dart` 首项「全部视频」点击即切到视频标签。
- `up_panel.dart` 末项触发 `controller.onLoadMore()`，否则第一页 UP 主不续载。
- `dynamics/view.dart` 三种停靠模式自绘 Divider（`outlineVariant` α0.1）；布局模式 0/1/2 = 瀑布流 / 网格对齐 / 单列居中（`GlobalData.dynamicLayoutMode`，`lib/utils/waterfall.dart`）。
- 推荐页卡片显示发布时间（`RcmdVideoItemAppModel.pubdate`）。
- 设置项 `cardSpacing` / `edgePadding`（`SettingBoxKey`）。
- `lib/utils/update.dart` 指向本仓库 `/releases/latest`。
- `Pref.defaultDynamicTypeIndex` 按 enum `name` 存储、兼容旧 int 索引，防上游增删 tab 后错位。
- 竖屏视频：上游改读 `card_goto` 后本 fork 仍接受 `vertical_av`——`RcmdOwner`（`rcmd/result.dart`，否则作者名退化成「竖屏」角标文案）、`video_card_v.dart` 与 `video_card_v_member_home.dart` 认 `'av'||'vertical_av'`、`app_scheme.dart` 认 `'video'||'story'` 使 story 深链可用（**本 fork 独有，别丢**）；不把 `goto` 改成 `av`，`feedDislike` 要原样回传。
- 成员页 `member/view.dart` TabBar 固定 45 高不滚动、`member/controller.dart` 默认选中观看记录；属**刻意定制**，别当遗留失误回退。

## 4. 架构边界与因果

- **Android 锁 media-kit**：`My-Responsitories/media-kit` 的 `media_kit_libs_android_video/build.gradle` 写死 `bggRGjQaUbCoE/libmpv-android-video-build` vnext 资产的 MD5；vnext 滚动更新致 MD5 漂移 → `Gradle MD5 verification failed`（可下载 jar 对比 `fileInfo.md5` 验证）。ref 跟随上游别自己挑（曾升 media_kit_video 2.0.1 →「暂停→切后台→回前台黑屏」而回退）。
- **material_ui 迁移**：上游 Flutter 3.47 起全库改用 `package:material_ui`（`lib/common/widgets/flutter/**` 下 vendored 文件例外）。它 export flutter/widgets，但 material 组件类与 flutter/material 是**不同声明**：同文件同时 import 会 ambiguous，两库 Theme 树不互通（跨库 `Theme.of` 报错）。合并后把残留 flutter/material 改为 material_ui；API 改名要跟（`ReplySortType`→`EnumWithLabel`）。
- **「假合并」遗留**：曾有 message 写「merge: 合并上游…」但只有一个父提交的手工提交，把文件整体换成落后上游版本，此后每次合并都被当「定制」保留。识别：文件用着上游早删的 API，或 `git log -S"<符号>"` 显示差异全来自某个单父「merge」提交 → 那是失误不是定制，直接取上游版本。

## 5. 版本与发布

- 版本号唯一来源：`pubspec.yaml` 的 `version` + `lib/scripts/build.ps1` 按 tag 递增出 `{base}.{seq}`；CI 必须 `fetch-depth: 0`，残留 release 会占号，删 release 要同时删 tag。
- 发布：push main 触发 Build workflow（Android arm64-v8a + Win-x64），成功即由 `softprops/action-gh-release` 发 `v{version}`；产物 = APK、Windows portable ZIP、EXE 安装包（上游已改为手动多平台，本 fork 保持 push 自动发）。
- Win 流程：`build.ps1` → `patch.ps1 windows` → `flutter build windows --release --pub` → fastforge 打包 → Release。
- 发布后核对 release assets 齐全；运行时行为需实机确认。

## 6. 已知坑

- 合并前工作区若有未提交改动（`.vscode/` 等未跟踪内容）属正常：先 stash 再合并，push 只推提交，最后 pop 恢复。
- `patch.ps1` 会 `git config --global` 覆写提交身份为 `ci`/`example@example.com`，本机跑完必须改回。
- 上游删/改名文件后易留悬空 import；`flutter/material` 残留常只在编译期暴露。

## 7. 指针

- 全局规则：`C:\Users\godis\.dsh\AGENTS.md`
- 记忆空间：PiliPlus（当前已发布版本、上游版本、上游 Flutter 版本、CI 状态）——合并或发布后回来更新。
- 分工：规则写本文件，会过时的事实/快照写记忆空间，别两处重复。

