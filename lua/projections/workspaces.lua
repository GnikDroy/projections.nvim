local M = {}
M.workspaces_file = vim.fn.stdpath("data") .. "/" .. "projection_workspaces.txt"

local function file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

local function unique(list)
    local hash = {}
    local result = {}
    for _,v in ipairs(list) do
       if not hash[v] then
           result[#result+1] = v
           hash[v] = true
       end
    end
    return result
end

local function create_workspace_file()
    local file = io.open(M.workspaces_file, "a")
    if file ~= nil then file:close() end
end

M.get_workspaces = function()
    if not file_exists(M.workspaces_file) then return {} end
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
    if not file_exists(path) then create_workspace_file() end

    local workspaces = M.get_workspaces()
    table.insert(workspaces, path)
    workspaces = unique(workspaces)

    local file = io.open(M.workspaces_file, "w")
    if file == nil then
        vim.notify("projections: cannot write to workspace file")
        return
    end
    for _, workspace in ipairs(workspaces) do file:write(workspace .. "\n") end
    file:close()
end

return M
