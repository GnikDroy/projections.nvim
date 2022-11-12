local config = require("projections.config")
local utils = require("projections.utils")
local Project = require("projections.project")

local Workspace = {}
Workspace.__index = Workspace

function Workspace.__eq(a, b) return a.path == b.path end

-- Constructor
-- @param path The path to the workspace
-- @param patterns The patterns associated with the workspace
function Workspace.new(path, patterns)
    local workspace = setmetatable({}, Workspace)

    workspace.path = path
    workspace.patterns = patterns
    return workspace
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

    for _, dir in ipairs(self:directories()) do
        if self:is_project(dir) then
            table.insert(projects, Project.new(dir, self))
        end
    end
    return projects
end

-- Gets list of directories in the workspace
-- @returns table List of name of directories
function Workspace:directories()
    local dirs = {}

    -- Check if we can iterate over the directories
    local dir = vim.loop.fs_scandir(tostring(self.path))
    if dir == nil then return dirs end

    -- iterate over workspace and return all directories
    while true do
        local file, type = vim.loop.fs_scandir_next(dir)
        if file == nil then return dirs end
        if type == "directory" then table.insert(dirs, file) end
    end
end

-- Checks if given is a project folder in workspace
-- @param name The folder name
-- @returns if it is a project under workspace
function Workspace:is_project(name)
    for _, pattern in ipairs(self.patterns) do
        local f = (self.path .. name) .. pattern
        if vim.fn.isdirectory(tostring(f)) == 1 or
            vim.fn.filereadable(tostring(f)) == 1 then
            return true
        end
    end

    -- If patterns is empty table then, select every subdirectory is a project
    return next(self.patterns) == nil
end

-- Get list of all workspaces from persistent file
-- @returns list of workspaces
function Workspace.get_workspaces_from_file()
    local workspaces = {}
    if vim.fn.filereadable(tostring(config.workspaces_file)) == 1 then
        for spath in io.lines(tostring(config.workspaces_file)) do
            local workspace = Workspace.new(Path.new(spath), config.patterns)
            table.insert(workspaces, workspace)
        end
    end
    workspaces = utils._unique_workspaces(workspaces)
    return workspaces
end

-- Get list of all workspaces from config file
-- @returns list of workspaces
function Workspace.get_workspaces_from_config()
    local workspaces = {}
    for _, ws in ipairs(config.workspaces) do
        -- has been configured for { path, patterns }
        if type(ws) == "table" then
            local spath, patterns = unpack(ws)
            local workspace = Workspace.new(Path.new(spath), patterns)
            table.insert(workspaces, workspace)
        end

        -- has been configured for "path"
        if type(ws) == "string" then
            local spath = ws
            local patterns = config.patterns
            table.insert(workspaces, Workspace.new(Path.new(spath), patterns))
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
    table.insert(workspaces, path)
    workspaces = utils._unique_workspaces(workspaces)

    local file = io.open(tostring(config.workspaces_file), "w")
    if file == nil then
        vim.notify("projections: cannot open workspace file", vim.log.levels.ERROR)
        return false
    end
    for _, workspace in ipairs(workspaces) do file:write(tostring(workspace.path) .. "\n") end
    file:close()
    return true
end

return Workspace
