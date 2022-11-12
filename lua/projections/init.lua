local config = require("projections.config")

local M = {}

M.setup = function(conf)
    config:merge(conf)
end

return M
