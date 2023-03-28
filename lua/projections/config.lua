local Path = require("projections.path")

---@class Config
---@field store_hooks HookGroup
---@field restore_hooks HookGroup
---@field workspaces table
---@field patterns Patterns
---@field workspaces_file Path
---@field projects_file Path
---@field sessions_directory Path
---@field skip_session_check boolean
local Config = {}
Config.__index = Config

-- Constructor
---@return Config
---@nodiscard
function Config.new()
    local config = setmetatable({}, Config)
    config.store_hooks = { pre = nil, post = nil }
    config.restore_hooks = { pre = nil, post = nil }
    config.workspaces = {}
    config.patterns = { '.git', '.svn', '.hg' }
    config.workspaces_file = Path.new(vim.fn.stdpath("data")) .. "projections_workspaces.json"
    config.projects_file = Path.new(vim.fn.stdpath("data")) .. "projections_projects.json"
    config.sessions_directory = Path.new(vim.fn.stdpath("cache")) .. "projections_sessions"
    config.skip_session_check = false

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
    if conf.projects_file ~= nil then
        M.config.projects_file = Path.new(conf.projects_file)
        conf.projects_file = nil
    end
    if conf.sessions_directory ~= nil then
        M.config.sessions_directory = Path.new(conf.sessions_directory)
        conf.sessions_directory = nil
    end
    M.config = vim.tbl_deep_extend("force", M.config, conf)
    -- tbl_deep_extend doesn't copy metatables reliably
    M.config.workspaces_file = setmetatable(M.config.workspaces_file, Path)
    M.config.projects_file = setmetatable(M.config.projects_file, Path)
    M.config.sessions_directory = setmetatable(M.config.sessions_directory, Path)

    return M.config
end

return M
