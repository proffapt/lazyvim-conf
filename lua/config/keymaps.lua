-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- vars
local wk = require("which-key")

-- custom logic
local function entity_close()
  local ok, _ = pcall(vim.cmd.close)
  if not ok then
    Snacks.bufdelete()
  end
end
local function run_contexify()
  local func_name = vim.fn.expand("<cword>")
  local file_path = vim.fn.expand("%:p")
  local script_path = "/Users/fbin-blr-0027/Desktop/scripts/contexify"
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
      vim.notify(
        "Successfully contexified " .. func_name .. " function ✅",
        vim.log.levels.INFO,
        { title = "Contexify " }
      )
    else
      vim.notify(
        "Failed contexified " .. func_name .. " function ❌",
        vim.log.levels.ERROR,
        { title = "Contexify " }
      )
    end
  end)
end

-- Which key setup
wk.add({
  -- Single Key Actions
  {
    "<leader>/",
    "<cmd>normal gcc<cr>",
    mode = { "n", "v" },
    desc = "Toggle Comment",
  },
  {
    "ss",
    "<cmd>w<cr>",
    mode = { "n", "v" },
    desc = "Save Buffer",
    icon = "󰆓",
  },
  {
    "<leader>X",
    entity_close,
    desc = "Close any Entity",
    icon = "",
  },
  {
    "<leader>cx",
    run_contexify,
    name = "Contexify",
    desc = "Inject ctx; Update log and sentry calls to V3",
    icon = "",
  },
})
