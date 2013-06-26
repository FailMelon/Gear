--[[
	*******************
	* GEAR - thomasfn *
	*******************
	sh_collection.lua - Loads the collection namespace
--]]

gear_module "gear_std"

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