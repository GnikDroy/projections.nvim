local Session = require("projections.session")
local utils = require("projections.utils")

local M = {}

-- Attempts to switch projects and load the session file.
-- @args spath String representing path to project root
-- @returns if operation was successful
M.switch = function(spath)
    if utils._unsaved_buffers_present() then
        vim.notify("projections: Unsaved buffers. Unable to switch projects", vim.log.levels.WARN)
        return false
    end

    local session_info = Session.info(spath)
    if session_info == nil then return false end

    if vim.loop.cwd() ~= spath then Session.store(vim.loop.cwd()) end
    vim.cmd("noautocmd cd " .. spath)
    vim.cmd [[
        silent! %bdelete
        clearjumps
    ]]
    Session.restore(spath)
    return true
end

return M
