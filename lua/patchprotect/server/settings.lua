----------------------
--  RESET SETTINGS  --
----------------------

local function resetSettings(ply, cmd, args, auto)
  -- all valid tables
  local tabs = {'all', 'help', 'antispam', 'propprotection', 'blocked_props', 'blocked_ents', 'blocked_tools', 'antispam_tools'}

  -- help for reset command
  if args[1] == 'help' then
    MsgC(Color(255, 0, 0), '\n[PatchProtect-Reset]', Color(255, 255, 255), ' Use all, antispam, propprotection, blocked_props, blocked_ents, blocked_tools or antispam_tools.\n')
    return
  end

  -- reset all sql-tables
  if args[1] == 'all' then
    table.foreach(tabs, function(key, value)
      sql.Query('DROP TABLE pprotect_' .. value)
    end)
    if auto == 'auto' then return end
    MsgC(Color(255, 0, 0), '\n[PatchProtect-Reset]', Color(255, 255, 255), ' Successfully deleted all sql-settings.\n', Color(255, 0, 0), '[PatchProtect-Reset]', Color(255, 255, 255), ' PLEASE RESTART YOUR SERVER.\n')
    return
  end

  -- check argument
  if !table.HasValue(tabs, args[1]) then
    MsgC(Color(255, 0, 0), '\n[PatchProtect-Reset]', Color(255, 255, 255), ' ' .. args[1] .. ' is not a valid sql-table.\n')
    return
  end

  -- delete sql-table
  sql.Query('DROP TABLE pprotect_' .. args[1])
  MsgC(Color(255, 0, 0), '\n[PatchProtect-Reset]', Color(255, 255, 255), ' Successfully deleted all ' .. args[1] .. '-settings.\n', Color(255, 0, 0), '[PatchProtect-Reset]', Color(255, 255, 255), ' PLEASE RESTART THE SERVER WHEN YOU ARE FINISHED WITH ALL RESETS.\n')
end
concommand.Add('pprotect_reset', resetSettings)

---------------------
--  LOAD SETTINGS  --
---------------------

-- ANTISPAM AND PROP PROTECTION
function sv_PProtect.loadSettings(name)
  local sqltable = 'pprotect_' .. string.lower(name)
  if !sql.TableExists(sqltable) then
    sql.Query('DROP TABLE ' .. sqltable)
  end
  sql.Query('CREATE TABLE IF NOT EXISTS ' .. sqltable .. ' (setting TEXT, value TEXT)')

  local sql_settings = {}

  -- Save/Load SQLSettings
  table.foreach(sv_PProtect.Config[name], function(setting, value)
    if !sql.Query('SELECT value FROM ' .. sqltable .. " WHERE setting = '" .. setting .. "'") then
      sql.Query('INSERT INTO ' .. sqltable .. " (setting, value) VALUES ('" .. setting .. "', '" .. tostring(value) .. "')")
    end

    sql_settings[setting] = sql.QueryValue('SELECT value FROM ' .. sqltable .. " WHERE setting = '" .. setting .. "'")
  end)

  -- Convert strings to numbers and booleans
  table.foreach(sql_settings, function(setting, value)
    if tonumber(value) != nil then
      sql_settings[setting] = tonumber(value)
    end
    if value == 'true' or value == 'false' then
      sql_settings[setting] = tobool(value)
    end
  end)

  return sql_settings
end

-- BLOCKED ENTS
function sv_PProtect.loadBlockedEnts(typ)
  if !sql.TableExists('pprotect_blocked_' .. typ) or !sql.Query('SELECT * FROM pprotect_blocked_' .. typ) then
    return {}
  end

  local sql_ents = {}
  table.foreach(sql.Query('SELECT * FROM pprotect_blocked_' .. typ), function(id, ent)
    sql_ents[ent.name] = ent.model
  end)

  return sql_ents
end

-- ANTISPAMMED/BLOCKED TOOLS
function sv_PProtect.loadBlockedTools(typ)
  if !sql.TableExists('pprotect_' .. typ .. '_tools') or !sql.Query('SELECT * FROM pprotect_' .. typ .. '_tools') then
    return {}
  end

  local sql_tools = {}
  table.foreach(sql.Query('SELECT * FROM pprotect_' .. typ .. '_tools'), function(ind, tool)
    sql_tools[tool.tool] = tobool(tool.bool)
  end)

  return sql_tools
end

-- LOAD SETTINGS
local sql_version = '2.3'
if !sql.TableExists('pprotect_version') or sql.QueryValue('SELECT * FROM pprotect_version') != sql_version then
  resetSettings(nil, nil, {'all'}, 'auto')
  sql.Query('DROP TABLE pprotect_version')
  sql.Query('CREATE TABLE IF NOT EXISTS pprotect_version (info TEXT)')
  sql.Query("INSERT INTO pprotect_version (info) VALUES ('" .. sql_version .. "')")
  MsgC(Color(255, 0, 0), '\n[PatchProtect-Reset]', Color(255, 255, 255), " Reset all sql-settings due a new sql-table-version, sry.\nYou don't need to resetart the server, but please check all settings. Thanks.\n")
end
sv_PProtect.Settings = {
  Antispam = sv_PProtect.loadSettings('Antispam'),
  Propprotection = sv_PProtect.loadSettings('Propprotection')
}
sv_PProtect.Blocked = {
  props = sv_PProtect.loadBlockedEnts('props'),
  ents = sv_PProtect.loadBlockedEnts('ents'),
  atools = sv_PProtect.loadBlockedTools('antispam'),
  btools = sv_PProtect.loadBlockedTools('blocked')
}
MsgC(Color(255, 255, 0), '\n[PatchProtect]', Color(255, 255, 255), ' Successfully loaded.\n\n')

---------------------
--  SAVE SETTINGS  --
---------------------

-- SAVE ANTISPAM/PROP PROTECTION
net.Receive('pprotect_save', function(len, pl)
  if !pl:IsSuperAdmin() then return end

  local data = net.ReadTable()
  sv_PProtect.Settings[data[1]] = data[2]
  sv_PProtect.sendSettings()

  -- SAVE TO SQL TABLES
  table.foreach(sv_PProtect.Settings[data[1]], function(setting, value)
    if !sql.Query('SELECT value FROM pprotect_' .. string.lower(data[1]) .. " WHERE setting = '" .. setting .. "'") then
      sql.Query('INSERT INTO pprotect_' .. string.lower(data[1]) .. " (setting, value) VALUES ('" .. setting .. "', '" .. tostring(value) .. "')")
    end
    sql.Query('UPDATE pprotect_' .. string.lower(data[1]) .. " SET value = '" .. tostring(value) .. "' WHERE setting = '" .. setting .. "'")
  end)

  sv_PProtect.Notify(pl, 'Saved new ' .. data[1] .. '-Settings', 'info')
  print('[PatchProtect - ' .. data[1] .. '] ' .. pl:Nick() .. ' saved new ' .. data[1] .. '-Settings.')
end)


--------------------------
--  BLOCKED PROPS/ENTS  --
--------------------------

-- SEND BLOCKED PROPS/ENTS TABLE
net.Receive('pprotect_request_ents', function(len, pl)
  if !pl:IsSuperAdmin() then return end
  local typ = net.ReadTable()[1]

  net.Start('pprotect_send_ents')
  net.WriteString(typ)
  net.WriteTable(sv_PProtect.Blocked[typ])
  net.Send(pl)
end)

-- SAVE BLOCKED PROPS/ENTS TABLE
net.Receive('pprotect_save_ents', function(len, pl)
  if !pl:IsSuperAdmin() then return end
  local d = net.ReadTable()
  local typ, key = d[1], d[2]

  sv_PProtect.Blocked[typ][key] = nil
  sv_PProtect.saveBlockedEnts(typ, sv_PProtect.Blocked[typ])
  print('[PatchProtect - AntiSpam] ' .. pl:Nick() .. ' removed ' .. key .. ' from the blocked-' .. typ .. '-list.')
end)

-- SAVE BLOCKED PROP/ENT FROM CPANEL
net.Receive('pprotect_save_cent', function(len, pl)
  if !pl:IsSuperAdmin() then return end
  local ent = net.ReadTable()

  if sv_PProtect.Blocked[ent.typ][ent.name] then
    sv_PProtect.Notify(pl, 'This object is already in the ' .. ent.typ .. '-list.', 'info')
    return
  end

  sv_PProtect.Blocked[ent.typ][string.lower(ent.name)] = string.lower(ent.model)
  sv_PProtect.saveBlockedEnts(ent.typ, sv_PProtect.Blocked[ent.typ])

  sv_PProtect.Notify(pl, 'Saved ' .. ent.name .. ' to blocked-' .. ent.typ .. '-list.', 'info')
  print('[PatchProtect - AntiSpam] ' .. pl:Nick() .. ' added ' .. ent.name .. ' to the blocked-' .. ent.typ .. '-list.')
end)

-- SAVE BLOCKED PROPS/ENTS
function sv_PProtect.saveBlockedEnts(typ, data)
  sql.Query('DROP TABLE pprotect_blocked_' .. typ)
  sql.Query('CREATE TABLE IF NOT EXISTS pprotect_blocked_' .. typ .. ' (name TEXT, model TEXT)')

  table.foreach(data, function(n, m)
    sql.Query('INSERT INTO pprotect_blocked_' .. typ .. " (name, model) VALUES ('" .. n .. "', '" .. m .. "')")
  end)
end

-- IMPORT BLOCKED PROPS LIST
concommand.Add('pprotect_import_blocked_props', function(ply, cmd, args)
  if !file.Read('pprotect_import_blocked_props.txt', 'DATA') then
    print("Cannot find 'pprotect_import_blocked_props.txt' to import props. Please read the description of patchprotect.")
    return
  end
  local imp = string.Explode(';', file.Read('pprotect_import_blocked_props.txt', 'DATA'))
  table.foreach(imp, function(key, model)
    if model == '' then return end
    model = string.lower(string.sub(model, string.find(model, 'models/'), string.find(model, ';')))
    if util.IsValidModel(model) and !sv_PProtect.Blocked.props[model] then
      sv_PProtect.Blocked.props[model] = model
    end
  end)
  sv_PProtect.saveBlockedEnts('props', sv_PProtect.Blocked.props)
  print("\n[PatchProtect] Imported all blocked props. If you experience any errors,\nthen use the command to reset the whole blocked-props-list:\n'pprotect_reset blocked_props'\n")
end)

--------------------------------
--  ANTISPAMED/BLOCKED TOOLS  --
--------------------------------

-- SEND ANTISPAMED/BLOCKED TOOLS TABLE
net.Receive('pprotect_request_tools', function(len, pl)
  if !pl:IsSuperAdmin() then return end
  local t = string.sub(net.ReadTable()[1], 1, 1) .. 'tools'
  local tools = {}

  table.foreach(weapons.GetList(), function(_, wep)
    if wep.ClassName != 'gmod_tool' then return end
    table.foreach(wep.Tool, function(name, tool)
      tools[name] = false
    end)
  end)

  table.foreach(sv_PProtect.Blocked[t], function(name, value)
    if value == true then
      tools[name] = true
    end
  end)

  net.Start('pprotect_send_tools')
  net.WriteString(t)
  net.WriteTable(tools)
  net.Send(pl)
end)

-- SAVE BLOCKED/ANTISPAMED TOOLS
net.Receive('pprotect_save_tools', function(len, pl)
  if !pl:IsSuperAdmin() then return end
  local d = net.ReadTable()
  local t1, t2, k, c = d[1], d[2], d[3], d[4]

  sv_PProtect.Blocked[t1][k] = c
  sv_PProtect.saveBlockedTools(t2, sv_PProtect.Blocked[t1])

  print('[PatchProtect - AntiSpam] ' .. pl:Nick() .. ' set "' .. k .. '" from ' .. t2 .. '-tools-list to "' .. tostring(c) .. '".')
end)

-- SAVE ANTISPAMED/BLOCKED TOOLS
function sv_PProtect.saveBlockedTools(typ, data)
  sql.Query('DROP TABLE pprotect_' .. typ .. '_tools')
  sql.Query('CREATE TABLE IF NOT EXISTS pprotect_' .. typ .. '_tools (tool TEXT, bool TEXT)')

  table.foreach(data, function(tool, bool)
    sql.Query('INSERT INTO pprotect_' .. typ .. "_tools (tool, bool) VALUES ('" .. tool .. "', '" .. tostring(bool) .. "')")
  end)
end

---------------
--  NETWORK  --
---------------

-- SEND SETTINGS
function sv_PProtect.sendSettings(ply, cmd, args)
  net.Start('pprotect_new_settings')
  net.WriteTable(sv_PProtect.Settings)
  if args and args[1] then
    net.WriteString(args[1])
  end
  if ply then
    net.Send(ply)
  else
    net.Broadcast()
  end
end
hook.Add('PlayerInitialSpawn', 'pprotect_playersettings', sv_PProtect.sendSettings)
concommand.Add('pprotect_request_new_settings', sv_PProtect.sendSettings)

-- SEND NOTIFICATION
function sv_PProtect.Notify(ply, text, typ)
  if ply == nil then
    for _, v in pairs( player.GetAll() ) do
      if typ == 'admin' and !v:IsAdmin() then continue end
      net.Start('pprotect_notify')
       net.WriteTable({text, typ})
      net.Send(v)
    end
  else
    net.Start('pprotect_notify')
     net.WriteTable({text, typ})
    net.Send(ply)
  end
end
