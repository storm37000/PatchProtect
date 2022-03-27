---------------------
--  ANTISPAM MENU  --
---------------------

function cl_PProtect.as_menu(p)
  if p == nil then return end
  if p.ClearControls == nil then return end
  -- clear Panel
  p:ClearControls()

  -- Main Settings
  p:addlbl('General Settings:', true)
  p:addchk('Enable AntiSpam', nil, cl_PProtect.Settings.Antispam['enabled'], function(c)
    cl_PProtect.Settings.Antispam['enabled'] = c
  end)

  if cl_PProtect.Settings.Antispam['enabled'] then
    -- General
	p:addchk('Ignore SuperAdmins', nil, cl_PProtect.Settings.Antispam['superadmins'], function(c)
      cl_PProtect.Settings.Antispam['superadmins'] = c
    end)
    p:addchk('Ignore Admins', nil, cl_PProtect.Settings.Antispam['admins'], function(c)
      cl_PProtect.Settings.Antispam['admins'] = c
    end)
    p:addchk('Admin-Alert Sound', nil, cl_PProtect.Settings.Antispam['alert'], function(c)
      cl_PProtect.Settings.Antispam['alert'] = c
    end)

    -- Anti-Spam features
    p:addlbl('\nEnable/Disable antispam features:', true)
    p:addchk('Tool-AntiSpam', nil, cl_PProtect.Settings.Antispam['tool'], function(c)
      cl_PProtect.Settings.Antispam['tool'] = c
    end)
    p:addchk('Prop/Entity-AntiSpam (buggy, dont use)', nil, cl_PProtect.Settings.Antispam['prop'], function(c)
      cl_PProtect.Settings.Antispam['prop'] = c
    end)
    p:addchk('Tool-Block', nil, cl_PProtect.Settings.Antispam['toolblock'], function(c)
      cl_PProtect.Settings.Antispam['toolblock'] = c
    end)
    p:addchk('Model-Block', nil, cl_PProtect.Settings.Antispam['propblock'], function(c)
      cl_PProtect.Settings.Antispam['propblock'] = c
    end)
    p:addchk('Entity-Block', nil, cl_PProtect.Settings.Antispam['entblock'], function(c)
      cl_PProtect.Settings.Antispam['entblock'] = c
    end)
    p:addchk('Prop-In-Prop (buggy, dont use)', nil, cl_PProtect.Settings.Antispam['propinprop'], function(c)
      cl_PProtect.Settings.Antispam['propinprop'] = c
    end)

    -- Tool Protection
    if cl_PProtect.Settings.Antispam['tool'] then
      p:addbtn('Set antispamed Tools', 'pprotect_request_tools', {'antispam'})
    end

    -- Tool Block
    if cl_PProtect.Settings.Antispam['toolblock'] then
      p:addbtn('Set blocked Tools', 'pprotect_request_tools', {'blocked'})
    end

    -- Prop Block
    if cl_PProtect.Settings.Antispam['propblock'] then
      p:addbtn('View blocked Models', 'pprotect_request_ents', {'props'})
    end

    -- Ent Block
    if cl_PProtect.Settings.Antispam['entblock'] then
      p:addbtn('View blocked Entities', 'pprotect_request_ents', {'ents'})
    end

    -- Cooldown
    p:addlbl('\nDuration till the next prop-spawn/tool-fire:', true)
    p:addsld(0, 10, 'Cooldown (Seconds)', cl_PProtect.Settings.Antispam['cooldown'], 'Antispam', 'cooldown', 1)
    p:addlbl('Number of props till admins get warned:')
    p:addsld(0, 40, 'Amount', cl_PProtect.Settings.Antispam['spam'], 'Antispam', 'spam', 0)
    p:addlbl('Automatic action after spamming:')
    p:addcmb({'Nothing', 'Cleanup', 'Kick', 'Ban', 'Command'}, 'spamaction', cl_PProtect.Settings.Antispam['spamaction'])

    -- Spamaction
    if cl_PProtect.Settings.Antispam['spamaction'] == 'Ban' then
      p:addsld(0, 60, 'Ban (Minutes)', cl_PProtect.Settings.Antispam['bantime'], 'Antispam', 'bantime', 0)
    elseif cl_PProtect.Settings.Antispam['spamaction'] == 'Command' then
      p:addlbl("Use '<player>' to use the spamming player.")
      p:addlbl("Some commands need sv_cheats 1 to run,\nlike 'kill <player>'")
      p:addtxt(cl_PProtect.Settings.Antispam['concommand'])
    end
  end

  -- save Settings
  p:addbtn('Save Settings', 'pprotect_save', {'Antispam'})
end

--------------
--  FRAMES  --
--------------

local cl_PProtect_Blocked = {
  props = {},
  ents = {},
  atools = {},
  btools = {}
}

-- ANTISPAMED/BLOCKED TOOLS
net.Receive('pprotect_send_tools', function()
  local t = net.ReadString()
  local typ = 'antispam'
  if t == 'btools' then
    typ = 'blocked'
  end
  cl_PProtect_Blocked[t] = net.ReadTable()
  local frm = cl_PProtect.addfrm(250, 350, typ .. ' tools:', false)

  for key, value in SortedPairs(cl_PProtect_Blocked[t]) do
    frm:addchk(key, nil, cl_PProtect_Blocked[t][key], function(c)
      net.Start('pprotect_save_tools')
      net.WriteTable({t, typ, key, c})
      net.SendToServer()
      cl_PProtect_Blocked[t][key] = c
    end)
  end
end)

-- BLOCKED PROPS/ENTS
net.Receive('pprotect_send_ents', function()
  local typ = net.ReadString()
  cl_PProtect_Blocked[typ] = net.ReadTable()
  local frm = cl_PProtect.addfrm(800, 600, 'blocked ' .. typ .. ':', true, 'Save ' .. typ, {typ, cl_PProtect_Blocked[typ]}, 'pprotect_save_ents')

  table.foreach(cl_PProtect_Blocked[typ], function(name, model)
    frm:addico(model, name, function(icon)
      local menu = DermaMenu()
      menu:AddOption('Remove from Blocked-List', function()
        net.Start('pprotect_save_ents')
        net.WriteTable({typ, name})
        net.SendToServer()
        icon:Remove()
      end)
      menu:Open()
    end)
  end)
end)

---------------------------
--  PROPPROTECTION MENU  --
---------------------------

function cl_PProtect.pp_menu(p)
  if p == nil then return end
  if p.ClearControls == nil then return end
  -- clear Panel
  p:ClearControls()

  -- Main Settings
  p:addlbl('General Settings:', true)
  p:addchk('Enable PropProtection', nil, cl_PProtect.Settings.Propprotection['enabled'], function(c)
    cl_PProtect.Settings.Propprotection['enabled'] = c
  end)

  if cl_PProtect.Settings.Propprotection['enabled'] then
    -- General
    p:addchk('Ignore SuperAdmins', nil, cl_PProtect.Settings.Propprotection['superadmins'], function(c)
      cl_PProtect.Settings.Propprotection['superadmins'] = c
    end)
    p:addchk('Ignore Admins', nil, cl_PProtect.Settings.Propprotection['admins'], function(c)
      cl_PProtect.Settings.Propprotection['admins'] = c
    end)
    p:addchk('Admins can use Cleanup-Menu', nil, cl_PProtect.Settings.Propprotection['adminscleanup'], function(c)
      cl_PProtect.Settings.Propprotection['adminscleanup'] = c
    end)

    -- Protections
    p:addlbl('\nProtection Settings:', true)
    p:addchk('Use-Protection', nil, cl_PProtect.Settings.Propprotection['use'], function(c)
      cl_PProtect.Settings.Propprotection['use'] = c
    end)
    p:addchk('Reload-Protection', nil, cl_PProtect.Settings.Propprotection['reload'], function(c)
      cl_PProtect.Settings.Propprotection['reload'] = c
    end)
    p:addchk('Damage-Protection', nil, cl_PProtect.Settings.Propprotection['damage'], function(c)
      cl_PProtect.Settings.Propprotection['damage'] = c
    end)
    p:addchk('GravGun-Protection', nil, cl_PProtect.Settings.Propprotection['gravgun'], function(c)
      cl_PProtect.Settings.Propprotection['gravgun'] = c
    end)
    p:addchk('PropPickup-Protection', "Pick up props with 'use'-key", cl_PProtect.Settings.Propprotection['proppickup'], function(c)
      cl_PProtect.Settings.Propprotection['proppickup'] = c
    end)

    -- Special damage protection
    if cl_PProtect.Settings.Propprotection['damage'] then
      p:addchk('In-Vehicle-Damage-Protection', 'Restrict players to kill other players, while sitting in a vehicle', cl_PProtect.Settings.Propprotection['damageinvehicle'], function(c)
        cl_PProtect.Settings.Propprotection['damageinvehicle'] = c
      end)
      p:addchk('Allow World Damage', 'Allow users to damage world props', cl_PProtect.Settings.Propprotection['worlddmg'], function(c)
        cl_PProtect.Settings.Propprotection['worlddmg'] = c
      end)
    end

    -- Restrictions
    p:addlbl('\nSpecial User-Restrictions:', true)
    p:addchk('Allow Creator-Tool', 'ie. spawning weapons with the toolgun', cl_PProtect.Settings.Propprotection['creator'], function(c)
      cl_PProtect.Settings.Propprotection['creator'] = c
    end)
    p:addchk('Allow Prop-Driving', 'Allow users to drive props over the context menu (c-key)', cl_PProtect.Settings.Propprotection['propdriving'], function(c)
      cl_PProtect.Settings.Propprotection['propdriving'] = c
    end)
    p:addchk('Allow World-Pickup', 'Allow users to pickup world props', cl_PProtect.Settings.Propprotection['worldpick'], function(c)
      cl_PProtect.Settings.Propprotection['worldpick'] = c
    end)
    p:addchk('Allow World-GravPick', 'Allow users to pickup world props using gravity gun', cl_PProtect.Settings.Propprotection['worldgrav'], function(c)
      cl_PProtect.Settings.Propprotection['worldgrav'] = c
    end)
    p:addchk('Allow World-Use', 'Allow users to use World-Buttons/Doors', cl_PProtect.Settings.Propprotection['worlduse'], function(c)
      cl_PProtect.Settings.Propprotection['worlduse'] = c
    end)
    p:addchk('Allow World-Tooling', 'Allow users to use tools on World-Objects', cl_PProtect.Settings.Propprotection['worldtool'], function(c)
      cl_PProtect.Settings.Propprotection['worldtool'] = c
    end)
    p:addchk('Allow Gravgun-Punt', 'Allow users to punt with the Gravgun', cl_PProtect.Settings.Propprotection['gravpunt'], function(c)
      cl_PProtect.Settings.Propprotection['gravpunt'] = c
    end)

    p:addlbl('\nProp-Delete on Disconnect:', true)
    p:addchk('Use Prop-Delete', nil, cl_PProtect.Settings.Propprotection['propdelete'], function(c)
      cl_PProtect.Settings.Propprotection['propdelete'] = c
    end)

    -- Prop-Delete
    if cl_PProtect.Settings.Propprotection['propdelete'] then
      p:addchk("Keep admin's props", nil, cl_PProtect.Settings.Propprotection['adminsprops'], function(c)
        cl_PProtect.Settings.Propprotection['adminsprops'] = c
      end)
      p:addsld(0, 300, 'Delay (sec.)', cl_PProtect.Settings.Propprotection['delay'], 'Propprotection', 'delay', 0)
    end
  end

  -- save Settings
  p:addbtn('Save Settings', 'pprotect_save', {'Propprotection'})
end

------------------
--  BUDDY MENU  --
------------------

local sply,names = nil,{
  phys = "Physgun",
  tool = "Toolgun",
  use = "Use (press E)",
  prop = "Property (C menu right click)",
  dmg = "Damage"
}

local function b_submenu(p,ply)
  if ply != sply then return end
  local ps = sh_PProtect.budyperms
  if chk then ps = LocalPlayer().Buddies[ply:SteamID()].perm end
  p:addlbl('Permissions (' .. ply:Nick() .. '):', true)
  for key,_ in pairs(ps) do
    -- add permissions
    local uiname = names[key] or key
    p:addchk(uiname, nil, cl_PProtect.setBuddyPerm(ply, key), function(c)
      cl_PProtect.setBuddyPerm(ply, key, c)
    end)
  end
end

function cl_PProtect.b_menu(p)
  if p == nil then return end
  if p.ClearControls == nil then return end
  -- clear Panel
  p:ClearControls()

  -- add buddies
  p:addlbl('Buddies:', true)
  p:addlbl('Click on name -> change permissions.')
  p:addlbl('Change right box -> add/remove buddy.')

  for _,ply in ipairs( player.GetAll() ) do
    if ply == LocalPlayer() then continue end
    local chk = cl_PProtect.setBuddy(ply)
    p:addplp(
      ply,
      chk,
      ply == sply,
      function()
        if ply == sply then
          sply = nil
          cl_PProtect.b_menu(p)
        else
          sply = ply
          b_submenu(p,ply)
        end
      end,
      function(c)
        cl_PProtect.setBuddy(ply, c)
      end
   )
   b_submenu(p,ply)
  end
end

--------------------
--  CLEANUP MENU  --
--------------------

function cl_PProtect.cu_menu(p)
  if p == nil then return end
  if p.ClearControls == nil then return end
  -- clear Panel
  p:ClearControls()

  local o_global, o_players = 0, {}

  local result = {
    global = 0,
    players = {}
   }
   for key, ent in pairs( ents.GetAll() ) do
     if ent:IsWorld() then continue end
     local o = sh_PProtect.GetOwner(ent)
     if !o then continue end

     -- check deleted entities (which shouldn't be counted, because they shouldn't exist anymore)
     --if istable(dels) and table.HasValue(dels, ent:EntIndex()) then return end

     -- Global-Count
     result.global = result.global + 1

     if !isstring(o) then
       if !o:IsValid() then continue end
     else
       continue
     end

     -- Player-Count
     if !result.players[o] then
       result.players[o] = 0
     end
     result.players[o] = result.players[o] + 1
   end
   -- set new Count-Data
   o_global = result.global
   o_players = result.players

  p:addlbl('NOTE: This menu only updates each time you open your spawn menu!', true)

  p:addlbl('Cleanup everything:', true)
  p:addbtn('Cleanup everything (' .. tostring(o_global) .. ' entities)', 'pprotect_cleanup', {'all'})

  p:addlbl('\nCleanup props from disconnected players:', true)
  p:addbtn('Cleanup all props from disc. players', 'pprotect_cleanup', {'disc'})

  p:addlbl('\nCleanup unowned props:', true)
  p:addbtn('Cleanup all unowned props', 'pprotect_cleanup', {'unowned'})

  p:addlbl("\nCleanup player's props:", true)
  table.foreach(o_players, function(pl, c)
    p:addbtn('Cleanup ' .. pl:Nick() .. ' (' .. tostring(c) .. ' entities)', 'pprotect_cleanup', {'ply', pl, tostring(c)})
  end)
end

----------------------------
--  CLIENT SETTINGS MENU  --
----------------------------

function cl_PProtect.cs_menu(p)
  if p == nil then return end
  if p.ClearControls == nil then return end
  -- clear Panel
  p:ClearControls()

  p:addlbl('Enable/Disable features:', true)
  p:addchk('Use Owner-HUD', 'Allows you to see the owner of a prop.', cl_PProtect.CSettings['ownerhud'], function(c)
    cl_PProtect.update_csetting('ownerhud', c)
  end)
  p:addchk('FPP-Mode (Owner HUD)', 'Owner will be shown under the crosshair', cl_PProtect.CSettings['fppmode'], function(c)
    cl_PProtect.update_csetting('fppmode', c)
  end)
  p:addchk('Use Notifications', 'Allows you to see incoming notifications. (right-bottom).', cl_PProtect.CSettings['notes'], function(c)
    cl_PProtect.update_csetting('notes', c)
  end)
  p:addchk('Admin Bypass', 'If you are an admin this will toggle your ability to bypass restrictions( If allowed by the server ofcourse )', cl_PProtect.CSettings['adminbypass'], function(c)
    cl_PProtect.update_csetting('adminbypass', c)
  end)
end

--------------------
--  CREATE MENUS  --
--------------------

hook.Add('PopulateToolMenu', 'pprotect_make_menus', function()
  -- Anti-Spam
  spawnmenu.AddToolMenuOption('Utilities', 'PatchProtect', 'PPAntiSpam', 'AntiSpam', '', '', function(p)
    cl_PProtect.UpdateMenus('as', p)
  end)

  -- Prop-Protection
  spawnmenu.AddToolMenuOption('Utilities', 'PatchProtect', 'PPPropProtection', 'PropProtection', '', '', function(p)
    cl_PProtect.UpdateMenus('pp', p)
  end)

  -- Buddy
  spawnmenu.AddToolMenuOption('Utilities', 'PatchProtect', 'PPBuddy', 'Buddy', '', '', function(p)
    cl_PProtect.UpdateMenus('b', p)
  end)

  -- Cleanup
  spawnmenu.AddToolMenuOption('Utilities', 'PatchProtect', 'PPCleanup', 'Cleanup', '', '', function(p)
    cl_PProtect.UpdateMenus('cu', p)
  end)

  -- Client-Settings
  spawnmenu.AddToolMenuOption('Utilities', 'PatchProtect', 'PPClientSettings', 'Client Settings', '', '', function(p)
    cl_PProtect.UpdateMenus('cs', p)
  end)
end)

--------------------
--  UPDATE MENUS  --
--------------------

local function showErrorMessage(p, msg)
  if p == nil then return end
  if p.ClearControls == nil then return end
  p:ClearControls()
  p:addlbl(msg,true,Color(200,0,0))
end

local pans = {}
function cl_PProtect.UpdateMenus(p_type, panel)
  -- add Panel
  if p_type and !pans[p_type] then
    pans[p_type] = panel
  end

  -- load Panel
  for t,p in pairs( pans ) do
    xpcall(function()
      if t == 'as' or t == 'pp' then
        if LocalPlayer():IsSuperAdmin() then cl_PProtect[t .. '_menu'](p) else showErrorMessage(p, 'Sorry, you need to be a SuperAdmin\nto change the settings.') end
      else
        cl_PProtect[t .. '_menu'](p)
      end
    end,function(error) ErrorNoHaltWithStack(error) showErrorMessage(p,"An error occured while building this menu.") end)
  end
end
hook.Add('OnSpawnMenuOpen', 'pprotect_update_menus', cl_PProtect.UpdateMenus)

---------------
--  NETWORK  --
---------------

-- RECEIVE NEW SETTINGS
net.Receive('pprotect_new_settings', function()
  cl_PProtect.Settings = net.ReadTable()
end)