-- Version 0.15

--[[----------------------------------------------------------------
Melismatic.nw

This will detect melismas in a staff and automatically draw an extender line that spans the notes contained within the melisma.
Only a single Melismatic.nw object is required. Simply add it to the start of any staff with lyrics, and the rest is automatic.

You can turn off Melismatic.nw at any point in a staff by adding a Melismatic.nw object, then assigning its Visibility to Never.

This object was inspired by the original work of Rick G on his rg_LyrEx object. The Melimatic object would not have been
possible without his original effort.
--]]----------------------------------------------------------------

-- extender lines will always be at least this long
local MIN_EXTENDER_WIDTH = 0.6

------------------------------------------------------

local function iterateMethod(o,f,i) return function() i=(i or 0)+1 return o[f](o,i) end end
local function iterateMethod2(o,f,i2,i)	return function() i=(i or 0)+1 return o[f](o,i,i2) end end

------------------------------------------------------

local function shouldExtendLyric(lt,sep)
	return (sep ~= "-") and (string.len(lt) > 0) and (lt ~= " ")
end

local function findLyricPos(o,dir)
	dir = dir or "next"
	while o:find(dir,"noteOrRest") do
		if o:isLyricPos() then return true end
	end

	return false
end

local function findMelisma(o,dir)
	dir = dir or "next"
	while o:find(dir,"noteOrRest") do
		if o:isMelisma() then return true end
	end

	return false
end

local killerObjSet = {Rest=1,RestMultiBar=1}
local function isMelKiller(o)
	local t = o:objType()

	if killerObjSet[t] or o:isLyricPos() then return true end

	if t == "User" then
		if o:userType() == "Melismatic.nw" then return true end
	end

	return false
end

local function findMelKiller(o,dir)
	dir = dir or "next"
	while o:find(dir) do
		if isMelKiller(o) then return true end
	end

	return false
end

local function getExtenderDestinationX(pos1,pos2,idx)
	local xSlurTie = nil

	pos2:find(pos1)

	if not findMelKiller(pos2,"next") then pos2:find("last") end

	idx:find(pos2)
	idx:find("prior","note")
	if idx:isTieOut() or idx:isSlurOut() then
		xSlurTie = pos2:xyAnchor()-.3
	end

	pos2:find(idx)
	local x = pos2:xyRight()

	if xSlurTie then x = math.max(x,xSlurTie) end

	return x
end

local showInTargets = {edit=1,selector=1}

local function doPrintName(showAs)
	nwcdraw.setFont('Arial',3,"b")

	local xyar = nwcdraw.getAspectRatio()
	local w,h = nwcdraw.calcTextSize(showAs)
	local w_adj,h_adj = h/xyar,(w*xyar)+2
	if not nwcdraw.isDrawing() then return w_adj end

	nwcdraw.alignText("bottom","left")
		
	nwcdraw.moveTo(0,0)
	nwcdraw.beginPath()
	nwcdraw.line(0,h_adj)
	nwcdraw.line(-w_adj,h_adj)
	nwcdraw.line(-w_adj,0)
	nwcdraw.line(0,0)
	nwcdraw.closeFigure()
	nwcdraw.endPath("fill")

	nwcdraw.moveTo(0,0.5)
	nwcdraw.setWhiteout()
	nwcdraw.text(showAs,90)
	nwcdraw.setWhiteout(false)
	return 0
end

------------------------------------------------------

-- we never apply Melismatic operations past another Melismatic instance
local nextMelismatic = nwc.drawpos.new()

-- we extend a melisma from drawpos to this item
local endingMelismaPos = nwc.drawpos.new()

-- we never extend a melisma through a rest position and such
local priorMelKiller = nwc.ntnidx.new()

-- keep the prior lyric position, which we set to start of staff if one does not exist
local priorLyricPos = nwc.ntnidx.new()

------------------------------------------------------

local function Melismatic_create(t)
	t.Class = 'StaffSig'
end

local function Melismatic_draw()
	local user = nwcdraw.user
	local drawpos = nwc.drawpos
	local idx = nwc.ntnidx
	local media = nwcdraw.getTarget()
	local w = 0;
	
	if showInTargets[media] then
		w = doPrintName("Melismatic")
	end

	if not nwcdraw.isDrawing() then return w end

	-- Melismatic can be disabled by turning off its visibility
	if user:isHidden() then return end

	-- we need at least one note to work with
	if not drawpos:find("next","note") then return end

	nwcdraw.setFontClass('StaffLyric')
	local w_ref,h_ref,desc_ref =  nwcdraw.calcTextSize("Wq")

	priorMelKiller:find(drawpos)
	if not findMelKiller(priorMelKiller,"prior") then priorMelKiller:find("first") end

	priorLyricPos:find(drawpos)
	if not findLyricPos(priorLyricPos,"prior") then priorLyricPos:find("first") end

	-- we never apply Melismatic operations past another Melismatic instance, so we need to check for one
	if not nextMelismatic:find("next","user",user:userType()) then nextMelismatic:find("last") end

	-- first, we need to check for a hanging melisma
	if user:isAutoInsert() and not isMelKiller(drawpos) and priorLyricPos:isMelisma() and (priorLyricPos:indexOffset() >= priorMelKiller:indexOffset())  then
		endingMelismaPos:find(drawpos)
		endingMelismaPos:find("prior")
		
		local x = endingMelismaPos:xyRight()
		local x2 = math.max(getExtenderDestinationX(drawpos,endingMelismaPos,idx),x+MIN_EXTENDER_WIDTH)
		local lyricRow = 0
		for lt,sep in iterateMethod2(drawpos,'lyricSyllable',-1) do
			lyricRow = lyricRow+1
			if shouldExtendLyric(lt,sep) then
				local _,ylyr = drawpos:xyLyric(lyricRow)
				ylyr = ylyr - (h_ref/2) + desc_ref
				nwcdraw.moveTo(x,ylyr)
				nwcdraw.line(x2,ylyr)
			end
		end
	end

	drawpos:reset()
	while findMelisma(drawpos) and (drawpos:indexOffset() < nextMelismatic:indexOffset()) do
		local xright = getExtenderDestinationX(drawpos,endingMelismaPos,idx)

		local lyricRow = 0
		for lt,sep in iterateMethod(drawpos,'lyricSyllable') do
			lyricRow = lyricRow+1
			if shouldExtendLyric(lt,sep) then
				local xlyr,ylyr,align = drawpos:xyLyric(lyricRow)
				local w,h,d = nwcdraw.calcTextSize(lt)
				
				if align == "Center" then w = w/2 end

				xlyr = xlyr + w + .2
				ylyr = ylyr - (h_ref/2) + desc_ref

				nwcdraw.moveTo(xlyr,ylyr)
				nwcdraw.line(math.max(xright,xlyr+MIN_EXTENDER_WIDTH),ylyr)
			end
		end
	end
end

return {
	create = Melismatic_create,
	width = Melismatic_draw,
	draw = Melismatic_draw
	}
