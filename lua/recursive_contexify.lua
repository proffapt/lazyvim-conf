local ts = require("nvim-treesitter")
local parsers = require("nvim-treesitter.parsers")

-- 1️⃣ Get calls inside a function
local function get_calls_in_function(bufnr, func_name)
  bufnr = bufnr or 0
  local ft = vim.bo[bufnr].filetype

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

  local ok, query = pcall(
    vim.treesitter.query.parse,
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
    local name = vim.treesitter.get_node_text(node, bufnr)
    if id == 1 and name == func_name then
      local body_node = node:parent():field("body")[1]
      if body_node then
        local ok2, call_query = pcall(
          vim.treesitter.query.parse,
          ft,
          [[
          (call_expression
            function: (_) @call_func)
        ]]
        )
        if ok2 and call_query then
          local s_row = body_node:start()
          local e_row = body_node:end_()
          for _, call_node, _ in call_query:iter_captures(body_node, bufnr, s_row, e_row) do
            table.insert(calls, {
              name = vim.treesitter.get_node_text(call_node, bufnr),
              buf = bufnr,
              line = call_node:start() + 1,
            })
          end
        end
      end
    end
  end

  return calls
end

-- 2️⃣ Insert ctx in parent call
local function add_ctx_to_call(parent_func, child_func)
  local bufnr = 0
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local inside_parent = false

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
        end
      end
    end
  end
end

-- 3️⃣ Run contexify on a function
local function run_contexify_on_function(func_name)
  local file_path = vim.fn.expand("%:p")
  local pkg_name = vim.fn.systemlist("awk '/^package / {print $2; exit}' " .. file_path)[1]
  local script_path = "/Users/fbin-blr-0027/Desktop/scripts/contexify"
  local cmd = string.format('bash -c "%s %s %s \\"%s\\""', script_path, func_name, pkg_name, file_path)

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code)
      if code == 0 then
        vim.schedule(function()
          vim.notify("Contexify successful ✅: " .. func_name, vim.log.levels.INFO)
        end)
      else
        vim.schedule(function()
          vim.notify("Contexify failed ❌: " .. func_name, vim.log.levels.ERROR)
        end)
      end
    end,
  })
end

-- 4️⃣ Recursive picker using vim.ui.select
local function pick_and_process(func_name)
  local calls = get_calls_in_function(0, func_name)
  if #calls == 0 then
    return
  end

  vim.ui.select(calls, {
    prompt = "Function calls in " .. func_name,
    format_item = function(item)
      return item.name
    end,
  }, function(choice)
    if choice then
      add_ctx_to_call(func_name, choice.name)
      run_contexify_on_function(choice.name)

      if choice.buf and choice.line then
        vim.api.nvim_win_set_cursor(0, { choice.line, 0 })
      end

      pick_and_process(choice.name)
    end
  end)
end

-- 5️⃣ Keymap
require("which-key").add({
  {
    "<leader>cX",
    function()
      local func_name = vim.fn.expand("<cword>")
      run_contexify_on_function(func_name)
      pick_and_process(func_name)
    end,
    name = "Recursive Contexify",
    desc = "Recursively contexify the codebase",
    icon = "",
  },
})
