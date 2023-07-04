local Path = require("projections.path")

---@class Config
---@field store_hooks HookGroup
---@field restore_hooks HookGroup
---@field workspaces WorkspaceUser
---@field default_patterns Patterns
---@field workspaces_file Path
---@field sessions_directory Path
---@field selector_mapping string?
---@field auto_restore boolean
---@field show_preview boolean
local Config = {}
Config.__index = Config

-- Constructor
---@return Config
---@nodiscard
function Config.new()
    local config = setmetatable({}, Config)
    local data_path = vim.fn.stdpath("data") --[[@as string]]
    local cache_path = vim.fn.stdpath("cache") --[[@as string]]
    config.store_hooks = { pre = nil, post = nil }
    config.restore_hooks = { pre = nil, post = nil }
    config.workspaces = {}
    config.default_patterns = { ".git", ".svn", ".hg" }
    config.workspaces_file = Path.new(data_path) .. "projections_workspaces.json"
    config.sessions_directory = Path.new(cache_path) .. "projections_sessions"
    config.selector_mapping = "<leader>fp"
    config.auto_restore = false
    config.show_preview = false
    return config
end

local M = {}
M.config = Config.new()

-- Merge config with existing config
---@param conf ConfigUser
---@return Config
M.merge = function(conf)
    if conf.workspaces_file ~= nil then
        M.config.workspaces_file = Path.new(conf.workspaces_file)
        conf.workspaces_file = nil
    end
    if conf.sessions_directory ~= nil then
        M.config.sessions_directory = Path.new(conf.sessions_directory)
        conf.sessions_directory = nil
    end
    M.config = vim.tbl_deep_extend("force", M.config, conf)
    -- tbl_deep_extend doesn't copy metatables reliably
    M.config.workspaces_file = setmetatable(M.config.workspaces_file, Path)
    M.config.sessions_directory = setmetatable(M.config.sessions_directory, Path)
    return M.config
end

return M
