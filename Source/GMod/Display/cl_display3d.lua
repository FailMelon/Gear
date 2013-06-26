--[[
	*******************
	* GEAR - thomasfn *
	*******************
	cl_display3d2d.lua - Loads the 3d2d display classes
--]]

gear_module "gear_std"

namespace( "Gmod.Display" )

using( System )
using( System.Collections )

_G.DISPLAY_MODE_3D2D = 1
_G.DISPLAY_MODE_RT = 2

local matBlur = _G.Material( "pp/blurscreen" )

local rt3D2D = _G.GetRenderTarget( "rt3D2D", _G.ScrW(), _G.ScrH(), false )
local mat3D2D = _G.CreateMaterial( "mat3D2D", "UnlitGeneric", {
	["$basetexture"] = rt3D2D,
	["$model"] = 1,
	["$translucent"] = 1,
	["$vertexalpha"] = 1,
} )

class "Manager" ("static")
function Manager:Init()
	self.Displays = new( List )
end
function Manager:GetAll()
	return self.Displays
end
function Manager:Add( item )
	self.Displays:Add( item )
end
function Manager:Remove( item )
	self.Displays:Remove( item )
	
	--print( "Display removed", item, self.Displays:Length() )
	--self.Displays:Clear()
end
function Manager:Update()
	for i=1, self.Displays:Length() do
		self.Displays[i]:Update()
	end
end
local mtxIdentity = _G.Matrix()
function Manager:Draw()
	if (IgnoreScreens) then return end
	--local blur = false
	--render.ClearStencil()

	--[[render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
	render.SetStencilZFailOperation( STENCILOPERATION_REPLACE )
	render.SetStencilFailOperation( STENCILOPERATION_REPLACE )
	render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_NEVER )
	render.SetStencilReferenceValue( 1 )
	
	for i=1, self.Displays:Length() do
		local obj = self.Displays[i]
		if (obj.ViewSpace) then cam.PushModelMatrix( mtxIdentity ) end
		if (obj.Blur) then
			render.SetStencilEnable( true )
			obj:Draw( DISPLAY_MODE_3D2D )
			render.SetStencilEnable( false )
			blur = true
		else
			obj:Draw( DISPLAY_MODE_3D2D )
		end
		if (obj.ViewSpace) then cam.PopModelMatrix() end
	end
	
	if (not blur) then return end
	
	render.UpdateScreenEffectTexture()
	
	render.SetStencilEnable( true )
	render.SetStencilPassOperation( STENCILOPERATION_KEEP )
	render.SetStencilZFailOperation( STENCILOPERATION_KEEP )
	render.SetStencilFailOperation( STENCILOPERATION_KEEP )
	render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
	render.SetStencilReferenceValue( 1 )--]]
	
	--[[render.SetMaterial( matBlur )
	for i = 0.16, 0.5, 0.16 do
		matBlur:SetFloat( "$blur", 10 * i )
		render.UpdateScreenEffectTexture()
		render.DrawScreenQuad()
	end]]
	
	--render.SetStencilEnable( false )
	
	for i=1, self.Displays:Length() do
		local obj = self.Displays[i]
		obj:Draw( DISPLAY_MODE_3D2D )
	end
	
end
function Manager:FireMousePress( code, pressed )
	for i=1, self.Displays:Length() do
		local obj = self.Displays[i]
		--print( "Testing", obj )
		if (obj:Is( InputDisplay )) then
			local result = obj:HandlePress( code, pressed )
			if (result) then
				obj:Focus()
				return result
			end
		end
	end
end

class "BaseDisplay" ("abstract")
function BaseDisplay:BaseDisplay( ent )
	self._prop = ent
	self.Position = Vector( 0, 0, 0 )
	self.Rotation = Vector( 0, 0, 0 )
	self.Width = 64
	self.Height = 64
	self.Resolution = 2
	self.OneSided = true
	self.ViewSpace = false
	self.Alpha = 1
	Gmod.Display.Manager:Add( self )
end
local vBaseRot = _G.Vector( -90, 90, 0 )
--local vBaseRot = _G.Vector( 0, 90, 0 )
local vecTonemapScale = _G.Vector( 0.8, 1, 1 )
function BaseDisplay:Draw( mode )
	if (self.Removed) then
		Gmod.Display.Manager:Remove( self )
		return
	end
	
	-- Get the angles and position of our entity
	local ent = self._prop
	if (not ent) or (not ent:IsValid()) then
		ErrorNoHalt( "Tried to draw display with invalid entity.\n" )
		self:Remove()
		return
	end
	local ang = ent:GetAngles()
	local rot = vBaseRot + self.Rotation
	ang:RotateAroundAxis(ang:Right(), 	rot.x)
	ang:RotateAroundAxis(ang:Up(), 		rot.y)
	ang:RotateAroundAxis(ang:Forward(), rot.z)
	local offset = self.Position
	local oldang = ent:GetAngles()
	local pos = ent:GetPos() + (oldang:Forward() * offset.y) + (oldang:Up() * offset.z) + (oldang:Right() * -offset.x)
	local c = pos + (oldang:Right() * self.Width * -0.5) + (oldang:Up() * self.Height * -0.5)
	--print( ent:GetPos(), pos, offset )
	--print( ent:GetAngles():Forward(), ent:GetAngles():Right() )
	
	-- Determine if we are behind it
	local behind = (pos - EyePos()):Dot( ent:GetAngles():Forward() ) > 0
	if (behind and self.OneSided) then return end
	
	-- 3D2D
	if (mode == DISPLAY_MODE_3D2D) then
		-- Begin the 3d2d
		cam.Start3D2D( pos, ang, 1 / self.Resolution )
		
		-- Render
		local b, res = pcall( self.Render, self, self.Width * self.Resolution, self.Height * self.Resolution, self.Alpha )
		if (not b) then
			ErrorNoHalt( "Failed to render display: " .. res .. "\n" )
		end
		
		-- End the 3d2d
		cam.End3D2D()
	end
	
	-- RT
	if (mode == DISPLAY_MODE_RT) then
		-- Setup our RT
		local oldrt = render.GetRenderTarget()
		render.SetRenderTarget( rt3D2D )
		render.ClearDepth()
		render.Clear( 255, 255, 255, 0 )
		
		-- Begin 2D mode
		cam.Start2D()
		
		-- Render
		local b, res = pcall( self.Render, self, self.Width * self.Resolution, self.Height * self.Resolution, self.Alpha )
		if (not b) then
			ErrorNoHalt( "Failed to render display: " .. res .. "\n" )
		end
		
		-- End 2D mode
		cam.End2D()
		
		-- Reset RT
		render.SetRenderTarget( oldrt )
		
		-- Render the RT
		mat3D2D:SetMaterialTexture( "$basetexture", rt3D2D )
		render.SetMaterial( mat3D2D )
		render.DrawQuadEasy( c, oldang:Forward(), self.Width, self.Height, color_white, 180 )
		--render.DrawScreenQuad()
	end
end
function BaseDisplay:Update()

end
function BaseDisplay:Render( w, h, a )
	surface.SetDrawColor( 255, 0, 0, 255 * a )
	surface.DrawRect( 0, 0, w, h )
end
function BaseDisplay:Remove()
	Gmod.Display.Manager:Remove( self )
	self.Removed = true
end



--[[
Give this function the coordinates of a pixel on your screen, and it will return a unit vector pointing
in the direction that the camera would project that pixel in.
 
Useful for converting mouse positions to aim vectors for traces.
 
iScreenX is the x position of your cursor on the screen, in pixels.
iScreenY is the y position of your cursor on the screen, in pixels.
iScreenW is the width of the screen, in pixels.
iScreenH is the height of the screen, in pixels.
angCamRot is the angle your camera is at
fFoV is the Field of View (FOV) of your camera in ___radians___
	Note: This must be nonzero or you will get a divide by zero error.
 ]]--
local function LPCameraScreenToVector( iScreenX, iScreenY, iScreenW, iScreenH, angCamRot, fFoV )
    --This code works by basically treating the camera like a frustrum of a pyramid.
    --We slice this frustrum at a distance "d" from the camera, where the slice will be a rectangle whose width equals the "4:3" width corresponding to the given screen height.
    local d = 4 * iScreenH / ( 6 * Core:Tan( 0.5 * fFoV ) )	;
 
    --Forward, right, and up vectors (need these to convert from local to world coordinates
    local vForward = angCamRot:Forward();
    local vRight   = angCamRot:Right();
    local vUp      = angCamRot:Up();
 
    --Then convert vec to proper world coordinates and return it 
    return ( d * vForward + ( iScreenX - 0.5 * iScreenW ) * vRight + ( 0.5 * iScreenH - iScreenY ) * vUp ):GetNormal();
end

class "InputDisplay" ("abstract") inherit "BaseDisplay"
function InputDisplay:InputDisplay( ent )
	self.InputDistance = 128
end
function InputDisplay:Focus()
	lastpressed = self
end
local vBaseRot = _G.Vector( -90, 90, 0 )
local debugmodel
local mtx
function InputDisplay:CalculateCursorLocation()
	-- Get and validate entity
	local ent = self._prop
	if (not ent) or (not ent:IsValid()) then return 0, 0 end
	
	-- Get line start and direction
	-- r = start + mu*dir
	--local view = hook.Call( "CalcView", GAMEMODE, LocalPlayer(), EyePos(), EyeAngles(), LocalPlayer():GetFOV() )
	
	--local start = LocalPlayer():GetShootPos()
	--local dir = LocalPlayer():GetCursorAimVector()
	--local start = view.origin
	--local start = EyePos()
	--local ang = EyeAngles()
	local start = Vector( 0, 0, 0 )
	local ang = Angle( 0, 0, 0 )
	local dir = LPCameraScreenToVector( gui.MouseX(), gui.MouseY(), ScrW(), ScrH(), ang, math.rad( 90 ) )
	--print( dir )
	
	-- Determine the normal
	local ang = ent:GetAngles()
	local rot = vBaseRot + self.Rotation
	ang:RotateAroundAxis(ang:Right(), 	rot.x)
	ang:RotateAroundAxis(ang:Up(), 		rot.y)
	ang:RotateAroundAxis(ang:Forward(), rot.z)
	local norm = ent:GetAngles():Forward()
	local oldang = ent:GetAngles()
	
	-- Build a matrix to translate from worldspace into 3d2dspace
	if (not mtx) then mtx = new( Matrix3 ) end
	mtx:SetRow( 1, -oldang:Right() )
	mtx:SetRow( 2, oldang:Up() )
	mtx:SetRow( 3, oldang:Forward() )
	
	-- Calculate the origin of the plane
	local offset = self.Position
	local pos = ent:GetPos() + (oldang:Forward() * offset.y) + (oldang:Up() * offset.z) + (oldang:Right() * -offset.x)
	
	-- Calculate the intersection between the line and the plane
	--print( norm, pos, start, dir )
	local mu = (norm:Dot(pos) - norm:Dot(start)) / norm:Dot(dir)
	local hitpos = start + (mu * dir)
	
	-- Transform from worldspace to 3d2dspace
	local lclpos = mtx:Transform( hitpos - pos )
	
	-- Normalise the coordinates and return
	return lclpos.x / self.Width, -lclpos.y / self.Height, mu
end
function InputDisplay:Update()
	self:CallBase( "Update" )
	local cx, cy, dist = self:CalculateCursorLocation()
	self._pcx = self._pcx or 0
	self._pcy = self._pcy or 0
	self._cx = math.Clamp( cx, 0, 1 )
	self._cy = math.Clamp( cy, 0, 1 )
	self._dist = dist
	local _hovered = (dist < self.InputDistance) and (cx >= 0) and (cx <= 1) and (cy >= 0) and (cy <= 1)
	if ((self._cx ~= self._pcx) or (self._cy ~= self._pcy)) then self:MouseMoved() end
	self._pcx = cx
	self._pcy = cy
	if (not _hovered) then
		if (self._leftclick) then
			self._leftclick = false
			self:LeftClick(false)
		end
		if (self._rightclick) then
			self._rightclick = false
			self:RightClick(false)
		end
		if (self._hovered) then
			self:NoLongerHovered()
		end
	end
	self._hovered = _hovered
end
function InputDisplay:HandlePress( code, state )
	if (not self._hovered) then return end
	--print( "HANDLE PRESS", self )
	if (code == 1) then
		if (self._leftclick ~= state) then
			self._leftclick = state
			self:LeftClick(state)
			return true
		end
	end
	if (code == 2) then
		if (self._rightclick ~= state) then
			self._rightclick = state
			self:RightClick(state)
			return true
		end
	end
end
function InputDisplay:LeftClick( state ) end
function InputDisplay:RightClick( state ) end
function InputDisplay:MouseMoved() end
function InputDisplay:NoLongerHovered() end
function InputDisplay:ShouldAcceptKBInput()
	return true
end
function InputDisplay:HandleKBInput( key )
	--print( "Handling KB inputnot  (" .. key .. ")" )
end
function InputDisplay:IsLeftDepressed() return self._leftclick end
function InputDisplay:IsRightDepressed() return self._rightclick end
function InputDisplay:GetCursorX()
	return self._cx or 0
end
function InputDisplay:GetCursorY()
	return self._cy or 0
end
function InputDisplay:GetHovered()
	return self._hovered
end

local currentdisplay

local function HackVGUI()
	local vgui = _G.vgui
	local table = _G.table
	local pairs = _G.pairs
	local Panel = _G.FindMetaTable( "Panel" )
	local function ValidPanel( pn )
		return (pn ~= nil) and (pn:IsValid())
	end
	
	if (not vgui.CreateOld) then

		vgui.CreateOld = vgui.Create
		Panel.RemoveOld = Panel.Remove
		Panel.SetParentOld = Panel.SetParent
		Panel.MouseCaptureOld = Panel.MouseCapture
		Panel.SetMouseInputEnabledOld = Panel.SetMouseInputEnabled
		
		function vgui.Create( ... )
			local args = { ... }
			local parent = args[2]
			local pn = vgui.CreateOld( ... )
			pn:AddToParentChildList()
			pn._dlib = pn:IsDisplayLib()
			return pn
		end
		
		function Panel:AddToParentChildList()
			local p = self:GetParent()
			p._children = p._children or {}
			--if (table.HasValue( p._children, self )) then return end
			for _, v in pairs( p._children ) do
				if (v == self) then return end
			end
			table.insert( p._children, self )
		end
		function Panel:RemoveFromParentChildList()
			local p = self:GetParent()
			if (p and p._children) then
				for key, val in pairs( p._children ) do
					if (val == self) then
						table.remove( p._children, key )
						break
					end
				end
			end
		end
		
		function Panel:Remove()
			self:RemoveFromParentChildList()
			self:RemoveOld()
		end
		
		function Panel:SetParent( parent )
			self:RemoveFromParentChildList()
			Panel.SetParentOld( self, parent )
			self:AddToParentChildList()
			self._dlib = self:IsDisplayLib()
		end
		
		function Panel:IsDisplayLib()
			if (self._root) then return true, self end
			if (self._dlib) then return self._dlib, self._rootpanel end
			local p = self:GetParent()
			if (ValidPanel( p )) then
				local b, root = p:IsDisplayLib()
				self._rootpanel = root
				return b, root
			end
			return false
		end
		
		function Panel:MouseCapture( b )
			if (self:IsDisplayLib() and self._rootpanel) then
				if (b) then
					self._rootpanel.activepanel = self
				else
					if (self._rootpanel.activepanel == self) then self._rootpanel.activepanel = nil end
				end
			else
				self:MouseCaptureOld( b )
			end
		end
		
		function Panel:SetMouseInputEnabled( b )
			self._mouseinputenabled = b
			--if (not self:IsDisplayLib()) then self:SetMouseInputEnabledOld( b ) end
		end
		
		function Panel:IsMouseInputEnabled()
			return (self._mouseinputenabled == nil) or self._mouseinputenabled
			
		end
	end

	function Panel:GetMousePos()
		if (currentdisplay) then
			return currentdisplay:GetCursorX() * currentdisplay:GetWidth() * currentdisplay:GetResolution(), currentdisplay:GetCursorY() * currentdisplay:GetHeight() * currentdisplay:GetResolution()
		else
			return gui.MousePos()
		end
	end

	function Panel:AbsolutePosition()
		if (self._root) then return 0, 0 end
		local px, py = 0, 0
		local p = self:GetParent()
		if (p) then px, py = p:AbsolutePosition() end
		local x, y = self:GetPos()
		return px + x, py + y
	end

	function Panel:PointInside( x, y )
		local myX, myY = self:AbsolutePosition()
		local w, h = self:GetSize()
		return (x >= myX) and (x <= myX+w) and (y >= myY) and (y <= myY+h)
	end

	function Panel:RaiseMouseEvent( name, cx, cy, ... )
		--MsgN( "RaiseMouseEvent (" .. name .. ") (" .. tostring( self ) .. " " .. (self.Derma and self.Derma.ClassName or "Unknown") .. ")" )
		--PrintTable( self:GetTable() )
		if (self._root and self.activepanel) then
			--MsgN( "Exiting on ActivePanel" )
			return self.activepanel[ name ]( self.activepanel, ... )
		end
		if (not self:PointInside( cx, cy )) then
			--MsgN( "Exiting on PointInside" )
			--displaylib.Print( "Mouse is not inside " .. tostring( self ) .. "not  (" .. cx .. ", " .. cy .. ")" )
			return false
		end
		if (self._children) then
			--MsgN( "I have " .. #self._children .. " children." )
			for _, pn in pairs( self._children ) do
				if (pn:RaiseMouseEvent( name, cx, cy, ... )) then return true end
			end
		end
		--displaylib.Print( "Calling self... (" .. tostring( self ) .. ")" )
		if (not self:IsMouseInputEnabled()) then return false end
		if (self[ name ]) then
			self[ name ]( self, ... )
			return true
		end
		return false
	end

	function Panel:__MouseDown( code )
		if (self.OnMousePressed) then self:OnMousePressed( code ) end
		self.__mousestate = self.__mousestate or {}
		self.__mousestate[code] = true
		if (not self:IsDisplayLib()) then return print( "NOT DISPLAY LIB" ) end
		local root = self._rootpanel
		if (root.__focus) then
			if (root.__focus.OnLoseFocus) then root.__focus:OnLoseFocus() end
			root.__focus._hasfocus = false
			root.__focus = nil
		end
		root.__focus = self
		--print( "SET FOCUS ON ROOT TO " .. tostring( self ) )
		self:RequestFocus()
		if (self.OnGetFocus) then self:OnGetFocus() end
		self._hasfocus = true
	end

	function Panel:__MouseUp( code )
		if (self.OnMouseReleased) then self:OnMouseReleased( code ) end
		self.__mousestate = self.__mousestate or {}
		self.__mousestate[code] = false
	end

	function Panel:CheckHovered( cx, cy )
		if (self._root and self.activepanel) then
			self.Hovered = false
			self.activepanel.Hovered = true
			return
		end
		local hovered = self:PointInside( cx, cy ) 
		if (hovered and (not self.Hovered)) then
			--self:OnCursorEntered()
			self.Hovered = true
		end
		if ((not hovered) and self.Hovered) then
			--self:OnCursorExited()
			self.Hovered = false
			if (self.__mousestate) then
				if (self.__mousestate[MOUSE_LEFT]) then
					if (self.OnMouseReleased) then self:OnMouseReleased( MOUSE_LEFT ) end
					self.__mousestate[MOUSE_LEFT] = false
				end
				if (self.__mousestate[MOUSE_RIGHT]) then
					if (self.OnMouseReleased) then self:OnMouseReleased( MOUSE_RIGHT ) end
					self.__mousestate[MOUSE_RIGHT] = false
				end
			end
		end
		if (self._children) then
			for _, pn in pairs( self._children ) do
				pn:CheckHovered( cx, cy )
			end
		end
	end
	function Panel:ResetHovered()
		self.Hovered = false
		if (self._children) then
			for _, pn in pairs( self._children ) do
				pn:ResetHovered()
			end
		end
	end

end

HackVGUI()

local host

class "VGUIDisplay" ("abstract") inherit "InputDisplay"
function VGUIDisplay:VGUIDisplay( ent )
	if (not host) then
		host = vgui.Create( "DPanel" )
		function host:Paint() end
		host:SetSize( ScrW(), ScrH() )
		host:SetPos( 0, 0 )
		host:SetMouseInputEnabled( false )
	end
end
function VGUIDisplay:Init()
	--print( "VGUIDisplay:Init" )
	local w, h = self.Width * self.Resolution, self.Height * self.Resolution
	local pn = vgui.Create( "DPanel", host )
	function pn:Paint() end
	pn:SetPos( 0, 0 )
	pn:SetSize( w, h )
	pn:SetPaintedManually( true )
	pn._root = true
	--pn:SetVisible( false )
	self._panel = pn
	self:InitVGUI()
	--pn:SetSize( 0, 0 )
end
function VGUIDisplay:Remove()
	self:CallBase( "Remove" )
	self._panel:Remove()
end
function VGUIDisplay:LeftClick( state )
	if (not self:GetHovered()) then return end
	--print( "VGUIDisplay LeftClick (" .. tostring(state) .. ")" )
	currentdisplay = self
	local w, h = self.Width * self.Resolution, self.Height * self.Resolution
	if (state) then
		self._panel:RaiseMouseEvent( "__MouseDown", self._cx * w, self._cy * h, MOUSE_LEFT )
	else
		self._panel:RaiseMouseEvent( "__MouseUp", self._cx * w, self._cy * h, MOUSE_LEFT )
	end
end
function InputDisplay:NoLongerHovered()
	self._panel:ResetHovered()
end
function VGUIDisplay:RightClick( state )
	if (not self:GetHovered()) then return end
	currentdisplay = self
	
end
local UpperNumbers = {
	[1] = "not ",
	[2] = "\"",
	[3] = "£",
	[4] = "$",
	[5] = "%",
	[6] = "^",
	[7] = "&",
	[8] = "*",
	[9] = "(",
	[0] = ")"
}
local function TranslateKey( key, shift )
	if (key >= KEY_A) and (key <= KEY_Z) then
		local char = string.char( ("a"):byte() + key - KEY_A )
		if (shift) then char = char:upper() end
		return char
	end
	if (key >= KEY_0) and (key <= KEY_9) then
		local char = string.char( ("0"):byte() + key - KEY_0 )
		if (shift) then char = UpperNumbers[tonumber(char)] or char end
		return char
	end
	if (key == KEY_SPACE) then return " " end
	if (shift) then
		if (key == KEY_COMMA) then return "<" end
		if (key == KEY_PERIOD) then return ">" end
		if (key == KEY_EQUAL) then return "+" end
		if (key == KEY_MINUS) then return "_" end
	else
		if (key == KEY_COMMA) then return "," end
		if (key == KEY_PERIOD) then return "." end
		if (key == KEY_EQUAL) then return "=" end
		if (key == KEY_MINUS) then return "-" end
	end
end
function VGUIDisplay:HandleKBInput( key )
	local focus = self._panel.__focus
	if (focus) then
		if (focus.OnKeyCodeTyped) then
			focus:OnKeyCodeTyped( key )
			local caret = focus:GetCaretPos()
			local val = focus:GetValue()
			local left = val:sub( 1, caret )
			local right = val:sub( caret + 1 )
			local char = TranslateKey( key, input.IsKeyDown( KEY_LSHIFT ) or input.IsKeyDown( KEY_RSHIFT ) )
			--print( "TRANSLATE KEY: '" .. tostring( char ) .. "'" )
			if (char) then
				focus:SetValue( left .. char .. right )
				focus:SetCaretPos( math.Clamp( caret + 1, 0, val:len()+1 ) )
			elseif (key == KEY_BACKSPACE) then
				left = left:sub( 1, left:len() - 1 )
				focus:SetValue( left .. right )
				focus:SetCaretPos( math.Clamp( caret - 1, 0, val:len()-1 ) )
			elseif (key == KEY_DELETE) then
				right = right:sub( 2 )
				focus:SetValue( left .. right )
			elseif (key == KEY_LEFT) then
				focus:SetCaretPos( math.Clamp( caret - 1, 0, val:len() ) )
			elseif (key == KEY_RIGHT) then
				focus:SetCaretPos( math.Clamp( caret + 1, 0, val:len() ) )
			end
		end
	end
end
function VGUIDisplay:ShouldAcceptKBInput()
	local focus = self._panel.__focus
	if (focus) then MsgN( "Focus panel is " .. tostring( focus ) .. "(" .. (focus.Derma and focus.Derma.ClassName or "Unknown") .. ")" ) end
	return focus and focus.OnKeyCodeTyped
end
function VGUIDisplay:MouseMoved()
	if (not self:GetHovered()) then return end
	currentdisplay = self
	local w, h = self.Width * self.Resolution, self.Height * self.Resolution
	self._panel:CheckHovered( self._cx * w, self._cy * h )
end
function VGUIDisplay:InitVGUI()
	
end
function VGUIDisplay:Render( w, h )
	local pn = self._panel
	pn:SetPaintedManually( false )
	pn:PaintManual()
	pn:SetPaintedManually( true )
end
function VGUIDisplay:GetPanel()
	return self._panel
end