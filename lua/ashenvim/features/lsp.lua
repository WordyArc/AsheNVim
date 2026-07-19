local M = {}

---@param picker AshenPickerProvider
function M.setup(picker)
  local group = vim.api.nvim_create_augroup("AshenVimLsp", { clear = true })

  local function setup_document_highlight(buf)
    local autocmds = vim.api.nvim_get_autocmds({
      group = group,
      event = "CursorHold",
      buffer = buf,
    })
    if #autocmds > 0 then
      return
    end

    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
      group = group,
      buffer = buf,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      group = group,
      buffer = buf,
      callback = vim.lsp.buf.clear_references,
    })
  end

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    desc = "Configure LSP buffer mappings",
    callback = function(event)
      local client = assert(vim.lsp.get_client_by_id(event.data.client_id))
      local buf = event.buf

      local function supports(method)
        return client:supports_method(method, buf)
      end

      local function map(method, mode, lhs, rhs, desc)
        if method == nil or supports(method) then
          vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
        end
      end

      map("textDocument/definition", "n", "gd", function()
        picker.open("definitions")
      end, "Goto definition")
      map("textDocument/references", "n", "grr", function()
        picker.open("references")
      end, "References")
      map("textDocument/implementation", "n", "gri", function()
        picker.open("implementations")
      end, "Goto implementation")
      map("textDocument/typeDefinition", "n", "grt", function()
        picker.open("type_definitions")
      end, "Goto type definition")
      map("textDocument/declaration", "n", "gD", vim.lsp.buf.declaration, "Goto declaration")
      map("textDocument/hover", "n", "K", vim.lsp.buf.hover, "Hover")
      map("textDocument/signatureHelp", "n", "gK", vim.lsp.buf.signature_help, "Signature help")
      map("textDocument/codeAction", { "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
      map("textDocument/rename", "n", "<leader>cr", vim.lsp.buf.rename, "Rename")
      map("textDocument/documentSymbol", "n", "<leader>ss", function()
        picker.open("document_symbols")
      end, "Document symbols")
      map("workspace/symbol", "n", "<leader>sS", function()
        picker.open("workspace_symbols")
      end, "Workspace symbols")
      map(nil, "n", "<leader>cl", "<cmd>checkhealth vim.lsp<cr>", "LSP info")

      if supports("textDocument/inlayHint") and not vim.b[buf].ashenvim_inlay_hints_initialized then
        vim.b[buf].ashenvim_inlay_hints_initialized = true
        vim.lsp.inlay_hint.enable(true, { bufnr = buf })
      end

      if supports("textDocument/documentHighlight") then
        setup_document_highlight(buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd("LspDetach", {
    group = group,
    desc = "Clear LSP references",
    callback = function(event)
      vim.lsp.util.buf_clear_references(event.buf)
    end,
  })
end

return M
