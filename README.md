# projections.nvim

A tiny **project** + sess**ions** manager for neovim, written in lua. Sessions support is optional.

![Project Telescope](https://user-images.githubusercontent.com/30725674/201093394-26ad578d-6a8d-4830-81c6-9e87eb5f0a34.png)

## Quick Guide

### Terminologies

```yaml
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
Grandchildrens are not considered projects.

> In the figure above, `W` is a workspace

#### Project

A project is any subdirectory of a workspace which contains a file/directory present in `patterns`.

For instance, if `patterns` is `{ ".git", ".svn", ".hg" }`, then all Git, SVN,
and Mercurial repositories under workspace `W` are considered projects.

> In the figure above, `A`, and `B` are projects. `D` and `E` are **not** projects.

You can get creative with this, `{ "package.json" }`, would classify all `npm` packages as projects.

*See `projections.setup()` for more details on `patterns`*

#### Sessions

This plugin also provides a small, and (completely optional) session manager for projects.
**It is only intended to work with projection's projects!**. See, `:h session` and `projections.sessions`

### Intended usage

You provide `projections` a list of workspaces, and it will figure out everything else!

For example, if you store your projects in `~/dev`, `~/Documents/dev` and `C:/repos`,
then you are responsible for providing that information. There are several methods to do so.
They are mentioned in their relevant sections. This is where the plugin stores that information:

```lua
workspaces = stdpath('data') .. 'projection_workspaces.txt'
sessions   = stdpath('cache') .. 'projection_sessions/'
```

> You are responsible for creating a clear folder structure for your projects!
While this plugin doesn't force any particularly outrageous folder structure,
it won't work well with a particularly outrageous folder structure either!


## Installation

```lua
use({ 
    'gnikdroy/projections.nvim',
    config = function()
        require("projections").setup({
            patterns = { ".git", ".svn", ".hg" }, -- Patterns to search for
            workspaces = { "~/dev" },             -- Default workspaces to search for
        })
    end
})
```

## Configuration

`projections` doesn't register commands or keybindings. It leaves you with 100% control.
As this might be inconvenient to some, this section comes with a recommended configuration 
and recipes for different workflows.

### Recommended configuration

The following saves project's session automatically, and provides a telescope switcher for projects.
Additionlly, `AddWorkspace` command is registered to help users add CWD as workspace.

```lua
use({
    "gnikdroy/projections.nvim",
    config = function()
        require("projections").setup({})
        local sessions = require("projections.sessions")

        -- Attempt to save session automatically on directory change and exit
        vim.api.nvim_create_autocmd({ 'DirChangedPre', 'VimLeavePre' }, {
            callback = function() sessions.save_project_session(vim.loop.cwd()) end,
            desc = "Save project session",
        })

        -- Bind <leader>p to Telescope find_projects
        -- on select switch to project's root and attempt to load project's session
        require('telescope').load_extension('projections')
        vim.keymap.set("n", "<leader>p", function()
            local find_projects = require("telescope").extensions.projections.projections
            find_projects({
                action = function(selection)
                    vim.fn.chdir(selection.value)
                    sessions.load_project_session(selection.value)
                end,
            })
        end, { desc = "Find projects" })

        -- Add workspace command
        vim.api.nvim_create_user_command("AddWorkspace", function() workspaces.add_workspace(vim.loop.cwd()) end, {})
    end
})
```
### Recipes

#### Manual Session commands

The following lines register two commands `SaveProjectSession` and `LoadProjectSession`.
Both of them attempt to save/load the session if `cwd` is a project directory.

```lua
local sessions = require("projections.sessions")

vim.api.nvim_create_user_command("SaveProjectSession", function()
    sessions.save_project_session(vim.loop.cwd())
end, {})

vim.api.nvim_create_user_command("LoadProjectSession", function()
    sessions.load_project_session(vim.loop.cwd())
end, {})
```

#### Autoload session if in project's root

The following example loads the project's session
if you launch nvim from project's root.

```lua
vim.api.nvim_create_autocmd('VimEnter' , {
    callback = function() sessions.load_project_session(vim.loop.cwd()) end,
    desc = "Autoload project session while launching vim",
})
```

## About Telescope

**The telescope plugin is intended to be the primary method to switch between projects!**
So expect the usability of this plugin to be greatly compromised if you don't use 
[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

That being said, you can create your own project switcher with the exposed functions.

## Interactions with other plugins

Neovim's sessions do not work well with some plugins. For example, if you try `:mksession` with an open
`nvim-tree` window, it will store instructions for an empty buffer in the sessions file.

There are several other plugins that do not work well. This is why it is recommended to close all such buffers
before attempting to save a session.

**Will such a functionality be present in `projections`?** Hard to say. This is not an easy problem to solve reliably.
And since the user knows better than `projections`, I am inclined to push this responsibility to the user as well.
