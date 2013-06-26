--[[
	*******************
	* GEAR - thomasfn *
	*******************
	sh_collection.lua - Loads the collection namespace
--]]

gear_module "gear_std"

-- Name: Structure
-- Purpose: Provides a base class for all structures to derive from
class "Structure" (abstract)
function Structure:Structure()
	self.Values = {}
end
function Structure:MetaNumIndex( i )
	return self.Values[ i ]
end
--function Structure:MetaLength()
	--return #self.Values
--end
function Structure:Length()
	return #self.Values
end
function Structure:Clear()
	self.Values = {}
end
function Structure:ToString()
	local tmp = self.Name .. " {"
	local cnt = self:Length()
	--local cnt = #self
	for i=1, cnt do
		tmp = tmp .. tostring(self[i])
		if (i < cnt) then tmp = tmp .. ", " end
	end
	return tmp .. "}"
end