-- GET OWNER
function sh_PProtect.GetOwner(ent)
  if !ent then return end
  return ent:GetNWEntity('pprotect_owner')
end

-- CHECK SHARED
-- ent: valid entity to check for shared state
-- mode: string value for the mode to check for
function sh_PProtect.IsShared(ent, mode)
  if mode == nil then
    return ent:GetNWBool('pprotect_shared_phys') or ent:GetNWBool('pprotect_shared_tool') or ent:GetNWBool('pprotect_shared_use') or ent:GetNWBool('pprotect_shared_dmg')
  else
    return ent:GetNWBool('pprotect_shared_' .. mode)
  end
end


-------------------
--  CHECK BUDDY  --
-------------------
function sh_PProtect.IsBuddy(ply, bud, mode)
  if ply == nil or !IsValid(ply) or !ply:IsPlayer() or bud == nil or !bud:IsPlayer() then return false end
  if CLIENT and ply.Buddies == nil then
    net.Start('pprotect_request_buddies')
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