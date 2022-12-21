local config = require("projections.config")
local Path = require("projections.path")
local validators = require("projections.validators")

local M = {}

M.setup = function(conf)
    validators.validate_config(conf)
    if conf.workspaces_file ~= nil then
        conf.workspaces_file = Path.new(conf.workspaces_file)
    end
    if conf.sessions_directory ~= nil then
        conf.sessions_directory = Path.new(conf.sessions_directory)
    end
    config.merge(conf)
    validators.validate_merged_config(config.config)
end

return M
