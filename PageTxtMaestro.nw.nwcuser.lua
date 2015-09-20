-- Version 0.6

--[[--------------------------------------------------------------------------
PageTxtMaestro enables PageTxt objects to be displayed on each printed page. 
You must add an instance of this object before PageTxt objects will show on 
the printed page.
--]]--------------------------------------------------------------------------

-- our object type is passed into the script
local userObjTypeName = ...
local userObjSigName = nwc.toolbox.genSigName(userObjTypeName)
local textObjectType = 'PageTxt.nw'

------------------------------------------------------------------------------
--
local function obj_create(t)
	t.Class = 'StaffSig'
end

------------------------------------------------------------------------------
--
local drawidx = nwc.drawpos
local ntnidx = nwc.ntnidx
local pg_l,pg_t,pg_r,pg_b = 0,0,0,0
--
local dynamicVars = {
	Title		= nwcdraw.getSongInfo,
	Author		= nwcdraw.getSongInfo,
	Lyricist	= nwcdraw.getSongInfo,
	Copyright1	= nwcdraw.getSongInfo,
	Copyright2	= nwcdraw.getSongInfo,
	StaffName	= {nwcdraw.getStaffProp, 'Name'},
	StaffLabel	= {nwcdraw.getStaffProp, 'Label'},
	StaffLabelAbbr	= {nwcdraw.getStaffProp, 'LabelAbbr'},
	StaffGroup	= {nwcdraw.getStaffProp, 'Group'},
	PageNum		= nwcdraw.getPageCounter,
	['PageNum,1'] = nwcdraw.getPageCounter,
	}

local function doTextSubstitution(txt)
	if txt == '%%' then return '%' end

	txt = txt:sub(2,-2)

	local f = dynamicVars[txt]

	if not f then
		local pagenumoffset = txt:match('^PageNum,(-*%d+)')
		if pagenumoffset then return nwcdraw.getPageCounter() - 1 + tonumber(pagenumoffset) end

		return '?'
	end
	
	if type(f) == "table" then return f[1](f[2]) or '?' end

	return f(txt) or '?'
end

--
local function isDefault(s) return s == '<default>' end
--
local firstTxtIdx = nwc.ntnidx.new()
local XLocMirror = {Left='Right',Right='Left'}
--
local function doTextDraw(idx,pgstyle)
	local txt = idx:userProp('Text')
	local fnt = idx:userProp('Fnt')
	local fntsz = idx:userProp('FntSz')
	local spoth,spotv = idx:userProp('XLoc'), idx:userProp('YLoc')
	local cx,cy = idx:userProp('CX'),idx:userProp('CY')
	local x,y = 0,0
	local pgctrl = idx:userProp('PgCtrl')

	-- we cannot totally implement Visibility, but we can respect a Never setting
	if idx:userProp('Visibility') == 'Never' then return end

	firstTxtIdx:find('first','user',textObjectType)
	while firstTxtIdx:userProp('PgStyle') ~= pgstyle do
		-- this cannot reallt fail, but just in case, we abort
		if not firstTxtIdx:find('next','user',textObjectType) then return end
	end

	if isDefault(fnt) then
		fnt = firstTxtIdx:userProp('Fnt')
		fntsz = firstTxtIdx:userProp('FntSz')
		if isDefault(fnt) then fnt = 'PageText' end
	end

	if isDefault(spoth) then
		spoth = firstTxtIdx:userProp('XLoc')
		cx = firstTxtIdx:userProp('CX')
		if isDefault(spoth) then spoth = 'Left' end
	end

	if isDefault(spotv) then
		spotv = firstTxtIdx:userProp('YLoc')
		cy = firstTxtIdx:userProp('CY')
		if isDefault(spotv) then spotv = 'Top' end
	end

	if isDefault(pgctrl) then
		pgctrl = firstTxtIdx:userProp('PgCtrl')
		if isDefault(pgctrl) then pgctrl = 'All' end
	end

	local isEvenPageNum = (nwcdraw.getPageCounter() % 2) == 0
	local oddEvenCtrl = pgctrl:match('^(%w+) Pages$')
	if oddEvenCtrl then
		if oddEvenCtrl == 'Odd' then
			if isEvenPageNum then return end
		elseif not isEvenPageNum then
			return
		end
	end

	if (pgctrl ~= 'No Mirroring') and nwcdraw.getPageMargin('Mirror') and XLocMirror[spoth] and isEvenPageNum then
		spoth = XLocMirror[spoth]
	end

	if spotv == 'Top' then
		y = pg_t - cy
	else
		y = pg_b + cy
	end

	if spoth == 'Left' then
		x = pg_l + cx
	elseif spoth == 'Center' then
		x = (pg_l + pg_r)/2 + cx
	else
		x = pg_r - cx
	end

	txt = txt:gsub('(%%[^%% ]*%%)',doTextSubstitution)

	nwcdraw.moveTo(x,y)
	nwcdraw.alignText(spotv,spoth)
	nwcdraw.setFontClass(fnt)
	--
	if math.abs(fntsz - 1.0) > 0.01 then
		nwcdraw.setFontSize(nwcdraw.getFontSize()*fntsz)
	end
	--
	nwcdraw.text(txt)
end

local function obj_draw(t)
	local w = nwc.toolbox.drawStaffSigLabel(userObjSigName)
	if (not nwcdraw.isDrawing()) or (w > 0) then return w end

	if nwcdraw.getTarget() ~= 'print' then return end
	if not drawidx:find('next','noteOrRest') then return end
	if nwcdraw.getSystemCounter() > 1 then return end

	ntnidx:find(drawidx)

	pg_l,pg_t,pg_r,pg_b = nwcdraw.getPageRect()

	local handledSpots = {}
	while ntnidx:find('prior','user',textObjectType) do
		local pgstyle = ntnidx:userProp('PgStyle')

		if not handledSpots[pgstyle] then
			doTextDraw(ntnidx,pgstyle)
			handledSpots[pgstyle] = 1
		end
	end
end

------------------------------------------------------------------------------

return {
	create		= obj_create,
	draw		= obj_draw,
	width		= obj_draw,
	}
