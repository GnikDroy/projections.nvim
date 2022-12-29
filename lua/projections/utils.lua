local M = {}

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
