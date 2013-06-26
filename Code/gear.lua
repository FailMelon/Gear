--[[
	*******************
	* GEAR - thomasfn *
	*******************
	gear.lua - Loads core gear functionality
--]]

local my_version = 1.00
local gear_info = MsgN or print
local warning = ErrorNoHalt or print
local error = error
local function gear_warning( str ) warning( str .. "\n" ) end
local function gear_error( str, n ) error( str .. "\n", n ) end

-- Check version
if (gear_version) then
	if (my_version == gear_version) then
		warning( "The same version of GEAR was nearly loaded twice (" .. tostring(my_version) .. ")" )
	elseif (my_version < gear_version) then
		warning( "An older version of GEAR nearly loaded over a newer (" .. tostring(my_version) .. ")" )
	elseif (my_version > gear_version) then
		warning( "A newer version of GEAR nearly loaded over an older (" .. tostring(my_version) .. ")" )
	end
	return
end
gear_version = my_version

-- Util
local function get_calling_function( lvl )
	return debug.getinfo( 2 + (lvl or 1), "f" ).func
end
local function string_split( str, sep )
	local sep, fields = sep or ":", {}
	local pattern = string.format("([^%s]+)", sep)
	str:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

-- Load type controller
local types = {}
local function type_create( name, ctor, metatable )
	local typ = {}
	typ.Name = name
	typ.Constructor = ctor
	typ.Metatable = metatable
	typ.ObjectType = "type"
	types[ name ] = typ
	return typ
end
local function type_get( name )
	return types[ name ]
end
local function type_tostring( typ )
	return (typ and typ.Name) or "Invalid Type"
end
local function type_valid( typ, acceptstaticclass )
	if (type(typ) ~= "table") then return false end
	if (acceptstaticclass and typ.ObjectType == "static_class") then return true end
	if (typ.ObjectType ~= "type") then return false end
	if (not typ.Name) then return false end
	return types[ typ.Name ] == typ
end

-- Load type API
function new( typ, ... )
	-- Validate the type
	if (not type_valid( typ )) then
		gear_warning( "Attempt to create instance of invalid type. (" .. tostring( typ ) .. ")" )
		return
	end
	if (not typ.Constructor) then
		gear_warning( "Attempt to create instance of type '" .. typ.Name .. "', type has no constructor." )
		return
	end

	-- Create
	return typ.Constructor( typ, ... )
end
function typeof( obj )
	if (obj == nil) then return nil end
	local t = type( obj )
	if (t == "string") then return System.String end
	if (t == "number") then return System.Number end
	if (t == "table") then
		if (obj.GetType) then return obj:GetType() end
		if (obj.Type) then return obj.Type end
		return System.Table
	end
	return System.Userdata
end

-- Load identifier controller
local metaIdentifier = {}
local identifier_create
function metaIdentifier.__index( t, key )
	local val = rawget( t, key )
	if (val) then return val end
	return identifier_create( rawget( t, "Name" ) .. "." .. key )
end
function identifier_create( name )
	local o = {}
	o.Name = name
	o.ObjectType = "identifier"
	setmetatable( o, metaIdentifier )
	return o
end
local function identifier_valid( obj )
	if (type(obj) ~= "table") then return false end
	if (obj.ObjectType ~= "identifier") then return false end
	return obj.Name ~= nil
end

-- Load namespace controller
local function namespace_create( name )
	if (identifier_valid( name )) then name = name.Name end
	local fields = string_split( name, "." )
	local c = _G
	local qname = ""
	for i=1, #fields do
		local name = fields[i]
		local n = c[ name ]
		qname = qname .. name
		if (not n) then
			n = {}
			n.QName = qname
			n.ObjectType = "namespace"
			c[ name ] = n
		end
		c = n
		qname = qname .. "."
	end
end
local function namespace_get( name, ignorelast )
	if (identifier_valid( name )) then name = name.Name end
	local fields = string_split( name, "." )
	local c = _G
	local cnt = #fields
	if (ignorelast) then cnt = cnt - 1 end
	for i=1, cnt do
		local name = fields[i]
		local n = c[ name ]
		if (not n) then return end
		c = n
	end
	return c, fields[#fields]
end
local function namespace_resolve( name )
	local n1, n2 = namespace_get( name, true )
	--MsgN( "Trying to resolve '" .. name .. "', got " .. n2 )
	--PrintTable( n1 )
	return n1 and n1[n2]
end

-- Load object metatable
local metaObject = {}
metaObject.__index = metaObject
function metaObject.__newindex( t, key, val )
	if (type( val ) == "function") then
		setfenv( val, t.fenv )
		local reg = rawget( t, "Registry" )
		reg[ val ] = t
	end
	rawset( t, key, val )
end
function metaObject:MetaEquals( other )
	return rawequal( self, other )
end
local function BindMetamethod( tbl, metamethod, proxy, op )
	local proxy = "Meta" .. proxy
	local function tmp( t, other )
		if (t[ proxy ]) then return t[ proxy ]( t, other ) end
		gear_error( "Attempt to use operator '" .. op .. "' on object '" .. t.ObjectType .. "'.", 2 )
	end
	tbl[ metamethod ] = tmp
end
local function BindMetamethods( tbl )
	BindMetamethod( tbl, "__add", "Add", "+" )
	BindMetamethod( tbl, "__sub", "Subtract", "-" )
	BindMetamethod( tbl, "__mul", "Multiply", "*" )
	BindMetamethod( tbl, "__div", "Divide", "/" )
	BindMetamethod( tbl, "__mod", "Modulus", "%" )
	BindMetamethod( tbl, "__pow", "Power", "^" )
	BindMetamethod( tbl, "__concat", "Concat", ".." )
	BindMetamethod( tbl, "__eq", "Equals", "==" )
end
function metaObject:ToString()
	return type_tostring(self.Type) .. " (" .. tostring_gear(self) .. ")"
end
function metaObject:CastTo( typ )
	if (type_valid( typ )) then typ = typ.Name end
	if (typ.Metatable and typ.Metatable.CastFrom) then
		local result = typ.Metatable.CastFrom( nil, self )
		if (result ~= nil) then return result end
	end
	if (typ == "string") then return self:ToString() end
end
function metaObject:CastFrom( obj )
	return nil
end
function metaObject:GetType()
	return self.Type
end
function metaObject:CallBase( funcname, ... )
	local caller = get_calling_function()
	local base = self.Registry[ caller ]
	if (not base) then return end
	local func = base.Inherits[ funcname ]
	if (not func) then return end
	return func( self, ... )
end
function metaObject:Is( typ )
	--if (not type_valid( typ )) then return false end
	if (self:GetType() == typ) then return true end
	local c = self.Inherits
	while true do
		if (c) then
			if (c == typ.Metatable) then return true end
			if (c == metaObject) then return false end
			c = c.Inherits
		else
			break
		end
	end
	return false
end
function metaObject:Reconstruct( ... )
	-- Call the constructors
	for i=1, #self.CtorList do
		self.CtorList[i]( self, ... )
	end
	local ctor = self[ self.Name ]
	if (ctor) then ctor( self, ... ) end
end
function metaObject:BindToObject( ent )
	-- Store object
	self.Object = ent
	
	-- Copy the old metatable into a new one
	local meta = getmetatable( self )
	local newmeta = {}
	for key, val in pairs( meta ) do newmeta[ key ] = val end
	
	-- Store the old index metamethod and create an entity method table
	local oldidx = newmeta.__index
	local entitymethods = {}
	
	-- Create a new index metamethod
	local function newidx( t, key )
		-- See if the old index metamethod yields a result
		local old = oldidx( t, key )
		if (old ~= nil) then return old end
		
		-- See if we already have a entity method stored
		if (entitymethods[ key ]) then return entitymethods[ key ] end
		
		-- Locate the method on the entity object, if it exists
		local targetfunc = ent[ key ]
		if (not targetfunc) then return end
		
		-- Create a proxy function to call the entity method
		local function func( obj, ... )
			return targetfunc( obj.Object, ... )
		end
		
		-- Store it in our entity method table and return
		entitymethods[ key ] = func
		return func
	end
	
	-- Override the existing metatable with our own
	newmeta.__index = newidx
	setmetatable( self, newmeta )
end

-- Load core namespace and types
namespace_create( "System" )
System.Object = type_create( "System.Object", nil, metaObject )
System.String = type_create( "System.String", function() return "" end, string )
System.Number = type_create( "System.Number", function() return 0 end, nil )
System.Table = type_create( "System.Table", function( ... ) return { ... } end, nil )
System.Userdata = type_create( "System.Userdata", nil, nil )

-- Override core functions
if (not tostring_gear) then
	tostring_gear = tostring
	function tostring( obj, ... )
		local t = type( obj )
		if (t == "table") and obj.ToString and (type( obj.ToString ) == "function") then return obj:ToString( ... ) end
		return tostring_gear( obj, ... )
	end
end
if (not tonumber_gear) then
	tonumber_gear = tonumber
	function tonumber( obj, ... )
		local t = type( obj )
		if (t == "table") and (obj.ToNumber) then return obj:ToNumber( ... ) end
		return tonumber_gear( obj, ... )
	end
end

-- Load module controller
local metaEnvModule = {}
function metaEnvModule.__index( t, key )
	return rawget( t, key ) or metaEnvModule[ key ] or identifier_create( key )
end
local metaEnvModuleG = {}
function metaEnvModuleG.__index( t, key )
	local gval = _G[ key ]
	if (not type_valid( gval )) then gval = nil end
	return rawget( t, key ) or metaEnvModule[ key ] or gval or identifier_create( key )
end
function gear_module( name )
	local caller = get_calling_function()
	local env = {}
	env._G = _G
	env.ns = _G
	env.usings = {}
	setmetatable( env, metaEnvModule )
	env.old = getfenv( caller )
	setfenv( caller, env )
end
local function module_import_global( func )
	setmetatable( getfenv( func ), metaEnvModuleG )
end

-- Load namespace interface
function using( name )
	if (type( name ) == "table") and (name.ObjectType == "namespace") then
		name = name.QName
	end
	if (name == "global") or (identifier_valid( name ) and (name.Name == "global")) then
		module_import_global( get_calling_function() )
		return
	end
	local ns = namespace_get( name )
	if (not ns) then return print( "Namespace '" .. (name.Name or name) .. "' not found." ) end
	local env = getfenv( get_calling_function() )
	if (not env.usings) then env.usings = {} end
	local strname = tostring( name )
	for k, v in pairs( ns ) do
		if (type_valid( v, true )) then
			if (rawget( env, k )) then
				print( "Duplicate type '" .. k .. "' when importing namespace '" .. strname .. "'." )
			else
				env[ k ] = v
				env.usings[ k ] = v
			end
		end
	end
end
function namespace( name )
	namespace_create( name )
	local env = getfenv( get_calling_function() )
	env.ns = namespace_get( name )
end
metaEnvModule.using = using
metaEnvModule.namespace = namespace

-- Load class interface
local reservednames = { "Name", "QName", "ObjectType" }
local inherit
function class( name )
	-- Check name
	if (identifier_valid( name )) then name = name.Name end

	-- Validate input
	if (reservednames[ name ]) then
		gear_warning( "Can't use reserved name '" .. name .. "' as a class name." )
		return
	end

	-- Define the metatable for the class
	local metaClass = {}
	function metaClass.__index( t, key )
		--if (t == metaClass) then return metaObject[ key ] end
		--print( key, tostring_gear(metaClass), tostring_gear(t), tostring_gear(metaObject) )
		if (type( key ) == "number") then
			local f = t[ "MetaNumIndex" ]
			if (f) then return f( t, key ) end
		end
		local v = rawget( t, key )
		if (v) then return v end
		--[[local i = rawget( metaClass, "Inherits" )
		print( "Looking up in " .. tostring_gear( i ) )
		if (i) then return i[ key ] end]]
		return metaClass[ key ]
	end
	--[[function metaClass.__len( t )
		local f = t[ "MetaLength" ]
		if (f) then return f( t ) end
		return 0
	end]]
	metaClass.__newindex = metaObject.__newindex
	BindMetamethods( metaClass )
	metaClass.ObjectType = "class"
	metaClass.Inherits = metaObject
	metaClass.CtorList = {}
	metaClass.Flags = {}
	metaClass.Name = name
	metaClass.Registry = {}
	for k, v in pairs( metaObject ) do
		if (type( v ) == "function") then metaClass.Registry[ v ] = metaObject end
	end
	setmetatable( metaClass, metaObject )

	-- Prepare the environment
	local env = getfenv( get_calling_function() )
	if (env.classname) then
		env[ env.classname ] = nil
	end
	env[ name ] = metaClass
	env.classname = name
	env.inherit = inherit

	-- Prepare the function environment
	local metaFenv = {}
	function metaFenv.__index( t, key )
		--if (key == name) then return metaClass end
		local value = _G[ key ] or env.ns[ key ] or env[ key ]
		if (identifier_valid( value )) then return nil end
		return value
	end
	metaClass.fenv = setmetatable( {}, metaFenv )

	-- Creation function
	local function newclass( t, ... )
		-- Create instance
		local o = {}
		o.Type = t
		setmetatable( o, metaClass )

		-- Call the constructors
		o:Reconstruct( ... )

		-- Done
		return o
	end

	-- Create the type
	local qname = (env.ns == _G) and name or (env.ns.QName .. "." .. name)
	local typ = type_create( qname, newclass, metaClass )
	metaClass.Type = typ

	-- Store in namespace
	env.ns[ name ] = typ

	-- Return the flags function
	local function flag( ... )
		local args = { ... }
		for i=1, #args do
			local arg = args[i]
			local name = identifier_valid( arg ) and arg.Name or arg
			if (name == "abstract") then
				typ.Constructor = nil
			elseif (name == "static") then
				--MsgN( "STATICLOL " .. name )
				typ.Constructor = nil
				typ.ObjectType = "static_class"
				typ.Type = typ
				local newmeta = {}
				for key, val in pairs( metaObject ) do
					newmeta[ key ] = val
				end
				function newmeta.__newindex( t, key, val )
					metaObject.__newindex( t, key, val )
					if (type( val ) == "function") then
						typ[ key ] = val
						--MsgN( "Static function '" .. key .. "'" )
					end
				end
				setmetatable( metaClass, newmeta )
			else
				gear_warning( "Unknown flag '" .. name .. "' on class '" .. qname .. "'." )
			end
			metaClass.Flags[ name ] = true
		end
	end
	return flag
end
metaEnvModule.class = class
function inherit( typ )
	-- Get the caller environment
	local env = getfenv( get_calling_function() )

	-- Validate the type
	if (type(typ) == "string") then
		typ = env.ns[typ] or env.usings[typ] or namespace_resolve(typ)
	end
	if (not type_valid( typ )) then
		gear_warning( "Attempt to inherit '" .. env.classname .. "' from invalid base class. (" .. tostring_gear( typ and typ.ObjectType ) .. ")" )
		return
	end
	local class = typ.Metatable

	-- Validate the class
	if (type( class ) == "string") then class = env.ns[ class ] or env[ class ] end
	if (not class) or (type(class) ~= "table") or (class.ObjectType ~= "class") then
		gear_warning( "Attempt to inherit '" .. env.classname .. "' from invalid base class." )
		return
	end

	-- Validate the current class
	if (not env.classname) then
		gear_warning( "Tring to inherit in the wrong place." )
		return
	end
	local c = env[ env.classname ]
	if (not c) then
		gear_warning( "Tring to inherit in the wrong place." )
		return
	end
	if (c.Inherits ~= metaObject) then
		gear_warning( "Tring to inherit twice." )
		return
	end
	
	-- Sanity check
	if (c == class) then return gear_warning( "Attempt to inherit class from itself." ) end

	-- Update the constructor list
	c.CtorList = {}
	for i=1, #class.CtorList do
		c.CtorList[i] = class.CtorList[i]
	end
	local ctor = class[ class.Name ]
	if (ctor) then c.CtorList[ #c.CtorList + 1 ] = ctor end
	--MsgN( "After inheritance, " .. c.Name .. " has " .. #c.CtorList .. " constructors." )
	
	-- Update registry
	for k, v in pairs( class.Registry ) do
		c.Registry[ v ] = class
	end

	-- Update metatable
	c.Inherits = class
	setmetatable( c, class )
end

-- Load debugging
function gear_dump()
	MsgN( "-- TYPES --" )
	for key, val in pairs( types ) do
		MsgN( key )
	end
end
