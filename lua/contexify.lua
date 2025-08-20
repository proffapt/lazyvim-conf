local script_path = "/Users/fbin-blr-0027/Desktop/scripts/contexify"

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
        -- Get all lines inside the function
        local s_row, e_row = body_node:start(), body_node:end_()
        local lines = vim.api.nvim_buf_get_lines(bufnr, s_row, e_row, false)

        for i, line in ipairs(lines) do
          -- Look for any call: match identifier followed by (
          for call_name in line:gmatch("([%w_%.]+)%s*%(") do
            local args_str = line:match(call_name .. "%s*%((.*)%)") or ""
            local status = "❌"

            if args_str:match("ctx") then
              status = "✅"
            elseif args_str:match("context%.TODO") or args_str:match("context%.Background") then
              status = "⚠️"
            end

            table.insert(calls, {
              name = call_name,
              buf = bufnr,
              line = s_row + i,
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

      if choice.buf and choice.line and choice.name then
        vim.api.nvim_set_current_buf(choice.buf)

        -- Get the full line text
        local line_text = vim.api.nvim_buf_get_lines(choice.buf, choice.line - 1, choice.line, false)[1]

        -- Find the start column of the function name
        local col = line_text:find(choice.name, 1, true) or 0

        -- Move cursor to function name
        vim.api.nvim_win_set_cursor(0, { choice.line, col })

        -- Trigger LSP "go to definition"
        vim.lsp.buf.definition()
      end

      -- pick_and_process(choice.name)
    end
  end)
end

local function run_contexify(func_name)
  local file_path = vim.fn.expand("%:p")
  local pkg_name = vim.fn.systemlist("awk '/^package / {print $2; exit}' " .. file_path)[1]

  -- Run script and echo exit code at the end
  local cmd =
    string.format('bash -c "%s %s %s \\"%s\\"; echo EXIT_CODE:$?"', script_path, func_name, pkg_name, file_path)

  local handle = io.popen(cmd)
  if not handle then
    vim.notify("Failed to start contexify script ❌", vim.log.levels.ERROR, { title = "Contexify " })
    return
  end

  local exit_code
  for line in handle:lines() do
    if line:match("^EXIT_CODE:") then
      exit_code = tonumber(line:sub(11))
    else
      vim.schedule(function()
        vim.notify(line, vim.log.levels.INFO, { title = "Contexify " })
      end)
    end
  end

  handle:close()

  vim.schedule(function()
    if exit_code == 0 then
      vim.notify("Contexify successful ✅", vim.log.levels.INFO, { title = "Contexify " })
    else
      vim.notify("Contexify failed ❌", vim.log.levels.ERROR, { title = "Contexify " })
    end
  end)
end

require("which-key").add({
  {
    "<leader>cx",
    function()
      local func_name = vim.fn.expand("<cword>")
      run_contexify(func_name)
      pick_and_process(func_name)
    end,
    name = "Contexify",
    desc = "Inject and use context in function calls",
    icon = "",
  },
})
