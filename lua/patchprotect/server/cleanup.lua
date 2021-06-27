---------------------
--  CLEANUP PROPS  --
---------------------

-- Cleanup Map
local function cleanupMap(typ, ply)
  -- cleanup map
  game.CleanUpMap()

  -- console exception
  if !ply:IsValid() then
    sv_PProtect.Notify(nil, 'Removed all props.', 'info')
    print('[PatchProtect - Cleanup] Removed all props.')
    return
  end

  sv_PProtect.Notify(nil, ply:Nick() .. ' cleaned Map.', 'info')
  print('[PatchProtect - Cleanup] ' .. ply:Nick() .. ' cleaned Map.')
end

-- Cleanup Disconnected Players Props
local function cleanupDisc(ply)
  for _, ent in ipairs( ents.GetAll() ) do
    if ent.pprotect_cleanup != nil and ent.ppowner != nil and !ent:IsWorld() then
      ent:Remove()
    end
  end

  sv_PProtect.Notify(nil, ply:Nick() .. ' removed all props from disconnected players.', 'info')
  print('[PatchProtect - Cleanup] ' .. ply:Nick() .. ' removed all props from disconnected players.')
end

-- Cleanup Players Props
local function cleanupPly(pl, c, ply)
  for _, ent in ipairs( ents.GetAll() ) do
    if sh_PProtect.GetOwner(ent) == pl then
      ent:Remove()
    end
  end

  sv_PProtect.Notify(nil, ply:Nick() .. ' cleaned ' .. pl:Nick() .. "'s props. (" .. tostring(c) .. ')', 'info')
  print('[PatchProtect - Cleanup] ' .. ply:Nick() .. ' removed ' .. tostring(c) .. ' props from ' .. pl:Nick() .. '.')
end

-- Cleanup Unowned Props
local function cleanupUnowned(ply)
  for _, ent in ipairs( ents.GetAll() ) do
    if !sh_PProtect.GetOwner(ent) and !sh_PProtect.IsWorld(ent) then
      ent:Remove()
    end
  end

  sv_PProtect.Notify(nil, ply:Nick() .. ' removed all unowned props.', 'info')
  print('[PatchProtect - Cleanup] ' .. ply:Nick() .. ' removed all unowned props.')
end

-- General Cleanup-Function
function sv_PProtect.Cleanup(typ, ply)
  -- check permissions
  if ply:IsValid() and (!sv_PProtect.Settings.Propprotection['adminscleanup'] or !ply:IsAdmin()) and !ply:IsSuperAdmin() then
    sv_PProtect.Notify(ply, 'You are not allowed to clean the map.')
    return
  end

  -- get cleanup-type
  local d = {}
  if !isstring(typ) then
    d = net.ReadTable()
    typ = d[1]
  end

  if typ == 'all' then
    cleanupMap(d[1], ply)
    return
  end

  if typ == 'disc' then
    cleanupDisc(ply)
    return
  end

  if typ == 'ply' then
    cleanupPly(d[2], d[3], ply)
    return
  end

  if typ == 'unowned' then
    cleanupUnowned(ply)
  end
end
net.Receive('pprotect_cleanup', sv_PProtect.Cleanup)

----------------------------------------
--  CLEAR DISCONNECTED PLAYERS PROPS  --
----------------------------------------

-- PLAYER LEFT SERVER
local function setCleanup(ply)
  if !sv_PProtect.Settings.Propprotection['enabled'] then return end
  if sv_PProtect.Settings.Propprotection['adminprops'] and (ply:IsSuperAdmin() or ply:IsAdmin()) then return end

  if sv_PProtect.Settings.Propprotection['propdelete'] then print('[PatchProtect - Cleanup] ' .. ply:Nick() .. ' left the server. Props will be deleted in ' .. sv_PProtect.Settings.Propprotection['delay'] .. ' seconds.') end

  for _, v in ipairs( ents.GetAll() ) do
    if !sh_PProtect.IsWorld(v) and v:CPPIGetOwner() and v:CPPIGetOwner() == ply then
      if sv_PProtect.Settings.Propprotection['delay'] ~= 0 then
        v.pprotect_cleanup = ply:SteamID()
      elseif sv_PProtect.Settings.Propprotection['propdelete'] then
        v:Remove()
        print('[PatchProtect - Cleanup] Removed ' .. ply:Nick() .. 's Props. (Reason: Left the Server)')
      end
    end
  end

  if sv_PProtect.Settings.Propprotection['propdelete'] and sv_PProtect.Settings.Propprotection['delay'] ~= 0 then
    timer.Create('pprotect_cleanup_' .. ply:SteamID(), sv_PProtect.Settings.Propprotection['delay'], 1, function()
      for _, v in ipairs( ents.GetAll() ) do
        if v.pprotect_cleanup and v.pprotect_cleanup == ply:SteamID() then
          v:Remove()
        end
      end
      print('[PatchProtect - Cleanup] Removed ' .. ply:Nick() .. 's Props. (Reason: Left the Server)')
    end)
  end
end
hook.Add('PlayerDisconnected', 'pprotect_playerdisconnected', setCleanup)

local aborting = {}

gameevent.Listen( "player_disconnect" )
hook.Add( "player_disconnect", "pprotect_playerdisconnectedcancel", function( data )
  if !sv_PProtect.Settings.Propprotection['propdelete'] then return end
  local name = data.name	--Same as Player:Nick()
  local steamid = data.networkid --Same as Player:SteamID()
  if not aborting[steamid] then return end
  aborting[steamid] = nil
  for _, v in ipairs( ents.GetAll() ) do
    if v.pprotect_cleanup and v.pprotect_cleanup == steamid then
      v:Remove()
    end
  end
  print('[PatchProtect - Cleanup] Removed ' .. name .. 's Props. (Reason: Left the Server)')
end)

-- PLAYER CAME BACK
hook.Add('NetworkIDValidated', 'pprotect_abortcleanup', function(name,sid)
  if !timer.Exists('pprotect_cleanup_' .. sid) then return end
  aborting[sid] = true
  timer.Destroy('pprotect_cleanup_' .. sid)
  print('[PatchProtect - Cleanup] Abort Cleanup. ' .. name .. ' came back.')
end)

hook.Add('PlayerInitialSpawn', 'pprotect_abortcleanupgetply', function(ply)
  if not aborting[ply:SteamID()] then return end
  for _, v in ipairs( ents.GetAll() ) do
    if v.pprotect_cleanup and v.pprotect_cleanup == ply:SteamID() then
      v.pprotect_cleanup = nil
      aborting[ply:SteamID()] = nil
      v:CPPISetOwner(ply)
    end
  end
end)