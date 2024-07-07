return {

  { "nvim-treesitter/nvim-treesitter", opts = {
      ensure_installed = {
        "bash",
        "go",
        "awk",
        "c",
        "cpp",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "vim",
        "yaml",
      },
    },
  },

  { "rose-pine/neovim", name = "rose-pine" },

  { "LazyVim/LazyVim", opts = {
      colorscheme = "rose-pine",
    },
  },

  { "nvim-neo-tree/neo-tree.nvim", opts = {
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = true,
          hide_gitignored = true,
          hide_by_name = { '.venv', },
          never_show = { '.git', },
          show_hidden_count = true,
        },
      },
    },
  },

}
