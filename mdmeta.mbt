///| Markdown YAML frontmatter toolkit (MVP subset).

///|
/// Supported YAML values: null, bool, int, float, string, and simple
/// string lists (flow `[a, b]` or block `- item`). Nested maps are out of scope.

///|
pub(all) suberror ParseError {
  Message(String)
} derive(Eq, @debug.Debug)

///|
pub extend ParseError with Eq::{equal, not_equal}

///|
pub fn ParseError::to_string(self : ParseError) -> String {
  match self {
    Message(msg) => msg
  }
}

///|
pub(all) enum YamlValue {
  Null
  Bool(Bool)
  Int(Int32)
  Float(Double)
  String(String)
  List(Array[YamlValue])
} derive(Eq, @debug.Debug)

///|
pub extend YamlValue with Eq::{equal, not_equal}

///|
pub fn YamlValue::to_string(self : YamlValue) -> String {
  yaml_value_to_string(self)
}

///|
pub(all) struct Document {
  frontmatter : Map[String, YamlValue]
  body : String
  has_frontmatter : Bool
} derive(Eq, @debug.Debug)

///|
pub extend Document with Eq::{equal, not_equal}

///|
pub(all) enum FieldType {
  TyString
  TyBool
  TyInt
  TyFloat
  TyList
  TyAny
} derive(Eq, @debug.Debug)

///|
pub extend FieldType with Eq::{equal, not_equal}

///|
pub fn FieldType::to_string(self : FieldType) -> String {
  match self {
    TyString => "string"
    TyBool => "bool"
    TyInt => "int"
    TyFloat => "float"
    TyList => "list"
    TyAny => "any"
  }
}

///|
pub(all) struct FieldSpec {
  name : String
  required : Bool
  ty : FieldType
} derive(Eq, @debug.Debug)

///|
pub extend FieldSpec with Eq::{equal, not_equal}

///|
pub(all) struct Schema {
  fields : Array[FieldSpec]
} derive(Eq, @debug.Debug)

///|
pub extend Schema with Eq::{equal, not_equal}

///|
pub(all) struct ValidationIssue {
  key : String
  message : String
} derive(Eq, @debug.Debug)

///|
pub extend ValidationIssue with Eq::{equal, not_equal}

///|
pub fn yaml_value_to_string(v : YamlValue) -> String {
  match v {
    Null => "null"
    Bool(b) => if b { "true" } else { "false" }
    Int(i) => i.to_string()
    Float(f) => f.to_string()
    String(s) => s
    List(items) => {
      let buf = StringBuilder()
      buf.write_char('[')
      let mut first = true
      for item in items {
        if !first {
          buf.write_string(", ")
        }
        first = false
        buf.write_string(yaml_value_to_string(item))
      }
      buf.write_char(']')
      buf.to_string()
    }
  }
}

///|
pub fn yaml_value_to_json(v : YamlValue) -> Json {
  match v {
    Null => Json::null()
    Bool(b) => Json::boolean(b)
    Int(i) => Json::number(i.to_double())
    Float(f) => Json::number(f)
    String(s) => Json::string(s)
    List(items) => {
      let arr : Array[Json] = []
      for item in items {
        arr.push(yaml_value_to_json(item))
      }
      Json::array(arr)
    }
  }
}

///|
pub fn frontmatter_to_json(fm : Map[String, YamlValue]) -> Json {
  let obj : Map[String, Json] = Map([])
  for key, val in fm {
    obj.set(key, yaml_value_to_json(val))
  }
  Json::object(obj)
}

///|
fn is_fence_line(line : StringView) -> Bool {
  let t = line.trim()
  t.equal_to_string("---") || t.equal_to_string("...")
}

///|
fn split_lines(text : String) -> Array[String] {
  let out : Array[String] = []
  for part in text.split("\n") {
    let s = match part.strip_suffix("\r") {
      Some(v) => v.to_owned()
      None => part.to_owned()
    }
    out.push(s)
  }
  out
}

///|
fn join_lines(lines : ArrayView[String], start : Int32, end : Int32) -> String {
  let buf = StringBuilder()
  let mut i = start
  while i < end {
    if i > start {
      buf.write_char('\n')
    }
    buf.write_string(lines[i])
    i = i + 1
  }
  buf.to_string()
}

///|
/// Parse a Markdown document into frontmatter + body.
/// Accepts an optional opening `---` fence at the start of the file.
pub fn parse_document(text : String) -> Document raise ParseError {
  let lines = split_lines(text)
  if lines.length() == 0 {
    return { frontmatter: Map([]), body: "", has_frontmatter: false, }
  }
  let first = lines[0].trim()
  if !first.equal_to_string("---") {
    return { frontmatter: Map([]), body: text, has_frontmatter: false, }
  }
  let mut close = -1
  let mut i = 1
  while i < lines.length() {
    if is_fence_line(lines[i].to_string_view()) {
      close = i
      break
    }
    i = i + 1
  }
  if close < 0 {
    raise ParseError::Message("missing closing frontmatter fence (---)")
  }
  let yaml_text = join_lines(lines[:], 1, close)
  let fm = parse_yaml_map(yaml_text)
  let body = if close + 1 >= lines.length() {
    ""
  } else {
    join_lines(lines[:], close + 1, lines.length())
  }
  { frontmatter: fm, body, has_frontmatter: true, }
}

///|
/// Parse a flat YAML map (MVP subset).
pub fn parse_yaml_map(text : String) -> Map[String, YamlValue] raise ParseError {
  let result : Map[String, YamlValue] = Map([])
  let lines = split_lines(text)
  let mut i = 0
  while i < lines.length() {
    let raw = lines[i]
    let trimmed = raw.trim()
    if trimmed.is_empty() || trimmed.has_prefix("#") {
      i = i + 1
      continue
    }
    if trimmed.has_prefix("- ") {
      raise ParseError::Message(
        "unexpected list item without a key at line \{i + 1}",
      )
    }
    match trimmed.split_once(":") {
      None => raise ParseError::Message("expected key: value at line \{i + 1}")
      Some((key_view, rest_view)) => {
        let key = key_view.trim().to_owned()
        if key.is_empty() {
          raise ParseError::Message("empty key at line \{i + 1}")
        }
        let rest = rest_view.trim()
        if rest.is_empty() {
          let (items, next) = parse_block_list(lines[:], i + 1)
          if items.length() > 0 {
            result.set(key, List(items))
            i = next
            continue
          }
          result.set(key, Null)
          i = i + 1
          continue
        }
        result.set(key, parse_scalar_or_flow_list(rest.to_owned()))
        i = i + 1
      }
    }
  }
  result
}

///|
fn parse_block_list(
  lines : ArrayView[String],
  start : Int32,
) -> (Array[YamlValue], Int32) {
  let items : Array[YamlValue] = []
  let mut i = start
  while i < lines.length() {
    let trimmed = lines[i].trim()
    if trimmed.is_empty() || trimmed.has_prefix("#") {
      i = i + 1
      continue
    }
    if !trimmed.has_prefix("- ") {
      break
    }
    let item_text = match trimmed.strip_prefix("- ") {
      Some(v) => v.trim().to_owned()
      None => trimmed.to_owned()
    }
    items.push(parse_scalar(item_text))
    i = i + 1
  }
  (items, i)
}

///|
fn parse_scalar_or_flow_list(text : String) -> YamlValue {
  let t = text.trim()
  if t.has_prefix("[") && t.has_suffix("]") {
    return parse_flow_list(t.to_owned())
  }
  parse_scalar(t.to_owned())
}

///|
fn parse_flow_list(text : String) -> YamlValue {
  let after_open = match text.to_string_view().strip_prefix("[") {
    Some(v) => v
    None => text.to_string_view()
  }
  let inner = match after_open.strip_suffix("]") {
    Some(v) => v.trim()
    None => after_open.trim()
  }
  let items : Array[YamlValue] = []
  if inner.is_empty() {
    return List(items)
  }
  let parts = split_csv_respecting_quotes(inner.to_owned())
  for part in parts {
    items.push(parse_scalar(part.trim().to_owned()))
  }
  List(items)
}

///|
fn split_csv_respecting_quotes(text : String) -> Array[String] {
  let parts : Array[String] = []
  let buf = StringBuilder()
  let mut in_single = false
  let mut in_double = false
  for ch in text {
    match ch {
      '\'' => {
        if !in_double {
          in_single = !in_single
        }
        buf.write_char(ch)
      }
      '"' => {
        if !in_single {
          in_double = !in_double
        }
        buf.write_char(ch)
      }
      ',' =>
        if in_single || in_double {
          buf.write_char(ch)
        } else {
          parts.push(buf.to_string())
          buf.reset()
        }
      _ => buf.write_char(ch)
    }
  }
  parts.push(buf.to_string())
  parts
}

///|
fn parse_scalar(text : String) -> YamlValue {
  let t = text.trim().to_owned()
  if t.is_empty() || t == "~" || t == "null" || t == "Null" || t == "NULL" {
    return Null
  }
  if t == "true" || t == "True" || t == "TRUE" {
    return Bool(true)
  }
  if t == "false" || t == "False" || t == "FALSE" {
    return Bool(false)
  }
  if (t.has_prefix("\"") && t.has_suffix("\"")) ||
    (t.has_prefix("'") && t.has_suffix("'")) {
    if t.length() >= 2 {
      return String(t[1:t.length() - 1].to_owned())
    }
  }
  try {
    let n = @string.parse_int(t.to_string_view())
    return Int(n)
  } catch {
    _ => ()
  }
  try {
    let f = @string.parse_double(t.to_string_view())
    if t.contains_any(chars="0123456789") {
      return Float(f)
    }
  } catch {
    _ => ()
  }
  String(t)
}

///|
pub fn get_field(doc : Document, key : String) -> YamlValue? {
  doc.frontmatter.get(key)
}

///|
pub fn list_fields(doc : Document) -> Array[String] {
  let keys : Array[String] = []
  for k, _ in doc.frontmatter {
    keys.push(k)
  }
  keys
}

///|
/// Return a new document with `key` set to `value`.
pub fn with_field(doc : Document, key : String, value : YamlValue) -> Document {
  let fm = doc.frontmatter.copy()
  fm.set(key, value)
  { frontmatter: fm, body: doc.body, has_frontmatter: true, }
}

///|
pub fn render_frontmatter(fm : Map[String, YamlValue]) -> String {
  let buf = StringBuilder()
  buf.write_string("---\n")
  for key, val in fm {
    buf.write_string(key)
    buf.write_string(": ")
    buf.write_string(render_yaml_value(val))
    buf.write_char('\n')
  }
  buf.write_string("---")
  buf.to_string()
}

///|
fn render_yaml_value(v : YamlValue) -> String {
  match v {
    Null => "null"
    Bool(b) => if b { "true" } else { "false" }
    Int(i) => i.to_string()
    Float(f) => f.to_string()
    String(s) => if needs_quotes(s) { "\"\{escape_double(s)}\"" } else { s }
    List(items) => {
      let buf = StringBuilder()
      buf.write_char('[')
      let mut first = true
      for item in items {
        if !first {
          buf.write_string(", ")
        }
        first = false
        buf.write_string(render_yaml_value(item))
      }
      buf.write_char(']')
      buf.to_string()
    }
  }
}

///|
fn needs_quotes(s : String) -> Bool {
  s.is_empty() ||
  s.contains_any(chars=":#[]{},&*!|>'\"%@`") ||
  s.has_prefix(" ") ||
  s.has_suffix(" ") ||
  s == "true" ||
  s == "false" ||
  s == "null" ||
  s == "~"
}

///|
fn escape_double(s : String) -> String {
  s.replace_all(old="\\", new="\\\\").replace_all(old="\"", new="\\\"")
}

///|
pub fn render_document(doc : Document) -> String {
  if !doc.has_frontmatter && doc.frontmatter.is_empty() {
    return doc.body
  }
  let fm = render_frontmatter(doc.frontmatter)
  if doc.body.is_empty() {
    fm + "\n"
  } else {
    fm + "\n" + doc.body
  }
}

///|
pub fn field_type_of_value(v : YamlValue) -> FieldType {
  match v {
    Null => TyAny
    Bool(_) => TyBool
    Int(_) => TyInt
    Float(_) => TyFloat
    String(_) => TyString
    List(_) => TyList
  }
}

///|
pub fn parse_field_type(name : String) -> FieldType? {
  match name.trim().to_lower() {
    "string" | "str" => Some(TyString)
    "bool" | "boolean" => Some(TyBool)
    "int" | "integer" => Some(TyInt)
    "float" | "number" | "double" => Some(TyFloat)
    "list" | "array" => Some(TyList)
    "any" => Some(TyAny)
    _ => None
  }
}

///|
pub fn validate(doc : Document, schema : Schema) -> Array[ValidationIssue] {
  let issues : Array[ValidationIssue] = []
  for spec in schema.fields {
    match doc.frontmatter.get(spec.name) {
      None =>
        if spec.required {
          issues.push({ key: spec.name, message: "missing required key", })
        }
      Some(val) =>
        if !type_matches(val, spec.ty) {
          issues.push({
            key: spec.name,
            message: "expected type \{spec.ty.to_string()}, got \{field_type_of_value(val).to_string()}",
          })
        }
    }
  }
  issues
}

///|
fn type_matches(val : YamlValue, ty : FieldType) -> Bool {
  match (val, ty) {
    (_, TyAny) => true
    (String(_), TyString) => true
    (Bool(_), TyBool) => true
    (Int(_), TyInt) => true
    (Float(_), TyFloat) => true
    (Int(_), TyFloat) => true
    (List(_), TyList) => true
    (Null, _) => false
    _ => false
  }
}

///|
pub fn schema_of_requires(
  required_keys : ArrayView[String],
  typed : Map[String, FieldType],
) -> Schema {
  let fields : Array[FieldSpec] = []
  let seen : Map[String, Bool] = Map([])
  for key in required_keys {
    let ty = typed.get(key).unwrap_or(TyAny)
    fields.push({ name: key, required: true, ty, })
    seen.set(key, true)
  }
  for key, ty in typed {
    if !seen.contains(key) {
      fields.push({ name: key, required: false, ty, })
    }
  }
  { fields, }
}
