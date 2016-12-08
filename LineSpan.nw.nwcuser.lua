-- Version 0.5

assert((nwc.VERSIONDATE or '00000000') >= '20161207','This plugin requires version 2.75a')

--[[-----------------------------------------------------------------------------------------
LineSpan.nw	<http://nwsw.net/-f9467>

This object can be used to add special lines that span across a selection of notes.
An optional text instruction can accompany the line.

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

--]]-----------------------------------------------------------------------------------------

local endPointStyles = {'none','stroke','arrow'}

if nwcut then
	local userObjTypeName = arg[1]
	local score = nwcut.loadFile()
	local span = 0
	local noteobjTypes = {Note=1,Rest=1,Chord=1,RestChord=1,RestMultiBar=1}
	local function CalculateSpan(o)
		if not o:IsFake() and noteobjTypes[o.ObjType] then
			span = span + 1
		end
	end
	local function AddLineSpan(o)
		if span and not o:IsFake() then
			local o2 = nwcItem.new('|User|'..userObjTypeName)
			o2.Opts.Class = 'Span'
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
local barobjTypes = {Bar=1,RestMultiBar=1}
local draw,drawpos,idx = nwcdraw,nwcdraw.user,nwc.ntnidx
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
}	

local function do_create(t)
	t.Class = 'Span'
end

local function do_span(t)
	return math.floor(t.Span)
end

--[[--
The audit sets the object Class to Span if the line crosses a bar. This
allows the line to span through multiple printed systems.
--]]--
local function do_audit(t)
	-- Overlap property is no longer needed
	t.Overlap = nil
	
	t.Class = 'Standard'
	
	idx:find('span',do_span(t))
	idx:find('prior','bar')
	if idx:indexOffset() > 0 then
		-- this line spans a bar
		t.Class = 'Span'
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
	
local function do_draw(t)
	local atSpanFront = not drawpos:isAutoInsert()
	local x,staffpos = 0,drawpos:staffPos()
	local rawspan = t.Span
	local span = math.floor(rawspan)
	local spanOffset = rawspan - span
	local txt = t.Text
	local cap1,cap2 = t.Cap1,t.Cap2
	local _,penh = draw.getMicrons(1,t.PenW*0.2)
	
	local atSpanEnd = drawpos:find('span',do_span(t))
	if not atSpanEnd then drawpos:find('last') end
	local x2 = drawpos:xyRight()
	
	if cap1 == 'none' then cap1 = false end
	if cap2 == 'none' then cap2 = false end
	
	if atSpanEnd and (spanOffset > 0) and (drawpos:find('next','noteRestBar')) then
		local x2a = drawpos:xyRight()
		if x2a > x2 then x2 = x2 + spanOffset*(x2a - x2) end
	end
	
	draw.setPen(t.Pen, penh)
	
	if atSpanFront and (#txt > 0) then
		local pl = t.TextPos
		
		draw.alignText('middle','left')
		draw.setFontClass(t.Font)
		draw.setFontSize(draw.getFontSize()*t.Scale/100)
		draw.text(txt)
		x = draw.calcTextSize(txt) + draw.calcTextSize(' ')
	end
	
	if x >= x2 then
		-- no room for a line
		return
	end
	
	if atSpanFront and cap1 then
		draw_cap(x,0,cap1,true,staffpos<0)
	end
	
	if cap2 then
		draw.line(x2,0,x,0)
	else
		draw.line(x,0,x2,0)
	end
	
	if atSpanEnd and cap2 then
		draw_cap(x2,0,cap2,false,staffpos<0)
	end
end


return {
	nwcut	=	{['Add a line span'] = 'ClipText'},
	spec	=	obj_spec,
	create	=	do_create,
	audit	=	do_audit,
	spin	=	do_spin,
	span	=	do_span,
	draw	=	do_draw,
}
