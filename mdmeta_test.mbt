///|
test "parse simple frontmatter" {
  let src =
    #|---
    #|title: Hello
    #|draft: false
    #|---
    #|Body text
  let doc = @mdmeta.parse_document(src)
  assert_eq(doc.has_frontmatter, true)
  assert_eq(doc.body, "Body text")
  assert_eq(
    @mdmeta.get_field(doc, "title"),
    Some(@mdmeta.YamlValue::String("Hello")),
  )
  assert_eq(
    @mdmeta.get_field(doc, "draft"),
    Some(@mdmeta.YamlValue::Bool(false)),
  )
}

///|
test "parse flow and block lists" {
  let src =
    #|---
    #|tags: [rust, moonbit]
    #|authors:
    #|- alice
    #|- bob
    #|count: 3
    #|pi: 3.14
    #|---
    #|
  let doc = @mdmeta.parse_document(src)
  assert_eq(
    @mdmeta.get_field(doc, "tags"),
    Some(
      @mdmeta.YamlValue::List([
        @mdmeta.YamlValue::String("rust"),
        @mdmeta.YamlValue::String("moonbit"),
      ]),
    ),
  )
  assert_eq(
    @mdmeta.get_field(doc, "authors"),
    Some(
      @mdmeta.YamlValue::List([
        @mdmeta.YamlValue::String("alice"),
        @mdmeta.YamlValue::String("bob"),
      ]),
    ),
  )
  assert_eq(@mdmeta.get_field(doc, "count"), Some(@mdmeta.YamlValue::Int(3)))
  assert_eq(@mdmeta.get_field(doc, "pi"), Some(@mdmeta.YamlValue::Float(3.14)))
}

///|
test "no frontmatter returns full body" {
  let doc = @mdmeta.parse_document("# Just markdown\n")
  assert_eq(doc.has_frontmatter, false)
  assert_eq(doc.body, "# Just markdown\n")
  assert_eq(@mdmeta.list_fields(doc).length(), 0)
}

///|
test "missing closing fence errors" {
  let src =
    #|---
    #|title: oops
  let result = Ok(@mdmeta.parse_document(src)) catch { e => Err(e) }
  match result {
    Err(err) =>
      inspect(
        err.to_string(),
        content="missing closing frontmatter fence (---)",
      )
    Ok(_) => fail("expected parse error")
  }
}

///|
test "validate required keys and types" {
  let src =
    #|---
    #|title: Demo
    #|draft: true
    #|---
    #|hi
  let doc = @mdmeta.parse_document(src)
  let schema = @mdmeta.Schema::{
    fields: [
      @mdmeta.FieldSpec::{
        name: "title",
        required: true,
        ty: @mdmeta.FieldType::TyString,
      },
      @mdmeta.FieldSpec::{
        name: "date",
        required: true,
        ty: @mdmeta.FieldType::TyString,
      },
      @mdmeta.FieldSpec::{
        name: "draft",
        required: false,
        ty: @mdmeta.FieldType::TyBool,
      },
    ],
  }
  let issues = @mdmeta.validate(doc, schema)
  assert_eq(issues.length(), 1)
  assert_eq(issues[0].key, "date")
}

///|
test "with_field set and render roundtrip" {
  let src =
    #|---
    #|title: Old
    #|---
    #|Body
  let doc0 = @mdmeta.parse_document(src)
  let doc1 = @mdmeta.with_field(doc0, "title", @mdmeta.YamlValue::String("New"))
  let doc2 = @mdmeta.with_field(
    doc1,
    "tags",
    @mdmeta.YamlValue::List([
      @mdmeta.YamlValue::String("a"),
      @mdmeta.YamlValue::String("b"),
    ]),
  )
  let rendered = @mdmeta.render_document(doc2)
  let again = @mdmeta.parse_document(rendered)
  assert_eq(
    @mdmeta.get_field(again, "title"),
    Some(@mdmeta.YamlValue::String("New")),
  )
  assert_eq(
    @mdmeta.get_field(again, "tags"),
    Some(
      @mdmeta.YamlValue::List([
        @mdmeta.YamlValue::String("a"),
        @mdmeta.YamlValue::String("b"),
      ]),
    ),
  )
  assert_eq(again.body, "Body")
}

///|
test "list_fields and schema_of_requires" {
  let src =
    #|---
    #|title: T
    #|slug: s
    #|---
    #|
  let doc = @mdmeta.parse_document(src)
  let keys = @mdmeta.list_fields(doc)
  assert_eq(keys.length(), 2)
  let typed : Map[String, @mdmeta.FieldType] = Map([
    ("title", @mdmeta.FieldType::TyString),
  ])
  let schema = @mdmeta.schema_of_requires(["title", "date"], typed)
  let issues = @mdmeta.validate(doc, schema)
  assert_eq(issues.length(), 1)
  assert_eq(issues[0].key, "date")
}

///|
test "frontmatter_to_json" {
  let src =
    #|---
    #|title: Hello
    #|n: 1
    #|---
    #|
  let doc = @mdmeta.parse_document(src)
  let js = @mdmeta.frontmatter_to_json(doc.frontmatter)
  let s = js.stringify()
  assert_true(s.contains("\"title\""))
  assert_true(s.contains("Hello"))
}
