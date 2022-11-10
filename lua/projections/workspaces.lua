local config = require("projections.config")
local utils = require("projections.utils")

local M = {}

M.workspaces_file = vim.fn.stdpath("data") .. "/" .. "projections_workspaces.txt"

-- creates workspace file if not present
local function create_workspaces_file()
    local file = io.open(M.workspaces_file, "a")
    if file ~= nil then file:close() end
end

-- get list of all configured workspaces
M.get_workspaces = function()
    local workspaces = {}
    if utils._file_exists(M.workspaces_file) then
        for ws in io.lines(M.workspaces_file) do
            workspaces[#workspaces + 1] = vim.fs.normalize(ws)
        end
    end

    local default_workspaces = config.get_config().workspaces
    for _, ws in ipairs(default_workspaces) do table.insert(workspaces, vim.fs.normalize(ws)) end
    workspaces = utils._unique(workspaces)
    return workspaces
end

-- add workspace to workspaces file
M.add_workspace = function(path)
    path = vim.fs.normalize(path)
    if vim.fn.isdirectory(path) == 0 then
        vim.notify("projections: cannot add workspace, not a directory")
        return
    end
    if not utils._file_exists(path) then create_workspaces_file() end

    local workspaces = M.get_workspaces()
    table.insert(workspaces, path)
    workspaces = utils._unique(workspaces)

    local file = io.open(M.workspaces_file, "w")
    if file == nil then
        vim.notify("projections: cannot write to workspace file")
        return
    end
    for _, workspace in ipairs(workspaces) do file:write(workspace .. "\n") end
    file:close()
end

return M
