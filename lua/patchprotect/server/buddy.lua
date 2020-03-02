-- SEND BUDDIES TO CLIENT
function sv_PProtect.sendbuddies(ply, sendto)
  if ply == nil then return end
  net.Start('pprotect_send_buddies')
   net.WriteEntity(ply)
   net.WriteTable(ply.Buddies or {})
  if sendto == nil then
    net.Broadcast()
  else
    net.Send(sendto)
  end
end

-- NOTIFICATION/MODIFICATION
net.Receive('pprotect_info_buddy', function(len, ply)
  local bud = net.ReadEntity()
  local tbl = net.ReadTable()
  local sid = bud:SteamID()
  if ply.Buddies == nil then ply.Buddies = {} end
  if tbl.bud and ply.Buddies[sid] and tbl.bud == ply.Buddies[sid].bud then
	ply.Buddies[sid] = tbl
	sv_PProtect.sendbuddies(ply)
    return 
  end
  if tbl.bud then
    ply.Buddies[sid] = tbl
    sv_PProtect.Notify(bud, ply:Nick() .. ' added you as a buddy.', 'normal')
  else
    ply.Buddies[sid] = nil
    sv_PProtect.Notify(bud, ply:Nick() .. ' removed you as a buddy.', 'normal')
  end
  sv_PProtect.sendbuddies(ply)
end)