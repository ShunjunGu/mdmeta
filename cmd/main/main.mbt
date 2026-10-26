///| mdmeta CLI — get / set / list / validate / batch Markdown frontmatter.

///|
fn usage() -> String {
  (
    #|mdmeta — Markdown YAML frontmatter toolkit
    #|
    #|Usage:
    #|  mdmeta get <file> <key>
    #|  mdmeta set <file> <key> <value> [--in-place]
    #|  mdmeta list <file>
    #|  mdmeta validate <file> [--require KEY]... [--type KEY=TYPE]...
    #|  mdmeta batch <dir> [--require KEY]... [--type KEY=TYPE]... [--ext .md]
    #|
    #|Types: string | bool | int | float | list | any
    #|YAML subset: scalars and simple lists only.
  )
}

///|
fn first_value(m : Map[String, Array[String]], key : String) -> String? {
  match m.get(key) {
    None => None
    Some(arr) => if arr.length() == 0 { None } else { Some(arr[0]) }
  }
}

///|
fn all_values(m : Map[String, Array[String]], key : String) -> Array[String] {
  match m.get(key) {
    None => []
    Some(arr) => arr
  }
}

///|
fn parse_cli_value(raw : String) -> @mdmeta.YamlValue raise {
  let text = "v: \{raw}"
  let map = @mdmeta.parse_yaml_map(text)
  match map.get("v") {
    Some(v) => v
    None => @mdmeta.YamlValue::String(raw)
  }
}

///|
fn build_schema(
  requires : Array[String],
  type_args : Array[String],
) -> @mdmeta.Schema raise {
  let typed : Map[String, @mdmeta.FieldType] = Map([])
  for spec in type_args {
    match spec.split_once("=") {
      None => raise Failure("invalid --type \{spec}, expected KEY=TYPE")
      Some((k, t)) => {
        let key = k.trim().to_owned()
        let ty_name = t.trim().to_owned()
        match @mdmeta.parse_field_type(ty_name) {
          None => raise Failure("unknown type \{ty_name}")
          Some(ty) => typed.set(key, ty)
        }
      }
    }
  }
  @mdmeta.schema_of_requires(requires[:], typed)
}

///|
fn is_markdown(name : String, ext : String) -> Bool {
  name.has_suffix(ext) || name.has_suffix(ext.to_upper())
}

///|
fn cmd_get(file : String, key : String) -> Unit raise {
  let text = @fs.read_file_to_string(file)
  let doc = @mdmeta.parse_document(text)
  match @mdmeta.get_field(doc, key) {
    None => {
      println("")
      @sys.exit(1)
    }
    Some(v) => println(@mdmeta.yaml_value_to_string(v))
  }
}

///|
fn cmd_list(file : String) -> Unit raise {
  let text = @fs.read_file_to_string(file)
  let doc = @mdmeta.parse_document(text)
  for k in @mdmeta.list_fields(doc) {
    match @mdmeta.get_field(doc, k) {
      Some(v) => println("\{k}\t\{@mdmeta.yaml_value_to_string(v)}")
      None => println(k)
    }
  }
}

///|
fn cmd_set(
  file : String,
  key : String,
  value : String,
  in_place : Bool,
) -> Unit raise {
  let text = @fs.read_file_to_string(file)
  let doc0 = @mdmeta.parse_document(text)
  let doc1 = @mdmeta.with_field(doc0, key, parse_cli_value(value))
  let out = @mdmeta.render_document(doc1)
  if in_place {
    @fs.write_string_to_file(file, out)
  } else {
    println(out)
  }
}

///|
fn cmd_validate(file : String, schema : @mdmeta.Schema) -> Unit raise {
  let text = @fs.read_file_to_string(file)
  let doc = @mdmeta.parse_document(text)
  let issues = @mdmeta.validate(doc, schema)
  if issues.length() == 0 {
    println("ok")
  } else {
    for issue in issues {
      println("\{issue.key}: \{issue.message}")
    }
    @sys.exit(1)
  }
}

///|
fn cmd_batch(dir : String, schema : @mdmeta.Schema, ext : String) -> Unit raise {
  let entries = @fs.read_dir(dir).to_owned()
  let files : Array[Json] = []
  let mut ok_count = 0
  let mut err_count = 0
  for name in entries {
    if !is_markdown(name, ext) {
      continue
    }
    let path = @path.Path::Path(dir).join(@path.Path::Path(name)).to_string()
    let file_obj : Map[String, Json] = Map([("path", Json::string(path))])
    try {
      let text = @fs.read_file_to_string(path)
      let doc = @mdmeta.parse_document(text)
      let issues = @mdmeta.validate(doc, schema)
      file_obj.set("frontmatter", @mdmeta.frontmatter_to_json(doc.frontmatter))
      let issue_json : Array[Json] = []
      for issue in issues {
        issue_json.push(
          Json::object(
            Map([
              ("key", Json::string(issue.key)),
              ("message", Json::string(issue.message)),
            ]),
          ),
        )
      }
      file_obj.set("issues", Json::array(issue_json))
      file_obj.set("ok", Json::boolean(issues.length() == 0))
      if issues.length() == 0 {
        ok_count = ok_count + 1
      } else {
        err_count = err_count + 1
      }
    } catch {
      e => {
        file_obj.set("ok", Json::boolean(false))
        file_obj.set("error", Json::string(e.to_string()))
        err_count = err_count + 1
      }
    }
    files.push(Json::object(file_obj))
  }
  let report = Json::object(
    Map([
      ("dir", Json::string(dir)),
      ("ok", Json::number(ok_count.to_double())),
      ("errors", Json::number(err_count.to_double())),
      ("files", Json::array(files)),
    ]),
  )
  println(report.stringify(indent=2))
  if err_count > 0 {
    @sys.exit(1)
  }
}

///|
fn main raise {
  let get_cmd = @argparse.Command("get", about="Print one frontmatter value", positionals=[
    @argparse.PositionArg("file", about="Markdown file"),
    @argparse.PositionArg("key", about="Frontmatter key"),
  ])
  let set_cmd = @argparse.Command(
    "set",
    about="Set a frontmatter key (prints unless --in-place)",
    flags=[
      @argparse.FlagArg(
        "in-place",
        long="in-place",
        about="Write file in place",
      ),
    ],
    positionals=[
      @argparse.PositionArg("file", about="Markdown file"),
      @argparse.PositionArg("key", about="Frontmatter key"),
      @argparse.PositionArg("value", about="Value (YAML scalar or [a,b] list)"),
    ],
  )
  let list_cmd = @argparse.Command(
    "list",
    about="List frontmatter keys and values",
    positionals=[@argparse.PositionArg("file", about="Markdown file")],
  )
  let validate_cmd = @argparse.Command(
    "validate",
    about="Validate frontmatter against required keys/types",
    options=[
      @argparse.OptionArg(
        "require",
        long="require",
        about="Required key (repeatable)",
        action=@argparse.OptionAction::Append,
      ),
      @argparse.OptionArg(
        "type",
        long="type",
        about="KEY=TYPE constraint (repeatable)",
        action=@argparse.OptionAction::Append,
      ),
    ],
    positionals=[@argparse.PositionArg("file", about="Markdown file")],
  )
  let batch_cmd = @argparse.Command(
    "batch",
    about="Validate all Markdown files in a directory; print JSON report",
    options=[
      @argparse.OptionArg(
        "require",
        long="require",
        about="Required key (repeatable)",
        action=@argparse.OptionAction::Append,
      ),
      @argparse.OptionArg(
        "type",
        long="type",
        about="KEY=TYPE constraint (repeatable)",
        action=@argparse.OptionAction::Append,
      ),
      @argparse.OptionArg("ext", long="ext", about="File extension filter", default_values=[
        ".md",
      ]),
    ],
    positionals=[@argparse.PositionArg("dir", about="Directory path")],
  )
  let root = @argparse.Command(
    "mdmeta",
    about="Markdown YAML frontmatter toolkit",
    version="0.1.0",
    subcommands=[get_cmd, set_cmd, list_cmd, validate_cmd, batch_cmd],
    subcommand_required=true,
    arg_required_else_help=true,
  )

  let matches = root.parse()
  match matches.subcommand {
    None => {
      println(usage())
      @sys.exit(2)
    }
    Some(("get", sub)) => {
      let file = first_value(sub.values, "file").unwrap()
      let key = first_value(sub.values, "key").unwrap()
      cmd_get(file, key)
    }
    Some(("set", sub)) => {
      let file = first_value(sub.values, "file").unwrap()
      let key = first_value(sub.values, "key").unwrap()
      let value = first_value(sub.values, "value").unwrap()
      let in_place = sub.flags.get("in-place").unwrap_or(false)
      cmd_set(file, key, value, in_place)
    }
    Some(("list", sub)) => {
      let file = first_value(sub.values, "file").unwrap()
      cmd_list(file)
    }
    Some(("validate", sub)) => {
      let file = first_value(sub.values, "file").unwrap()
      let schema = build_schema(
        all_values(sub.values, "require"),
        all_values(sub.values, "type"),
      )
      cmd_validate(file, schema)
    }
    Some(("batch", sub)) => {
      let dir = first_value(sub.values, "dir").unwrap()
      let ext = first_value(sub.values, "ext").unwrap_or(".md")
      let schema = build_schema(
        all_values(sub.values, "require"),
        all_values(sub.values, "type"),
      )
      cmd_batch(dir, schema, ext)
    }
    Some((name, _)) => {
      println("unknown subcommand: \{name}")
      println(usage())
      @sys.exit(2)
    }
  }
}
