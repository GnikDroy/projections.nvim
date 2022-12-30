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

return Project
