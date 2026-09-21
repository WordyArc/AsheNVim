local t = require("harness")
local h = require("helpers")
local root = require("ashenvim.core.root")

t.describe("root.cwd", function()
  t.it("follows a window-local directory", function()
    local project = h.project({ ["README"] = {} })
    local before = vim.fn.getcwd()
    vim.cmd.lcd(project)
    t.cleanup(function()
      vim.cmd.lcd(before)
    end)

    h.eq(root.cwd(), project)
  end)
end)

t.describe("root.get", function()
  t.it("falls back to cwd for an unnamed buffer", function()
    local buf = vim.api.nvim_create_buf(true, false)
    t.cleanup(function()
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    h.eq(root.get(buf), root.cwd())
  end)

  t.it("falls back to cwd for a file without markers", function()
    local project = h.project({ ["notes.txt"] = { "plain" } })
    local buf = h.open(project .. "/notes.txt")
    h.eq(root.get(buf), root.cwd())
  end)

  t.it("walks up to a marker above the file", function()
    local project = h.project({
      [".git"] = {},
      ["src/deep/file.txt"] = { "x" },
    })
    local buf = h.open(project .. "/src/deep/file.txt")
    h.eq(root.get(buf), project)
  end)

  t.it("prefers the git root over a nearer language marker", function()
    local project = h.project({
      [".git"] = {},
      ["crate/Cargo.toml"] = {},
      ["crate/src/main.txt"] = { "x" },
    })
    local buf = h.open(project .. "/crate/src/main.txt")
    h.eq(root.get(buf), project)
  end)

  t.it("resolves a buffer that was named but never read", function()
    local project = h.project({ ["settings.gradle.kts"] = {} })
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, project .. "/src/main/kotlin/Main.kt")
    t.cleanup(function()
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
    h.eq(root.get(buf), project)
  end)

  t.it("prefers the LSP root over markers", function()
    local project = h.project({
      [".git"] = {},
      ["crate/Cargo.toml"] = {},
      ["crate/src/main.txt"] = { "x" },
    })
    local buf = h.open(project .. "/crate/src/main.txt")
    h.fake_lsp(buf, { root_dir = project })
    h.eq(root.get(buf), project)
  end)

  t.it("prefers the deepest workspace folder containing the file", function()
    local project = h.project({
      ["a/file.txt"] = { "x" },
      ["b/file.txt"] = { "x" },
    })
    local buf = h.open(project .. "/b/file.txt")
    h.fake_lsp(buf, { root_dir = project, workspace_folders = { project .. "/a", project .. "/b" } })
    h.eq(root.get(buf), project .. "/b")
  end)

  t.it("ignores an LSP root that does not contain the file", function()
    local elsewhere = h.project({ ["README"] = {} })
    local project = h.project({
      ["go.mod"] = {},
      ["pkg/file.txt"] = { "x" },
    })
    local buf = h.open(project .. "/pkg/file.txt")
    h.fake_lsp(buf, { root_dir = elsewhere })
    h.eq(root.get(buf), project)
  end)
end)
