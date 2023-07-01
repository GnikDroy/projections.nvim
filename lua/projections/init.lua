local Config = require("projections.config")
local Workspace = require("projections.workspace")
local validators = require("projections.validators")
local Session = require("projections.session")

local M = {}

---@alias Hook function?
---@alias HookGroup { pre: Hook, post: Hook }

---@alias WorkspaceUser { path: string, patterns: string[]? }

---@class ConfigUser
---@field store_hooks HookGroup?
---@field restore_hooks HookGroup?
---@field workspaces WorkspaceUser[]?
---@field default_patterns Patterns?
---@field workspaces_file string?
---@field sessions_directory string?
---@field selector_mapping string?
---@field auto_restore boolean?

-- Launch the projections project switcher
function M.launch()
    local telescope_present, telescope = pcall(require, "telescope")
    if telescope_present then
        telescope.extensions.projections.projections()
    else
        vim.notify("projections: quickfix implementation is not ready")
    end
end

-- Setup projections (with side-effects)
---@param conf Config
---@return Config
local function _setup(conf)
    if conf.selector_mapping ~= nil then
        vim.keymap.set("n", conf.selector_mapping, M.launch, { desc = "projections: find projects" })
    end

    vim.api.nvim_create_augroup("projections.nvim", {})
    vim.api.nvim_create_autocmd({ 'VimLeavePre' }, {
        group = "projections.nvim",
        desc = "Autostore session on VimLeave",
        callback = function() Session.store(vim.fn.getcwd()) end,
    })

    if conf.auto_restore then
        -- If vim was started with arguments, do nothing
        -- If in some project's root, attempt to restore that project's session
        -- If not, restore last session
        -- If no sessions, do nothing
        vim.api.nvim_create_autocmd({ "VimEnter" }, {
            group = "projections.nvim",
            callback = function()
                if vim.fn.argc() ~= 0 then return end
                local session_info = Session.info(vim.fn.getcwd())
                if session_info == nil then
                    Session.restore_latest()
                else
                    Session.restore(vim.fn.getcwd())
                end
            end,
            desc = "Restore last session automatically"
        })
    end

    -- Add workspace command
    vim.api.nvim_create_user_command("ProjectionsAddWorkspace", function(opts)
        local nargs = #opts.fargs
        if nargs == 0 then
            Workspace.add(vim.fn.getcwd(), Config.config.default_patterns)
        elseif nargs == 1 then
            Workspace.add(opts.args, Config.config.default_patterns)
        else
            vim.api.nvim_err_writeln("ProjectionsAddWorkspace command takes at most 1 argument")
        end
    end, {
        desc = "projections: add workspace to workspaces.json file",
        nargs = "*",
    })

    return conf
end

-- Setup projections
---@param conf ConfigUser
---@return Config
M.setup = function(conf)
    validators.validate_user_config(conf)
    Config.merge(conf)
    validators.validate_config(Config.config)
    return _setup(Config.config)
end

return M
