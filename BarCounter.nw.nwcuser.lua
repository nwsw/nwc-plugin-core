-- Version 1.0

--[[-----------------------------------------------------------------------------------------
BarCounter.nw <http://nwsw.net/-f9198>

This object can be used to create a custom bar counter.

Usage:
- turn off the built-in bar counter from File, Page Setup
- add this object at the start of your file's top staff
- add new instances of this object whenever you want to reset the bar count


@StartAt
Enter the starting bar count here.

@HideStart
This hides the initial starting bar count value when printing. Turn this off if you want the initial
starting bar count value to be shown.

--]]-----------------------------------------------------------------------------------------

local userObjTypeName = ...
local userObjSigName = nwc.toolbox.genSigName(userObjTypeName)

---------------------------------------------------------------------------------------------
local obj_spec = {
	{id='StartAt',label='Starting Bar Number',type='int',default=1,min=-1000,max=999999},
	{id='HideStart',label='Hide Starting Bar Number',type='bool',default=true},
	}

---------------------------------------------------------------------------------------------
local function do_create(t)
	t.Class = 'StaffSig'
	t.Pos = 7
end

---------------------------------------------------------------------------------------------
local function obj_spin(t,d)
	t.StartAt = t.StartAt + d
end

---------------------------------------------------------------------------------------------
local drawidx1 = nwc.drawpos
local objidx = nwc.ntnidx
local searchidx = objidx.new()
local noteobjTypes = {Note=1,Rest=1,Chord=1,RestChord=1}
local editmodeTypes = {edit=1,selector=1}
local c = nwcdraw

local function do_draw(t)
	local w = nwc.toolbox.drawStaffSigLabel(userObjSigName)
	--
	if not c.isDrawing() then return w end

	local me = c.user
	local me_autoins = me:isAutoInsert()
	local editMode = editmodeTypes[c.getTarget()]
	local barCount = 0
	local x1,y1 = 0,0

	drawidx1:reset()

	if editMode and not me_autoins then
		if not drawidx1:find('prior','bar') then drawidx1:find('first') end
	end

	if not editMode and not me_autoins and t.HideStart then return end

	if not editMode then
		-- don't do anything when hidden
		if me:isHidden() then return end

		if me_autoins then
			drawidx1:find('first')
		else
			drawidx1:find('prior','bar')
		end
	end

	x1,y1 = drawidx1:xyAnchor()

	local pendingBar = 0
	--
	if me_autoins and drawidx1:find('first','noteOrRest') then
		if drawidx1:isAutoInsert() and (drawidx1:objType() == 'RestMultiBar') then
			pendingBar = drawidx1:barCounter()
		end
	else
		drawidx1:reset()
	end

	-- start from the first note and count bars backwards
	objidx:reset()
	searchidx:find(drawidx1)
	while searchidx:find('prior') and (searchidx > objidx) do
		local objt = searchidx:objType()
		
		if objt == 'RestMultiBar' then
			pendingBar = tonumber(searchidx:objProp('NumBars'))
		elseif noteobjTypes[objt] and (pendingBar < 1) then
			pendingBar = 1
		elseif objt == 'Bar' then
			barCount = barCount + pendingBar
			pendingBar = 0
		end
	end

	barCount = barCount + pendingBar + t.StartAt

	c.setFontClass('StaffBold')
	c.moveTo(x1)
	c.alignText('bottom','center')
	c.text(barCount)
end

---------------------------------------------------------------------------------------------

return {
	spec		= obj_spec,
	create		= do_create,
	spin		= do_spin,
	width		= do_draw,
	draw		= do_draw
	}
