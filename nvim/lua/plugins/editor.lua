return {
  -- Format on save with conform
  {
    "stevearc/conform.nvim",
    opts = {
      format_on_save = function(bufnr)
        -- Skip C/C++ (use clangd formatting instead)
        local ft = vim.bo[bufnr].filetype
        if ft == "c" or ft == "cpp" then
          return false
        end
        return { timeout_ms = 3000, lsp_format = "fallback" }
      end,
    },
  },

  -- Blink.cmp: auto-show docs
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
      },
    },
  },

  -- Which-key: instant popup
  {
    "folke/which-key.nvim",
    opts = {
      delay = 0,
    },
  },
}
