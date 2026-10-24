-- language support not covered by a LazyVim extra
-- (go, rust, elixir, python, typescript, json, yaml, toml, markdown, docker, clangd come from extras in config/lazy.lua)
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "bash",
        "c",
        "cpp",
        "css",
        "diff",
        "dockerfile",
        "eex",
        "elixir",
        "go",
        "gomod",
        "gosum",
        "gowork",
        "heex",
        "html",
        "javascript",
        "json",
        "json5",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "regex",
        "ron",
        "rust",
        "sql",
        "toml",
        "tsx",
        "typescript",
        "xml",
        "yaml",
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {},
        html = {},
        cssls = {},
        lemminx = {}, -- xml
        nginx_language_server = {},
        postgres_lsp = {
          -- attach without a postgres-language-server.jsonc in the project
          workspace_required = false,
          root_markers = { "postgres-language-server.jsonc", ".git" },
        },
        -- mason-lspconfig auto-enables every installed server; these duplicate pyright/ruff and marksman
        pylsp = { enabled = false },
        markdown_oxide = { enabled = false },
      },
    },
  },

  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "shellcheck",
        "shfmt",
        "pgformatter",
        "postgres-language-server",
      })
    end,
  },

  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        sh = { "shfmt" },
        bash = { "shfmt" },
        sql = { "pg_format" },
        pgsql = { "pg_format" },
      },
    },
  },
}
