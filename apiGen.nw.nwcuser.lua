--[[----------------------------------------------------------------
apiGen.nw

This is a collection of tools that are used in the creation of the NWC api specs.
This is currently an evolving mechanism.

This object script includes includes tools that must be run from an external
Lua mechanism. The easiest way to do this is using the ZeroBrane Studio IDE,
and then running this script using its standard Lua interpreter. See the source
code for more details.
--]]----------------------------------------------------------------
--[[ Fake user tool input for use by `nwcut.bat`
!NoteWorthyComposerClip(2.75,Single)
|Note|Dur:4th|Pos:0
!NoteWorthyComposerClip-End
--]]--

--[[----------------------------------------------------------------
**Technical Overview**

This script runs in three different environments:

1.	[NWC Object Plugins](https://lua.noteworthycomposer.com/plugin/)
	You have to manually add the object to a staff, which then provides a context menu with the commands that it supports.
	
2.	[NWC User Tool](https://lua.noteworthycomposer.com/usertool/)
	You can run these from NWC, but they are also invoked by this script when run in the `wx` env.
	
3.	[ZeroBrane Studio (ZBS)](https://studio.zerobrane.com/)
	When run from within ZBS, the wxLua package enables a GUI environment with menu commands for extracting and building the API spreadsheet. The ZBS standard `Lua` interpreter should be used to run this script.
--]]----------------------------------------------------------------
local apiColumnNames = {'name','args','returns','inherits','description'}
local apiColumnSizes = {220,150,200,100,500}

local function iterlistvals(t) local i=0;return function() i=i+1;if t[i] then return t[i] end;end;end
local function itertextlines(s) return string.gmatch(s,'([^\r\n]+)') end
local function createtextblock(lineproc) t={} for s in lineproc() do t[#t+1]=s end return table.concat(t,'\n') end

local function api_Load(apiT,tsvProc)
	local function getnode(nm)
		local node = apiT
		local ftype = 'function'
		for v,sep in nm:gmatch('([^%.:]+)([.:]?)') do
			if not node[v] then node[v] = {type='lib',description=''} end
			node = node[v]
			if sep == '' then
				if node.type == 'lib' then node.type = ftype else node = false end
				return node
			elseif sep == ':' then
				ftype = 'method'
			end
			
			if not node.childs then node.childs = {} end
			node = node.childs
		end
		
		return false
	end
		
	local adds = 0
	
	while true do
		local tsv = tsvProc()
		if not tsv then break end
		local nm,fargs,freturns,inherits,desc = tsv:match('^([^\t\r\n]+)\t([^\t\r\n]*)\t?([^\t\r\n]*)\t?([^\t\r\n]*)\t?([^\t\r\n]*)')
		
		local node = getnode(nm or '')
		if node then
			local isFunction = fargs:match('%(')
			local isClass = inherits:match('%w') or freturns:match('^%(?class%)?$')
			
			adds = adds+1
			node.description = desc
			
			if isFunction then
				local firstretvalue = freturns:match('^%(([%w_%.]+)')
				node.args = fargs
				node.returns = freturns
				if firstretvalue then node.valuetype = firstretvalue end
			elseif isClass then
				node.type = 'class'
				if (inherits:len() > 0) and (inherits ~= 'nil') then node.inherits = inherits end
			else -- value
				node.type = 'value'
				if freturns:len() > 0 then node.valuetype = freturns end
			end
		end
	end
	
	return adds
end

local function api_ConvToList(apiT)
	local out = {}
	local n = 0
	local function ensurefuncfmt(s) 
		if not s:match('^%(') then return '('..s..')' end
		return s
	end
	local function conv(namespace,nm,t)
		if t.type=='lib' then return end -- the `lib` type is auto generated so should not be put in the list
		local sep = (t.type=='method') and ':' or '.'
		local fargs,freturns,inherits = '','',''
		if (t.type == 'method') or (t.type == 'function') then
			fargs,freturns = ensurefuncfmt(t.args or ''),ensurefuncfmt(t.returns or '')
		elseif (t.type == 'class') then
			freturns,inherits = (t.returns or 'class'),(t.inherits or 'nil')
		elseif (t.type == 'value') then
			freturns = (t.valuetype or t.returns) or ''
		end
		
		local ln = ('%s%s%s\t%s\t%s\t%s\t%s'):format(namespace or '',namespace and sep or '',nm,fargs,freturns,inherits,t.description or '')
		
		n = n+1
		table.insert(out,n,ln)
	end
	
	local function procAPI(api,namespace)
		if not api then return end
		for k,v in pairs(api) do
			conv(namespace,k,v)
			if v.childs then
				procAPI(v.childs,namespace and ('%s.%s'):format(namespace,k) or k)
			end
		end
	end
	
	procAPI(apiT)
	table.sort(out)
	return out
end
		
local function EmbedText_Replace(lineProc,embedname,replWith)
	local hdr = ('$%s:(%s)$'):format('EMBEDFILE',embedname)
	local ftr = ('$/%s:(%s)$'):format('EMBEDFILE',embedname)
	local c = {}
	local found = false
	local function flush(p)
		while true do
			local s = p()
			if not s then return end
			c[#c+1] = s
		end
	end
	
	while true do
		local s = lineProc()
		if not s then break end
		if found then
			if s:find(ftr,nil,true) then
				flush(replWith)
				c[#c+1] = s
				flush(lineProc)
				return c
			end
			found[#found+1] = s
		else
			c[#c+1] = s
			if s:find(hdr,nil,true) then found = {} end
		end
	end
	
	return false
end
				
local function EmbedText_Load(lineProc, embedname)
	local hdr = ('$%s:(%s)$'):format('EMBEDFILE',embedname)
	local ftr = ('$/%s:(%s)$'):format('EMBEDFILE',embedname)
	local found = false
	
	while true do
		local s = lineProc()
		if not s then break end
		if found then
			if s:find(ftr,nil,true) then return found end
			found[#found+1] = s
		elseif s:find(hdr,nil,true) then
			found = {}
		end
	end
	
	return false
end

if not nwc then
	-- we are not running in a nwc sandbox, which allows us more freedom
	require('wx')
	
	apiFilename = wx.wxGetHomeDir()..'\\.zbstudio\\packages\\zbs-nwcapi.lua'
	apiTable = {}
	apiName = false
	isDirty = false
	
	frame = wx.wxFrame(wx.NULL,wx.wxID_ANY,"apiGen",wx.wxDefaultPosition,wx.wxSize(800, 600),wx.wxDEFAULT_FRAME_STYLE)
	gridCtrl = wx.wxGrid(frame, wx.wxID_ANY)
	gridCtrl:CreateGrid(8, #apiColumnNames)
	textCtrl = wx.wxTextCtrl(frame,wx.wxID_ANY, "",wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxTE_MULTILINE+wx.wxTE_DONTWRAP)
	
	sizerTop = wx.wxBoxSizer(wx.wxVERTICAL)
	sizerTop:Add(gridCtrl, 2, wx.wxGROW + wx.wxFIXED_MINSIZE + wx.wxALL, 6)
	sizerTop:Add(textCtrl, 1, wx.wxGROW + wx.wxFIXED_MINSIZE + wx.wxALL, 6)
	frame:SetAutoLayout(true)
	frame:SetSizer(sizerTop)

	local function evt_GridChanged()
		if not apiName then return end
		if not isDirty then gridCtrl:SetColLabelValue(0, '* '..apiName) end
		isDirty = true
	end
	
	local function evt_GridEdit(event)
		local row,col = event:GetRow(),event:GetCol()
		gridCtrl:SelectBlock(row,col,row,col)
		if (col ~= 4) then
			event:Skip()
			return
		end
		local v = gridCtrl:GetCellValue(row,col) or ''
		v = v:gsub('\\n','\n'):gsub('\\t','\t')
		local dialog = wx.wxDialog(frame, wx.wxID_ANY, "Description Editor",wx.wxDefaultPosition,wx.wxDefaultSize)
		local descCtrl = wx.wxTextCtrl(dialog,wx.wxID_ANY,v,wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxTE_MULTILINE)
		descCtrl:Connect(wx.wxID_ANY, wx.wxEVT_KEY_DOWN, function(event)
			local endCode = false
			if event.KeyCode == wx.WXK_F9 then
				endCode = wx.wxID_OK
			elseif event:ControlDown() and event.KeyCode == wx.WXK_RETURN then
				endCode = wx.wxID_OK
			elseif event.KeyCode == wx.WXK_ESCAPE then
				endCode = wx.wxID_NONE
			end
			if endCode then return dialog:EndModal(endCode) end
			event:Skip()
		end)
		if dialog:ShowModal() ~= wx.wxID_NONE then
			v = descCtrl:GetValue()
			v = v:gsub('\r?\n','\\n'):gsub('\t','\\t')
			gridCtrl:SetCellValue(row,col,v)
			evt_GridChanged()
		end
	end
	
	local function utl_gridlines()
		local maxrow = gridCtrl:GetNumberRows()
		local row = 0
		local t = {}
		return function()
			while row < maxrow do
				for c=1,5 do
					local cellv = gridCtrl:GetCellValue(row,c-1) or ''
					t[c] = cellv:gsub('[\r\n\t]+',' '):gsub('%]%]','] ] ')
				end
				row = row + 1
				if string.len(t[1]) > 0 then return table.concat(t,'\t') end
			end
			return nil
		end
	end
				
	local function nwc_RunTool(utAction)
		local cmd = ('..\\nwcut.bat "%s" "apiGen.nw" "%s"'):format(arg[0],utAction)
		local fin = io.popen(cmd, 'r')
		local outTxt = (fin and fin:read('*a')) or 'operation failed'
		if fin then fin:close() end
		return outTxt
	end
	
	local function gui_SynchToGrid()
		local t = api_ConvToList(apiTable)
		local cRows = gridCtrl:GetNumberRows()
		local nRows = #t + 8
		if nRows < cRows then
			gridCtrl:DeleteRows(0, cRows-nRows)
		elseif nRows > cRows then
			gridCtrl:AppendRows(nRows-cRows)
		end
		gridCtrl:ClearGrid()

		gridCtrl:BeginBatch()
		for i,v in ipairs(t) do
			local col=0
			for fld in v:gmatch('([^\t\r\n]*)\t?') do
				gridCtrl:SetCellValue(i-1,col,fld)
				col=col+1
			end
		end
		
		gridCtrl:EndBatch()
	end	

	local function menucmd_nwcut_FileScan()
		local fList = setmetatable({},{__index=table})
		for l in io.lines('../nwcutlib/nwcut.lua') do
			local fName,fArgs = l:match('function ([%w_]+[%.:][%w%.:]+)%s*%(([^%)]*)')
			if not fName then fName,fArgs = l:match('([%w_]+[%.:][%w%.:]+)%s*=%s*function%s*%(([^%)]*)') end
			if fName then fList:insert(('%s\t(%s)\t(...)'):format(fName,fArgs)) end
		end

		local msg = ('%d additions'):format(api_Load(apiTable,iterlistvals(fList)))
		textCtrl:SetValue(msg)
		gui_SynchToGrid()
	end
	
	local function menucmd_nwcut_DynamicScan()
		local liblist = nwc_RunTool('nwcutlib_list')
		local msg = ('%d additions'):format(api_Load(apiTable,itertextlines(liblist)))
		textCtrl:SetValue(msg)
		gui_SynchToGrid()
	end

	local function menucmd_LoadCurrentAPI(tsvName)
		local msg = 'embed failed'
		
		if wx.wxFileExists(apiFilename) then
			local txtT = EmbedText_Load(io.lines(apiFilename),tsvName..'.tsv')
			if txtT then
				apiTable = {}
				msg = ('%d assignments'):format(api_Load(apiTable,iterlistvals(txtT)))
				gridCtrl:SetColLabelValue(0, tsvName)
				apiName = tsvName
				gui_SynchToGrid()
			end
		else
			msg = 'File not found: '..apiFilename
		end
		
		textCtrl:SetValue(msg)
	end
	
	local function menucmd_Load_nwcut() menucmd_LoadCurrentAPI('nwcut') end
	local function menucmd_Load_nwcplugin() menucmd_LoadCurrentAPI('nwcplug') end
	
	local function menucmd_CopyGridToClipboard()
		local tb = createtextblock(utl_gridlines)
		textCtrl:SetValue(tb)
		textCtrl:SelectAll()
		textCtrl:Copy()
	end
		
	local function menucmd_ClearGrid()
		apiTable = {}
		gui_SynchToGrid()
		textCtrl:SetValue('')
		evt_GridChanged()
	end
	
	local function menucmd_MergeText()
		local lnum = 0
		local function gl()
			local s = textCtrl:GetLineText(lnum)
			if not (s or ''):match('\t') then return nil end
			lnum=lnum+1
			return s
		end
		
		msg = ('%d assignments'):format(api_Load(apiTable,gl))
		textCtrl:SetValue(msg)
		gui_SynchToGrid()
		evt_GridChanged()
	end
		
	local function menucmd_SaveGrid()
		if not apiName then
			textCtrl:SetValue('No API list has been loaded from '..apiFilename)
			return
		end
			
		if not wx.wxFileExists(apiFilename) then
			textCtrl:SetValue('File not found: '..apiFilename)
			return
		end
		
		local txtT = EmbedText_Replace(io.lines(apiFilename),apiName..'.tsv',utl_gridlines())
		os.rename(apiFilename,apiFilename..'.bak')
		local apiF = io.open(apiFilename,'wb')
		apiF:write(table.concat(txtT,'\n'))
		apiF:close()
		
		gridCtrl:SetColLabelValue(0,apiName)
		isDirty = false
		textCtrl:SetValue('API update has been saved.\n\nHint: You must restart ZBS to load the new api')
	end
		
	local function gui_CloseEvent(event)
		if apiName and isDirty then
			if wx.wxMessageBox('Data has changed...save changes?','Save',wx.wxYES_NO+wx.wxYES_DEFAULT+wx.wxICON_QUESTION,frame) == wx.wxYES then
				menucmd_SaveGrid()
			end
		end
		
		event:Skip()
	end
	
	local function gui_Init()
		local aMenu = wx.wxMenu()
		local function wx_AddMenuCommand(id,name,f)
			aMenu:Append(id, name, name)
			frame:Connect(id, wx.wxEVT_COMMAND_MENU_SELECTED,f)
		end

		wx_AddMenuCommand(wx.wxNewId(),"load current zbs-nwcapi:nwcut API",menucmd_Load_nwcut)
		wx_AddMenuCommand(wx.wxNewId(),"load current zbs-nwcapi:nwcplugin API",menucmd_Load_nwcplugin)
		aMenu:Append(wx.wxID_SEPARATOR,"--")
		wx_AddMenuCommand(wx.wxNewId(),"Clear current api definitions",menucmd_ClearGrid)
		wx_AddMenuCommand(wx.wxNewId(),"Merge control text (TSV format)",menucmd_MergeText)
		aMenu:Append(wx.wxID_SEPARATOR,"--")
		wx_AddMenuCommand(wx.wxNewId(),"Merge nwcut.lua file scan",menucmd_nwcut_FileScan)
		wx_AddMenuCommand(wx.wxNewId(),"Merge nwcut dynamic content",menucmd_nwcut_DynamicScan)
		aMenu:Append(wx.wxID_SEPARATOR,"--")
		wx_AddMenuCommand(wx.wxNewId(),"Copy grid to clipboard",menucmd_CopyGridToClipboard)
		wx_AddMenuCommand(wx.wxNewId(),"Save grid into zbs-nwcapi\tCtrl+S",menucmd_SaveGrid)
		aMenu:Append(wx.wxID_SEPARATOR,"--")
		wx_AddMenuCommand(wx.wxID_EXIT, "E&xit",function (event) frame:Close(true) end)
	
		local menuBar = wx.wxMenuBar()
		menuBar:Append(aMenu, "&Actions")
		frame:SetMenuBar(menuBar)
		
		gridCtrl:Connect(wx.wxEVT_GRID_CELL_CHANGED, evt_GridChanged)
		gridCtrl:Connect(wx.wxEVT_GRID_CELL_RIGHT_CLICK,evt_GridEdit)
		
		frame:Connect(wx.wxEVT_CLOSE_WINDOW, gui_CloseEvent)
		
		for i,v in ipairs(apiColumnNames) do
			gridCtrl:SetColLabelValue(i-1, v)
			gridCtrl:SetColSize(i-1, apiColumnSizes[i])
		end
			
		gridCtrl:DisableDragRowSize()
		
		textCtrl:SetValue('Select an action from the menu\n\nRight click on a description to use an edit box (F9, Alt+F4, or Ctrl+Enter to update)')
		
		wx.wxGetApp():SetTopWindow(frame)
		frame:Show(true)
	end
	
	gui_Init()
	wx.wxGetApp():MainLoop() 
	os.exit()
	return
end
	
local function returnType(v)
	if (type(v) == "function") then
		return "(...)\t(...)"
	end
	
	return ('\t%s'):format(nwcut and nwcut.typeOf(v) or type(v))
end

local function outAPIList(pkg,t,skipmeta,outproc)
	if not outproc then outproc = print end
	for k,v in pairs(t) do
		if not string.match(k,'^__') then
			local tsvline = ('%s.%s\t%s'):format(pkg,k,returnType(v))
			if (pkg == 'nwc.txt') then
				tsvline = ('%s\t\t%s'):format(tsvline,tostring(v))
			end
			
			outproc(tsvline)
		end
	end

	if not skipmeta then
		local mt = getmetatable(t)
		if mt and mt.__index then
			outAPIList(pkg,mt.__index,true,outproc,true)
		end
	end
end

if nwcut then
	local userObjTypeName = arg[1]
    local userAction = arg[2]

	-- all tools will return a report
	nwcut.status = nwcut.const.rc_Report

	-- all tools will have a standard score available
	local score = nwcut.loadFile()

	if userAction == 'utnwctxt_markdown' then
		print('| nwc.txt | Contains |')
		print('|:--------:|:---------|')
		local typnames = {}
		for typname in pairs(nwc.txt) do table.insert(typnames,typname) end
		table.sort(typnames)
		for i,typname in ipairs(typnames) do
			print('| `'..typname..'` | ',tostring(nwc.txt[typname]),' |')
		end
	elseif userAction == 'nwctxt_list' then
		local out = {}		
		for i,v in pairs(nwc.txt) do
			local l = string.gsub(tostring(v),",","','")
			table.insert(out,string.format("%s\t= {'%s'},",i,l))
		end
		print(table.concat(out,"\n"))
	elseif userAction == 'nwctxt_apilist' then
		outAPIList('nwc.txt',nwc.txt)
	elseif userAction == 'nwcutlib_list' then
		local pkgs = nwcut.buildEnv()

		for nm,t in pairs(pkgs) do
			local t2 = false

			if nm == 'nwcFile' then t2 = score
			elseif nm == 'nwcStaff' then t2 = score.Staff[1]
			elseif nm == 'nwcItem' then t2 = score.Staff[1].Items[1]
			elseif nm == 'nwcPlayContext' then t2 = t.new()
			--StringBuilder
			--nwcNotePos
			--nwcNotePosList
			--nwcOptGroup
			--nwcOptList
			--nwcOptText
			end

			outAPIList(nm,t2 or t)
		end
		
		outAPIList('nwc.txt',nwc.txt)
	end

	return
end

--------------------------------------------------------------------
-- Plugin runtime code below here
-- our object type is passed into the script
local userObjTypeName = ...

local function doPluginList(t)
	local flist = {}
	local function outproc(s) flist[#flist+1] = s end
	local function flistContains(s) for k,v in ipairs(flist) do if v:find(s,1,true) then return k end end end
	
	outAPIList('nwc',nwc,true,outproc)
	outAPIList('nwc.ntnidx',nwc.ntnidx,true,outproc)
	outAPIList('nwc.drawpos',nwc.drawpos,true,outproc)
	outAPIList('nwc.toolbox',nwc.toolbox,true,outproc)
	outAPIList('nwcdraw',nwcdraw,true,outproc)
	outAPIList('nwcplay',nwcplay,true,outproc)
	outAPIList('nwcui',nwcui,true,outproc)
	
	-- remove the inherited methods
	for k,v in pairs(nwc.drawpos) do
		if (type(v) == 'function') and (nwc.ntnidx[k] == v) then
			
			if nwc.ntnidx[k] == v then
				local killidx = flistContains('nwc.drawpos.'..k)
				table.remove(flist,killidx)
			end
		end
	end
	
	local ss = table.concat(flist,'\n')
	nwcui.prompt('Here is the generated TSV','_',ss)
end

local function doInheritList(t)
	local flist = {}
	
	for k,v in pairs(nwc.drawpos) do
		if type(v) == 'function' then
			if nwc.ntnidx[k] == v then
				flist[#flist+1] = k
			end
		end
	end
	
	table.sort(flist)
	local ss = table.concat(flist,'\n')
	nwcui.prompt('Inherited drawpos functions include','_',ss)
end

local function doMarkdown_nwctxt()
	local l = {}
	
	l[#l+1] = '| nwc.txt | Contains |'
	l[#l+1] = '|:--------:|:---------|'
	local typnames = {}
	for typname in pairs(nwc.txt) do table.insert(typnames,typname) end
	table.sort(typnames)
	for i,typname in ipairs(typnames) do
		l[#l+1] = '| `'..typname..'` | '..tostring(nwc.txt[typname])..' |'
	end
	local ss = table.concat(l,'\n')
	nwcui.prompt('nwc.txt Markdown','_',ss)
end	

local objMenu = {
	{type='command',name='Plugin API List...',checkmark=false,disable=false,data=doPluginList},
	{type='command',name='Show drawpos inherited methods...',checkmark=false,disable=false,data=doInheritList},
	{type='command',name='Show nwc.txt contents in markdown...',checkmark=false,disable=false,data=doMarkdown_nwctxt},
	}

local function objMenuClick(t,menu,choice)
	local m = objMenu[menu]

	if m and m.data then
		m.data(t)
	end
end

local function objDraw() return nwc.toolbox.drawStaffSigLabel('apiGen') end

--------------------------------------------------------------------
return {
	nwcut	= {utnwctxt_markdown='clip',nwctxt_list='clip',nwctxt_apilist='clip',nwcutlib_list='clip'},
	create	= false,
	draw	= objDraw,
	width	= objDraw,
	menu	= objMenu,
	menuClick  = objMenuClick,
	}
