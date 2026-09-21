local tests_dir = vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(_G.arg[0])))
package.path = tests_dir .. "/lib/?.lua;" .. package.path

dofile(assert(_G.arg[1], "usage: nvim -u init.lua -l tests/lib/run.lua <spec.lua>"))

if not require("harness").run() then
  vim.cmd("cquit 1")
end
