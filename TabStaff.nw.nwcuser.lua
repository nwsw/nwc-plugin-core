-- Version 1.2

--[[--------------------------------------------------------------------------
TabStaff is used to add a guitar tab staff to your NWC file. You can add this
object into the current staff, or create a new staff that has no staff lines.
This object will take care of drawing the guitar strings that comprise the
guitar tablature.

A user tool in the .Plugins group can also be used to create a TabStaff system
in the current staff.

@Strings
This establishes the number of strings in the tab staff.

@Size
This establishes the height of tab staff. Specifically, it sets the gap height
between each guitar string.

@Opaque
When enabled, the fret numbers drawn by TabFret.nw objects will be opaque in
the TabStaff.

--]]--------------------------------------------------------------------------

if nwcut then
	--[[-------------------------------------------------------------------------
	This NWC user tool can be used to construct a tablature staff from an 
	existing staff of notation. The current implementation silently ignores
	any errors that might occur, such as pitch being too low, or too many
	notes in a chord.
	--]]-------------------------------------------------------------------------

	-- This is the user tool entry point
	local userObjTypeName = arg[1]

	local score = nwcut.loadFile()

	local notenameShift = {['Cb']=-1,['C']=0,['C#']=1,['Db']=1,['D']=2,['D#']=3,['Eb']=3,['E']=4,['E#']=5,['Fb']=4,['F']=5,['F#']=6,['Gb']=6,['G']=7,['G#']=8,['Ab']=8,['A']=9,['A#']=10,['Bb']=10,['B']=11,['B#']=12}

	local function midiPitch(s)
		local name,octave = s:match('^([A-G][b#]?)([%d]+)$')
		return 60 + (notenameShift[name] or 0) + (((octave or 4) - 4)*12)
	end

	local function midiPitchList(mpl)
		local a = {}
		for s in mpl:gmatch('[^%s,]+') do table.insert(a,1,midiPitch(s)) end
		return a
	end

	local Tunings = {
		guitar		= 'E2 A2 D3 G3 B3 E4',
		bass		= 'E1 A1 D2 G2',
		mandolin	= 'G3 D4 A4 E5',
		['ukulele (baritone)'] = 'D3 G3 B3 E4',
		['ukulele (soprano)'] = 'G3 C4 E4 A4',
	}

	local iTuning = nwcut.prompt('Enter a tuning type', '|guitar|bass|mandolin|ukulele (baritone)|ukulele (soprano)')
	local iStrings = midiPitchList(Tunings[iTuning])

	local staff = score:getSelection()

	local playContext = nwcPlayContext.new()
	local objTabStaff = false
	local objTabFret = false
	local addList = {}

	for itemindex,item in ipairs(staff.Items) do
		if item:GetUserType() == 'TabStaff.nw' then
			objTabStaff = item
		elseif item:GetUserType() == 'TabFret.nw' then
			objTabFret = item
		elseif item:ContainsNotes() then
			if not objTabStaff then
				-- we have encountered a note without finding a TabStaff signature

				-- set the staff boundary to make space for a TabStaff
				local boundary = staff.StaffProperties:GetNum('BoundaryBottom') or 12
				boundary = boundary + 8 + 3*(#iStrings-1)
				staff.StaffProperties.Opts.BoundaryBottom = boundary

				-- we create a new TabStaff and add it into our addList
				objTabStaff = nwcItem.new(string.format('|User|TabStaff.nw|Pos:%g|Strings:%d|Class:StaffSig',-(boundary-3),#iStrings))
				table.insert(addList,{1,objTabStaff})
			end
			
			if not objTabFret then
				objTabFret = nwcItem.new(string.format('|User|TabFret.nw|Pos:%g',objTabStaff:GetNum('Pos')))
				table.insert(addList,{itemindex,objTabFret})

				local noteposTopDown = {}
				for notepos in item:AllNotePositions() do
					table.insert(noteposTopDown,1,notepos)
				end

				local stringnum = 0
				for _,notepos in ipairs(noteposTopDown) do
					local midipitch = playContext:GetNoteMidiPitch(notepos)
					local tiedIn = playContext:FindTieIndex(notepos) and '^' or ''
					local tiedOut = notepos.Tied and '^' or ''

					stringnum = stringnum + 1
					if stringnum > #iStrings then break end

					while (stringnum < #iStrings) and (midipitch < iStrings[stringnum]) do
						stringnum = stringnum + 1
					end

					if (midipitch < iStrings[stringnum]) then break end

					local stringName = 'S'..stringnum
					objTabFret.Opts[stringName] = string.format('%s%d%s',tiedIn,midipitch-iStrings[stringnum],tiedOut)
				end
			end

			-- reset for the next note
			objTabFret = nil
		end

		playContext:put(item)
	end

	-- now add the additional objects into the staff item list
	local count = 0
	for _,data in ipairs(addList) do
		table.insert(staff.Items,data[1]+count,data[2])
		count = count + 1
	end

	if count > 0 then
		score:save()
	else
		nwcut.status = nwcut.const.rc_Report
		print("No changes were made to the file")
	end

	return
end

------------------------------------------------------------------------------

-- our object type is passed into the script
local userObjTypeName = ...

-- things work best when all fields supported by the plugin are published in a
-- spec table
local obj_spec = {
	{ id='Strings', label='Number of Strings', type='int', min=1, max=6, step=1, default=6 },
	{ id='Size', label='Tablature Size', type='float', min=.3, max=4.0, step=0.1, default=1 },
	{ id='Opaque', label='Opaque Mode', type='bool', default=true },
}

------------------------------------------------------------------------------
--
local function obj_create(t)
	t.Class = 'StaffSig'
end

------------------------------------------------------------------------------
--
local function obj_audit(t)
end

------------------------------------------------------------------------------
--
local function obj_spin(t,d)
	t.Size = t.Size + 0.1*d
end

------------------------------------------------------------------------------
--
local function obj_transpose(t,semitones,notepos,updpatch)
end

------------------------------------------------------------------------------
--
local function obj_play(t)
end

------------------------------------------------------------------------------
--
local TAB = {'T','A','B'}
local drawidx1 = nwc.drawpos
local drawidx2 = nwc.drawpos.new()
--
local function obj_draw(t)
	local numStrings = t.Strings
	local h = t.Size*3
	local total_h = h*(numStrings-1)
	local center_h = total_h/2
	local c = nwcdraw

	-- only the first tabStaff in a system is used
	if drawidx1:find('prior','user',userObjTypeName) then return end

	drawidx1:find('first')
	drawidx2:find('last')

	local x1,y1 = drawidx1:xyAnchor()
	local x2,y2 = drawidx2:xyAnchor()
	for i=1,numStrings do
		y1 = h*(i-1)
		c.moveTo(x1,y1)
		c.line(x2,y1)
	end

	c.setFontClass('StaffSymbols')
	local dotWidth = c.calcTextSize('J')
	local barHalfH = math.max(center_h,h/2)
	--
	drawidx1:find('first','bar')
	repeat
		local barstyle = drawidx1:objProp('Style')
		x1 = drawidx1:xyAnchor()
		c.moveTo(x1)
		local barw = c.barSegment(barstyle,center_h+barHalfH,center_h-barHalfH)
		local drawRepeat = false

		if barstyle:match('RepeatClose') then
			drawRepeat = x1 + dotWidth
		elseif barstyle:match('RepeatOpen') then
			drawRepeat = x1+barw
		end

		if drawRepeat then
			local cgap = (numStrings < 3) and (barHalfH/2) or (((numStrings % 2) < 0.5) and h or h/2)

			for dotpos=-1,1,2 do
				c.moveTo(drawRepeat-dotWidth/2,center_h + dotpos*cgap)
				c.beginPath()
					c.ellipse(dotWidth/2)
				c.endPath()
			end
		end
	until not drawidx1:find('next','bar')

	if drawidx1:find('first','clef') then
		local tabtxt_h = math.min(5*h,math.max(3*h,total_h))
		local letterh = tabtxt_h/3
		x1 = drawidx1:xyAnchor()
		c.setFont('Times',-(1.1*letterh),'b')
		c.alignText('middle','left')
		local centerh = total_h/2
		for i,letter in ipairs(TAB) do
			c.moveTo(x1,centerh + (2-i)*letterh)
			c.text(letter)
		end
	end
end

------------------------------------------------------------------------------
-- all object plug-ins must return the methods that they support in a
-- standard method table; uncomment any additional methods as needed

return {
	nwcut		= {['Create Tablature'] = 'FileText'},
	spec		= obj_spec,
	create		= obj_create,
	spin		= obj_spin,
	draw		= obj_draw
	}
