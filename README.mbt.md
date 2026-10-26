# mdmeta

Markdown **YAML frontmatter** parse / validate / get-set-list toolkit in MoonBit.

MVP scope: `---` fences, scalar + simple list YAML, schema checks, CLI, directory
batch JSON report. Not a full YAML 1.2 or CommonMark renderer.

License: **Apache-2.0**

## Build / test

```bash
export PATH="$HOME/.moon/bin:$PATH"
cd mdmeta
moon test          # library parse/validate tests
moon run cmd/main -- --help
```

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
