-- Version 0.91

--[[----------------------------------------------------------------
ChordPlay.nw

This will show and play a named chord. For play back, the duration of the
chord is determined by the indicated Span value, which defines the number
of notes/rests for which the chord will play.

The Font, Size, and Style can be set within any instance of ChordPlay, but
only the the first instance in a staff generally needs to define the font
details. By default, all subsequent ChordPlay objects will use the font 
details specified in the first instance in the staff.

For play back, both the Octave number and Strum style (Up, Down, or No) can
be specified for the chord:

	Octave:	4
	Strum:	Up

If not specified, the most recent earlier chord settings that specifies these
will be used.
--]]----------------------------------------------------------------

-- our object type is passed into the script as a first paramater, which we can access using the vararg expression ...
local userObjTypeName = ...

local notenameShift = {
	['Cb']=-1,['C']=0,['C#']=1,
	['Db']=1,['D']=2,['D#']=3,
	['Eb']=3,['E']=4,['E#']=5,
	['Fb']=4,['F']=5,['F#']=6,
	['Gb']=6,['G']=7,['G#']=8,
	['Ab']=8,['A']=9,['A#']=10,
	['Bb']=10,['B']=11,['B#']=12,
	}

local strumStyles = {'Default','No','Up','Down'}
local octaveList = {'Default','1','2','3','4','5','6','7','8','9'}

local chordKeySeqList = {
	{'', {0,4,7}},
	{'M', {0,4,7}},
	{'Maj', {0,4,7}},
	{'maj', {0,4,7}},
	{'m', {0,3,7}},
	{'min', {0,3,7}},
	{'dim', {0,3,6}},
	{'aug', {0,4,8}},
	{'+', {0,4,8}},
	{'sus', {0,5,7}},
	{'sus2', {0,2,7}},
	{'6', {0,4,7,9}},
	{'6-9', {0,4,9,14}},
	{'m6', {0,3,7,9}},
	{'7', {0,4,7,10}},
	{'7#5', {0,4,8,10}},
	{'7#9', {0,4,10,15}},
	{'add9', {0,4,7,14}},
	{'dim7', {0,3,6,9}},
	{'m7', {0,3,7,10}},
	{'m7b5', {0,3,6,10}},
	{'m7#5', {0,3,8,10}},
	{'m7b9', {0,3,10,13}},
	{'M7', {0,4,7,11}},
	{'Maj7', {0,4,7,11}},
	{'maj7', {0,4,7,11}},
	{'7sus', {0,5,7,10}},
	{'7b9', {0,4,10,13}},
	{'9', {0,4,7,10,14}},
	{'m9', {0,3,7,10,14}},
	{'M9', {0,4,7,11,14}},
	{'13th', {0,10,16,21}}
	}

local chordKeys = {}
local chordKeyUserList = {}
for _,v in ipairs(chordKeySeqList)  do
	local keyname,pitchlist = v[1],v[2]
	chordKeys[keyname] = pitchlist
	chordKeyUserList[#chordKeyUserList+1] = (keyname == '') and '(Maj)' or keyname
end

local function getNoteBaseAndChordList(fullname)
	if not fullname then return end
	local n,c,inv = fullname:match('^%s*([A-G][b#]?)([^/%s]*)%s*/*%s*([^%s]*)%s*$')
	if not n then return end
	if not notenameShift[n] then return end
	local k = chordKeys[c]

	if (inv == '') then
		inv = nil
	elseif not inv:match('^[A-G][b#]?%s*$') then
		return
	end
	
	if k then return n,c,k,inv end
end

--------------------------------------------------------------------

local userObj = nwc.ntnidx
local drawpos = nwcdraw.user
local searchObj = userObj.new()

local defaultChordFontFace = 'MusikChordSerif'
local defaultChordFontSize = 8
local defaultChordFontStyle = 'b'

local function findInTable(t,searchFor)
	for k,v in pairs(t) do if v == searchFor then return k end end
	return false
end

local function hasTargetDuration()
	searchObj:reset()
	while searchObj:find('next') do
		if searchObj:userType() == userObjTypeName then return false end
		if searchObj:durationBase() then return true end
	end

	return false
end

local function getFontSpec(t)
	local useFont,useSize,useStyle = t.Font,t.Size,t.Style

	if not (useFont and useSize and useStyle) then
		searchObj:reset()
		if searchObj:find('first','user',userObjTypeName) and (searchObj < userObj) then
			if not useFont  then useFont = searchObj:userProp('Font') end
			if not useSize  then useSize = tonumber(searchObj:userProp('Size')) end
			if not useStyle then useStyle = searchObj:userProp('Style') end
		end
	end

	if not useFont then useFont = defaultChordFontFace end
	if not useSize then useSize = defaultChordFontSize end
	if not useStyle then useStyle = defaultChordFontStyle end

	return useFont,useSize,useStyle
end

local function setDrawFont(t)
	local useFont,useSize,useStyle = getFontSpec(t)

	if tonumber(useFont) ~= nil then
		nwcdraw.setFontClass('User'..useFont)
	else
		nwcdraw.setFont(useFont,useSize,useStyle)
	end
end

local function getPerformanceProperty(t,propName,defaultVal)
	local r = t[propName]

	searchObj:reset()
	while r == 'Default' do
		if not searchObj:find('prior','user',userObjTypeName,propName) then break end

		r = searchObj:userProp(propName)
	end

	if r == 'Default' then return defaultVal end
	return r
end

--------------------------------------------------------------------
local oldValidFontStyles = {Bold='b',Italic='i',BoldItalic='bi',Regular='r'}
--
local function audit_ChordPlay(t)
	-- fix the Style field, which formerly was set as Bold/Italic/BoldItalic
	local stylefix = oldValidFontStyles[t.Style]
	if stylefix then t.Style = stylefix end
end

--------------------------------------------------------------------
local function create_ChordPlay(t)
	t.Name = 'C'
end

--------------------------------------------------------------------
local function doFontChange(t,k)
	local useFont,useSize,useStyle = getFontSpec(t)
	useFont,useSize,useStyle = nwcui.fontdlg(useFont,useSize,useStyle)
	if useFont then
		t.Font = useFont
		t.Style = useStyle
		t.Size = useSize
	end
end

local function doKeyChange(t,k,v)
	local name = t.Name
	if v == '(Maj)' then v = '' end
	local p1,p2,p3 = name:match('^(%s*[A-G][b#]?)([^/%s]*)(%s*/*%s*[^%s]*%s*)$')

	t.Name = p1..v..p3
end

--------------------------------------------------------------------

local function spin_ChordPlay(t,dir)
	t.Span = math.max(t.Span + dir,0)
end

--------------------------------------------------------------------

local function draw_ChordPlay(t)
	local drawt = nwcdraw.getTarget()
	local hastarget = hasTargetDuration()
	local fullname = t.Name
	local n,c,k,inv = getNoteBaseAndChordList(fullname)
	if (not k) and (drawt == 'edit') then
		fullname = fullname..' ?'
	end

	setDrawFont(t)

	local w = nwcdraw.calcTextSize(fullname)

	if not nwcdraw.isDrawing() then
		return hastarget and 0 or w
	end

	nwcdraw.alignText('baseline',hastarget and 'center' or 'right')
	nwcdraw.text(fullname)

	if hastarget then
		local span,spanned = t.Span,0
		while (spanned < span) and drawpos:find('next','duration') do
			spanned = spanned + 1
		end

		if spanned > 0 then
			local w = drawpos:xyRight()
			nwcdraw.hintline(w)
		end
	end
end

--------------------------------------------------------------------

local function transposeNoteString(chordRoot,semitones,notepos)
	local notename = chordRoot:sub(1,1)
	local notenameidx = findInTable(nwc.txt.NoteScale,notename)
	if not notenameidx then return chordRoot end

	-- set semitones to the new target pitch shift
	semitones = (notenameShift[chordRoot] + semitones) % 12
	
	-- use 'notepos' to calculate the preferred note name
	notenameidx = 1 + ((tonumber(notenameidx) + notepos - 1) % 7)
	notename = nwc.txt.NoteScale[notenameidx]

	-- search through the notenameShift values and look for a matching nshift,
	-- favoring the preferred notename (from above)
	for refRoot,rootShift in pairs(notenameShift) do
		if (rootShift %12) == semitones then
			chordRoot = refRoot
			if refRoot:sub(1,1) == notename then break end
		end
	end

	return chordRoot
end

local function transpose_ChordPlay(t,semitones,notepos)
	local fullname = t.Name
	local xspace1,chordRoot,chordVoicing = fullname:match('^(%s*)([A-G][b#]?)(.*)$')
	if not (chordRoot and notenameShift[chordRoot]) then return end

	if chordVoicing and chordVoicing ~= '' then
		local vcp1,vcp2,xspace2 = chordVoicing:match('^([^/%s]*)%s*/%s*([A-G][b#]?)(%s*)$')
		if vcp2 and notenameShift[vcp2] then
			chordVoicing = vcp1..'/'..transposeNoteString(vcp2,semitones,notepos)..xspace2
		end
	end

	t.Name = xspace1..transposeNoteString(chordRoot,semitones,notepos)..chordVoicing
end

--------------------------------------------------------------------
local constructedPlayTable = {}
--
local function bldPlayInversion(k,startingPitch)
	if (startingPitch == 0) then return k end

	local k2 = constructedPlayTable
	local k_l = #k

	while #k2 > k_l do k2[#k2] = nil end
	for i=1,k_l do k2[i] = k[i] end

	local invIndex = findInTable(k,startingPitch)

	if not invIndex then
		-- simply add this pitch under the current chord
		table.insert(k2,1,(startingPitch%12)-12)
	else
		-- move the inversion pitch and later pitches relative to the original tonic
		local octaveChange = k[invIndex] - ((k[invIndex] % 12) - 12)

		for i = invIndex,k_l do
			k2[i] = k2[i] - octaveChange
		end

		table.sort(k2)
	end

	return k2
end

local function bldUserChord(keylist)
	if not keylist then return false end

	local k2 = constructedPlayTable
	local n = 0

	-- copy the pitch list into the k2 table
	for key in keylist:gmatch('[^%s,]+') do
		local v = tonumber(key)
		if (not v) or (math.abs(v) > 48) then break end
		n = n + 1
		k2[n] = v
	end

	-- remove any trailing k2 values beyond what we are using
	while #k2 > n do k2[#k2] = nil end

	return k2
end

local function play_ChordPlay(t)
	if not hasTargetDuration() then return end

	local fullname = t.Name
	local n,c,k,inv = getNoteBaseAndChordList(fullname)
	if not k then return end

	local span,spanned = t.Span,0
	searchObj:reset()
	while (spanned < span) and searchObj:find('next','duration') do
		spanned = spanned + 1
	end

	-- need the song position of the item just after the target
	searchObj:find('next')
	local duration = searchObj:sppOffset()

	if duration < 1 then return end

	local nshift = notenameShift[n]
	local startPitch = 12 * tonumber(getPerformanceProperty(t,'Octave',4))
	local strum = getPerformanceProperty(t,'Strum','No')
	local k_user = bldUserChord(t.Keys)

	if k_user then
		k = k_user
	elseif inv then
		local invShift = notenameShift[inv] or nshift 
		
		k = bldPlayInversion(k,(invShift - nshift) % 12)

		-- keep the starting note in the target octave (allow for Cb in lower octave)
		if (k[1] + nshift) < ((invShift == -1) and -1 or 0) then
			startPitch = startPitch + 12
		end
	end

	local noteCount = #k
	local arpeggioShift = (strum ~= 'No') and math.floor(math.min(duration,nwcplay.PPQ)/math.max(12,noteCount+1)) or 0

	for i, v in ipairs(k) do
		local thisShift = math.min(duration-arpeggioShift, arpeggioShift * ((strum == 'Down') and (noteCount-i) or i))
		nwcplay.note(thisShift, duration-thisShift, startPitch+v+nshift)
	end
end

--------------------------------------------------------------------
local spec_ChordPlay = {
	{id='Name',type='text',default='C'},
	{id='Span',type='int',default=0,min=0,max=32},
	{id='Octave',type='enum',default=octaveList[1],list=octaveList},
	{id='Strum',type='enum',default=strumStyles[1],list=strumStyles},
	{id='Font',type='text',default=nil,click=doFontChange},
	{id='Size',type='float',default=nil,min=0.1,max=50,step=0.1},
	{id='Style',type='text',default=nil,click=doFontChange},
	{id='Keys',type='text',default=nil},
	{id='ChangeKey',type='enum',default=nil,list=chordKeyUserList,click=doKeyChange},
	}

--------------------------------------------------------------------

return {
	spec = spec_ChordPlay,
	audit = audit_ChordPlay,
	create = create_ChordPlay,
	spin = spin_ChordPlay,
	transpose = transpose_ChordPlay,
	play = play_ChordPlay,
	draw = draw_ChordPlay,
	width = draw_ChordPlay
	}
