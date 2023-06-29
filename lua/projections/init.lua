local config = require("projections.config")
local validators = require("projections.validators")

local M = {}

---@alias Hook function|nil
---@alias HookGroup { pre: Hook, post: Hook }

---@class ConfigUser
---@field store_hooks HookGroup|nil
---@field restore_hooks HookGroup|nil
---@field workspaces table|nil
---@field patterns Patterns|nil
---@field workspaces_file string|nil
---@field sessions_directory string|nil

-- Setup projections
---@param conf ConfigUser
---@return Config
M.setup = function(conf)
    validators.validate_user_config(conf)
    config.merge(conf)
    validators.validate_config(config.config)

    vim.defer_fn(
        function()
            vim.notify(
                table.concat(
                    {
                        "Projections is getting ready for a major release.",
                        "",
                        "For more details:",
                        "www.github.com/GnikDroy/projections.nvim/issues/42",
                        "",
                        "You can suppress this message by",
                        "switching to the 'pre_release' branch",
                    }, "\n"
                ), vim.log.levels.INFO)
        end,
        5000
    )
    return M.config
end

return M
