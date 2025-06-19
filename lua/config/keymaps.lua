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
})
