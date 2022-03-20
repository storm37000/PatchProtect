----------------------
--  ANTISPAM SETUP  --
----------------------

-- CHECK ANTISPAM ADMIN
local function sv_PProtect_CheckASAdmin(ply)
  if !sv_PProtect.Settings.Antispam['enabled'] then return true end
  if !ply.ppadminbypass then return false end
  if !(ply.IsSuperAdmin and ply.IsAdmin) then return false end
  if ply:IsSuperAdmin() and sv_PProtect.Settings.Antispam['superadmins'] then return true end
  if ply:IsAdmin() and sv_PProtect.Settings.Antispam['admins'] then return true end
  return false
end

-------------------
--  SPAM ACTION  --
-------------------

local function sv_PProtect_spamaction(ply)
  local action = sv_PProtect.Settings.Antispam['spamaction']
  local name = ply:Nick()

  -- Cleanup
  if action == 'Cleanup' then
    cleanup.CC_Cleanup(ply, '', {})
    sv_PProtect.Notify(ply, 'Cleaned all your props. (Reason: spamming)')
    sv_PProtect.Notify(nil, 'Cleaned ' .. name .. 's props. (Reason: spamming)', 'admin')
    print('[PatchProtect - AntiSpam] Cleaned ' .. name .. 's props. (Reason: spamming)')
  -- Kick
  elseif action == 'Kick' then
    ply:Kick('Kicked by PatchProtect. (Reason: spamming)')
    sv_PProtect.Notify(nil, 'Kicked ' .. name .. '. (Reason: spamming)', 'admin')
    print('[PatchProtect - AntiSpam] Kicked ' .. name .. '. (Reason: spamming)')
  -- Ban
  elseif action == 'Ban' then
    local mins = sv_PProtect.Settings.Antispam['bantime']
    ply:Ban(mins, 'Banned by PatchProtect. (Reason: spamming)')
    sv_PProtect.Notify(nil, 'Banned ' .. name .. ' for ' .. mins .. ' minutes. (Reason: spamming)', 'admin')
    print('[PatchProtect - AntiSpam] Banned ' .. name .. ' for ' .. mins .. ' minutes. (Reason: spamming)')
  -- ConCommand
  elseif action == 'Command' then
    if sv_PProtect.Settings.Antispam['concommand'] == sv_PProtect.Config.Antispam['concommand'] then return end
    local rep = string.Replace(sv_PProtect.Settings.Antispam['concommand'], '<player>', ply:SteamID())
    local cmd = string.Explode(' ', rep)
    RunConsoleCommand(cmd[1], unpack(cmd, 2))
    print("[PatchProtect - AntiSpam] Ran console command '" .. rep .. "'. (Reason: reached spam limit)")
  end
end

-----------------------
--  SPAWN ANTI SPAM  --
-----------------------

local function sv_PProtect_ModelBlacklist(ply, mdl)
  if sv_PProtect.Settings.Antispam['propblock'] and sv_PProtect.Blocked.props[string.lower(mdl)] then
    sv_PProtect.Notify(ply, 'This object is in the blacklist.')
    return true
  end
end

local function sv_PProtect_EntityBlacklist(ply, class)
  if sh_PProtect.CheckBlockedClass(class,"spawn") or (sv_PProtect.Settings.Antispam['entblock'] and sv_PProtect.Blocked.ents[string.lower(class)]) then
    sv_PProtect.Notify(ply, 'This object is in the blacklist.')
    return true
  end
end

function sv_PProtect_CanSpawn(ply, object)
  if sv_PProtect_CheckASAdmin(ply) then return end

  -- Prop/Entity-Block
  if string.find( object, "models/", nil, true ) then
    if sv_PProtect_ModelBlacklist(ply, object) then return false end
  else
    if sv_PProtect_EntityBlacklist(ply, object) then return false end
  end

  if !sv_PProtect.Settings.Antispam['prop'] then return end
  if (ply.AdvDupe2 and ply.AdvDupe2.Entities) or (ply.CurrentDupe and ply.CurrentDupe.Entities) or (IsValid(ply:GetActiveWeapon()) and IsValid(ply:GetActiveWeapon():GetToolObject()) and ply:GetActiveWeapon():GetToolObject().Entities) then return end

  -- Cooldown
  if CurTime() > (ply.propcooldown or 0) then
    ply.props = 0
    ply.propcooldown = CurTime() + sv_PProtect.Settings.Antispam['cooldown']
    return
  end
  ply.props = (ply.props or 0) + 1
  sv_PProtect.Notify(ply, 'Please wait ' .. math.Round(ply.propcooldown - CurTime(), 1) .. ' seconds', 'normal')

  -- Spamaction
  if ply.props >= sv_PProtect.Settings.Antispam['spam'] then
    ply.props = 0
    sv_PProtect_spamaction(ply)
    sv_PProtect.Notify(nil, ply:Nick() .. ' is spamming.', 'admin')
    print('[PatchProtect - AntiSpam] ' .. ply:Nick() .. ' is spamming.')
	return false
  end
end

hook.Add('PlayerSpawnProp', 'pprotect_spawnprop', sv_PProtect_CanSpawn)
hook.Add('PlayerSpawnEffect', 'pprotect_spawneffect', sv_PProtect_CanSpawn)
hook.Add('PlayerSpawnSENT', 'pprotect_spawnSENT', sv_PProtect_CanSpawn)
hook.Add('PlayerSpawnRagdoll', 'pprotect_spawnragdoll', sv_PProtect_CanSpawn)
hook.Add('PlayerSpawnVehicle', 'pprotect_spawnvehicle', sv_PProtect_CanSpawn)
hook.Add('PlayerSpawnNPC', 'pprotect_spawnNPC', sv_PProtect_CanSpawn)
hook.Add('PlayerSpawnSWEP', 'pprotect_spawnSWEP', sv_PProtect_CanSpawn)

----------------------
--  TOOL ANTI SPAM  --
----------------------

hook.Add('CanTool', 'pprotect_antispam_toolgun', function(ply,trace,tool)
  if sv_PProtect_CheckASAdmin(ply) then return end

  -- Blocked Tool
  if sv_PProtect.Settings.Antispam['toolblock'] and sv_PProtect.Blocked.btools[tool] then
    sv_PProtect.Notify(ply, 'This tool is in the blacklist.', 'normal')
    return false
  end

  if !sv_PProtect.Settings.Antispam['tool'] then return end
  if !sv_PProtect.Blocked.atools[tool] then return end
  if trace.HitNormal == vector_origin then return end

  -- Cooldown
  if CurTime() > (ply.toolcooldown or 0) then
    ply.tools = 0
    ply.toolcooldown = CurTime() + sv_PProtect.Settings.Antispam['cooldown']
    return
  end

  ply.tools = (ply.tools or 0) + 1
  sv_PProtect.Notify(ply, 'Please wait ' .. math.Round(ply.toolcooldown - CurTime(), 1) .. ' seconds', 'normal')

  -- Spamaction
  if ply.tools >= sv_PProtect.Settings.Antispam['spam'] then
    ply.tools = 0
    sv_PProtect_spamaction(ply)
    sv_PProtect.Notify(nil, ply:Nick() .. ' is spamming with ' .. tostring(tool) .. 's.', 'admin')
    print('PatchProtect - AntiSpam] ' .. ply:Nick() .. ' is spamming with ' .. tostring(tool) .. 's.')
	  return false
  end
end)