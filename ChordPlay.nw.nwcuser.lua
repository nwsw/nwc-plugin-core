-- Version 0.63

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
	['']		= {0,4,7},
	['M']		= {0,4,7},
	['Maj']		= {0,4,7},
	['m']		= {0,3,7},
	['min']		= {0,3,7},
	['dim']		= {0,3,6},
	['aug']		= {0,4,8},
	['+']		= {0,4,8},
	['sus']		= {0,5,7},
	['sus2']	= {0,2,7},
	['6']		= {0,4,7,9},
	['6/9']		= {0,4,9,14},
	['m6']		= {0,3,7,9},
	['7']		= {0,4,7,10},
	['7#5']		= {0,4,8,10},
	['7#9']		= {0,4,10,15},
	['add9']	= {0,4,7,14},
	['dim7']	= {0,3,6,9},
	['m7']		= {0,3,7,10},
	['m7b5']	= {0,3,6,10},
	['m7#5']	= {0,3,8,10},
	['m7b9']	= {0,3,10,13},
	['M7']		= {0,4,7,11},
	['7sus']	= {0,5,7,10},
	['7b9']		= {0,4,10,13},
	['9']		= {0,4,7,10,14},
	['m9']		= {0,3,7,10,14},
	['M9']		= {0,4,7,11,14},
	['13th']	= {0,10,16,21}
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

	local promptTxt = nwcui.prompt('Change Strum Style','|Unchanged|'..table.concat(strumStyles,'|'))
	if promptTxt ~= 'Unchanged' then
		t.Strum = promptTxt
	end

	if (not searchObj:find('first','user',userObjTypeName)) or (searchObj >= userObj) then
		t.Octave = 4
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

local function play_ChordPlay(t)
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
	local startPitch = 12 * getPerformanceProperty(t,'Octave')
	local strum = getPerformanceProperty(t,'Strum')

	if inv then
		local invShift = notenameShift[inv] or nshift 
		
		k = bldPlayInversion(k,(invShift - nshift) % 12)

		-- keep the starting note in the target octave (allow for Cb in lower octave)
		if (k[1] + nshift) < ((invShift == -1) and -1 or 0) then
			startPitch = startPitch + 12
		end
	end

	local noteCount = #k
	local arpeggioShift = (strum ~= 'No') and math.min(duration,nwcplay.PPQ)/12 or 0

	for i, v in ipairs(k) do
		local thisShift = arpeggioShift * ((strum == 'Down') and (noteCount-i) or i)
		nwcplay.note(thisShift, duration-thisShift, startPitch+v+nshift)
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
