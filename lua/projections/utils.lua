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

return M
