----------------------
--  GENERAL CHECKS  --
----------------------

-- CHECK FOR PROP PROTECTION ADMIN CONDITIONS
local function CheckPPAdmin(ply)
  if !sv_PProtect.Settings.Propprotection['enabled'] then return true end
  if !ply.ppadminbypass then return false end
  if !(ply.IsSuperAdmin and ply.IsAdmin) then return false end
  if ply:IsSuperAdmin() and sv_PProtect.Settings.Propprotection['superadmins'] then return true end
  if ply:IsAdmin() and sv_PProtect.Settings.Propprotection['admins'] then return true end
  return false
end

-- Checks if the given entity is a world prop and if players are allowed to interact with them for the given setting
-- ent: valid entity to check
-- sett: PatchProtect setting to use to check for world-premissions
local function CheckWorld(ent, sett)
  if sv_PProtect.Settings.Propprotection['world' .. sett] and sh_PProtect.IsWorld(ent) then return true end
  return false
end

-- GET DATA
local en, uc, ue, up, uf = nil, undo.Create, undo.AddEntity, undo.SetPlayer, undo.Finish
function undo.Create(typ)
  uc(typ)
  if en != nil then ErrorNoHaltWithStack("tried to create a new undo before the last one was finished! discarding unfinished undo!") end
  en = {
    e = {},
    o = nil
  }
end
function undo.AddEntity(ent)
  ue(ent)
  if en == nil then
    ErrorNoHaltWithStack("tried to add an entity to a nonexistant undo! Please run undo.Create first!")
    undo.Create("something")
    undo.AddEntity(ent)
  else
    table.insert(en.e, ent)
  end
end
function undo.SetPlayer(ply)
  up(ply)
  if en == nil then
    ErrorNoHaltWithStack("tried to add a player owner to a nonexistant undo! Please run undo.Create first!")
    undo.Create("something")
    undo.SetPlayer(ply)
  else
    en.o = ply
  end
end
function undo.Finish()
  uf()
  if en == nil then
    ErrorNoHaltWithStack("tried to finish a nonexistant undo! Please run undo.Create first")
    return
  end
  if en.o == nil then
    ErrorNoHaltWithStack("tried to finish an undo without any owner player! Please run undo.SetPlayer first")
  else
    if IsValid(en.o) and en.o:IsPlayer() then
      for _, ent in ipairs( en.e ) do
        if IsEntity(ent) and not ent.ppowner then
          ent:CPPISetOwner(en.o)
        end
        -- if the entity is a duplication or the PropInProp protection is disabled or the spawner is an admin (and accepted by PatchProtect) or it is not a physics prop, then don't check for penetrating props
        if sv_PProtect.Settings.Antispam['propinprop'] and (not CheckPPAdmin(en.o)) then
          local phys = ent:GetPhysicsObject()
          -- PropInProp-Protection
          if IsValid(phys) and phys:IsPenetrating() then
            sv_PProtect.Notify(en.o, 'You are not allowed to spawn a prop inside another object.')
            ent:Remove()
          end
        end
      end
    end
    en = nil
  end
end

hook.Add("PlayerSpawnedEffect","pprotection_setowner",function(ply,mdl,ent)
  ent:CPPISetOwner(ply)
end)
hook.Add("PlayerSpawnedNPC","pprotection_setowner",function(ply,ent)
  ent:CPPISetOwner(ply)
end)
hook.Add("PlayerSpawnedProp","pprotection_setowner",function(ply,mdl,ent)
  ent:CPPISetOwner(ply)
end)
hook.Add("PlayerSpawnedRagdoll","pprotection_setowner",function(ply,mdl,ent)
  ent:CPPISetOwner(ply)
end)
hook.Add("PlayerSpawnedSENT","pprotection_setowner",function(ply,ent)
  ent:CPPISetOwner(ply)
end)
hook.Add("PlayerSpawnedSWEP","pprotection_setowner",function(ply,ent)
  ent:CPPISetOwner(ply)
end)
hook.Add("PlayerSpawnedVehicle","pprotection_setowner",function(ply,ent)
  ent:CPPISetOwner(ply)
end)

-------------------------------
--  PHYSGUN PROP PROTECTION  --
-------------------------------

function sv_PProtect.CanPhysgun(ply, ent)
  -- Check Entity
  if !IsValid(ent) then return false end
  
  if ent:GetClass() == "vc_fuel_nozzle" then return end

  if sh_PProtect.CheckBlocked(ent,"phys") then return false end

  if ply == ent then return end

  ----if !IsValid(ply) then return false end

  -- Check Admin
  if CheckPPAdmin(ply) then return end

  -- Check World
  if CheckWorld(ent, 'pick') then return end

  -- Check Shared
  if sh_PProtect.IsShared(ent, 'phys') then return end

  -- Check Owner and Buddy
  local owner = sh_PProtect.GetOwner(ent)
  if ply == owner or sh_PProtect.IsBuddy(owner, ply, 'phys') then return end

  sv_PProtect.Notify(ply, 'You are not allowed to hold this object.')
  return false
end
hook.Add('PhysgunPickup', 'pprotect_touch', sv_PProtect.CanPhysgun)

----------------------------
--  TOOL PROP PROTECTION  --
----------------------------

function sv_PProtect.CanTool(ply, ent, tool)
  -- Check Protection
  if tool == 'creator' and !sv_PProtect.Settings.Propprotection['creator'] then
    sv_PProtect.Notify(ply, 'You are not allowed to use the creator tool on this server.')
    return false
  end

  -- Check Entity
  if !IsValid(ent) then return end

  if sh_PProtect.CheckBlocked(ent,"tool") then return false end

  --if !IsValid(ply) then return false end

  -- Check Admin
  if CheckPPAdmin(ply) then return end

  -- Check World
  if CheckWorld(ent, 'tool') then return end

  -- Check Shared
  if sh_PProtect.IsShared(ent, 'tool') then return end

  -- Check Owner and Buddy
  local owner = sh_PProtect.GetOwner(ent)
  if ply == owner or sh_PProtect.IsBuddy(owner, ply, 'tool') then return end

  sv_PProtect.Notify(ply, 'You are not allowed to use ' .. tool .. ' on this object.')
  return false
end
hook.Add('CanTool', 'pprotect_propprotection_toolgun', function(ply, trace, tool)
	return sv_PProtect.CanTool(ply, trace.Entity, tool)
end)

---------------------------
--  USE PROP PROTECTION  --
---------------------------

function sv_PProtect.CanUse(ply, ent)
  -- Check Protection and GameMode
  if !sv_PProtect.Settings.Propprotection['use'] or engine.ActiveGamemode() == 'prop_hunt' then return end

  --if !IsValid(ply) then return false end

  -- Check Admin
  if CheckPPAdmin(ply) then return end

  -- Check Entity
  if !IsValid(ent) then return false end

  -- Check World
  if CheckWorld(ent, 'use') then return end

  -- Check Shared
  if sh_PProtect.IsShared(ent, 'use') then return end

  -- Check Owner and Buddy
  local owner = sh_PProtect.GetOwner(ent)
  if ply == owner or sh_PProtect.IsBuddy(owner, ply, 'use') then return end

  sv_PProtect.Notify(ply, 'You are not allowed to use this object.')
  return false
end
hook.Add('PlayerUse', 'pprotect_use', sv_PProtect.CanUse)

------------------------------
--  PROP PICKUP PROTECTION  --
------------------------------

function sv_PProtect.CanPickup(ply, ent)
  -- Check Protection
  if !sv_PProtect.Settings.Propprotection['proppickup'] then return end

  --if !IsValid(ply) then return false end

  -- Check Admin
  if CheckPPAdmin(ply) then return end

  -- Check Entity
  if !IsValid(ent) then return false end

  -- Check World
  if CheckWorld(ent, 'use') then return end

  -- Check Shared
  if sh_PProtect.IsShared(ent, 'use') then return end

  -- Check Owner and Buddy
  local owner = sh_PProtect.GetOwner(ent)
  if ply == owner or sh_PProtect.IsBuddy(owner, ply, 'use') then return end

  sv_PProtect.Notify(ply, 'You are not allowed to pick up this object.')
  return false
end
hook.Add('AllowPlayerPickup', 'pprotect_proppickup', sv_PProtect.CanPickup)

--------------------------------
--  PROPERTY PROP PROTECTION  --
--------------------------------

function sv_PProtect.CanProperty(ply, property, ent)

  --if !IsValid(ply) then return false end

  -- Check Admin
  if CheckPPAdmin(ply) then return end

  -- Check Persist
  if property == 'persist' then
    sv_PProtect.Notify(ply, 'You are not allowed to persist this object.')
    return false
  end

  -- Check Entity
  if !IsValid(ent) then return false end

  -- Check World
  if CheckWorld(ent, 'tool') then return end

  -- Check Shared
  if sh_PProtect.IsShared(ent, 'tool') then return end

  -- Check Owner and Buddy
  local owner = sh_PProtect.GetOwner(ent)
  if ply == owner or sh_PProtect.IsBuddy(owner, ply, 'prop') then return end

  sv_PProtect.Notify(ply, 'You are not allowed to change the properties on this object.')
  return false
end
hook.Add('CanProperty', 'pprotect_property', sv_PProtect.CanProperty)
hook.Add('CanEditVariable','pprotect_editvariable', function(ent,ply,key)
	return sv_PProtect.CanProperty(ply, key, ent)
end)

function sv_PProtect.CanDrive(ply, ent)

  --if !IsValid(ply) then return false end

  -- Check Admin
  if CheckPPAdmin(ply) then return end

  -- Check Protection
  if !sv_PProtect.Settings.Propprotection['propdriving'] then
    sv_PProtect.Notify(ply, 'Driving objects is not allowed on this server.')
    return false
  end

  -- Check Entity
  if !IsValid(ent) then return false end

  -- Check World
  if CheckWorld(ent, 'pick') then return end
  
  -- Check Shared
  if sh_PProtect.IsShared(ent, 'phys') then return end

  -- Check Owner and Buddy
  local owner = sh_PProtect.GetOwner(ent)
  if ply == owner or sh_PProtect.IsBuddy(owner, ply, 'prop') then return end

  sv_PProtect.Notify(ply, 'You are not allowed to drive this object.')
  return false
end
hook.Add('CanDrive', 'pprotect_drive', sv_PProtect.CanDrive)

------------------------------
--  DAMAGE PROP PROTECTION  --
------------------------------

function sv_PProtect.CanDamage(ply, ent)
  -- Check Protection
  if !sv_PProtect.Settings.Propprotection['damage'] then return end

  -- Check Admin
  if CheckPPAdmin(ply) then return end

  -- Check Damage from Player in Vehicle
  if sv_PProtect.Settings.Propprotection['damageinvehicle'] and ply.InVehicle and ply:InVehicle() then
    sv_PProtect.Notify(ply, 'You are not allowed to damage other players while sitting in a vehicle.')
    return false
  end

  if ply:IsWorld() then return end

  -- Check Entity
  if !IsValid(ent) then return false end

  if ent:IsPlayer() then return end

  -- Check World
  if CheckWorld(ent, 'dmg') then return end

  -- Check Shared
  if sh_PProtect.IsShared(ent, 'dmg') then return end

  -- Check Owner and Buddy
  local owner = sh_PProtect.GetOwner(ent)
  if ply == owner or sh_PProtect.IsBuddy(owner, ply, 'dmg') then return end

  sv_PProtect.Notify(ply, 'You are not allowed to damage this object.')
  return false
end
hook.Add('EntityTakeDamage', 'pprotect_damage', function(ent, info)
  return sv_PProtect.CanDamage(info:GetAttacker():CPPIGetOwner() or info:GetAttacker(), ent)
end)

---------------------------------
--  PHYSGUN-RELOAD PROTECTION  --
---------------------------------

function sv_PProtect.CanPhysReload(ply, ent)
  -- Check Protection
  if !sv_PProtect.Settings.Propprotection['reload'] then return end

  if !IsValid(ply) then return false end

  -- Check Admin
  if CheckPPAdmin(ply) then return end

  -- Check Entity
  if !IsValid(ent) then return false end

  -- Check World
  if CheckWorld(ent, 'pick') then return end

  -- Check Owner and Buddy
  local owner = sh_PProtect.GetOwner(ent)
  if ply == owner or sh_PProtect.IsBuddy(owner, ply, 'phys') then return end

  sv_PProtect.Notify(ply, 'You are not allowed to unfreeze this object.')
  return false
end
hook.Add('CanPlayerUnfreeze', 'pprotect_physreload', sv_PProtect.CanPhysReload)

-------------------------------
--  GRAVGUN PUNT PROTECTION  --
-------------------------------

function sv_PProtect.CanGravPunt(ply, ent)
  -- Check Protection
  if !sv_PProtect.Settings.Propprotection['gravgun'] then return end

  --if !IsValid(ply) then return false end

  -- Check Admin
  if CheckPPAdmin(ply) then return end

  -- Check Entity
  if !IsValid(ent) then return false end

  -- Check World
  if CheckWorld(ent, 'pick') then return end
  -- I assume people don't want to allow both grabing and throwing props using gravity gun

  -- Check Owner and Buddy
  local owner = sh_PProtect.GetOwner(ent)
  if ply == owner or sh_PProtect.IsBuddy(owner, ply, 'phys') then return end

  sv_PProtect.Notify(ply, 'You are not allowed to punt this object.')
  return false
end
hook.Add('GravGunPunt', 'pprotect_gravpunt', sv_PProtect.CanGravPunt)

function sv_PProtect.CanGravPickup(ply, ent)
  -- Check Protection
  if !sv_PProtect.Settings.Propprotection['gravgun'] then return end

  --if !IsValid(ply) then return false end

  -- Check Admin
  if CheckPPAdmin(ply) then return end

  -- Check Entity
  if !IsValid(ent) then ply:DropObject() return false end

  -- Check World
  if CheckWorld(ent, 'grav') then return end

  --- Check Owner and Buddy
  local owner = sh_PProtect.GetOwner(ent)
  if ply == owner or sh_PProtect.IsBuddy(owner, ply, 'phys') then return end

  sv_PProtect.Notify(ply, 'You are not allowed to use the Grav-Gun on this object.')
  ply:DropObject()
  return false
end
hook.Add('GravGunOnPickedUp', 'pprotect_gravpickup', sv_PProtect.CanGravPickup)