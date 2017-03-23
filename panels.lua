--[[
	panels.lua
		Configuration panels
--]]

local CONFIG, Config = ...
local ADDON = GetAddOnMetadata(CONFIG, 'X-Dependencies')
local L = LibStub('AceLocale-3.0'):GetLocale(CONFIG)
local Addon = _G[ADDON]

local SLOT_COLOR_TYPES = {}
for id, name in pairs(Addon.BAG_TYPES) do
	tinsert(SLOT_COLOR_TYPES, name)
end

sort(SLOT_COLOR_TYPES)
tinsert(SLOT_COLOR_TYPES, 1, 'normal')

local SetProfile = function(profile)
	Addon:SetProfile(profile)
	Addon.profile = Addon:GetProfile()
	Addon:UpdateFrames()
	Addon.GeneralOptions:Update()
end

StaticPopupDialogs[CONFIG .. '_ConfirmGlobals'] = {
	text = 'Are you sure you want to disable specific settings for this character? All specific settings will be lost.',
	OnAccept = function() SetProfile(nil) end,
	whileDead = 1, exclusive = 1, hideOnEscape = 1,
	button1 = YES, button2 = NO,
	timeout = 0,
}


--[[ Panels ]]--

Addon.GeneralOptions = Addon.Options:NewPanel(nil, ADDON, L.GeneralDesc, function(self)
	self:CreateCheck('locked')
	self:CreateCheck('tipCount')
	self:CreateCheck('flashFind')

	if Config.fading then
		self:CreateCheck('fading')
	end
	
	self:CreateCheck('displayBlizzard', ReloadUI)

	local global = self:Create('Check')
	global:SetLabel(L.CharacterSpecific)
	global:SetValue(Addon:GetSpecificProfile())
	global:SetCall('OnInput', function(_, v)
		if Addon:GetSpecificProfile() then
			StaticPopup_Show(CONFIG .. '_ConfirmGlobals')	
		else
			SetProfile(CopyTable(Addon.sets.global))
		end
	end)
end)

Addon.FrameOptions = Addon.Options:NewPanel(ADDON, L.FrameSettings, L.FrameSettingsDesc, function(self)
	local frames = self:Create('Dropdown')
	frames:SetLabel(L.Frame)
	frames:SetValue(self.frameID)
	frames:AddLine('inventory', INVENTORY_TOOLTIP)
	frames:AddLine('bank', BANK)
	frames:SetCall('OnInput', function(_, v)
		self.frameID = v
	end)
	
	if GetAddOnEnableState(UnitName('player'), ADDON .. '_GuildBank') >= 2 then
		frames:AddLine('guild', GUILD_BANK)
	end
	
	if GetAddOnEnableState(UnitName('player'), ADDON .. '_VoidStorage') >= 2 then
		frames:AddLine('vault', VOID_STORAGE)
	end

	self.sets = Addon.profile[self.frameID]
	self:CreateCheck('enabled'):SetDisabled(self.frameID ~= 'inventory' and self.frameID ~= 'bank')

	if self.sets.enabled then
		self:CreateCheck('actPanel')

		-- Display
		self:CreateHeader(DISPLAY, 'GameFontHighlight', true)
		self:CreateRow(Config.displayRowHeight, function(row)
			if Config.components then
				if self.frameID ~= 'guild' then
					row:CreateCheck('bagFrame')
					row:CreateCheck('sort')
				end
				
				row:CreateCheck('search')
				row:CreateCheck('options')
				row:CreateCheck('broker')

				if self.frameID ~= 'vault' then
					row:CreateCheck('money')
				end
			end

			if Config.tabs then
				row:CreateCheck('leftTabs')
			end
		end)

		-- Appearance
		self:CreateHeader(L.Appearance, 'GameFontHighlight', true)
		self:CreateRow(70, function(row)
			if Config.colors then
				row:CreateColor('color')
				row:CreateColor('borderColor')
			end

			row:CreateCheck('reverseBags')
			row:CreateCheck('reverseSlots')
			row:CreateCheck('bagBreak')

			if self.frameID == 'bank' then
				row:CreateCheck('exclusiveReagent')
			end
		end)

		self:CreateRow(162, function(row)
			row:CreateDropdown('strata', 'LOW',LOW, 'MEDIUM',AUCTION_TIME_LEFT2, 'HIGH',HIGH)
			row:CreatePercentSlider('alpha', 1, 100)
			row:CreatePercentSlider('scale', 20, 300):SetCall('OnInput', function(self,v)
				local new = v/100
				local old = self.sets.scale
				local ratio = new / old

				self.sets.x =  self.sets.x / ratio
				self.sets.y =  self.sets.y / ratio
				self.sets.scale = new
				Addon:UpdateFrames()
			end)

			row:Break()
			row:CreatePercentSlider('itemScale', 20, 200)
			row:CreateSlider('spacing', -15, 15)

			if Config.columns then
				row:CreateSlider('columns', 1, 50)
			end
		end).bottom = -50
	end
end)

Addon.DisplayOptions = Addon.Options:NewPanel(ADDON, L.DisplaySettings, L.DisplaySettingsDesc, function(self)
	self:CreateHeader(L.DisplayInventory, 'GameFontHighlight', true)
	for i, event in ipairs {'Bank', 'Auction', 'Guildbank', 'Mail', 'Player', 'Trade', 'Gems', 'Craft'} do
		self:CreateCheck('display' .. event)
	end

	self:CreateHeader(L.CloseInventory, 'GameFontHighlight', true)
	for i, event in ipairs {'Bank', 'Combat', 'Vehicle', 'Vendor'} do
		self:CreateCheck('close' .. event)
	end
end)

Addon.ColorOptions = Addon.Options:NewPanel(ADDON, L.ColorSettings, L.ColorSettingsDesc, function(self)
	self:CreateCheck('glowQuality')
	self:CreateCheck('glowNew')
	self:CreateCheck('glowQuest')
	self:CreateCheck('glowUnusable')
	self:CreateCheck('glowSets')
	self:CreateCheck('emptySlots')
	self:CreateCheck('colorSlots').bottom = 11

	if self.sets.colorSlots then
		self:CreateRow(140, function(self)
			for i, name in ipairs(SLOT_COLOR_TYPES) do
				self:CreateColor(name .. 'Color').right = 144
			end
		end)
	end

	self:CreatePercentSlider('glowAlpha', 1, 100):SetWidth(585)
end)