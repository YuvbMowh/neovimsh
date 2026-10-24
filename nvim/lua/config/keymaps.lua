-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- VS Code owns IDE services; terminal LazyVim keeps its existing mappings.
if vim.g.vscode then
  local vscode = require("vscode")
  local function map(modes, lhs, command, desc)
    vim.keymap.set(modes, lhs, function() vscode.action(command) end, { desc = desc })
  end
  map("n", "<leader>e", "workbench.action.toggleSidebarVisibility", "Toggle Explorer/sidebar")
  map("n", "<leader>E", "workbench.view.explorer", "Focus Explorer")
  map("n", "<leader>,", "workbench.action.showAllEditors", "Switch Buffer")
  map("n", "<leader>bd", "workbench.action.closeActiveEditor", "Close Buffer safely")
  map("n", "<leader>bb", "workbench.action.openPreviousRecentlyUsedEditor", "Alternate Buffer")
  map("n", "<leader><space>", "workbench.action.quickOpen", "Find Files")
  map("n", "<leader>ff", "workbench.action.quickOpen", "Find Files")
  map("n", "<leader>/", "workbench.action.findInFiles", "Search Project")
  map("n", "<leader>sg", "workbench.action.findInFiles", "Search Project")
  map("n", "<S-h>", "workbench.action.previousEditor", "Previous Buffer")
  map("n", "<S-l>", "workbench.action.nextEditor", "Next Buffer")
  map("n", "gd", "editor.action.revealDefinition", "Definition")
  map("n", "gr", "editor.action.goToReferences", "References")
  map("n", "gD", "editor.action.revealDeclaration", "Declaration")
  map("n", "gi", "editor.action.goToImplementation", "Implementation")
  map("n", "K", "editor.action.showHover", "Hover")
  map({ "n", "x" }, "<leader>ca", "editor.action.quickFix", "Code Action")
  map("n", "<leader>cr", "editor.action.rename", "Rename")
  map("n", "<leader>cf", "editor.action.formatDocument", "Format")
  map("x", "<leader>cf", "editor.action.formatSelection", "Format Selection")
  map("n", "]d", "editor.action.marker.next", "Next Diagnostic")
  map("n", "[d", "editor.action.marker.prev", "Previous Diagnostic")
  map("n", "<leader>xx", "workbench.actions.view.problems", "Problems")
  map("n", "<leader>db", "editor.debug.action.toggleBreakpoint", "Breakpoint")
  map("n", "<leader>dc", "workbench.action.debug.start", "Start/Continue Debugging")
  map("n", "<leader>qq", "workbench.action.closeWindow", "Close Window safely")
end
