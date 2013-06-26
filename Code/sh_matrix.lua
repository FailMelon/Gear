--[[
	*******************
	* GEAR - thomasfn *
	*******************
	sh_matrix.lua - Loads the matrix class
--]]

gear_module "gear_std"

namespace( System.Math )

class "Matrix3"
function Matrix3:Matrix3()
	self.Values = {}
end
function Matrix3:Set( x, y, val )
	self.Values[y*3 + x] = val
end
function Matrix3:Get( x, y )
	return self.Values[y*3 + x]
end
function Matrix3:SetRow( y, vec )
	self:Set( 1, y, vec.x )
	self:Set( 2, y, vec.y )
	self:Set( 3, y, vec.z )
end
function Matrix3:SetCol( x, vec )
	self:Set( x, 1, vec.x )
	self:Set( x, 2, vec.y )
	self:Set( x, 3, vec.z )
end
function Matrix3:SetZero()
	for i=1, 9 do
		self.Values[i] = 0
	end
end
function Matrix3:SetIdentity()
	self:SetZero()
	self:Set( 1, 1, 1 )
	self:Set( 2, 2, 1 )
	self:Set( 3, 3, 1 )
end
function Matrix3:Transform( vec )
	return Vector(
		self:Get( 1, 1 ) * vec.x + self:Get( 2, 1 ) * vec.y + self:Get( 3, 1 ) * vec.z,
		self:Get( 1, 2 ) * vec.x + self:Get( 2, 2 ) * vec.y + self:Get( 3, 2 ) * vec.z,
		self:Get( 1, 3 ) * vec.x + self:Get( 2, 3 ) * vec.y + self:Get( 3, 3 ) * vec.z
	)
end