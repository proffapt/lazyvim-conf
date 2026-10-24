-- hidden dirs we never want in file/grep results
local search_exclude = {
  ".git",
  ".codegraph",
  ".opencode",
  ".claude",
  ".cursor*",
  ".cortexkit",
  ".omo",
  ".trae",
  ".act",
  "tmp",
}

return {
  {
    "folke/snacks.nvim",
    opts = {
      -- disable LSP/treesitter/etc. on huge files (default 1.5MB)
      bigfile = { size = 500 * 1024 },
      picker = {
        sources = {
          explorer = {
            ignored = false,
            hidden = true,
          },
          files = {
            ignored = false,
            hidden = true,
            exclude = search_exclude,
          },
          grep = {
            hidden = true,
            exclude = search_exclude,
          },
        },
      },
    },
    keys = {
      { "<leader>/", false },
      {
        "<leader>s.",
        function()
          Snacks.picker()
        end,
        desc = "Show all pickers",
      },
      {
        "<leader>ueh",
        function()
          -- Get the current config
          local config = require("snacks").config
          -- Toggle the hidden setting
          config.picker.sources.explorer.hidden = not config.picker.sources.explorer.hidden
          -- Notify about the change
          vim.notify("Explorer hidden files: " .. (config.picker.sources.explorer.hidden and "shown" or "hidden"))
        end,
        desc = "Toggle explorer hidden files",
      },
      {
        "<leader>uei",
        function()
          -- Get the current config
          local config = require("snacks").config
          -- Toggle the ignored setting
          config.picker.sources.explorer.ignored = not config.picker.sources.explorer.ignored
          -- Notify about the change
          vim.notify("Explorer ignored files: " .. (config.picker.sources.explorer.ignored and "shown" or "hidden"))
        end,
        desc = "Toggle explorer ignored files",
      },
      {
        "<leader>ufh",
        function()
          -- Get the current config
          local config = require("snacks").config
          -- Toggle the hidden setting
          config.picker.sources.files.hidden = not config.picker.sources.files.hidden
          -- Notify about the change
          vim.notify("files hidden files: " .. (config.picker.sources.files.hidden and "shown" or "hidden"))
        end,
        desc = "Toggle hidden files",
      },
      {
        "<leader>ufi",
        function()
          -- Get the current config
          local config = require("snacks").config
          -- Toggle the ignored setting
          config.picker.sources.files.ignored = not config.picker.sources.files.ignored
          -- Notify about the change
          vim.notify("files ignored files: " .. (config.picker.sources.files.ignored and "shown" or "hidden"))
        end,
        desc = "Toggle ignored files",
      },
    },
  },
}
