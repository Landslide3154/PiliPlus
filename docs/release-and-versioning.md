# PiliPlus 版本号取号、发布流程与 Win 打包链路

> 自仓库根 `AGENTS.md` §5「版本与发布」外移（2026-10-24），搬移的正文逐字保留；七节骨架与硬约束仍在 `../AGENTS.md`。
>
> 本文件不注入每轮上下文——发布前、或要改版本号取号逻辑时来这里。

## 1. 版本号怎么算

- 版本号 = 上游同主版本最新 tag + 构建序号（上游 `2.1.6.2` → 本 fork `2.1.6.2.1`）：`build.ps1` 从 `pubspec.yaml` 读三段基础版本，用 `git ls-remote` 取上游同主版本最大 tag，扫本仓库 `v{base}.*` 取下一个序号，回写 `version: {三段}+{commitCount}`（pubspec 必须保持三段）；取不到上游 tag 会直接失败，可用 `-UpstreamBase` 覆盖。只落 tag 不够，残留 release 会占号 → CI 必须 `fetch-depth: 0`，删 release 要同时删 tag。

## 2. 发布流程（push main 即发版）

- 发布：push main 触发 Build workflow（Android arm64-v8a + Win-x64；`build.yml` 调 `win_x64.yml`），成功即由 `softprops/action-gh-release` 按 `v{version}` 发 Release；产物 = APK、Windows portable ZIP、EXE 安装包（本 fork 保持 push 自动发，上游已改手动多平台）。

## 3. Windows 打包链路

- Win 流程：`build.ps1` → `patch.ps1 windows` → `flutter build windows --release --pub --dart-define-from-file=pili_release.json` → fastforge 打包 exe → Release。
