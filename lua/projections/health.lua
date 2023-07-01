local M = {}

function M.check()
    vim.health.start("projections.nvim")
    local telescope_present, _ = pcall(require, "telescope")
    if telescope_present then
        vim.health.ok("Found telescope")
    else
        vim.health.warn("Telescope not found.")
    end
end

return M
