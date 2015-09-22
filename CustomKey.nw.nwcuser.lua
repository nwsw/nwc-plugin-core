-- Version 1.0

--[[-----------------------------------------------------------------------------------------
CustomKey.nw <http://nwsw.net/-f9077>

This object is best used with the Accidentals font, by Ertuğrul İnanç. It can be found at:

http://nwc-scriptorium.org/sfontr.html

This object allows a list of accidental strings to be defined such that they form a
custom key signature. A list of accidentals are defined by a series of comma separated
strings. Each string in the sequence gets displayed at the next position in the circle
of fifths. An empty string can be used to skip a position in the circle of fifths.
By default, the circle of fifths position starts at position 0, and cycles through the
standard flat circle of fifth positions. If the list continues, the traditional sharp 
circle of fifth positions are used. If the list continues, then the process wraps and
starts over again with position 0.

The starting position in the flat to sharp circle of fifths can be defined. This can be
used to start with the first sharp position. The exact location for each positoin is
relative to the user object's position, which allows the user additional flexibility.

@AccList
List the accidentals, separated by a comma
@Start
The starting position for the custom signature.
@Font
This is the font typeface used to draw the custom signature characters. This is typically
the Accidentals font, but can be set to a number from 1 through 6 to reference a User font.
@Size
This is the font size to use. This is ignored when a user font is designated by the Font property.

--]]-----------------------------------------------------------------------------------------

-- our object type is passed into the script
local userObjTypeName = ...

local KeysOrder  = {0,3,-1,2,5,1,4,1,5,2,-1,3}
local XAccMatch = '([^,]*)[,]?'

local userObj = nwc.ntnidx
local searchObj = userObj.new()

---------------------------------------------------------------------------------------------
-- the 'spec' table is used to filter the object properties as they are returned from 't'
local obj_spec = {
	{id='AccList',label='Accidental List',type='text',default='3,3'},
	{id='Start',label='Start Position',type='int',default=6,min=0,max=#KeysOrder},
	{id='Font',label='Font Typeface',type='text',default='Accidentals'},
	{id='Size',label='Font Size',type='float',default=8,min=0.1,max=50},
	}

---------------------------------------------------------------------------------------------
-- the 'create' method is used to establish the object properties that will
-- control our plugin object
local function do_create(t)
	t.Class = 'StaffSig'
	t.Pos = 0

	if nwcui.askbox('Should this key start with flats?') == 1 then
		t.AccList = '1,1'
		t.Start = 0
	end

	if not nwc.hasTypeface('Accidentals') then
		t.Font = nwcui.prompt('Accidentals font not found...which user font do you want to use?','#[1-6]',1)
	end
end

---------------------------------------------------------------------------------------------
-- the 'width' and 'draw' methods are combined here, and are used in the
-- formatting and display of our object on the NWC staff
--
local function do_draw(t)
	local accList = t.AccList
	local font = t.Font
	local fontsize = t.Size

	if accList:len() < 1 then return end

	if font:match('^[1-6]$') then
		nwcdraw.setFontClass('User'..font)
	elseif nwc.hasTypeface(font) then
		nwcdraw.setFont(font,-fontsize)
	elseif (font ~= 'Accidentals') and nwc.hasTypeface('Accidentals') then
		nwcdraw.setFont('Accidentals',-fontsize)
	else
		nwcdraw.setFont('NWC2STDA',fontsize)
	end

	local cw,h,descent = nwcdraw.calcTextSize('?')
	local w = .5

	for c in accList:gmatch(XAccMatch) do
		if c:len() > 0 then w = w + nwcdraw.calcTextSize(c) + .25 end
	end
	
	if not nwcdraw.isDrawing() then return w end

	local x = -nwcdraw.width()
	local y = -h/2
	
	nwcdraw.alignText('bottom','left')

	local i = t.Start

	for c in accList:gmatch(XAccMatch) do
		if c:len() > 0 then
			nwcdraw.moveTo(x,y+KeysOrder[1+(i%(#KeysOrder-1))])
			nwcdraw.text(c)

			x = x + nwcdraw.calcTextSize(c) + .25
		end
			
		i = i + 1
	end
end

---------------------------------------------------------------------------------------------

return {
	spec		= obj_spec,
	create		= do_create,
	width		= do_draw,
	draw		= do_draw
	}
