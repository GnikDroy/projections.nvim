local utils = require("projections.utils")
local config = require("projections.config").config
local Workspace = require("projections.workspace")
local Project = require("projections.project")

local Session = {}
Session.__index = Session

-- Returns the path of the session file as well as project information
-- Returns nil if path is not a valid project path
-- @args spath The path to project root
-- @returns nil | path of session file and project information
function Session.info(spath)
    -- check if path is some project's root
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
    return {
        path = config.sessions_folder .. filename,
        project = Project.new(project_name, workspace)
    }
end

-- Ensures sessions folder is available
-- @returns if operation was successful
function Session._ensure_sessions_folder()
    return vim.fn.mkdir(tostring(config.sessions_folder), "p") == 1
end

-- Attempts to store the session
-- @args spath String representing the path to the project root
-- @returns if operation was successful
function Session.store(spath)
    Session._ensure_sessions_folder()
    local session_info = Session.info(spath)
    if session_info == nil then return false end
    return Session.store_to_session_file(tostring(session_info.path))
end

-- Attempts to store to session file
-- @args spath String representing the path to the session file
-- @returns if operation was successful
function Session.store_to_session_file(spath)
    if config.store_hooks.pre ~= nil then config.store_hooks.pre() end
    -- TODO: correctly indicate errors here!
    vim.cmd("mksession! " .. spath)
    if config.store_hooks.post ~= nil then config.store_hooks.post() end
    return true
end

-- Attempts to restore a session
-- @args spath String representing the path to the project root
-- @returns if operation was successful
function Session.restore(spath)
    Session._ensure_sessions_folder()
    local session_info = Session.info(spath)
    if session_info == nil or not session_info.path:is_file() then return false end
    return Session.restore_from_session_file(tostring(session_info.path))
end

-- Attempts to restore a session from session file
-- @args spath String representing path to session file
-- @returns if operation was successful
function Session.restore_from_session_file(spath)
    if config.restore_hooks.pre ~= nil then config.restore_hooks.pre() end
    -- TODO: correctly indicate errors here!
    vim.cmd("source " .. spath)
    if config.restore_hooks.post ~= nil then config.restore_hooks.post() end
    return true
end

-- Get latest session
-- @returns nil | path to latest session
function Session.latest()
    local latest_session = nil
    local latest_timestamp = 0

    for _, filename in ipairs(vim.fn.readdir(tostring(config.sessions_folder))) do
        local session = config.sessions_folder .. filename
        local timestamp = vim.fn.getftime(tostring(session))
        if timestamp > latest_timestamp then
            latest_session = session
            latest_timestamp = timestamp
        end
    end
    return latest_session
end

-- Restore latest session
-- @returns if operation was successful
function Session.restore_latest()
    local latest_session = Session.latest()
    if latest_session == nil then return false end
    return Session.restore_from_session_file(tostring(latest_session))
end

return Session
