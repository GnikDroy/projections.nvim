local M = {}
M.workspaces_file = vim.fn.stdpath("data") .. "/" .. "projection_workspaces.txt"

local utils = require("projections.utils")

local function create_workspace_file()
    local file = io.open(M.workspaces_file, "a")
    if file ~= nil then file:close() end
end

M.get_workspaces = function()
    if not utils._file_exists(M.workspaces_file) then return {} end
    local workspaces = {}
    for workspace in io.lines(M.workspaces_file) do
        workspaces[#workspaces + 1] = workspace
    end
    return workspaces
end

M.add_workspace = function(path)
    path = vim.fs.normalize(path)
    if vim.fn.isdirectory(path) == 0 then
        vim.notify("projections: cannot add workspace, not a directory")
        return
    end
    if not utils._file_exists(path) then create_workspace_file() end

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
