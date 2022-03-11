-- Currently used language servers:
-- - r_language_server for R
-- - pyright for Python
-- - sumneko_lua for Lua

local lspconfig = require('lspconfig')

-- Preconfiguration ===========================================================
local on_attach_custom = function(client, bufnr)
  local function buf_set_option(name, value)
    vim.api.nvim_buf_set_option(bufnr, name, value)
  end

  buf_set_option('omnifunc', 'v:lua.MiniCompletion.completefunc_lsp')

  -- Mappings are created globally for simplicity

  -- Currently all formatting is handled with 'null-ls' plugin
  client.resolved_capabilities.document_formatting = false
end

local diagnostic_opts = {
  -- Show gutter sings
  signs = {
    -- With highest priority
    priority = 9999,
    -- Only for warnings and errors
    severity = { min = 'WARN', max = 'ERROR' },
  },
  -- Show virtual text only for errors
  virtual_text = { severity = { min = 'ERROR', max = 'ERROR' } },
  -- Don't update diagnostics when typing
  update_in_insert = false,
}

vim.diagnostic.config(diagnostic_opts)

-- R (r_language_server) ======================================================
lspconfig.r_language_server.setup({
  on_attach = on_attach_custom,
  -- Debounce "textDocument/didChange" notifications because they are slowly
  -- processed (seen when going through completion list with `<C-N>`)
  flags = { debounce_text_changes = 150 },
})

-- Python (pyright) ===========================================================
lspconfig.pyright.setup({ on_attach = on_attach_custom })

-- Lua (sumneko_lua) ==========================================================
-- Expected to use precompiled binaries from Github releases:
-- https://github.com/sumneko/lua-language-server/wiki/PreCompiled-Binaries
-- Should be extracted into '.config/nvim/misc' as 'lua-language-server' directory.
-- Code structure is taken from https://www.chrisatmachine.com/Neovim/28-neovim-lua-development/
local sumneko_root = vim.fn.expand('$HOME/.config/nvim/misc/lua-language-server')
if vim.fn.isdirectory(sumneko_root) == 1 then
  local sumneko_binary = sumneko_root .. '/bin/lua-language-server'

  lspconfig.sumneko_lua.setup({
    cmd = { sumneko_binary, '-E', sumneko_root .. '/main.lua' },
    on_attach = function(client, bufnr)
      on_attach_custom(client, bufnr)
      -- Reduce unnecessarily long list of completion triggers for better
      -- `MiniCompletion` experience
      client.server_capabilities.completionProvider.triggerCharacters = { '.', ':' }
    end,
    root_dir = function(fname)
      return lspconfig.util.root_pattern('.git')(fname) or lspconfig.util.path.dirname(fname)
    end,
    settings = {
      Lua = {
        runtime = {
          -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
          version = 'LuaJIT',
          -- Setup your lua path
          path = vim.split(package.path, ';'),
        },
        diagnostics = {
          -- Get the language server to recognize common globals
          globals = { 'vim', 'describe', 'it', 'before_each', 'after_each' },
        },
        workspace = {
          -- Don't analyze code from submodules
          ignoreSubmodules = true,
          -- Don't analyze 'undo cache'
          ignoreDir = { 'undodir' },
          -- Make the server aware of Neovim runtime files
          library = { [vim.fn.expand('$VIMRUNTIME/lua')] = true, [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true },
        },
        -- Do not send telemetry data containing a randomized but unique identifier
        telemetry = {
          enable = false,
        },
      },
    },
  })
end
