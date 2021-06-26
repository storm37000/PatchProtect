--------------------------------
--  LOAD SERVER/CLIENT FILES  --
--------------------------------

-- Create shared table
sh_PProtect = {}

--update version in line with github commit #
sh_PProtect.version = 463

-- Include shared files
include('patchprotect/shared/patchprotect.lua')

if SERVER then
  -- Create server table
  sv_PProtect = {
    Settings = {}
  }

  -- Include server files
  include('patchprotect/server/config.lua')
  include('patchprotect/server/antispam.lua')
  include('patchprotect/server/propprotection.lua')
  include('patchprotect/server/cleanup.lua')
  include('patchprotect/server/buddy.lua')

  -- Force clients to download all client files
  AddCSLuaFile()
  AddCSLuaFile('patchprotect/client/csettings.lua')
  AddCSLuaFile('patchprotect/client/fonts.lua')
  AddCSLuaFile('patchprotect/client/hud.lua')
  AddCSLuaFile('patchprotect/client/derma.lua')
  AddCSLuaFile('patchprotect/client/panel.lua')
  AddCSLuaFile('patchprotect/client/propprotection.lua')

  -- Force clients to download all shared files
  AddCSLuaFile('patchprotect/shared/patchprotect.lua')
else
  -- Create client table
  cl_PProtect = {
    Settings = {
      Antispam = {},
      Propprotection = {}
    },
    CSettings = {}
  }

  -- Include client files
  include('patchprotect/client/csettings.lua')
  include('patchprotect/client/fonts.lua')
  include('patchprotect/client/hud.lua')
  include('patchprotect/client/derma.lua')
  include('patchprotect/client/panel.lua')
  include('patchprotect/client/propprotection.lua')
end
