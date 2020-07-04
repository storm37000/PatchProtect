----------------------
--  GENERAL CHECKS  --
----------------------

-- CHECK FOR PROP PROTECTION ADMIN CONDITIONS
local function CheckPPAdmin(ply)
  -- allow if PatchProtect is disabled or for SuperAdmins (if enabled) or for Admins (if enabled)
  if !sv_PProtect.Settings.Propprotection['enabled'] or (sv_PProtect.Settings.Propprotection['superadmins'] and ply:IsSuperAdmin()) or (sv_PProtect.Settings.Propprotection['admins'] and ply:IsAdmin()) then return true end

  return false
end

-- Checks if the given entity is a world prop and if players are allowed to interact with them for the given setting
-- ent: valid entity to check
-- sett: PatchProtect setting to use to check for world-premissions
local function CheckWorld(ent, sett)
  if sv_PProtect.Settings.Propprotection['world' .. sett] and sh_PProtect.IsWorld(ent) then return true end

  return false
end

-- Checks if the given entity is a world object that should never be touched.
-- ent: valid entity to check
-- typ: type of interaction(phys, tool, spawn)
local function CheckBlocked(ent,typ)
  local class = ent:GetClass()
  if class == "func_door_rotating" and sh_PProtect.IsWorld(ent) and (typ == "phys" or typ == "tool" or typ == "spawn") then return true end
  if class == "func_breakable_surf" and (typ == "phys" or typ == "tool" or typ == "spawn") then return true end
  if class == "func_door" and sh_PProtect.IsWorld(ent) and (typ == "phys" or typ == "tool" or typ == "spawn") then return true end
  if class == "player" and (typ == "tool" or typ == "spawn") then return true end
  if class == "func_button" and (typ == "phys" or typ == "spawn") then return true end
  if class == "func_brush" and (typ == "phys" or typ == "spawn") then return true end
  if class == "func_breakable" and (typ == "phys" or typ == "spawn") then return true end
  if class == "func_physbox" and (typ == "phys" or typ == "spawn") then return true end
  if class == "prop_dynamic" and (typ == "phys" or typ == "spawn") then return true end
  if class == "func_wall_toggle" and (typ == "phys" or typ == "tool" or typ == "spawn") then return true end
end

-----------------
--  OWNERSHIP  --
-----------------

-- Set the owner for an entity
-- ent: valid entity which probably gets a new owner
-- ply: valid player which probably gets the new owner of ent
function sv_PProtect.SetOwner(ent, ply)
  -- Check if another addon may want to block the owner assignment
  if ply == nil then
    if hook.Run('CPPIAssignOwnership', ply, ent) == false then return false end
    ent.ppowner = game.GetWorld()
    net.Start("pprotect_send_owner")
     net.WriteEntity(ent)
     net.WriteEntity(ent.ppowner)
    net.Broadcast()
  else
    if hook.Run('CPPIAssignOwnership', ply, ent, ply:UniqueID()) == false then return false end
    ent.ppowner = ply
    net.Start("pprotect_send_owner")
     net.WriteEntity(ent)
     net.WriteEntity(ply)
    net.Broadcast()
  end
  -- get all contrained entitis and do the same for them
--  table.foreach(constraint.GetAllConstrainedEntities(ent), function(_, cent)
    -- if there is already an owner on a constrained entity set, don't overwrite it
--    if cent.ppowner then return end

--    cent.ppowner = ply
	
--    net.Start("pprotect_send_owner")
--     net.WriteEntity(cent)
--     net.WriteEntity(ply)
--    net.Broadcast()
--  end)

  return true
end

-- GET DATA
local en, uc, ue, up, uf = nil, undo.Create, undo.AddEntity, undo.SetPlayer, undo.Finish
function undo.Create(typ)
  if en != nil then print("tried to create a new undo before the last one was finished! discarding unfinished undo!") end
  en = {
    e = {},
    o = nil
  }
  uc(typ)
end
function undo.AddEntity(ent)
  if IsValid(ent) and ent:GetClass() != 'phys_constraint' then
    table.insert(en.e, ent)
  end
  ue(ent)
end
function undo.SetPlayer(ply)
  en.o = ply
  up(ply)
end
function undo.Finish()
  if !en.e or !IsValid(en.o) or !en.o:IsPlayer() then return end

  table.foreach(en.e, function(k, ent)
    if not ent.ppowner then
      sv_PProtect.SetOwner(ent, en.o)
    end

    -- if the entity is a duplication or the PropInProp protection is disabled or the spawner is an admin (and accepted by PatchProtect) or it is not a physics prop, then don't check for penetrating props
    if en.o.duplicate or !sv_PProtect.Settings.Antispam['propinprop'] or CheckPPAdmin(en.o) or ent:GetClass() != 'prop_physics' then return end

    -- PropInProp-Protection
    if ent:GetPhysicsObject():IsPenetrating() then
      sv_PProtect.Notify(en.o, 'You are not allowed to spawn a prop in an other prop.')
      ent:Remove()
    end
  end)
  
  -- as soon as there is not a duplicated entity, disable the duplication exception
  if en.o.duplicate then
    en.o.duplicate = false
  end

  en = nil
  uf()
end

hook.Add("PlayerSpawnedEffect","PlayerSpawnedEffect",function(ply,mdl,ent)
  if CheckBlocked(ent,"spawn") then return false end
  sv_PProtect.SetOwner(ent, ply)
end)
hook.Add("PlayerSpawnedNPC","PlayerSpawnedNPC",function(ply,ent)
  if CheckBlocked(ent,"spawn") then return false end
  sv_PProtect.SetOwner(ent, ply)
end)
hook.Add("PlayerSpawnedProp","PlayerSpawnedProp",function(ply,mdl,ent)
  if CheckBlocked(ent,"spawn") then return false end
  sv_PProtect.SetOwner(ent, ply)
end)
hook.Add("PlayerSpawnedRagdoll","PlayerSpawnedRagdoll",function(ply,mdl,ent)
  if CheckBlocked(ent,"spawn") then return false end
  sv_PProtect.SetOwner(ent, ply)
end)
hook.Add("PlayerSpawnedSENT","PProtect_PlayerSpawnedSENT",function(ply,ent)
  if CheckBlocked(ent,"spawn") then return false end
  sv_PProtect.SetOwner(ent, ply)
end)
hook.Add("PlayerSpawnedSWEP","PProtect_PlayerSpawnedSWEP",function(ply,ent)
  if CheckBlocked(ent,"spawn") then return false end
  sv_PProtect.SetOwner(ent, ply)
end)
hook.Add("PlayerSpawnedVehicle","PProtect_PlayerSpawnedVehicle",function(ply,ent)
  if CheckBlocked(ent,"spawn") then return false end
  sv_PProtect.SetOwner(ent, ply)
end)


-------------------------------
--  PHYSGUN PROP PROTECTION  --
-------------------------------

function sv_PProtect.CanPhysgun(ply, ent)
  -- Check Entity
  if !IsValid(ent) then return false end
  
  if ent:GetClass() == "vc_fuel_nozzle" then return end

  if CheckBlocked(ent,"phys") then return false end

  -- Check Admin
  if CheckPPAdmin(ply) then return end

  -- Check Entity 2
  if ent:IsPlayer() then return false end

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
  -- Check Entity
  if !IsValid(ent) then return end

  -- Check Admin
  if CheckPPAdmin(ply) then return end

  -- Check Protection
  if tool == 'creator' and !sv_PProtect.Settings.Propprotection['creator'] then
    sv_PProtect.Notify(ply, 'You are not allowed to use the creator tool on this server.')
    return false
  end
  
  if CheckBlocked(ent,"tool") then return false end

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

  -- Check Entity
  if !IsValid(ent) then return false end

  -- Check Admin
  if CheckPPAdmin(ply) then return end

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

  -- Check Entity
  if !IsValid(ent) then return false end

  -- Check Admin
  if CheckPPAdmin(ply) then return end

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
  -- Check Entity
  if !IsValid(ent) then return false end

  -- Check Admin
  if CheckPPAdmin(ply) then return end

  -- Check Persist
  if property == 'persist' then
    sv_PProtect.Notify(ply, 'You are not allowed to persist this object.')
    return false
  end

  -- Check World
  if CheckWorld(ent, 'pick') then return end

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
  -- Check Entity
  if !IsValid(ent) then return false end

  -- Check Admin
  if CheckPPAdmin(ply) then return end

  -- Check Protection
  if !sv_PProtect.Settings.Propprotection['propdriving'] then
    sv_PProtect.Notify(ply, 'Driving objects is not allowed on this server.')
    return false
  end

  -- Check World
  if CheckWorld(ent, 'pick') then return end

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

  -- Check Entity
  if !IsValid(ent) or !ply:IsPlayer() then return false end

  -- Check Admin
  if CheckPPAdmin(ply) then return end

  -- Check Damage from Player in Vehicle
  if ply:InVehicle() and sv_PProtect.Settings.Propprotection['damageinvehicle'] then
    sv_PProtect.Notify(ply, 'You are not allowed to damage other players while sitting in a vehicle.')
    return true
  end

  -- Check World
  if CheckWorld(ent, 'pick') then return end

  -- Check Shared
  if sh_PProtect.IsShared(ent, 'dmg') then return end

  -- Check Owner and Buddy
  local owner = sh_PProtect.GetOwner(ent)
  if ply == owner or sh_PProtect.IsBuddy(owner, ply, 'dmg') or ent:IsPlayer() then return end

  sv_PProtect.Notify(ply, 'You are not allowed to damage this object.')
  return true
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

  -- Check Entity
  if !IsValid(ent) then return false end

  -- Check Admin
  if CheckPPAdmin(ply) then return end

  -- Check World
  if CheckWorld(ent, 'pick') then return end
  -- I assume people don't want to allow both grabing and throwing props using gravity gun

  -- Check Owner
  if ply == sh_PProtect.GetOwner(ent) then return end

  sv_PProtect.Notify(ply, 'You are not allowed to punt this object.')
  return false
end
hook.Add('GravGunPunt', 'pprotect_gravpunt', sv_PProtect.CanGravPunt)

function sv_PProtect.CanGravPickup(ply, ent)
  -- Check Protection
  if !sv_PProtect.Settings.Propprotection['gravgun'] then return end

  -- Check Entity
  if !IsValid(ent) then return false end

  -- Check Admin
  if CheckPPAdmin(ply) then return end

  -- Check World
  if CheckWorld(ent, 'grav') then return end

  -- Check Owner
  if ply == sh_PProtect.GetOwner(ent) then return end

  sv_PProtect.Notify(ply, 'You are not allowed to use the Grav-Gun on this object.')
  ply:DropObject()
  return false
end
hook.Add('GravGunOnPickedUp', 'pprotect_gravpickup', sv_PProtect.CanGravPickup)

-----------------------
--  SET WORLD PROPS  --
-----------------------

function sv_PProtect.setWorldProps()
  table.foreach(ents:GetAll(), function(id, ent)
    if string.find(ent:GetClass(), 'func_') or string.find(ent:GetClass(), 'prop_') then
      ent.ppowner = game.GetWorld()
    end
  end)
end
hook.Add('PersistenceLoad', 'pprotect_worldprops', sv_PProtect.setWorldProps)
