-- Version 0.22

--[[--------------------------------------------------------------------------
TabFret is currently a developmental test object. It is recommended that this
object, as currently implemented, not be used for anything other than
exploratory testing.

TabFret is used to add a guitar fret numbers to a TabStaff. You should add
a TabStaff object first, prior to using this object.

@S1
This is the fret assignment for string #1. Leave it blank if it should not be played.
@S2
This is the fret assignment for string #2. Leave it blank if it should not be played.
@S3
This is the fret assignment for string #3. Leave it blank if it should not be played.
@S4
This is the fret assignment for string #4. Leave it blank if it should not be played.
@S5
This is the fret assignment for string #5. Leave it blank if it should not be played.
@S6
This is the fret assignment for string #6. Leave it blank if it should not be played.

--]]--------------------------------------------------------------------------

-- our object type is passed into the script
local userObjTypeName = ...
local idTabStaff = 'TabStaff.nw'

local obj_spec = {}

local tabStringList = {'S6','S5','S4','S3','S2','S1'}

for i,s in ipairs(tabStringList) do
	table.insert(obj_spec,1,{id=s, label='Fret for String &'..(7-i), type='text', default=''})
end
	

------------------------------------------------------------------------------
local auditidx = nwc.ntnidx.new()
local function obj_audit(t)
	if auditidx:find('prior','user',idTabStaff) then
		t.Pos = auditidx:staffPos()
	end
end

------------------------------------------------------------------------------
local function obj_create(t)
	obj_audit(t)
end

------------------------------------------------------------------------------
local function obj_spin(t,d)
end

------------------------------------------------------------------------------
local function obj_transpose(t,semitones,notepos,updpatch)
end

------------------------------------------------------------------------------
local function obj_play(t)
end

------------------------------------------------------------------------------
local drawIdx = nwc.drawpos
local noteIdx = nwc.drawpos.new()
local tabStaffIdx = nwc.drawpos.new()
local drawFretNumbers = {'','','','','',''}
--
local function obj_draw(t)
	if not tabStaffIdx:find('first','user',idTabStaff) then return end

	local h = tabStaffIdx:userProp('Size')*3
	local w = 0
	local c = nwcdraw

	c.setFont('Times',1.5*h,'r')
	for i,s in ipairs(tabStringList) do
		local s_v = string.match(t[s],'%(*%d+%)*') or ''
		drawFretNumbers[i] = s_v

		if s_v ~= '' then
			local s_w = c.calcTextSize(s_v)
			w = math.max(w,s_w)
		end
	end

	local preserveWidth = false
	--
	noteIdx:reset()
	drawIdx:reset()
	--
	if not noteIdx:find('next','note') then
		preserveWidth = true
	elseif drawIdx:find('next','user',userObjTypeName) and (drawIdx < noteIdx) then
		preserveWidth = true
	end

	if not c.isDrawing() then
		print("Fret width done")
		return preserveWidth and (w+0.5) or 0
	end

	drawIdx:reset()

	local x,y = tabStaffIdx:xyAnchor()

	x = preserveWidth and c.user:width()/2 or noteIdx:xyTimeslot()+w/2

	c.alignText('middle','center')
	c.opaqueMode(true)
	--
	for i=1,6 do
		local s_v = drawFretNumbers[i]

		if s_v ~= '' then
			local y1 = y + h*(i-1)
			c.moveTo(x,y1)
			c.text(s_v)
		end
	end
end

------------------------------------------------------------------------------

return {
	spec		= obj_spec,
	create		= obj_create,
	audit		= obj_audit,
	spin		= obj_spin,
	draw		= obj_draw,
	}
