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



---@class LspTask
---@field title string
---@field message string
---@field percentage integer

---@class BaseLspNotification
local BaseLspNotification = {
  id = nil,
  name = "",
  spinner = 1,
  ---@type {any: LspTask}
  tasks = {},
  notification = nil,
  window = nil
}

---@param id integer
---@param name string
---@return BaseLspNotification
function BaseLspNotification.new(id, name)
  local self = vim.deepcopy(BaseLspNotification)
  self.id = id
  self.name = name
  return self
end


function BaseLspNotification:format_title()
  return self.name
end

---@param task LspTask
---@return string
function BaseLspNotification.__format_task(task)
  return (
    string.format(
      "%-8s",
      task.percentage and task.percentage .. "%" or ""
    )
    .. ((task.title .. " ") or "")
    .. (task.message or "")
  )
end

function BaseLspNotification:format_message()
  local lines = ""
  for _, t in pairs(self.tasks) do
    lines = lines .. BaseLspNotification.__format_task(t) .. "\n"
  end
  return lines
end


function BaseLspNotification:__get_number_tasks()
  local count = 0
  for _ in pairs(self.tasks) do
    count = count + 1
  end
  return count
end


function BaseLspNotification:__notification_start()
  self.notification = options.notify(
    "Started",
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

function BaseLspNotification:__notification_progress()
  local message = self:format_message()
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
      2 + select(2, message:gsub('\n', '\n'))
    )
  end
end

function BaseLspNotification:__notification_end()
  options.notify(
    "Completed",
    vim.log.levels.INFO,
    {
      replace = self.notification,
      icon = options.icons and options.icons.done or nil,
      timeout = 1000
    }
  )
  self.notification = nil
  self.spinner = nil

  if self.window then
    vim.api.nvim_win_set_height(
      self.window,
      3
    )
  end
end

function BaseLspNotification:update()
  if not self.notification then
    self:__notification_start()
  elseif self:__get_number_tasks() > 0 then
    self:__notification_progress()
  elseif self:__get_number_tasks() == 0 then
    self:__notification_end()
  end
end


function BaseLspNotification:get_task(task_id)
  self.tasks[task_id] =
    self.tasks[task_id]
    or {
      title = "",
      message = "",
      percentage = 0
    }
  return self.tasks[task_id]
end

function BaseLspNotification:schedule_kill_task(task_id)
  vim.defer_fn(
    function()
      self.tasks[task_id] = nil
      self:update()
    end,
    1000
  )
end



-- TODO Move to BaseLspNotification
---@param notification BaseLspNotification
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


---@type {integer: BaseLspNotification}
local notifications = {}

---@param client_id integer
---@return BaseLspNotification
local function get_notification(client_id)
  notifications[client_id] =
    notifications[client_id]
    or BaseLspNotification.new(
      client_id,
      vim.lsp.get_client_by_id(client_id).name
    )
  return notifications[client_id]
end



local function handle_progress(_, result, context)
  local value = result.value

  local client_id = context.client_id
  local notification = get_notification(client_id)

  local task_id = result.token
  local task = notification:get_task(task_id)

  if value.kind == "begin" then
    task.title = value.title
    task.message = value.message

    notification:update()

  elseif value.kind == "report" then
    task.message = value.message
    task.percentage = value.percentage

    notification:update()

  elseif value.kind == "end" then
    task.message = value.message
    task.percentage = task.percentage and 100 or nil

    notification:update()
    notification:schedule_kill_task(task_id)
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
