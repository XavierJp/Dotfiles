return {
  -- Treesitter: ensure languages are installed
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "css",
        "diff",
        "go",
        "html",
        "javascript",
        "json",
        "lua",
        "luadoc",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "rust",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "vue",
        "yaml",
      },
    },
  },

  -- Mason: ensure tools are installed
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "stylua",
        "shfmt",
      },
    },
  },
}
