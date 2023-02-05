local M = {}

-- Splits a string at all instances of provided 'separator'
---@param input_string string String to separate
---@param sep string Separator to split on
---@return Table
local split = function(input_string, sep)
  local fields = {}
  local pattern = string.format("([^%s]+)", sep)
  local _ = string.gsub(input_string, pattern, function(c)
    fields[#fields + 1] = c
  end)

  return fields
end

-- Gets a project directory from a session file
---@param filepath string Filepath for session file
---@return string
M.project_dir_from_session_file = function(filepath)
  local session = vim.fn.readfile(filepath)
  -- Directory for session is found on line 6. It is preceded by "cd ", so we take a substring
  local project_dir = string.sub(session[6], 4, -1)
  return project_dir
end

-- Checks if unsaved buffers are present
---@return boolean
---@nodiscard
M._unsaved_buffers_present = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, 'modified') then
            return true
        end
    end
    return false
end

-- Gets number of valid buffers currently open
---@return integer
M._num_valid_buffers = function()
    local get_ls = vim.tbl_filter(function(buf)
        return vim.api.nvim_buf_is_valid(buf)
                and vim.api.nvim_buf_get_option(buf, 'buflisted')
    end, vim.api.nvim_list_bufs())
    return #get_ls
end

-- Calculate fnv1a hash
---@param s string String to hash
---@return integer
---@nodiscard
M._fnv1a = function(s)
    local bit = require("bit")
    local prime = 1099511628211ULL
    local hash = 14695981039346656037ULL
    for i = 1, #s do
        hash = bit.bxor(hash, s:byte(i))
        hash = hash * prime
    end
    return hash
end

-- Returns unique workspaces in list
---@param workspaces Workspace[] List of workspaces
---@return Workspace[]
---@nodiscard
M._unique_workspaces = function(workspaces)
    local hashmap = {}
    local result = {}
    for _, ws in ipairs(workspaces) do
        local hash = tostring(ws.path)
        if not hashmap[hash] then
            result[#result + 1] = ws
            hashmap[hash] = true
        end
    end
    return result
end

return M
