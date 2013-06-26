--[[
	*******************
	* GEAR - thomasfn *
	*******************
	sh_resource.lua - Loads the resource namespace
--]]

gear_module "gear_std"

using( System.Collections )

namespace( System.Resources )

-- Name: Pool
-- Purpose: Provide a resource pool for efficient lua resource usage
class "Pool"
function Pool:Pool( typ )
	self.Cache = new( List )
	self.RType = typ
	print( "Init! " .. self.Cache:ToString() )
end
function Pool:Allocate( ... )
	local len = self.Cache:Length()
	if (len == 0) then return new( self.RType, ... ) end
	local item = self.Cache[ len ]
	self.Cache:RemoveAt( len )
	if (item.Reconstruct) then item:Reconstruct( ... ) end
	return item
end
function Pool:Free( item )
	self.Cache:Add( item )
end
