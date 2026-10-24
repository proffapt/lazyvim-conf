-- gopls tuning for huge repos
local heavy_repos = {
  vim.fn.expand("~/Desktop/github/lending-middleware"),
}

local function is_heavy(root)
  if not root then
    return false
  end
  for _, repo in ipairs(heavy_repos) do
    if vim.startswith(root, repo) then
      return true
    end
  end
  return false
end

local heavy_settings = {
  gopls = {
    -- skip non-Go dirs while loading the workspace
    directoryFilters = {
      "-.git",
      "-.codegraph",
      "-.opencode",
      "-.claude",
      "-.cortexkit",
      "-.omo",
      "-.trae",
      "-.act",
      "-.code-review",
      "-.github",
      "-infra",
      "-deployment",
      "-migrations",
      "-api_testing",
      "-seedlocal",
      "-htmltemplates",
      "-tmp",
      "-temp",
      "-node_modules",
    },
    semanticTokens = false,
    staticcheck = false,
    usePlaceholders = false,
    codelenses = {
      gc_details = false,
      generate = false,
      regenerate_cgo = false,
      run_govulncheck = false,
      test = false,
      tidy = false,
      upgrade_dependency = false,
      vendor = false,
    },
    hints = {
      assignVariableTypes = false,
      compositeLiteralFields = false,
      compositeLiteralTypes = false,
      constantValues = false,
      functionTypeParameters = false,
      parameterNames = false,
      rangeVariableTypes = false,
    },
  },
}

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.gopls = vim.tbl_deep_extend("force", opts.servers.gopls or {}, {
        before_init = function(params, config)
          local root = config.root_dir or params.rootPath
          if is_heavy(root) then
            config.settings = vim.tbl_deep_extend("force", config.settings or {}, heavy_settings)
            -- lang.go extra's semantic tokens workaround reads this and breaks if we strip the provider
            config.init_options = vim.tbl_deep_extend("force", config.init_options or {}, { semanticTokens = false })
          end
        end,
      })

      -- no client-side semantic tokens for gopls in heavy repos
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("heavy_go_semantic_tokens", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "gopls" and is_heavy(client.root_dir or client.config.root_dir) then
            client.server_capabilities.semanticTokensProvider = nil
          end
        end,
      })
    end,
  },

  -- lang.go enables golangci-lint; far too heavy on huge repos (CI/reviewdog covers it)
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters = {
        golangcilint = {
          condition = function(ctx)
            return not is_heavy(ctx.filename)
          end,
        },
      },
    },
  },
}
