# 🛸 projections.nvim

<!-- panvimdoc-ignore-start -->

![vimdoc workflow](https://img.shields.io/github/actions/workflow/status/gnikdroy/projections.nvim/gendocs.yml?branch=main)
![code size](https://img.shields.io/github/languages/code-size/gnikdroy/projections.nvim?style=flat-square)
![license](https://img.shields.io/github/license/gnikdroy/projections.nvim?style=flat-square)

<!-- panvimdoc-ignore-end -->

A tiny **project** + sess**ions** manager for neovim, written in lua. Sessions support is optional.

<!-- panvimdoc-ignore-start -->

![Project Telescope](https://user-images.githubusercontent.com/30725674/206680980-eebb0f6d-b130-4070-80ab-7aab34450165.gif)

<!-- panvimdoc-ignore-end -->

## 🗺️ Quick Guide

### Terminologies

```haskell
─── W
    ├── A
    │   └── .git
    ├── B
    │   └── .hg
    └── D
         └── E
              └── .svn
```
#### Workspace

A workspace is a directory that contains projects as their children. That's it.
Grandchildren are not considered projects.

> In the figure above, `W` is a workspace

#### Project

A project is any subdirectory of a workspace which contains a file/directory present in `patterns`.

For instance, if `patterns` is `{ ".git", ".svn", ".hg" }`, then all Git, SVN,
and Mercurial repositories under workspace `W` are considered projects.

> In the figure above, `A`, and `B` are projects. `D` and `E` are **not** projects.

You can get creative with this, `{ "package.json" }`, would classify all `npm` packages as projects.

*See `projections.init.setup`, or the next section for more details on `patterns`*

#### Sessions

This plugin also provides a small, and (completely optional) session manager for projects.
**It is only intended to work with projections' projects!**. See, `:h session` and `projections.session`

## 🔌 Installation

**The table provided to setup consists of default values for the options.** *None* of the arguments are required.
Workspaces can be configured dynamically via a json file. See `AddWorkspace` command configuration below.

```lua
use({ 
    'gnikdroy/projections.nvim',
    config = function()
        require("projections").setup({
            workspaces = {                                -- Default workspaces to search for 
                -- { "~/Documents/dev", { ".git" } },        Documents/dev is a workspace. patterns = { ".git" }
                -- { "~/repos", {} },                        An empty pattern list indicates that all subdirectories are considered projects
                -- "~/dev",                                  dev is a workspace. default patterns is used (specified below)
            },
            -- patterns = { ".git", ".svn", ".hg" },      -- Default patterns to use if none were specified. These are NOT regexps.
            -- store_hooks = { pre = nil, post = nil },   -- pre and post hooks for store_session, callable | nil
            -- restore_hooks = { pre = nil, post = nil }, -- pre and post hooks for restore_session, callable | nil
            -- workspaces_file = "path/to/file",          -- Path to workspaces json file
            -- sessions_directory = "path/to/dir",        -- Directory where sessions are stored
        })
    end
})
```

## 🛠️ Configuration

`projections` doesn't register commands or keybindings. It leaves you with 100% control.
As this might be inconvenient to some, this section comes with a recommended configuration 
and recipes for different workflows.

### Recommended configuration

The recommended setup does the following:

* Provides a telescope switcher for projects, which can be launched by `<leader>fp`
* Saves project's session automatically on `VimExit`
* Switch to project if nvim was started from a project root

```lua
use({
    "gnikdroy/projections.nvim",
    config = function()
        require("projections").setup({})

        -- Bind <leader>fp to Telescope projections
        require('telescope').load_extension('projections')
        vim.keymap.set("n", "<leader>fp", function() vim.cmd("Telescope projections") end)

        -- Autostore session on VimExit
        local Session = require("projections.session")
        vim.api.nvim_create_autocmd({ 'VimLeavePre' }, {
            callback = function() Session.store(vim.loop.cwd()) end,
        })

        -- Switch to project if vim was started in a project dir
        local switcher = require("projections.switcher")
        vim.api.nvim_create_autocmd({ "VimEnter" }, {
            callback = function()
                if vim.fn.argc() == 0 then switcher:switch(vim.loop.cwd()) end
            end,
        })
    end
})
```

Additionally you will likely want to enable `localoptions`:

```lua
vim.opt.sessionoptions:append("localoptions")       -- Save localoptions to session file
```

### Recipes

#### Automatically restore last session

The following lines setup an autocmd to automatically restore last session.
If you are using the recommended configuration, make sure to remove the
`VimEnter` autocmd

```lua
-- If vim was started with arguments, do nothing
-- If in some project's root, attempt to restore that project's session
-- If not, restore last session
-- If no sessions, do nothing
local Switcher = require("projections.switcher")
local Session = require("projections.session")
vim.api.nvim_create_autocmd({ "VimEnter" }, {
    callback = function()
        if vim.fn.argc() ~= 0 then return end
        local session_info = Session.info(vim.loop.cwd())
        if session_info == nil then
            Switcher.last()
        else
            Session.restore(vim.loop.cwd())
        end
    end,
    desc = "Restore last session automatically"
})
```

#### Manual Session commands

The following lines register two commands `StoreProjectSession` and `RestoreProjectSession`.
Both of them attempt to store/restore the session if `cwd` is a project directory.

```lua
local Session = require("projections.session")
vim.api.nvim_create_user_command("StoreProjectSession", function()
    Session.store(vim.loop.cwd())
end, {})

vim.api.nvim_create_user_command("RestoreProjectSession", function()
    Session.restore(vim.loop.cwd())
end, {})
```

#### Create AddWorkspace command

The following example creates a `AddWorkspace` user command
which adds the current directory to workspaces json file. Default set of `patterns` is used.

```lua
local Workspace = require("projections.workspace")
-- Add workspace command
vim.api.nvim_create_user_command("AddWorkspace", function() 
    Workspace.add(vim.loop.cwd()) 
end, {})
```

The json file format is as follows:

```json
[
    {
        "path": "/path/to/workspace",
        "patterns": ["list", "of", "patterns"]
    },
    {
        "path": "/tmp",
        "patterns": [".git", ".svn", ".hg"]
    }
]
```

### Intended usage

> You are responsible for creating a clear folder structure for your projects!
While this plugin doesn't force any particularly outrageous folder structure,
it won't work well with a particularly outrageous folder structure either!

`projections` stores information in the following places by default:

```lua
workspaces = stdpath('data') .. 'projections_workspaces.json'
sessions   = stdpath('cache') .. 'projections_sessions/'
```

## 🔭 About Telescope

**The telescope plugin is intended to be the primary method to switch between projects!**
So expect the usability of this plugin to be greatly compromised if you don't use 
[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

That being said, you can create your own project switcher with the exposed functions.

### 🔍 Use fzf?

Take a look at the unofficial extension by nyngwang: [fzf-lua-projections](https://github.com/nyngwang/fzf-lua-projections.nvim)

## 💻 API

The source files are documented for now. But this section will be completed in due time.
The API is not stable. You might need to spend a couple of minutes every once in a while to update!
That being said, most of the core stuff shouldn't change.

## 📦 Interaction with plugins

Neovim's sessions do not work well with some plugins. For example, if you try `:mksession` with an open
`nvim-tree` window, it will store instructions for an empty buffer in the sessions file.

There are several other plugins that do not work well. There are several methods to deal with this including:

1. Close all such buffers before saving the session. `see pre store hooks`
2. Store all such buffers, and then restore them accordingly. `see post restore hooks`
3. Do nothing and handle the buffers manually, either at store or restore.

For example, let's see how you can close `nvim-tree`, or `neo-tree` before storing sessions:

```lua
require("projections").setup({
    store_hooks = {
        pre = function()
            -- nvim-tree 
            local nvim_tree_present, api = pcall(require, "nvim-tree.api")
            if nvim_tree_present then api.tree.close() end

            -- neo-tree
            if pcall(require, "neo-tree") then vim.cmd [[Neotree action=close]] end
        end
    }
})
```

**Will such a functionality be present in `projections`?** Hard to say. This is not an easy problem to solve reliably.
Option 2 sounds reasonable, but everyone has different needs.
And since the user knows better than `projections`, I am inclined to push this responsibility to the user as well.
If enough people ask for this, I may provide support for common plugins via something like `projections.unstable`

## ❓ Further queries

1. Make sure you have read `:h session`, `:h mksession`, and `:h sessionoptions`
2. Check out the [wiki](https://github.com/GnikDroy/projections.nvim/wiki), the FAQ, and this document.
2. Search active and closed [issues](https://github.com/GnikDroy/projections.nvim/issues?q=is%3Aissue)

If you still can't solve your problem, feel free to file an issue.
