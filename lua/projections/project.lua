local Path = require("projections.path")
local utils = require("projections.utils")
local config = require("projections.config").config
local validators = require("projections.validators")

---@class Project
---@field name string Name of the project
---@field workspace Workspace Workspace project is from
local Project = {}
Project.__index = Project

-- Constructor
---@param name string Name of the project
---@param workspace Workspace The workspace of the project
---@return Project
---@nodiscard
function Project.new(name, workspace)
    local project = setmetatable({}, Project)
    project.name = name
    project.workspace = workspace
    return project
end

-- Returns the path to the project
---@return Path
---@nodiscard
function Project:path()
    return self.workspace.path .. self.name
end

---@alias ProjectJSON { name: string, workspace: string }

-- Deserialize project from table
---@param tbl ProjectJSON string or table of values
---@return Project
---@nodiscard
function Project.deserialize(tbl)
    local Workspace = require("projections.workspace")

    validators.assert_type(
      { "table" },
      tbl,
      "Please consult README/wiki for a spec for the format. projects -"
    )
    return Project.new(tbl.name, Workspace.new(Path.new(tbl.workspace), {}))
end

-- Ensure that persistent projects file is present
-- @return boolean
function Project._ensure_persistent_file()
    local file = io.open(tostring(config.projects_file), "a")
    if file == nil then
        vim.notify("projections: cannot access projects file", vim.log.levels.ERROR)
        return false
    end
    file:close()
    return true
end

function Project.get_projects()
    local projects = {}
    if vim.fn.filereadable(tostring(config.projects_file)) == 1 then
        local lines = vim.fn.readfile(tostring(config.projects_file))
        if next(lines) == nil then
            return {}
        end

        local projects_json = vim.fn.json_decode(lines)
        validators.validate_projects_json(projects_json)

        for _, proj in ipairs(projects_json) do
            table.insert(projects, Project.deserialize(proj))
        end
    end

    return projects
end

function Project.add(spath)
    local Workspace = require("projections.workspace")

    local path = Path.new(spath)
    if vim.fn.isdirectory(tostring(path)) == 0 then
        vim.notify(
            "projections: can't add project, not a directory",
            vim.log.levels.ERROR
        )
        return false
    end

    Project._ensure_persistent_file()

    local projects = Project.get_projects()
    table.insert(
        projects,
        Project.new(
            path:basename(),
            Workspace.new(
                Path.new(tostring(path:parent())), {}
            )
        )
    )
    projects = utils._unique_projects(projects)

    local projects_serialized = {}
    for _, project in ipairs(projects) do
        table.insert(
            projects_serialized,
            { name = tostring(project.name), workspace = tostring(project.workspace.path) }
        )
    end

    local file = io.open(tostring(config.projects_file), "w")
    if file == nil then
        vim.notify("projections: cannot open projects file", vim.log.levels.ERROR)
        return false
    end
    file:write(vim.json.encode(projects_serialized))
    file:close()
    return true
end

return Project
