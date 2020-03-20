---------------------
--  CLEANUP PROPS  --
---------------------

-- Cleanup Map
local function cleanupMap(typ, ply)
  -- cleanup map
  game.CleanUpMap()

  -- set world props
  sv_PProtect.setWorldProps()

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
  local del_ents = {}
  table.foreach(ents.GetAll(), function(key, ent)
    if ent.pprotect_cleanup != nil then
      ent:Remove()
      table.insert(del_ents, ent:EntIndex())
    end
  end)

  sv_PProtect.Notify(nil, ply:Nick() .. ' removed all props from disconnected players.', 'info')
  print('[PatchProtect - Cleanup] ' .. ply:Nick() .. ' removed all props from disconnected players.')
end

-- Cleanup Players Props
local function cleanupPly(pl, c, ply)
  local del_ents = {}
  table.foreach(ents.GetAll(), function(key, ent)
    if sh_PProtect.GetOwner(ent) == pl then
      ent:Remove()
      table.insert(del_ents, ent:EntIndex())
    end
  end)

  sv_PProtect.Notify(nil, ply:Nick() .. ' cleaned ' .. pl:Nick() .. "'s props. (" .. tostring(c) .. ')', 'info')
  print('[PatchProtect - Cleanup] ' .. ply:Nick() .. ' removed ' .. tostring(c) .. ' props from ' .. pl:Nick() .. '.')
end

-- Cleanup Unowned Props
local function cleanupUnowned(ply)
  table.foreach(ents.GetAll(), function(key, ent)
    if ent:IsValid() and !sh_PProtect.GetOwner(ent) and !sh_PProtect.IsWorld(ent) then
      ent:Remove()
    end
  end)

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
concommand.Add('gmod_admin_cleanup', function(ply, cmd, args)
  sv_PProtect.Cleanup('all', ply)
end)

----------------------------------------
--  CLEAR DISCONNECTED PLAYERS PROPS  --
----------------------------------------

-- PLAYER LEFT SERVER
local function setCleanup(ply)
  if !sv_PProtect.Settings.Propprotection['enabled'] or !sv_PProtect.Settings.Propprotection['propdelete'] then return end
  if sv_PProtect.Settings.Propprotection['adminprops'] and (ply:IsSuperAdmin() or ply:IsAdmin()) then return end

  print('[PatchProtect - Cleanup] ' .. ply:Nick() .. ' left the server. Props will be deleted in ' .. tostring(sv_PProtect.Settings.Propprotection['delay']) .. ' seconds.')

  table.foreach(ents.GetAll(), function(k, v)
    if v:CPPIGetOwner() and v:CPPIGetOwner():UniqueID() == ply:UniqueID() then
      v.pprotect_cleanup = ply:Nick()
    end
  end)

  local nick = ply:Nick()
  timer.Create('pprotect_cleanup_' .. nick, sv_PProtect.Settings.Propprotection['delay'], 1, function()
    table.foreach(ents.GetAll(), function(k, v)
      if v.pprotect_cleanup == nick then
        v:Remove()
      end
    end)
    print('[PatchProtect - Cleanup] Removed ' .. nick .. 's Props. (Reason: Left the Server)')
  end)
end
hook.Add('PlayerDisconnected', 'pprotect_playerdisconnected', setCleanup)

-- PLAYER CAME BACK
local function abortCleanup(ply)
  if !timer.Exists('pprotect_cleanup_' .. ply:Nick()) then return end

  print('[PatchProtect - Cleanup] Abort Cleanup. ' .. ply:Nick() .. ' came back.')
  timer.Destroy('pprotect_cleanup_' .. ply:Nick())

  table.foreach(ents.GetAll(), function(k, v)
    if v:CPPIGetOwner() and v:CPPIGetOwner():UniqueID() == ply:UniqueID() then
      v.pprotect_cleanup = nil
      v:CPPISetOwner(ply)
    end
  end)
end
hook.Add('PlayerSpawn', 'pprotect_abortcleanup', abortCleanup)
