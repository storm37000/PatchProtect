-- GET OWNER
-- ent: valid entity to get owner player object.
function sh_PProtect.GetOwner(ent)
  if CLIENT and ent.ppowner == nil then
    net.Start('pprotect_request_cl_data')
	    net.WriteString("owner")
	    net.WriteEntity(ent)
    net.SendToServer()
    ent.ppowner = "wait"
    return "wait"
  end
  if CLIENT and ent.ppowner == "world" then return nil end
  return ent.ppowner
end

-- CHECK SHARED
-- ent: valid entity to check for shared state
-- mode: string value for the mode to check for
function sh_PProtect.IsShared(ent, mode) --TODO: Code share system.
--  if mode == nil then
--    return ent:GetNWBool('pprotect_shared_phys') or ent:GetNWBool('pprotect_shared_tool') or ent:GetNWBool('pprotect_shared_use') or ent:GetNWBool('pprotect_shared_dmg')
--  else
--    return ent:GetNWBool('pprotect_shared_' .. mode)
--  end
  return false
end

-- CHECK BUDDY
function sh_PProtect.IsBuddy(ply, bud, mode)
  if ply == nil or bud == nil then return false end
  if ply == "wait" or bud == "wait" then return false end
  if ply == bud then return true end
  if ply.Buddies == nil then ply.Buddies = {} end
  if CLIENT and ply != LocalPlayer() then
    net.Start('pprotect_request_cl_data')
	    net.WriteString("buddy")
	    net.WriteEntity(ply)
    net.SendToServer()
  end
  if ply.Buddies[bud:SteamID()] == nil or ply.Buddies[bud:SteamID()].bud == nil then return false end
  if (mode == nil and ply.Buddies[bud:SteamID()].bud == true) or (mode != nil and ply.Buddies[bud:SteamID()].bud == true and ply.Buddies[bud:SteamID()].perm != nil and ply.Buddies[bud:SteamID()].perm[mode] == true) then
    return true
  end
  return false
end

-- CHECK WORLD
-- ent: valid entity to check for being world owned.
function sh_PProtect.IsWorld(ent)
  if CLIENT then
    return ent.ppowner == "world" or ent:IsWorld()
  else
    return ent.ppowner == nil or ent:IsWorld()
  end
end

-- Checks if the given entity is an object that should never be touched.
-- ent: valid entity to check
-- typ: type of interaction(phys, tool, spawn)
function sh_PProtect.CheckBlocked(ent,typ)
  local class = ent:GetClass()
  if class == "func_breakable_surf" and sh_PProtect.IsWorld(ent) and (typ == "phys") then return true end
  if class == "func_door_rotating" and sh_PProtect.IsWorld(ent) and (typ == "phys") then return true end
  if class == "func_door" and sh_PProtect.IsWorld(ent) and (typ == "phys") then return true end
  sh_PProtect.CheckBlockedClass(class,typ)
end

-- Checks if the given entity class is an object that should never be touched.
-- class: entity class to check
-- typ: type of interaction(phys, tool, spawn)
function sh_PProtect.CheckBlockedClass(class,typ)
  if class == "player" and (typ == "tool" or typ == "spawn") then return true end
  if class == "func_button" and (typ == "phys" or typ == "spawn") then return true end
  if class == "func_brush" and (typ == "phys" or typ == "spawn") then return true end
  if class == "func_breakable" and (typ == "phys" or typ == "spawn") then return true end
  if class == "func_wall_toggle" and (typ == "phys" or typ == "tool" or typ == "spawn") then return true end
  if class == "func_movelinear" and (typ == "phys" or typ == "tool" or typ == "spawn") then return true end
  if class == "lua_run" and (typ == "phys" or typ == "tool" or typ == "spawn") then return true end
  if class == "info_player_start" and (typ == "phys" or typ == "tool" or typ == "spawn") then return true end
  if class == "func_areaportal" and (typ == "phys" or typ == "tool" or typ == "spawn") then return true end
end

sh_PProtect.budyperms = {
  phys = false,
  tool = false,
  use = false,
  prop = false,
  dmg = false
}