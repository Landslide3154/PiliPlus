# PiliPlus `.gitignore` 与上游的差异：来源、事故与清理手法

> 迁移自 dsh-mnemon 记忆空间 PiliPlus 条目 `d81b0474`（insight，2026-09-29 更新），原文内容完整保留。
> 跨机规则的精简版在 `AGENTS.md` §3；本文件只作取证留档，不参与每轮注入。

## 差异本身

上游 `.gitignore` 末尾那行是 `test*`，本 fork 换成显式三行：

```
.reasonix/
.codegraph/
/tmp/
```

前两者不限目录层级，`/tmp/` 限定仓库根。

更早时曾误写成 `test*.reasonix/`——那要求文件名恰好是 `test*.reasonix`，匹配不到任何东西，等于没忽略。

## 为什么这三个目录必须被忽略

- `.reasonix/` 与 `.codegraph/` 是已弃用的 Reasonix agent 残留数据。
- `/tmp/` 是本地草稿目录，例如 `my_changes.patch`、接口响应样本。

## 为什么不能恢复上游的 `test*`

`test*` 会连整个 `test/` 目录一起忽略，而 `test/utils/accounts/deleted_account_test.dart` 是真实存在的测试文件。

## 事故记录

这三个目录一度没被忽略，导致一次误点「提交全部」把 **21 个草稿文件（4610 行）**推进公开仓库，并触发了一次多余的 CI 发布。

## 常规做法

- 提交前 `git status` 确认没扫进草稿。
- 合并上游后复查 `.gitignore` 仍是 fork 这版。
- 把误提交的文件移出跟踪用 `git rm -r --cached <dir>`（保留磁盘文件），别用 `git revert`。
- 非代码提交带 `[skip ci]`，避免白占版本号。

（2026-10-16 迁移整理）
