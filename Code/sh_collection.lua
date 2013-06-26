--[[
	*******************
	* GEAR - thomasfn *
	*******************
	sh_collection.lua - Loads the collection namespace
--]]

gear_module "gear_std"

namespace( System.Collections )

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

-- Name: List
-- Purpose: Provides a list of items
class "List" inherit "Structure"
function List:Add( item )
	return table.insert( self.Values, item )
end
function List:Remove( item )
	for key, val in pairs( self.Values ) do
		if (val == item) then
			self:RemoveAt( key )
			return true
		end
	end
	return false
end
function List:RemoveAt( idx )
	table.remove( self.Values, idx )
end
function List:Contains( item )
	for key, val in pairs( self.Values ) do
		if (val == item) then
			return true
		end
	end
	return false
end
function List:MetaAdd( other )
	if (not other:Is( List )) then return error( "Attempt to add list to non list.", 3 ) end
	local tmp = new( List )
	for i=1, self:Length() do
		tmp:Add( self[i] )
	end
	for i=1, other:Length() do
		tmp:Add( other[i] )
	end
	return tmp
end
function List:MetaSubtract( other )
	if (not other:Is( List )) then return error( "Attempt to subtract list from non list.", 2 ) end
	local tmp = new( List )
	for i=1, self:Length() do
		tmp:Add( self[i] )
	end
	for i=1, other:Length() do
		tmp:Remove( other[i] )
	end
	return tmp
end
function List:Sort( func )
	table.sort( self.Values, func )
end
function List:FindBest( scorefunction )
	if (self:Length() == 0) then return end
	local best = self[1]
	local bestscore = scorefunction( best )
	for i=2, self:Length() do
		local score = scorefunction( self[i] )
		if (score > bestscore) then
			bestscore = score
			best = self[i]
		end
	end
	return best
end
function List:FindWorst( scorefunction )
	if (self:Length() == 0) then return end
	local worst = self[1]
	local worstscore = scorefunction( worst )
	for i=2, self:Length() do
		local score = scorefunction( self[i] )
		if (score < worstscore) then
			worstscore = score
			worst = self[i]
		end
	end
	return worst
end
function List:SelectRandom()
	return self[ math.random( 1, self:Length() ) ]
end

-- Name: Array2D
-- Purpose: Provides a 2d array structure
class "Array2D" inherit "Structure"
function Array2D:Array2D( width, height, def )
	self.Width = width
	self.Height = height
	if (def) then
		for x=1,width do
			for y=1,height do
				self:Set( x, y, def )
			end
		end
	end
end
function Array2D:Set( x, y, val )
	x = x - 1
	y = y - 1
	self.Values[ (x * self.Height) + y ] = val
end
function Array2D:Get( x, y )
	x = x - 1
	y = y - 1
	return self.Values[ (x * self.Height) + y ]
end
function Array2D:GetDimensions()
	return self.Width, self.Height
end

-- Name: Array3D
-- Purpose: Provides a 3d array structure
class "Array3D" inherit "Structure"
function Array3D:Array3D( width, height, depth, def )
	self.Width = width
	self.Height = height
	self.Depth = depth
	if (def) then
		for x=1,width do
			for y=1,height do
				for z=1,depth do
					self:Set( x, y, z, def )
				end
			end
		end
	end
end
function Array3D:Set( x, y, z, val )
	self.Values[ ((x-1) * self.Height * self.Depth) + ((y-1) * self.Depth) + (z-1) + 1 ] = val
end
function Array3D:Get( x, y, z )
	return self.Values[ ((x-1) * self.Height * self.Depth) + ((y-1) * self.Depth) + (z-1) + 1 ]
end
function Array3D:GetDimensions()
	return self.Width, self.Height, self.Depth
end