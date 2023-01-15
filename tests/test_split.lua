local helpers = dofile("tests/helpers.lua")

local child = helpers.new_child_neovim()
local eq = helpers.expect.equality
local eq_state, eq_buf_width = helpers.expect.state_equality, helpers.expect.buf_width_equality

local new_set = MiniTest.new_set

local T = new_set({
    hooks = {
        -- This will be executed before every (even nested) case
        pre_case = function()
            -- Restart child process with custom 'init.lua' script
            child.restart({ "-u", "scripts/minimal_init.lua" })
        end,
        -- This will be executed one after all tests from this set are finished
        post_once = child.stop,
    },
})

T["split"] = new_set()

T["split"]["only one side buffer, closing help doesn't close NNP"] = function()
    child.set_size(500, 500)
    child.lua([[
        require('no-neck-pain').setup({width=50, buffers={right={enabled=false}}})
        require('no-neck-pain').enable()
    ]])

    child.cmd("h")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1002, 1000 })
    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", vim.NIL)
    eq_state(child, "win.main.split", 1002)
    eq_state(child, "win.main.curr", 1000)
    eq_state(child, "vsplit", false)

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.win.main.split)")
    child.cmd("q")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000 })
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1000)
    eq_state(child, "enabled", true)
end

T["split"]["closing `curr` makes `split` the new `curr`"] = function()
    child.set_size(200, 200)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    child.cmd("split")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1003, 1000, 1002 })
    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", 1002)
    eq_state(child, "win.main.split", 1003)
    eq_state(child, "win.main.curr", 1000)
    eq_state(child, "vsplit", false)

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.win.main.curr)")
    child.cmd("q")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1003, 1002 })
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1003)
end

T["split"]["keeps side buffers"] = function()
    child.set_size(200, 200)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    child.cmd("split")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1003, 1000, 1002 })
    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", 1002)
    eq_state(child, "win.main.split", 1003)
    eq_state(child, "vsplit", false)

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.win.main.split)")
    child.cmd("q")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    eq_buf_width(child, "main.left", 15)
    eq_buf_width(child, "main.right", 15)
end

T["vsplit"] = new_set()

T["vsplit"]["correctly position side buffers with vsplits already opened"] = function()
    child.cmd("vsplit")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000 })

    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1002, 1001, 1000, 1003 })
end

T["vsplit"]["closing `curr` makes `split` the new `curr`"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    child.cmd("vsplit")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1003, 1000 })
    eq_state(child, "win.main.left", vim.NIL)
    eq_state(child, "win.main.right", vim.NIL)
    eq_state(child, "win.main.split", 1003)
    eq_state(child, "win.main.curr", 1000)
    eq_state(child, "vsplit", true)

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.win.main.curr)")
    child.cmd("q")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1004, 1003, 1005 })
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1003)
end

T["vsplit"]["hides side buffers"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    child.cmd("vsplit")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1003, 1000 })
    eq_state(child, "win.main.left", vim.NIL)
    eq_state(child, "win.main.right", vim.NIL)
    eq_state(child, "win.main.split", 1003)
    eq_state(child, "vsplit", true)

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.win.main.split)")
    child.cmd("q")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1004, 1000, 1005 })
    eq_state(child, "win.main.left", 1004)
    eq_state(child, "win.main.right", 1005)
    eq_state(child, "win.main.split", vim.NIL)
    eq_state(child, "vsplit", false)
end

T["vsplit/split"] = new_set()

T["vsplit/split"]["state is correctly sync'd even after many changes"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1000 })

    child.lua([[ require('no-neck-pain').enable() ]])

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })

    child.cmd("split")
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1003, 1000, 1002 })
    child.cmd("q")

    child.cmd("vsplit")
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1004, 1000 })
    child.cmd("q")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1005, 1000, 1006 })
end

return T