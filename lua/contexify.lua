local script_path = "/Users/fbin-blr-0027/Desktop/scripts/contexify"

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
    end,

    name = "Contexify",
    desc = "Inject ctx; Update log and sentry calls to V3",
    icon = "",
  },
})

return {
  run_contexify = run_contexify,
}
