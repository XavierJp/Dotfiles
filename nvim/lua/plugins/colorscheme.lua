return {
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "night",
      on_highlights = function(hl, _)
        -- No italic comments
        hl.Comment = { fg = hl.Comment.fg, italic = false }
        hl["@comment"] = { link = "Comment" }
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "tokyonight-night" },
  },
}
