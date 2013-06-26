--[[
	*******************
	* GEAR - thomasfn *
	*******************
	sh_hooks.lua - Loads the hooks namespace
--]]

gear_module "gear_std"

using( System.Collections )

namespace( Gmod.Hooks )

local hookobjects

class "HookManager" ( "static" )
function HookManager:AddHookObject( obj )
	if (not hookobjects) then hookobjects = new( List ) end
	hookobjects:Add( obj )
end
function HookManager:RemoveHookObject( obj )
	hookobjects:Remove( obj )
end
function HookManager:CallHook( name, ... )
	if (not hookobjects) then return end
	for i=1, hookobjects:Length() do
		local obj = hookobjects[i]
		if (obj[name]) then
			local result = obj[name]( obj, ... )
			if (result ~= nil) then return result end
		end
	end
end

_G.hook.OldCall = _G.hook.Call
function _G.hook.Call( name, gm, ... )
	local result = HookManager:CallHook( name, ... )
	if (result ~= nil) then return result end
	return _G.hook.OldCall( name, gm, ... )
end