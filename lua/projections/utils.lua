local M = {}

M._file_exists = function(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

M._unique = function(list)
    local hash = {}
    local result = {}
    for _, v in ipairs(list) do
        if not hash[v] then
            result[#result + 1] = v
            hash[v] = true
        end
    end
    return result
end

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

return M
