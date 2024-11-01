-- Telescope
local telescope = require('telescope.builtin')
vim.keymap.set('n', 'ff', telescope.find_files, {})
vim.keymap.set('n', 'fg', telescope.live_grep, {})
vim.keymap.set('n', 'fb', telescope.buffers, {})
vim.keymap.set('n', 'fh', telescope.help_tags, {})

local actions = require('telescope.actions')
vim.keymap.set('n', '<leader>fh', function()
  telescope.find_files {
    attach_mappings = function(_, map)
      map('i', '<C-x>', actions.select_horizontal)  -- Horizontal split
      map('i', '<C-v>', actions.select_vertical)    -- Vertical split
      map('n', '<C-x>', actions.select_horizontal)  -- Horizontal split in normal mode
      map('n', '<C-v>', actions.select_vertical)    -- Vertical split in normal mode
      return true
    end,
  }
end)

