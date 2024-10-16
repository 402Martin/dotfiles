local nvim_lsp = require("lspconfig")
local M = {}
local configs = require("lspconfig/configs")
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
function M.on_attach(client, bufnr)
	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end

	-- Mappings.
	local opts = { noremap = true, silent = true }

	buf_set_keymap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
	buf_set_keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
	buf_set_keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
	buf_set_keymap("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
	buf_set_keymap("n", "<space>ll", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
	buf_set_keymap("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
	buf_set_keymap("n", "<space>e", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
	buf_set_keymap("n", "[d", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>", opts)
	buf_set_keymap("n", "]d", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", opts)
	buf_set_keymap("n", "<space>fo", "<cmd>lua vim.lsp.buf.format()<CR>", opts)
	buf_set_keymap("n", "<space>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
	buf_set_keymap("n", "<space>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)

	-- Set some key bindings conditional on server capabilities
	if client.server_capabilities.document_formatting then
		vim.keymap.set("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting_sync()<CR>", opts)
	end
	if client.server_capabilities.document_range_formatting then
		vim.keymap.set("x", "<space>f", "<cmd>lua vim.lsp.buf.range_formatting()<CR><ESC>", opts)
	end

	-- The blow command will highlight the current variable and its usages in the buffer
	if client.server_capabilities.document_highlight then
		vim.cmd([[
          hi! link LspReferenceRead Visual
          hi! link LspReferenceText Visual
          hi! link LspReferenceWrite Visual
          augroup lsp_document_highlight
            autocmd! * <buffer>
            autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
            autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
          augroup END
      ]])
	end

	-- lsp-signature
	require("lsp_signature").on_attach({
		bind = true, -- This is mandatory, otherwise border config won't get registered.
		hint_prefix = " ",
		handler_opts = { border = "rounded" },
	}, bufnr)
end

-- Attempt to fix slow rendering of typescript highlights when using tree-sitter.
-- This doesn't solve the problem for all Typescript files. I don't know what the
-- problem is exactly. I've read online that is a problem related to JSDocs, or
-- the cadence at which Treesitter queries the file.
-- ~~Source: https://github.com/nvim-treesitter/nvim-treesitter/issues/1396
local TSPrebuild = {}
local has_prebuilt = false

TSPrebuild.on_attach = function(client, bufnr)
	if has_prebuilt then
		return
	end

	local function safe_read(filename, read_quantifier)
		local file, err = io.open(filename, "r")
		if not file then
			error(err)
		end
		local content = file:read(read_quantifier)
		io.close(file)
		return content
	end

	local function read_query_files(filenames)
		local contents = {}

		for _, filename in ipairs(filenames) do
			table.insert(contents, safe_read(filename, "*a"))
		end

		return table.concat(contents, "")
	end

	local function prebuild_query(lang, query_name)
		local treesitter = require("vim.treesitter")
		local query_files = treesitter.get_query_files(lang, query_name)
		local query_string = read_query_files(query_files)

		treesitter.set_query(lang, query_name, query_string)
	end

	local prebuild_languages = { "typescript", "javascript", "tsx" }
	for _, lang in ipairs(prebuild_languages) do
		prebuild_query(lang, "highlights")
		prebuild_query(lang, "injections")
	end

	has_prebuilt = true
	M.on_attach(client, bufnr)
end

-- Setup lspconfig
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.documentationFormat = { "markdown", "plaintext", "norg" }
capabilities.textDocument.completion.completionItem.preselectSupport = true
capabilities.textDocument.completion.completionItem.insertReplaceSupport = true
capabilities.textDocument.completion.completionItem.labelDetailsSupport = true
capabilities.textDocument.completion.completionItem.deprecatedSupport = true
capabilities.textDocument.completion.completionItem.commitCharactersSupport = true
capabilities.textDocument.completion.completionItem.tagSupport = { valueSet = { 1 } }
capabilities.textDocument.completion.completionItem.relativeSupport = {
	properties = { "documentation", "detail", "additionalTextEdits" },
}

-- Borders --
local border = {
	{ "╭", "FloatBorder" },
	{ "─", "FloatBorder" },
	{ "╮", "FloatBorder" },
	{ "│", "FloatBorder" },
	{ "╯", "FloatBorder" },
	{ "─", "FloatBorder" },
	{ "╰", "FloatBorder" },
	{ "│", "FloatBorder" },
}

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = border })
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = border })
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
	underline = true,
	update_in_insert = true,
	signs = true,
	virtual_text = true,
})

vim.cmd.highlight("DiagnosticUnderlineError guisp=#ff0000 gui=undercurl")

-- NVIM lsp installer --
require("nvim-lsp-installer").setup({
	automatic_installation = true, -- automatically detect which servers to install (based on which servers are set up via lspconfig)
	ui = {
		icons = {
			server_installed = "✓",
			server_pending = "➜",
			server_uninstalled = "✗",
		},
	},
})

-- Ansible --
nvim_lsp.ansiblels.setup({
	cmd = { "ansible-language-server", "--stdio" },
	filetypes = { "yaml", "yml", "yaml.ansible", "ansible" },
	on_attach = M.on_attach,
	flags = { debounce_text_changes = 150 },
	capabilities = capabilities,
})

-- Bash --
nvim_lsp.bashls.setup({
	cmd = { "bash-language-server", "start" },
	on_attach = M.on_attach,
	filetypes = { "sh" },
	flags = { debounce_text_changes = 150 },
	capabilities = capabilities,
})
local util = require("lspconfig.util")
-- CSS --
nvim_lsp.cssls.setup({
	cmd = { "vscode-css-language-server", "--stdio" },
	capabilities = capabilities,
	filetypes = { "css", "scss", "less" },
	on_attach = M.on_attach,
	flags = { debounce_text_changes = 150 },
	single_file_support = true,
	root_dir = util.root_pattern("package.json", ".git"),
	settings = {
		css = { validate = true },
		scss = { validate = true },
		less = { validate = true },
	},
})
-- Docker --
nvim_lsp.dockerls.setup({
	cmd = { "docker-langserver", "--stdio" },
	filetypes = { "Dockerfile", "dockerfile" },
	on_attach = M.on_attach,
	flags = { debounce_text_changes = 150 },
	capabilities = capabilities,
})
-- ESLint --
nvim_lsp.eslint.setup({
	cmd = { "vscode-eslint-language-server", "--stdio" },
	on_attach = M.on_attach,
	flags = { debounce_text_changes = 150 },
	capabilities = capabilities,
})
-- Go --
nvim_lsp.gopls.setup({
	cmd = { "gopls" },
	on_attach = M.on_attach,
	flags = { debounce_text_changes = 150 },
	capabilities = capabilities,
})
-- HTML --
nvim_lsp.html.setup({
	cmd = { "vscode-html-language-server", "--stdio" },
	capabilities = capabilities,
	on_attach = M.on_attach,
	flags = { debounce_text_changes = 150 },
})

-- Lua --
local runtime_path = vim.split(package.path, ";")
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")

nvim_lsp.lua_ls.setup({
	on_attach = M.on_attach,
	settings = {
		Lua = {
			runtime = {
				-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
				version = "LuaJIT",
				-- Setup your lua path
				path = runtime_path,
			},
			diagnostics = {
				-- Get the language server to recognize the `vim` global
				globals = { "vim" },
			},
			workspace = {
				-- Make the server aware of Neovim runtime files
				library = vim.api.nvim_get_runtime_file("", true),
				checkThirdParty = false,
			},
			-- Do not send telemetry data containing a randomized but unique identifier
			telemetry = { enable = false },
		},
	},
})
local mason_registry = require("mason-registry")
local vue_language_server_path = mason_registry.get_package("vue-language-server"):get_install_path()
	.. "/node_modules/@vue/language-server"
-- Typescript --
nvim_lsp.ts_ls.setup({
	cmd = { "typescript-language-server", "--stdio" },
	capabilities = capabilities,
	-- on_attach = TSPrebuild.on_attach,
	on_attach = M.on_attach,
	on_init = function(client)
		client.config.flags.debounce_text_changes = 150
	end,
	flags = { debounce_text_changes = 150 },
	init_options = {
		plugins = {
			{
				name = "@vue/typescript-plugin",
				location = vue_language_server_path,
				languages = { "vue" },
			},
		},
	},
})

nvim_lsp.volar.setup({
	init_options = {
		vue = {
			hybridMode = false,
		},
	},
})
-- Vim --
nvim_lsp.vimls.setup({
	cmd = { "vim-language-server", "--stdio" },
	capabilities = capabilities,
	on_attach = M.on_attach,
	flags = { debounce_text_changes = 150 },
})

-- Python --
nvim_lsp.pyright.setup({
	on_attach = M.on_attach,
	cmd = { "pyright-langserver", "--stdio" },
	capabilities = capabilities,
})

-- EFM Lang server --
nvim_lsp.efm.setup({
	on_attach = M.on_attach,
	init_options = { documentFormatting = true },
	filetypes = { "lua" },
	settings = {
		rootMarkers = { ".git/" },
		languages = {
			lua = {
				{
					formatCommand = "lua-format -i --no-keep-simple-function-one-line --no-break-after-operator --column-limit=120 --break-after-table-lb",
					formatStdin = true,
				},
			},
		},
	},
})

-- Terraform --
nvim_lsp.terraformls.setup({
	on_attach = M.on_attach,
	cmd = { "terraform-ls", "serve" },
})

-- Rust --
nvim_lsp.rust_analyzer.setup({
	on_attach = M.on_attach,
	settings = {
		["rust-analyzer"] = {
			assist = { importGranularity = "module", importPrefix = "self" },
			cargo = { loadOutDirsFromCheck = true },
			procMacro = { enable = true },
		},
	},
})

nvim_lsp.grammarly.setup({
	on_attach = M.on_attach,
	filetypes = { "html", "markdown", "markdown.pandoc", "text", "txt", "norg" },
})

-- Change diagnostics signs
vim.fn.sign_define("DiagnosticSignError", { text = "", texthl = "DiagnosticSignError" })
vim.fn.sign_define("DiagnosticSignWarn", { text = "", texthl = "DiagnosticSignWarn" })
vim.fn.sign_define("DiagnosticSignInformation", { text = "", texthl = "DiagnosticSignInfo" })
vim.fn.sign_define("DiagnosticSignHint", { text = "", texthl = "DiagnosticSignHint" })

-- global config for diagnostic
vim.diagnostic.config({ underline = true, virtual_text = true, signs = true, severity_sort = true })

nvim_lsp.ember.setup({
	on_attach = M.on_attach,
	capabilities = capabilities,
	filetypes = { "handlebars", "html.handlebars", "javascript", "typescript" },
})

nvim_lsp.sourcekit.setup({})

nvim_lsp.csharp_ls.setup({
	AutomaticWorkspaceInit = true,
	root_dir = function(startpath)
		return nvim_lsp.util.root_pattern("*.csproj")(startpath)
			or nvim_lsp.util.root_pattern("*.sln")(startpath)
			or nvim_lsp.util.root_pattern("*.fsproj")(startpath)
			or nvim_lsp.util.root_pattern(".git")(startpath)
	end,
	on_attach = M.on_attach,
	capabilities = capabilities,
})

nvim_lsp.typos_lsp.setup({
	-- Logging level of the language server. Logs appear in :LspLog. Defaults to error.
	cmd_env = { RUST_LOG = "error" },
	init_options = {
		-- Custom config. Used together with any workspace config files, taking precedence for
		-- settings declared in both. Equivalent to the typos `--config` cli argument.
		config = "~/code/typos-lsp/crates/typos-lsp/tests/typos.toml",
		-- How typos are rendered in the editor, eg: as errors, warnings, information, or hints.
		-- Defaults to error.
		diagnosticSeverity = "Hint",
	},
})

-- Map key combination to trigger lsp hover
vim.api.nvim_set_keymap("n", "<C-,>", "<cmd>lua vim.lsp.buf.hover()<CR>", { noremap = true, silent = true })

-- require("xbase").setup()
return M
