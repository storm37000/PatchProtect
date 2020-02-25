--------------------------
--  BUDDY SQL SETTINGS  --
--------------------------

-- Load Buddies
hook.Add('InitPostEntity', 'pprotect_load_buddies', function()
  if file.Exists('pprotect_buddies.txt', 'DATA') then
    LocalPlayer().Buddies = util.JSONToTable(file.Read('pprotect_buddies.txt', 'DATA'))
    for k, v in pairs( LocalPlayer().Buddies ) do
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
function cl_PProtect.setBuddy(bud, c)
  if !bud then return end
  local id = bud:SteamID()
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
  net.WriteEntity(bud)
  net.WriteTable(LocalPlayer().Buddies[id])
  net.SendToServer()

  if c then
    cl_PProtect.ClientNote('Added ' .. bud:Nick() .. ' to the Buddy-List.', 'info')
  else
    cl_PProtect.ClientNote('Removed ' .. bud:Nick() .. ' from the Buddy-List.', 'info')
  end

  saveBuddies()
end

-- Set Buddy
function cl_PProtect.setBuddyPerm(bud, p, c)
  if !bud then return end
  local id = bud:SteamID()
  if !LocalPlayer().Buddies[id] then cl_PProtect.setBuddy(bud, c) end

  LocalPlayer().Buddies[id].perm[p] = c

  -- Send message to buddy
  net.Start('pprotect_info_buddy')
  net.WriteEntity(bud)
  net.WriteTable(LocalPlayer().Buddies[id])
  net.SendToServer()

  saveBuddies()
end
