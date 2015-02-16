-- Version 0.4

--[[----------------------------------------------------------------
ChordPlay.nw

This will show and play a named chord. For play back, the duration of the
chord is determined by the indicated Span value, which defines the number
of notes/rests for which the chord will play.

The Font, Size, and Style can be set within any instance of ChordPlay, but
only the the first instance in a staff generally needs to define the font
details. By default, all subsequent ChordPlay objects will use the font 
details specified in the first instance in the staff.
--]]----------------------------------------------------------------

-- our object type is passed into the script as a first paramater, which we can access using the vararg expression ...
local userObjTypeName = ...

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
	['13th']	= {1,11,17,22},
	}

local notenameShift = {
	['Cb']=-1,['C']=0,['C#']=1,
	['Db']=1,['D']=2,['D#']=3,
	['Eb']=3,['E']=4,['E#']=5,
	['Fb']=4,['F']=5,['F#']=6,
	['Gb']=6,['G']=7,['G#']=8,
	['Ab']=8,['A']=9,['A#']=10,
	['Bb']=10,['B']=11,['B#']=12,
	}
	
local function getNoteBaseAndChordList(fullname)
	if not fullname then return end
	local n,c = fullname:match('^([A-G][b#]?)(.*)$')
	if not n then return end
	if not notenameShift[n] then return end
	local k = chordKeys[c]
	if k then return n,k end
end

--------------------------------------------------------------------

local userObj = nwc.ntnidx
local drawpos = nwcdraw.user
local searchObj = userObj.new()

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

local function getSpan(t,defaultSpan)
	defaultSpan = defaultSpan or 1
	local i = tonumber(t.Span) or defaultSpan
	return (i < 0) and 0 or i
end

local validFontStyles = {Bold='b',Italic='i',BoldItalic='bi',Regular='r'}
--
local function setDrawFont(t)
	local useFont = t.Font
	local useSize = tonumber(t.Size)
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
	if not useSize or (useSize < 0) then useSize = defaultChordFontSize end
	if not useStyle then useStyle = defaultChordFontStyle end

	useStyle = validFontStyles[useStyle] or 'r'

	if tonumber(useFont) ~= nil then
		nwcdraw.setFontClass('User'..useFont)
	else
		nwcdraw.setFont(useFont,useSize,useStyle)
	end
end

--------------------------------------------------------------------

local function create_ChordPlay(t)
	local notename = nwcui.prompt('Note name','|C|C#|Cb|D|D#|Db|E|E#|Eb|F|F#|Fb|G|G#|Gb|A|A#|Ab|B|B#|Bb')
	if not notename then return end

	local namedchords = {}
	for k,_ in pairs(chordKeys) do
		table.insert(namedchords,notename..k)
	end

	table.sort(namedchords)

	notename = nwcui.prompt('Full chord name','|'..table.concat(namedchords,'|'))
	if not notename then return end

	t.Name = notename
	t.Span = 1

	if (not searchObj:find('first','user',userObjTypeName)) or (searchObj >= userObj) then
		t.Font = defaultChordFontFace
		t.Size = defaultChordFontSize
		t.Style = defaultChordFontStyle
	end
end

--------------------------------------------------------------------

local function spin_ChordPlay(t,dir)
	local v = tonumber(t.Span) or 0
	v = math.max(v + ((dir > 0) and 1 or -1),0)
	t.Span = v
end

--------------------------------------------------------------------

local function draw_ChordPlay(t)
	local fullname = t.Name
	local n,k = getNoteBaseAndChordList(fullname)
	if not k then
		fullname = '??'
	end

	setDrawFont(t)
	nwcdraw.alignText('baseline','center')
	nwcdraw.text(fullname)

	local span,spanned = getSpan(t),0
	while (spanned < span) and drawpos:find('next','duration') do
		spanned = spanned + 1
	end

	if spanned > 0 then
		local w = drawpos:xyRight()
		nwcdraw.hintline(w)
	end
end

--------------------------------------------------------------------

local function transpose_ChordPlay(t,semitones,notepos)
	local fullname = t.Name or ''
	local chordRoot,chordVoicing = fullname:match('^([A-G][b#]?)(.*)$')
	if not (chordRoot and notenameShift[chordRoot]) then return end
	local notename = fullname:sub(1,1)
	local notenameidx = findInTable(nwc.txt.NoteScale,notename)
	if not notenameidx then return end

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

	t.Name = chordRoot..chordVoicing
end

--------------------------------------------------------------------

local function play_ChordPlay(t)
	local fullname = t.Name
	local n,k = getNoteBaseAndChordList(fullname)
	if not k then return end

	local span,spanned = getSpan(t),0
	searchObj:reset()
	while (spanned < span) and searchObj:find('next','duration') do
		spanned = spanned + 1
	end

	-- need the song position of the item just after the target
	searchObj:find('next')
	local duration = searchObj:sppOffset()

	if duration < 1 then return end

	local nshift = notenameShift[n]

	if k then
		local arpeggioShift = (duration >= nwcplay.PPQ) and (nwcplay.PPQ/16) or 0
		for i, v in ipairs(k) do
			local thisShift = i*arpeggioShift
			nwcplay.note(thisShift, duration-thisShift, 47+v+nshift)
		end
	end
end

--------------------------------------------------------------------
return {
	create = create_ChordPlay,
	spin = spin_ChordPlay,
	transpose = transpose_ChordPlay,
	play = play_ChordPlay,
	draw = draw_ChordPlay
	}
