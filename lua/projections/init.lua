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
    return M.config
end

return M
