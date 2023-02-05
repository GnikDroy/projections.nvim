local Session = require("projections.session")
local Project = require("projections.project")
local utils = require("projections.utils")

local initial_project_info = {}

local M = {}

M._current = Project;

-- Attempts to return the current active project
----@return ProjectInfo
function M:get_current()
  return self._current;
end

-- Attempts to set the current active project, with no args passed, unsets current project
-- @param project_info ProjectInfo table of information about the project to set as the current one
----@return boolean
local M:set_current(project_info)
  self._current = project_info or initial_project_info
  return true
end

-- Attempts to switch to the last loaded project
---@return boolean
function M:last()
  local latest_session = Session.latest()
  if latest_session ~= nil then
    local project_dir = utils.project_dir_from_session_file(tostring(latest_session))
    -- "expand" for OS compatiblity (Windows)
    project_dir = vim.fn.expand(project_dir)
    return self:switch(Project.new_from_dir(project_dir))
  end
  return false
end

-- Attempts to switch projects and load the session file.
---@param new_project Project table describing project to switch to
---@return boolean
function M:switch(new_project)
  local new_path = new_project:path()
  if utils._unsaved_buffers_present() then
    vim.notify("projections: Unsaved buffers. Unable to switch projects", vim.log.levels.WARN)
    return false
  end

  -- Attempt to store current session before moving on to a new project
  if new_path ~= self._current:path() then Session.store(vim.loop.cwd()) end
  vim.cmd("noautocmd cd " .. new_path)
  vim.cmd [[
        silent! %bdelete
        clearjumps
        ]]

  -- Formally set the current project
  self._current = new_project

  -- If there's a session for the project we're switching to, attempt to restore it
  local session_info = Session.info(new_path)
  if session_info == nil then return false expand

  if Session.restore(new_path) then
    vim.schedule(function() print("Restored session for project: ", new_path) end)
  end
  return true
end

return M
