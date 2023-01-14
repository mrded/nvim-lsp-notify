local notify = require('notify')
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

    notif_data.notification = notify(message, "info", {
      title = title,
      timeout = false,
      hide_from_history = false,
    })

  elseif val.kind == "report" and notif_data then
    local message = (val.percentage and val.percentage .. "%\t" or "") .. (val.message or "")

    notif_data.notification = notify(message, "info", {
      replace = notif_data.notification,
      hide_from_history = false,
    })

  elseif val.kind == "end" and notif_data then
    local message = val.message or "Complete"

    notif_data.notification = notify(message, "info", {
      replace = notif_data.notification,
      timeout = 3000,
    })
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
  notify(method.message, severity[params.type], { title = "LSP" })
end

return {
  setup = function()
    -- TODO: add config options
  end
}
