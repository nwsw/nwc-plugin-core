-- Version 1.1

--[[--------------------------------------------------------------------------
TabStaff is used to add a guitar tab staff to your NWC file. You can add this
object into the current staff, or create a new staff that has no staff lines.
This object will take care of drawing the guitar strings that comprise the
guitar tablature.

@Strings
This establishes the number of strings in the tab staff.

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
	{ id='Strings', label='Number of Strings', type='int', min=1, max=6, step=1, default=6 },
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
	local numStrings = t.Strings
	local h = t.Size*3
	local total_h = h*(numStrings-1)
	local center_h = total_h/2
	local c = nwcdraw

	-- only the first tabStaff in a system is used
	if drawidx1:find('prior','user',userObjTypeName) then return end

	drawidx1:find('first')
	drawidx2:find('last')

	local x1,y1 = drawidx1:xyAnchor()
	local x2,y2 = drawidx2:xyAnchor()
	for i=1,numStrings do
		y1 = h*(i-1)
		c.moveTo(x1,y1)
		c.line(x2,y1)
	end

	c.setFontClass('StaffSymbols')
	local dotWidth = c.calcTextSize('J')
	local barHalfH = math.max(center_h,h/2)
	--
	drawidx1:find('first','bar')
	repeat
		local barstyle = drawidx1:objProp('Style')
		x1 = drawidx1:xyAnchor()
		c.moveTo(x1)
		local barw = c.barSegment(barstyle,center_h+barHalfH,center_h-barHalfH)
		local drawRepeat = false

		if barstyle:match('RepeatClose') then
			drawRepeat = x1 + dotWidth
		elseif barstyle:match('RepeatOpen') then
			drawRepeat = x1+barw
		end

		if drawRepeat then
			local cgap = (numStrings < 3) and (barHalfH/2) or (((numStrings % 2) < 0.5) and h or h/2)

			for dotpos=-1,1,2 do
				c.moveTo(drawRepeat-dotWidth/2,center_h + dotpos*cgap)
				c.beginPath()
					c.ellipse(dotWidth/2)
				c.endPath()
			end
		end
	until not drawidx1:find('next','bar')

	if drawidx1:find('first','clef') then
		local tabtxt_h = math.min(5*h,math.max(3*h,total_h))
		local letterh = tabtxt_h/3
		x1 = drawidx1:xyAnchor()
		c.setFont('Times',-(1.1*letterh),'b')
		c.alignText('middle','left')
		local centerh = total_h/2
		for i,letter in ipairs(TAB) do
			c.moveTo(x1,centerh + (2-i)*letterh)
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
