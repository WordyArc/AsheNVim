local fixture = vim.fn.tempname()

local function write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(lines, path)
end

local function open(path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  return vim.api.nvim_get_current_buf()
end

local function wait_for_client(name, buf)
  assert(
    vim.wait(120000, function()
      return #vim.lsp.get_clients({ bufnr = buf, name = name }) == 1
    end, 100),
    name .. " did not attach"
  )
  return vim.lsp.get_clients({ bufnr = buf, name = name })[1]
end

local function assert_parser(buf, lang)
  assert(
    vim.wait(10000, function()
      return pcall(vim.treesitter.get_parser, buf, lang)
    end, 100),
    lang .. " Tree-sitter parser did not attach"
  )
end

local rust_root = fixture .. "/rust"
local rust_file = rust_root .. "/src/main.rs"
write(rust_root .. "/Cargo.toml", {
  "[package]",
  'name = "ashenvim-smoke"',
  'version = "0.1.0"',
  'edition = "2024"',
})
write(rust_file, { 'fn   main(){println!("AshenVim");}' })

local rust_buf = open(rust_file)
local rust_client = wait_for_client("rust_analyzer", rust_buf)
assert(rust_client:supports_method("textDocument/hover", rust_buf), "rust-analyzer hover support is missing")
assert(rust_client:supports_method("textDocument/completion", rust_buf), "rust-analyzer completion support is missing")
assert_parser(rust_buf, "rust")

vim.cmd("Lazy load conform.nvim")
local conform = require("conform")
assert(conform.get_formatter_info("rustfmt", rust_buf).available, "rustfmt is unavailable")
local rust_format_error
conform.format({ bufnr = rust_buf, async = false, lsp_format = "fallback" }, function(err)
  rust_format_error = err
end)
assert(rust_format_error == nil, "rustfmt failed: " .. tostring(rust_format_error))
assert(vim.api.nvim_buf_get_lines(rust_buf, 0, 1, false)[1] == "fn main() {", "Rust buffer was not formatted")

local kotlin_root = fixture .. "/kotlin"
local kotlin_file = kotlin_root .. "/src/commonMain/kotlin/Main.kt"
write(kotlin_root .. "/settings.gradle.kts", { 'rootProject.name = "ashenvim-smoke"' })
write(kotlin_root .. "/build.gradle.kts", {
  "plugins {",
  '  kotlin("multiplatform") version "2.2.0"',
  "}",
  "kotlin { jvm() }",
})
write(kotlin_file, { "fun main() {", '  println("AshenVim")', "}" })

local kotlin_buf = open(kotlin_file)
local kotlin_client = wait_for_client("kotlin_lsp", kotlin_buf)
assert(kotlin_client:supports_method("textDocument/hover", kotlin_buf), "Kotlin LSP hover support is missing")
assert(kotlin_client:supports_method("textDocument/completion", kotlin_buf), "Kotlin LSP completion support is missing")
assert(kotlin_client:supports_method("textDocument/formatting", kotlin_buf), "Kotlin LSP formatting support is missing")
assert_parser(kotlin_buf, "kotlin")

local kotlin_format_done = false
local kotlin_format_error
conform.format({ bufnr = kotlin_buf, async = true, lsp_format = "fallback", timeout_ms = 30000 }, function(err)
  kotlin_format_error = err
  kotlin_format_done = true
end)
assert(
  vim.wait(40000, function()
    return kotlin_format_done
  end, 100),
  "Kotlin LSP formatting timed out"
)
assert(kotlin_format_error == nil, "Kotlin LSP formatting failed: " .. tostring(kotlin_format_error))

rust_client:stop(true)
kotlin_client:stop(true)
vim.bo[rust_buf].modified = false
vim.bo[kotlin_buf].modified = false
vim.api.nvim_buf_delete(rust_buf, { force = true })
vim.api.nvim_buf_delete(kotlin_buf, { force = true })
vim.fn.delete(fixture, "rf")

print("AshenVim language integration test: ok")
