--[[
	*******************
	* GEAR - thomasfn *
	*******************
	sv_netmessage.lua - Loads the net message class
]]

gear_module "gear_std"

using( System.Collections )

namespace( Gmod.Net )

class "Message"
function Message:Message( msgname )
	self.Items = new( List )
	self.ID = msgname
end
function Message:WriteInt( num, bits )
	bits = bits or 32
	self.Items:Add( { "int", num, bits } )
end
function Message:WriteIntArray( arr, bits )
	bits = bits or 32
	self.Items:Add( { "intarr", arr, bits } )
end
function Message:WriteUInt( num, bits )
	bits = bits or 32
	self.Items:Add( { "uint", num, bits } )
end
function Message:WriteUIntArray( arr, bits )
	bits = bits or 32
	self.Items:Add( { "uintarr", arr, bits } )
end
function Message:WriteString( str )
	self.Items:Add( { "string", str } )
end
function Message:WriteFloat( num )
	self.Items:Add( { "float", num } )
end
function Message:WriteVector( vec )
	self.Items:Add( { "vector", vec } )
end
function Message:WriteBool( b )
	self.Items:Add( { "bool", b } )
end
function Message:WriteEntity( ent )
	self.Items:Add( { "entity", ent } )
end
function Message:Dispatch( target )
	net.Start( self.ID )
	for i=1, self.Items:Length() do
		local item = self.Items[i]
		local typ = item[1]
		if (typ == "int") then net.WriteInt( item[2], item[3] ) end
		if (typ == "uint") then net.WriteUInt( item[2], item[3] ) end
		if (typ == "bool") then net.WriteBit( item[2] ) end
		if (typ == "string") then net.WriteString( item[2] ) end
		if (typ == "float") then net.WriteFloat( item[2] ) end
		if (typ == "vector") then net.WriteVector( item[2] ) end
		if (typ == "entity") then net.WriteEntity( item[2] ) end
		if (typ == "uintarr") then
			local arr = item[2]
			local bits = item[3]
			for j=1, #arr do
				net.WriteUInt( arr[j], bits )
			end
		end
		if (typ == "intarr") then
			local arr = item[2]
			local bits = item[3]
			for j=1, #arr do
				net.WriteInt( arr[j], bits )
			end
		end
	end
	net.Send( target )
end