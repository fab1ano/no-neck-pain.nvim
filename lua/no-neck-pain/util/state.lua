local St = {}

function St.init()
    return {
        enabled = false,
        augroup = nil,
        wins = {
            main = {
                curr = nil,
                left = nil,
                right = nil,
            },
            splits = nil,
            external = {
                trees = {
                    NvimTree = {
                        id = nil,
                        width = 0,
                    },
                    undotree = {
                        id = nil,
                        width = 0,
                    },
                },
            },
        },
        tabs = 0,
    }
end

return St