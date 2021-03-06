
local addon = LibStub("AceAddon-3.0"):NewAddon("SoundMapper", "AceConsole-3.0")

local SoundMapperLDB = LibStub("LibDataBroker-1.1"):NewDataObject("SoundMapper!", {
    type = "data source",
    text = "SoundMapper!",
    icon = "Interface\\Icons\\spell_holy_circleofrenewal",
	OnTooltipShow = function(tooltip)
		local c="Sound_OutputDriverIndex"
		local m=GetCVar(c)
		local n=Sound_GameSystem_GetNumOutputDrivers()
		local t=Sound_GameSystem_GetOutputDriverNameByIndex(m)
		tooltip:SetText("SoundMapper")
		tooltip:AddLine("|cff0000ff"..t.."|r")
		tooltip:AddLine(" ")
		tooltip:AddLine("|cffddff00Left Click|r |cff00ff00= Toggle Audio Interfaces|r")
		tooltip:AddLine("|cffddff00Right Click|r |cff00ff00= Configure|r")
	end,
    OnClick = function(a,b)
		if b == "LeftButton" then
			addon:switchOutputDriver()
		elseif b == "RightButton" then
			addon:SoundMapperConfig()
		end
	end,
})
local icon = LibStub("LibDBIcon-1.0")

function formatText(t,c)
	if c == nil then
		return(t)
	end
	return("|cff"..c..t.."|r")
end

function pChat(t,c)
	print(formatText("["..addon.name.."]","00ff00"),formatText(t,c))
end

function addon:switchOutputDriver()
	local devlist={}
	local activeDrivers=0
	local totalDrivers=Sound_GameSystem_GetNumOutputDrivers()
	for i=1,totalDrivers do
		local d=Sound_GameSystem_GetOutputDriverNameByIndex(i)
		if d == 'None' then d = 'System Default' end
		n=_cleanDevName(d)
		devlist[i]={}
		devlist[i].name=n
		devlist[i].active=self.db.global.devlist[n]
		if devlist[i].active then activeDrivers = activeDrivers + 1 end
		devlist[i].desc=d
	end
	if activeDrivers == 0 then
		pChat("No eligible devices selected in configuration","dc322f")
		 return
	end

	local cVar="Sound_OutputDriverIndex"
	local curIndex=tonumber(GetCVar(cVar))
	local lastIndex=curIndex
	repeat
		curIndex = curIndex + 1
		if curIndex > totalDrivers then curIndex = 1 end
	until (devlist[curIndex].active == true)

	if lastIndex == curIndex then
		pChat("No change was made","b58900")
		return
	end
	SetCVar(cVar,curIndex)
	AudioOptionsFrame_AudioRestart()
	pChat('Output Device set to '..formatText(devlist[curIndex].name,"268bd2"))

end

function _cleanDevName(name)
	if string.find(name,'[(]') then
		name=string.match(name,"^(.-)[(].*$")
	end
	return name:match "^%s*(.-)%s*$"
end

function addon:getDeviceSelectedState(info)
	--print(info.option.name,':',self.db.global.devlist[info.option.name])
	return(self.db.global.devlist[info.option.name])
end

function addon:setDeviceSelectedState(info,val)
	self.db.global.devlist[info.option.name]=val
end

function addon:OnInitialize()
	local defaults = {
		profile = {
			minimap = {
				hide = false,
			},
			devlist = {},
		},
		global = {
			devlist = {},
		}
	}
	local options = {
		name = "SoundMapper",
		handler = addon,
		type = 'group',
		args = {
			minimap_icon = {
				name = "Show Minimap Icon",
				desc = "Show/Hide minimap Icon",
				type = "toggle",
				set = function(info,val) addon:SetIconHidden(not val) end,
				get = function(info) return not addon:IsIconHidden() end
			},
			device_list = {
				name = "Sound Devices",
				desc = "Check the devices you want to cycle through when toggling devices",
				type = "group",
				args = {}
			}
		},
	}
	for i=1,Sound_GameSystem_GetNumOutputDrivers() do
		local dev = Sound_GameSystem_GetOutputDriverNameByIndex(i)
		if dev == "None" then
			dev = "System Default"
		end
		options.args.device_list.args["dev"..i]={
			name = _cleanDevName(dev),
			desc = dev,
			type = "toggle",
			width = "full",
			get = function(info) return(addon:getDeviceSelectedState(info)) end,
			set = function(info,val) addon:setDeviceSelectedState(info,val) end
		}
	end

		-- Obviously you'll need a ## SavedVariables: SoundMapperDB line in your TOC, duh!
	self.db = LibStub("AceDB-3.0"):New("SoundMapperDB",defaults,true)

	for k,v in pairs(options.args.device_list.args) do
		local d=options.args.device_list.args[k].name
		--print ('-->'..d)
		if  self.db.global.devlist[d] == nil then
			self.db.global.devlist[d] = true
		end
	end
	LibStub("AceConfig-3.0"):RegisterOptionsTable("SoundMapper", options)
    icon:Register("SoundMapper!", SoundMapperLDB, self.db.profile.minimap)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SoundMapper", "SoundMapper")
    self:RegisterChatCommand("sm", "smCommand")
end
 
 function addon:SoundMapperConfig()
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
 end
 
 function SoundMapperHelp()
	print("Sound Mapper Options")
	print("  help - this message")
	print("  show - show minimap button")
	print("  hide - hide minimap button")
	print("  config - open configuration dialog")
end

function addon:SetIconHidden(state)
	self.db.profile.minimap.hide=state
	if state then
        icon:Hide("SoundMapper!")
	else
        icon:Show("SoundMapper!")
	end
end
 
function addon:IsIconHidden()
	if self.db.profile.minimap.hide == nil then
		return false
	elseif self.db.profile.minimap.hide == false then
		return false
	end
	return true
end

function addon:smCommand(args)
    local cmd=string.lower(args)
	if cmd == "hide" then
		addon:SetIconHidden(true)
    elseif cmd == "show" then
		addon:SetIconHidden(false)
	elseif cmd == "config" then
		addon:SoundMapperConfig()
	else
		SoundMapperHelp()
    end
end