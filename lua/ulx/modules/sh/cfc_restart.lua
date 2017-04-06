-- Put me in addons/ulxsvrestart/lua/ulx/modules/sh/restartme.lua

AddCSLuaFile()
if SERVER then util.AddNetworkString("OMG_SERVER_RESTART") end

if CLIENT then
	local function SVRestartHud(whensta)
		local whendyn = tonumber(whensta)

		hook.Add("DrawOverlay","ServerRestartGo", function()
			surface.SetFont("TargetID")
			local txt = "The server is restarting in "..(whendyn > -1 and whendyn or "some").." seconds!\n"
			local tw,th = surface.GetTextSize(txt)

			draw.WordBox(0, ScrW()-tw, 10, txt, "TargetID", {r=0,g=0,b=0,a=180}, {r=255,g=0,b=0,a=255})
		end)

		timer.Create("_SERVER_RESTART_OMG", 1, math.max(1,whensta), function()
			whendyn = math.max(0,(whendyn - 1))
		end)

		timer.Simple(whensta+0.1, function()
			hook.Remove("DrawOverlay","ServerRestartGo")
			timer.Destroy("_SERVER_RESTART_OMG")
		end)
	end

	net.Receive("OMG_SERVER_RESTART", function()
		local time = Entity(0):GetNWFloat("OMG_SERVER_RESTART", -1)
		SVRestartHud(time)
		hook.Add("InitPostEntity", "ServerRestartGo", function()
			timer.Simple(0, function()
				time = Entity(0):GetNWFloat("OMG_SERVER_RESTART", -1)
				SVRestartHud(time)
			end)
		end)
	end)
end

OMG_SERVER_RESTART = {yes = false, time = 0}
function ulx.svrestart(calling_ply, time, stop)

	OMG_SERVER_RESTART.yes = false
	if SERVER then
		timer.Destroy("__SERVER_RESTART_OMG")
		hook.Remove("Think","ServerRestartGo")
	end

	if stop then
		Entity(0):SetNWFloat("OMG_SERVER_RESTART", 0)

		timer.Simple(0.21, function() -- Slow to update??
			net.Start("OMG_SERVER_RESTART")
			net.Broadcast()
		end)
		
		ulx.fancyLogAdmin( calling_ply, "#A stopped the server restart!") 
		return 
	end

	local time = math.max(0,tonumber(time))

	OMG_SERVER_RESTART = {yes = true, time = (SysTime()+tonumber(time))}

	local diff = math.max(0,SysTime() - SysTime()+time)
	Entity(0):SetNWFloat("OMG_SERVER_RESTART", diff)

	if SERVER then
		timer.Create("__SERVER_RESTART_OMG", 0.9, time+1, function()
			local diff = math.max(0,SysTime() - SysTime()+time)
			Entity(0):SetNWFloat("OMG_SERVER_RESTART", math.max(0,diff))
		end)
		hook.Add("Think","ServerRestartGo",function()
			local bool = OMG_SERVER_RESTART.yes
			local systime = OMG_SERVER_RESTART.time

			if bool and systime <= SysTime() then
				ServerLog("\n\nYour Server Has Been Restarted!\n\n")

				-- RunConsoleCommand("_restart") -- Pick a method and comment the other one out!
				RunConsoleCommand("changelevel",tostring(game.GetMap()))

				OMG_SERVER_RESTART.yes = false
				hook.Remove("Think","ServerRestartGo")
			end
			if not bool then hook.Remove("Think","ServerRestartGo") end
		end)
		timer.Simple(0.21, function()
			net.Start("OMG_SERVER_RESTART")
			net.Broadcast()
		end)
	end

	ulx.fancyLogAdmin( calling_ply, "#A told the server to restart in #i seconds!", tonumber(time) )
end
local svrestart = ulx.command( CATEGORY_NAME, "ulx svrestart", ulx.svrestart, "!svrestart" )
svrestart:addParam{ type=ULib.cmds.NumArg, min=0, default=30, hint="restart time", ULib.cmds.optional, ULib.cmds.round }
svrestart:addParam{ type=ULib.cmds.BoolArg, invisible=true }
svrestart:defaultAccess( ULib.ACCESS_SUPERADMIN )
svrestart:help( "Starts a server restart, and lets everyone know that the server is about to restart." )
svrestart:setOpposite( "ulx svstop", {_,0,true}, {"!svrestop","!svstop"} )
