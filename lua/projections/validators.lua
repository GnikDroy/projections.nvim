local M = {}

-- Autocorrect incorrect pattern specifications
-- This function is meant to be conservative (no false positives) and
-- only corrects and notifies common errors.
--
-- @param workspace_path The path to the workspace
-- @param patterns The pattern list
M.autocorrect_patterns = function(workspace_path, patterns)
    local notify_incorrect_pattern = function(actual, expected)
        vim.notify(
            string.format(
                "projections.config: Autocorrected incorrect pattern.\n\n" ..
                "Workspace: '%s'\n" ..
                "'%s' -> '%s'\n\n" ..
                "Update the pattern to remove this message.",
                workspace_path, actual, expected
            ), vim.log.levels.INFO
        )
    end

    local autocorrect_entries = {
        { '.git', '^%.git$' },
        { '.svn', '^%.svn$' },
        { '.hg', '^%.hg$' },
        { '.gitignore', '^%.gitignore$' },
        { 'package.json', '^package%.json$' },
        { 'Cargo.toml', '^Cargo%.toml$' },
    }
    for i, pattern in ipairs(patterns) do
        for _, entry in ipairs(autocorrect_entries) do
            local actual, expected = unpack(entry)
            if pattern == actual then
                notify_incorrect_pattern(actual, expected)
                patterns[i] = expected
            end
        end
    end
end

-- Assert value is of some type or throw error with custom message
-- @param expected_types table of possible expected types
-- @param value The value to check
-- @param msg Error message, can be a string.format pattern
-- @param ... Additional values to format the message string
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

-- Validate workspaces table. Throws error on failure.
-- @param workspaces Sequential table of workspace strings or pairs
M.validate_workspaces_table = function(workspaces)
    M.assert_type({ "table" }, workspaces, "workspaces")

    for workspace_index, ws in ipairs(workspaces) do
        if type(ws) == "table" then
            local path, patterns = unpack(ws)
            M.assert_type({ "string" }, path, "workspaces[%d].path", workspace_index)
            M.assert_type({ "table" }, patterns, "workspaces[%d].patterns", workspace_index)

            for pattern_index, pattern in ipairs(patterns) do
                M.assert_type({ "string" }, pattern, "workspaces[%d].patterns[%d]", workspace_index, pattern_index)
            end
        elseif type(ws) == "string" then
            -- No further validation required
        else
            M.assert_type({ "string", "table" }, ws, "workspaces[%d]", workspace_index)
        end
    end
end

-- Validate projections config passed to setup. Throws error on failure.
-- @param config config passed to projections
M.validate_config = function(config)
    M.assert_type({ "string", "nil" }, config.workspaces_file, "workspace_file")
    M.assert_type({ "string", "nil" }, config.sessions_directory, "sessions_directory")
end

-- Validate merged projections config table. Throws error on failure.
-- @param config Merged custom config with defaults
M.validate_merged_config = function(config)
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
