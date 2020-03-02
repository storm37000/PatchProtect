--------------------------
--  BUDDY SQL SETTINGS  --
--------------------------

-- Load Buddies
hook.Add('InitPostEntity', 'pprotect_load_buddies', function()
  if file.Exists('pprotect_buddies.txt', 'DATA') then
    LocalPlayer().Buddies = util.JSONToTable(file.Read('pprotect_buddies.txt', 'DATA'))
    for k, v in pairs( LocalPlayer().Buddies ) do
      if isbool(v) then cl_PProtect.ClientNote('Your buddy list is corrupt!', 'admin') continue end
      cl_PProtect.setBuddy(player.GetBySteamID(k), v.bud)
    end
  end
end)

-- Save Buddies
local function saveBuddies()
  file.Write('pprotect_buddies.txt', util.TableToJSON(LocalPlayer().Buddies))
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
  net.ReadEntity().Buddies = net.ReadTable()
end)

-- Set Buddy
function cl_PProtect.setBuddy(budent, c)
  if !budent then return end
  if !isbool( c ) then cl_PProtect.ClientNote('Your buddy list is corrupt!', 'admin') return end
  local id = budent:SteamID()
  if !LocalPlayer().Buddies[id] then
    LocalPlayer().Buddies[id] = {
      bud = false,
      perm = {
        phys = false,
        tool = false,
        use = false,
        prop = false,
        dmg = false
      }
    }
  end

  LocalPlayer().Buddies[id].bud = c

  -- Send message to buddy
  net.Start('pprotect_info_buddy')
  net.WriteEntity(budent)
  net.WriteTable(LocalPlayer().Buddies[id])
  net.SendToServer()

  if c then
    cl_PProtect.ClientNote('Added ' .. budent:Nick() .. ' to the Buddy-List.', 'info')
  else
    cl_PProtect.ClientNote('Removed ' .. budent:Nick() .. ' from the Buddy-List.', 'info')
  end

  saveBuddies()
end

-- Set Buddy
function cl_PProtect.setBuddyPerm(budent, p, c)
  if !budent then return end
  if !isbool( c ) then cl_PProtect.ClientNote('Your buddy list is corrupt!', 'admin') return end
  local id = budent:SteamID()
  if !LocalPlayer().Buddies[id] then cl_PProtect.setBuddy(budent, c) end

  LocalPlayer().Buddies[id].perm[p] = c

  -- Send message to buddy
  net.Start('pprotect_info_buddy')
  net.WriteEntity(budent)
  net.WriteTable(LocalPlayer().Buddies[id])
  net.SendToServer()

  saveBuddies()
end

--------------------------
--  PP DATA SYNC FUNCTIONS
--------------------------

net.Receive('pprotect_send_isworld', function(len)
  net.ReadEntity().ppworld = net.ReadBool()
end)

net.Receive('pprotect_send_owner', function(len)
  net.ReadEntity().ppowner = net.ReadEntity()
end)