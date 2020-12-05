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
  if ply == bud then return false end
  if ply == "wait" or bud == "wait" then return false end
  if !IsValid(ply) or !IsValid(bud) then return false end
  if CLIENT and ply.Buddies == nil then
    net.Start('pprotect_request_cl_data')
	 net.WriteString("buddy")
	 net.WriteString(ply:SteamID())
    net.SendToServer()
	return false
  end
  if ply.Buddies == nil or !ply.Buddies[bud:SteamID()] or !ply.Buddies[bud:SteamID()].bud then return false end
  if (!mode and ply.Buddies[bud:SteamID()].bud == true) or (ply.Buddies[bud:SteamID()].bud == true and ply.Buddies[bud:SteamID()].perm[mode] == true) then
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