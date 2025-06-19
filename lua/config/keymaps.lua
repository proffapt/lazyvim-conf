-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local opts = { noremap = true, silent = true }
local keymap = LazyVim.safe_keymap_set

-- custom logic
local function entity_close()
  local ok, _ = pcall(vim.cmd.close)
  if not ok then
    Snacks.bufdelete()
  end
end

-- toggle comment
keymap({ "n", "v" }, "<Leader>/", "<cmd>normal gcc<cr>", { desc = "Toggle Comment" })

-- close anything - literally anything
keymap("n", "<leader>X", entity_close, opts)
