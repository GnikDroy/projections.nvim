local M = {}
local config = {
    workspaces = {},
    patterns = { '.git', '.svn', '.hg' },
}


M.set_config = function(conf)
    config = conf
end

M.get_config = function()
    return config
end

return M
