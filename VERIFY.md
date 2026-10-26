# VERIFY · mdmeta local MVP

**Updated:** 2026-10-26 ~12:35 Asia/Shanghai  
**Local path:** `/workspace/paid-ops/moonbit-hackathon-2026-10/mdmeta/`  
**Module:** `ShunjunGu/mdmeta` @ 0.1.0 · Apache-2.0

## Done on this box

- [x] `moon new` project (not hello-demo)
- [x] Parse `---` YAML frontmatter (scalars + simple lists)
- [x] Schema validate (required keys + types)
- [x] Library get / with_field / list / render
- [x] CLI: `get` `set` `list` `validate` `batch` (JSON report)
- [x] `moon test` — 8 passed
- [x] README examples + `examples/*.md`
- [x] No git push / no Feishu / no WeChat join

## Still needs the user

1. **Public GitHub repo URL** for `mdmeta` (GitHub restore + create public repo; this package does **not** push).
2. Join **赛事交流群**, set nick = **`ShunjunGu`** (GitHub ID).
3. Fill **飞书报名表** (≤3 times in October) with one-pager + public repo URL.
4. Keep public commits through 2026-10-31; optional mooncakes.io publish / GitHub Action later.

## Quick re-verify

```bash
export PATH="$HOME/.moon/bin:$PATH"
cd /workspace/paid-ops/moonbit-hackathon-2026-10/mdmeta
moon test
moon run cmd/main -- batch examples --require title --require date
```
