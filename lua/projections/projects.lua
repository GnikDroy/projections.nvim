local M = {}

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

local function contains_pattern(path, patterns)
    for _, file in ipairs(get_files(path)) do
        for _, pattern in ipairs(patterns) do
            if string.match(file, pattern) then
                return true
            end
        end
    end
    return false
end

M.get_workspace_projects = function (workspace_path, patterns)
    local projects = {}
    for _, dir in ipairs(get_files(workspace_path)) do
        if contains_pattern(workspace_path .. "/" .. dir, patterns) then
            table.insert(projects, workspace_path .. "/" .. dir)
        end
    end
    return projects
end

M.get_projects = function()
    local results = {}
    local workspaces = require("projections.workspaces").get_workspaces()
    local patterns = require("projections.config").get_config().patterns
    for _, workspace in ipairs(workspaces) do
        for _, project in ipairs(M.get_workspace_projects(vim.fn.expand(workspace), patterns)) do
            table.insert(results, vim.fs.normalize(project))
        end
    end
    return results
end

M.is_project_dir = function(path)
    path = vim.fs.normalize(path)
    local projects = M.get_projects()
    for _, dir in ipairs(projects) do
        if dir == path then return true end
    end
    return false
end

return M
