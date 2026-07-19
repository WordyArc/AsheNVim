local M = {}

local logo = {
  " █████╗  ███████╗ ██╗  ██╗ ███████╗ ███╗   ██╗ ██╗   ██╗ ██╗ ███╗   ███╗",
  "██╔══██╗ ██╔════╝ ██║  ██║ ██╔════╝ ████╗  ██║ ██║   ██║ ██║ ████╗ ████║",
  "███████║ ███████╗ ███████║ █████╗   ██╔██╗ ██║ ██║   ██║ ██║ ██╔████╔██║",
  "██╔══██║ ╚════██║ ██╔══██║ ██╔══╝   ██║╚██╗██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║",
  "██║  ██║ ███████║ ██║  ██║ ███████╗ ██║ ╚████║  ╚████╔╝  ██║ ██║ ╚═╝ ██║",
  "╚═╝  ╚═╝ ╚══════╝ ╚═╝  ╚═╝ ╚══════╝ ╚═╝  ╚═══╝   ╚═══╝   ╚═╝ ╚═╝     ╚═╝",
}

---@return LazyPluginSpec
function M.spec()
  return {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      dashboard = {
        enabled = true,
        preset = {
          header = table.concat(logo, "\n"),
          keys = {
            { icon = " ", key = "f", desc = "Find file", action = "<leader>ff" },
            { icon = " ", key = "n", desc = "New file", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find text", action = "<leader>sg" },
            { icon = " ", key = "r", desc = "Recent files", action = "<leader>fr" },
            { icon = " ", key = "c", desc = "Config", action = "<leader>fc" },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
        },
      },
    },
  }
end

return M
