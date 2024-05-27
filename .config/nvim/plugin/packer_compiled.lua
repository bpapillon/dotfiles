-- Automatically generated packer.nvim plugin loader code

if vim.api.nvim_call_function('has', {'nvim-0.5'}) ~= 1 then
  vim.api.nvim_command('echohl WarningMsg | echom "Invalid Neovim version for packer.nvim! | echohl None"')
  return
end

vim.api.nvim_command('packadd packer.nvim')

local no_errors, error_msg = pcall(function()

_G._packer = _G._packer or {}
_G._packer.inside_compile = true

local time
local profile_info
local should_profile = false
if should_profile then
  local hrtime = vim.loop.hrtime
  profile_info = {}
  time = function(chunk, start)
    if start then
      profile_info[chunk] = hrtime()
    else
      profile_info[chunk] = (hrtime() - profile_info[chunk]) / 1e6
    end
  end
else
  time = function(chunk, start) end
end

local function save_profiles(threshold)
  local sorted_times = {}
  for chunk_name, time_taken in pairs(profile_info) do
    sorted_times[#sorted_times + 1] = {chunk_name, time_taken}
  end
  table.sort(sorted_times, function(a, b) return a[2] > b[2] end)
  local results = {}
  for i, elem in ipairs(sorted_times) do
    if not threshold or threshold and elem[2] > threshold then
      results[i] = elem[1] .. ' took ' .. elem[2] .. 'ms'
    end
  end
  if threshold then
    table.insert(results, '(Only showing plugins that took longer than ' .. threshold .. ' ms ' .. 'to load)')
  end

  _G._packer.profile_output = results
end

time([[Luarocks path setup]], true)
local package_path_str = "/Users/bpapillon/.cache/nvim/packer_hererocks/2.1.1710088188/share/lua/5.1/?.lua;/Users/bpapillon/.cache/nvim/packer_hererocks/2.1.1710088188/share/lua/5.1/?/init.lua;/Users/bpapillon/.cache/nvim/packer_hererocks/2.1.1710088188/lib/luarocks/rocks-5.1/?.lua;/Users/bpapillon/.cache/nvim/packer_hererocks/2.1.1710088188/lib/luarocks/rocks-5.1/?/init.lua"
local install_cpath_pattern = "/Users/bpapillon/.cache/nvim/packer_hererocks/2.1.1710088188/lib/lua/5.1/?.so"
if not string.find(package.path, package_path_str, 1, true) then
  package.path = package.path .. ';' .. package_path_str
end

if not string.find(package.cpath, install_cpath_pattern, 1, true) then
  package.cpath = package.cpath .. ';' .. install_cpath_pattern
end

time([[Luarocks path setup]], false)
time([[try_loadstring definition]], true)
local function try_loadstring(s, component, name)
  local success, result = pcall(loadstring(s), name, _G.packer_plugins[name])
  if not success then
    vim.schedule(function()
      vim.api.nvim_notify('packer.nvim: Error running ' .. component .. ' for ' .. name .. ': ' .. result, vim.log.levels.ERROR, {})
    end)
  end
  return result
end

time([[try_loadstring definition]], false)
time([[Defining packer_plugins]], true)
_G.packer_plugins = {
  ChatVim = {
    loaded = true,
    path = "/Users/bpapillon/.local/share/nvim/site/pack/packer/start/ChatVim",
    url = "https://github.com/jakethekoenig/ChatVim"
  },
  ["coc.nvim"] = {
    loaded = true,
    path = "/Users/bpapillon/.local/share/nvim/site/pack/packer/start/coc.nvim",
    url = "https://github.com/neoclide/coc.nvim"
  },
  ["copilot.vim"] = {
    loaded = true,
    path = "/Users/bpapillon/.local/share/nvim/site/pack/packer/start/copilot.vim",
    url = "https://github.com/github/copilot.vim"
  },
  nerdtree = {
    loaded = true,
    path = "/Users/bpapillon/.local/share/nvim/site/pack/packer/start/nerdtree",
    url = "https://github.com/preservim/nerdtree"
  },
  ["nerdtree-git-plugin"] = {
    loaded = true,
    path = "/Users/bpapillon/.local/share/nvim/site/pack/packer/start/nerdtree-git-plugin",
    url = "https://github.com/Xuyuanp/nerdtree-git-plugin"
  },
  ["nvim-test"] = {
    config = { "\27LJ\2\nÙ\2\0\0\5\0\f\0\0256\0\0\0'\2\1\0B\0\2\0029\0\2\0005\2\4\0005\3\3\0=\3\5\2B\0\2\0016\0\0\0'\2\6\0B\0\2\2\18\2\0\0009\0\2\0005\3\b\0005\4\a\0=\4\t\3B\0\3\0016\0\0\0'\2\n\0B\0\2\2\18\2\0\0009\0\2\0005\3\v\0B\0\3\1K\0\1\0\1\0\1\fcommand(npx dotenv -e test.env -- yarn test\27nvim-test.runners.jest\benv\1\0\1\benv\0\1\0\1\16CONFIG_FILE?/Users/bpapillon/projects/schematic/schematic-api/test.env\30nvim-test.runners.go-test\rtermOpts\1\0\1\rtermOpts\0\1\0\3\vheight\0030\nwidth\3¿\1\14direction\nfloat\nsetup\14nvim-test\frequire\0" },
    loaded = true,
    path = "/Users/bpapillon/.local/share/nvim/site/pack/packer/start/nvim-test",
    url = "https://github.com/klen/nvim-test"
  },
  ["nvim-treesitter"] = {
    config = { "\27LJ\2\nç\3\0\0\4\0\b\0\v6\0\0\0'\2\1\0B\0\2\0029\0\2\0005\2\4\0005\3\3\0=\3\5\0025\3\6\0=\3\a\2B\0\2\1K\0\1\0\14highlight\1\0\2\venable\2&additional_vim_regex_highlighting\2\21ensure_installed\1\0\2\21ensure_installed\0\14highlight\0\1 \0\0\tbash\ncmake\fcomment\bcss\15dockerfile\14gitignore\ago\ngomod\fgraphql\thtml\thttp\15javascript\njsdoc\tjson\njson5\nlatex\blua\tmake\rmarkdown\20markdown_inline\bphp\vpython\nregex\truby\trust\tscss\bsql\ttoml\btsx\15typescript\bvim\nsetup\28nvim-treesitter.configs\frequire\0" },
    loaded = true,
    path = "/Users/bpapillon/.local/share/nvim/site/pack/packer/start/nvim-treesitter",
    url = "https://github.com/nvim-treesitter/nvim-treesitter"
  },
  ["packer.nvim"] = {
    loaded = true,
    path = "/Users/bpapillon/.local/share/nvim/site/pack/packer/start/packer.nvim",
    url = "https://github.com/wbthomason/packer.nvim"
  },
  ["plenary.nvim"] = {
    loaded = true,
    path = "/Users/bpapillon/.local/share/nvim/site/pack/packer/start/plenary.nvim",
    url = "https://github.com/nvim-lua/plenary.nvim"
  },
  ["presenting.vim"] = {
    loaded = true,
    path = "/Users/bpapillon/.local/share/nvim/site/pack/packer/start/presenting.vim",
    url = "https://github.com/sotte/presenting.vim"
  },
  ["telescope.nvim"] = {
    loaded = true,
    path = "/Users/bpapillon/.local/share/nvim/site/pack/packer/start/telescope.nvim",
    url = "https://github.com/nvim-telescope/telescope.nvim"
  },
  ["trouble.nvim"] = {
    loaded = true,
    path = "/Users/bpapillon/.local/share/nvim/site/pack/packer/start/trouble.nvim",
    url = "https://github.com/folke/trouble.nvim"
  },
  ["typescript-vim"] = {
    loaded = true,
    path = "/Users/bpapillon/.local/share/nvim/site/pack/packer/start/typescript-vim",
    url = "https://github.com/leafgarland/typescript-vim"
  },
  ["vim-airline"] = {
    loaded = true,
    path = "/Users/bpapillon/.local/share/nvim/site/pack/packer/start/vim-airline",
    url = "https://github.com/vim-airline/vim-airline"
  },
  ["vim-airline-themes"] = {
    loaded = true,
    path = "/Users/bpapillon/.local/share/nvim/site/pack/packer/start/vim-airline-themes",
    url = "https://github.com/vim-airline/vim-airline-themes"
  },
  ["vim-commentary"] = {
    loaded = true,
    path = "/Users/bpapillon/.local/share/nvim/site/pack/packer/start/vim-commentary",
    url = "https://github.com/tpope/vim-commentary"
  },
  ["vim-fugitive"] = {
    loaded = true,
    path = "/Users/bpapillon/.local/share/nvim/site/pack/packer/start/vim-fugitive",
    url = "https://github.com/tpope/vim-fugitive"
  },
  ["vim-prettier"] = {
    loaded = true,
    path = "/Users/bpapillon/.local/share/nvim/site/pack/packer/start/vim-prettier",
    url = "https://github.com/prettier/vim-prettier"
  },
  ["vim-surround"] = {
    loaded = true,
    path = "/Users/bpapillon/.local/share/nvim/site/pack/packer/start/vim-surround",
    url = "https://github.com/tpope/vim-surround"
  }
}

time([[Defining packer_plugins]], false)
-- Config for: nvim-test
time([[Config for nvim-test]], true)
try_loadstring("\27LJ\2\nÙ\2\0\0\5\0\f\0\0256\0\0\0'\2\1\0B\0\2\0029\0\2\0005\2\4\0005\3\3\0=\3\5\2B\0\2\0016\0\0\0'\2\6\0B\0\2\2\18\2\0\0009\0\2\0005\3\b\0005\4\a\0=\4\t\3B\0\3\0016\0\0\0'\2\n\0B\0\2\2\18\2\0\0009\0\2\0005\3\v\0B\0\3\1K\0\1\0\1\0\1\fcommand(npx dotenv -e test.env -- yarn test\27nvim-test.runners.jest\benv\1\0\1\benv\0\1\0\1\16CONFIG_FILE?/Users/bpapillon/projects/schematic/schematic-api/test.env\30nvim-test.runners.go-test\rtermOpts\1\0\1\rtermOpts\0\1\0\3\vheight\0030\nwidth\3¿\1\14direction\nfloat\nsetup\14nvim-test\frequire\0", "config", "nvim-test")
time([[Config for nvim-test]], false)
-- Config for: nvim-treesitter
time([[Config for nvim-treesitter]], true)
try_loadstring("\27LJ\2\nç\3\0\0\4\0\b\0\v6\0\0\0'\2\1\0B\0\2\0029\0\2\0005\2\4\0005\3\3\0=\3\5\0025\3\6\0=\3\a\2B\0\2\1K\0\1\0\14highlight\1\0\2\venable\2&additional_vim_regex_highlighting\2\21ensure_installed\1\0\2\21ensure_installed\0\14highlight\0\1 \0\0\tbash\ncmake\fcomment\bcss\15dockerfile\14gitignore\ago\ngomod\fgraphql\thtml\thttp\15javascript\njsdoc\tjson\njson5\nlatex\blua\tmake\rmarkdown\20markdown_inline\bphp\vpython\nregex\truby\trust\tscss\bsql\ttoml\btsx\15typescript\bvim\nsetup\28nvim-treesitter.configs\frequire\0", "config", "nvim-treesitter")
time([[Config for nvim-treesitter]], false)

_G._packer.inside_compile = false
if _G._packer.needs_bufread == true then
  vim.cmd("doautocmd BufRead")
end
_G._packer.needs_bufread = false

if should_profile then save_profiles() end

end)

if not no_errors then
  error_msg = error_msg:gsub('"', '\\"')
  vim.api.nvim_command('echohl ErrorMsg | echom "Error in packer_compiled: '..error_msg..'" | echom "Please check your config for correctness" | echohl None')
end
