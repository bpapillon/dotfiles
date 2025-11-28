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
  use('wbthomason/packer.nvim')

  use('tpope/vim-commentary')
  use('tpope/vim-fugitive')
  use('tpope/vim-surround')

  use('preservim/nerdtree')
  use('Xuyuanp/nerdtree-git-plugin')
  use('ctrlpvim/ctrlp.vim')

  use('vim-airline/vim-airline')
  use('vim-airline/vim-airline-themes')

  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.4',
    requires = { {'nvim-lua/plenary.nvim'} }
  }

  use {
    'neoclide/coc.nvim',
    branch = 'release',
    run = function()
      vim.fn['coc#util#install']()
    end
  }
  use('github/copilot.vim')
  use('leafgarland/typescript-vim')
  use('prettier/vim-prettier')
  use('folke/trouble.nvim')

  use('nvim-lua/plenary.nvim') -- used by lua/llm.lua

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
          'c_sharp',
          'comment',
          'css',
          'dockerfile',
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
          'php',
          'python',
          'regex',
          'ruby',
          'rust',
          'scss',
          'sql',
          'toml',
          'tsx',
          'typescript',
          'vim',
        },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = true,
        },
      })
    end,
  })

  use {
    'klen/nvim-test',
    config = function()
      require('nvim-test').setup {
        termOpts = {
          direction = 'float',
          width = 192,
          height = 48
        }
      }
      require('nvim-test.runners.go-test'):setup {
        env = {
          CONFIG_FILE = '/Users/bpapillon/projects/schematic/schematic-api/test.env',
        },
      }
      require('nvim-test.runners.jest'):setup {
        command = 'yarn test',
      }
    end
  }

  use({
    "iamcco/markdown-preview.nvim",
    run = function() vim.fn["mkdp#util#install"]() end,
    ft = { "markdown" },
    setup = function()
      local mm = {
        theme = "dark",
        darkMode = true,
        securityLevel = "loose",
        flowchart = {
          curve = "basis",
          nodeSpacing = 96,
          rankSpacing = 108,
          htmlLabels = false,
          useMaxWidth = true,
          padding = 16,
        },
        themeVariables = {
          primaryColor = "#141922",       -- node fill
          primaryTextColor = "#e6e7eb",   -- node text
          primaryBorderColor = "#303744", -- node stroke
          lineColor = "#8a93a3",
          clusterBkg = "#0b0f14",
          clusterBorder = "#22303c",
          fontFamily = "Inter, ui-sans-serif, system-ui",
          fontSize   = "18px",
        },
      }

      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_preview_options = {
        mermaid = mm,
        maid    = mm,
      }

      vim.g.mkdp_markdown_css = vim.fn.expand("~/.config/nvim/markdown-preview.css")
    end,
  })

  if packer_bootstrap then
    require('packer').sync()
  end
end)
