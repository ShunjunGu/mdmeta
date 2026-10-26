# mdmeta · 可复现演示（MoonBit 黑客松十月赛）

**仓库：** https://github.com/ShunjunGu/mdmeta  
**截止：** 2026-10-31（Asia/Shanghai）  
**本页用途：** 验收时按步骤复现 README / 测试 / CLI。

## 环境

```bash
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
export PATH="$HOME/.moon/bin:$PATH"
moon version
git clone https://github.com/ShunjunGu/mdmeta.git
cd mdmeta
```

## 一键演示

```bash
bash scripts/demo.sh
```

预期：`moon test` 全绿；CLI `list` / `get` / `validate` / `batch` 有输出；`incomplete.md` 报缺 `date`。

## 逐步命令

```bash
moon test
moon run cmd/main -- --help
moon run cmd/main -- list examples/post.md
moon run cmd/main -- get examples/post.md title
moon run cmd/main -- validate examples/post.md --require title --require date --type title=string
moon run cmd/main -- validate examples/incomplete.md --require title --require date   # 期望非 0
moon run cmd/main -- batch examples --require title --require date
moon run cmd/main -- set examples/post.md slug hello-moonbit   # 打印改写后全文，不写盘
```

## 验收六条自检

| # | 要求 | 本项目 |
|---|---|---|
| 1 | MoonBit 为主 | `*.mbt` 库 + CLI |
| 2 | 公开仓可追踪 | 本 GitHub 仓 + Issues |
| 3 | README / 示例 / 测试 | 本页 + `examples/` + `moon test` |
| 4 | 实质工作 | 新项目 MVP（解析/校验/CLI/batch） |
| 5 | 开源许可 | Apache-2.0 |
| 6 | AI 可解释 | 边界见 README「YAML subset」 |

## 非目标（刻意不做）

完整 YAML 1.2、CommonMark 渲染、GUI、云服务。
