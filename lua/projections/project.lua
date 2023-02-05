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

-- Alternate constructor (using a given project dir)
---@param dir_path string Full path for session file
---@return Project
---@nodiscard
function Project.new_from_dir(dir_path)
    local path = Path.new(dir_path)
    local name = path:basename()
    local workspace = require("projections.workspace").new(path:parent())
    local project = setmetatable({}, Project)
    project.name = name
    project.workspace = workspace
    return project
end

-- Returns the path to the project
---@return Path
---@nodiscard
function Project:path()
    if not self.workspace or not self.name then return Path.new("") end
    return self.workspace.path .. self.name
end

return Project
