local NOREF_NOERR_TRUNC = { noremap = true, silent = true, nowait = true }
local NOREF_NOERR = { noremap = true, silent = true }
local EXPR_NOREF_NOERR_TRUNC = { expr = true, noremap = true, silent = true, nowait = true }
local M = {}

M.projects = function(workspaces, opts)
  if workspaces == nil then
    workspaces = require('projections.workspace').get_workspaces()
  end

  local paths_all_pjs = {}

  for _, ws in ipairs(workspaces) do
    for _, pj in ipairs(ws:projects()) do
      local path_pj = tostring(pj:path())
      paths_all_pjs[#paths_all_pjs+1] = path_pj
    end
  end

  opts = opts or {}
  opts.prompt = 'Projections> '
  opts.actions = {
    ['default'] = function(selected)
      require('projections.switcher').switch(selected[1])
    end
  }

  table.sort(paths_all_pjs, function(a, b) return a:lower() < b:lower() end)
  require('fzf-lua').fzf_exec(paths_all_pjs, opts)
end

return M
