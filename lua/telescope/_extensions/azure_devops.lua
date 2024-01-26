local default_wiql = [[
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
]]

return require("telescope").register_extension {
  setup = function(ext_config)
    telescope_ado_wiql = ext_config.wiql or default_wiql
    telescope_ado_organization = ext_config.organization or ""
  end,
  exports = {
    work_items = require("telescope._extensions.azure_devops.work_items").work_items
  },
}
