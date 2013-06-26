--[[
	*******************
	* GEAR - thomasfn *
	*******************
	sh_player.lua - Loads the base player class
]]

gear_module "gear_std"

class "BasePlayer"
function BasePlayer:BasePlayer( ply )
	self.Object = ply
	local meta = getmetatable( self )
	local newmeta = {}
	for key, val in pairs( meta ) do newmeta[ key ] = val end
	local oldidx = newmeta.__index
	local playerfunc = {}
	local metaPlayer = FindMetaTable( "Player" )
	local metaEntity = FindMetaTable( "Entity" )
	local function newidx( t, key )
		local old = oldidx( t, key )
		if (old ~= nil) then return old end
		if (playerfunc[ key ]) then return playerfunc[ key ] end
		local targetfunc = metaPlayer[ key ] or metaEntity[ key ]
		if (not targetfunc) then return end
		local function func( obj, ... )
			return targetfunc( obj.Object, ... )
		end
		playerfunc[ key ] = func
		return func
	end
	newmeta.__index = newidx
	setmetatable( self, newmeta )
end
function BasePlayer:ToString()
	return "Player (" .. self:Nick() .. " | " .. self:SteamID() .. ")"
end