local config = require("projections.config")

local M = {}

-- gets list of files in directory
local function get_files(path)
    local dirs = {}

    local dir = vim.loop.fs_scandir(path)
    if dir == nil then return dirs end

    while true do
        local file = vim.loop.fs_scandir_next(dir)
        if file == nil then return dirs end
        table.insert(dirs, file)
    end
end

-- checks if path contains files/directory specified in patterns
local function contains_pattern(path, patterns)
    for _, pattern in ipairs(patterns) do
        local f = vim.fs.normalize(path .. "/" .. pattern)
        if vim.fn.isdirectory(f) == 1 or vim.fn.filereadable(f) == 1 then
            return true
        end
    end
    return false
end

-- Returns normalized project paths from a workspace
M.get_workspace_projects = function (workspace_path)
    local projects = {}
    local patterns = config.get_config().patterns
    for _, dir in ipairs(get_files(workspace_path)) do
        if contains_pattern(workspace_path .. "/" .. dir, patterns) then
            table.insert(projects, workspace_path .. "/" .. dir)
        end
    end
    return projects
end

-- Returns normalized project paths from all workspaces
M.get_projects = function()
    local results = {}
    local workspaces = require("projections.workspaces").get_workspaces()

    for _, workspace in ipairs(workspaces) do
        for _, project in ipairs(M.get_workspace_projects(vim.fn.expand(workspace))) do
            table.insert(results, vim.fs.normalize(project))
        end
    end
    return results
end

-- check if given path is a project root
M.is_project_dir = function(path)
    path = vim.fs.normalize(path)
    local projects = M.get_projects()
    for _, dir in ipairs(projects) do
        if dir == path then return true end
    end
    return false
end

return M
