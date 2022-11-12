local utils = require("projections.utils")
local config = require("projections.config")
local Workspace = require("projections.workspace")

local Session = {}
Session.__index = Session

-- Returns the path of the session file
-- Returns nil if path is not a valid project path
-- @returns nil | path of session file
function Session.path(spath)
    -- check if this is some project's session
    local path = Path.new(spath)
    local project_name = path:basename()
    local workspace_path = path:parent()
    local all_workspaces = Workspace.get_workspaces()
    local workspace = nil
    for _, ws in ipairs(all_workspaces) do
        if workspace_path == ws.path then
            workspace = ws
            break
        end
    end
    if workspace == nil or not workspace:is_project(project_name) then return nil end

    local path_hash = utils._fnv1a(tostring(workspace_path))
    local filename = string.format("%s_%u.vim", project_name, path_hash)
    return config.sessions_folder .. filename
end

-- Ensures sessions folder is available
-- @returns if operation was successful
function Session._ensure_sessions_folder()
    return vim.fn.mkdir(tostring(config.sessions_folder), "p") == 1
end

-- Saves the session
-- @returns if operation was successful
function Session.save(spath)
    Session._ensure_sessions_folder()

    local session_path = Session.path(spath)
    if session_path == nil then return false end
    -- TODO: correctly indicate errors here!
    vim.cmd("mksession! " .. tostring(session_path))
    return true
end

-- Attempts to load a session
-- @returns if operation was successful
function Session.load(spath)
    Session._ensure_sessions_folder()

    local session_path = Session.path(spath)
    if session_path == nil or not session_path:is_file() then return false end
    -- TODO: correctly indicate errors here!
    vim.cmd [[
        %bdelete!
        clearjumps
    ]]
    vim.cmd("source " .. tostring(session_path))
    return true
end

return Session
