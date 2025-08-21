local ignore_list = {
  "general.InArr",

  -- redis
  "redis.*",

  -- database
  "database.*",
  "txn.*",

  -- log
  "log.*",

  -- fmt
  "fmt.*",

  -- json
  "json.*",

  -- strings
  "strings.*",

  -- bytes
  "bytes.*",

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

local function is_ignored(name)
  for _, ignore in ipairs(ignore_list) do
    if ignore:sub(-2) == ".*" then
      -- Prefix match (json.* → matches json.Marshal, json.NewEncoder, etc.)
      local prefix = ignore:sub(1, -3) -- remove ".*"
      if vim.startswith(name, prefix) then
        return true
      end
    else
      -- Exact match
      if name == ignore then
        return true
      end
    end
  end
  return false
end

return {
  is_ignored = is_ignored,
}
