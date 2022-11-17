local telescope = require("telescope")
local entry_display = require("telescope.pickers.entry_display")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values

local function project_finder(_)
    local workspaces = require("projections.workspace").get_workspaces()
    local projects = {}
    for _, ws in ipairs(workspaces) do
        for _, project in ipairs(ws:projects()) do
            table.insert(projects, project)
        end
    end

    local display = entry_display.create({
        items = { { width = 35 }, { remaining = true } },
        separator = " ",
    })

    return finders.new_table({
        results = projects,
        entry_maker = function(project)
            return {
                display = function(e) return display({ e.name, { e.value, "Comment" } }) end,
                name = project.name,
                value = tostring(project:path()),
                ordinal = tostring(project:path()),
            }
        end,
    })
end

local find_projects = function(opts)
    local switcher = require("projections.switcher")
    opts = opts or {}
    pickers.new(opts, {
        prompt_title = "Projects",
        finder = project_finder(opts),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                if opts.action == nil then
                    opts.action = function(selected) switcher.switch(selected.value) end
                end
                opts.action(selection)
            end)
            return true
        end,
    }):find()
end

return telescope.register_extension({
    setup = function(_, _) end,
    exports = { projections = find_projects },
})
