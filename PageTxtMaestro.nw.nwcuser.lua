-- Version 1.21

--[[--------------------------------------------------------------------------
PageTxtMaestro.nw	<http://nwsw.net/-f9215>

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
local function getCommentLabel(lbl)
	local s = nwcdraw.getSongInfo('Comments') or ''
	local x = string.format('^%s:%%s*([^\r\n]+)',lbl)

	for line in s:gmatch('([^\n]+)')  do
		local r = line:match(x)
		if r then return r end
	end

	return false
end

local dynamicVars = {
	br			= '\n',
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
		local pagenumoffset = txt:match('^PageNum,(-*%d+)$')
		if pagenumoffset then return nwcdraw.getPageCounter() - 1 + tonumber(pagenumoffset) end

		local cLabel = txt:match('^Comment,(%w+)$')
		if cLabel then return getCommentLabel(cLabel) or '' end

		return '?'
	end
	
	if type(f) == "string" then return f end
	if type(f) == "table" then return f[1](f[2]) or '?' end

	return f(txt) or '?'
end

--
local function isDefault(s) return s == '<default>' end

local firstTxtIdx = nwc.ntnidx.new()
--
local function syncFirstTxtIdx(pgstyle)
	if (firstTxtIdx:userType() == textObjectType) and (firstTxtIdx:userProp('PgStyle') == pgstyle) then return end
	firstTxtIdx:find('first','user',textObjectType)
	while firstTxtIdx:userProp('PgStyle') ~= pgstyle do
		-- when things are working right, this cannot really fail, but just in case...
		if not firstTxtIdx:find('next','user',textObjectType) then return end
	end
end
--
local function getTxtPropVal(idx,propname,defvalue)
	local v = idx:userProp(propname)
	if isDefault(v) then
		v = firstTxtIdx:userProp(propname)
		if isDefault(v) then v = defvalue end
	end

	return v
end
--
local function isOnceText(idx)
	local v = idx:userProp('PgCtrl')
	if isDefault(v) then
		syncFirstTxtIdx(idx:userProp('PgStyle'))
		v = firstTxtIdx:userProp('PgCtrl')
	end

	return v == 'Once'
end

local XLocMirror = {Left='Right',Right='Left'}
local noMirrorTags = {['No Mirroring']=1,['Once']=1}
local txtML = {}

local function doTextDraw(idx,pgstyle)
	local _
	local txt = idx:userProp('Text')
	local fnt = idx:userProp('Fnt')
	local fntsz = idx:userProp('FntSz')
	local spoth,spotv = idx:userProp('XLoc'), idx:userProp('YLoc')
	local cx,cy = idx:userProp('CX'),idx:userProp('CY')
	local x,y = 0,0

	if idx.isHidden then
		if idx:isHidden() then return end
	else
		-- we cannot totally implement Visibility, but we can respect a Never setting
		if idx:userProp('Visibility') == 'Never' then return end
	end

	syncFirstTxtIdx(pgstyle)
	--
	local pgctrl = getTxtPropVal(idx,'PgCtrl','All')

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

	local isEvenPageNum = (nwcdraw.getPageCounter() % 2) == 0
	local oddEvenCtrl = pgctrl:match('^(%w+) Pages$')
	if oddEvenCtrl then
		if oddEvenCtrl == 'Odd' then
			if isEvenPageNum then return end
		elseif not isEvenPageNum then
			return
		end
	end

	if (not noMirrorTags[pgctrl]) and nwcdraw.getPageMargin('Mirror') and XLocMirror[spoth] and isEvenPageNum then
		spoth = XLocMirror[spoth]
	end

	local balign = getTxtPropVal(idx,'BAlign',spoth)

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

	nwcdraw.setFontClass(fnt)

	if math.abs(fntsz - 1.0) > 0.01 then
		nwcdraw.setFontSize(nwcdraw.getFontSize()*fntsz)
	end

	txt = txt:gsub('(%%[^%% ]*%%)',doTextSubstitution)

	-- clear out old txtML lines
	while #txtML > 0 do table.remove(txtML) end

	-- build a table of txt lines
	for line in txt:gmatch('([^\n]+)') do table.insert(txtML,line)	end

	local i1,i2,iStep,lh = 1,#txtML,1,0
	if i2 > 1 then
		_,lh = nwcdraw.calcTextSize('W')
		if spotv == 'Bottom' then
			i1,i2,iStep,lh = i2,i1,-1,-lh
		end

		if balign ~= spoth then
			local lw = 0
			for i = i1,i2,iStep do
				local w = nwcdraw.calcTextSize(txtML[i])
				lw = math.max(w,lw)
			end

			if balign == 'Left' then
				x = x - ((spoth == 'Right') and lw or lw/2)
			elseif balign == 'Center' then
				x = x + ((spoth == 'Right') and -lw/2 or lw/2)
			else
				x = x + ((spoth == 'Left') and lw or lw/2)
			end
		end
	else
		-- block alignment has no effect here
		balign = spoth
	end

	nwcdraw.alignText(spotv,balign)

	for i = i1,i2,iStep do
		nwcdraw.moveTo(x,y)
		nwcdraw.text(txtML[i])
		y = y - lh
	end
end

local function obj_draw(t)
	local w = nwc.toolbox.drawStaffSigLabel(userObjSigName)
	if (not nwcdraw.isDrawing()) or (w > 0) then return w end

	if nwcdraw.getTarget() ~= 'print' then return end

	local isTopSystem = (nwcdraw.getSystemCounter() == 1)
	local handledSpots = isTopSystem and {} or false

	pg_l,pg_t,pg_r,pg_b = nwcdraw.getPageRect()

	-- handle any Once text
	while drawidx:find('next','user') do
		local uobjType = drawidx:userType()
		if uobjType == userObjTypeName then break end
		if uobjType == textObjectType then 
			local pgstyle = drawidx:userProp('PgStyle')
			
			if isOnceText(drawidx) then
				if isTopSystem then
					-- Once text can be placed into the top system that replaces prior text in the same PgStyle
					handledSpots[pgstyle] = 1
				end

				--if not drawidx:isHidden() then
					doTextDraw(drawidx,pgstyle)
				--end
			end
		end
	end
		
	if not isTopSystem then return end

	drawidx:reset()
	if not drawidx:find('next','noteOrRest') then return end

	ntnidx:find(drawidx)

	while ntnidx:find('prior','user',textObjectType) do
		local pgstyle = ntnidx:userProp('PgStyle')

		if not handledSpots[pgstyle] then
			syncFirstTxtIdx(pgstyle)

			handledSpots[pgstyle] = 1

			if not isOnceText(ntnidx) then
				doTextDraw(ntnidx,pgstyle)
			end
		end
	end
end

------------------------------------------------------------------------------

return {
	create		= obj_create,
	draw		= obj_draw,
	width		= obj_draw,
	}
