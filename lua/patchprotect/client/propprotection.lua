--------------------------
--  BUDDY SQL SETTINGS  --
--------------------------

local function notifyServer(sid,tbl)
  -- Send message to buddy
  net.Start('pprotect_info_buddy')
    net.WriteString(sid)
    net.WriteTable(tbl)
  net.SendToServer()
end

-- Load Buddies
hook.Add('InitPostEntity', 'pprotect_load_buddies', function()
  LocalPlayer().Buddies = {}
  if file.Exists('pprotect_buddies.txt', 'DATA') then
    file.AsyncRead('pprotect_buddies.txt', 'DATA', function(_,_,status,data)
      data = util.JSONToTable(data)
      if data then
        for k, v in pairs(data) do
          if v == nil or v.bud == nil or (not isstring(k)) then cl_PProtect.ClientNote('An entry in your buddy list is corrupt!', 'admin') continue end
          LocalPlayer().Buddies[k] = v
          notifyServer(k,v)
        end
      else
        cl_PProtect.ClientNote('Your buddy list is corrupt!', 'admin')
        saveBuddies()
      end
      hook.Run('CPPIFriendsChanged', ply, LocalPlayer().Buddies)
    end)
  end
end)

-- Save Buddies
local function saveBuddies()
  file.Write('pprotect_buddies.txt', util.TableToJSON(LocalPlayer().Buddies))
  hook.Run('CPPIFriendsChanged', ply, LocalPlayer().Buddies)
end

-- Reset Buddies
concommand.Add('pprotect_reset_buddies', function()
  for k,_ in pairs( LocalPlayer().Buddies ) do
    notifyServer(k,{})
  end
  LocalPlayer().Buddies = {}
  saveBuddies()
  print('[PProtect-Buddy] Successfully deleted all Buddies.')
end)

-- Receive Others' Buddies
net.Receive('pprotect_send_buddies', function(len)
  local ply = net.ReadEntity()
  ply.Buddies = net.ReadTable()
end)

-- Set Buddy
function cl_PProtect.setBuddy(budent, c)
  if budent == nil then return end
  if not IsValid(budent) then return end
  if !budent:IsPlayer() then return end
  local id = budent:SteamID()
  if id == "NULL" then id = budent:Nick() end
  if c == nil then
    if LocalPlayer().Buddies and LocalPlayer().Buddies[id] and LocalPlayer().Buddies[id].bud then
      return LocalPlayer().Buddies[id].bud
    end
    return false
  end
  
  if LocalPlayer().Buddies[id] == nil then
    LocalPlayer().Buddies[id] = {
      bud = c,
      perm = sh_PProtect.budyperms
    }
  else
    LocalPlayer().Buddies[id].bud = c
  end

  saveBuddies()

  notifyServer(id,LocalPlayer().Buddies[id])

  return c
end

-- Set Buddy
function cl_PProtect.setBuddyPerm(budent, p, c)
  if budent == nil then return end
  if not IsValid(budent) then return end
  if not budent:IsPlayer() then return end
  local id = budent:SteamID()
  if id == "NULL" then id = budent:Nick() end
  if c == nil then
    if LocalPlayer().Buddies and LocalPlayer().Buddies[id] and LocalPlayer().Buddies[id].perm then
      return LocalPlayer().Buddies[id].perm[p]
    end
    return false
  end

  if LocalPlayer().Buddies[id] == nil then
    cl_PProtect.setBuddy(budent, false)
  end
  if LocalPlayer().Buddies[id].perm == nil then
    LocalPlayer().Buddies[id].perm = {}
  end
  LocalPlayer().Buddies[id].perm[p] = c
  saveBuddies()

  notifyServer(id,LocalPlayer().Buddies[id])

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