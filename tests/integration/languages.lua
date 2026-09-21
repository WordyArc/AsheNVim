local t = require("harness")
local h = require("helpers")

local function wait_for_client(name, buf)
  h.wait_for(name .. " did not attach", function()
    return #vim.lsp.get_clients({ bufnr = buf, name = name }) == 1
  end, 120000)
  local client = vim.lsp.get_clients({ bufnr = buf, name = name })[1]
  t.cleanup(function()
    client:stop(true)
  end)
  return client
end

local function assert_parser(buf, lang)
  h.wait_for(lang .. " Tree-sitter parser did not attach", function()
    return pcall(vim.treesitter.get_parser, buf, lang)
  end, 10000)
end

local function keep_content(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  t.cleanup(function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end)
end

local function assert_supports(client, buf, ...)
  for _, method in ipairs({ ... }) do
    assert(client:supports_method(method, buf), client.name .. " does not support " .. method)
  end
end

t.describe("rust", function()
  local buf, client

  t.before_all(function()
    local project = h.project({
      ["Cargo.toml"] = { "[package]", 'name = "ashenvim-smoke"', 'version = "0.1.0"', 'edition = "2024"' },
      ["src/main.rs"] = { 'fn   main(){println!("AsheNVim");}' },
    })
    buf = h.open(project .. "/src/main.rs")
    client = wait_for_client("rust_analyzer", buf)
  end)

  t.it("attaches rust-analyzer with hover and completion", function()
    assert_supports(client, buf, "textDocument/hover", "textDocument/completion")
    local info = vim.iter(vim.api.nvim_buf_get_keymap(buf, "n")):find(function(mapping)
      return mapping.desc == "LSP info"
    end)
    assert(info and info.rhs:find("checkhealth vim.lsp", 1, true), "LSP info mapping is invalid")
  end)

  t.it("loads the rust parser", function()
    assert_parser(buf, "rust")
  end)

  t.it("formats with rustfmt", function()
    keep_content(buf)
    vim.cmd("Lazy load conform.nvim")
    local conform = require("conform")
    assert(conform.get_formatter_info("rustfmt", buf).available, "rustfmt is unavailable")
    local format_error
    conform.format({ bufnr = buf, async = false, lsp_format = "fallback" }, function(err)
      format_error = err
    end)
    h.eq(format_error, nil)
    h.eq(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1], "fn main() {")
  end)
end)

t.describe("kotlin", function()
  local buf, client

  t.before_all(function()
    local project = h.project({
      ["settings.gradle.kts"] = { 'rootProject.name = "ashenvim-smoke"' },
      ["build.gradle.kts"] = { "plugins {", '  kotlin("multiplatform") version "2.2.0"', "}", "kotlin { jvm() }" },
      ["src/commonMain/kotlin/Main.kt"] = { "fun main() {", '  println("AsheNVim")', "}" },
    })
    buf = h.open(project .. "/src/commonMain/kotlin/Main.kt")
    client = wait_for_client("kotlin_lsp", buf)
  end)

  t.it("attaches kotlin-lsp with hover, completion and formatting", function()
    assert_supports(client, buf, "textDocument/hover", "textDocument/completion", "textDocument/formatting")
  end)

  t.it("loads the kotlin parser", function()
    assert_parser(buf, "kotlin")
  end)

  t.it("formats through the LSP", function()
    keep_content(buf)
    vim.cmd("Lazy load conform.nvim")
    local done, format_error = false
    require("conform").format({ bufnr = buf, async = true, lsp_format = "fallback", timeout_ms = 30000 }, function(err)
      format_error = err
      done = true
    end)
    h.wait_for("Kotlin LSP formatting timed out", function()
      return done
    end, 40000)
    h.eq(format_error, nil)
  end)
end)
