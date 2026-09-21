local M = {}

local suites = {}
local current
local cleanup_scope = {}

---@param name string
---@param body fun()
function M.describe(name, body)
  current = { name = name, tests = {}, before_all = {}, before_each = {}, after_each = {} }
  body()
  suites[#suites + 1] = current
  current = nil
end

local function suite()
  return assert(current, "it and hooks must be called inside describe")
end

---@param name string
---@param fn fun()
function M.it(name, fn)
  local tests = suite().tests
  tests[#tests + 1] = { name = name, fn = fn }
end

---@param fn fun()
function M.before_all(fn)
  local hooks = suite().before_all
  hooks[#hooks + 1] = fn
end

---@param fn fun()
function M.before_each(fn)
  local hooks = suite().before_each
  hooks[#hooks + 1] = fn
end

---@param fn fun()
function M.after_each(fn)
  local hooks = suite().after_each
  hooks[#hooks + 1] = fn
end

---@param fn fun()
function M.cleanup(fn)
  cleanup_scope[#cleanup_scope + 1] = fn
end

---@param reason string
function M.skip(reason)
  error({ skip = reason })
end

local function failure_of(fn)
  local ok, err = pcall(fn)
  if not ok then
    return err
  end
end

local function run_hooks(hooks)
  for _, hook in ipairs(hooks) do
    hook()
  end
end

local function run_cleanups(cleanups)
  for index = #cleanups, 1, -1 do
    cleanups[index]()
  end
end

local function run_test(owner, test)
  cleanup_scope = {}
  local failure = failure_of(function()
    run_hooks(owner.before_each)
    test.fn()
  end)
  local cleanups = cleanup_scope
  local teardown_failure = failure_of(function()
    run_hooks(owner.after_each)
    run_cleanups(cleanups)
  end)
  return failure or teardown_failure
end

local counts = { passed = 0, failed = 0, skipped = 0 }

local function report(name, failure)
  if failure == nil then
    counts.passed = counts.passed + 1
    io.write("  ok    ", name, "\n")
  elseif type(failure) == "table" and failure.skip then
    counts.skipped = counts.skipped + 1
    io.write("  skip  ", name, " (", failure.skip, ")\n")
  else
    counts.failed = counts.failed + 1
    io.write("  FAIL  ", name, "\n        ", tostring(failure):gsub("\n", "\n        "), "\n")
  end
end

local function run_suite(owner)
  io.write(owner.name, "\n")
  cleanup_scope = {}
  local setup_failure = failure_of(function()
    run_hooks(owner.before_all)
  end)
  local suite_cleanups = cleanup_scope

  for _, test in ipairs(owner.tests) do
    report(test.name, setup_failure or run_test(owner, test))
  end

  local teardown_failure = failure_of(function()
    run_cleanups(suite_cleanups)
  end)
  if teardown_failure then
    report("suite cleanup", teardown_failure)
  end
end

---@return boolean
function M.run()
  for _, owner in ipairs(suites) do
    run_suite(owner)
  end
  io.write(("\n%d passed, %d failed, %d skipped\n"):format(counts.passed, counts.failed, counts.skipped))
  return counts.failed == 0
end

return M
