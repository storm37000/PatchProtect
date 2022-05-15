-- http://ulyssesmod.net/archive/CPPI_v1-3.pdf

CPPI = CPPI or {}

CPPI.CPPI_DEFER = 8080
CPPI.CPPI_NOTIMPLEMENTED = 9090

local PLAYER = FindMetaTable('Player')
local ENTITY = FindMetaTable('Entity')

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
  for _,ply in ipairs( player.GetAll() ) do
    if sh_PProtect.IsBuddy(self, ply) then
      table.insert(plist,ply)
    end
  end
  return plist
end

-- Get the owner of an entity
function ENTITY:CPPIGetOwner()
  local ply = sh_PProtect.GetOwner(self)
  if ply == nil then return nil,nil end
  if ply == "wait" then return CPPI.CPPI_DEFER,CPPI.CPPI_DEFER end
  return ply, CPPI.CPPI_NOTIMPLEMENTED
end

if CLIENT then return end

-- Set owner of an entity
function ENTITY:CPPISetOwner(ply)
  if hook.Run('CPPIAssignOwnership', ply, self, CPPI.CPPI_NOTIMPLEMENTED) == false then return false end
  self:SetNWEntity("ppowner", ply)
  self:SetNWString("ppownerid", ply:SteamID())
  self.ppowner = ply
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
