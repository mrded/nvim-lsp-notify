---@type LspNotifyConfig
local options = nil

local client_notifs = {}

local function get_notif_data(client_id, token)
  if not client_notifs[client_id] then
    client_notifs[client_id] = {}
  end

  if not client_notifs[client_id][token] then
    client_notifs[client_id][token] = {}
  end

  return client_notifs[client_id][token]
end

local function update_spinner(client_id, token)
  local notif_data = get_notif_data(client_id, token)

  if notif_data.spinner then
    notif_data.spinner = (notif_data.spinner % #options.icons.spinner) + 1

    notif_data.notification = options.notify(nil, nil, {
      hide_from_history = true,
      icon = options.icons.spinner[notif_data.spinner],
      replace = notif_data.notification,
    })

    vim.defer_fn(function()
      update_spinner(client_id, token)
    end, 100)
  end
end


vim.lsp.handlers["$/progress"] = function(_, result, ctx)
  local val = result.value

  if not val.kind then
    return
  end

  local client_id = ctx.client_id

  local notif_data = get_notif_data(client_id, result.token)

  if val.kind == "begin" then
    local message = val.message or "Loading..."
    local title = val.title or vim.lsp.get_client_by_id(client_id).name or "Notification"

    notif_data.notification = options.notify(message, "info", {
      title = title,
      icon = options.icons.spinner and options.icons.spinner[1] or nil,
      timeout = false,
      hide_from_history = false,
    })

    if options.icons.spinner then
      notif_data.spinner = 1
      update_spinner(client_id, result.token)
    end

  elseif val.kind == "report" and notif_data then
    local message = (val.percentage and val.percentage .. "%\t" or "") .. (val.message or "")

    notif_data.notification = options.notify(message, "info", {
      replace = notif_data.notification,
      hide_from_history = false,
    })

  elseif val.kind == "end" and notif_data then
    local message = val.message or "Complete"

    notif_data.notification = options.notify(message, "info", {
      icon = options.icons.done or nil,
      replace = notif_data.notification,
      timeout = 3000,
    })

    notif_data.spinner = nil
  end
end

vim.lsp.handlers["window/showMessage"] = function(err, method, params, client_id)
  -- table from lsp severity to vim severity.
  local severity = {
    "error",
    "warn",
    "info",
    "info", -- map both hint and info to info?
  }
  options.notify(method.message, severity[params.type], { title = "LSP" })
end

---@class LspNotifyConfig
local default_options = {
  notify = vim.notify,
  icons = {
    ---@type string[] | false
    spinner = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
    ---@type string | false
    done = "󰗡"
  }
}

return {
  ---@param opts LspNotifyConfig?
  setup = function(opts)
    options = vim.tbl_deep_extend("force", default_options, opts or {})
  end
}
