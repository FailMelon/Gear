--[[
	*******************
	* GEAR - thomasfn *
	*******************
	sh_math.lua - Loads the math namespace
--]]

gear_module "gear_std"

namespace( System.Math )

local math_cos = _G.math.cos
local math_sin = _G.math.sin
local math_tan = _G.math.tan

class "Core" ("static")
function Core:Cos( num )
	return math_cos( num )
end
function Core:Sin( num )
	return math_sin( num )
end
function Core:Tan( num )
	return math_tan( num )
end

class "Helper" ("static")
function Helper:Lerp( a, b, mid )
	return (b - a) * mid + a
end
function Helper:Coserp( a, b, mid )
	local mu2 = (1 - math_cos( mid * 3.141592 )) / 2
	return (a * (1 - mu2)) + (b * mu2)
end
function Helper:PointLineDistance( p1, p2, p )
	local l = (p1 - p2):LengthSqr()
	if (l == 0) then return (p1 - p):Length() end
	local t = (p - p1):Dot( p2 - p1 ) / l
	if (t < 0) then
		return (p - p1):Length(), p1
	elseif (t > 1) then
		return (p - p2):Length(), p2
	else
		local projection = p1 + t * (p2 - p1)
		return (p - projection):Length(), projection
	end
end