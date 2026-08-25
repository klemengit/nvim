-- "Open with..." for the snacks explorer / file picker.
-- `o` opens a file with the system default (built-in snacks action);
-- `O` opens a menu of the desktop applications registered for that file type.

local M = {}

--- All directories that may contain .desktop files.
local function app_dirs()
  local data_home = vim.env.XDG_DATA_HOME or (vim.env.HOME .. "/.local/share")
  local data_dirs = vim.env.XDG_DATA_DIRS or "/usr/local/share:/usr/share"
  local dirs = { data_home .. "/applications" }
  for d in vim.gsplit(data_dirs, ":", { trimempty = true }) do
    table.insert(dirs, d .. "/applications")
  end
  -- flatpak exports are usually in XDG_DATA_DIRS already, but not always
  table.insert(dirs, data_home .. "/flatpak/exports/share/applications")
  table.insert(dirs, "/var/lib/flatpak/exports/share/applications")

  local seen, ret = {}, {}
  for _, d in ipairs(dirs) do
    if not seen[d] and vim.fn.isdirectory(d) == 1 then
      seen[d] = true
      table.insert(ret, d)
    end
  end
  return ret
end

--- Absolute path of a desktop id, e.g. "okularApplication_md.desktop".
local function desktop_path(id)
  for _, dir in ipairs(app_dirs()) do
    local p = dir .. "/" .. id
    if vim.fn.filereadable(p) == 1 then
      return p
    end
    -- ids may encode subdirectories with dashes (kde4-foo.desktop)
    local found = vim.fs.find(id, { path = dir, type = "file", limit = 1 })[1]
    if found then
      return found
    end
  end
end

--- Human-readable Name= from the [Desktop Entry] section.
local function desktop_name(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil
  end
  local in_entry = false
  for _, line in ipairs(lines) do
    if line:match("^%[") then
      in_entry = line == "[Desktop Entry]"
    elseif in_entry then
      local name = line:match("^Name%s*=%s*(.+)$")
      if name then
        return vim.trim(name)
      end
    end
  end
end

local function sh(cmd)
  local out = vim.system(cmd, { text = true }):wait()
  return out.code == 0 and out.stdout or nil
end

--- Desktop ids registered for a mime type: default first, then recommended, then the rest.
local function apps_for_mime(mime)
  local out = sh({ "gio", "mime", mime })
  if not out then
    return {}
  end

  local default, rec, reg, section = nil, {}, {}, nil
  for line in vim.gsplit(out, "\n", { trimempty = true }) do
    if line:match("^Default application") then
      default, section = line:match("([^%s]+%.desktop)%s*$"), nil
    elseif line:match("^Recommended applications") then
      section = rec
    elseif line:match("^Registered applications") then
      section = reg
    elseif section and line:match("^%s") then
      local id = vim.trim(line)
      if id:match("%.desktop$") then
        table.insert(section, id)
      end
    end
  end

  local seen, ids = {}, {}
  for _, id in ipairs(vim.list_extend(vim.list_extend({ default }, rec), reg)) do
    if id and not seen[id] then
      seen[id] = true
      table.insert(ids, id)
    end
  end
  return ids
end

--- Run a command detached, so it survives closing Neovim.
local function spawn(cmd)
  vim.fn.jobstart(cmd, { detach = true })
end

--- Show the "Open with" menu for one or more files.
---@param files string[]
function M.open_with(files)
  files = vim.tbl_filter(function(f)
    return f and f ~= ""
  end, files or {})
  if #files == 0 then
    return vim.notify("Open with: no file selected", vim.log.levels.WARN)
  end

  local mime = sh({ "xdg-mime", "query", "filetype", files[1] })
  mime = mime and vim.trim(mime) or "application/octet-stream"

  ---@type { label: string, run: fun() }[]
  local choices = {}
  for _, id in ipairs(apps_for_mime(mime)) do
    local path = desktop_path(id)
    if path then
      table.insert(choices, {
        label = (desktop_name(path) or id:gsub("%.desktop$", "")) .. "  (" .. id .. ")",
        run = function()
          spawn(vim.list_extend({ "gio", "launch", path }, files))
        end,
      })
    end
  end

  table.insert(choices, {
    label = "xdg-open  (system default)",
    run = function()
      for _, f in ipairs(files) do
        spawn({ "xdg-open", f })
      end
    end,
  })
  table.insert(choices, {
    label = "Custom command...",
    run = function()
      vim.ui.input({ prompt = "Command: " }, function(cmd)
        if cmd and cmd ~= "" then
          spawn(vim.list_extend(vim.split(cmd, "%s+", { trimempty = true }), files))
        end
      end)
    end,
  })

  local title = #files == 1 and ("Open " .. vim.fn.fnamemodify(files[1], ":t") .. " (" .. mime .. ") with")
    or ("Open " .. #files .. " files (" .. mime .. ") with")

  vim.ui.select(choices, {
    prompt = title,
    format_item = function(c)
      return c.label
    end,
  }, function(choice)
    if choice then
      choice.run()
    end
  end)
end

--- Picker action: use the selected items, falling back to the item under the cursor.
local function picker_open_with(picker, item)
  local files = {}
  for _, it in ipairs(picker:selected({ fallback = true })) do
    table.insert(files, Snacks.picker.util.path(it))
  end
  if #files == 0 and item then
    files = { Snacks.picker.util.path(item) }
  end
  M.open_with(files)
end

local source = {
  actions = { open_with = picker_open_with },
  win = { list = { keys = { ["O"] = "open_with" } } },
}

return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = vim.deepcopy(source),
          files = vim.deepcopy(source),
        },
      },
    },
    keys = {
      {
        "<leader>fO",
        function()
          M.open_with({ vim.api.nvim_buf_get_name(0) })
        end,
        desc = "Open current file with...",
      },
    },
  },
}
