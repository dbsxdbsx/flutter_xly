# .issue/

暂缓但未丢失的问题现场。AGENTS.md **Active Context** 只链接 `items/` 下 `suspended` / `blocked` 条目。

## 目录约定

```text
.issue/
├── README.md
├── items/
├── assets/
└── _archive/
    ├── items/
    └── assets/
```

## Status 枚举（强制）

`status` **只认**：`suspended`｜`blocked`｜`resolved`｜`superseded`。

- **禁止** `closed`（以及 `open` / `active` 等别名）。
- `resolved` / `superseded` **必须**归档到 `.issue/_archive/items/`（附件同步 `_archive/assets/`）；留在 `items/` 不算收完。
- 旧说明里的 `items/_archive/` 路径作废，一律用 `_archive/items/`。

## 操作

- 新建：在 `items/` 下用 `YYYY-MM-DD_<topic>.md` + frontmatter（`status`、`created`、`updated`）。
- 已闭环：改 status → 补结论 → 移至 `_archive/items/`，并更新 AGENTS.md。

当前无开放条目。
