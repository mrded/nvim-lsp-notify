---@class LspTask
---@field title string
---@field message string
---@field percentage integer

---@class LspNotification
---@field name string
---@field spinner integer
---@field tasks {any: LspTask}
---@field notification any
---@field window any



---@class LspNotifyConfig
local options = {
  notify = vim.notify,
  ---@type {spinner: string[] | false, done: string | false} | false
  icons = {
    spinner = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
    done = "󰗡"
  }
}



---@type {integer: LspNotification}
local notifications = {}

local function get_notification(client_id)
  notifications[client_id] =
    notifications[client_id]
    or {
      name = "",
      spinner = 1,
      tasks = {},
      notification = nil,
      window = nil
    }
  return notifications[client_id]
end

---@param notification LspNotification
local function get_task(notification, task_id)
  if not notification.tasks[task_id] then
    notification.tasks[task_id] = {
      title = "",
      message = "",
      percentage = 0
    }
  end
  return notification.tasks[task_id]
end

---@param notification LspNotification
local function count_tasks(notification)
  local count = 0
  for _, v in pairs(notification.tasks) do
    count = count + 1
  end
  return count
end

---@param notification LspNotification
local function update_spinner(notification)
  if notification.spinner then
    notification.spinner = (notification.spinner % #options.icons.spinner) + 1

    notification.notification = options.notify(nil, nil, {
      hide_from_history = true,
      icon = options.icons.spinner[notification.spinner],
      replace = notification.notification,
    })

    vim.defer_fn(function()
      update_spinner(notification)
    end, 100)
  end
end

---@param notification LspNotification
local function get_message(notification)
  local lines = ""
  for _, t in pairs(notification.tasks) do
    lines =
      lines
      .. (t.percentage and t.percentage .. "\t" or "    ")
      .. "" .. (t.title or "")
      .. " - " .. (t.message or "")
      .. ("\n")
  end
  return lines
end

---@param notification LspNotification
local function display_progress(notification)
  if (count_tasks(notification) > 0) then
    local message_computed = get_message(notification)
    notification.notification = options.notify(
      message_computed,
      vim.log.levels.INFO,
      {
        replace = notification.notification,
        hide_from_history = false,
      }
    )
    vim.api.nvim_win_set_height(
      notification.window,
      2 + select(2, message_computed:gsub('\n', '\n'))
    )
  else
    notification.notification = options.notify(
      "Completed",
      vim.log.levels.INFO,
      {
        replace = notification.notification,
        icon = options.icons and options.icons.done or nil,
        timeout = 1000
      }
    )
    vim.api.nvim_win_set_height(
      notification.window,
      3
    )
  end
end



local function handle_progress(_, result, context)
  local value = result.value

  local client_id = context.client_id
  local notification = get_notification(client_id)
  local client = vim.lsp.get_client_by_id(client_id)

  local task_id = result.token
  ---@type LspTask?
  local task = get_task(notification, task_id)

  if value.kind == "begin" then
    task.title = value.title or "LSP"
    task.message = value.message or "Loading ..."

    if (count_tasks(notification) == 1) then
      -- New LSP notification
      notification.name = client.name
      notification.notification = options.notify(
        "Started",
        vim.log.levels.INFO,
        {
          title = notification.name,
          icon = (options.icons and options.icons.spinner) and options.icons.spinner[1] or nil,
          timeout = false,
          hide_from_history = false,
          on_open = function(window)
            notification.window = window
          end
        }
      )
    end

  elseif value.kind == "report" then
    task.message = value.message
    task.percentage = value.percentage
    display_progress(notification)
  elseif value.kind == "end" then
    task.message = value.message
    task.percentage = task.percentage and 100 or nil

    display_progress(notification)

    vim.defer_fn(
      function()
        notification.tasks[task_id] = nil
        if count_tasks(notification) == 0 then
          display_progress(notification)
        end
      end,
      1000
    )

  end
end

local function handle_message(err, method, params, client_id)
  -- table from lsp severity to vim severity.
  local severity = {
    "error",
    "warn",
    "info",
    "info", -- map both hint and info to info?
  }
  options.notify(method.message, severity[params.type], { title = "LSP" })
end


local function init()
  if vim.lsp.handlers["$/progress"] then
    local handler = vim.lsp.handlers["$/progress"]
    vim.lsp.handlers["$/progress"] = function(...)
      handler(...)
      handle_progress(...)
    end
  end

  if vim.lsp.handlers["window/showMessage"] then
    local handler = vim.lsp.handlers["window/showMessage"]
    vim.lsp.handlers["window/showMessage"] = function(...)
      handler(...)
      handle_message(...)
    end
  end
end

return {
  ---@param opts LspNotifyConfig?
  setup = function(opts)
    options = vim.tbl_deep_extend("force", options, opts or {})
    init()
  end
}
