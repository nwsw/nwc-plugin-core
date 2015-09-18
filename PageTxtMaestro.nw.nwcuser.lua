-- Version 0.1

--[[--------------------------------------------------------------------------
PageTxtMaestro enables PageTxt objects to be displayed on each printed page. 
You must add an instance of this object before PageTxt objects will show on 
the printed page.
--]]--------------------------------------------------------------------------

-- our object type is passed into the script
local userObjTypeName = ...
local userObjSigName = nwc.toolbox.genSigName(userObjTypeName)
local textObjectType = 'PageTxt.nw'

local pageTxtPositionList = {'top-left', 'top-center', 'top-right','bottom-left', 'bottom-center', 'bottom-right'}

local function obj_create(t)
	t.Class = 'StaffSig'
end

------------------------------------------------------------------------------
--
local drawidx = nwc.drawpos
local ntnidx = nwc.ntnidx
local pg_l,pg_t,pg_r,pg_b = 0,0,0,0
--
local function doTextDraw(idx)
	local txt = idx:userProp('Text')
	local fnt = idx:userProp('Fnt')
	local spot = idx:userProp('PgLoc')
	local spotv,spoth = spot:match('^([^-]+)-(.+)$')
	local cx,cy = idx:userProp('CX'),idx:userProp('CY')
	local x,y = 0,0

	if spotv == 'top' then
		y = pg_t
	else
		y = pg_b
	end

	if spoth == 'left' then
		x = pg_l
	elseif spoth == 'center' then
		x = (pg_r - pg_l)/2
	else
		x = pg_r
	end

	nwcdraw.moveTo(x + cx,y + cy)
	nwcdraw.alignText(spotv,spoth)
	nwcdraw.setFontClass(fnt)
	nwcdraw.text(txt)
end

local function obj_draw(t)
	local w = nwc.toolbox.drawStaffSigLabel(userObjSigName)
	if (not nwcdraw.isDrawing()) or (w > 0) then return w end

	if not drawidx:find('next','noteOrRest') then return end
	if nwcdraw.getSystemCounter() > 1 then return end

	ntnidx:find(drawidx)

	pg_l,pg_t,pg_r,pg_b = nwcdraw.getPageRect()

	local handledSpots = {}
	while ntnidx:find('prior','user',textObjectType) do
		local spot = ntnidx:userProp('PgLoc')

		if not handledSpots[spot] then
			doTextDraw(ntnidx)
			handledSpots[spot] = 1
		end
	end
end

------------------------------------------------------------------------------

return {
	create		= obj_create,
	draw		= obj_draw,
	width		= obj_draw,
	}
