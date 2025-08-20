local ignore_fn = {
  "general.InArr",

  -- redis
  "redis.Get",
  "redis.Set",

  -- database
  "database.GetContext",
  "database.ExecContext",
  "database.SelectContext",
  "database.NamedExecContext",
  "txn.GetContext",
  "txn.ExecContext",
  "txn.SelectContext",
  "txn.NamedExecContext",

  -- Logs
  "log.Printf",
  "log.Print",
  "log.Println",
  "log.Fatal",
  "log.Fatalln",
  "log.Fatalln",
  "log.Panic",
  "log.Panicln",
  "log.Panicf",

  -- fmt
  "fmt.Print",
  "fmt.Println",
  "fmt.Printf",
  "fmt.Sprintf",
  "fmt.Sprintln",
  "fmt.Sprint",

  -- JSON
  "json.Marshal",
  "json.Unmarshal",
  "json.NewEncoder",
  "json.NewDecoder",
  "json.Valid",

  -- Strings
  "strings.Split",
  "strings.Join",
  "strings.Replace",
  "strings.ReplaceAll",
  "strings.ToUpper",
  "strings.ToLower",
  "strings.Trim",
  "strings.TrimSpace",
  "strings.HasPrefix",
  "strings.HasSuffix",
  "strings.Contains",
  "strings.Index",
  "strings.LastIndex",

  -- Bytes
  "bytes.NewBuffer",
  "bytes.NewReader",
  "bytes.Buffer",
  "bytes.Compare",
  "bytes.Contains",
  "bytes.HasPrefix",
  "bytes.HasSuffix",
  "bytes.Index",
  "bytes.Join",
  "bytes.Repeat",
  "bytes.Split",
  "bytes.Trim",
  "bytes.TrimSpace",

  -- Built-ins
  "make",
  "len",
  "cap",
  "copy",
  "append",
  "delete",
  "new",
  "complex",
  "real",
  "imag",
  "panic",
  "recover",
  "close",

  -- Primitive types
  "string",
  "byte",
  "rune",
  "int",
  "int8",
  "int16",
  "int32",
  "int64",
  "uint",
  "uint8",
  "uint16",
  "uint32",
  "uint64",
  "float32",
  "float64",
  "bool",
}

return {
  ignore_fn = ignore_fn,
}
