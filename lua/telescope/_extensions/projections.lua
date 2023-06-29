local telescope = require("telescope")
local entry_display = require("telescope.pickers.entry_display")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local previewers = require('telescope.previewers')

local function make_project_sorter()
    -- Sort by recent implemented by
    -- hooking into the default scoring function, of generic_sorter
    -- we check if prompt is empty, if so, score by file modification time (inverted)
    -- if prompt is not empty, use the default scoring function
    local config = require("projections.config").config
    local Session = require("projections.session")
    local sorter = conf.generic_sorter(opts)
    local default_scoring_function = sorter.scoring_function
    sorter.scoring_function = function(_sorter, prompt, line, ...)
        if prompt == '' then
            local session_filename = Session.session_filename(vim.fn.fnamemodify(line, ":h"), vim.fs.basename(line))
            return 1 / math.abs(vim.fn.getftime(tostring(config.sessions_directory .. session_filename)))
        end
        return default_scoring_function(_sorter, prompt, line, ...)
    end
    return sorter
end

local function make_project_previewer()
    local command = { "ls", "-lhA", "--color=auto" }
    if vim.fn.executable('lsd') == 1 then
        command = { "lsd", "-lhA" }
    elseif vim.fn.executable('exa') == 1 then
        command = { "exa", "-lha" }
    end

    return previewers.new_termopen_previewer({
        get_command = function(entry, _)
            table.insert(command, entry.value)
            return command
        end
    })
end

local function project_finder(opts)
    local workspaces = require("projections.workspace").get_workspaces()
    local projects = {}
    for _, ws in ipairs(workspaces) do
        for _, project in ipairs(ws:projects()) do
            table.insert(projects, project)
        end
    end

    return finders.new_table({
        results = projects,
        entry_maker = opts.entry_maker or function(project)
            return {
                display = function(e)
                    local display = entry_display.create({
                        items = { { width = 35 }, { remaining = true } },
                        separator = " ",
                    })
                    return display({ e.name, { e.value, "Comment" } })
                end,
                name = project.name,
                value = tostring(project:path()),
                ordinal = tostring(project:path()),
            }
        end,
    })
end

local find_projects = function(opts)
    opts = opts or {}
    opts.sorter = opts.sorter or make_project_sorter()
    opts.previewer = opts.previewer or make_project_previewer()

    local switcher = require("projections.switcher")
    pickers.new(opts, {
        prompt_title = "Projects",
        finder = project_finder(opts),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                if opts.action == nil then
                    opts.action = function(selected)
                        if selected ~= nil and selected.value ~= vim.fn.getcwd() then
                            switcher.switch(selected.value)
                        end
                    end
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
