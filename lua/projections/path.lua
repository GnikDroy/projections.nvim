---@class Path
---@field path string String representing full path
---@operator concat(string|Path): Path
Path = {}
Path.__index = Path

-- Return string representing full path
---@param p Path
---@return string
---@nodiscard
function Path.__tostring(p) return p.path end

function Path.__concat(a, b)
    return Path.new(vim.fs.normalize(tostring(a) .. '/' .. tostring(b)))
end

-- Check if paths are equal
---@param a Path
---@param b Path
---@return boolean
---@nodiscard
function Path.__eq(a, b)
    return a.path == b.path or
        not vim.fn.has("fname_case") and string.lower(a.path) == string.lower(b.path)
end

---@param spath string String representing path
---@return Path
---@nodiscard
function Path.new(spath)
    local path = setmetatable({}, Path)

    path.path = vim.fs.normalize(spath)
    return path
end

-- Checks if path is valid file
---@return boolean
---@nodiscard
function Path:is_file()
    return vim.fn.filereadable(self.path) == 1
end

-- Returns basename from path
---@return string
---@nodiscard
function Path:basename()
    return vim.fs.basename(self.path)
end

-- Returns parent of path
---@return Path
---@nodiscard
function Path:parent()
    return Path.new(vim.fn.fnamemodify(self.path, ":h"))
end

-- Gets list of directories in path
-- @returns table List of directory names
function Path:directories()
    local dirs = {}

    -- Check if we can iterate over the directories
    local dir = vim.loop.fs_scandir(tostring(self.path))
    if dir == nil then return dirs end

    -- iterate over workspace and return all directories
    while true do
        local file, type = vim.loop.fs_scandir_next(dir)
        if file == nil then return dirs end
        if type == "directory" then table.insert(dirs, file) end
    end
end

-- Gets list of files (including directories) in path
-- @returns table List of filenames
function Path:files()
    local dirs = {}

    -- Check if we can iterate over the directories
    local dir = vim.loop.fs_scandir(tostring(self.path))
    if dir == nil then return dirs end

    -- iterate over workspace and return all directories
    while true do
        local file, _ = vim.loop.fs_scandir_next(dir)
        if file == nil then return dirs end
        table.insert(dirs, file)
    end
end

return Path
