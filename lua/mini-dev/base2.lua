-- TODO:
--
-- - Recheck correctness of hue generation.

--- *mini.base2* Generate color scheme based on background and foreground
--- *MiniBase2*
---
--- MIT License Copyright (c) 2023 Evgeni Chasnovski
---
--- ==============================================================================
---
--- Requires Neovim>=0.8.
---
--- Supported highlight groups:
--- - Builtin-in Neovim LSP and diagnostic.
---
--- - Plugins (either with explicit definition or by verification that default
---   highlighting works appropriately):
---     - 'echasnovski/mini.nvim'
---     - 'akinsho/bufferline.nvim'
---     - 'anuvyklack/hydra.nvim'
---     - 'DanilaMihailov/beacon.nvim'
---     - 'folke/todo-comments.nvim'
---     - 'folke/trouble.nvim'
---     - 'folke/which-key.nvim'
---     - 'ggandor/leap.nvim'
---     - 'glepnir/dashboard-nvim'
---     - 'glepnir/lspsaga.nvim'
---     - 'hrsh7th/nvim-cmp'
---     - 'justinmk/vim-sneak'
---     - 'nvim-tree/nvim-tree.lua'
---     - 'lewis6991/gitsigns.nvim'
---     - 'lukas-reineke/indent-blankline.nvim'
---     - 'neoclide/coc.nvim'
---     - 'nvim-lualine/lualine.nvim'
---     - 'nvim-neo-tree/neo-tree.nvim'
---     - 'nvim-telescope/telescope.nvim'
---     - 'p00f/nvim-ts-rainbow'
---     - 'phaazon/hop.nvim'
---     - 'rcarriga/nvim-dap-ui'
---     - 'rcarriga/nvim-notify'
---     - 'rlane/pounce.nvim'
---     - 'romgrk/barbar.nvim'
---     - 'simrat39/symbols-outline.nvim'
---     - 'stevearc/aerial.nvim'
---     - 'TimUntersberger/neogit'
---     - 'williamboman/mason.nvim'
---
--- # Setup~
---
--- This module needs a setup with `require('mini.base2').setup({})` (replace
--- `{}` with your `config` table). It will create global Lua table
--- `MiniBase2` which you can use for scripting or manually (with
--- `:lua MiniBase2.*`).
---
--- See |MiniBase2.config| for `config` structure and default values.
---
--- This module doesn't have runtime options, so using `vim.b.minibase2_config`
--- will have no effect here.
---
--- Example:
--- >
---   require('mini.base2').setup({
---     background = '#0a2a2a',
---     foreground = '#d0d0d0',
---     plugins = {
---       default = false,
---       ['echasnovski/mini.nvim'] = true,
---     },
---   })
--- <
--- # Notes~
---
--- - Using `setup()` doesn't actually create a |colorscheme|. It basically
---   creates a coordinated set of |highlight|s. To create your own theme:
---     - Put "myscheme.lua" file (name after your chosen theme name) inside
---       any "colors" directory reachable from 'runtimepath' ("colors" inside
---       your Neovim config directory is usually enough).
---     - Inside "myscheme.lua" call `require('mini.base2').setup()` with your
---       palette and only after that set |g:colors_name| to "myscheme".

---@diagnostic disable:undefined-field
---@diagnostic disable:discard-returns
---@diagnostic disable:unused-local

-- Module definition ==========================================================
-- TODO: make local before public release
MiniBase2 = {}
H = {}

--- Module setup
---
---
---@usage `require('mini.colors').setup({})` (replace `{}` with your `config` table)
MiniBase2.setup = function(config)
  -- Export module
  _G.MiniBase2 = MiniBase2

  -- Setup config
  config = H.setup_config(config)

  -- Apply config
  H.apply_config(config)
end

--- Module config
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
MiniBase2.config = {
  background = nil,
  foreground = nil,

  -- Saturation level. One of 'low', 'medium', 'high'.
  saturation = 'medium',

  -- Accent color.
  -- One of 'red', 'yellow', 'green', 'cyan', 'blue', 'magenta', 'gray'.
  accent = 'gray',

  -- Plugin integrations. Use `default = false` to disable all integrations.
  -- Also can be set per plugin (see |MiniBase16.config|).
  plugins = { default = true },
}
--minidoc_afterlines_end

MiniBase2.make_palette = function(opts)
  opts = vim.tbl_deep_extend('force', MiniBase2.config, opts or {})
  local bg = H.validate_hex(opts.background)
  local fg = H.validate_hex(opts.foreground)
  local saturation = H.validate_one_of(opts.saturation, { 'low', 'medium', 'high' }, 'saturation')
  local accent =
    H.validate_one_of(opts.accent, { 'red', 'yellow', 'green', 'cyan', 'blue', 'magenta', 'gray' }, 'accent')

  local bg_lch, fg_lch = H.hex2oklch(bg), H.hex2oklch(fg)
  local bg_l, fg_l = bg_lch.l, fg_lch.l
  if not ((bg_l <= 50 and 50 < fg_l) or (fg_l <= 50 and 50 < bg_l)) then
    H.error('`background` and `foreground` should have opposite lightness.')
  end

  -- Basic lightness levels
  local is_dark = bg_l <= 50
  local bg_l_edge = is_dark and 0 or 100
  local fg_l_edge = is_dark and 100 or 0

  -- Hues. Correct them to be distant from both bg and fg hues.
  local bg_h, fg_h = bg_lch.h, fg_lch.h
  local d
  if bg_h == nil and fg_h == nil then d = 0 end
  if bg_h ~= nil and fg_h == nil then d = ((bg_h - 30) % 60 + 30) % 60 end
  if bg_h == nil and fg_h ~= nil then d = ((fg_h - 30) % 60 + 30) % 60 end
  if bg_h ~= nil and fg_h ~= nil then
    -- Subtract 30 because reference grid starts at 30 (red)
    local ref_bg, ref_fg = (bg_h - 30) % 60, (fg_h - 30) % 60
    -- Pick the point most distant from both on a circle with period 60
    local mid = 0.5 * (ref_bg + ref_fg)
    local mid_alt = (mid + 30) % 60

    d = H.dist_circle(mid, ref_bg) < H.dist_circle(mid_alt, ref_bg) and mid_alt or mid
  end

  local hues = { red = 30 + d, yellow = 90 + d, green = 150 + d, cyan = 210 + d, blue = 270 + d, magenta = 330 + d }

  -- Configurable chroma level
  local chroma = ({ low = 5, medium = 10, high = 15 })[saturation]

  -- Compute result
  local golden_point = function(x, y) return 0.618 * x + 0.382 * y end

  --stylua: ignore
  return {
    bg_edge    = H.oklch2hex({ l = golden_point(bg_l_edge, bg_l), c = bg_lch.c, h = bg_lch.h }),
    bg         = bg,
    bg_center  = H.oklch2hex({ l = golden_point(50, bg_l),        c = bg_lch.c, h = bg_lch.h }),

    fg_edge    = H.oklch2hex({ l = golden_point(fg_l_edge, fg_l), c = fg_lch.c, h = fg_lch.h }),
    fg         = fg,
    fg_center  = H.oklch2hex({ l = golden_point(50, fg_l),        c = fg_lch.c, h = fg_lch.h }),

    gray       = H.oklch2hex({ l = fg_l, c = 0 }),
    gray_bg    = H.oklch2hex({ l = bg_l, c = 0 }),

    red        = H.oklch2hex({ l = fg_l, c = chroma, h = hues.red }),
    red_bg     = H.oklch2hex({ l = bg_l, c = chroma, h = hues.red }),

    yellow     = H.oklch2hex({ l = fg_l, c = chroma, h = hues.yellow }),
    yellow_bg  = H.oklch2hex({ l = bg_l, c = chroma, h = hues.yellow }),

    green      = H.oklch2hex({ l = fg_l, c = chroma, h = hues.green }),
    green_bg   = H.oklch2hex({ l = bg_l, c = chroma, h = hues.green }),

    cyan       = H.oklch2hex({ l = fg_l, c = chroma, h = hues.cyan }),
    cyan_bg    = H.oklch2hex({ l = bg_l, c = chroma, h = hues.cyan }),

    blue       = H.oklch2hex({ l = fg_l, c = chroma, h = hues.blue }),
    blue_bg    = H.oklch2hex({ l = bg_l, c = chroma, h = hues.blue }),

    magenta    = H.oklch2hex({ l = fg_l, c = chroma, h = hues.magenta }),
    magenta_bg = H.oklch2hex({ l = bg_l, c = chroma, h = hues.magenta }),

    accent     = H.oklch2hex({ l = fg_l, c = chroma, h = hues[accent] }),
    accent_bg  = H.oklch2hex({ l = bg_l, c = chroma, h = hues[accent] }),
  }
end

-- Helper data ================================================================
-- Module default config
H.default_config = MiniBase2.config

-- Color conversion constants
H.tau = 2 * math.pi

-- Cusps for Oklch color space. See 'mini.colors' for more details.
--stylua: ignore start
---@diagnostic disable
---@private
H.cusps = {
  [0] = {26.23,64.74},
  {26.14,64.65},{26.06,64.56},{25.98,64.48},{25.91,64.39},{25.82,64.29},{25.76,64.21},{25.70,64.13},{25.65,64.06},
  {25.59,63.97},{25.55,63.90},{25.52,63.83},{25.48,63.77},{25.45,63.69},{25.43,63.63},{25.41,63.55},{25.40,63.50},
  {25.39,63.43},{25.40,63.33},{25.40,63.27},{25.42,63.22},{25.44,63.15},{25.46,63.11},{25.50,63.05},{25.53,63.00},
  {25.58,62.95},{25.63,62.90},{25.69,62.85},{25.75,62.81},{25.77,62.80},{25.34,63.25},{24.84,63.79},{24.37,64.32},
  {23.92,64.83},{23.48,65.35},{23.08,65.85},{22.65,66.38},{22.28,66.86},{21.98,67.27},{21.67,67.70},{21.36,68.14},
  {21.05,68.60},{20.74,69.08},{20.50,69.45},{20.27,69.83},{20.04,70.22},{19.82,70.62},{19.60,71.03},{19.38,71.44},
  {19.17,71.87},{19.03,72.16},{18.83,72.59},{18.71,72.89},{18.52,73.34},{18.40,73.64},{18.28,73.95},{18.17,74.26},
  {18.01,74.74},{17.91,75.05},{17.82,75.38},{17.72,75.70},{17.64,76.03},{17.56,76.36},{17.48,76.69},{17.41,77.03},
  {17.35,77.36},{17.29,77.71},{17.24,78.05},{17.19,78.39},{17.15,78.74},{17.12,79.09},{17.09,79.45},{17.07,79.80},
  {17.05,80.16},{17.04,80.52},{17.04,81.06},{17.04,81.42},{17.05,81.79},{17.07,82.16},{17.08,82.53},{17.11,82.72},
  {17.14,83.09},{17.18,83.46},{17.22,83.84},{17.27,84.22},{17.33,84.60},{17.39,84.98},{17.48,85.56},{17.56,85.94},
  {17.64,86.33},{17.73,86.72},{17.81,87.10},{17.91,87.50},{18.04,88.09},{18.16,88.48},{18.27,88.88},{18.40,89.48},
  {18.57,89.87},{18.69,90.27},{18.88,90.87},{19.03,91.48},{19.22,91.88},{19.44,92.49},{19.66,93.10},{19.85,93.71},
  {20.04,94.33},{20.33,94.94},{20.60,95.56},{20.85,96.18},{21.10,96.80},{21.19,96.48},{21.27,96.24},{21.38,95.93},
  {21.47,95.70},{21.59,95.40},{21.72,95.10},{21.86,94.80},{21.97,94.58},{22.12,94.30},{22.27,94.02},{22.43,93.74},
  {22.64,93.40},{22.81,93.14},{23.04,92.81},{23.22,92.56},{23.45,92.25},{23.68,91.95},{23.92,91.65},{24.21,91.31},
  {24.45,91.04},{24.74,90.72},{25.08,90.36},{25.37,90.07},{25.70,89.74},{26.08,89.39},{26.44,89.07},{26.87,88.69},
  {27.27,88.34},{27.72,87.98},{28.19,87.61},{28.68,87.23},{29.21,86.84},{29.48,86.64},{28.99,86.70},{28.13,86.81},
  {27.28,86.92},{26.56,87.02},{25.83,87.12},{25.18,87.22},{24.57,87.32},{24.01,87.41},{23.53,87.49},{23.03,87.58},
  {22.53,87.68},{22.10,87.76},{21.68,87.84},{21.26,87.93},{20.92,88.01},{20.58,88.08},{20.25,88.16},{19.92,88.24},
  {19.59,88.33},{19.35,88.39},{19.12,88.46},{18.81,88.55},{18.58,88.61},{18.36,88.68},{18.14,88.76},{17.93,88.83},
  {17.79,88.88},{17.59,88.95},{17.39,89.03},{17.26,89.08},{17.08,89.16},{16.96,89.21},{16.79,89.29},{16.68,89.35},
  {16.58,89.41},{16.43,89.49},{16.33,89.55},{16.24,89.60},{16.16,89.66},{16.04,89.75},{15.96,89.81},{15.89,89.87},
  {15.83,89.93},{15.77,89.99},{15.71,90.05},{15.66,90.12},{15.61,90.18},{15.57,90.24},{15.54,90.31},{15.51,90.37},
  {15.48,90.44},{15.46,90.51},{15.40,90.30},{15.30,89.83},{15.21,89.36},{15.12,88.89},{15.03,88.67},{14.99,88.18},
  {14.92,87.71},{14.85,87.24},{14.78,86.77},{14.75,86.53},{14.70,86.06},{14.65,85.59},{14.61,85.12},{14.60,84.89},
  {14.57,84.42},{14.54,83.94},{14.53,83.71},{14.52,83.24},{14.51,82.77},{14.52,82.30},{14.52,81.83},{14.53,81.60},
  {14.55,81.13},{14.58,80.66},{14.59,80.43},{14.63,79.96},{14.68,79.49},{14.70,79.26},{14.76,78.79},{14.82,78.32},
  {14.85,78.09},{14.93,77.62},{15.01,77.16},{15.10,76.69},{15.19,76.23},{15.24,76.00},{15.34,75.54},{15.45,75.07},
  {15.57,74.61},{15.69,74.15},{15.82,73.69},{15.96,73.23},{16.10,72.77},{16.24,72.31},{16.39,71.86},{16.55,71.40},
  {16.71,70.95},{16.96,70.26},{17.14,69.81},{17.32,69.36},{17.59,68.69},{17.88,68.02},{18.07,67.57},{18.37,66.90},
  {18.67,66.24},{18.99,65.58},{19.30,64.93},{19.74,64.06},{20.07,63.42},{20.51,62.57},{20.97,61.73},{21.54,60.69},
  {22.00,59.87},{22.70,58.66},{23.39,57.49},{24.19,56.16},{25.20,54.52},{26.38,52.66},{28.55,49.32},{31.32,45.20},
  {31.15,45.42},{30.99,45.64},{30.85,45.85},{30.72,46.06},{30.57,46.31},{30.47,46.50},{30.34,46.75},{30.23,46.97},
  {30.13,47.20},{30.03,47.45},{29.93,47.71},{29.86,47.91},{29.77,48.20},{29.71,48.43},{29.65,48.66},{29.58,48.98},
  {29.53,49.23},{29.48,49.48},{29.44,49.74},{29.41,50.01},{29.37,50.29},{29.35,50.57},{29.33,50.86},{29.31,51.16},
  {29.30,51.56},{29.29,51.87},{29.29,52.39},{29.30,52.72},{29.31,53.05},{29.33,53.38},{29.35,53.72},{29.37,54.06},
  {29.40,54.41},{29.43,54.76},{29.47,55.12},{29.52,55.60},{29.56,55.97},{29.61,56.34},{29.66,56.72},{29.73,57.22},
  {29.79,57.61},{29.84,57.99},{29.93,58.52},{29.99,58.91},{30.08,59.44},{30.15,59.84},{30.24,60.38},{30.34,60.93},
  {30.42,61.34},{30.52,61.90},{30.63,62.45},{30.73,63.02},{30.85,63.58},{30.96,64.15},{31.08,64.72},{31.19,65.30},
  {31.31,65.88},{31.44,66.46},{31.59,67.20},{31.72,67.79},{31.88,68.53},{32.01,69.12},{32.18,69.87},{32.25,70.17},
  {32.06,69.99},{31.76,69.70},{31.45,69.42},{31.21,69.20},{30.97,68.98},{30.68,68.71},{30.44,68.50},{30.21,68.29},
  {29.98,68.09},{29.75,67.89},{29.53,67.69},{29.31,67.50},{29.09,67.31},{28.88,67.12},{28.72,66.98},{28.52,66.80},
  {28.31,66.63},{28.16,66.50},{27.97,66.33},{27.78,66.17},{27.64,66.05},{27.49,65.94},{27.33,65.77},{27.20,65.66},
  {27.04,65.51},{26.92,65.40},{26.81,65.30},{26.66,65.16},{26.55,65.06},{26.45,64.96},{26.35,64.87},
}
--stylua: ignore end

-- Helper functionality =======================================================
-- Settings -------------------------------------------------------------------
H.setup_config = function(config)
  -- General idea: if some table elements are not present in user-supplied
  -- `config`, take them from default config
  vim.validate({ config = { config, 'table', true } })
  config = vim.tbl_deep_extend('force', H.default_config, config or {})

  vim.validate({
    background = { config.background, H.is_hex },
    foreground = { config.foreground, H.is_hex },
    plugins = { config.plugins, 'table' },
  })

  return config
end

H.apply_config = function(config)
  MiniBase16.config = config

  H.apply_colorscheme(config)
end

-- Palette --------------------------------------------------------------------
H.validate_hex = function(x, name)
  if type(x) == 'string' and x:find('^#%x%x%x%x%x%x$') ~= nil then return x end
  local msg = string.format('`%s` should be hex color string in the form "#rrggbb", not %s.', name, vim.inspect(x))
  H.error(msg)
end

H.validate_one_of = function(x, choices, name)
  if vim.tbl_contains(choices, x) then return x end
  local choices_string = table.concat(vim.tbl_map(vim.inspect, choices), ', ')
  local msg = string.format('`%s` should be one of ', name, choices_string)
  H.error(msg)
end

-- Highlighting ---------------------------------------------------------------
---@diagnostic disable
---@private
-- stylua: ignore
H.apply_colorscheme = function(config)
  -- Prepare highlighting application. Notes:
  -- - Clear current highlight only if other theme was loaded previously.
  -- - No need to `syntax reset` because *all* syntax groups are defined later.
  if vim.g.colors_name then vim.cmd('highlight clear') end

  -- As this doesn't create colorscheme, don't store any name. Not doing it
  -- might cause some issues with `syntax on`.
  vim.g.colors_name = nil

  local p = H.make_palette(config)
  local hi = function(name, data) vim.api.nvim_set_hl(0, name, data) end
  local has_integration = function(name)
    local entry = config.plugins[name]
    if entry == nil then return config.plugins.default end
    return entry
  end

  local has_integration = function(name)
    local entry = config.plugins[name]
    if entry == nil then return config.plugins.default end
    return entry
  end

  -- NOTE: recommendations for adding new highlight groups:
  -- - Put all related groups (like for new plugin) in single paragraph.
  -- - Sort within group alphabetically (by hl-group name) ignoring case.
  -- - Link all repeated groups within paragraph (lowers execution time).
  -- - Align by commas.

  -- Builtin highlighting groups
  hi('ColorColumn',    {fg=nil,      bg=p.base01, attr=nil,         sp=nil})
  hi('Conceal',        {fg=p.base0D, bg=p.base00, attr=nil,         sp=nil})
  hi('CurSearch',      {fg=p.base01, bg=p.base09, attr=nil,         sp=nil})
  hi('Cursor',         {fg=p.base00, bg=p.base05, attr=nil,         sp=nil})
  hi('CursorColumn',   {fg=nil,      bg=p.base01, attr=nil,         sp=nil})
  hi('CursorIM',       {fg=p.base00, bg=p.base05, attr=nil,         sp=nil})
  hi('CursorLine',     {fg=nil,      bg=p.base01, attr=nil,         sp=nil})
  hi('CursorLineFold', {fg=p.base0C, bg=p.base01, attr=nil,         sp=nil})
  hi('CursorLineNr',   {fg=p.base04, bg=p.base01, attr=nil,         sp=nil})
  hi('CursorLineSign', {fg=p.base03, bg=p.base01, attr=nil,         sp=nil})
  hi('DiffAdd',        {fg=p.base0B, bg=p.base01, attr=nil,         sp=nil})
  hi('DiffChange',     {fg=p.base0E, bg=p.base01, attr=nil,         sp=nil})
  hi('DiffDelete',     {fg=p.base08, bg=p.base01, attr=nil,         sp=nil})
  hi('DiffText',       {fg=p.base0D, bg=p.base01, attr=nil,         sp=nil})
  hi('Directory',      {fg=p.base0D, bg=nil,      attr=nil,         sp=nil})
  hi('EndOfBuffer',    {fg=p.base03, bg=nil,      attr=nil,         sp=nil})
  hi('ErrorMsg',       {fg=p.base08, bg=p.base00, attr=nil,         sp=nil})
  hi('FoldColumn',     {fg=p.base0C, bg=p.base01, attr=nil,         sp=nil})
  hi('Folded',         {fg=p.base03, bg=p.base01, attr=nil,         sp=nil})
  hi('IncSearch',      {fg=p.base01, bg=p.base09, attr=nil,         sp=nil})
  hi('lCursor',        {fg=p.base00, bg=p.base05, attr=nil,         sp=nil})
  hi('LineNr',         {fg=p.base03, bg=p.base01, attr=nil,         sp=nil})
  hi('LineNrAbove',    {fg=p.base03, bg=p.base01, attr=nil,         sp=nil})
  hi('LineNrBelow',    {fg=p.base03, bg=p.base01, attr=nil,         sp=nil})
  hi('MatchParen',     {fg=nil,      bg=p.base02, attr=nil,         sp=nil})
  hi('ModeMsg',        {fg=p.base0B, bg=nil,      attr=nil,         sp=nil})
  hi('MoreMsg',        {fg=p.base0B, bg=nil,      attr=nil,         sp=nil})
  hi('MsgArea',        {fg=p.base05, bg=p.base00, attr=nil,         sp=nil})
  hi('MsgSeparator',   {fg=p.base04, bg=p.base02, attr=nil,         sp=nil})
  hi('NonText',        {fg=p.base03, bg=nil,      attr=nil,         sp=nil})
  hi('Normal',         {fg=p.base05, bg=p.base00, attr=nil,         sp=nil})
  hi('NormalFloat',    {fg=p.base05, bg=p.base01, attr=nil,         sp=nil})
  hi('NormalNC',       {fg=p.base05, bg=p.base00, attr=nil,         sp=nil})
  hi('PMenu',          {fg=p.base05, bg=p.base01, attr=nil,         sp=nil})
  hi('PMenuSbar',      {fg=nil,      bg=p.base02, attr=nil,         sp=nil})
  hi('PMenuSel',       {fg=p.base01, bg=p.base05, attr=nil,         sp=nil})
  hi('PMenuThumb',     {fg=nil,      bg=p.base07, attr=nil,         sp=nil})
  hi('Question',       {fg=p.base0D, bg=nil,      attr=nil,         sp=nil})
  hi('QuickFixLine',   {fg=nil,      bg=p.base01, attr=nil,         sp=nil})
  hi('Search',         {fg=p.base01, bg=p.base0A, attr=nil,         sp=nil})
  hi('SignColumn',     {fg=p.base03, bg=p.base01, attr=nil,         sp=nil})
  hi('SpecialKey',     {fg=p.base03, bg=nil,      attr=nil,         sp=nil})
  hi('SpellBad',       {fg=nil,      bg=nil,      attr='undercurl', sp=p.base08})
  hi('SpellCap',       {fg=nil,      bg=nil,      attr='undercurl', sp=p.base0D})
  hi('SpellLocal',     {fg=nil,      bg=nil,      attr='undercurl', sp=p.base0C})
  hi('SpellRare',      {fg=nil,      bg=nil,      attr='undercurl', sp=p.base0E})
  hi('StatusLine',     {fg=p.base04, bg=p.base02, attr=nil,         sp=nil})
  hi('StatusLineNC',   {fg=p.base03, bg=p.base01, attr=nil,         sp=nil})
  hi('Substitute',     {fg=p.base01, bg=p.base0A, attr=nil,         sp=nil})
  hi('TabLine',        {fg=p.base03, bg=p.base01, attr=nil,         sp=nil})
  hi('TabLineFill',    {fg=p.base03, bg=p.base01, attr=nil,         sp=nil})
  hi('TabLineSel',     {fg=p.base0B, bg=p.base01, attr=nil,         sp=nil})
  hi('TermCursor',     {fg=nil,      bg=nil,      attr='reverse',   sp=nil})
  hi('TermCursorNC',   {fg=nil,      bg=nil,      attr='reverse',   sp=nil})
  hi('Title',          {fg=p.base0D, bg=nil,      attr=nil,         sp=nil})
  hi('VertSplit',      {fg=p.base02, bg=p.base02, attr=nil,         sp=nil})
  hi('Visual',         {fg=nil,      bg=p.base02, attr=nil,         sp=nil})
  hi('VisualNOS',      {fg=p.base08, bg=nil,      attr=nil,         sp=nil})
  hi('WarningMsg',     {fg=p.base08, bg=nil,      attr=nil,         sp=nil})
  hi('Whitespace',     {fg=p.base03, bg=nil,      attr=nil,         sp=nil})
  hi('WildMenu',       {fg=p.base08, bg=p.base0A, attr=nil,         sp=nil})
  hi('WinBar',         {fg=p.base04, bg=p.base02, attr=nil,         sp=nil})
  hi('WinBarNC',       {fg=p.base03, bg=p.base01, attr=nil,         sp=nil})
  hi('WinSeparator',   {fg=p.base02, bg=p.base02, attr=nil,         sp=nil})

  -- Standard syntax (affects treesitter)
  hi('Boolean',        {fg=p.base09, bg=nil,      attr=nil, sp=nil})
  hi('Character',      {fg=p.base08, bg=nil,      attr=nil, sp=nil})
  hi('Comment',        {fg=p.base03, bg=nil,      attr=nil, sp=nil})
  hi('Conditional',    {fg=p.base0E, bg=nil,      attr=nil, sp=nil})
  hi('Constant',       {fg=p.base09, bg=nil,      attr=nil, sp=nil})
  hi('Debug',          {fg=p.base08, bg=nil,      attr=nil, sp=nil})
  hi('Define',         {fg=p.base0E, bg=nil,      attr=nil, sp=nil})
  hi('Delimiter',      {fg=p.base0F, bg=nil,      attr=nil, sp=nil})
  hi('Error',          {fg=p.base00, bg=p.base08, attr=nil, sp=nil})
  hi('Exception',      {fg=p.base08, bg=nil,      attr=nil, sp=nil})
  hi('Float',          {fg=p.base09, bg=nil,      attr=nil, sp=nil})
  hi('Function',       {fg=p.base0D, bg=nil,      attr=nil, sp=nil})
  hi('Identifier',     {fg=p.base08, bg=nil,      attr=nil, sp=nil})
  hi('Ignore',         {fg=p.base0C, bg=nil,      attr=nil, sp=nil})
  hi('Include',        {fg=p.base0D, bg=nil,      attr=nil, sp=nil})
  hi('Keyword',        {fg=p.base0E, bg=nil,      attr=nil, sp=nil})
  hi('Label',          {fg=p.base0A, bg=nil,      attr=nil, sp=nil})
  hi('Macro',          {fg=p.base08, bg=nil,      attr=nil, sp=nil})
  hi('Number',         {fg=p.base09, bg=nil,      attr=nil, sp=nil})
  hi('Operator',       {fg=p.base05, bg=nil,      attr=nil, sp=nil})
  hi('PreCondit',      {fg=p.base0A, bg=nil,      attr=nil, sp=nil})
  hi('PreProc',        {fg=p.base0A, bg=nil,      attr=nil, sp=nil})
  hi('Repeat',         {fg=p.base0A, bg=nil,      attr=nil, sp=nil})
  hi('Special',        {fg=p.base0C, bg=nil,      attr=nil, sp=nil})
  hi('SpecialChar',    {fg=p.base0F, bg=nil,      attr=nil, sp=nil})
  hi('SpecialComment', {fg=p.base0C, bg=nil,      attr=nil, sp=nil})
  hi('Statement',      {fg=p.base08, bg=nil,      attr=nil, sp=nil})
  hi('StorageClass',   {fg=p.base0A, bg=nil,      attr=nil, sp=nil})
  hi('String',         {fg=p.base0B, bg=nil,      attr=nil, sp=nil})
  hi('Structure',      {fg=p.base0E, bg=nil,      attr=nil, sp=nil})
  hi('Tag',            {fg=p.base0A, bg=nil,      attr=nil, sp=nil})
  hi('Todo',           {fg=p.base0A, bg=p.base01, attr=nil, sp=nil})
  hi('Type',           {fg=p.base0A, bg=nil,      attr=nil, sp=nil})
  hi('Typedef',        {fg=p.base0A, bg=nil,      attr=nil, sp=nil})

  -- Other community standard
  hi('Bold',       {fg=nil,      bg=nil, attr='bold',      sp=nil})
  hi('Italic',     {fg=nil,      bg=nil, attr='italic',    sp=nil})
  hi('TooLong',    {fg=p.base08, bg=nil, attr=nil,         sp=nil})
  hi('Underlined', {fg=nil,      bg=nil, attr='underline', sp=nil})

  -- Git diff
  hi('DiffAdded',   {fg=p.base0B, bg=p.base00, attr=nil, sp=nil})
  hi('DiffFile',    {fg=p.base08, bg=p.base00, attr=nil, sp=nil})
  hi('DiffLine',    {fg=p.base0D, bg=p.base00, attr=nil, sp=nil})
  hi('DiffNewFile', {link='DiffAdded'})
  hi('DiffRemoved', {link='DiffFile'})

  -- Git commit
  hi('gitcommitBranch',        {fg=p.base09, bg=nil, attr='bold', sp=nil})
  hi('gitcommitComment',       {link='Comment'})
  hi('gitcommitDiscarded',     {link='Comment'})
  hi('gitcommitDiscardedFile', {fg=p.base08, bg=nil, attr='bold', sp=nil})
  hi('gitcommitDiscardedType', {fg=p.base0D, bg=nil, attr=nil,    sp=nil})
  hi('gitcommitHeader',        {fg=p.base0E, bg=nil, attr=nil,    sp=nil})
  hi('gitcommitOverflow',      {fg=p.base08, bg=nil, attr=nil,    sp=nil})
  hi('gitcommitSelected',      {link='Comment'})
  hi('gitcommitSelectedFile',  {fg=p.base0B, bg=nil, attr='bold', sp=nil})
  hi('gitcommitSelectedType',  {link='gitcommitDiscardedType'})
  hi('gitcommitSummary',       {fg=p.base0B, bg=nil, attr=nil,    sp=nil})
  hi('gitcommitUnmergedFile',  {link='gitcommitDiscardedFile'})
  hi('gitcommitUnmergedType',  {link='gitcommitDiscardedType'})
  hi('gitcommitUntracked',     {link='Comment'})
  hi('gitcommitUntrackedFile', {fg=p.base0A, bg=nil, attr=nil,    sp=nil})

  -- Built-in diagnostic
  hi('DiagnosticError', {fg=p.base08, bg=nil, attr=nil, sp=nil})
  hi('DiagnosticHint',  {fg=p.base0D, bg=nil, attr=nil, sp=nil})
  hi('DiagnosticInfo',  {fg=p.base0C, bg=nil, attr=nil, sp=nil})
  hi('DiagnosticWarn',  {fg=p.base0E, bg=nil, attr=nil, sp=nil})

  hi('DiagnosticFloatingError', {fg=p.base08, bg=p.base01, attr=nil, sp=nil})
  hi('DiagnosticFloatingHint',  {fg=p.base0D, bg=p.base01, attr=nil, sp=nil})
  hi('DiagnosticFloatingInfo',  {fg=p.base0C, bg=p.base01, attr=nil, sp=nil})
  hi('DiagnosticFloatingWarn',  {fg=p.base0E, bg=p.base01, attr=nil, sp=nil})

  hi('DiagnosticSignError', {link='DiagnosticFloatingError'})
  hi('DiagnosticSignHint',  {link='DiagnosticFloatingHint'})
  hi('DiagnosticSignInfo',  {link='DiagnosticFloatingInfo'})
  hi('DiagnosticSignWarn',  {link='DiagnosticFloatingWarn'})

  hi('DiagnosticUnderlineError', {fg=nil, bg=nil, attr='underline', sp=p.base08})
  hi('DiagnosticUnderlineHint',  {fg=nil, bg=nil, attr='underline', sp=p.base0D})
  hi('DiagnosticUnderlineInfo',  {fg=nil, bg=nil, attr='underline', sp=p.base0C})
  hi('DiagnosticUnderlineWarn',  {fg=nil, bg=nil, attr='underline', sp=p.base0E})

  -- Built-in LSP
  hi('LspReferenceText',  {fg=nil, bg=p.base02, attr=nil, sp=nil})
  hi('LspReferenceRead',  {link='LspReferenceText'})
  hi('LspReferenceWrite', {link='LspReferenceText'})

  hi('LspSignatureActiveParameter', {link='LspReferenceText'})

  hi('LspCodeLens',          {link='Comment'})
  hi('LspCodeLensSeparator', {link='Comment'})

  -- Plugins
  -- echasnovski/mini.nvim
  if has_integration('echasnovski/mini.nvim') then
    hi('MiniAnimateCursor', {fg=nil, bg=nil, attr='reverse,nocombine', sp=nil})

    hi('MiniCompletionActiveParameter', {fg=nil, bg=p.base02, attr=nil, sp=nil})

    hi('MiniCursorword',        {fg=nil, bg=nil, attr='underline', sp=nil})
    hi('MiniCursorwordCurrent', {fg=nil, bg=nil, attr='underline', sp=nil})

    hi('MiniIndentscopeSymbol',    {fg=p.base0F, bg=nil, attr=nil, sp=nil})
    hi('MiniIndentscopeSymbolOff', {fg=p.base08, bg=nil, attr=nil, sp=nil})

    hi('MiniJump', {link='SpellRare'})

    hi('MiniJump2dDim',        {link='Comment'})
    hi('MiniJump2dSpot',       {fg=p.base07, bg=p.base01, attr='bold,nocombine', sp=nil})
    hi('MiniJump2dSpotAhead',  {fg=p.base06, bg=p.base00, attr='nocombine',      sp=nil})
    hi('MiniJump2dSpotUnique', {link='MiniJump2dSpot'})

    hi('MiniMapNormal',      {fg=p.base05, bg=p.base01, attr=nil, sp=nil})
    hi('MiniMapSymbolCount', {fg=p.base0C, bg=nil,      attr=nil, sp=nil})
    hi('MiniMapSymbolLine',  {fg=p.base0D, bg=nil,      attr=nil, sp=nil})
    hi('MiniMapSymbolView',  {fg=p.base0F, bg=nil,      attr=nil, sp=nil})

    hi('MiniStarterCurrent',    {fg=nil,      bg=nil, attr=nil,    sp=nil})
    hi('MiniStarterFooter',     {fg=p.base0D, bg=nil, attr=nil,    sp=nil})
    hi('MiniStarterHeader',     {fg=p.base0D, bg=nil, attr=nil,    sp=nil})
    hi('MiniStarterInactive',   {link='Comment'})
    hi('MiniStarterItem',       {fg=p.base05, bg=nil, attr=nil,    sp=nil})
    hi('MiniStarterItemBullet', {fg=p.base0F, bg=nil, attr=nil,    sp=nil})
    hi('MiniStarterItemPrefix', {fg=p.base08, bg=nil, attr='bold', sp=nil})
    hi('MiniStarterSection',    {fg=p.base0F, bg=nil, attr=nil,    sp=nil})
    hi('MiniStarterQuery',      {fg=p.base0B, bg=nil, attr='bold', sp=nil})

    hi('MiniStatuslineDevinfo',     {fg=p.base04, bg=p.base02, attr=nil,    sp=nil})
    hi('MiniStatuslineFileinfo',    {link='MiniStatuslineDevinfo'})
    hi('MiniStatuslineFilename',    {fg=p.base03, bg=p.base01, attr=nil,    sp=nil})
    hi('MiniStatuslineInactive',    {link='MiniStatuslineFilename'})
    hi('MiniStatuslineModeCommand', {fg=p.base00, bg=p.base08, attr='bold', sp=nil})
    hi('MiniStatuslineModeInsert',  {fg=p.base00, bg=p.base0D, attr='bold', sp=nil})
    hi('MiniStatuslineModeNormal',  {fg=p.base00, bg=p.base05, attr='bold', sp=nil})
    hi('MiniStatuslineModeOther',   {fg=p.base00, bg=p.base03, attr='bold', sp=nil})
    hi('MiniStatuslineModeReplace', {fg=p.base00, bg=p.base0E, attr='bold', sp=nil})
    hi('MiniStatuslineModeVisual',  {fg=p.base00, bg=p.base0B, attr='bold', sp=nil})

    hi('MiniSurround', {link='IncSearch'})

    hi('MiniTablineCurrent',         {fg=p.base05, bg=p.base02, attr='bold', sp=nil})
    hi('MiniTablineFill',            {fg=nil,      bg=nil,      attr=nil,    sp=nil})
    hi('MiniTablineHidden',          {fg=p.base04, bg=p.base01, attr=nil,    sp=nil})
    hi('MiniTablineModifiedCurrent', {fg=p.base02, bg=p.base05, attr='bold', sp=nil})
    hi('MiniTablineModifiedHidden',  {fg=p.base01, bg=p.base04, attr=nil,    sp=nil})
    hi('MiniTablineModifiedVisible', {fg=p.base02, bg=p.base04, attr='bold', sp=nil})
    hi('MiniTablineTabpagesection',  {fg=p.base01, bg=p.base0A, attr='bold', sp=nil})
    hi('MiniTablineVisible',         {fg=p.base05, bg=p.base01, attr='bold', sp=nil})

    hi('MiniTestEmphasis', {fg=nil,      bg=nil, attr='bold', sp=nil})
    hi('MiniTestFail',     {fg=p.base08, bg=nil, attr='bold', sp=nil})
    hi('MiniTestPass',     {fg=p.base0B, bg=nil, attr='bold', sp=nil})

    hi('MiniTrailspace', {link='Error'})
  end

  if has_integration('akinsho/bufferline.nvim') then
    hi('BufferLineBuffer',              {fg=p.base04, bg=nil,      attr=nil,    sp=nil})
    hi('BufferLineBufferSelected',      {fg=p.base05, bg=nil,      attr='bold', sp=nil})
    hi('BufferLineBufferVisible',       {fg=p.base05, bg=nil,      attr=nil,    sp=nil})
    hi('BufferLineCloseButton',         {link='BufferLineBackground'})
    hi('BufferLineCloseButtonSelected', {link='BufferLineBufferSelected'})
    hi('BufferLineCloseButtonVisible',  {link='BufferLineBufferVisible'})
    hi('BufferLineFill',                {link='Normal'})
    hi('BufferLineTab',                 {fg=p.base00, bg=p.base0A, attr=nil,    sp=nil})
    hi('BufferLineTabSelected',         {fg=p.base00, bg=p.base0A, attr='bold', sp=nil})
  end

  if has_integration('anuvyklack/hydra.nvim') then
    hi('HydraRed',      {fg=p.base08, bg=nil, attr=nil, sp=nil})
    hi('HydraBlue',     {fg=p.base0D, bg=nil, attr=nil, sp=nil})
    hi('HydraAmaranth', {fg=p.base0E, bg=nil, attr=nil, sp=nil})
    hi('HydraTeal',     {fg=p.base0B, bg=nil, attr=nil, sp=nil})
    hi('HydraPink',     {fg=p.base09, bg=nil, attr=nil, sp=nil})
    hi('HydraHint',     {link='NormalFloat'})
  end

  if has_integration('DanilaMihailov/beacon.nvim') then
    hi('Beacon', {fg=nil, bg=p.base07, attr=nil, sp=nil})
  end

  -- folke/trouble.nvim
  -- Everything works correctly out of the box

  -- folke/todo-comments.nvim
  -- Everything works correctly out of the box

  if has_integration('folke/which-key.nvim') then
    hi('WhichKey',          {fg=p.base0D, bg=nil,      attr=nil, sp=nil})
    hi('WhichKeyDesc',      {fg=p.base05, bg=nil,      attr=nil, sp=nil})
    hi('WhichKeyFloat',     {fg=p.base05, bg=p.base01, attr=nil, sp=nil})
    hi('WhichKeyGroup',     {fg=p.base0E, bg=nil,      attr=nil, sp=nil})
    hi('WhichKeySeparator', {fg=p.base0B, bg=p.base01, attr=nil, sp=nil})
    hi('WhichKeyValue',     {fg=p.base03, bg=nil,      attr=nil, sp=nil})
  end

  if has_integration('ggandor/leap.nvim') then
    hi('LeapMatch',          {fg=p.base0E, bg=nil, attr='bold,nocombine', sp=nil})
    hi('LeapLabelPrimary',   {fg=p.base08, bg=nil, attr='bold,nocombine', sp=nil})
    hi('LeapLabelSecondary', {fg=p.base05, bg=nil, attr='bold,nocombine', sp=nil})
    hi('LeapLabelSelected',  {fg=p.base09, bg=nil, attr='bold,nocombine', sp=nil})
    hi('LeapBackdrop',       {link='Comment'})
  end

  if has_integration('glepnir/dashboard-nvim') then
    hi('DashboardCenter',   {link='Delimiter'})
    hi('DashboardFooter',   {link='Title'})
    hi('DashboardHeader',   {link='Title'})
    hi('DashboardShortCut', {link='WarningMsg'})
  end

  if has_integration('glepnir/lspsaga.nvim') then
    hi('LspSagaCodeActionBorder',  {fg=p.base0F, bg=nil, attr=nil,    sp=nil})
    hi('LspSagaCodeActionContent', {fg=p.base05, bg=nil, attr=nil,    sp=nil})
    hi('LspSagaCodeActionTitle',   {fg=p.base0D, bg=nil, attr='bold', sp=nil})

    hi('Definitions',            {fg=p.base0B, bg=nil, attr=nil, sp=nil})
    hi('DefinitionsIcon',        {fg=p.base0D, bg=nil, attr=nil, sp=nil})
    hi('FinderParam',            {fg=p.base08, bg=nil, attr=nil, sp=nil})
    hi('FinderVirtText',         {fg=p.base09, bg=nil, attr=nil, sp=nil})
    hi('LspSagaAutoPreview',     {fg=p.base0F, bg=nil, attr=nil, sp=nil})
    hi('LspSagaFinderSelection', {fg=p.base0A, bg=nil, attr=nil, sp=nil})
    hi('LspSagaLspFinderBorder', {fg=p.base0F, bg=nil, attr=nil, sp=nil})
    hi('References',             {fg=p.base0B, bg=nil, attr=nil, sp=nil})
    hi('ReferencesIcon',         {fg=p.base0D, bg=nil, attr=nil, sp=nil})
    hi('TargetFileName',         {fg=p.base05, bg=nil, attr=nil, sp=nil})

    hi('FinderSpinner',       {fg=p.base0B, bg=nil, attr=nil, sp=nil})
    hi('FinderSpinnerBorder', {fg=p.base0F, bg=nil, attr=nil, sp=nil})
    hi('FinderSpinnerTitle',  {link='Title'})

    hi('LspSagaDefPreviewBorder', {fg=p.base0F, bg=nil, attr=nil, sp=nil})

    hi('LspSagaHoverBorder', {fg=p.base0F, bg=nil, attr=nil, sp=nil})

    hi('LspSagaRenameBorder', {fg=p.base0F, bg=nil, attr=nil, sp=nil})

    hi('LspSagaDiagnosticBorder', {fg=p.base0F, bg=nil, attr=nil, sp=nil})
    hi('LspSagaDiagnosticHeader', {link='Title'})
    hi('LspSagaDiagnosticSource', {fg=p.base0E, bg=nil, attr=nil, sp=nil})

    hi('LspSagaBorderTitle', {link='Title'})

    hi('LspSagaSignatureHelpBorder', {fg=p.base0F, bg=nil, attr=nil, sp=nil})

    hi('LSOutlinePreviewBorder', {fg=p.base0F, bg=nil, attr=nil, sp=nil})
    hi('OutlineDetail',          {fg=p.base03, bg=nil, attr=nil, sp=nil})
    hi('OutlineFoldPrefix',      {fg=p.base08, bg=nil, attr=nil, sp=nil})
    hi('OutlineIndentEvn',       {fg=p.base04, bg=nil, attr=nil, sp=nil})
    hi('OutlineIndentOdd',       {fg=p.base05, bg=nil, attr=nil, sp=nil})
  end

  if has_integration('hrsh7th/nvim-cmp') then
    hi('CmpItemAbbr',           {fg=p.base05, bg=nil,      attr=nil,    sp=nil})
    hi('CmpItemAbbrDeprecated', {fg=p.base03, bg=nil,      attr=nil,    sp=nil})
    hi('CmpItemAbbrMatch',      {fg=p.base0A, bg=nil,      attr='bold', sp=nil})
    hi('CmpItemAbbrMatchFuzzy', {fg=p.base0A, bg=nil,      attr='bold', sp=nil})
    hi('CmpItemKind',           {fg=p.base0F, bg=p.base01, attr=nil,    sp=nil})
    hi('CmpItemMenu',           {fg=p.base05, bg=p.base01, attr=nil,    sp=nil})

    hi('CmpItemKindClass',         {link='Type'})
    hi('CmpItemKindColor',         {link='Special'})
    hi('CmpItemKindConstant',      {link='Constant'})
    hi('CmpItemKindConstructor',   {link='Type'})
    hi('CmpItemKindEnum',          {link='Structure'})
    hi('CmpItemKindEnumMember',    {link='Structure'})
    hi('CmpItemKindEvent',         {link='Exception'})
    hi('CmpItemKindField',         {link='Structure'})
    hi('CmpItemKindFile',          {link='Tag'})
    hi('CmpItemKindFolder',        {link='Directory'})
    hi('CmpItemKindFunction',      {link='Function'})
    hi('CmpItemKindInterface',     {link='Structure'})
    hi('CmpItemKindKeyword',       {link='Keyword'})
    hi('CmpItemKindMethod',        {link='Function'})
    hi('CmpItemKindModule',        {link='Structure'})
    hi('CmpItemKindOperator',      {link='Operator'})
    hi('CmpItemKindProperty',      {link='Structure'})
    hi('CmpItemKindReference',     {link='Tag'})
    hi('CmpItemKindSnippet',       {link='Special'})
    hi('CmpItemKindStruct',        {link='Structure'})
    hi('CmpItemKindText',          {link='Statement'})
    hi('CmpItemKindTypeParameter', {link='Type'})
    hi('CmpItemKindUnit',          {link='Special'})
    hi('CmpItemKindValue',         {link='Identifier'})
    hi('CmpItemKindVariable',      {link='Delimiter'})
  end

  if has_integration('justinmk/vim-sneak') then
    hi('Sneak',      {fg=p.base00, bg=p.base0E, attr=nil,    sp=nil})
    hi('SneakScope', {fg=p.base00, bg=p.base07, attr=nil,    sp=nil})
    hi('SneakLabel', {fg=p.base00, bg=p.base0E, attr='bold', sp=nil})
  end

  if has_integration('nvim-tree/nvim-tree.lua') then
    hi('NvimTreeExecFile',     {fg=p.base0B, bg=nil,      attr='bold',           sp=nil})
    hi('NvimTreeFolderIcon',   {fg=p.base03, bg=nil,      attr=nil,              sp=nil})
    hi('NvimTreeGitDeleted',   {fg=p.base08, bg=nil,      attr=nil,              sp=nil})
    hi('NvimTreeGitDirty',     {fg=p.base08, bg=nil,      attr=nil,              sp=nil})
    hi('NvimTreeGitMerge',     {fg=p.base0C, bg=nil,      attr=nil,              sp=nil})
    hi('NvimTreeGitNew',       {fg=p.base0A, bg=nil,      attr=nil,              sp=nil})
    hi('NvimTreeGitRenamed',   {fg=p.base0E, bg=nil,      attr=nil,              sp=nil})
    hi('NvimTreeGitStaged',    {fg=p.base0B, bg=nil,      attr=nil,              sp=nil})
    hi('NvimTreeImageFile',    {fg=p.base0E, bg=nil,      attr='bold',           sp=nil})
    hi('NvimTreeIndentMarker', {link='NvimTreeFolderIcon'})
    hi('NvimTreeOpenedFile',   {link='NvimTreeExecFile'})
    hi('NvimTreeRootFolder',   {link='NvimTreeGitRenamed'})
    hi('NvimTreeSpecialFile',  {fg=p.base0D, bg=nil,      attr='bold,underline', sp=nil})
    hi('NvimTreeSymlink',      {fg=p.base0F, bg=nil,      attr='bold',           sp=nil})
    hi('NvimTreeWindowPicker', {fg=p.base05, bg=p.base01, attr="bold",           sp=nil})
  end

  if has_integration('lewis6991/gitsigns.nvim') then
    hi('GitSignsAdd',          {fg=p.base0B, bg=p.base01, attr=nil, sp=nil})
    hi('GitSignsAddLn',        {link='GitSignsAdd'})
    hi('GitSignsAddInline',    {link='GitSignsAdd'})
    hi('GitSignsChange',       {fg=p.base0E, bg=p.base01, attr=nil, sp=nil})
    hi('GitSignsChangeLn',     {link='GitSignsChange'})
    hi('GitSignsChangeInline', {link='GitSignsChange'})
    hi('GitSignsDelete',       {fg=p.base08, bg=p.base01, attr=nil, sp=nil})
    hi('GitSignsDeleteLn',     {link='GitSignsDelete'})
    hi('GitSignsDeleteInline', {link='GitSignsDelete'})
  end

  if has_integration('lukas-reineke/indent-blankline.nvim') then
    hi('IndentBlanklineChar',         {fg=p.base02, bg=nil, attr='nocombine',           sp=nil})
    hi('IndentBlanklineContextChar',  {fg=p.base0F, bg=nil, attr='nocombine',           sp=nil})
    hi('IndentBlanklineContextStart', {fg=nil,      bg=nil, attr='underline,nocombine', sp=p.base0F})
    hi('IndentBlanklineIndent1',      {fg=p.base08, bg=nil, attr='nocombine',           sp=nil})
    hi('IndentBlanklineIndent2',      {fg=p.base09, bg=nil, attr='nocombine',           sp=nil})
    hi('IndentBlanklineIndent3',      {fg=p.base0A, bg=nil, attr='nocombine',           sp=nil})
    hi('IndentBlanklineIndent4',      {fg=p.base0B, bg=nil, attr='nocombine',           sp=nil})
    hi('IndentBlanklineIndent5',      {fg=p.base0C, bg=nil, attr='nocombine',           sp=nil})
    hi('IndentBlanklineIndent6',      {fg=p.base0D, bg=nil, attr='nocombine',           sp=nil})
    hi('IndentBlanklineIndent7',      {fg=p.base0E, bg=nil, attr='nocombine',           sp=nil})
    hi('IndentBlanklineIndent8',      {fg=p.base0F, bg=nil, attr='nocombine',           sp=nil})
  end

  if has_integration('neoclide/coc.nvim') then
    hi('CocErrorHighlight',   {link='DiagnosticError'})
    hi('CocHintHighlight',    {link='DiagnosticHint'})
    hi('CocInfoHighlight',    {link='DiagnosticInfo'})
    hi('CocWarningHighlight', {link='DiagnosticWarn'})

    hi('CocErrorFloat',   {link='DiagnosticFloatingError'})
    hi('CocHintFloat',    {link='DiagnosticFloatingHint'})
    hi('CocInfoFloat',    {link='DiagnosticFloatingInfo'})
    hi('CocWarningFloat', {link='DiagnosticFloatingWarn'})

    hi('CocErrorSign',   {link='DiagnosticSignError'})
    hi('CocHintSign',    {link='DiagnosticSignHint'})
    hi('CocInfoSign',    {link='DiagnosticSignInfo'})
    hi('CocWarningSign', {link='DiagnosticSignWarn'})

    hi('CocCodeLens',             {link='LspCodeLens'})
    hi('CocDisabled',             {link='Comment'})
    hi('CocMarkdownLink',         {fg=p.base0F, bg=nil,      attr=nil, sp=nil})
    hi('CocMenuSel',              {fg=nil,      bg=p.base02, attr=nil, sp=nil})
    hi('CocNotificationProgress', {link='CocMarkdownLink'})
    hi('CocPumVirtualText',       {link='CocMarkdownLink'})
    hi('CocSearch',               {fg=p.base0A, bg=nil,      attr=nil, sp=nil})
    hi('CocSelectedText',         {fg=p.base08, bg=nil,      attr=nil, sp=nil})
  end

  -- nvim-lualine/lualine.nvim
  -- Everything works correctly out of the box

  if has_integration('nvim-neo-tree/neo-tree.nvim') then
    hi('NeoTreeDimText',              {fg=p.base03, bg=nil,      attr=nil,    sp=nil})
    hi('NeoTreeDotfile',              {fg=p.base04, bg=nil,      attr=nil,    sp=nil})
    hi('NeoTreeFadeText1',            {link='NeoTreeDimText'})
    hi('NeoTreeFadeText2',            {fg=p.base02, bg=nil,      attr=nil,    sp=nil})
    hi('NeoTreeGitAdded',             {fg=p.base0B, bg=nil,      attr=nil,    sp=nil})
    hi('NeoTreeGitConflict',          {fg=p.base08, bg=nil,      attr='bold', sp=nil})
    hi('NeoTreeGitDeleted',           {fg=p.base08, bg=nil,      attr=nil,    sp=nil})
    hi('NeoTreeGitModified',          {fg=p.base0E, bg=nil,      attr=nil,    sp=nil})
    hi('NeoTreeGitUnstaged',          {fg=p.base08, bg=nil,      attr=nil,    sp=nil})
    hi('NeoTreeGitUntracked',         {fg=p.base0A, bg=nil,      attr=nil,    sp=nil})
    hi('NeoTreeMessage',              {fg=p.base05, bg=p.base01, attr=nil,    sp=nil})
    hi('NeoTreeModified',             {fg=p.base07, bg=nil,      attr=nil,    sp=nil})
    hi('NeoTreeRootName',             {fg=p.base0D, bg=nil,      attr='bold', sp=nil})
    hi('NeoTreeTabInactive',          {fg=p.base04, bg=nil,      attr=nil,    sp=nil})
    hi('NeoTreeTabSeparatorActive',   {fg=p.base03, bg=p.base02, attr=nil,    sp=nil})
    hi('NeoTreeTabSeparatorInactive', {fg=p.base01, bg=p.base01, attr=nil,    sp=nil})
  end

  if has_integration('nvim-telescope/telescope.nvim') then
    hi('TelescopeBorder',         {fg=p.base0F, bg=nil,      attr=nil,    sp=nil})
    hi('TelescopeMatching',       {fg=p.base0A, bg=nil,      attr=nil,    sp=nil})
    hi('TelescopeMultiSelection', {fg=nil,      bg=p.base01, attr='bold', sp=nil})
    hi('TelescopeSelection',      {fg=nil,      bg=p.base01, attr='bold', sp=nil})
  end

  if has_integration('p00f/nvim-ts-rainbow') then
    hi('rainbowcol1', {fg=p.base08, bg=nil, attr=nil, sp=nil})
    hi('rainbowcol2', {fg=p.base09, bg=nil, attr=nil, sp=nil})
    hi('rainbowcol3', {fg=p.base0A, bg=nil, attr=nil, sp=nil})
    hi('rainbowcol4', {fg=p.base0B, bg=nil, attr=nil, sp=nil})
    hi('rainbowcol5', {fg=p.base0C, bg=nil, attr=nil, sp=nil})
    hi('rainbowcol6', {fg=p.base0D, bg=nil, attr=nil, sp=nil})
    hi('rainbowcol7', {fg=p.base0E, bg=nil, attr=nil, sp=nil})
  end

  if has_integration('phaazon/hop.nvim') then
    hi('HopNextKey',   {fg=p.base0E, bg=nil, attr='bold,nocombine', sp=nil})
    hi('HopNextKey1',  {fg=p.base08, bg=nil, attr='bold,nocombine', sp=nil})
    hi('HopNextKey2',  {fg=p.base04, bg=nil, attr='bold,nocombine', sp=nil})
    hi('HopPreview',   {fg=p.base09, bg=nil, attr='bold,nocombine', sp=nil})
    hi('HopUnmatched', {link='Comment'})
  end

  if has_integration('rcarriga/nvim-dap-ui') then
    hi('DapUIScope',                   {link='Title'})
    hi('DapUIType',                    {link='Type'})
    hi('DapUIModifiedValue',           {fg=p.base0E, bg=nil, attr='bold', sp=nil})
    hi('DapUIDecoration',              {link='Title'})
    hi('DapUIThread',                  {link='String'})
    hi('DapUIStoppedThread',           {link='Title'})
    hi('DapUISource',                  {link='Directory'})
    hi('DapUILineNumber',              {link='Title'})
    hi('DapUIFloatBorder',             {link='SpecialChar'})
    hi('DapUIWatchesEmpty',            {link='ErrorMsg'})
    hi('DapUIWatchesValue',            {link='String'})
    hi('DapUIWatchesError',            {link='DiagnosticError'})
    hi('DapUIBreakpointsPath',         {link='Directory'})
    hi('DapUIBreakpointsInfo',         {link='DiagnosticInfo'})
    hi('DapUIBreakpointsCurrentLine',  {fg=p.base0B, bg=nil, attr='bold', sp=nil})
    hi('DapUIBreakpointsDisabledLine', {link='Comment'})
  end

  if has_integration('rcarriga/nvim-notify') then
    hi('NotifyDEBUGBorder', {fg=p.base03, bg=nil, attr=nil, sp=nil})
    hi('NotifyDEBUGIcon',   {link='NotifyDEBUGBorder'})
    hi('NotifyDEBUGTitle',  {link='NotifyDEBUGBorder'})
    hi('NotifyERRORBorder', {fg=p.base08, bg=nil, attr=nil, sp=nil})
    hi('NotifyERRORIcon',   {link='NotifyERRORBorder'})
    hi('NotifyERRORTitle',  {link='NotifyERRORBorder'})
    hi('NotifyINFOBorder',  {fg=p.base0C, bg=nil, attr=nil, sp=nil})
    hi('NotifyINFOIcon',    {link='NotifyINFOBorder'})
    hi('NotifyINFOTitle',   {link='NotifyINFOBorder'})
    hi('NotifyTRACEBorder', {fg=p.base0D, bg=nil, attr=nil, sp=nil})
    hi('NotifyTRACEIcon',   {link='NotifyTRACEBorder'})
    hi('NotifyTRACETitle',  {link='NotifyTRACEBorder'})
    hi('NotifyWARNBorder',  {fg=p.base0E, bg=nil, attr=nil, sp=nil})
    hi('NotifyWARNIcon',    {link='NotifyWARNBorder'})
    hi('NotifyWARNTitle',   {link='NotifyWARNBorder'})
  end

  if has_integration('rlane/pounce.nvim') then
    hi('PounceMatch',      {fg=p.base00, bg=p.base05, attr='bold,nocombine', sp=nil})
    hi('PounceGap',        {fg=p.base00, bg=p.base03, attr='bold,nocombine', sp=nil})
    hi('PounceAccept',     {fg=p.base00, bg=p.base08, attr='bold,nocombine', sp=nil})
    hi('PounceAcceptBest', {fg=p.base00, bg=p.base0B, attr='bold,nocombine', sp=nil})
  end

  if has_integration('romgrk/barbar.nvim') then
    hi('BufferCurrent',       {fg=p.base05, bg=p.base02, attr='bold', sp=nil})
    hi('BufferCurrentIcon',   {fg=nil,      bg=p.base02, attr=nil,    sp=nil})
    hi('BufferCurrentIndex',  {link='BufferCurrentIcon'})
    hi('BufferCurrentMod',    {fg=p.base08, bg=p.base02, attr='bold', sp=nil})
    hi('BufferCurrentSign',   {link='BufferCurrent'})
    hi('BufferCurrentTarget', {fg=p.base0E, bg=p.base02, attr='bold', sp=nil})

    hi('BufferInactive',       {fg=p.base04, bg=p.base01, attr=nil,    sp=nil})
    hi('BufferInactiveIcon',   {fg=nil,      bg=p.base01, attr=nil,    sp=nil})
    hi('BufferInactiveIndex',  {link='BufferInactiveIcon'})
    hi('BufferInactiveMod',    {fg=p.base08, bg=p.base01, attr=nil,    sp=nil})
    hi('BufferInactiveSign',   {link='BufferInactive'})
    hi('BufferInactiveTarget', {fg=p.base0E, bg=p.base01, attr='bold', sp=nil})

    hi('BufferOffset',      {link='Normal'})
    hi('BufferTabpages',    {fg=p.base01, bg=p.base0A, attr='bold', sp=nil})
    hi('BufferTabpageFill', {link='Normal'})

    hi('BufferVisible',       {fg=p.base05, bg=p.base01, attr='bold', sp=nil})
    hi('BufferVisibleIcon',   {fg=nil,      bg=p.base01, attr=nil,    sp=nil})
    hi('BufferVisibleIndex',  {link='BufferVisibleIcon'})
    hi('BufferVisibleMod',    {fg=p.base08, bg=p.base01, attr='bold', sp=nil})
    hi('BufferVisibleSign',   {link='BufferVisible'})
    hi('BufferVisibleTarget', {fg=p.base0E, bg=p.base01, attr='bold', sp=nil})
  end

  -- simrat39/symbols-outline.nvim
  -- Everything works correctly out of the box

  -- stevearc/aerial.nvim
  -- Everything works correctly out of the box

  -- TimUntersberger/neogit
  -- Everything works correctly out of the box

  if has_integration('williamboman/mason.nvim') then
    hi('MasonError',                       {fg=p.base08, bg=nil,      attr=nil,    sp=nil})
    hi('MasonHeader',                      {fg=p.base00, bg=p.base0D, attr='bold', sp=nil})
    hi('MasonHeaderSecondary',             {fg=p.base00, bg=p.base0F, attr='bold', sp=nil})
    hi('MasonHeading',                     {link='Bold'})
    hi('MasonHighlight',                   {fg=p.base0F, bg=nil,      attr=nil,    sp=nil})
    hi('MasonHighlightBlock',              {fg=p.base00, bg=p.base0F, attr=nil,    sp=nil})
    hi('MasonHighlightBlockBold',          {link='MasonHeaderSecondary'})
    hi('MasonHighlightBlockBoldSecondary', {link='MasonHeader'})
    hi('MasonHighlightBlockSecondary',     {fg=p.base00, bg=p.base0D, attr=nil,    sp=nil})
    hi('MasonHighlightSecondary',          {fg=p.base0D, bg=nil,      attr=nil,    sp=nil})
    hi('MasonLink',                        {link='MasonHighlight'})
    hi('MasonMuted',                       {link='Comment'})
    hi('MasonMutedBlock',                  {fg=p.base00, bg=p.base03, attr=nil,    sp=nil})
    hi('MasonMutedBlockBold',              {fg=p.base00, bg=p.base03, attr='bold', sp=nil})
  end

  -- Terminal colors
  vim.g.terminal_color_0  = palette.bg
  vim.g.terminal_color_1  = palette.red
  vim.g.terminal_color_2  = palette.green
  vim.g.terminal_color_3  = palette.yellow
  vim.g.terminal_color_4  = palette.blue
  vim.g.terminal_color_5  = palette.magenta
  vim.g.terminal_color_6  = palette.cyan
  vim.g.terminal_color_7  = palette.fg
  vim.g.terminal_color_8  = palette.bg
  vim.g.terminal_color_9  = palette.red
  vim.g.terminal_color_10 = palette.green
  vim.g.terminal_color_11 = palette.yellow
  vim.g.terminal_color_12 = palette.blue
  vim.g.terminal_color_13 = palette.magenta
  vim.g.terminal_color_14 = palette.cyan
  vim.g.terminal_color_15 = palette.fg
end

-- Color conversion -----------------------------------------------------------
H.hex2oklch = function(hex) return H.oklab2oklch(H.rgb2oklab(H.hex2rgb(hex))) end

H.oklch2hex = function(lch) return H.rgb2hex(H.oklab2rgb(H.oklch2oklab(H.clip_to_gamut(lch)))) end

-- HEX <-> RGB in [0; 255]
H.hex2rgb = function(hex)
  local dec = tonumber(hex:sub(2), 16)

  local b = math.fmod(dec, 256)
  local g = math.fmod((dec - b) / 256, 256)
  local r = math.floor(dec / 65536)

  return { r = r, g = g, b = b }
end

H.rgb2hex = function(rgb)
  -- Use straightforward clipping to [0; 255] here to ensure correctness.
  -- Modify `rgb` prior to this to ensure only a small distortion.
  local r = H.clip(H.round(rgb.r), 0, 255)
  local g = H.clip(H.round(rgb.g), 0, 255)
  local b = H.clip(H.round(rgb.b), 0, 255)

  return string.format('#%02x%02x%02x', r, g, b)
end

-- RGB in [0; 255] <-> Oklab
-- https://bottosson.github.io/posts/oklab/#converting-from-linear-srgb-to-oklab
H.rgb2oklab = function(rgb)
  -- Convert to linear RGB
  local r, g, b = H.correct_channel(rgb.r / 255), H.correct_channel(rgb.g / 255), H.correct_channel(rgb.b / 255)

  -- Convert to Oklab
  local l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
  local m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
  local s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

  local l_, m_, s_ = H.cuberoot(l), H.cuberoot(m), H.cuberoot(s)

  local L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
  local A = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
  local B = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_

  -- Explicitly convert to gray for nearly achromatic colors
  if math.abs(A) < 1e-4 then A = 0 end
  if math.abs(B) < 1e-4 then B = 0 end

  -- Normalize to appropriate range
  return { l = H.correct_lightness(100 * L), a = 100 * A, b = 100 * B }
end

H.oklab2rgb = function(lab)
  local L, A, B = 0.01 * H.correct_lightness_inv(lab.l), 0.01 * lab.a, 0.01 * lab.b

  local l_ = L + 0.3963377774 * A + 0.2158037573 * B
  local m_ = L - 0.1055613458 * A - 0.0638541728 * B
  local s_ = L - 0.0894841775 * A - 1.2914855480 * B

  local l = l_ * l_ * l_
  local m = m_ * m_ * m_
  local s = s_ * s_ * s_

  --stylua: ignore
  local r =  4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
  local g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
  local b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

  return { r = 255 * H.correct_channel_inv(r), g = 255 * H.correct_channel_inv(g), b = 255 * H.correct_channel_inv(b) }
end

-- Oklab <-> Oklch
H.oklab2oklch = function(lab)
  local c = math.sqrt(lab.a ^ 2 + lab.b ^ 2)
  -- Treat grays specially
  local h = nil
  if c > 0 then h = H.rad2degree(math.atan2(lab.b, lab.a)) end
  return { l = lab.l, c = c, h = h }
end

H.oklch2oklab = function(lch)
  -- Treat grays specially
  if lch.c <= 0 or lch.h == nil then return { l = lch.l, a = 0, b = 0 } end

  local a = lch.c * math.cos(H.degree2rad(lch.h))
  local b = lch.c * math.sin(H.degree2rad(lch.h))
  return { l = lch.l, a = a, b = b }
end

-- Degree in [0; 360] <-> Radian in [0; 2*pi]
H.rad2degree = function(x) return (x % H.tau) * 360 / H.tau end

H.degree2rad = function(x) return (x % 360) * H.tau / 360 end

-- Functions for RGB channel correction. Assumes input in [0; 1] range
-- https://bottosson.github.io/posts/colorwrong/#what-can-we-do%3F
H.correct_channel = function(x) return 0.04045 < x and math.pow((x + 0.055) / 1.055, 2.4) or (x / 12.92) end

H.correct_channel_inv =
  function(x) return (0.0031308 >= x) and (12.92 * x) or (1.055 * math.pow(x, 0.416666667) - 0.055) end

-- Functions for lightness correction
-- https://bottosson.github.io/posts/colorpicker/#intermission---a-new-lightness-estimate-for-oklab
H.correct_lightness = function(x)
  x = 0.01 * x
  local k1, k2 = 0.206, 0.03
  local k3 = (1 + k1) / (1 + k2)

  local res = 0.5 * (k3 * x - k1 + math.sqrt((k3 * x - k1) ^ 2 + 4 * k2 * k3 * x))
  return 100 * res
end

H.correct_lightness_inv = function(x)
  x = 0.01 * x
  local k1, k2 = 0.206, 0.03
  local k3 = (1 + k1) / (1 + k2)
  local res = (x / k3) * (x + k1) / (x + k2)
  return 100 * res
end

-- Get gamut ranges for Lch point. More info in 'mini.colors'.
H.get_gamut_points = function(lch)
  local c, l = lch.c, H.clip(lch.l, 0, 100)
  l = H.correct_lightness_inv(l)
  local cusp = H.cusps[math.floor(lch.h % 360)]
  local c_cusp, l_cusp = cusp[1], cusp[2]

  -- Maximum allowed chroma. Used for computing saturation.
  local c_upper = l <= l_cusp and (c_cusp * l / l_cusp) or (c_cusp * (100 - l) / (100 - l_cusp))
  c_upper = H.clip(c_upper, 0, math.huge)

  -- Other points can be computed only in presence of actual chroma
  if c == nil then return { c_upper = c_upper } end

  -- Intersection of segment between (c, l) and (0, l_cusp) with gamut boundary
  -- Used for gamut clipping
  local c_cusp_clip, l_cusp_clip
  if c <= 0 then
    c_cusp_clip, l_cusp_clip = c, l
  elseif l <= l_cusp then
    -- Intersection with lower segment
    local prop = 1 - l / l_cusp
    c_cusp_clip = c_cusp * c / (c_cusp * prop + c)
    l_cusp_clip = l_cusp * c_cusp_clip / c_cusp
  else
    -- Intersection with upper segment
    local prop = 1 - (l - 100) / (l_cusp - 100)
    c_cusp_clip = c_cusp * c / (c_cusp * prop + c)
    l_cusp_clip = 100 + c_cusp_clip * (l_cusp - 100) / c_cusp
  end

  return {
    c_upper = c_upper,
    l_cusp_clip = H.correct_lightness(l_cusp_clip),
    c_cusp_clip = c_cusp_clip,
  }
end

H.clip_to_gamut = function(lch)
  local res = vim.deepcopy(lch)

  -- Gray is always in gamut
  if res.h == nil then return res end

  local gamut_points = H.get_gamut_points(lch)

  local is_inside_gamut = lch.c <= gamut_points.c_upper
  if is_inside_gamut then return res end

  -- Clip by going towards (0, l_cusp) until in gamut
  res.l, res.c = gamut_points.l_cusp_clip, gamut_points.c_cusp_clip

  return res
end

-- ============================================================================
-- Utilities ------------------------------------------------------------------
H.error = function(msg) error(string.format('(mini.base2) %s', msg), 0) end

H.round = function(x)
  if x == nil then return nil end
  return math.floor(x + 0.5)
end

H.clip = function(x, from, to) return math.min(math.max(x, from), to) end

H.cuberoot = function(x) return math.pow(x, 0.333333) end

H.dist_circle = function(x, y)
  local d = math.abs((x % 360) - (y % 360))
  return math.min(d, 360 - d)
end

return MiniBase2
