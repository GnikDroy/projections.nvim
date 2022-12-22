local config = require("projections.config").config
local utils = require("projections.utils")
local Project = require("projections.project")
local validators = require("projections.validators")

local Workspace = {}
Workspace.__index = Workspace

function Workspace.__eq(a, b) return a.path == b.path end

-- Constructor
-- @param path The path to the workspace
-- @param patterns The patterns associated with the workspace
function Workspace.new(path, patterns)
    local workspace = setmetatable({}, Workspace)
    validators.autocorrect_patterns(path, patterns)

    workspace.path = path
    workspace.patterns = patterns
    return workspace
end

-- Deserialize workspace from dict
-- @param tbl String | Table of values
-- @returns workspace
function Workspace.deserialize(tbl)
    -- has been configured for { path, patterns }
    if type(tbl) == "table" then
        return Workspace.new(Path.new(tbl.path.path), tbl.patterns)
    end

    -- has been configured for "path"
    if type(tbl) == "string" then
        local patterns = config.patterns
        return Workspace.new(Path.new(tbl), patterns)
    end
    error("projections: deserializing workspaces file failed")
end

-- ensures that persistent workspaces file is present
-- @returns if operation was successful
function Workspace._ensure_persistent_file()
    local file = io.open(tostring(config.workspaces_file), "a")
    if file == nil then
        vim.notify("projections: cannot access workspace file", vim.log.levels.ERROR)
        return false
    end
    file:close()
    return true
end

-- Returns projects in workspace
-- @returns list of projects in workspace
function Workspace:projects()
    local projects = {}

    for _, dir in ipairs(self.path:directories()) do
        if self:is_project(dir) then
            table.insert(projects, Project.new(dir, self))
        end
    end
    return projects
end

-- Checks if given is a project directory in workspace
-- @param name The directory name
-- @returns if it is a project under workspace
function Workspace:is_project(name)
    local project_path = self.path .. name
    for _, filename in ipairs(project_path:files()) do
        for _, pattern in ipairs(self.patterns) do
            if string.match(filename, pattern) ~= nil then
                return true
            end
        end
    end

    -- If patterns is an empty table then unconditionally return true
    return next(self.patterns) == nil
end

-- Get list of all workspaces from persistent file
-- @returns list of workspaces
function Workspace.get_workspaces_from_file()
    local workspaces = {}
    if vim.fn.filereadable(tostring(config.workspaces_file)) == 1 then
        local lines = vim.fn.readfile(tostring(config.workspaces_file))
        if next(lines) == nil then return {} end
        for _, ws in ipairs(vim.fn.json_decode(lines)) do
            table.insert(workspaces, Workspace.deserialize(ws))
        end
    end
    workspaces = utils._unique_workspaces(workspaces)
    validators.validate_workspaces_table(workspaces)
    return workspaces
end

-- Get list of all workspaces from config file
-- @returns list of workspaces
function Workspace.get_workspaces_from_config()
    local workspaces = {}
    for _, ws in ipairs(config.workspaces) do
        -- has been configured for { path, patterns }
        if type(ws) == "table" then
            local path, patterns = unpack(ws)
            table.insert(workspaces, Workspace.new(Path.new(path), patterns))
        end
        -- has been configured for "path"
        if type(ws) == "string" then
            table.insert(workspaces, Workspace.new(Path.new(ws), config.patterns))
        end
    end
    workspaces = utils._unique_workspaces(workspaces)
    return workspaces
end

-- Returns list of all registered workspaces
-- @returns all registered workspaces
function Workspace.get_workspaces()
    local workspaces = Workspace.get_workspaces_from_config()
    for _, ws in ipairs(Workspace.get_workspaces_from_file()) do
        table.insert(workspaces, ws)
    end
    return utils._unique_workspaces(workspaces)
end

-- Add workspace to workspaces file
-- @param spath String representation of path. Can be unnormalized
-- @returns if operation was successful
function Workspace.add(spath)
    local path = Path.new(spath)
    if vim.fn.isdirectory(tostring(path)) == 0 then
        vim.notify("projections: can't add workspace, not a directory", vim.log.levels.ERROR)
        return false
    end

    Workspace._ensure_persistent_file()

    local workspaces = Workspace.get_workspaces_from_file()
    table.insert(workspaces, Workspace.new(path, config.patterns))
    workspaces = utils._unique_workspaces(workspaces)

    local file = io.open(tostring(config.workspaces_file), "w")
    if file == nil then
        vim.notify("projections: cannot open workspace file", vim.log.levels.ERROR)
        return false
    end
    file:write(vim.json.encode(workspaces))
    file:close()
    return true
end

return Workspace
