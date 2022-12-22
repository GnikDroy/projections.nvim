---
name: Bug report
about: Create a report to help us improve
title: "[bug] Bug title"
labels: bug
assignees: GnikDroy

---

**Basic checklist**
- [ ] I have read the README
- [ ] I have read the wiki
- [ ] I have read `:h session`, `:h mksession`, and `:h sessionoptions`
- [ ] I have searched through existing/closed issues
- [ ] I have checked if the recommended config has changed, and if that solves my issue.

**Expected vs Actual behavior**
A clear and concise description of the bug

**Environment information**
- Neovim version:
- Operating system:
- Projections branch/commit hash:
- Projections config:
```lua 
use({
    "gnikdroy/projections.nvim",
    config = function()
        ...
    end,
})
```

- Projections workspace file (find this at `stdpath('data') .. 'projections_workspaces.json'`: 
```lua
-- contents of file here (keep empty if none)
```

- Result of `ls -lah` from projection sessions folder (find this at `stdpath('cache') .. 'projections_sessions/'` . Remove personal information as needed.
```lua
-- outupt of ls
```

- Result of `tree -a -L 2` from every configured workspace (both config and workspace json file). Remove personal and unnecessary information as needed.
```lua
-- result of tree -a -L 2 from every configured workspace
```

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....' etc
