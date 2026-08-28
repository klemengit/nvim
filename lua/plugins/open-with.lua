-- "Open with..." for the snacks explorer / file picker.
-- `o` opens the selected file(s) with the system default application;
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

--- Keys of the [Desktop Entry] section, unlocalised (Name, Terminal, Exec, ...).
---@return table<string, string>
local function desktop_entry(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return {}
  end
  local entry, in_entry = {}, false
  for _, line in ipairs(lines) do
    if line:match("^%[") then
      in_entry = line == "[Desktop Entry]"
    elseif in_entry then
      local key, val = line:match("^([%w-]+)%s*=%s*(.*)$")
      if key and not entry[key] then
        entry[key] = vim.trim(val)
      end
    end
  end
  return entry
end

--- Human-readable Name= of a desktop entry.
local function desktop_name(path)
  local name = desktop_entry(path).Name
  return name ~= "" and name or nil
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
--- Failures are reported instead of being swallowed: a silent no-op is the
--- usual symptom of a missing handler or a Terminal=true entry that could not
--- find a terminal.
---@param cmd string[]
---@param what? string label used in the failure message
local function spawn(cmd, what)
  vim.system(cmd, { detach = true, text = true }, function(out)
    if out.code ~= 0 then
      local msg = vim.trim((out.stderr or "") .. " " .. (out.stdout or ""))
      vim.schedule(function()
        vim.notify(
          ("Failed to open %s (exit %d)\n%s\n%s"):format(what or cmd[1], out.code, table.concat(cmd, " "), msg),
          vim.log.levels.ERROR
        )
      end)
    end
  end)
end

--- Mime type of a file, e.g. "text/x-lua".
local function mime_of(file)
  local mime = sh({ "xdg-mime", "query", "filetype", file })
  return mime and vim.trim(mime) or "application/octet-stream"
end

--- Open one or more files with their default application.
--- Resolves the default via `gio mime`, which follows mime subclassing (so
--- text/javascript inherits the text/plain handler) where `xdg-mime query
--- default` returns nothing. Falls back to xdg-open when nothing is registered.
--- Open files in the current window: the first replaces it, the rest are added
--- to the buffer list.
---@param files string[]
local function edit_here(files)
  vim.cmd.edit(vim.fn.fnameescape(files[1]))
  for i = 2, #files do
    vim.cmd.badd(vim.fn.fnameescape(files[i]))
  end
  if #files > 1 then
    vim.notify(("Opened %s, added %d more to the buffer list"):format(vim.fn.fnamemodify(files[1], ":t"), #files - 1))
  end
end

---@param files string[]
---@param edit? fun(files: string[]) how to open files handled by a terminal app
function M.open_default(files, edit)
  files = vim.tbl_filter(function(f)
    return f and f ~= ""
  end, files or {})
  if #files == 0 then
    return vim.notify("Open: no file selected", vim.log.levels.WARN)
  end

  local to_edit = {}
  for _, f in ipairs(files) do
    local mime = mime_of(f)
    local id = apps_for_mime(mime)[1]
    local path = id and desktop_path(id)
    local entry = path and desktop_entry(path) or {}
    local name = vim.fn.fnamemodify(f, ":t")
    if entry.Terminal == "true" then
      -- the default handler is a terminal app (nvim itself, for most text
      -- files) -- open it here instead of spawning a second editor
      table.insert(to_edit, f)
    elseif path then
      vim.notify(("Opening %s with %s"):format(name, desktop_name(path) or id), vim.log.levels.INFO)
      spawn({ "gio", "launch", path, f }, desktop_name(path) or id)
    else
      vim.notify(("No app registered for %s (%s); trying xdg-open"):format(name, mime), vim.log.levels.WARN)
      spawn({ "xdg-open", f }, "xdg-open")
    end
  end

  if #to_edit > 0 then
    (edit or edit_here)(to_edit)
  end
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

  local mime = mime_of(files[1])

  ---@type { label: string, run: fun() }[]
  local choices = {}
  for _, id in ipairs(apps_for_mime(mime)) do
    local path = desktop_path(id)
    if path then
      table.insert(choices, {
        label = (desktop_name(path) or id:gsub("%.desktop$", "")) .. "  (" .. id .. ")",
        run = function()
          spawn(vim.list_extend({ "gio", "launch", path }, files), desktop_name(path) or id)
        end,
      })
    end
  end

  table.insert(choices, {
    label = "xdg-open  (system default)",
    run = function()
      for _, f in ipairs(files) do
        spawn({ "xdg-open", f }, "xdg-open")
      end
    end,
  })
  table.insert(choices, {
    label = "Custom command...",
    run = function()
      vim.ui.input({ prompt = "Command: " }, function(cmd)
        if cmd and cmd ~= "" then
          spawn(vim.list_extend(vim.split(cmd, "%s+", { trimempty = true }), files), cmd)
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

--- Selected picker items, falling back to the item under the cursor.
local function picker_files(picker, item)
  local files = {}
  for _, it in ipairs(picker:selected({ fallback = true })) do
    table.insert(files, Snacks.picker.util.path(it))
  end
  if #files == 0 and item then
    files = { Snacks.picker.util.path(item) }
  end
  return files
end

local source = {
  actions = {
    open_with = function(picker, item)
      M.open_with(picker_files(picker, item))
    end,
    open_default = function(picker, item)
      M.open_default(picker_files(picker, item), function(files)
        -- open in the editor window the picker was called from, never in the
        -- picker's own window
        local function go()
          if picker.main and vim.api.nvim_win_is_valid(picker.main) then
            vim.api.nvim_set_current_win(picker.main)
          end
          edit_here(files)
        end
        if vim.fn.mode():sub(1, 1) == "i" then
          vim.cmd.stopinsert()
          vim.schedule(go)
        else
          go()
        end
      end)
    end,
  },
  -- bound on the list window, and on the input window in normal mode, so the
  -- keys work no matter which half of the picker has focus
  win = {
    list = { keys = { ["o"] = "open_default", ["O"] = "open_with" } },
    input = { keys = { ["o"] = { "open_default", mode = "n" }, ["O"] = { "open_with", mode = "n" } } },
  },
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
