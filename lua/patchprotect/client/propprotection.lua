--------------------------
--  BUDDY SQL SETTINGS  --
--------------------------

-- Load Buddies
hook.Add('InitPostEntity', 'pprotect_load_buddies', function()
  if file.Exists('pprotect_buddies.txt', 'DATA') then
    LocalPlayer().Buddies = util.JSONToTable(file.Read('pprotect_buddies.txt', 'DATA'))
    if LocalPlayer().Buddies == nil then cl_PProtect.ClientNote('Your buddy list is corrupt!', 'admin') LocalPlayer().Buddies = {} saveBuddies() end
    for k, v in pairs( LocalPlayer().Buddies ) do
      if isbool(v) then cl_PProtect.ClientNote('Your buddy list is corrupt!', 'admin') continue end
      cl_PProtect.setBuddy(player.GetBySteamID(k), v.bud)
    end
  else
    LocalPlayer().Buddies = {}
  end
  hook.Run('CPPIFriendsChanged', ply, LocalPlayer().Buddies)
end)

-- Save Buddies
local function saveBuddies()
  file.Write('pprotect_buddies.txt', util.TableToJSON(LocalPlayer().Buddies))
  hook.Run('CPPIFriendsChanged', ply, LocalPlayer().Buddies)
end

-- Reset Buddies
concommand.Add('pprotect_reset_buddies', function()
  for k, v in pairs( LocalPlayer().Buddies ) do
    cl_PProtect.setBuddy(player.GetBySteamID(k), false)
  end
  LocalPlayer().Buddies = {}
  saveBuddies()
  print('[PProtect-Buddy] Successfully deleted all Buddies.')
end)

-- Receive Others' Buddies
net.Receive('pprotect_send_buddies', function(len)
  local ply = net.ReadEntity()
  ply.Buddies = net.ReadTable()
  hook.Run('CPPIFriendsChanged', ply, ply:CPPIGetFriends())
end)

-- Set Buddy
function cl_PProtect.setBuddy(budent, c)
  if !budent then return end
  if !budent:IsPlayer() then return end
  local id = budent:SteamID()
  if c == nil then
    if LocalPlayer().Buddies[id] then
      return LocalPlayer().Buddies[id].bud
    end
    return false
  end
  if !isbool( c ) then cl_PProtect.ClientNote('Your buddy list is corrupt!', 'admin') return end
  
  if !LocalPlayer().Buddies[id] then
    LocalPlayer().Buddies[id] = {
      bud = c,
      perm = sh_PProtect.budyperms
    }
  else
    LocalPlayer().Buddies[id].bud = c
  end

  saveBuddies()

  -- Send message to buddy
  net.Start('pprotect_info_buddy')
  net.WriteEntity(budent)
  net.WriteTable(LocalPlayer().Buddies[id])
  net.SendToServer()

  return c
end

-- Set Buddy
function cl_PProtect.setBuddyPerm(budent, p, c)
  if !budent then return end
  if !budent:IsPlayer() then return end
  local id = budent:SteamID()
  if c == nil then
    if LocalPlayer().Buddies[id] then
      return LocalPlayer().Buddies[id].perm[p]
    end
    return false
  end
  if !isbool( c ) then cl_PProtect.ClientNote('Your buddy list is corrupt!', 'admin') return end

  if !LocalPlayer().Buddies[id] then
    cl_PProtect.setBuddy(budent, false)
  else
    LocalPlayer().Buddies[id].perm[p] = c
  end
  saveBuddies()

  -- Send message to buddy
  net.Start('pprotect_info_buddy')
  net.WriteEntity(budent)
  net.WriteTable(LocalPlayer().Buddies[id])
  net.SendToServer()

  return c
end

--------------------------
--  PP DATA SYNC FUNCTIONS
--------------------------
net.Receive('pprotect_send_owner', function(len)
  local ent = net.ReadEntity()
  local owner = net.ReadEntity()
  if owner == game.GetWorld() then owner = "world" end
  ent.ppowner = owner
end)