vim.cmd('colorscheme randomhue')

require('mini.sessions').setup({ directory = vim.fn.stdpath('config') .. '/misc/sessions' })

require('mini.starter').setup()
vim.cmd([[autocmd User MiniStarterOpened
  \ lua vim.keymap.set(
  \   'n',
  \   '<CR>',
  \   '<Cmd>lua MiniStarter.eval_current_item(); MiniMap.open()<CR>',
  \   { buffer = true }
  \ )]])

require('mini.files').setup({ windows = { preview = true } })
local minifiles_augroup = vim.api.nvim_create_augroup('ec-mini-files', {})
vim.api.nvim_create_autocmd('User', {
  group = minifiles_augroup,
  pattern = 'MiniFilesWindowOpen',
  callback = function(args) vim.api.nvim_win_set_config(args.data.win_id, { border = 'double' }) end,
})

local miniclue = require('mini-dev.clue')
miniclue.setup({
  clues = {
    EC.leader_group_clues,

    miniclue.gen_clues.builtin_completion(),
    miniclue.gen_clues.windows({ submode_focus = true, submode_move = true, submode_resize = true }),
    miniclue.gen_clues.g(),

    { mode = 'n', keys = '<C-w>gga', desc = 'Case 1', postkeys = '<C-w>gg' },
    { mode = 'n', keys = '<C-w>ggb', desc = 'Case 2', postkeys = '<C-w>gg' },

    { mode = 'n', keys = 'g~', desc = 'Switch case' },
    { mode = 'n', keys = 'gU', desc = 'Make uppercase' },
    { mode = 'n', keys = 'gu', desc = 'Make lowercase' },
    { mode = 'n', keys = 'g?', desc = 'Rot13 encode' },

    { mode = 'i', keys = '<C-x><C-l>', desc = 'MINE Complete line' },
    { mode = 'i', keys = '<C-x><C-f>', desc = 'MINE Complete file path' },

    { mode = 'c', keys = '<C-r><C-w>', desc = 'Word under cursor' },
    { mode = 'c', keys = '<C-r>=', desc = 'Expression register' },

    { mode = 'x', keys = 'iw', desc = 'Word' },
    { mode = 'x', keys = 'if', desc = 'Function call' },
    { mode = 'o', keys = 'iw', desc = 'Word' },
    { mode = 'o', keys = 'iw', desc = 'Function call' },

    { mode = 'x', keys = 'aw', desc = 'Word' },
    { mode = 'x', keys = 'af', desc = 'Function call' },
    { mode = 'o', keys = 'aw', desc = 'Word' },
    { mode = 'o', keys = 'aw', desc = 'Function call' },
  },

  triggers = {
    { mode = 'n', keys = '<Leader>' },
    { mode = 'x', keys = '<Leader>' },

    { mode = 'n', keys = '[' },
    { mode = 'n', keys = ']' },
    { mode = 'n', keys = [[\]] },

    { mode = 'o', keys = '`' },

    { mode = 'i', keys = '<C-x>' },

    { mode = 'c', keys = '<C-r>' },

    { mode = 't', keys = '<C-w>' },
    { mode = 't', keys = '<Space>' },

    { mode = 'n', keys = 's' },
    { mode = 'x', keys = 's' },

    { mode = 'n', keys = 'g' },
    { mode = 'x', keys = 'g' },
    { mode = 'n', keys = '<C-w>' },

    { mode = 'x', keys = '[' },
    { mode = 'o', keys = '[' },
    { mode = 'x', keys = ']' },
    { mode = 'o', keys = ']' },

    { mode = 'x', keys = 'a' },
    { mode = 'o', keys = 'a' },
    { mode = 'x', keys = 'i' },
    { mode = 'o', keys = 'i' },
  },

  window = {
    delay = 0,
    config = {
      width = 'auto',
    },
  },
})

require('mini.statusline').setup({
  content = {
    active = function()
      -- stylua: ignore start
      local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
      local spell         = vim.wo.spell and (MiniStatusline.is_truncated(120) and 'S' or 'SPELL') or ''
      local wrap          = vim.wo.wrap  and (MiniStatusline.is_truncated(120) and 'W' or 'WRAP')  or ''
      local git           = MiniStatusline.section_git({ trunc_width = 75 })
      -- Default diagnstics icon has some problems displaying in Kitty terminal
      local diagnostics   = MiniStatusline.section_diagnostics({ trunc_width = 75 })
      local filename      = MiniStatusline.section_filename({ trunc_width = 140 })
      local fileinfo      = MiniStatusline.section_fileinfo({ trunc_width = 120 })
      local searchcount   = MiniStatusline.section_searchcount({ trunc_width = 75})
      local location      = MiniStatusline.section_location({ trunc_width = 75 })

      -- Usage of `MiniStatusline.combine_groups()` ensures highlighting and
      -- correct padding with spaces between groups (accounts for 'missing'
      -- sections, etc.)
      return MiniStatusline.combine_groups({
        { hl = mode_hl,                  strings = { mode, spell, wrap } },
        { hl = 'MiniStatuslineDevinfo',  strings = { git, diagnostics } },
        '%<', -- Mark general truncate point
        { hl = 'MiniStatuslineFilename', strings = { filename } },
        '%=', -- End left alignment
        { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
        { hl = mode_hl,                  strings = { searchcount, location } },
      })
      -- stylua: ignore end
    end,
  },
})

require('mini.tabline').setup()

vim.schedule(function()
  local ai = require('mini.ai')
  ai.setup({
    custom_textobjects = {
      F = ai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }),
    },
  })

  require('mini.align').setup()

  require('mini.animate').setup()

  require('mini.basics').setup({
    options = {
      -- Manage options manually
      basic = false,
    },
    mappings = {
      windows = true,
      move_with_alt = true,
    },
    autocommands = {
      relnum_in_visual_mode = true,
    },
  })

  require('mini.bracketed').setup()

  require('mini.bufremove').setup()

  -- Don't really need it on daily basis
  -- require('mini.colors').setup()

  require('mini.comment').setup()

  require('mini.completion').setup({
    lsp_completion = {
      source_func = 'omnifunc',
      auto_setup = false,
      process_items = function(items, base)
        -- Don't show 'Text' and 'Snippet' suggestions
        items = vim.tbl_filter(function(x) return x.kind ~= 1 and x.kind ~= 15 end, items)
        return MiniCompletion.default_process_items(items, base)
      end,
    },
    window = {
      info = { border = 'double' },
      signature = { border = 'double' },
    },
  })

  require('mini.cursorword').setup()

  require('mini.doc').setup()

  local hipatterns = require('mini.hipatterns')
  hipatterns.setup({
    highlighters = {
      fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
      hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
      todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
      note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },

      hex_color = hipatterns.gen_highlighter.hex_color(),
    },
  })

  require('mini.indentscope').setup()

  require('mini.jump').setup()

  require('mini.jump2d').setup({
    view = {
      dim = true,
    },
  })

  local map = require('mini.map')
  local gen_integr = map.gen_integration
  local encode_symbols = map.gen_encode_symbols.block('3x2')
  -- Use dots in `st` terminal because it can render them as blocks
  if vim.startswith(vim.fn.getenv('TERM'), 'st') then encode_symbols = map.gen_encode_symbols.dot('4x2') end
  map.setup({
    symbols = { encode = encode_symbols },
    integrations = { gen_integr.builtin_search(), gen_integr.gitsigns(), gen_integr.diagnostic() },
  })
  for _, key in ipairs({ 'n', 'N', '*' }) do
    vim.keymap.set('n', key, key .. 'zv<Cmd>lua MiniMap.refresh({}, { lines = false, scrollbar = false })<CR>')
  end

  require('mini.misc').setup({ make_global = { 'put', 'put_text', 'stat_summary', 'bench_time' } })
  MiniMisc.setup_auto_root()

  require('mini.move').setup({ options = { reindent_linewise = false } })

  require('mini.pairs').setup({ modes = { insert = true, command = true, terminal = true } })
  vim.keymap.set('i', '<CR>', 'v:lua.EC.cr_action()', { expr = true })

  require('mini.splitjoin').setup()

  require('mini.surround').setup({ search_method = 'cover_or_next' })

  local test = require('mini.test')
  local reporter = test.gen_reporter.buffer({ window = { border = 'double' } })
  test.setup({
    execute = { reporter = reporter },
  })

  require('mini.trailspace').setup()
end)
