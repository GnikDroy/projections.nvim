local M = {}

M.setup = function(conf)
    local config = require("projections.config")
    config.set_config(vim.tbl_deep_extend("force", config.get_config(), conf))
end

return M
