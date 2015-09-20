-- Version 0.6

--[[--------------------------------------------------------------------------
A PageTxtMaestro.nw object should always be added to the staff before adding
this object.

PageTxt.nw is used to set printed page text, whch is then rendered on the page
by the PageTxtMaestro.nw object. Your page text can access File and Staff Info
using any of the following variables:

%Title%
%Author%
%Lyricist%
%Copyright1%
%Copyright2%

%StaffName%
%StaffLabel%
%StaffLabelAbbr%
%StaffGroup%

%PageNum%
%PageNum,1%


@Text
This is the text that should be shown. You can also use these variables in your text:

%Title% %Author% %Lyricist% %Copyright1% %Copyright2% %StaffName% %StaffLabel%
%StaffLabelAbbr% %StaffGroup% %PageNum% %PageNum,1%

You can use %% to show an actual percent character in your text, avoiding the variable
substitution.

@PgStyle
This is the Page style for the given page text. Only one item of text will appear on a page
for each style that is defined.

@Fnt
This establishes the font that will be used to display the text. The first instance of any
given Page Style should establish the default font.
@FntSz
If the Fnt is specified (not set as <default>), this can be used to alter the size of the
text.

@XLoc
This sets the horizontal position for the text. The first instance of any
given Page Style establishes the default location for all text using the style.
@CX
This controls the horizontal offset for the text. This is ignored when XLoc is set to <default>.

@YLoc
This sets the vertical placement for the text. The first instance of any
given Page Style establishes the default location for all text using the style.
@CY
This controls the vertical offset for the text. This is ignored when YLoc is set to <default>.

@PgCtrl
This can be used to control when the text shows in the printed page. For example, the text can
be limited to even or odd pages, or the mirror pargins mechanism can be disabled.

--]]--------------------------------------------------------------------------

-- our object type is passed into the script
local userObjTypeName = ...
local userObjSigName = nwc.toolbox.genSigName(userObjTypeName)

local maestroObjectType = 'PageTxtMaestro.nw'

local defaultString = '<default>'

local FntTypeList = {defaultString}
for _,fnttyp in ipairs(nwc.txt.TextExpressionFonts) do
	table.insert(FntTypeList,fnttyp)
end

local XPositionList = {defaultString, 'Left', 'Center', 'Right'}
local YPositionList = {defaultString, 'Top', 'Bottom'}
local PgCtrlList = {defaultString, 'All', 'Even Pages', 'Odd Pages', 'No Mirroring'}

------------------------------------------------------------------------------
local obj_spec = {
	{id='Text',label='Text',type='text',default=''},
	{id='PgStyle',label='Page &Style',type='text',default=''},
	{id='Fnt', label='Display Font', type='enum', default=FntTypeList[1], list=FntTypeList },
	{id='FntSz', label='Font Si&ze', type='float', default=1, min=0.1, max=100,step=0.1 },
	{id='XLoc', label='X Page Location', type='enum', default=XPositionList[1], list=XPositionList },
	{id='CX', label='X Offset', type='float', default=0, min=-100, max=100, step=.5 },
	{id='YLoc', label='Y Page Location', type='enum', default=YPositionList[1], list=YPositionList },
	{id='CY', label='Y Offset', type='float', default=0, min=-100, max=100, step=.5 },
	{id='PgCtrl', label='Page &Display Control', type='enum', default=defaultString, list=PgCtrlList },
}

------------------------------------------------------------------------------
--
local function obj_audit(t)
	t.Text = string.gsub(t.Text,'%%PageNum%w+','%%PageNum')

	if not nwc.isset(t,'PgStyle') then
		-- top-left, top-center, top-right, bottom-left, bottom-center, bottom-right
		local oldPgLoc = t.PgLoc or string.format('%s-%s',nwc.rawget(t,'YLoc') or 'top',nwc.rawget(t,'XLoc') or 'left')
		local ypos,xpos = oldPgLoc:match('^(%w+)-(%w+)$')
		if ypos and xpos then
			xpos = xpos:gsub("^%l", string.upper)
			ypos = ypos:gsub("^%l", string.upper)
			t.XLoc = xpos
			t.YLoc = ypos
			t.PgStyle = string.format("%s%s",ypos,xpos)

			t.PgLoc = nil
		end
	end
end

------------------------------------------------------------------------------
local function obj_create(t)
	if not nwc.ntnidx:find('first','user',maestroObjectType) then
		nwcui.msgbox('You should add a PageTxtMaestro.nw object first')
		return false
	end

	local userSelPgStyle = '<new>'
	--
	local pgStyles = {}
	local pgStyleList = {}
	local idx = nwc.ntnidx
	if idx:find('first','user',userObjTypeName,'PgStyle') then
		repeat
			local pgstyle = idx:userProp('PgStyle')
			if not pgStyles[pgstyle] then
				pgStyles[pgstyle] = 1
				table.insert(pgStyleList,pgstyle)
			end
		until not idx:find('next','user',userObjTypeName,'PgStyle')
	end

	if pgStyleList[1] then
		table.sort(pgStyleList)
		table.insert(pgStyleList,1,'<new>')
		
		userSelPgStyle = nwcui.prompt('Select a Page Style',string.format('|%s',table.concat(pgStyleList,'|')),pgStyleList[1])
		if not userSelPgStyle then return end
	end

	if userSelPgStyle == '<new>' then
		userSelPgStyle = nwcui.prompt('Enter a New Page Style','*')
		if not userSelPgStyle then return end
	end

	t.PgStyle = userSelPgStyle
	idx:reset()
	while idx:find('prior','user',userObjTypeName,'PgStyle') do
		if idx:userProp('PgStyle') == userSelPgStyle then
			t.Text = idx:userProp('Text')
			return
		end
	end

	-- this is currently the first of this style in the staff
	t.Fnt = 'PageText'
	t.XLoc = 'Left'
	t.YLoc = 'Top'
end

------------------------------------------------------------------------------
local function obj_draw(t)
	return nwc.toolbox.drawStaffSigLabel('PgTxt: '..t.PgStyle)
end

------------------------------------------------------------------------------

return {
	spec		= obj_spec,
	audit		= obj_audit,
	create		= obj_create,
	draw		= obj_draw,
	width		= obj_draw,
	}
