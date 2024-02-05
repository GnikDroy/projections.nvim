local utils     = require("projections.utils")
local Config    = require("projections.config")
local Workspace = require("projections.workspace")
local Project   = require("projections.project")

local Session   = {}
Session.__index = Session

---@alias SessionInfo { path: Path, project: Project }

-- Returns the path of the session file as well as project information
-- Returns nil if path is not a valid project path
---@param spath string The path to project root
---@return SessionInfo?
---@nodiscard
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

    local filename = Session.session_filename(tostring(workspace_path), project_name)
    return {
        path = Config.config.sessions_directory .. filename,
        project = Project.new(project_name, workspace)
    }
end

-- Returns the session filename for project
---@param workspace_path string The path to workspace
---@param project_name string Name of project
---@return string
---@nodiscard
function Session.session_filename(workspace_path, project_name)
    local path_hash = utils._fnv1a(workspace_path)
    return string.format("%s_%u.vim", project_name, path_hash)
end

-- Ensures sessions directory is available
---@return boolean
function Session._ensure_sessions_directory()
    return vim.fn.mkdir(tostring(Config.config.sessions_directory), "p") == 1
end

-- Attempts to store the session
---@param spath string Path to the project root
---@return boolean
function Session.store(spath)
    Session._ensure_sessions_directory()
    local session_info = Session.info(spath)
    if session_info == nil then return false end
    return Session.store_to_session_file(tostring(session_info.path))
end

-- Attempts to store to session file
---@param spath string Path to the session file
---@returns boolean
function Session.store_to_session_file(spath)
    vim.api.nvim_exec_autocmds("User", { pattern = "ProjectionsPreStoreSession" })
    local ret, _ = pcall(vim.cmd.mksession, { vim.fn.fnameescape(spath), bang = true })
    if not ret then return false end
    vim.api.nvim_exec_autocmds("User", { pattern = "ProjectionsPostStoreSession" })
    return true
end

-- Attempts to restore a session
---@param spath string Path to the project root
---@return boolean
function Session.restore(spath)
    Session._ensure_sessions_directory()
    local session_info = Session.info(spath)
    if session_info == nil or not session_info.path:is_file() then return false end
    return Session.restore_from_session_file(tostring(session_info.path))
end

-- Attempts to restore a session from session file
---@param spath string Path to session file
---@return boolean
function Session.restore_from_session_file(spath)
    vim.api.nvim_exec_autocmds("User", { pattern = "ProjectionsPreRestoreSession" })
    local ret, _ = pcall(vim.cmd.source, vim.fn.fnameescape(spath))
    if not ret then return false end
    vim.api.nvim_exec_autocmds("User", { pattern = "ProjectionsPostRestoreSession" })
    return true
end

-- Get latest session
---@return Path?
---@nodiscard
function Session.latest()
    local latest_session = nil
    local latest_timestamp = 0

    for _, filename in ipairs(vim.fn.readdir(tostring(Config.config.sessions_directory))) do
        local session = Config.config.sessions_directory .. filename
        local timestamp = vim.fn.getftime(tostring(session))
        if timestamp > latest_timestamp then
            latest_session = session
            latest_timestamp = timestamp
        end
    end
    return latest_session
end

-- Restore latest session
---@return boolean
function Session.restore_latest()
    local latest_session = Session.latest()
    if latest_session == nil then return false end
    return Session.restore_from_session_file(tostring(latest_session))
end

return Session

