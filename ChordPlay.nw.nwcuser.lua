-- Version 0.61

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

local chordKeys = {
	['']		= {1,5,8},
	['M']		= {1,5,8},
	['Maj']		= {1,5,8},
	['m']		= {1,4,8},
	['min']		= {1,4,8},
	['dim']		= {1,4,7},
	['aug']		= {1,5,9},
	['+']		= {1,5,9},
	['sus']		= {1,6,8},
	['sus2']	= {1,3,8},
	['6']		= {1,5,8,10},
	['6/9']		= {1,5,10,15},
	['m6']		= {1,4,8,10},
	['7']		= {1,5,8,11},
	['7#5']		= {1,5,9,11},
	['7#9']		= {1,5,11,16},
	['add9']	= {1,5,8,15},
	['dim7']	= {1,4,7,10},
	['m7']		= {1,4,8,11},
	['m7b5']	= {1,4,7,11},
	['m7#5']	= {1,4,9,11},
	['m7b9']	= {1,4,11,14},
	['M7']		= {1,5,8,12},
	['7sus']	= {1,6,8,11},
	['7b9']		= {1,5,11,14},
	['9']		= {1,5,8,11,15},
	['m9']		= {1,4,8,11,15},
	['M9']		= {1,5,8,12,15},
	['13th']	= {1,11,17,22}
	}

local guitarStringSemitoneOffsets = {0,5,10,15,19,24}

local chordFingerings = {
	['']		= 0x022100,
	['M']		= 0x022100,
	['Maj']		= 0x022100,
	['m']		= 0x022000,
	['min']		= 0x022000,
	['dim']		= 0x0f2353,
	['aug']		= 0x032110,
	['+']		= 0x032110,
	['sus']		= 0x022200,
	['sus2']	= 0x0f2452,
	['6']		= 0x022120,
	['6/9']		= 0x0f2422,
	['m6']		= 0x022020,
	['7']		= 0x020100,
	['7#5']		= 0x032130,
	['7#9']		= 0x056000,
	['add9']	= 0x022102,
	['dim7']	= 0x012020,
	['m7']		= 0x020000,
	['m7b5']	= 0x055353,
	['m7#5']	= 0x030013,
	['m7b9']	= 0x023030,
	['M7']		= 0x021100,
	['7sus']	= 0x020200,
	['7b9']		= 0x020131,
	['9']		= 0x020102,
	['m9']		= 0x020002,
	['M9']		= 0x021102,
	['13th']	= 0x020120,
	}

local function getNoteBaseAndChordList(fullname)
	if not fullname then return end
	local n,c,inv = fullname:match('^([A-G][b#]?)([^/]*)/*(.*)$')
	if not n then return end
	if not notenameShift[n] then return end
	local k = chordKeys[c]

	if (inv == '') then
		inv = nil
	elseif not inv:match('^[A-G][b#]?$') then
		return
	end
	
	if k then return n,c,k,inv end
end

--------------------------------------------------------------------

local userObj = nwc.ntnidx
local drawpos = nwcdraw.user
local searchObj = userObj.new()

local calcGuitarStringPitches = {0,0,0,0,0,0}

local defaultChordFontFace = 'Arial'
local defaultChordFontSize = 5
local defaultChordFontStyle = 'Bold'

if nwc.hasTypeface('MusikChordSerif') then
	defaultChordFontFace = 'MusikChordSerif'
	defaultChordFontSize = 8
end

local function findInTable(t,searchFor)
	for k,v in pairs(t) do if v == searchFor then return k end end
	return false
end

local instrumentTypes = {'Piano','Guitar'}
local strumStyles = {'Up','Down','No'}

local validFontStyleList = {'Bold','Italic','BoldItalic','Regular'}
local validFontStyles = {Bold='b',Italic='i',BoldItalic='bi',Regular='r'}
--
local function setDrawFont(t)
	local useFont = t.Font
	local useSize = t.Size
	local useStyle = t.Style

	if searchObj:find('first','user',userObjTypeName) and (searchObj < userObj) then
		if not useFont then
			useFont = searchObj:userProp('Font')
		end

		if not useSize then
			useSize = tonumber(searchObj:userProp('Size'))
		end

		if not useStyle then
			useStyle = searchObj:userProp('Style') 
		end
	end

	if not useFont then useFont = defaultChordFontFace end
	if not useSize then useSize = defaultChordFontSize end
	if not useStyle then useStyle = defaultChordFontStyle end

	useStyle = validFontStyles[useStyle] or 'r'

	if tonumber(useFont) ~= nil then
		nwcdraw.setFontClass('User'..useFont)
	else
		nwcdraw.setFont(useFont,useSize,useStyle)
	end
end

--------------------------------------------------------------------
local spec_ChordPlay = {
	Span	= {type='int',default=0,min=0,max=32},
	Name	= {type='text',default='C'},
	Font	= {type='text',default=nil},
	Size	= {type='float',default=false,min=0.1,max=50},
	Style	= {type='enum',default=false,list=validFontStyleList},
	Instrument = {type='enum',default='Guitar',list=instrumentTypes},
	Octave	= {type='int',default=4,min=0,max=9},
	Strum	= {type='enum',default='Up',list=strumStyles}
	}

local function create_ChordPlay(t)
	local notename = nwcui.prompt('Note name','|C|C#|Cb|D|D#|Db|E|E#|Eb|F|F#|Fb|G|G#|Gb|A|A#|Ab|B|B#|Bb')
	if not notename then return end

	local namedchords = {}
	for k,_ in pairs(chordKeys) do
		table.insert(namedchords,notename..k)
	end

	table.sort(namedchords)

	local chordkey = nwcui.prompt('Full chord name','|'..table.concat(namedchords,'|'))
	if not chordkey then return end

	t.Name = chordkey
	t.Span = 1

	local promptTxt = nwcui.prompt('Change Instrument Type','|Unchanged|'..table.concat(instrumentTypes,'|'))
	if promptTxt ~= 'Unchanged' then
		t.Instrument = promptTxt
	end

	promptTxt = nwcui.prompt('Change Strum Style','|Unchanged|'..table.concat(strumStyles,'|'))
	if promptTxt ~= 'Unchanged' then
		t.Strum = promptTxt
	end

	if (not searchObj:find('first','user',userObjTypeName)) or (searchObj >= userObj) then
		t.Font = defaultChordFontFace
		t.Size = defaultChordFontSize
		t.Style = defaultChordFontStyle
	end
end

--------------------------------------------------------------------

local function spin_ChordPlay(t,dir)
	t.Span = math.max(t.Span + dir,0)
end

--------------------------------------------------------------------

local function draw_ChordPlay(t)
	local fullname = t.Name
	local n,c,k,inv = getNoteBaseAndChordList(fullname)
	if (not k) and (nwcdraw.getTarget() == 'edit') then
		fullname = fullname..' ?'
	end

	setDrawFont(t)
	nwcdraw.alignText('baseline','center')
	nwcdraw.text(fullname)

	local span,spanned = t.Span,0
	while (spanned < span) and drawpos:find('next','duration') do
		spanned = spanned + 1
	end

	if spanned > 0 then
		local w = drawpos:xyRight()
		nwcdraw.hintline(w)
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
	local chordRoot,chordVoicing = fullname:match('^([A-G][b#]?)(.*)$')
	if not (chordRoot and notenameShift[chordRoot]) then return end

	if chordVoicing and chordVoicing ~= '' then
		local vcp1,vcp2 = chordVoicing:match('^([^/]*)/([A-G][b#]?)$')
		if vcp2 and notenameShift[vcp2] then
			chordVoicing = vcp1..'/'..transposeNoteString(vcp2,semitones,notepos)
		end
	end

	t.Name = transposeNoteString(chordRoot,semitones,notepos)..chordVoicing
end

--------------------------------------------------------------------
local function getPerformanceProperty(t,propName)
	if not nwc.isset(t,propName) then
		searchObj:reset()
		if searchObj:find('prior','user',userObjTypeName,propName) then
			return searchObj:userProp(propName)
		end
	end

	return t[propName]
end

local function play_ChordPlay(t)
	local fullname = t.Name
	local n,c,k = getNoteBaseAndChordList(fullname)
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
	local instrument = getPerformanceProperty(t,'Instrument')
	local startPitch = 12 * getPerformanceProperty(t,'Octave')
	local strum = getPerformanceProperty(t,'Strum')

	if instrument == 'Guitar' then
		local k2 = calcGuitarStringPitches
		local f = chordFingerings[c]
		local stringCount = 0

		if nshift >= 4 then nshift = nshift - 12 end

		for stringNum=1,6 do
			local semitones = bit32.extract(f,(6-stringNum)*4,4)
			if semitones < 15 then
				stringCount = stringCount + 1
				k2[stringCount] = guitarStringSemitoneOffsets[stringNum] + semitones + 1
			end
		end
		
		for i=6,stringCount,-1 do
			k2[i] = nil
		end

		k = k2
	end

	local noteCount = #k
	local arpeggioShift = (strum ~= 'No') and math.min(duration,nwcplay.PPQ)/12 or 0

	for i, v in ipairs(k) do
		local thisShift = arpeggioShift * ((strum == 'Down') and (noteCount-i) or i)
		nwcplay.note(thisShift, duration-thisShift, startPitch-1+v+nshift)
	end
end

--------------------------------------------------------------------
return {
	spec = spec_ChordPlay,
	create = create_ChordPlay,
	spin = spin_ChordPlay,
	transpose = transpose_ChordPlay,
	play = play_ChordPlay,
	draw = draw_ChordPlay
	}
