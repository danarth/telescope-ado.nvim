local pickers = require "telescope.pickers"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local finders = require "telescope.finders"
local previewers = require "telescope.previewers"
local putils = require "telescope.previewers.utils"
local conf = require("telescope.config").values
local make_entry = require "telescope.make_entry"
local utils = require "telescope.utils"
local popup = require "plenary.popup"

local A = {}

local function msgLoadingPopup(msg, cmd, complete_fn)
  local row = math.floor((vim.o.lines - 5) / 2)
  local width = 20 + #msg
  local col = math.floor((vim.o.columns - width) / 2)
  for _ = 1, (width - #msg) / 2, 1 do
    msg = " " .. msg
  end
  local prompt_win, prompt_opts = popup.create(msg, {
    border = {},
    borderchars = conf.borderchars,
    height = 5,
    col = col,
    line = row,
    width = width,
  })
  vim.api.nvim_win_set_option(prompt_win, "winhl", "Normal:TelescopeNormal")
  vim.api.nvim_win_set_option(prompt_win, "winblend", 0)
  local prompt_border_win = prompt_opts.border and prompt_opts.border.win_id
  if prompt_border_win then
    vim.api.nvim_win_set_option(prompt_border_win, "winhl", "Normal:TelescopePromptBorder")
  end
  vim.defer_fn(
    vim.schedule_wrap(function()
      local results = utils.get_os_command_output(cmd)
      if not pcall(vim.api.nvim_win_close, prompt_win, true) then
        log.trace("Unable to close window: ", "azcli", "/", prompt_win)
      end
      complete_fn(results)
    end),
    10
  )
end

local Job = require("plenary.job")
local open_work_item = function(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    actions.close(prompt_bufnr)
    local tmp_table = vim.split(selection.value, "\t")
    if vim.tbl_isempty(tmp_table) then
      return
    end
    local id = tmp_table[1]
    local args = {
      "boards",
      "work-item",
      "show",
      "--id",
      id,
      "--open"
    }
    if telescope_ado_organization ~= "" then
      table.insert(args, "--organization")
      table.insert(args, telescope_ado_organization)
    end
    Job:new({command = "az", args = args}):start()
  end

local copy_work_item_id = function(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    actions.close(prompt_bufnr)
    local tmp_table = vim.split(selection.value, "\t")
    if vim.tbl_isempty(tmp_table) then
      return
    end
    local id = tmp_table[1]
    vim.fn.setreg("+", id)
end


local write_work_item_id = function(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    actions.close(prompt_bufnr)
    local tmp_table = vim.split(selection.value, "\t")
    if vim.tbl_isempty(tmp_table) then
      return
    end
    local id = tmp_table[1]
    vim.api.nvim_put({id}, "", true, true)
end

-- b for builtin function
A.work_items = function(opts)
  opts = opts or {}

  local cmd = vim.tbl_flatten {
    "az",
    "boards",
    "query",
    "-o",
    "tsv",
    "--wiql",
    telescope_ado_wiql,
    "--query",
    '[].fields.["System.Id", "System.WorkItemType", "System.Title", "System.State"]'
  }
  if telescope_ado_organization ~= "" then
    table.insert(cmd, "--organization")
    table.insert(cmd, telescope_ado_organization)
  end
  local title = "Work Items"
  msgLoadingPopup("Loading " .. title, cmd, function(results)
    if results[1] == "" then
      print("Empty " .. title)
      return
    end
    pickers.new(opts, {
      prompt_title = title,
      finder = finders.new_table {
        results = results,
        entry_maker = make_entry.gen_from_string(opts),
      },
      previewer = previewers.new_buffer_previewer {
        title = "Work Item Preview",
        teardown = function()end,

        get_buffer_by_name = function(_, entry)
          return entry.value
        end,

        define_preview = function(self, entry)
          local entry_cols = vim.split(entry.value, "\t")
          if vim.tbl_isempty(entry_cols) then
            return { "echo", "" }
          end
          local preview_cmd = {
            "az",
            "boards",
            "work-item",
            "show",
            "--id",
            entry_cols[1],
            "--query",
            [[
            fields.{
              id: "System.Id",
              type: "System.WorkItemType",
              title: "System.Title",
              state: "System.State",
              description: "System.Description",
              tags: "System.Tags",
              areaPath: "System.AreaPath",
              iterationPath: "System.IterationPath",
              assignedTo: "System.AssignedTo".displayName
            }
            ]]
          }
          if telescope_ado_organization ~= "" then
            table.insert(preview_cmd, "--organization")
            table.insert(preview_cmd, telescope_ado_organization)
          end
          putils.job_maker(preview_cmd, self.state.bufnr, {
            value = entry.value,
            bufname = self.state.bufname,
            cwd = opts.cwd,
            callback = function(bufnr)
              if vim.api.nvim_buf_is_valid(bufnr) then
                putils.highlighter(bufnr, "json")
              end
            end,
          })
        end,
      },
      sorter = conf.file_sorter(opts),
      attach_mappings = function(_, map)
        actions.select_default:replace(write_work_item_id)
        map("i", "<c-t>", open_work_item)
        map("i", "<c-c>", copy_work_item_id)
        return true
      end,
    }):find()
  end)
end

return A
