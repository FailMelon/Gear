--[[
	*******************
	* GEAR - thomasfn *
	*******************
	sh_moduleprovider.lua - Loads the module provider class
--]]

gear_module "gear_std"

using( System.Collections )

namespace( System.Util )

class "ModuleProvider"
function ModuleProvider:ModuleProvider()
	local modules = new( List )
	self.Modules = modules
	local meta = getmetatable( self )
	local oldidx = rawget( meta, "__index" )
	local function newidx( t, key )
		local old = oldidx( t, key )
		if (old ~= nil) then return old end
		return function( obj, ... )
			for i=1, modules:Length() do
				local m = modules[i]
				if (m[ key ]) then
					local result = m[ key ]( m, ... )
					if (result ~= nil) then return result end
				end
			end
		end
	end
	rawset( meta, "__index", newidx )
end
function ModuleProvider:AddModule( obj )
	self.Modules:Add( obj )
	obj.Provider = self
end
function ModuleProvider:RemoveModule( obj )
	self.Modules:Remove( obj )
end