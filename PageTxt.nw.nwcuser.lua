-- Version 0.1

--[[--------------------------------------------------------------------------
PageTxt.nw is ued to pass printed page text to the PageTxtMaestro.nw object.

@Text
This is the text that should be shown.
@PgLoc
This is the location where the text should be shown on the printed page.
@CX
This controls the horizontal offset for the text.
@CY
This controls the vertical offset for the text.

--]]--------------------------------------------------------------------------

-- our object type is passed into the script
local userObjTypeName = ...
local userObjSigName = nwc.toolbox.genSigName(userObjTypeName)

local maestroObjectType = 'PageTxtMaestro.nw'
local pageTxtPositionList = {'top-left', 'top-center', 'top-right','bottom-left', 'bottom-center', 'bottom-right'}

------------------------------------------------------------------------------
local obj_spec = {
	{id='Text',label='Text',type='text',default=''},
	{id='Fnt', label='Display Font', type='enum', default='PageText', list=nwc.txt.TextExpressionFonts },
	{id='PgLoc', label='Location on Page', type='enum', default=pageTxtPositionList[1], list=pageTxtPositionList },
	{id='CX', label='X Offset', type='float', default=0, min=-100, max=100, step=.5 },
	{id='CY', label='Y Offset', type='float', default=0, min=-100, max=100, step=.5 },
}

------------------------------------------------------------------------------
local function obj_create(t)
	if not nwc.ntnidx:find('first','user',maestroObjectType) then
		nwcui.msgbox('You should add a PageTxtMaestro.nw object before using this')
	end
end

------------------------------------------------------------------------------
local function obj_draw(t)
	return nwc.toolbox.drawStaffSigLabel('pgtxt: '..t.PgLoc)
end

------------------------------------------------------------------------------

return {
	spec		= obj_spec,
	create		= obj_create,
	draw		= obj_draw,
	width		= obj_draw,
	}
