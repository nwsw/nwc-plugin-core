-- Version 0.6

--[[-----------------------------------------------------------------------------------------
CustomKey.nw

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

For more information, please refer to this plugin's topic on the NWC forums:

https://forum.noteworthycomposer.com/?topic=9077

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
	Span	= {type='int',default=0,min=0,max=32},
	Start	= {type='int',default=0,min=0,max=#KeysOrder},
	AccList	= {type='text',default=''},
	Font	= {type='text',default=nil},
	Size	= {type='float',default=-8,min=0.1,max=50},
	}

---------------------------------------------------------------------------------------------
-- the 'create' method is used to establish the object properties that will
-- control our plugin object
local function do_create(t)
	local s = '1,1'

	t.Class = 'StaffSig'

	if nwcui.askbox('Should this key start with sharps?') == 1 then
		t.Start = 6
		s = '3,3'
	end

	-- the prompt does not currently support custom fonts, but once displayed in the
	-- staff, the user should get the idea of it
	t.AccList = nwcui.prompt('List the accidentals, separated by a comma','*',s)

	if not nwc.hasTypeface('Accidentals') then
		t.Font = nwcui.prompt('Which user font do you want to use?','#[1-8]',1)
	end
end

---------------------------------------------------------------------------------------------
-- the 'audit' method is called whenever something has changed in the area of the object,
-- including the object itself
local function do_audit(t)
end

---------------------------------------------------------------------------------------------
-- the 'spin' method is called whenever the user applied the +/- keys to our 
-- object from within the editor
local function do_spin(t,d)
end

---------------------------------------------------------------------------------------------
-- the 'transpose' method is called whenever the user runs the Transpose Staff
-- command from within the editor
local function do_transpose(t,semitones,notepos,updpatch)
end

---------------------------------------------------------------------------------------------
-- the 'play' method is called whenever our notatation is compiled into a
-- midi performance
local function do_play(t)
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

	if tonumber(font) then
		nwcdraw.setFontClass('User'..tonumber(font))
	elseif font and nwc.hasTypeface(font) then
		nwcdraw.setFont(font,fontsize)
	elseif nwc.hasTypeface('Accidentals') then
		nwcdraw.setFont('Accidentals',fontsize)
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
--	audit		= do_audit,
--	spin		= do_spin,
--	transpose	= do_transpose,
--	play		= do_play,
	width		= do_draw,
	draw		= do_draw
	}
