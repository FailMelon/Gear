--[[
	*******************
	* GEAR - thomasfn *
	*******************
	sh_typefinder.lua - Loads the type finder class
--]]

gear_module "gear_std"

local function string_split( str, sep )
	local sep, fields = sep or ":", {}
	local pattern = _G.string.format("([^%s]+)", sep)
	str:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

class "Finder" ( "static" )
function Finder:Find( qname )
	local fields = string_split( qname, "." )
	local c = _G
	local cnt = #fields - 1
	for i=1, cnt do
		local name = fields[i]
		local n = c[ name ]
		if (not n) then return end
		c = n
	end
	return c[ fields[#fields] ]
end