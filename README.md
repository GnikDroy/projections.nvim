# 🛸 projections.nvim

<!-- panvimdoc-ignore-start -->

![vimdoc workflow](https://img.shields.io/github/actions/workflow/status/gnikdroy/projections.nvim/gendocs.yml?branch=main)
![code size](https://img.shields.io/github/languages/code-size/gnikdroy/projections.nvim?style=flat-square)
![license](https://img.shields.io/github/license/gnikdroy/projections.nvim?style=flat-square)

<!-- panvimdoc-ignore-end -->

A tiny **project** + sess**ions** manager for neovim, written in lua.

<!-- panvimdoc-ignore-start -->

![Project Telescope](https://user-images.githubusercontent.com/30725674/249766947-e2fa995c-c860-423b-a775-9a55ac7d6256.png)

<!-- panvimdoc-ignore-end -->

## 🔌 Installation

```lua

{ 'gnikdroy/projections.nvim', opts = {} }

```

Additionally you will likely want to enable `localoptions`:

```lua
-- Save localoptions to session file
vim.opt.sessionoptions:append("localoptions")
```

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
#### Workspace / Project

A workspace houses projects.

> In the figure above, `W` is a workspace

A project is a direct children of a workspace.
Given that the project contains any one of `patterns`.

For instance, if `patterns` is `{ ".git", ".svn", ".hg" }`, then all Git, SVN,
and Mercurial repositories under workspace `W` are considered projects.

> In the figure above, `A`, and `B` are projects. `D` and `E` are **not** projects.

`patterns = { "package.json" }`, would classify all `npm` packages as projects etc.


## 🛠️ Configuration

**The table provided consists of default values for the options.**


```lua
{ 
    -- Workspaces to search for, (table|string)[]
    workspaces = {
    -- Examples:
    -- { path = "~/dev", patterns = { ".git" } },
    -- { path = "~/repos", patterns = {} }      , -- An empty pattern list indicates that all subdirectories are projects
                                                  -- i.e patterns are not considered
    -- { path = "~/dev" },                        -- When patterns is not provided, default patterns is used (specified below)
    },

    -- Default set of patterns, string[]
    -- NOTE: patterns are not regexps
    default_patterns = { ".git", ".svn", ".hg" },

    -- The keymapping to use to launch the picker, string?
    selector_mapping = "<leader>fp",

    -- If projections will try to auto restore sessions when you open neovim, boolean
    auto_restore = true,
    -- The behaviour is as follows:
    -- 1) If vim was started with arguments, do nothing
    -- 2) If in some project's root, attempt to restore that project's session
    -- 3) If not, restore last stored session

    -- Hooks when storing session, function?
    store_hooks = { pre = nil, post = nil },

    -- Hooks when restoring session, function?
    restore_hooks = { pre = nil, post = nil },

    -- Path to workspaces json file, string?
    workspaces_file = stdpath("data") .. "projections_workspaces.json",

    -- Directory where sessions are stored
    sessions_directory = stdpath("cache") .. "projections_sessions/",
}
```

## 💻 API

The source files are documented and annotated.
All functions that do not start with an underscore are public.

If you have something like [neodev](https://github.com/folke/neodev.nvim) setup, it should give you proper documentation and autocomplete.

### Availabe commands

1. `:ProjectionsAddWorkspace` - Adds the current working directory to workspaces.json file. Default set of patterns is used.
1. `:Telescope projections`   - You can select the projections picker through telescope


### JSON file format

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

## 📦 Interaction with plugins

Some plugins do not work well with Neovim's sessions. For example, if you try `:mksession` with an open
`nvim-tree` window (at the time of writing), it will store instructions for an empty buffer in the sessions file.

There are several other plugins that do not work well. There are several methods to deal with this including:

1. Close all such buffers before saving the session. `see pre store hooks`
2. Store all such buffers, and then restore them accordingly. `see post restore hooks`

For example, let's see how you can close `nvim-tree`, or `neo-tree` before storing sessions:

```lua
{
    store_hooks = {
        pre = function()
            -- nvim-tree 
            local nvim_tree_present, api = pcall(require, "nvim-tree.api")
            if nvim_tree_present then api.tree.close() end

            -- neo-tree
            if pcall(require, "neo-tree") then vim.cmd [[Neotree action=close]] end
        end
    }
}
```

**Will such a functionality be present in `projections`?** Hard to say. This is not an easy problem to solve reliably.
Option 2 sounds reasonable, but everyone has different needs.

I am inclined to push this responsibility to the user. The provided hooks should be enough to solve basic problems.
If the same problem is encountered many times, I may provide support for common plugins via something like `projections.unstable`

## ❓ Further queries

1. Make sure you have read `:h session`, `:h mksession`, and `:h sessionoptions`
2. Check out the [wiki](https://github.com/GnikDroy/projections.nvim/wiki), the FAQ, and this document.
2. Search active and closed [issues](https://github.com/GnikDroy/projections.nvim/issues?q=is%3Aissue)

If you still can't solve your problem, feel free to file an issue.
