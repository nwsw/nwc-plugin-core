-- Version 1.7

--[[----------------------------------------------------------------
ChordPlay.nw <https://nwsw.net/-f9092>

This object plugin shows and plays a named chord. It also provides a user tool in
the .Plugins group that can be used to convert text into native ChordPlay objects.

For display, the object provides font, size and style options which control how
the chord is shown in the staff. The first object in a staff can be used to establish
a default font that will apply to all other ChordPlay objects that appear later in the
staff. You can establish the font for any ChordPlay object by selecting it by itself,
the using the right click property menu to select a new font designation.

For play back, the duration of the chord is determined by the indicated Span value,
which defines the number of notes/rests over which the chord will play. A strum
direction enables the arpeggiation of the chord. A key/pitch override provides
complete control over the notes that comprise the chord during play back. Finally,
an octave indicator controls which octave contains the root note of the chord.

@Name
This is the name of the chord or 'N.C.'. It should look something like these:

	 C7     Dbmaj7     C7/E

You should use 'b' for flats and '#' for sharps. The following chord key
types are recognized:

M, Maj, maj, m, min, dim, aug, +, sus, sus2, 6, 6-9, m6, 7, 7#5, 7#9, add9,
dim7, m7, m7b5, m7#5, m7b9, M7, Maj7, maj7, 7sus, 7b9, 9, m9, M9, 13th,
4, 4/9, 5+, 7/5+, 5-, 7+, 7/4, 7/9+, 9-, 9sus, -, -7, -7/5+, -7/5-, -6, m7/5-, m7/5+

@Span
This specifies the number of following notes/rests over which the chord will
play. Set to 0 to disable play back.

@Octave
The starting MIDI octave for the root note in the chord.

@Strum
This can be used to strum/arpeggiate the chord.

@Font
This is the typeface used by the chord. When blank, the typeface defaults to that
specified in the first instance of the object type in the staff.

@Size
This is the size of the text used to display the chord. When blank, the size defaults to that
specified in the first instance of the object type in the staff.

@Style
This is the style of the text used to display the chord. When blank, the style defaults to that
specified in the first instance of the object type in the staff.

@Keys
This provides a list of pitch offsets that will be used for play back, overriding the default
play back pitches.

--]]----------------------------------------------------------------
local function specialChordFont(typeface)
	-- MusikChordSans.ttf
	-- MusikChordSansGermanic.ttf
	-- MusikChordSerif.ttf
	-- MusikChordSerifGermanic.ttf
	-- SwingChord.ttf
	-- SwingChordGermanic.ttf
	return typeface:match('^MusikChord') or typeface:match('^SwingChord')
end
-- The special chord fonts have a much smaller size than the standard
local chordFontScaling = 1.7

local solfeggioNoteCorrespondence = {
	['DO']='C',
	['RE']='D',
	['MI']='E',
	['FA']='F',
	['SO']='G', -- Warning!
	['LA']='A',
	['SI']='B',
	['TI']='B' }

local function getSolfeggioNote(textName)
	local noteName = string.upper(string.sub(textName, 1, 2))
	alphaNoteName = solfeggioNoteCorrespondence[noteName] or ''
	if not (alphaNoteName == '') then
		if alphaNoteName == 'G' then -- Special case: length = 3
			noteName = string.upper(string.sub(textName, 1, 3))
			if noteName == 'SOL' then
			  textName = 'G'..string.sub(textName, 4)
			end
		else
		  textName = alphaNoteName..string.sub(textName, 3)
		end
	end
	return textName
end

if nwcut then
	-- This is the user tool entry point
	local userObjTypeName = arg[1] or 'ChordPlay.nw'
	local copyProps = {'Visibility','Color'}
	local changeCount = 0
	local score = nwcut.loadFile()
	local function filterProc(o)
		if o:Is('Text') then
			local textName = o:Get('Text') or ''
			textName = getSolfeggioNote(textName)
			-- Only alphabetical note names here
			if string.match(textName, '^%s*[A-G][b#]?[^/%s]*%s*/*%s*[^%s]*%s*$') then
				local o2 = nwcItem.new('|User|'..userObjTypeName)
				o2.Opts.Name = textName -- o.Opts.Text
				o2.Opts.Pos = o:Provide('Pos',0) - 1
				for _,prop in ipairs(copyProps) do
					if o.Opts[prop] then o2.Opts[prop] = o.Opts[prop] end
				end

				changeCount = changeCount + 1
				return o2
			end
		end
	end

	score:forSelection(filterProc)
	nwcut.warn('Changed '..changeCount..' object'..((changeCount == 1) and '' or 's'))
	score:save()
	return
end

--------------------------------------------------------------------

-- our object type
local userObjTypeName = ...

local spec_ChordPlay, menu_ChordPlay -- tables actually established later

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
local defaultYesOrNo = {'Default','No','Yes'}
local seventhNoteNames = {'Default','Si','Ti'}

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
	{'13th', {0,10,16,21}},
	-- Flurmy
	{'4', {0,5,7}},
	{'4/9', {0,5,7,14}},
	{'5+', {0,4,8}},
	{'7/5+', {0,4,8,10}},
	{'5-', {0,4,6}},
	{'7+', {0,4,7,11}},
	{'7/4', {0,5,10,15}},
	{'7/9+', {0,4,10,15}},
	{'-', {0,3,7}},
	{'-7', {0,3,7,10}},
	{'-7/5-', {0,3,6,10}},
	{'m7/5-', {0,3,6,10}},
	{'-7/5+', {0,3,8,10}},
	{'m7/5+', {0,3,8,10}},
	{'-6', {0,3,7,9}},
	{'9-', {0,4,7,13}},
	{'9sus', {0,5,7,10,14}},
	-- Lawrie (Special Chord Font characters)
	{'%', {0,4,9,14}},
	{'H', {0,4,9,14}},
	{'<%', {0,4,9,14}},
	{'m%', {0,3,9,14}},
	{'>%', {0,3,9,14}},
	{'min%', {0,3,9,14}},
	{'<', {0,4,7}},
	{'<7', {0,4,7,11}},
	{'<9', {0,4,7,11,14}},
	{'>', {0,3,7}},
	{'>7', {0,3,7,10}},
	{'>9', {0,3,7,10,14}},
	{'W', {0,5,7}},
	{'W2', {0,2,7}},
	{'X', {0,5,7}},
	{'Z', {0,5,7,10}},
	{'I', {0,4,7,9}},
	{'J', {0,4,7,11}},
	{'K', {0,4,7,11,14}},
	{'L', {0,11,16,21}}
	}

local chordKeys = {}
local chordKeyUserList = {}
for _,v in ipairs(chordKeySeqList) do
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
	elseif not inv:match('^[A-G2-9][%+%-b#]?%s*$') then
		return
	end

	if k then return n,c,k,inv end
end

--------------------------------------------------------------------
spec_ChordPlay = {
	{id='Name',label='Chord &Name',type='text',default=''},
	{id='Span',label='Note &Span',type='int',default=0,min=0,max=32},
	{id='Octave',label='Root &Octave',type='enum',default=octaveList[1],list=octaveList},
	{id='Strum',label='Strum Style',type='enum',default=strumStyles[1],list=strumStyles},
	{id='Font',label='Font Typeface',type='text',default=nil},
	{id='Size',label='Font Size',type='float',default=nil,min=0.1,max=50,step=0.1},
	{id='Style',label='Font Style',type='text',default=nil},
	{id='Keys',label='Override Play &Keys',type='text',default=nil},
	{id='Localize',label='Localize',type='text',default=nil},
	{id='Solfeggio',label='Solfeggio Style Chords',type='enum',default=defaultYesOrNo[1],list=defaultYesOrNo},
	{id='SeventhNote',label='7th Note Name',type='enum',default=seventhNoteNames[1],list=seventhNoteNames},
	{id='Unicode',label='Unicode chars',type='enum',default=defaultYesOrNo[1],list=defaultYesOrNo}
	}

--------------------------------------------------------------------

local userObj = nwc.ntnidx
local drawpos = nwcdraw.user
local searchObj = userObj.new()

local defaultChordFontFace = 'MusikChordSerif'
local defaultChordFontSize = 8
local defaultChordFontStyle = 'b'

-- check the font....this has the side effect of making it available in the Viewer
-- if the font is not installed
if not nwc.hasTypeface(defaultChordFontFace) then
	defaultChordFontFace = 'Arial'
end

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
local function doFontChange(t)
	local useFont,useSize,useStyle = getFontSpec(t)
	useFont,useSize,useStyle = nwcui.fontdlg(useFont,useSize/4,useStyle)
	if useFont then
		t.Font = useFont
		t.Style = useStyle
		t.Size = useSize*4
	end
end

local function doKeyChange(t,choice)
	local name = t.Name
	choice = choice or ''
	if choice == '(Maj)' then choice = '' end
	local p1,p2,p3 = name:match('^(%s*[A-G][b#]?)([^/%s]*)(%s*/*%s*[^%s]*%s*)$')

	t.Name = (p1 or 'C')..choice..(p3 or '')
end

local function doCustomChord(t)
	local keys = t.Keys

	if not keys then
		local n,c,k,inv = getNoteBaseAndChordList(t.Name)
		if k then
			keys = table.concat(k,',')
		else
			keys = ''
		end
	end

	keys = nwcui.prompt('Enter the semitone offset of each pitch','*',keys)
	if keys then
		t.Keys = (keys ~= '') and keys or nil
	end
end

--------------------------------------------------------------------

local function spin_ChordPlay(t,dir)
	t.Span = math.max(t.Span + dir,0)
end

--------------------------------------------------------------------
local function remapAccToUnicode(c)
	if c == '#' then return '♯' end -- U+266F
	if c == 'b' then return '♭' end -- U+266D
	return c
end

local function isNoChord(chordName)
	local upCase = string.upper(chordName)
	return (upCase == 'N.C.') or (upCase == 'NC')
end

local function draw_ChordPlay(t)
	local fullname = t.Name
	if fullname == '' then
		if userObj:find('prior', 'note') then return end
		return nwc.toolbox.drawStaffSigLabel(userObjTypeName)
	end

	local drawt = nwcdraw.getTarget()
	local hastarget = hasTargetDuration()
	local span = t.Span
	local spanned = 0
	if not isNoChord(fullname) then
		local n,c,k,inv = getNoteBaseAndChordList(fullname)
		if (not k) and (drawt == 'edit') then
			fullname = fullname..' ?'
		end
	end

	setDrawFont(t)

	local typeface = nwcdraw.getTypeface()
	local displayname = fullname
	if isNoChord(displayname) then
		if specialChordFont(typeface) then
			displayname = '±' -- 'n.c.' char in special chord fonts
		else
			displayname = 'N.C.'
			nwcdraw.setFontSize(nwcdraw.getFontSize()/chordFontScaling)
		end
	else
		if getPerformanceProperty(t,'Solfeggio','No') == 'Yes' then
			if specialChordFont(typeface) then
				-- Those fonts don't have capital letters beside A..G
				-- and seem to have a much smaller size than the standard
				nwcdraw.setTypeface('Arial')
			end
			nwcdraw.setFontSize(nwcdraw.getFontSize()/chordFontScaling)
			displayname = displayname:gsub('([A-G])([Mm]aj7)','%17+',1)
			displayname = displayname:gsub('([A-G])(maj)','%1',1)
			displayname = displayname:gsub('([A-G])(min)','%1-',1)
			displayname = displayname:gsub('([A-G])(m)','%1-',1)
			local solfeggioNoteNames = {
				['C']='Do',
				['D']='Re',
				['E']='Mi',
				['F']='Fa',
				['G']='Sol',
				['A']='La',
				['B']=getPerformanceProperty(t,'SeventhNote','Si')}
			displayname = displayname:gsub('[A-G]',solfeggioNoteNames)
			displayname = displayname:gsub('([A-G])(aug)','%15+',1)
			displayname = displayname:gsub('([A-G])(7#5)','%17/5+',1)
			displayname = displayname:gsub('([A-G])(7#9)','%17/9+',1)
			displayname = displayname:gsub('([A-G])(7b5)','%17/5-',1)
			displayname = displayname:gsub('([A-G])(7b9)','%17/9-',1)
			if getPerformanceProperty(t,'Unicode','Yes') == 'Yes' then
				displayname = displayname:gsub('([#,b])',remapAccToUnicode)
			end
		else
			if specialChordFont(typeface) then
				if typeface:match('Germanic$') then
					-- B shows as H, and Bb shows as B
					displayname = displayname:gsub('^%s*(B)','H')
					displayname = displayname:gsub('/%s*(B)','H')
					displayname = displayname:gsub('Hb','B')
				end
			else
				nwcdraw.setFontSize(nwcdraw.getFontSize()/chordFontScaling)
				if getPerformanceProperty(t,'Unicode','Yes') == 'Yes' then
					displayname = displayname:gsub('([#,b])',remapAccToUnicode)
				end
			end
		end
	end

	local w = nwcdraw.calcTextSize(displayname)

	if not nwcdraw.isDrawing() then
		return hastarget and 0 or w
	end

	drawpos:reset()
	if hastarget and drawpos:find('next','duration') then
		local targetx = drawpos:xyTimeslot()
		spanned = 1
		nwcdraw.moveTo(targetx+0.5,0)
	end

	nwcdraw.alignText('baseline',hastarget and 'center' or 'right')
	nwcdraw.text(displayname)

	if (span > 0) and (spanned > 0) then
		-- drawpos is already pointed at the first note position
		while (spanned < span) and drawpos:find('next','duration') do
			spanned = spanned + 1
		end

		if spanned > 0 then
			local w = drawpos:xyRight()
			nwcdraw.moveTo(0,0)
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
	local duration = math.min(searchObj:sppOffset(),nwcplay.MAXSPPOFFSET or (30*nwcplay.PPQ))

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
	local trans = nwcplay.getTransposition()

	for i, v in ipairs(k) do
		local thisShift = math.min(duration - arpeggioShift, arpeggioShift*((strum == 'Down') and (noteCount-i) or i))
		nwcplay.note(thisShift, duration - thisShift, startPitch + v + nshift + trans)
	end
end

--------------------------------------------------------------------
menu_ChordPlay = {
	{type='choice',name='Change Chord',default=nil,list=chordKeyUserList,disable=false,data=doKeyChange},
	{type='command',name='Custom Chord Notes...',separator=true,checkmark=false,disable=false,data=doCustomChord},
	{type='command',name='Set Font...',checkmark=false,disable=false,data=doFontChange},
	}

local function menuInit_ChordPlay(t)
	local p1,p2 = t.Name:match('^(%s*[A-G][b#]?)([^/%s]*)')
	if not p2 or (p2 == '') then p2 = '(Maj)' end
	menu_ChordPlay[1].default = p2
	menu_ChordPlay[2].checkmark = (t.Keys and true) or false
end

local function menuClick_ChordPlay(t,menu,choice)
	local m = menu_ChordPlay[menu]

	if m and m.data then
		choice = choice and m['list'][choice] or false
		m.data(t,choice)
	end
end

--------------------------------------------------------------------

return {
	nwcut      = {['Convert Text Chords'] = 'ClipText'},
	spec       = spec_ChordPlay,
	menu       = menu_ChordPlay,
	menuInit   = menuInit_ChordPlay,
	menuClick  = menuClick_ChordPlay,
	audit      = audit_ChordPlay,
	create     = create_ChordPlay,
	spin       = spin_ChordPlay,
	transpose  = transpose_ChordPlay,
	play       = play_ChordPlay,
	draw       = draw_ChordPlay,
	width      = draw_ChordPlay
	}
