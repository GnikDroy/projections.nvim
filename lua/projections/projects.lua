local utils = require("projections.utils")
local config = require("projections.config")

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
    for _, pattern in ipairs(patterns) do
        local f = vim.fs.normalize(path .. "/" .. pattern)
        if vim.fn.isdirectory(f) == 1 or vim.fn.filereadable(f) == 1 then
            return true
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
    local default_workspaces = config.get_config().workspaces
    for _, ws in ipairs(default_workspaces) do table.insert(workspaces, ws) end
    workspaces = utils._unique(workspaces)

    local patterns = config.get_config().patterns
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
