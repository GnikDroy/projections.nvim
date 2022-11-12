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

return Path
