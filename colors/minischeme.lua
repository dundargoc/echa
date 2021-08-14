-- 'Minischeme' color scheme
-- Derived from base16 (https://github.com/chriskempson/base16) and mini16
-- palette generator
local palette

-- Dark palette is an output of 'MiniBase16.mini_palette' with background
-- '#1f242e' (HSL = 220-20-15) and foreground '#e1f28c' (HSL = 70-80-75)
if vim.o.background == 'dark' then
  palette = {
    base00 = '#1f242e',
    base01 = '#3a4355',
    base02 = '#54627d',
    base03 = '#7382a0',
    base04 = '#d3ec57',
    base05 = '#e1f28c',
    base06 = '#eff8c1',
    base07 = '#fdfef6',
    base08 = '#f29d8c',
    base09 = '#e74b2c',
    base0A = '#6ae72c',
    base0B = '#aef28c',
    base0C = '#a92ce7',
    base0D = '#8ce1f2',
    base0E = '#d08cf2',
    base0F = '#2cc8e7'
  }
end

-- Dark palette is an output of 'MiniBase16.mini_palette' with background
-- '#e5eeff' (HSL = 220-100-95) and foreground '#7f9900' (HSL = 70-100-30)
if vim.o.background == 'light' then
  palette = {
    base00 = '#e5eeff',
    base01 = '#9dbfff',
    base02 = '#5690ff',
    base03 = '#0e61ff',
    base04 = '#bae000',
    base05 = '#7f9900',
    base06 = '#445200',
    base07 = '#080a00',
    base08 = '#991a00',
    base09 = '#ff360e',
    base0A = '#5eff0e',
    base0B = '#339900',
    base0C = '#af0eff',
    base0D = '#008099',
    base0E = '#660099',
    base0F = '#0ed7ff'
  }
end

if palette then
  require('mini.base16').apply(palette, 'minischeme')
end