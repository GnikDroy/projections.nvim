local Project = {}
Project.__index = Project

-- Constructor
-- @param name Name of the project
-- @param workspace The workspace of the project
function Project.new(name, workspace)
    local project = setmetatable({}, Project)
    project.name = name
    project.workspace = workspace
    return project
end

-- Returns the path to the project
-- @returns path to project
function Project:path()
    return self.workspace.path .. self.name
end

return Project
