local Owner
local IsWorld
local IsShared
local IsBuddy
local LastID
local Note = {
  msg = '',
  typ = '',
  time = 0,
  alpha = 0
}
local scr_w, scr_h = ScrW(), ScrH()
local t = scr_h * 0.5
local g = scr_w * 0.5
local font = cl_PProtect.setFont('roboto', 14, 500, true)
local fontb = cl_PProtect.setFont('roboto', 18, 500, true)
local fontc = cl_PProtect.setFont('roboto', 36, 1000, true)

local COL_GREEN = Color(128, 255, 0, 200)
local COL_BLUE = Color(0, 161, 222, 200)
local COL_RED = Color(176, 0, 0, 200)
local COL_GREY = Color(75, 75, 75)
local COL_GREYTRANS = Color(0, 0, 0, 150)
local COL_LTGREY = Color(240, 240, 240, 200)

------------------
--  PROP OWNER  --
------------------

local function showOwner()
  if LocalPlayer():InVehicle() or !cl_PProtect.Settings.Propprotection['enabled'] or !cl_PProtect.CSettings['ownerhud'] then return end

  -- Check Entity
  local ent = LocalPlayer():GetEyeTrace().Entity
  if !ent or !ent:IsValid() or ent:IsWorld() or ent:IsPlayer() then return end

  if LastID != ent:EntIndex() or (!Owner and !IsWorld) then
    Owner, IsWorld, IsShared, IsBuddy, LastID = sh_PProtect.GetOwner(ent), sh_PProtect.IsWorld(ent), sh_PProtect.IsShared(ent), sh_PProtect.IsBuddy(Owner, LocalPlayer()), ent:EntIndex()
  end

  local txt = nil
  if IsWorld then
    txt = 'World'
  elseif Owner == nil then
    txt = 'No Owner'
  elseif Owner == "wait" then
    txt = 'Waiting for server...'
  elseif IsValid(Owner) then
    txt = Owner:Nick()
    if IsBuddy then
      txt = txt .. ' (Buddy)'
    elseif IsShared then
      txt = txt .. ' (Shared)'
    end
  else
    txt = 'Disconnected'
  end

  -- Set Variables
  surface.SetFont(font)
  local w = surface.GetTextSize(txt) + 10
  local l = scr_w - w - 20

  -- Set color
  local col
  if Owner == LocalPlayer() or (cl_PProtect.Settings.Propprotection['admins'] and LocalPlayer():IsAdmin()) or (cl_PProtect.Settings.Propprotection['superadmins'] and LocalPlayer():IsSuperAdmin()) or IsBuddy or IsShared then
    col = COL_GREEN
  elseif IsWorld and (cl_PProtect.Settings.Propprotection['worldpick'] or cl_PProtect.Settings.Propprotection['worlduse'] or cl_PProtect.Settings.Propprotection['worldtool']) then
    col = COL_BLUE
  else
    col = COL_RED
  end

  -- Check Draw-Mode (FPP-Mode or not)
  if !cl_PProtect.CSettings['fppmode'] then
    -- Background
    draw.RoundedBoxEx(4, l - 5, t - 12, 5, 24, col, true, false, true, false)
    draw.RoundedBoxEx(4, l, t - 12, w, 24, COL_LTGREY, false, true, false, true)
    -- Text
    draw.SimpleText(txt, font, l + 5, t - 6, COL_GREY)
  else
    -- Background
    draw.RoundedBox(4, g - (w * 0.5), t + 16, w, 20, COL_GREYTRANS)
    -- Text
    draw.SimpleText(txt, font, g, t + 20, col, TEXT_ALIGN_CENTER, 0)
  end
end

----------------
--  MESSAGES  --
----------------

-- DRAW NOTE
local function DrawNote()
  -- Check Note
  if Note.msg == '' or Note.time + 5 < SysTime() then return end

  -- Animation
  if Note.time + 0.5 > SysTime() then
    Note.alpha = math.Clamp(Note.alpha + 10, 0, 255)
  elseif SysTime() > Note.time + 4.5 then
    Note.alpha = math.Clamp(Note.alpha - 10, 0, 255)
  end

  surface.SetFont(fontb)
  local tw, th = surface.GetTextSize(Note.msg)
  local w = tw + 20
  local h = th + 20
  local x = ScrW() - w - 20
  local y = ScrH() - h - 20
  local alpha = Note.alpha
  local bcol = Color(88, 144, 222, alpha)

  -- Textbox
  if Note.typ == 'info' then
    bcol = Color(128, 255, 0, alpha)
  elseif Note.typ == 'admin' then
    bcol = Color(176, 0, 0, alpha)
  end
  draw.RoundedBox(0, x - h, y, h, h, bcol)
  draw.RoundedBox(0, x, y, w, h, Color(240, 240, 240, alpha))
  draw.SimpleText('i', fontc, x - 23, y + 2, Color(255, 255, 255, alpha))

  local tri = {{
    x = x,
    y = y + (h * 0.5) - 6
  }, {
    x = x + 5,
    y = y + (h * 0.5)
  }, {
    x = x,
    y = y + (h * 0.5) + 6
  }}
  surface.SetDrawColor(bcol)
  draw.NoTexture()
  surface.DrawPoly(tri)

  -- Text
  draw.SimpleText(Note.msg, fontb, x + 10, y + 10, Color(75, 75, 75, alpha))
end
hook.Add('HUDPaint', 'pprotect_hud', function()
	showOwner()
	DrawNote()
end)

function cl_PProtect.ClientNote(msg, typ)
  if !cl_PProtect.CSettings['notes'] then return end

  Note = {
    msg = msg,
    typ = typ,
    time = SysTime(),
    alpha = 255
  }

  if Note.typ == 'info' then
    LocalPlayer():EmitSound('buttons/button9.wav', 100, 100)
  elseif Note.typ == 'admin' and cl_PProtect.Settings.Antispam['alert'] then
    LocalPlayer():EmitSound('ambient/alarms/klaxon1.wav', 100, 100)
  end
end

---------------
--  NETWORK  --
---------------

-- NOTIFY
net.Receive('pprotect_notify', function(len)
  local note = net.ReadTable()
  cl_PProtect.ClientNote(note[1], note[2])
end)

------------------------
--  PHYSGUN BEAM FIX  --
------------------------

hook.Add('PhysgunPickup', 'pprotect_physbeam', function()
  return false
end)

----------------------------
--  ADD BLOCKED PROP/ENT  --
----------------------------

properties.Add('addblockedprop', {
  MenuLabel = 'Add to Blocked-List',
  Order = 2002,
  MenuIcon = 'icon16/page_white_edit.png',
  Filter = function(self, ent, ply)
    local typ = 'prop'
    if ent:GetClass() != 'prop_physics' then
      typ = 'ent'
    end
    if !cl_PProtect.Settings.Antispam['enabled'] or !cl_PProtect.Settings.Antispam[typ .. 'block'] or !LocalPlayer():IsSuperAdmin() or !ent:IsValid() or ent:IsPlayer() then
      return false
    end
    return true
  end,
  Action = function(self, ent)
    net.Start('pprotect_save_cent')
    if ent:GetClass() == 'prop_physics' then
      net.WriteTable({
        typ = 'props',
        name = ent:GetModel(),
        model = ent:GetModel()
      })
    else
      net.WriteTable({
        typ = 'ents',
        name = ent:GetClass(),
        model = ent:GetModel()
      })
    end
    net.SendToServer()
  end
})

---------------------
--  SHARED ENTITY  --
---------------------
--[[
properties.Add('shareentity', {
  MenuLabel = 'Share entity',
  Order = 2003,
  MenuIcon = 'icon16/group.png',
  Filter = function(self, ent, ply)
    if !ent:IsValid() or !cl_PProtect.Settings.Propprotection['enabled'] or ent:IsPlayer() then
      return false
    end
    if LocalPlayer():IsSuperAdmin() or Owner == LocalPlayer() then
      return true
    else
      return false
    end
  end,
  Action = function(self, ent)
    local shared_info = {}
    table.foreach({'phys', 'tool', 'use', 'dmg'}, function(k, v)
      shared_info[v] = ent:GetNWBool('pprotect_shared_' .. v)
    end)

    -- Frame
    local frm = cl_PProtect.addfrm(180, 165, 'share prop:', false)

    -- Checkboxes
    frm:addchk('Physgun', nil, shared_info['phys'], function(c)
      ent:SetNWBool('pprotect_shared_phys', c)
    end)
    frm:addchk('Toolgun', nil, shared_info['tool'], function(c)
      ent:SetNWBool('pprotect_shared_tool', c)
    end)
    frm:addchk('Use', nil, shared_info['use'], function(c)
      ent:SetNWBool('pprotect_shared_use', c)
    end)
    frm:addchk('Damage', nil, shared_info['dmg'], function(c)
      ent:SetNWBool('pprotect_shared_dmg', c)
    end)
  end
})
--]]