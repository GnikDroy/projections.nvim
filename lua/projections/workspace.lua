local config = require("projections.config").config
local utils = require("projections.utils")
local Project = require("projections.project")
local validators = require("projections.validators")

---@alias Patterns string[] List of patterns

---@class Workspace
---@field path Path Path to workspace
---@field patterns Patterns Patterns in workspace
local Workspace = {}
Workspace.__index = Workspace

---@param a Workspace
---@param b Workspace
---@return boolean
---@nodiscard
function Workspace.__eq(a, b) return a.path == b.path end

-- Constructor
---@param path Path The path to the workspace
---@param patterns Patterns The patterns associated with the workspace
---@return Workspace
---@nodiscard
function Workspace.new(path, patterns)
    local workspace = setmetatable({}, Workspace)

    workspace.path = path
    workspace.patterns = patterns
    return workspace
end

---@alias WorkspaceJSON { path: string, patterns: nil|string[] }

-- Deserialize workspace from table
---@param tbl WorkspaceJSON string or table of values
---@return Workspace
---@nodiscard
function Workspace.deserialize(tbl)
    validators.assert_type({ "table" }, tbl, "Please consult README/wiki for a spec for the format. workspaces -")
    return Workspace.new(Path.new(tbl.path), tbl.patterns)
end

-- Ensures that persistent workspaces file is present
---@return boolean
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
---@return Project[]
---@nodiscard
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
---@return string[]
---@nodiscard
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

-- Checks if given is a project directory in workspace
---@param name string The directory name
---@return boolean
---@nodiscard
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
---@return Workspace[]
---@nodiscard
function Workspace.get_workspaces_from_file()
    local workspaces = {}
    if vim.fn.filereadable(tostring(config.workspaces_file)) == 1 then
        local lines = vim.fn.readfile(tostring(config.workspaces_file))
        if next(lines) == nil then return {} end

        local workspaces_json = vim.fn.json_decode(lines)
        validators.validate_workspaces_json(workspaces_json)

        for _, ws in ipairs(workspaces_json) do
            table.insert(workspaces, Workspace.deserialize(ws))
        end
    end
    workspaces = utils._unique_workspaces(workspaces)
    return workspaces
end

-- Get list of all workspaces from config file
---@return Workspace[]
---@nodiscard
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
---@return Workspace[]
---@nodiscard
function Workspace.get_workspaces()
    local workspaces = Workspace.get_workspaces_from_config()
    for _, ws in ipairs(Workspace.get_workspaces_from_file()) do
        table.insert(workspaces, ws)
    end
    return utils._unique_workspaces(workspaces)
end

-- Add workspace to workspaces file
---@param spath string String representation of path. Can be unnormalized
---@param patterns Patterns The patterns for workspace
---@return boolean
function Workspace.add(spath, patterns)
    local path = Path.new(spath)
    if vim.fn.isdirectory(tostring(path)) == 0 then
        vim.notify("projections: can't add workspace, not a directory", vim.log.levels.ERROR)
        return false
    end

    Workspace._ensure_persistent_file()

    local workspaces = Workspace.get_workspaces_from_file()
    table.insert(workspaces, Workspace.new(path, patterns or config.patterns))
    workspaces = utils._unique_workspaces(workspaces)

    local workspaces_serialized = {}
    for _, ws in ipairs(workspaces) do
        table.insert(workspaces_serialized, { path = tostring(ws.path), patterns = ws.patterns })
    end

    local file = io.open(tostring(config.workspaces_file), "w")
    if file == nil then
        vim.notify("projections: cannot open workspace file", vim.log.levels.ERROR)
        return false
    end
    file:write(vim.json.encode(workspaces_serialized))
    file:close()
    return true
end

return Workspace
