-----------------------
--  CLIENT SETTINGS  --
-----------------------

-- Set default CSettings
local csettings_default = {
  ownerhud = true,
  fppmode = false,
  notes = true,
  adminbypass = true,
  nophysreload = false
}

-- Load/Create CSettings
function cl_PProtect.load_csettings()
  -- Create SQL-CSettings-Table
  if !sql.TableExists('pprotect_csettings') then
    sql.Query('CREATE TABLE IF NOT EXISTS pprotect_csettings (setting TEXT, value TEXT)')
  end
  -- Check/Load SQL-CSettings
  table.foreach(csettings_default, function(setting, value)
    local v = sql.QueryValue("SELECT value FROM pprotect_csettings WHERE setting = '" .. setting .. "'")
    if !v then
      sql.Query("INSERT INTO pprotect_csettings (setting, value) VALUES ('" .. setting .. "', '" .. tostring(value) .. "')")
      cl_PProtect.CSettings[setting] = value
    else
      cl_PProtect.CSettings[setting] = tobool(v)
    end
  end)
end

cl_PProtect.load_csettings()

-- Admin pickup
local function cl_PProtect_setAdminBypass()
  net.Start("pprotect_setadminbypass")
    net.WriteBool(cl_PProtect.CSettings["adminbypass"])
  net.SendToServer()
end

-- Physgun reload
local function cl_PProtect_setNoPhysReload()
  net.Start("pprotect_setnophysreload")
    net.WriteBool(cl_PProtect.CSettings["nophysreload"])
  net.SendToServer()
end

local function cl_PProtect_setSyncCSettings()
  cl_PProtect_setAdminBypass()
  cl_PProtect_setNoPhysReload()
end

hook.Add( "InitPostEntity", "PProtect_setSyncCSettings", function()
  cl_PProtect_setSyncCSettings()
  hook.Remove("InitPostEntity","PProtect_setSyncCSettings") -- just in case
end)

-- Update CSettings
function cl_PProtect.update_csetting(setting, value)
  sql.Query("UPDATE pprotect_csettings SET value = '" .. tostring(value) .. "' WHERE setting = '" .. setting .. "'")
  cl_PProtect.CSettings[setting] = value
  if setting == "adminbypass" then cl_PProtect_setAdminBypass() end
  if setting == "nophysreload" then cl_PProtect_setNoPhysReload() end
end

-- Reset CSettings
concommand.Add('pprotect_reset_csettings', function(ply, cmd, args)
  sql.Query('DROP TABLE pprotect_csettings')
  cl_PProtect.load_csettings()
  print('[PProtect-CSettings] Successfully reset all Client Settings.')
end)