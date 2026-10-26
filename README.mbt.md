# mdmeta

Markdown **YAML frontmatter** parse / validate / get-set-list toolkit in **MoonBit**.

> MoonBit 黑客松十月赛参赛项目（顾舜竣 / [ShunjunGu](https://github.com/ShunjunGu)）  
> 公开仓：https://github.com/ShunjunGu/mdmeta · License **Apache-2.0**

MVP scope: `---` fences, scalar + simple list YAML, schema checks, CLI, directory
batch JSON report. Not a full YAML 1.2 or CommonMark renderer.

## 一句话（中文）

用 MoonBit 实现 Markdown frontmatter 的解析 / 校验 / 批量查询改写 CLI，并提供可发布库——服务博客与 docs 站 CI 检查。

## Build / test

```bash
export PATH="$HOME/.moon/bin:$PATH"
cd mdmeta
moon test          # library parse/validate tests
moon run cmd/main -- --help
bash scripts/demo.sh   # full reproducible demo
```

详见 [`DEMO.md`](./DEMO.md)。

## Library

```mbt nocheck
let doc = @mdmeta.parse_document(src)
let title = @mdmeta.get_field(doc, "title")
let issues = @mdmeta.validate(doc, schema)
let out = @mdmeta.render_document(@mdmeta.with_field(doc, "slug", String("x")))
```

## CLI

```bash
moon run cmd/main -- list examples/post.md
moon run cmd/main -- get examples/post.md title
moon run cmd/main -- set examples/post.md slug hello-moonbit          # prints
moon run cmd/main -- set examples/post.md slug hello-moonbit --in-place
moon run cmd/main -- validate examples/post.md --require title --require date --type title=string
moon run cmd/main -- batch examples --require title --require date
```

`batch` prints a JSON report (`ok` / `errors` / per-file `frontmatter` + `issues`).

## YAML subset

Supported values: `null`, bool, int, float, string, flow lists `[a, b]`, block
lists `- item`. Nested maps / anchors / multi-doc YAML are **out of scope**.

## Examples

See `examples/post.md` and `examples/incomplete.md`.

## Hackathon acceptance map

| Criterion | Evidence |
| --- | --- |
| MoonBit primary | `mdmeta.mbt`, `cmd/main/main.mbt` |
| Public continuous history | this repo + [issues](https://github.com/ShunjunGu/mdmeta/issues) |
| Runnable + tests | `moon test`, `scripts/demo.sh`, `DEMO.md` |
| License | Apache-2.0 (`LICENSE`) |
| Clear boundary | YAML subset section above |

## Tracking

- [#1 acceptance checklist](https://github.com/ShunjunGu/mdmeta/issues/1)
- [#2 CI / DEMO roadmap](https://github.com/ShunjunGu/mdmeta/issues/2)
