# Azure DevOps Telescope Plugin

Telescope plugin for Azure DevOps, using the Azure DevOps CLI

## Installation

### Pre-requisites

You must have the Azure CLI installed with the `azure-devops` extension added.

If you have `az` installed, you can run:

```
az extension add --name azure-devops
```

### Install

Install with your favourite package manager, for example with Lazy:

```lua
{
  'nvim-telescope/telescope.nvim',
  cmd = 'Telescope',
  config = function()
    require('telescope').setup({
      -- other config here
      extensions = {
        azure_devops = {
          organization = "" -- Custom ADO organization
          wiql = [[

          ]] -- Custom WIQL query to search through
        }
      }
    })
  end
  dependencies = {
    { 'danarth/telescope-ado.nvim' }
  },
}
```

### Configuration

| Property | Description | Default Value |
| --- | --- | --- |
| `organization` | Custom ADO org, e.g. `https://yourcompany.visualstudio.com` | none |
| `wiql` | Custom WIQL query | see below |

#### Default WIQL Query

```sql
SELECT
    [System.Id],
    [System.WorkItemType],
    [System.Title],
    [System.State]
FROM workitems
WHERE
    [System.WorkItemType] IN ('Product Backlog Item', 'Bug', 'Production Defect', 'Feature', 'Epic')
    AND [System.State] NOT IN ('Done', 'Removed')
    AND [System.ChangedDate] > @today - 180
```

### Setup

```lua
require('telescope').load_extension('azure_devops')
```

## Usage 

Command line:

```
Telescope azure_devops work_items
```

Using Lua:

```lua
require('telescope').extensions.azure_devops.work_items()
```

### Work Items

#### Key Mappings

| Key | Action |
| --- | --- |
| `<cr>` | Insert work item ID in buffer |
| `<c-c>` | Copy work item ID to clipboard |
| `<c-t>` | Open work item in new browser window |
