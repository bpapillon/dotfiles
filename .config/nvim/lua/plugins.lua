local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
  use("wbthomason/packer.nvim")

  use("dense-analysis/ale")
  use("tpope/vim-commentary")
  use("tpope/vim-surround")

  use("preservim/nerdtree")
  use("Xuyuanp/nerdtree-git-plugin")

  use("tpope/vim-fugitive")

  use("vim-airline/vim-airline")
  use("vim-airline/vim-airline-themes")

  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.0',
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  -- use({
  --   "nvim-telescope/telescope.nvim",
  --   requires = { "kyazdani42/nvim-web-devicons", "nvim-lua/plenary.nvim" }
  --   config = function()
  --     local actions = require("telescope.actions")

  --     require("telescope").setup({
  --       defaults = {
  --         layout_config = {
  --           prompt_position = "bottom",
  --         },
  --         layout_strategy = "bottom_pane",
  --         path_display = {
  --           shorten = {
  --             len = 2,
  --             exclude = { -1, -2 },
  --           },
  --         },
  --       },
  --       pickers = {
  --         find_files = {
  --           find_command = { "fd", "--hidden", "--glob", "", "--type", "file" },
  --         },
  --         live_grep = {
  --           file_ignore_patterns = { "node_modules", ".git" },
  --           find_command = "rg",
  --           additional_args = function()
  --             return {
  --               "--no-heading",
  --               "--with-filename",
  --               "--line-number",
  --               "--column",
  --               "--hidden",
  --               "--smart-case",
  --             }
  --           end,
  --         },
  --         buffers = {
  --           mappings = {
  --             i = {
  --               ["<c-q>"] = actions.delete_buffer + actions.move_to_top,
  --             },
  --           },
  --         },
  --       },
  --       extensions = {
  --         ["ui-select"] = {
  --           require("telescope.themes").get_dropdown({
  --             layout_config = {
  --               prompt_position = "top",
  --             },
  --           }),
  --         },
  --       },
  --     })
  --   end,
  -- })

  use('fatih/vim-go')
  use('leafgarland/typescript-vim')
  use('maxmellon/vim-jsx-pretty')
  use('mxw/vim-jsx')
  use {'neoclide/coc.nvim', branch = 'release'}
  use('pangloss/vim-javascript')
  use('peitalin/vim-jsx-typescript')
  use('tpope/vim-markdown')
  use('uarun/vim-protobuf')
  use('cespare/vim-toml')
  use('github/copilot.vim')
end)
