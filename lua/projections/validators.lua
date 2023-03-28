local M = {}

-- Assert value is of some type or throw error with custom message
---@param expected_types string[] table of possible expected types
---@param value any The value to check
---@param msg string Error message, can be a string.format pattern
---@param ... any Additional values to format the message string
M.assert_type = function(expected_types, value, msg, ...)
    local actual_type = type(value)
    local args = { ... }
    table.insert(args, table.concat(expected_types, " | "))
    table.insert(args, actual_type)

    assert(
        vim.tbl_contains(expected_types, actual_type),
        string.format("projections.config: " .. msg .. " - expected %s, got %s", unpack(args))
    )
end

-- Validate workspaces table from config. Throws error on failure.
---@param workspaces table Sequential table of workspace strings or pairs
M.validate_workspaces_table = function(workspaces)
    M.assert_type({ "table" }, workspaces, "workspaces")
    for workspace_index, ws in ipairs(workspaces) do
        M.assert_type({ "string", "table" }, ws, "workspaces[%d]", workspace_index)
        if type(ws) == "table" then
            local path, patterns = unpack(ws)
            M.assert_type({ "string" }, path, "workspaces[%d].path", workspace_index)
            M.assert_type({ "table" }, patterns, "workspaces[%d].patterns", workspace_index)
            for pattern_index, pattern in ipairs(patterns) do
                M.assert_type({ "string" }, pattern, "workspaces[%d].patterns[%d]", workspace_index, pattern_index)
            end
        end
    end
end

-- Validate workspaces table from JSON. Throws error on failure.
---@param workspaces table Sequential table of workspace config
M.validate_workspaces_json = function(workspaces)
    M.assert_type({ "table" }, workspaces, "workspaces")
    for workspace_index, ws in ipairs(workspaces) do
        M.assert_type({ "table" }, ws, "workspaces[%d]", workspace_index)
        M.assert_type({ "string" }, ws.path, "workspaces[%d].path", workspace_index)
        M.assert_type({ "table" }, ws.patterns, "workspaces[%d].patterns", workspace_index)
        for pattern_index, pattern in ipairs(ws.patterns) do
            M.assert_type({ "string" }, pattern, "workspaces[%d].patterns[%d]", workspace_index, pattern_index)
        end
    end
end

-- Validate projects table from JSON. Throws error on failure.
---@param projects table Sequential table of projects
M.validate_projects_json = function(projects)
    M.assert_type({ "table" }, projects, "projects")
    for project_index, proj in ipairs(projects) do
        M.assert_type({ "table" },  proj, "projects[%d]", project_index)
        M.assert_type({ "string" }, proj.name, "projects[%d].name", project_index)
        M.assert_type({ "string" }, proj.workspace, "projects[%d].workspace", project_index)
    end
end

-- Validate projections config passed to setup. Throws error on failure.
---@param config ConfigUser Config passed to projections by user
M.validate_user_config = function(config)
    M.assert_type({ "string", "nil" }, config.workspaces_file, "workspace_file")
    M.assert_type({ "string", "nil" }, config.sessions_directory, "sessions_directory")
end

-- Validate projections config table. Throws error on failure.
---@param config Config Internal representation of config from projections
M.validate_config = function(config)
    M.validate_workspaces_table(config.workspaces)
    M.assert_type({ "table" }, config.patterns, "patterns")

    for i, pattern in ipairs(config.patterns) do
        M.assert_type({ "string" }, pattern, "patterns[%d]", i)
    end

    M.assert_type({ "table" }, config.store_hooks, "store_hooks")
    M.assert_type({ "function", "nil" }, config.store_hooks.pre, "store_hooks.pre")
    M.assert_type({ "function", "nil" }, config.store_hooks.post, "store_hooks.post")

    M.assert_type({ "table" }, config.restore_hooks, "restore_hooks")
    M.assert_type({ "function", "nil" }, config.restore_hooks.pre, "restore_hooks.pre")
    M.assert_type({ "function", "nil" }, config.restore_hooks.post, "restore_hooks.post")
end

return M
