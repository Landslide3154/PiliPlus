# PiliPlus — 开发约定

> 通用规则（git 推送、shell 编码、MCP、归位判据）见全局 `~/.dsh/AGENTS.md`，**本文件不重复**；本机专属见 `AGENTS.local.md`（不提交）。

## 1. 这个项目是什么

B 站第三方客户端 PiliPlus 的个人 fork（Flutter + GetX，多平台）。origin `Landslide3154/PiliPlus`，upstream `bggRGjQaUbCoE/PiliPlus`。fork 版本号口径见 §5。

## 2. 常用命令（在仓库根执行）

| 目的 | 命令 |
| --- | --- |
| 取/查上游 | `git fetch upstream && git log --oneline -5 upstream/main` |
| 算版本号（**会改写 `pubspec.yaml` 并生成 `pili_release.json`**） | `lib/scripts/build.ps1`（需先设 `$env:GITHUB_ENV`，见 §6） |
| 打 Flutter 补丁 | `lib/scripts/patch.ps1 windows`（或 `android`） |
| 构建 / 打包 / 发布 | 不在本地做：push main 触发 GitHub Actions（见 §5） |

## 3. 硬约束

- **必须**：合并前先 `git fetch upstream`，确认 `upstream/main` 是否又前进（曾 fetch 后上游已发新 release），合到最新 head。
- **必须**：冲突时 `.github/workflows/build.yml`、`win_x64.yml` **一律保留本地版本**；`win_x64.yml` 里 `patch.ps1 windows` 那步不能丢（丢了 Windows 编译报大量 error）。
- **必须**：合并后逐条复查 fork 定制清单——下列三条最易被上游覆盖，**全量 8 条及原因见 `docs/fork-customizations.md`**：
  - 竖屏视频仍认 `vertical_av`：`rcmd/result.dart`、`video_card_v*.dart`、`app_scheme.dart`（**本 fork 独有，别丢**）。
  - 成员页 TabBar 固定 45 高、默认选中观看记录：属**刻意定制**，别当遗留失误回退。
  - 动态页只看视频：`DynamicsTabType` 无 `all`；`up_panel.dart` 首项「全部视频」点击即切视频标签、末项触发 `onLoadMore()`。
- **push main = 发版**：只有用户明确要求才 push。
- **禁止**改回上游 `.gitignore` 的 `test*`：fork 用显式 `.reasonix/`、`.codegraph/`、`/tmp/` 替代；恢复 `test*` 会连真测试 `test/utils/accounts/deleted_account_test.dart` 一起忽略（取证见 `docs/`）。
- 只想改文档/CI 不发版：commit message 加 `[skip ci]`。

## 4. 架构边界与因果

- **Android 锁 media-kit**：`My-Responsitories/media-kit` 的 `media_kit_libs_android_video` 把 `libmpv-android-video-build` vnext 资产的 MD5 写死在 `build.gradle`；vnext 更新致 MD5 漂移 → `Gradle MD5 verification failed`（比对 `fileInfo.md5` 可验证）。ref 跟随上游，**别自己升**（曾自升级 media-kit 相关依赖 →「暂停→切后台→回前台黑屏」而回退）。
- **material_ui 迁移**：上游 Flutter 3.47 起全库改用 `package:material_ui`（`lib/common/widgets/flutter/**` 下 vendored 文件例外）。material 组件类与 `flutter/material` 是**不同声明**：同文件同时 import 会 ambiguous，两库 Theme 树不互通（跨库 `Theme.of` 报错）→ 合并后把残留 `flutter/material` 改成 `material_ui`；上游 API 改名要跟着走。
- **「假合并」遗留**：message 写「merge: 合并上游…」却只有一个父提交的手工提交，会把文件整体换成落后上游的版本，此后每次合并都被当「定制」保留。识别：文件用着上游早删的 API，或 `git log -S"<符号>"` 显示差异全来自某个单父「merge」提交 → 那是失误，直接取上游版本。

## 5. 版本与发布

- 版本号：`build.ps1` 从 `pubspec.yaml` 读三段 baseVersion，扫 tag 算下一个两位序号，回写 `version: {base}+{commitCount}`；只落 tag 不够，残留 release 会占号 → CI 必须 `fetch-depth: 0`，删 release 要同时删 tag。
- 发布：push main 触发 Build workflow（Android arm64-v8a + Win-x64；`build.yml` 调 `win_x64.yml`），成功即由 `softprops/action-gh-release` 按 `v{version}` 发 Release；产物 = APK、Windows portable ZIP、EXE 安装包（本 fork 保持 push 自动发，上游已改手动多平台）。
- Win 流程：`build.ps1` → `patch.ps1 windows` → `flutter build windows --release --pub --dart-define-from-file=pili_release.json` → fastforge 打包 exe → Release。
- 发布后核对 release assets 齐全；运行时行为需实机确认。

## 6. 已知坑

- **在真仓库根跑 `build.ps1` 会改写工作区**（先回写 `pubspec.yaml`、再落 `pili_release.json`，最后才碰 `$env:GITHUB_ENV`；失败也不回滚）→ 只检验命令时先备份 `pubspec.yaml`，跑完还原；跑法与报错原文见 `AGENTS.local.md` §2 / §6。
- 合并前工作区有未提交改动（本机文档、未跟踪草稿）属正常：先 stash 再合并，push 只推提交，最后 pop 恢复。
- 上游删/改名文件后易留悬空 import；`flutter/material` 残留常只在编译期暴露。

## 7. 指针

- 全局通用规则与归位判据：`~/.dsh/AGENTS.md`。
- 取证文档（不注入）：`docs/fork-customizations.md`（**fork 定制改动全量 8 条**，合并后逐条复查）、`docs/gitignore-fork-differences.md`（`.gitignore` 差异与事故）。
