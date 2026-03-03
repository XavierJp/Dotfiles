-- Options (loaded before lazy.nvim)
local opt = vim.opt

opt.scrolloff = 10
opt.inccommand = "split"
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.list = true

-- Diagnostics
vim.diagnostic.config({
  float = { border = "rounded" },
  severity_sort = true,
  virtual_text = {
    spacing = 4,
    source = "if_many",
    prefix = "●",
  },
})
