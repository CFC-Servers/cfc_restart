-- Put me in addons/ulxsvrestart/lua/ulx/modules/sh/restartme.lua
-- Theres so many poor design decisions in this script it should be rewritten when there are
-- less pressing things to work on.

AddCSLuaFile()
if SERVER then util.AddNetworkString( "CFC_SERVER_RESTART" ) end

if CLIENT then
    local function SVRestartHud( whensta )
        local whendyn = tonumber( whensta )

        hook.Add( "DrawOverlay", "ServerRestartGo", function()
            surface.SetFont( "TargetID" )
            local txt = "The server is restarting in " .. ( whendyn > -1 and whendyn or "some" ) .. " seconds!\n"
            local tw, _ = surface.GetTextSize( txt )
            draw.WordBox( 0, ScrW() - tw, 10, txt, "TargetID", { r = 0, g = 0, b = 0, a = 180 }, { r = 255, g = 0, b = 0, a = 255} ) -- Says there is an "Unnecessary Parenthesies" but I see none
        end )
        timer.Create( "CFC_SERVER_RESTART_TIMER", 1, math.max( 1, whensta ), function()
            whendyn = math.max( 0,  whendyn - 1  )
        end )
        timer.Simple( whensta + 0.1, function()
            hook.Remove( "DrawOverlay", "ServerRestartGo" )  
            timer.Remove( "CFC_SERVER_RESTART_TIMER" )
        end )
    end

    net.Receive( "CFC_SERVER_RESTART", function()
        local thyme = Entity( 0 ):GetNWFloat( "CFC_SERVER_RESTART", -1 )
        SVRestartHud( thyme )
        hook.Add( "InitPostEntity", "ServerRestartGo", function()
            timer.Simple( 0, function()
                thyme = Entity( 0 ):GetNWFloat( "CFC_SERVER_RESTART", -1 )
                SVRestartHud( thyme )
            end )
        end )
    end )
end

CFC_SERVER_RESTART = { yes = false, thyme = 30 }
function ulx.svrestart( calling_ply, thyme, stop )

    CFC_SERVER_RESTART.yes = false

    if SERVER then
        timer.Remove( "CFC_SERVER_RESTART_TIMER" )
        hook.Remove( "Think", "ServerRestartGo" )
    end

    if stop then
        Entity( 0 ):SetNWFloat( "CFC_SERVER_RESTART", 0 )

        timer.Simple( 0.21, function() -- Slow to update??
            net.Start( "CFC_SERVER_RESTART" )
            net.Broadcast()
        end )

        ulx.fancyLogAdmin( calling_ply, "#A stopped the server restart!" )
        return
    end

    local thyme = math.max( 0, tonumber( thyme ) )

    CFC_SERVER_RESTART = { yes = true, thyme = SysTime() + tonumber( thyme ) }

    local diff = math.max( 0, SysTime() - SysTime() + thyme )
    Entity( 0 ):SetNWFloat( "CFC_SERVER_RESTART", diff )
    if SERVER then
        timer.Create( "CFC_SERVER_RESTART", 0.9, thyme + 1, function()
            local diff = math.max( 0, SysTime() - SysTime() + thyme ) -- Isn't this the same as max( 0, thyme ) ?
            Entity( 0 ):SetNWFloat( "CFC_SERVER_RESTART", math.max( 0, diff ) )
        end )
        hook.Add( "Think", "ServerRestartGo", function()
            local bool = CFC_SERVER_RESTART.yes
            local systhyme = CFC_SERVER_RESTART.thyme

            if bool and systhyme <= SysTime() then
                ServerLog( "\n\nYour Server Has Been Restarted!\n\n" )

                -- RunConsoleCommand( "_restart" ) -- Pick a method and comment the other one out!

                RunConsoleCommand( "changelevel", tostring( game.GetMap() ) )

                CFC_SERVER_RESTART.yes = false
                hook.Remove( "Think", "ServerRestartGo" )
            end
            if not bool then hook.Remove( "Think", "ServerRestartGo" ) end
        end )
        timer.Simple( 0.21, function()
            net.Start( "CFC_SERVER_RESTART" )
            net.Broadcast()
        end )
    end

    ulx.fancyLogAdmin( calling_ply, "#A told the server to restart in #i seconds!", tonumber( thyme ) )
end
local svrestart = ulx.command( CATEGORY_NAME, "ulx svrestart", ulx.svrestart, "!svrestart" )
svrestart:addParam{ type = ULib.cmds.NumArg, min = 0, hint = "restart time", ULib.cmds.optional, ULib.cmds.round,
default = 30}
svrestart:addParam{ type = ULib.cmds.BoolArg, invisible = true }
svrestart:defaultAccess( ULib.ACCESS_SUPERADMIN )
svrestart:help( "Starts a server restart, and lets everyone know that the server is about to restart." )
svrestart:setOpposite( "ulx svstop", {_, 0, true}, {"!svrestop", "!svstop"} )
