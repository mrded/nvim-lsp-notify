# nvim-lsp-notify

NVIM plugin to notify about LSP progress

### Motivation 

The motivation for this project was to address the uncertainty that can sometimes accompany the LSP process. 
I wanted to create a solution that would provide better visibility into the LSP's progress.

### Required dependencies

- [nvim-notify](https://github.com/rcarriga/nvim-notify) is required.

### Installation

```
Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'mrded/nvim-lsp-notify',
    requires = { 'rcarriga/nvim-notify' },
    config = function()
      require('lsp-notify').setup({})
    end
}
```

### Credits

I am deeply grateful to the creators of [nvim-notify](https://github.com/rcarriga/nvim-notify) for their invaluable contributions.
Their work, specifically the implementation of LSP notifications in their [usage recipes](https://github.com/rcarriga/nvim-notify/wiki/Usage-Recipes/#progress-updates), served as the foundation for this project, which has been developed into a convenient, standalone module.
