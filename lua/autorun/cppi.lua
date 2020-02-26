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
  return '1.4.0'
end

-- Get interface version of CPPI
function CPPI:GetInterfaceVersion()
  return 1.3
end

-- Get name of player from UID
function CPPI:GetNameFromUID(uid)
  local ply = player.GetByUniqueID(uid)
  if !ply then return end
  return ply:Nick()
end

-- Get friends from a player
function PLAYER:CPPIGetFriends()
  local plist = {}
  for k,_ in pairs( self.Buddies or {} ) do
    table.insert(plist,player.GetBySteamID(k))
  end
  return plist
end

-- Get the owner of an entity
function ENTITY:CPPIGetOwner()
  local ply = sh_PProtect.GetOwner(self)
  if ply == nil or !IsValid(ply) or !ply:IsPlayer() then return nil, nil end
  return ply, ply:UniqueID()
end

if CLIENT then return end

-- Set owner of an entity
function ENTITY:CPPISetOwner(ply)
  return sv_PProtect.SetOwner(self, ply)
end

-- Set owner of an entity by UID
function ENTITY:CPPISetOwnerUID(uid)
  return self:CPPISetOwner(player.GetByUniqueID(uid))
end

-- Set entity to no world (true) or not even world (false)
-- It is not officially documented, but some addons seem to require this.
function ENTITY:CPPISetOwnerless(bool)
  if !IsValid(self) then return false end

  if bool then
    self:SetNWBool('pprotect_owner', nil)
    self:SetNWBool('pprotect_world', true)
  else
    self:SetNWBool('pprotect_owner', nil)
  end

  return true
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
