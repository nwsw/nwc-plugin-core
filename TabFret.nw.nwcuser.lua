-- Version 1.1

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

local tabStringList = {'S1','S2','S3','S4','S5','S6'}

for i,s in ipairs(tabStringList) do
	table.insert(obj_spec,{id=s, label='Fret for String &'..i, type='text', default=''})
end
	
local scanIdx = nwc.ntnidx.new()

------------------------------------------------------------------------------
local function obj_audit(t)
	if scanIdx:find('prior','user',idTabStaff) then
		t.Pos = scanIdx:staffPos()
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
local noteDrawIdx = nwc.drawpos.new()
local tabStaffIdx = nwc.drawpos.new()
--
local function ForcesPreserveWidth(idx)
	local ot = idx:objType()
	if (ot == 'User') and (idx:userType() == userObjTypeName) then return true end
	if (ot == 'Bar') then return true end
	return false
end

local function obj_draw(t)
	if not tabStaffIdx:find('first','user',idTabStaff) then return end

	local opaqueMode = tabStaffIdx:userProp('Opaque')
	local numStrings = tabStaffIdx:userProp('Strings')
	local h = tabStaffIdx:userProp('Size')*3
	local total_h = h*(numStrings-1)
	local c = nwcdraw

	c.setFont('Times',(opaqueMode and 1.3 or 1.4)*h,'r')

	local w = c.calcTextSize("8")
	local preserveWidth = false

	scanIdx:reset()
	if scanIdx:find('next','note') then
		repeat scanIdx:find('prior') until ForcesPreserveWidth(scanIdx)
		if scanIdx:indexOffset() > 0 then
			preserveWidth = true
		end
	else
		preserveWidth = true
	end

	if not c.isDrawing() then
		return preserveWidth and w*2 or 0
	end

	noteDrawIdx:reset()
	noteDrawIdx:find('next','note')

	local x = preserveWidth and -c.user:width()/2 or noteDrawIdx:xyTimeslot()+w/2
	local _,y = tabStaffIdx:xyAnchor()

	c.alignText('middle','center')
	c.opaqueMode(opaqueMode)

	for i,s in ipairs(tabStringList) do
		local s_v = string.match(t[s],'%(*%d+%)*') or ''

		if s_v ~= '' then
			local y1 = y + total_h - (h*(i-1))
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
	width		= obj_draw,
	draw		= obj_draw,
	}
