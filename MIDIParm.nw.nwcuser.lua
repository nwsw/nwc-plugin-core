-- Version 0.31

--[[-----------------------------------------------------------------------------------------
MIDIParm.nw

This object allows you to send MIDI RPN and NRPN changes. If you do not want these to show
when printing, then you will need to hide the object. You can change the text that is 
displayed for the object by adding a ShowAs property.

--]]-----------------------------------------------------------------------------------------

-- our object type is passed into the script
local userObjTypeName = ...

-- use a single table instance to quickly create our display string
local stringTable = {}

-- save the last user selection as the default for next time
local lastSelType = 'RPN'

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

	if DataMSB then
		st[6] = ':'
		st[7] = DataMSB

		if DataLSB then
			st[8] = ','
			st[9] = DataLSB
		end
	end

	return table.concat(st)
end

---------------------------------------------------------------------------------------------
-- the 'spec' table is used to filter the object properties as they are returned from 't'
local obj_spec = {
	ShowAs	= {type='text',default=''},
	Type	= {type='enum',default='RPN',list={'RPN','NRPN'}},
	MSB		= {type='int',default=0,min=0,max=127},
	LSB		= {type='int',default=0,min=0,max=127},
	DataMSB	= {type='int',default=false,min=0,max=127},
	DataLSB	= {type='int',default=false,min=0,max=127},
	}

---------------------------------------------------------------------------------------------
-- the 'create' method is used to establish the object properties that will
-- control our plugin object
local function do_create(t)
	local typ = nwcui.prompt('Paramater Control Type','|RPN|NRPN|Expression',lastSelType)
	if not typ then return end

	lastSelType = typ

	if typ == 'Expression' then
		local ShowAs,ProgramNumber,DataNumber

		repeat
			local x = nwcui.prompt('Paramater specification','*','Description = NRPN #, #')
			if not x then return end
			ShowAs,typ,ProgramNumber,DataNumber = string.match(x,'([^=]+)=%s*([NPR]+)%s+(%d+)[,]*%s*(%d*)')
		until typ

		ProgramNumber = tonumber(ProgramNumber) or 0

		t.ShowAs = ShowAs:match('^%s*(.-)%s*$')
		t.Type = typ
		t.MSB = math.floor(ProgramNumber / 128)
		t.LSB = ProgramNumber % 128

		if DataNumber then
			DataNumber = tonumber(DataNumber) or 0
			t.DataMSB = math.floor(DataNumber / 128)
			t.DataLSB = DataNumber % 128
		end

		return
	end

	t.Type = typ
	t.MSB = 127
	t.LSB = 127
	t.DataMSB = 0
	t.DataLSB = 0
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
	-- we simply reassign all properties that maintain a valid default value
	for k,v in pairs(obj_spec) do
		if v.default and (k ~= 'ShowAs') then
			t[k] = t[k]
		end
	end
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

	if DataMSB then
		nwcplay.midi(0,'controller',6,DataMSB) 
		if DataLSB then
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
