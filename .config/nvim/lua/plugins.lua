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

  use({
    'nvim-treesitter/nvim-treesitter',
    run = function()
      require('nvim-treesitter.install').update({ with_sync = true })
    end,
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = {
          'bash',
          'cmake',
          'comment',
          'css',
          'dockerfile',
          'fish',
          'gitignore',
          'go',
          'gomod',
          'graphql',
          'html',
          'http',
          'javascript',
          'jsdoc',
          'json',
          'json5',
          'latex',
          'lua',
          'make',
          'markdown',
          'markdown_inline',
          'ocaml',
          'python',
          'regex',
          'ruby',
          'rust',
          'scss',
          'solidity',
          'sql',
          'svelte',
          'swift',
          'todotxt',
          'toml',
          'tsx',
          'typescript',
          'vim',
          'vue',
        },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = true,
        },
      })
    end,
  })

  use {
    "klen/nvim-test",
    config = function()
      require('nvim-test').setup {
        run = true,                 -- run tests (using for debug)
        commands_create = true,     -- create commands (TestFile, TestLast, ...)
        filename_modifier = ":.",   -- modify filenames before tests run(:h filename-modifiers)
        silent = false,             -- less notifications
        term = "terminal",          -- a terminal to run ("terminal"|"toggleterm")
        termOpts = {
          direction = "vertical",   -- terminal's direction ("horizontal"|"vertical"|"float")
          width = 96,               -- terminal's width (for vertical|float)
          height = 24,              -- terminal's height (for horizontal|float)
          go_back = false,          -- return focus to original window after executing
          stopinsert = "auto",      -- exit from insert mode (true|false|"auto")
          keep_one = true,          -- keep only one terminal for testing
        },
        runners = {               -- setup tests runners
          go = "nvim-test.runners.go-test",
        }
      }

      require('nvim-test.runners.go-test'):setup {
        env = {
          RCORE_TEST_CONFIG = "/Users/bpapillon/projects/dev-env/relay-rcore-testing.toml",
          RELAY_TEST_CONFIG = "/Users/bpapillon/projects/dev-env/relay-core-testing.toml",
          RPOS_TEST_CONFIG = "/Users/bpapillon/projects/dev-env/relay-portal-testing.toml",
        },
      }
    end
  }

end)
