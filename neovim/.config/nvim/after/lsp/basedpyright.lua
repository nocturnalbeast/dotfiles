-- ruff owns import organization (I rules + ruff-format); disable
-- basedpyright's organizer to avoid fighting it.
return {
    settings = {
        basedpyright = {
            analysis = {
                organizeImports = false,
            },
        },
    },
}
