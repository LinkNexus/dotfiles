local dashboard_dir = vim.fn.stdpath("config") .. "/dashboard"
local dashboard_dir_content = vim.fn.readdir(dashboard_dir)
local dashboard_files_count = 0

for _, v in ipairs(dashboard_dir_content) do
  if v ~= ".DS_Store" and v ~= "banner.txt" then
    dashboard_files_count = dashboard_files_count + 1
  end
end

local dashboard_cmd = "uv tool run img2art " ..
    dashboard_dir ..
    "/wallpaper.png --scale 0.20 --with-color --threshold 60"
local banner_lines = { 'NEOVIM' }
local banner_path = dashboard_dir .. "/banner.txt"

if vim.fn.filereadable(banner_path) == 1 then
  local lines = vim.fn.readfile(banner_path)
  if #banner_lines > 0 then
    banner_lines = lines
  end
end

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      lazygit = { enabled = true },
      dashboard = {
        preset = {
          header = table.concat(banner_lines, "\n")
        },
        sections = {
          {
            section = "terminal",
            cmd = dashboard_cmd,
            height = 20,
            padding = 1,
          },
          {
            pane = 2,
            { padding = math.floor((20 - #banner_lines - 4) / 2) },
            { section = "header" },
            { section = "startup" }
          }
        },
      },
    },
  },
}
