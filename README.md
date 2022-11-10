# projections.nvim

<div>
   A tiny <span style="color: #a33">project</span> + sess<span style="color: #a33">ions</span> manager for neovim,
   written in lua. Sessions support is optional.
</div>

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

A workspace is a folder that contains projects as their children. That's it. :)
**Take note that grandchildren are not considered projects!**

> In the figure above, `W` is a workspace

#### Project
A project is any subdirectory of a workspace which contains a file/folder present in `patterns`

For example, if patterns is `[".git", ".svn", ".hg"]`, then all Git, SVN,
and Mercurial repositories under workspace `W` are considered projects.

> In the figure above, `A`, and `B` are projects. `D` and `E` are **not** projects.

You can get creative with this, `["package.json"]`, would classify all `npm` packages as projects.

#### Sessions

This plugin also provides a small, and (completely optional) session manager for projects.
**It is only intended to work with projection's projects!**. See also, `:h session`

### Intended usage

You provide `projections` a list of workspaces, and it will figure out everything else!

For example, if you store your projects in `~/dev`, `~/Documents/dev` and `C:/repos`,
then you are responsible for providing that information. There are several methods to do so.
They will be mentioned in other sections. For now, this is where the plugin stores that information:

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
This plugin registers no commands and keybindings. It leaves you 100% control over the modules used.
This might be inconvenient to users, therefore, this section comes with an example configuration 
and several recipes for different workflows.

### Example configuration with packer

The following is the basic scaffolding we will be working with.

```lua
use({
    'gnikdroy/projections.nvim',
    config = function()
        require("projections").setup({})
        -- !!!! YOU PUT YOUR RECIPES HERE !!!!
    end
})
```
### Recipes

#### Using telescope to navigate between projects

The following examples shows how you can use telescope to quickly navigate between projects.
Use `<leader>p` to bring up telescope. **Make sure `telescope` is loaded!**

```lua
-- Telescope setup for projections
require('telescope').load_extension('projections')
vim.keymap.set("n", "<leader>p", function()
    local find_projects = require("telescope").extensions.projections.projections
    find_projects({
        action = function(selection)
            vim.fn.chdir(selection.value) -- this is needed because a session might not be present
            sessions.load_project_session(selection.value)
        end
    })
end, { desc = "Fuzzy search and switch projects" })
```

#### Autosave session

The following `autocmd` autosaves the session if your `cwd` switches (maybe you navigated to a different project), or
if you leave nvim. If combined, with the above section on telescope, you can very rapidly navigate between projects.

```lua
local sessions = require("projections.sessions")

vim.api.nvim_create_autocmd({ 'DirChangedPre', 'VimLeavePre' }, {
    callback = function() sessions.save_project_session(vim.loop.cwd()) end,
    desc = "Save project session",
})
```
#### Manual Session commands

The following lines register two commands `SaveProjectSession` and `LoadProjectSession`.
Both of them save/load the session if `cwd` is a project directory.

```lua
----- Session commands
local sessions = require("projections.sessions")

vim.api.nvim_create_user_command("SaveProjectSession", function()
    sessions.save_project_session(vim.loop.cwd())
end, {})

vim.api.nvim_create_user_command("LoadProjectSession", function()
    sessions.load_project_session(vim.loop.cwd())
end, {})
```

#### Autoload session if in project's directory

The following example loads the project's session
if you launch nvim from project's CWD.

```lua
vim.api.nvim_create_autocmd('VimEnter' , {
    callback = function() sessions.load_project_session(vim.loop.cwd()) end,
    desc = "Autoload project session while launching vim",
})
```

## Telescope plugin

This plugin also ships with a telescope extension to simplify switching between projects.
**This is intended to be the primary method to switch between projects!** So expect the usability of this plugin to be greatly compromised if you don't use [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

*That being said, you can create your own project switcher with the exposed functions.*
