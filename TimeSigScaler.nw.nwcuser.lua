-- Version 0.9

assert((nwc.VERSIONDATE or '00000000') >= '20161230','This plugin requires version 2.75a')

--[[-----------------------------------------------------------------------------------------
TimeSigScaler.nw	<http://nwsw.net/-f9533>

This object can be used to draw a scaled version of a prior, usually hidden, time signature.
This object should always be placed after the real time signature.

@Scale
This sets the scaling used in the synthesized replacement time signature.

--]]-----------------------------------------------------------------------------------------

if nwcut then
	local userObjTypeName = arg[1]
	local doAdd = false
	local removeExtras = -1
	local addObj = false
	local changes = 0
	
	nwcut.setlevel(0)
	nwcut.writeline(nwcut.getprop('StartingLine'))

	for item in nwcut.items() do
		local t1 = nwcut.objtyp(item)
		
		if t1 == 'User' then
			local t2 = item:match('^|User|([^|]+)')
			if t2 == userObjTypeName then
				addObj = item
	
				if doAdd then
					doAdd = false
				else
					if removeExtras < 0 then
						removeExtras = nwcut.askbox(('Should extra %s objects be removed?'):format(userObjTypeName))
					end
					
					if removeExtras == 1 then
						changes = changes+1
						item = false
					end
				end
			end
		end
		
		if item and doAdd then
			if not addObj then
				local scale = nwcut.prompt('Scaling factor','#[50,250]',150)
				addObj = ('|User|%s|Pos:0|Scale:%d'):format(userObjTypeName,scale)
			end
			
			changes = changes+1
			nwcut.writeline(addObj)
			doAdd = false
		end
		
		if t1 == 'TimeSig' then
			local tsObj = nwcItem.new(item,1)
			doAdd = true
			tsObj:Set('Visibility','Never')
			item = tostring(tsObj)
		end
		
		if item then 
			nwcut.writeline(item)
		end
	end
		
	nwcut.writeline(nwcut.getprop('EndingLine'))
	
	if changes < 1 then nwcut.warn('No changes\n') end
	
	return
end

local userObjTypeName = ...

local object_spec = {
{ id='Scale', label='Scale (%)', type='int', default=150, min=50, max=300, step=10 },
}

local function do_spin(t,d)
	t.Scale = t.Scale + d*10
end

local function drawUpDnArrow(x,y,h,w,t)
	nwcdraw.setPen('solid',t)
	nwcdraw.line(x-w/2,y-h/2,x-w/2,y+h/2)
	nwcdraw.moveTo(x-w,y-h/2+1)
	nwcdraw.lineBy(w/2,-1,w/2,1)
	nwcdraw.moveTo(x-w,y+h/2-1)
	nwcdraw.lineBy(w/2,1,w/2,-1)
end
	
local scanStopItems = {Note=1,Chord=1,RestChord=1,Rest=1,Bar=1,Clef=1,Key=1}
local spaceStopItems = {Spacer=1,RestMultiBar=1}
local function calcBoundarySpace(idx,dir,defaultSpace)
	idx:reset()
	while idx:find(dir) and not scanStopItems[idx:objType()] do
		if spaceStopItems[idx:objType()] then return 0 end
	end
	
	return defaultSpace or 0.5
end
	
local function do_draw(t)
	local idx = nwc.ntnidx
	
	if not idx:find('prior', 'TimeSig') then
		return nwc.toolbox.drawStaffSigLabel(UserObjTypeName)
	end
	
	local Scale = t.Scale*.01
	
	if (nwcdraw.getTarget() == 'edit') and (idx:indexOffset() == -1) then
		local afterW = calcBoundarySpace(idx,'next')
		if not nwcdraw.isDrawing() then return afterW+0.6 end
		drawUpDnArrow(-.1-afterW,0,3,0.5,500)
		return
	end
		
	local NextTimeSig_Prop = idx:objProp('Signature') or '4/4'
	local beforeW = calcBoundarySpace(idx,'prior',0.75)
	local afterW = calcBoundarySpace(idx,'next')
	
	nwcdraw.setFontClass('StaffSymbols')
	nwcdraw.setFontSize(nwcdraw.getFontSize()*Scale)

	local Beats,Value = NextTimeSig_Prop:match('(%d+)/(%d+)')

	if NextTimeSig_Prop == 'Common' then
		Beats,Value = 4,4
	elseif NextTimeSig_Prop == 'AllaBreve' then
		Beats,Value = 2,2
	else
		assert(Beats and Value,NextTimeSig_Prop)
	end

	local w1 = nwcdraw.calcTextSize(Beats)
	local w2 = nwcdraw.calcTextSize(Value)
	local w = math.max(w1,w2)
	if not nwcdraw.isDrawing() then return w + beforeW + afterW end
	
	local xmid = -w/2 - afterW
	
	nwcdraw.alignText('middle','center')
	nwcdraw.moveTo(xmid,4*Scale - 0.15)
	nwcdraw.text(Beats)
	nwcdraw.moveTo(xmid,-0.2*(Scale+1))
	nwcdraw.text(Value)
end

return {
	nwcut =	{['Override All Time Signatures'] = 'FileText'},
	spec = object_spec,
	spin = do_spin,
	width = do_draw,
	draw = do_draw,
}