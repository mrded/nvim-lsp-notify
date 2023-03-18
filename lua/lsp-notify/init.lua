--- Options for the plugin
---@class LspNotifyConfig
local options = {
  notify = vim.notify,
  ---@type {spinner: string[] | false, done: string | false} | false
  icons = {
    spinner = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
    done = "󰗡"
  }
}



--#region Task

---@class BaseLspTask
local BaseLspTask = {
  ---@type string?
  title = "",
  ---@type string?
  message = "",
  ---@type number?
  percentage = nil
}

---@param title string
---@param message string
---@return BaseLspTask
function BaseLspTask.new(title, message)
  local self = vim.deepcopy(BaseLspTask)
  self.title = title
  self.message = message
  return self
end

function BaseLspTask:format()
  return (
    ("  ")
    .. (string.format(
      "%-8s",
      self.percentage and self.percentage .. "%" or ""
    ))
    .. (self.title and self.title .. " " or "")
    .. (self.message or "")
  )
end

--#endregion

--#region Client

---@class BaseLspClient
local BaseLspClient = {
  name = "",
  ---@type {any: BaseLspTask}
  tasks = {}
}

---@param name string
---@return BaseLspClient
function BaseLspClient.new(name)
  local self = vim.deepcopy(BaseLspClient)
  self.name = name
  return self
end

function BaseLspClient:count_tasks()
  local count = 0
  for _ in pairs(self.tasks) do
    count = count + 1
  end
  return count
end

function BaseLspClient:kill_task(task_id)
  self.tasks[task_id] = nil
end

function BaseLspClient:format()
  local tasks = ""
  for _, t in pairs(self.tasks) do
    tasks = tasks .. t:format() .. "\n"
  end

  return (
    (self.name)
    .. ("\n")
    .. (tasks ~= "" and tasks:sub(1, -2) or "  Complete")
  )
end

--#endregion

--#region Notification

---@class BaseLspNotification
local BaseLspNotification = {
  spinner = 1,
  ---@type {integer: BaseLspClient}
  clients = {},
  notification = nil,
  window = nil
}

---@return BaseLspNotification
function BaseLspNotification:new()
  return vim.deepcopy(BaseLspNotification)
end

function BaseLspNotification:count_clients()
  local count = 0
  for _ in pairs(self.clients) do
    count = count + 1
  end
  return count
end

function BaseLspNotification:notification_start()
  self.notification = options.notify(
    "",
    vim.log.levels.INFO,
    {
      title = self:format_title(),
      icon = (options.icons and options.icons.spinner and options.icons.spinner[1]) or nil,
      timeout = false,
      hide_from_history = false,
      on_open = function(window)
        self.window = window
      end
    }
  )
end

function BaseLspNotification:notification_progress()
  local message = self:format()
  self.notification = options.notify(
    message,
    vim.log.levels.INFO,
    {
      replace = self.notification,
      hide_from_history = false,
    }
  )
  if self.window then
    vim.api.nvim_win_set_height(
      self.window,
      3 + select(2, message:gsub('\n', '\n'))
    )
  end
end

function BaseLspNotification:notification_end()
  options.notify(
    self:format(),
    vim.log.levels.INFO,
    {
      replace = self.notification,
      icon = options.icons and options.icons.done or nil,
      timeout = 1000
    }
  )
  if self.window then
    vim.api.nvim_win_set_height(
      self.window,
      3
    )
  end

  self.notification = nil
  self.spinner = nil
  self.window = nil
end

function BaseLspNotification:update()
  if not self.notification then
    self:notification_start()
    self.spinner = 1
    self:spinner_start()
  elseif self:count_clients() > 0 then
    self:notification_progress()
  elseif self:count_clients() == 0 then
    self:notification_end()
  end
end

function BaseLspNotification:schedule_kill_task(client_id, task_id)
  vim.defer_fn(function()
    local client = self.clients[client_id]
    client:kill_task(task_id)
    self:update()

    if client:count_tasks() == 0 then
      vim.defer_fn(function()
        if client:count_tasks() == 0 then
          self.clients[client_id] = nil
          self:update()
        end
      end, 2000)
    end

  end, 1000)
end

function BaseLspNotification:format_title()
  return "LSP progress"
end

function BaseLspNotification:format()
  local clients = ""
  for _, c in pairs(self.clients) do
    clients = clients .. c:format() .. "\n"
  end

  return clients ~= "" and clients:sub(1, -2) or "Complete"
end

function BaseLspNotification:spinner_start()
  if self.spinner and options.icons and options.icons.spinner then
    self.spinner = (self.spinner % #options.icons.spinner) + 1

    self.notification = options.notify(nil, nil, {
      hide_from_history = true,
      icon = options.icons.spinner[self.spinner],
      replace = self.notification,
    })

    vim.defer_fn(function()
      self:spinner_start()
    end, 100)
  end
end

--#endregion

---#region Handlers

local notification = BaseLspNotification:new()

local function handle_progress(_, result, context)
  local value = result.value

  local client_id = context.client_id
  notification.clients[client_id] =
    notification.clients[client_id]
    or BaseLspClient.new(vim.lsp.get_client_by_id(client_id).name)
  local client = notification.clients[client_id]

  local task_id = result.token
  client.tasks[task_id] =
    client.tasks[task_id]
    or BaseLspTask.new(value.title, value.message)
  local task = client.tasks[task_id]

  if value.kind == "report" then
    task.message = value.message
    task.percentage = value.percentage
  elseif value.kind == "end" then
    task.message = value.message
    notification:schedule_kill_task(client_id, task_id)
  end

  notification:update()
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

--#endregion

--#region Setup

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

--#endregion
