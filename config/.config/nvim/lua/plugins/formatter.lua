local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local util = require("formatter.util")
local formatter = require("formatter")

formatter.setup({
	-- Enable or disable logging
	logging = true,
	-- Set the log level
	log_level = vim.log.levels.WARN,
	-- All formatter configurations are opt-in
	filetype = {
		-- Luatry_node_modules formatting with stylua
		lua = {
			require("formatter.filetypes.lua").stylua,
			function()
				if util.get_current_buffer_file_name() == "special.lua" then
					return nil
				end
				return {
					exe = "stylua",
					args = {
						"--search-parent-directories",
						"--stdin-filepath",
						util.escape_path(util.get_current_buffer_file_path()),
						"--",
						"-",
					},
					stdin = true,
				}
			end,
		},
		json = {
			function()
				return {
					exe = "prettier",
					args = {
						"--stdin-filepath",
						util.escape_path(util.get_current_buffer_file_path()),
						"--",
					},
					stdin = true,
				}
			end,
		},
		typescript = {
			require("formatter.filetypes.javascript").prettier,
			require("formatter.filetypes.javascript").eslint_d,
		},
		javascript = {
			require("formatter.filetypes.javascript").prettier,
			require("formatter.filetypes.javascript").eslint_d,
		},
		typescriptreact = {
			require("formatter.filetypes.javascript").prettier,
			require("formatter.filetypes.javascript").eslint_d,
		},
		javascriptreact = {
			require("formatter.filetypes.javascript").prettier,
			require("formatter.filetypes.javascript").eslint_d,
		},
		vue = {
			require("formatter.filetypes.javascript").prettier,
			require("formatter.filetypes.javascript").eslint_d,
		},
		python = {
			require("formatter.filetypes.python").black,
		},
		["*"] = {
			require("formatter.filetypes.any").remove_trailing_whitespace,
		},
	},
})

vim.g.auto_format_enabled = true

function ToggleAutoFormat()
	vim.g.auto_format_enabled = not vim.g.auto_format_enabled
	if vim.g.auto_format_enabled then
		print("Auto format enabled")
	else
		print("Auto format disabled")
	end
end
vim.api.nvim_create_user_command("FormatToggle", ToggleAutoFormat, {})

augroup("__formatter__", { clear = true })

autocmd("BufWritePost", {
	group = "__formatter__",
	pattern = "*",
	callback = function()
		if vim.g.auto_format_enabled then
			vim.cmd("FormatWrite")
		end
	end,
})
