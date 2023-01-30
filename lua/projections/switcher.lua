local Session = require("projections.session")
local Project = require("projections.project")
local utils = require("projections.utils")

---@alias ProjectInfo { path: Path, project: Project }
local initial_project_info = {
  project = "",
  path = "",
}

local M = {}

M._current = initial_project_info;

-- Attempts to return the current active project
----@return ProjectInfo
function M:get_current()
  return self._current;
end

-- Creates a table of all necessary information about a project
-- @param path string Path to the project's root directory
-- @param name string Name of the project
-- return nil | ProjectInfo
---@nodiscard
local create_project_info = function(path, name)
  return name and path and {
    path = path,
    project = name,
  } or nil
end

-- Attempts to switch to the last loaded project
---@return boolean
function M:last()
  local latest_session = Session.latest()
  if latest_session ~= nil then
    local project_dir = utils.project_dir_from_session_file(tostring(latest_session))
    return self:switch(project_dir)
  end
  return false
end

-- Attempts to switch projects and load the session file.
---@param spath string Path to project root
---@return boolean
function M:switch(spath)
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
  self._current = create_project_info(utils.project_name_from_session_filepath(spath))
  if Session.restore(spath) then
    vim.schedule(function() print("Restored session for project: ", spath) end)
  end
  return true
end

return M
