if not vim.g.neovide then
  return {}
end

-- Font
vim.o.guifont = "JetBrainsMono Nerd Font:h13"

-- Cursor animation
vim.g.neovide_cursor_animation_length = 0.08
vim.g.neovide_cursor_trail_size = 0.4

-- Scroll animation
vim.g.neovide_scroll_animation_length = 0.2

-- Padding
vim.g.neovide_padding_top = 4
vim.g.neovide_padding_bottom = 4
vim.g.neovide_padding_left = 8
vim.g.neovide_padding_right = 8

-- GUI keymaps (Cmd)
local map = vim.keymap.set
map("n", "<D-s>", "<cmd>w<cr>", { desc = "Save" })
map({ "n", "v" }, "<D-c>", '"+y', { desc = "Copy" })
map({ "n", "v", "i" }, "<D-v>", function()
  vim.api.nvim_paste(vim.fn.getreg("+"), true, -1)
end, { desc = "Paste" })
map({ "n", "v" }, "<D-a>", "ggVG", { desc = "Select all" })
map("n", "<D-z>", "u", { desc = "Undo" })
map("n", "<D-w>", "<cmd>bd<cr>", { desc = "Close buffer" })

return {}
