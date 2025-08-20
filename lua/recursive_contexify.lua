local contexify = require("contexify")

local function get_calls_in_function(bufnr, func_name)
  bufnr = bufnr or 0
  local ft = vim.bo[bufnr].filetype
  local parsers = require("nvim-treesitter.parsers")
  local ts = vim.treesitter

  if not parsers.has_parser(ft) then
    vim.notify("No Treesitter parser for filetype: " .. ft, vim.log.levels.ERROR)
    return {}
  end

  local parser = parsers.get_parser(bufnr, ft)
  if not parser then
    vim.notify("Parser not available for " .. ft, vim.log.levels.ERROR)
    return {}
  end

  local tree = parser:parse()[1]
  if not tree then
    return {}
  end
  local root = tree:root()
  local calls = {}

  -- Safe get_node_text
  local function safe_get_node_text(node)
    if not node then
      return ""
    end
    local ok, text = pcall(ts.get_node_text, node, bufnr)
    return (ok and text) or ""
  end

  -- Query-based argument extraction
  local function get_arguments(call_node)
    local args = {}
    local ok, query = pcall(
      ts.query.parse,
      ft,
      [[
      (call_expression
        arguments: (argument_list) @args)
    ]]
    )
    if not ok or not query then
      return args
    end

    for id, node, _ in query:iter_captures(call_node, bufnr, 0, -1) do
      if id == 0 then -- @args capture
        for i = 0, node:named_child_count() - 1 do
          local child = node:named_child(i)
          if child:type() ~= "," then
            local text = safe_get_node_text(child)
            if text ~= "" then
              table.insert(args, text)
            end
          end
        end
      end
    end
    vim.notify(vim.inspect(args), vim.log.levels.DEBUG, { title = "Contexify " })
    return args
  end

  -- Query function by name
  local ok, query = pcall(
    ts.query.parse,
    ft,
    [[
    (function_declaration
      name: (identifier) @func_name
      (_) @body)
  ]]
  )
  if not ok or not query then
    vim.notify("Failed to parse Treesitter query for " .. ft, vim.log.levels.ERROR)
    return {}
  end

  local start_row, end_row = 0, vim.api.nvim_buf_line_count(bufnr)
  for id, node, _ in query:iter_captures(root, bufnr, start_row, end_row) do
    local name = safe_get_node_text(node)
    if id == 1 and name == func_name then
      local body_node = node:parent():field("body")[1]
      if body_node then
        local ok2, call_query = pcall(
          ts.query.parse,
          ft,
          [[
          (call_expression
            function: (_) @call_func)
        ]]
        )
        if ok2 and call_query then
          local s_row, e_row = body_node:start(), body_node:end_()
          for _, call_node, _ in call_query:iter_captures(body_node, bufnr, s_row, e_row) do
            local text = safe_get_node_text(call_node)
            local status = "❌"

            local args = get_arguments(call_node)
            for _, arg_text in ipairs(args) do
              if arg_text:match("ctx") then
                status = "✅"
                break
              elseif arg_text:match("context%.TODO") or arg_text:match("context%.Background") then
                status = "⚠️"
              end
            end

            table.insert(calls, {
              name = text,
              buf = bufnr,
              line = call_node:start() + 1,
              status = status,
            })
          end
        end
      end
    end
  end

  return calls
end

local function add_ctx_to_call(parent_func, child_func)
  local bufnr = 0
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local inside_parent = false
  local modified = false

  for i, line in ipairs(lines) do
    if line:match("func%s+" .. parent_func .. "%(") then
      inside_parent = true
    elseif inside_parent and line:match("^func%s") then
      inside_parent = false
    end

    if inside_parent then
      -- Only add ctx if it’s not already the first argument
      local pattern = child_func .. "%(%s*ctx%s*,?"
      if not line:match(pattern) then
        local new_line, n = line:gsub(child_func .. "%(", child_func .. "(ctx, ")
        if n > 0 then
          vim.api.nvim_buf_set_lines(bufnr, i - 1, i, false, { new_line })
          modified = true
        end
      end
    end
  end

  -- Save buffer if modified
  if modified then
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd("write")
    end)
  end
end

local function pick_and_process(func_name)
  local calls = get_calls_in_function(0, func_name)
  if #calls == 0 then
    return
  end

  vim.ui.select(calls, {
    prompt = "Function calls in " .. func_name,
    format_item = function(item)
      return item.status .. " " .. item.name
    end,
  }, function(choice)
    if choice then
      add_ctx_to_call(func_name, choice.name)
      -- contexify.run_contexify(choice.name)

      if choice.buf and choice.line then
        vim.api.nvim_win_set_cursor(0, { choice.line, 0 })
      end

      -- pick_and_process(choice.name)
    end
  end)
end

require("which-key").add({
  {
    "<leader>cX",
    function()
      local func_name = vim.fn.expand("<cword>")
      contexify.run_contexify(func_name)
      pick_and_process(func_name)
    end,
    name = "Recursive Contexify",
    desc = "Recursively contexify the codebase",
    icon = "",
  },
})
