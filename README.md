# nvim-lsp-notify

NVIM plugin to notify about LSP processes

### Motivation 

The motivation was to address the uncertainty that can sometimes accompany using LSP. 
I wanted to create a solution that would provide better visibility into the LSP's processes.

### Examples
![image](https://user-images.githubusercontent.com/347098/212483632-d8a4a6d7-320e-4002-b263-6e736ac83c1d.png)
![image](https://user-images.githubusercontent.com/347098/212483720-e6c7b782-1aa1-49ad-b45a-8502b2b9cbf5.png)
![image](https://user-images.githubusercontent.com/347098/212483653-e1fb1f5a-5826-400a-b79e-cba754e4fe2e.png)

### Required dependencies

- [nvim-notify](https://github.com/rcarriga/nvim-notify)

### Installation

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
