local Session = require("projections.session")
local Project = require("projections.project")
local utils = require("projections.utils")

local M = {}

M._current = Project;

-- Attempts to return the current active project
----@return ProjectInfo
function M:get_current()
  return self._current;
end

-- Returns whether or not we are currently in a project
function M:in_project()
  return (#tostring(self._current:path()) > 0)
end

-- Attempts to set the current active project, with no args passed, unsets current project
-- @param project_info ProjectInfo table of information about the project to set as the current one
----@return boolean
function M:set_current(project_info)
  if project_info == nil then
    self._current = Project
  else
    self._current = project_info
  end
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
    return self:switch(project_dir)
  end
  return false
end


-- Attempts to switch projects and load the session file.
---@param new_project Project table describing project to switch to
---@return boolean
function M:switch_project(new_project)
  local new_path = vim.fn.expand(tostring(new_project:path()))
  local current_path = vim.fn.expand(tostring(self._current and self._current:path() or Path.new("")))
  if #new_path == 0 or new_path == current_path then return false end

  if utils._unsaved_buffers_present() then
    vim.notify("projections: Unsaved buffers. Unable to switch projects", vim.log.levels.WARN)
    return false
  end

  -- Store current session before moving on to the new project
  if new_path ~= vim.loop.cwd() then
    Session.store(vim.loop.cwd())
  end

  -- Close any existing buffers
  if utils._num_valid_buffers() > 0 then
    vim.cmd [[
          silent! %bdelete
          clearjumps
          ]]
  end

  -- If there's a session for the project we're switching to, attempt to restore it
  local session_info = Session.info(new_path)
  if session_info ~= nil then
    if Session.restore(new_path) then
      vim.schedule(function() vim.notify("[projections.nvim]: Restored session for project - " .. new_project.name, vim.log.levels.INFO) end)
    else
      -- Something went wrong restoring session
      return false
    end
  else
    -- Otherwise, project with no existing session
    -- Update current dir to new project dir
    vim.cmd("noautocmd cd " .. new_path)
  end

  -- Formally set the current project
  self._current = new_project

  return true
end

-- Attempts to switch projects using only a path to the desired project dir
---@param spath string Path to project root
---@return boolean
function M:switch(spath)
    local Workspace = require("projections.workspace")
    -- check if path is some project's root
    local path = Path.new(spath)
    local project_name = path:basename()
    local workspace_path = path:parent()
    local workspace = Workspace.find(workspace_path)
    if workspace == nil or not workspace:is_project(project_name) then return nil end

  return self:switch_project(Project.new(project_name, workspace))
end


return M
