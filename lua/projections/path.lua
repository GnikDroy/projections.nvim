Path = {}
Path.__index = Path

function Path.__tostring(p) return p.path end

function Path.__concat(a, b)
    return Path.new(vim.fs.normalize(tostring(a) .. '/' .. tostring(b)))
end

function Path.__eq(a, b)
    return a.path == b.path
end

-- Path constructor
-- @param spath String representation of the path. Can be unnormalized.
function Path.new(spath)
    local path = setmetatable({}, Path)

    path.path = vim.fs.normalize(spath)
    return path
end

-- Checks if path is valid file
-- @returns if file
function Path:is_file()
    return vim.fn.filereadable(self.path) == 1
end

-- Returns basename from path
-- @returns basename
function Path:basename()
    return vim.fs.basename(self.path)
end

-- Returns parent of path
-- @returns parent path
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
