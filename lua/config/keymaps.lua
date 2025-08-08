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
  local func_name = vim.fn.expand("<cword>") -- word under cursor
  local file_path = vim.fn.expand("%:p") -- full path of current file
  local script_path = "/Users/fbin-blr-0027/Desktop/scripts/contexify"

  local cmd = string.format('bash %s %s "%s"', script_path, func_name, file_path)
  vim.cmd("!" .. cmd)
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
