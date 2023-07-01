local M = {}

function M.check()
    vim.health.start("projections.nvim")
    local telescope_present, _ = pcall(require, "telescope")
    if telescope_present then
        vim.health.ok("Found telescope")
    else
        vim.health.warn("Telescope is not found. Projections will use the quickfix list.")
    end
end

return M
