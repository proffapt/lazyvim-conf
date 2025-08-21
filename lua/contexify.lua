local contexify_list = require("contexify_list")

local function contexify_references(func_name)
  if func_name:match("Cont$") then
    return
  end

  local bufnr = 0
  local params = vim.lsp.util.make_position_params(bufnr, "utf-16")

  vim.lsp.buf_request(bufnr, "textDocument/references", params, function(err, result)
    if err then
      vim.schedule(function()
        vim.notify("LSP reference request failed: " .. (err.message or tostring(err)), vim.log.levels.ERROR)
      end)
      return
    end

    if not result or vim.tbl_isempty(result) then
      vim.schedule(function()
        vim.notify("No references found for " .. func_name, vim.log.levels.INFO)
      end)
      return
    end

    local modified_buffers = {}
    local seen_lines = {}  -- Track unique line content per buffer

    for _, ref in ipairs(result) do
      local ref_buf = vim.uri_to_bufnr(ref.uri)
      if not vim.api.nvim_buf_is_loaded(ref_buf) then
        local ok, _ = pcall(vim.fn.bufload, ref_buf)
        if not ok then
          vim.schedule(function()
            vim.notify(
              "⚠️ Skipped buffer (swap file or locked): " .. vim.api.nvim_buf_get_name(ref_buf),
              vim.log.levels.WARN
            )
          end)
          goto continue
        end
      end

      local start_line = ref.range.start.line
      local lines = vim.api.nvim_buf_get_lines(ref_buf, start_line, start_line + 1, false)
      if not lines or #lines == 0 then
        goto continue
      end
      local line = lines[1]

      -- Skip if this line content was already modified
      seen_lines[ref_buf] = seen_lines[ref_buf] or {}
      if seen_lines[ref_buf][line] then
        goto continue
      end

      -- Apply gsub once per unique line content
      line = line:gsub(func_name .. "%(", func_name .. "(context.TODO(), ")
      vim.api.nvim_buf_set_lines(ref_buf, start_line, start_line + 1, false, { line })
      modified_buffers[ref_buf] = true
      seen_lines[ref_buf][line] = true  -- Mark this line as modified

      ::continue::
    end

    -- Save and run goimports only for successfully modified buffers
    for buf, _ in pairs(modified_buffers) do
      vim.schedule(function()
        local name = vim.api.nvim_buf_get_name(buf)
        if vim.api.nvim_buf_is_loaded(buf) then
          vim.api.nvim_buf_call(buf, function()
            vim.cmd("write")
          end)
          vim.fn.system("goimports -w " .. name)
        end
      end)
    end

    vim.schedule(function()
      vim.notify("✅ Contexified " .. func_name .. " across all references", vim.log.levels.INFO)
    end)
  end)
end

local function run_contexify(func_name)
  local script_path = "/Users/fbin-blr-0027/Desktop/scripts/contexify"
  local file_path = vim.fn.expand("%:p")
  local line_no = vim.fn.line(".")
  local pkg_name = vim.fn.systemlist("awk '/^package / {print $2; exit}' " .. file_path)[1]

  local cmd = string.format(
    'bash -c "%s %s %s %s \\"%s\\"; echo EXIT_CODE:$?"',
    script_path,
    func_name,
    line_no,
    pkg_name,
    file_path
  )

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

  -- Call LSP-based references
  contexify_references(func_name)

  -- Reload buffer to reflect changes
  vim.api.nvim_buf_call(0, function()
    local view = vim.fn.winsaveview()
    vim.cmd("edit")
    vim.fn.winrestview(view)
  end)
end

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

  local function safe_get_node_text(node)
    if not node then
      return ""
    end
    local ok, text = pcall(ts.get_node_text, node, bufnr)
    return (ok and text) or ""
  end

  -- Query the target function by name
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

  -- Build a set of valid call positions from tree-sitter
  local valid_calls = {}
  local call_query = ts.query.parse(
    ft,
    [[
    (call_expression
      function: (identifier) @call)
    (call_expression
      function: (selector_expression) @call)
  ]]
  )
  for id, node, _ in call_query:iter_captures(root, bufnr, 0, -1) do
    if id == 1 then
      local start_row = node:start()
      valid_calls[start_row + 1] = valid_calls[start_row + 1] or {}
      table.insert(valid_calls[start_row + 1], safe_get_node_text(node))
    end
  end

  -- Process lines, only include calls recognized by Treesitter
  local start_row, end_row = 0, vim.api.nvim_buf_line_count(bufnr)
  for id, node, _ in query:iter_captures(root, bufnr, start_row, end_row) do
    local name = safe_get_node_text(node)
    if id == 1 and name == func_name then
      local body_node = node:parent():field("body")[1]
      if body_node then
        local s_row, e_row = body_node:start(), body_node:end_()
        local lines = vim.api.nvim_buf_get_lines(bufnr, s_row, e_row, false)

        for i, line in ipairs(lines) do
          if not line:match("^%s*func%s") and not line:match("^%s*//") and line:match("%S") then
            for call_name in line:gmatch("([%w_%.]+)%s*%(") do
              local tree_calls = valid_calls[s_row + i] or {}
              local matched = false
              for _, tcall in ipairs(tree_calls) do
                if tcall == call_name then
                  matched = true
                  break
                end
              end
              if matched and not vim.tbl_contains(contexify_list.ignore_fn, call_name) then
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
      -- Replace all occurrences of child_func( that do not already have ctx
      local new_line = line
      local start_pos = 1

      while true do
        local s, e = new_line:find(child_func .. "%(", start_pos)
        if not s then
          break
        end

        local after = new_line:sub(e + 1)
        -- Check if 'ctx' is already the first argument
        if not after:match("^%s*ctx%s*,?") then
          new_line = new_line:sub(1, e) .. "ctx, " .. after
          modified = true
        end
        start_pos = e + 1
      end

      if modified then
        vim.api.nvim_buf_set_lines(bufnr, i - 1, i, false, { new_line })
      end
    end
  end

  -- Save buffer if modified
  if modified then
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd("write")
    end)

    vim.api.nvim_buf_call(0, function()
      local view = vim.fn.winsaveview()
      vim.cmd("edit")
      vim.fn.winrestview(view)
    end)
  end
end

local function pick_and_process(func_name)
  local calls = get_calls_in_function(0, func_name)
  if #calls == 0 then
    return
  end

  -- Deduplicate by function name and filter ignore list
  local unique_calls = {}
  local seen = {}
  for _, c in ipairs(calls) do
    if not seen[c.name] and not vim.tbl_contains(contexify_list.ignore_fn, c.name) then
      table.insert(unique_calls, c)
      seen[c.name] = true
    end
  end

  vim.ui.select(unique_calls, {
    prompt = "Function calls in " .. func_name,
    format_item = function(item)
      return item.status .. " " .. item.name
    end,
  }, function(choice)
    if choice then
      -- Add ctx to ALL occurrences of this function in parent_func
      add_ctx_to_call(func_name, choice.name)

      -- Go to any one instance
      local first_call = nil
      for _, c in ipairs(calls) do
        if c.name == choice.name then
          first_call = c
          break
        end
      end

      if first_call and first_call.buf and first_call.line then
        vim.api.nvim_set_current_buf(first_call.buf)

        local line_text = vim.api.nvim_buf_get_lines(first_call.buf, first_call.line - 1, first_call.line, false)[1]
        local func_only = choice.name:match("[^.]+$") or choice.name
        local col = line_text:find(func_only, 1, true) or 0

        vim.api.nvim_win_set_cursor(0, { first_call.line, col })

        -- Trigger LSP "go to definition"
        vim.lsp.buf.definition()
      end
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
