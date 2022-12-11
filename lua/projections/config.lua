local Path = require("projections.path")

local Config = {}
Config.__index = Config

function Config.new()
    local config = setmetatable({}, Config)
    config.store_hooks = { pre = nil, post = nil }
    config.restore_hooks = { pre = nil, post = nil }
    config.workspaces = {}
    config.patterns = { '.git', '.svn', '.hg' }
    config.ignore_patterns = {}
    config.ignore_dirs = {}
    config.workspaces_file = Path.new(vim.fn.stdpath("data")) .. "projections_workspaces.json"
    config.sessions_directory = Path.new(vim.fn.stdpath("cache")) .. "projections_sessions"
    return config
end

local M = {}
M.config = Config.new()

M.merge = function(conf)
    M.config = vim.tbl_deep_extend("force", M.config, conf)
    -- tbl_deep_extend doesn't copy metatables reliably
    M.config.workspaces_file = setmetatable(M.config.workspaces_file, Path)
    M.config.sessions_directory = setmetatable(M.config.sessions_directory, Path)
end

return M
