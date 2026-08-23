-- http://ulyssesmod.net/archive/CPPI_v1-3.pdf

CPPI = CPPI or {}

CPPI.CPPI_DEFER = 8080
CPPI.CPPI_NOTIMPLEMENTED = 9090

local PLAYER = FindMetaTable('Player')
local ENTITY = FindMetaTable('Entity')

--ENTITY.old_InstallDataTable = ENTITY.InstallDataTable
--function ENTITY:InstallDataTable()
--  self:old_InstallDataTable()
--  self:DTVar( "Entity","ppowner" )
--end

hook.Add( "OnEntityCreated", "pprotect_ownership_net", function( ent )
  if not ent.InstallDataTable then ent.InstallDataTable = ENTITY.InstallDataTable end
  if not ent.NetworkVar then ent:InstallDataTable() ent.InstallDataTable = function() end end
  ent:NetworkVar( "Entity","ppowner" ) --this doesnt work for base_gmodentity for some reason?
  --print(ent,"ppowner created")
  --PrintTable(ent.dt)
--  function ent:Getppowner()
--    return self:GetDTEntity(1)
--  end
--  function ent:Setppowner(owner)
--    return self:SetDTEntity(1,owner)
--  end
--  timer.Simple(0, function()
--    if not IsValid(ent) then return end
--    for k, v in ipairs( ent:GetInternalVariable("m_GMOD_EHANDLE") ) do
--      print( k, v )
--    end
--  end)
end )

-- Get name of prop protection
function CPPI:GetName()
  return 'PatchProtect'
end

-- Get version of prop protection
function CPPI:GetVersion()
  return sh_PProtect.version
end

-- Get interface version of CPPI
function CPPI:GetInterfaceVersion()
  return 1.3
end

-- Get name of player from UID
function CPPI:GetNameFromUID(uid)
  if !uid then return end
  local ply = player.GetByUniqueID(uid)
  if !ply then return end
  return ply:Nick()
end

-- Get friends from a player
function PLAYER:CPPIGetFriends()
  local plist = {}
  for _, ply in player.Iterator() do
    if sh_PProtect.IsBuddy(self, ply) then
      table.insert(plist,ply)
    end
  end
  return plist
end

-- Get the owner of an entity
function ENTITY:CPPIGetOwner()
  if not self.Getppowner then return end
  local owner = self:Getppowner()
  if owner == NULL then return end
  return owner, CPPI.CPPI_NOTIMPLEMENTED
end

if CLIENT then return end

-- Set owner of an entity
function ENTITY:CPPISetOwner(ply)
  --print(self,"ppowner set")
  if not self.Setppowner then return false end
  if hook.Run('CPPIAssignOwnership', ply, self, CPPI.CPPI_NOTIMPLEMENTED) == false then return false end
    self:Setppowner(ply)
  return true
end

-- Set owner of an entity by UID
function ENTITY:CPPISetOwnerUID(uid)
  if uid == nil then return self:CPPISetOwner(nil) end
  ply = player.GetByUniqueID(uid)
  if not ply then return false end
  return self:CPPISetOwner(ply)
end

-- Set entity to world (true) or not even world (false)
-- It is not officially documented, but some addons seem to require this.
function ENTITY:CPPISetOwnerless(bool)  
  return self:CPPISetOwner(nil)
end

-- Can tool
function ENTITY:CPPICanTool(ply, tool)
  local ret = sv_PProtect.CanTool(ply, self, tool)
  if ret == nil then return true end
  return ret
end

-- Can physgun
function ENTITY:CPPICanPhysgun(ply)
  local ret = sv_PProtect.CanPhysgun(ply, self)
  if ret == nil then return true end
  return ret
end

-- Can pickup
function ENTITY:CPPICanPickup(ply)
  local ret = sv_PProtect.CanPickup(ply, self)
  if ret == nil then return true end
  return ret
end

-- Can punt
function ENTITY:CPPICanPunt(ply)
  local ret = sv_PProtect.CanGravPunt(ply, self)
  if ret == nil then return true end
  return ret
end

-- Can use
function ENTITY:CPPICanUse(ply)
  local ret = sv_PProtect.CanUse(ply, self)
  if ret == nil then return true end
  return ret
end

-- Can damage
function ENTITY:CPPICanDamage(ply)
  local ret = sv_PProtect.CanDamage(ply, self)
  if ret == nil then return true end
  return ret
end

-- Can drive
function ENTITY:CPPICanDrive(ply)
  local ret = sv_PProtect.CanDrive(ply, self)
  if ret == nil then return true end
  return ret
end

-- Can property
function ENTITY:CPPICanProperty(ply, property)
  local ret = sv_PProtect.CanProperty(ply, property, self)
  if ret == nil then return true end
  return ret
end

-- Can edit variable
function ENTITY:CPPICanEditVariable(ply, key, val, edit)
  local ret = sv_PProtect.CanProperty(ply, key, self)
  if ret == nil then return true end
  return ret
end
