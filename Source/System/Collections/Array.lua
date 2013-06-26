--[[
	*******************
	* GEAR - thomasfn *
	*******************
	sh_collection.lua - Loads the collection namespace
--]]

gear_module "gear_std"

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