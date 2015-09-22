-- Version 1.0

--[[-----------------------------------------------------------------------------------------
MIDIParm.nw <http://nwsw.net/-f9096>

This object plugin is used to send MIDI RPN and NRPN changes. If you do not want this to show
when printing, then you will need to hide the object.

@ShowAs
This can be used to change what is displayed on the staff.
@Type
This controls which type of parameter change will be sent during play back.
@MSB
This is the program number's MSB MIDI value.
@LSB
This is the program number's LSB MIDI value.
@DataMSB
This is the data value's MSB MIDI value. Set this to -1 to prevent any data value from being sent.
@DataLSB
This is the data value's LSB MIDI value. Set this to -1 to prevent any data LSB value from being sent.

--]]-----------------------------------------------------------------------------------------

-- our object type is passed into the script
local userObjTypeName = ...

-- use a single table instance to quickly create our display string
local stringTable = {}

local function getDisplayText(t)
	local ShowAs = t.ShowAs
	if ShowAs:len() > 0 then return ShowAs end

	-- for efficiency, use the same strTable every time
	local st = stringTable
	st[1] = t.Type
	st[2] = ':'
	st[3] = t.MSB
	st[4] = ','
	st[5] = t.LSB

	for i=6,9 do st[i] = nil end

	local DataMSB = t.DataMSB
	local DataLSB = t.DataLSB

	if DataMSB >= 0 then
		st[6] = ':'
		st[7] = DataMSB

		if DataLSB >= 0 then
			st[8] = ','
			st[9] = DataLSB
		end
	end

	return table.concat(st)
end

---------------------------------------------------------------------------------------------
-- the 'spec' table is used to filter the object properties as they are returned from 't'
local obj_spec = {
	{id='ShowAs',label='Show As',type='text',default=''},
	{id='Type',label='Type',type='enum',default='RPN',list={'RPN','NRPN'}},
	{id='MSB',label='MSB',type='int',default=0,min=0,max=127},
	{id='LSB',label='LSB',type='int',default=0,min=0,max=127},
	{id='DataMSB',label='Data MSB',type='int',default=-1,min=-1,max=127},
	{id='DataLSB',label='Data LSB',type='int',default=-1,min=-1,max=127},
	}

---------------------------------------------------------------------------------------------
-- the 'create' method is used to establish the object properties that will
-- control our plugin object
local function do_create(t)
	if nwc.ntnidx:find('prior','user',userObjTypeName) then
		for _,v in ipairs(obj_spec) do
			t[v.id] = nwc.ntnidx:userProp(v.id)
		end
	end
end

---------------------------------------------------------------------------------------------
-- the 'spin' method is called whenever the user applied the +/- keys to our 
-- object from within the editor
local function do_spin(t,d)
	local DataMSB = t.DataMSB
	if DataMSB then
		t.DataMSB = DataMSB + d
	end
end

---------------------------------------------------------------------------------------------
-- the 'audit' method is called whenever a file is first opened, or when the user performs
-- a View, Refresh Score from within the editor
local function do_audit(t)
end

---------------------------------------------------------------------------------------------
-- the 'play' method is called whenever our notatation is compiled into a
-- midi performance
local function do_play(t)
	local Type = t.Type
	local MSB = t.MSB
	local LSB = t.LSB
	local DataMSB = t.DataMSB
	local DataLSB = t.DataLSB

	local c1,c2 = 101,100
	if Type == 'NRPN' then c1,c2 = 99,98 end

	nwcplay.midi(0,'controller',c1,MSB)
	nwcplay.midi(0,'controller',c2,LSB)

	if DataMSB >= 0 then
		nwcplay.midi(0,'controller',6,DataMSB) 
		if DataLSB >= 0 then
			nwcplay.midi(0,'controller',38,DataLSB)
		end
	end
end

---------------------------------------------------------------------------------------------
-- the 'width' and 'draw' methods are combined here, and are used in the
-- formatting and display of our object on the NWC staff
--
local function do_draw(t)
	local txt = getDisplayText(t)

	nwcdraw.setFontClass('StaffBold')
	local w,h,descent = nwcdraw.calcTextSize(txt)
	w = w + nwcdraw.calcTextSize(' ')

	if not nwcdraw.isDrawing() then
		-- the user can always add spacers to control width and placement, but one
		-- is provided here for demonstration purposes...a dedicated width method
		-- could also be created for an object (it need not be done in 'draw')
		return w
	end

	nwcdraw.alignText("bottom","left")
	nwcdraw.moveTo(-nwcdraw.width())
	nwcdraw.text(txt)
end

---------------------------------------------------------------------------------------------

return {
	spec		= obj_spec,
	create		= do_create,
	spin		= do_spin,
	audit		= do_audit,
	play		= do_play,
	width		= do_draw,
	draw		= do_draw
	}
