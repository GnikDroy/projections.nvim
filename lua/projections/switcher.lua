local M = {}
local Session = require("projections.session")
local utils = require("projections.utils")

-- Attempts to switch projects and load the session file.
-- The quiet version doesn't make any vim.notify calls
---@param path string Path to project root
function M.switch_quiet(path)
    if utils._unsaved_buffers_present() then
        error("projections: Unsaved buffers. Unable to switch projects")
    end

    if Session.info(path) == nil then
        error(string.format("projections: '%s' is not a valid project path", path))
    end

    local cwd = vim.fn.getcwd()
    if path ~= cwd then
        Session.store(cwd)
    end

    vim.cmd("silent! %bdelete")

    local ret = Session.restore(path)
    if not ret then vim.cmd.cd(path) end
    return ret
end

-- Attempts to switch projects and load the session file.
---@param path string Path to project root
---@return boolean
function M.switch(path)
    local ok, ret = pcall(M.switch_quiet, path)
    if not ok then
        local err = ret --[[@as string]]
        vim.notify(err, vim.log.levels.WARN)
    end
    return ok
end

return M
