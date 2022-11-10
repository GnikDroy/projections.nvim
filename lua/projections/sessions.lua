local projects = require("projections.projects")

local M = {}
M.sessions_folder = vim.fs.normalize(vim.fn.stdpath("cache") .. "/" .. "projection_sessions")

M.save_project_session = function()
    local cwd = vim.loop.cwd()
    if not projects.is_project_dir(cwd) then return false end

    vim.fn.mkdir(M.sessions_folder, "p")

    -- TODO: add path hash to filename
    local session_path = vim.fs.normalize(M.sessions_folder .. "/" .. vim.fs.basename(cwd) .. ".vim")
    vim.cmd(string.format("mksession! %s", session_path))
    return true
end

M.load_project_session = function(path)
    if not projects.is_project_dir(path) then return end

    vim.fn.mkdir(M.sessions_folder, "p")

    -- TODO: add path hash to filename
    local session_path = vim.fs.normalize(M.sessions_folder .. "/" .. vim.fs.basename(path) .. ".vim")
    if vim.fn.filereadable(session_path) == 0 then return false end

    vim.cmd[[
        %bdelete!
        clearjumps
    ]]
    vim.cmd(string.format("source %s", session_path))
    return true
end

return M
