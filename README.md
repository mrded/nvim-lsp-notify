# nvim-lsp-notify

NVIM plugin to notify about LSP processes

### Motivation

The motivation was to address the uncertainty that can sometimes accompany using LSP.
I wanted to create a solution that would provide better visibility into the LSP's processes.

### Examples

![null-ls and lua-ls](https://user-images.githubusercontent.com/44075969/226129296-a7997008-9163-4b42-9b91-04d2816620f7.gif)
![null-ls and rust-analyzer](https://user-images.githubusercontent.com/44075969/226129502-ff6a14b9-42ba-45ec-94e4-45ac900c23f6.gif)

### Optional dependencies

- [nvim-notify](https://github.com/rcarriga/nvim-notify)

### Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

Basic setup will use `vim.notify()` for notifications:
```lua
use {
  'mrded/nvim-lsp-notify',
  config = function()
    require('lsp-notify').setup({})
  end
}
```

You can pass `notify` function, for example from [nvim-notify](https://github.com/rcarriga/nvim-notify):
```lua
use {
  'mrded/nvim-lsp-notify',
  requires = { 'rcarriga/nvim-notify' },
  config = function()
    require('lsp-notify').setup({
      notify = require('notify'),
    })
  end
}
```

Or `icons` to customize icons:
```lua
use {
  'mrded/nvim-lsp-notify',
  requires = { 'rcarriga/nvim-notify' },
  config = function()
    require('lsp-notify').setup({
      icons = {
        spinner = { '|', '/', '-', '\\' },      -- `= false` to disable only this icon
        done = '!'                              -- `= false` to disable only this icon
      }
    })
  end
}
```

Or `icons = false` to disable them completely:
```lua
use {
  'mrded/nvim-lsp-notify',
  requires = { 'rcarriga/nvim-notify' },
  config = function()
    require('lsp-notify').setup({
      icons = false
    })
  end
}
```

### Credits

I am deeply grateful to the creators of [nvim-notify](https://github.com/rcarriga/nvim-notify) for their invaluable contributions.
Their work, specifically the implementation of LSP notifications in their [usage recipes](https://github.com/rcarriga/nvim-notify/wiki/Usage-Recipes/#progress-updates), served as the foundation for this project, which has been developed into a convenient, standalone module.
