# VERIFY · mdmeta

**Updated:** 2026-10-26 20:25 Asia/Shanghai  
**Module:** `ShunjunGu/mdmeta` @ 0.1.0 · Apache-2.0  
**Public:** https://github.com/ShunjunGu/mdmeta

## Done

- [x] Parse `---` YAML frontmatter (scalars + simple lists)
- [x] Schema validate (required keys + types)
- [x] Library get / with_field / list / render
- [x] CLI: `get` `set` `list` `validate` `batch`
- [x] `moon test` — 8 passed (box 2026-10-26)
- [x] README + `DEMO.md` + `scripts/demo.sh` + examples
- [x] Public GitHub repo
- [x] Issues #1 #2 for acceptance tracking
- [x] Local CI workflow file `.github/workflows/ci.yml` (push pending if not on remote yet)

## User / process

- [x] 飞书报名（mdmeta）
- [x] 赛事群昵称 = `ShunjunGu`
- [ ] Continuous commits on GitHub through **2026-10-31** (DEMO/CI polish push)
- [ ] 本期审核通过后领完成支持 ¥350

## Quick re-verify

```bash
export PATH="$HOME/.moon/bin:$PATH"
cd /workspace/paid-ops/moonbit-hackathon-2026-10/mdmeta
moon test
bash scripts/demo.sh
```
