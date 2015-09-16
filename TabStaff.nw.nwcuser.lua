-- Version 0.24

--[[--------------------------------------------------------------------------
TabStaff is currently a developmental test object. It is recommended that this
object, as currently implemented, not be used for anything other than
exploratory testing.

TabStaff is used to add a guitar tab staff to your NWC file. You can add this
object into the current staff, or create a new staff that has no staff lines.
This object will take care of drawing the guitar strings that comprise the
guitar tablature.

@Size
This establishes the height of tab staff. Specifically, it sets the gap height
between each guitar string.

@Opaque
When enabled, the fret numbers drawn by TabFret.nw objects will be opaque in
the TabStaff.

--]]--------------------------------------------------------------------------

-- our object type is passed into the script
local userObjTypeName = ...

-- things work best when all fields supported by the plugin are published in a
-- spec table
local obj_spec = {
	{ id='Size', label='Tablature Size', type='float', min=.3, max=4.0, step=0.1, default=1 },
	{ id='Opaque', label='Opaque Mode', type='bool', default=true },
}

------------------------------------------------------------------------------
--
local function obj_create(t)
	t.Class = 'StaffSig'
end

------------------------------------------------------------------------------
--
local function obj_audit(t)
end

------------------------------------------------------------------------------
--
local function obj_spin(t,d)
	t.Size = t.Size + 0.1*d
end

------------------------------------------------------------------------------
--
local function obj_transpose(t,semitones,notepos,updpatch)
end

------------------------------------------------------------------------------
--
local function obj_play(t)
end

------------------------------------------------------------------------------
--
local TAB = {'T','A','B'}
local drawidx1 = nwc.drawpos
local drawidx2 = nwc.drawpos.new()
--
local function obj_draw(t)
	local h = t.Size*3
	local c = nwcdraw

	drawidx1:find('first')
	drawidx2:find('last')

	local x1,y1 = drawidx1:xyAnchor()
	local x2,y2 = drawidx2:xyAnchor()
	for i=1,6 do
		y1 = h*(i-1)
		c.moveTo(x1,y1)
		c.line(x2,y1)
	end

	c.setFontClass('StaffSymbols')
	local dotWidth = c.calcTextSize('J')
	--
	drawidx1:find('first','bar')
	repeat
		local barstyle = drawidx1:objProp('Style')
		x1 = drawidx1:xyAnchor()
		c.moveTo(x1)
		local barw = c.barSegment(barstyle,5*h,0)
		local drawRepeat = false

		if barstyle:match('RepeatClose') then
			drawRepeat = x1 + dotWidth
		elseif barstyle:match('RepeatOpen') then
			drawRepeat = x1+barw
		end

		if drawRepeat then
			for dotpos=1,2 do
				c.moveTo(drawRepeat-dotWidth/2,(2*dotpos*h)-h/2)
				c.beginPath()
					c.ellipse(dotWidth/2)
				c.endPath()
			end
		end
	until not drawidx1:find('next','bar')

	if drawidx1:find('first','clef') then
		x1 = drawidx1:xyAnchor()
		c.setFont('Times',2.2*h,'b')
		c.alignText('middle','left')
		local letterh = 1.8*h
		for i,letter in ipairs(TAB) do
			c.moveTo(x1,(2.5*h) + (2-i)*letterh)
			c.text(letter)
		end
	end
end

------------------------------------------------------------------------------
-- all object plug-ins must return the methods that they support in a
-- standard method table; uncomment any additional methods as needed

return {
	spec		= obj_spec,
	create		= obj_create,
	spin		= obj_spin,
	draw		= obj_draw
	}
