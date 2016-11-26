-- Version 0.21

assert((nwc.VERSIONDATE or '00000000') > '20161120','This plugin requires version 2.75a')

--[[-----------------------------------------------------------------------------------------
LineSpan.nw	<http://nwsw.net/-f9467>

This object can be used to add special lines that span across a selection of notes.
An optional text instruction can accompany the line.

Caveat: If overlapping line spans are created, then you lose the ability to define
individual color and visibility for the longer line spans.

@Span
This sets the number of notes that will encompass the line span. You can use a fractional
value to extend the line beyond the target note.
@Pen
This sets the pen style for the line.
@PenW
This sets the thickness for the line.
@Cap1
This is the cap that will be placed on the start of the line.
@Cap2
This is the end cap that will be placed at the conclusion of the line span.
@Text
Optional text that will be included with the line.
@Overlap
Set by the Refresh Audit, this indicates that the object is preceded by an overlapping line span.
This assists the object plugin with efficiently handling line spans across multiple systems. This
option does not require any user input, as it is set automatically, as needed.

--]]-----------------------------------------------------------------------------------------

local noteobjTypes = {Note=1,Rest=1,Chord=1,RestChord=1,RestMultiBar=1}
local endPointStyles = {'none','stroke','arrow'}

if nwcut then
	local userObjTypeName = arg[1]
	local score = nwcut.loadFile()
	local span = 0
	local function CalculateSpan(o)
		if not o:IsFake() and noteobjTypes[o.ObjType] then
			span = span + 1
		end
	end
	local function AddLineSpan(o)
		if span and not o:IsFake() then
			local o2 = nwcItem.new('|User|'..userObjTypeName)
			o2.Opts.Class = 'StaffSig'
			o2.Opts.Pos = 9
			o2.Opts.Span = span
			o2.Opts.Text = nwcut.prompt('Text Instruction','*','')
			span = false
			return {o2,o}
		end
	end

	score:forSelection(CalculateSpan)
	if span > 0 then
		span = span+0.5
		nwcut.msgbox(('Span: %g'):format(span))
		score:forSelection(AddLineSpan)
		score:save()
	else
		nwcut.status = nwcut.const.rc_Error
		nwcut.warn(('This is not a valid span for %s'):format(userObjTypeName))
	end

	return
end

--------------------------------------------------------------------
	
local userObjTypeName = ...

local textFontList = nwc.txt.TextExpressionFonts

local obj_spec = {
	{id='Span',label='Note &Span',type='float',default=4.5,min=1,max=2048,step=0.5},
	{id='Pen',label='&Line Type',type='enum',default=nwc.txt.DrawPenStyle[1], list=nwc.txt.DrawPenStyle},
	{id='PenW',label='T&hickness',type='float',default=1,min=0.1,max=4,step=0.1},
	{id='Cap1',label='&Front Cap',type='enum',default=endPointStyles[1],list=endPointStyles},
	{id='Cap2',label='&End Cap',type='enum',default=endPointStyles[2],list=endPointStyles},
	{id='Text',label='&Text Instruction',type='text',default=''},
	{id='Font',label='&Font',type='enum',default='StaffItalic',list=textFontList},
	{id='Scale',label='&Scale',type='int',default=100,min=5,max=400,step=5},
	{id='Overlap',label='Overlap (Read-only)'},
}	

local barobjTypes = {Bar=1,RestMultiBar=1}
local draw,usr,idx = nwcdraw,nwcdraw.user,nwc.ntnidx
local note1 = usr.new()
local note2 = usr.new()

local function insideMMR(dpos)
	return (dpos:objType() == 'RestMultiBar') and ((dpos:barCounter()+1) < tonumber(dpos:objProp('NumBars')))
end

local function do_create(t)
	t.Class = 'StaffSig'
end

--[[--
The audit performs two automatic tasks:

1.	It sets the object Class to StaffSig if the line spans across a bar. This
	allows the line to span through multiple printed systems.
	
2.	It looks back for any overlapping LineSpan objects. If an overlap is found,
	then indicate this in the object's Overlap flag.
--]]--
local function do_audit(t)
	local nc = 0
	local myspan = math.floor(t.Span)
	
	t.Class = 'Standard'
	idx:reset()
	while (nc < myspan) and idx:find('next') do
		local objt = idx:objType()
		if barobjTypes[objt] then
			-- this line spans a bar
			t.Class = 'StaffSig'
			break
		elseif noteobjTypes[objt] then
			nc = nc + 1
		end
	end
	
	t.Overlap = nil
	
	idx:reset()
	while idx:find('prior') do
		if noteobjTypes[idx:objType()] then
			nc = nc + 1
		elseif (idx:userType() == userObjTypeName) then
			if nc <= math.floor(idx:userProp('Span')) then
				t.Overlap = true
				break
			end
			
			if not idx:userProp('Overlap') then
				-- since audits are done from left to right, we don't need to go any further
				break
			end
		end
	end
	
end
	
local function do_spin(t,dir)
	t.Span = t.Span + dir*0.5
	do_audit(t)
end

local function draw_cap(x,y,cap,front,up)
	if cap == 'stroke' then
		draw.line(x,y,x,y+(up and 2 or -2))
	elseif cap == 'arrow' then
		local x2 = x + (front and 1 or -1)
		draw.line(x2,y-1,x,y)
		draw.line(x2,y+1,x,y)
	end
end
	
local function draw_span(obj,drawpos,nc)
	local _,penh = nwcdraw.getMicrons(1,obj:userProp('PenW')*0.2)
	local x = drawpos:xyAnchor()
	local staffpos = obj:staffPos()
	local y = staffpos - usr:staffPos()
	local atFront = (nc < 1)
	local rawspan = obj:userProp('Span')
	local span = math.floor(rawspan)
	local spanOffset = rawspan - span
	local txt = obj:userProp('Text')
	local cap1,cap2 = obj:userProp('Cap1'),obj:userProp('Cap2')
	
	if cap1 == 'none' then cap1 = false end
	if cap2 == 'none' then cap2 = false end
	
	note2:find(drawpos)
	while (nc < span) and note2:find('next','objType','Note','Rest','Chord','RestChord','RestMultiBar') do
		if not insideMMR(note2) then nc = nc + 1 end
	end
	
	local x2 = note2:xyStemAnchor() or (note2:xyAlignAnchor()+1)
	local atEnd = (nc == span)
	
	if (nc < span) and (note2:find('next','bar') or note2:find('last')) then
		x2 = note2:xyAlignAnchor()
	elseif (nc == span) and (note2:find('next','objType','Bar','Note','Rest','Chord','RestChord','RestMultiBar')) then
		local x2a = note2:xyAnchor()
		x2 = x2 + spanOffset*(x2a - x2)
	end
	
	draw.setPen(obj:userProp('Pen'), penh)
	
	if atFront and (#txt > 0) then
		local pl = obj:userProp('TextPos')
		
		draw.alignText('middle','left')
		draw.setFontClass(obj:userProp('Font'))
		draw.setFontSize(draw.getFontSize()*obj:userProp('Scale')/100)
		draw.moveTo(x,y)
		draw.text(txt)
		x = x + draw.calcTextSize(txt) + draw.calcTextSize(' ')
	end
	
	if x >= x2 then
		-- no room for a line
		return
	end
	
	if atFront and cap1 then
		draw_cap(x,y,cap1,true,staffpos<0)
	end
	
	if cap2 then
		draw.line(x2,y,x,y)
	else
		draw.line(x,y,x2,y)
	end
	
	if atEnd and cap2 then
		draw_cap(x2,y,cap2,false,staffpos<0)
	end
end

local function do_draw(t)
	if not note1:find('first','objType','Note','Rest','Chord','RestChord','RestMultiBar') then return end
	
	if draw.isAutoInsert() then
		-- look back for spans that extend into current system
		local nc = insideMMR(note1) and 0 or 1
		idx:find(note1)
		while idx:find('prior') do
			if noteobjTypes[idx:objType()] then
				nc = nc + 1
			elseif (idx:userType() == userObjTypeName) then
				if nc <= math.floor(idx:userProp('Span')) then
					draw_span(idx,note1,nc)
				end
				
				if not idx:userProp('Overlap') then
					-- we don't need to go any further
					break
				end
			end
		end
	else
		draw_span(usr,usr,0)
	end
end

return {
	nwcut	=	{['Add a line span'] = 'ClipText'},
	spec	=	obj_spec,
	create	=	do_create,
	audit	=	do_audit,
	spin	=	do_spin,
	draw	=	do_draw,
}
