
Healium_Debug = false
local AddonVersion = "|cFFFFFF00 1.0.2|r"
local GetSpellCooldown = GetSpellCooldown

local GetSpellBookItemName = GetSpellBookItemName
local IsUsableSpell    = IsUsableSpell
local SpellHasRange    = SpellHasRange
local IsSpellInRange   = IsSpellInRange
local GetSpellInfo     = GetSpellInfo
local BOOKTYPE_SPELL   = BOOKTYPE_SPELL
local LowHP = 0.6
local VeryLowHP = 0.3
local DefaultButtonCount = 5
local wipe = wipe
local UnitExists = UnitExists
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local InCombatLockdown = InCombatLockdown
local pairs = pairs
local ipairs = ipairs
local math_max = math.max
local math_min = math.min
local math_floor = math.floor
local ActivatePrimarySpecSpellName = GetSpellInfo(63645)
local ActivateSecondarySpecSpellName = GetSpellInfo(63644)
Healium = {
  Scale = 1.0,
  ShowToolTips = true,
  ShowPercentage = true,
  UseClassColors = false,
  ShowPartyFrame = true,
  ShowGroupFrames = { },
  HideCloseButton = false,
  HideCaptions = false,
  LockFrames = false,
  EnableDebufs = true,
  EnableDebufHealthbarHighlighting = true,
  EnableDebufButtonHighlighting = true,
  EnableDebufHealthbarColoring = false,
  ShowMana = true,
}

Healium_MaxButtons = 15
Healium_AddonName = "Healium"
Healium_AddonColor = "|cFF55AAFF"
Healium_AddonColoredName = Healium_AddonColor .. Healium_AddonName .. "|r"
Healium_Units = { }
Healium_Frames = { }
Healium_ShownFrames = { }
Healium_ButtonIDs = { }

local HealiumFrame = nil

function Healium_Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(Healium_AddonColor .. Healium_AddonName .. "|r " .. tostring(msg))		
end

function Healium_DebugPrint(msg)
	if (Healium_Debug) then
		Healium_Print("Debug: " .. tostring(msg))		
	end
end

function Healium_Warn(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|CFFFF0000Warning|r: " .. tostring(msg))		
end
local _profileCache = {}
local function CreateDefaultProfile()
	return {
		ButtonCount    = DefaultButtonCount,
		SpellNames     = {},
		SpellIcons     = {},
		SpellNamesHash = {},
	}
end

function Healium_GetProfile()
	local key = GetActiveTalentGroup()
	if not _profileCache[key] then
		local saved = Healium.Profiles and Healium.Profiles[key]
		if saved then
			_profileCache[key] = saved
		else
			_profileCache[key] = CreateDefaultProfile()
			Healium_DebugPrint("GetProfile: no saved profile for talent group " .. tostring(key) .. ", using default")
		end
	end
	return _profileCache[key]
end
local function Healium_InvalidateProfileCache()
	_profileCache = {}
end

function Healium_OnLoad(self)
	HealiumFrame = self
 	Healium_Print(AddonVersion.." |cFF00FF00Loaded|r")

	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("SPELLS_CHANGED")
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_SPELLCAST_SENT")	
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("RAID_TARGET_UPDATE")
end

function Healium_UpdatePercentageVisibility()
	for _, k in ipairs(Healium_Frames) do
		k.HPText:SetShown(Healium.ShowPercentage)
	end
end
local function UpdateHealthBar(HPPercent, frame)
	if (HPPercent < VeryLowHP) then
		frame.HealthBar:SetStatusBarColor(1,0,0,1) 
	elseif (HPPercent < LowHP) then 
		frame.HealthBar:SetStatusBarColor(1,0.9,0,1) 
	else
		frame.HealthBar:SetStatusBarColor(0,1,0,1) 
	end
end

function Healium_UpdateClassColors()
	for _, k in ipairs(Healium_Frames) do
		if k.TargetUnit and UnitExists(k.TargetUnit) then
			if Healium.UseClassColors then
				local class = select(2, UnitClass(k.TargetUnit)) or "WARRIOR"
				local color = RAID_CLASS_COLORS[class]
				k.HealthBar:SetStatusBarColor(color.r, color.g, color.b)
			else
				local Health = UnitHealth(k.TargetUnit)
				local MaxHealth = math.max(1, UnitHealthMax(k.TargetUnit))
				UpdateHealthBar(Health / MaxHealth, k)
			end
		end
	end
end

function Healium_UpdateUnitHealth(UnitName, NamePlate)
	if not NamePlate or not UnitExists(UnitName) then return end

	local Health    = UnitHealth(UnitName)
	local MaxHealth = math.max(1, UnitHealthMax(UnitName))
	local isDead    = UnitIsDeadOrGhost(UnitName)

	local HPPercent = isDead and 0 or math_max(0, math_min(1, Health / MaxHealth))
	NamePlate.HPText:SetText(isDead and "dead" or math_floor(HPPercent * 100) .. "%")

	NamePlate.HealthBar:SetMinMaxValues(0, MaxHealth)
	NamePlate.HealthBar:SetValue(isDead and 0 or Health)

	if Healium.EnableDebufs and Healium.EnableDebufHealthbarColoring and NamePlate.hasDebuf then
		NamePlate.HealthBar:SetStatusBarColor(NamePlate.debuffColor.r, NamePlate.debuffColor.g, NamePlate.debuffColor.b)
	elseif Healium.UseClassColors then
		local class = select(2, UnitClass(UnitName)) or "WARRIOR"
		local color = RAID_CLASS_COLORS[class]
		NamePlate.HealthBar:SetStatusBarColor(color.r, color.g, color.b)
	else
		UpdateHealthBar(HPPercent, NamePlate)
	end
end

function Healium_UpdateUnitMana(UnitName, NamePlate)
	if not NamePlate or not UnitExists(UnitName) or not NamePlate.showMana then return end

	local MaxMana = math.max(1, UnitPowerMax(UnitName, SPELL_POWER_MANA))
	local Mana = UnitIsDeadOrGhost(UnitName) and 0 or UnitPower(UnitName, SPELL_POWER_MANA)

	NamePlate.ManaBar:SetMinMaxValues(0,MaxMana)
	NamePlate.ManaBar:SetValue(Mana)
end

function Healium_UpdateShowMana()
	if Healium.ShowMana then
		HealiumFrame:RegisterEvent("UNIT_MANA")
		HealiumFrame:RegisterEvent("UNIT_DISPLAYPOWER")		
	else
		HealiumFrame:UnregisterEvent("UNIT_MANA")	
		HealiumFrame:UnregisterEvent("UNIT_DISPLAYPOWER")				
	end

	for _, k in ipairs(Healium_Frames) do
		if (k.TargetUnit) then
			HealiumUnitFrames_CheckPowerType(k.TargetUnit, k)
			Healium_UpdateUnitMana(k.TargetUnit, k)
		end

		if InCombatLockdown() then
			k.fixShowMana = true
		else
			Healium_UpdateManaBarVisibility(k)
		end
	end
end

function Healium_UpdateManaBarVisibility(frame)
	if Healium.ShowMana then
		frame.ManaBar:Show()
		frame.HealthBar:SetWidth(111)
		frame.HealthBar:SetPoint("TOPLEFT", 7, -2)
	else
		frame.ManaBar:Hide()
		frame.HealthBar:SetWidth(116)			
		frame.HealthBar:SetPoint("TOPLEFT", 2, -2)				
	end		

	Healium_UpdateUnitHealth(frame.TargetUnit, frame)
end

function Healium_UpdateShowBuffs()
	HealiumFrame:RegisterEvent("UNIT_AURA")

	for _, k in pairs(Healium_ShownFrames) do
		if (k.TargetUnit) then
			Healium_UpdateUnitBuffs(k.TargetUnit, k)
		end
	end	
end

local SpellCache = nil

local function BuildSpellCache()
	SpellCache = {}
	for i = 1, 500 do
		local spellName, spellRank = GetSpellBookItemName(i, BOOKTYPE_SPELL)
		if not spellName then break end
		SpellCache[spellName] = { id = i, rank = spellRank }
	end
end

local function GetSpellID(spell)
	if not SpellCache then
		BuildSpellCache()
	end
	local item = SpellCache[spell]
	if item then
		return item.id, item.rank
	end
	return nil, nil
end
local function Healium_UpdateSpells()
	SpellCache = nil
	Healium_UpdateButtonSpells()
end
function Healium_UpdateButtonCooldownsByColumn(column)
	if Healium_ButtonIDs[column] then
		local start, duration, enable = GetSpellCooldown(Healium_ButtonIDs[column], BOOKTYPE_SPELL)

		for frame, _ in pairs(Healium_ShownFrames) do
			local button = frame.buttons[column]
			if button and button:IsShown() then 
				CooldownFrame_SetTimer(button.cooldown, start, duration, enable)
			end
		end
	end
end

local function Healium_UpdateButtonCooldowns()
	local count = Healium_GetProfile().ButtonCount

	for i = 1, count do
		Healium_UpdateButtonCooldownsByColumn(i)
	end
end

function Healium_UpdateButtonIcon(button, texture)
	if InCombatLockdown() then
		return
	end

	if (texture) then
		button.icon:SetTexture(texture)
	else
		button.icon:SetTexture("Interface/Icons/INV_Misc_QuestionMark")
	end		
end

function Healium_UpdateButtonIcons()
	if InCombatLockdown() then
		return
	end

	local Profile = Healium_GetProfile()
	for i = 1, Healium_MaxButtons do
		local texture = Profile.SpellIcons[i]
		for _, k in ipairs(Healium_Frames) do
			local button = k.buttons[i]
			if button then
				Healium_UpdateButtonIcon(button, texture)
			end
		end
	end
end

function Healium_UpdateButtonSpell(button, spell, id, checkforCombat)

	local oldspell = button:GetAttribute("spell")
	local oldid = button.id

	if (oldspell == spell) and (oldid == id) then
		return 
	end

	if checkforCombat then 
		if InCombatLockdown() then
			return
		end
	end

	button.id = id
	button:SetAttribute("spell", spell)
end

function Healium_UpdateButtonSpells()
	local Profile = Healium_GetProfile()

	if Profile.SpellNamesHash then
		wipe(Profile.SpellNamesHash)
	else
		Profile.SpellNamesHash = {}
	end

	for i = 1, Healium_MaxButtons do
		local spell = Profile.SpellNames[i]
		local id

		if spell and spell ~= "" then
			Profile.SpellNamesHash[spell] = true
			id = GetSpellID(spell)
		end

		Healium_ButtonIDs[i] = id

		for _, k in ipairs(Healium_Frames) do
			local button = k.buttons[i]
			if button then
				Healium_UpdateButtonSpell(button, spell, id, true)
			end
		end
	end

	Healium_UpdateCures()
end

local function UpdateButtonVisibility(frame)
	if InCombatLockdown() then
		return
	end
	for i = 1, Healium_MaxButtons do
		local button = frame.buttons[i]
		if button then
			button:Hide()
		end
	end
	local count = Healium_GetProfile().ButtonCount
	for i = 1, count do
		local button = frame.buttons[i]
		if button then
			button:Show()
		end
	end
end

function Healium_UpdateButtonVisibility()
	if InCombatLockdown() then
		return
	end

	for _,k in ipairs(Healium_Frames) do
		UpdateButtonVisibility(k)
	end
end
function Healium_UpdateButtons()
	if InCombatLockdown() then return end

	local Profile = Healium_GetProfile()
	local count   = Profile.ButtonCount

	for _, k in ipairs(Healium_Frames) do
		for i = 1, Healium_MaxButtons do
			local btn = k.buttons[i]
			if btn then
				if i <= count then btn:Show() else btn:Hide() end
				Healium_UpdateButtonSpell(btn, Profile.SpellNames[i], Healium_ButtonIDs[i], true)
				Healium_UpdateButtonIcon(btn, Profile.SpellIcons[i])
			end
		end
	end
	Healium_UpdateButtonSpells()
end

function Healium_RangeCheckButton(button, targetUnit)
	local id = button.id
	if id then
		local bookType = BOOKTYPE_SPELL
		local isUsable, noMana = IsUsableSpell(id, bookType)

		if isUsable then
			button.icon:SetVertexColor(1.0, 1.0, 1.0)
		elseif noMana then
			button.icon:SetVertexColor(0.5, 0.5, 1.0)
		else
			button.icon:SetVertexColor(0.3, 0.3, 0.3)
		end

		if SpellHasRange(id, bookType) then
			local inRange = IsSpellInRange(id, bookType, targetUnit)
			if (inRange == 0) or (inRange == nil) then
				button.icon:SetVertexColor(1.0, 0.3, 0.3)
			end
		end
	end
end

local function CopyFlatTable(src)
	local dest = {}
	if src then
		for k, v in pairs(src) do
			dest[k] = v
		end
	end
	return dest
end
local function InitVariables()
	local H = Healium
	if H.ShowGroupFrames == nil then H.ShowGroupFrames = {} end

	local DEFAULTS = {
		ShowToolTips                     = true,
		ShowMana                         = true,
		ShowPercentage                   = true,
		UseClassColors                   = false,
		ShowPartyFrame                   = true,
		HideCloseButton                  = false,
		HideCaptions                     = false,
		LockFrames                       = false,
		EnableDebufs                     = true,
		EnableDebufHealthbarHighlighting = true,
		EnableDebufButtonHighlighting    = true,
		EnableDebufHealthbarColoring     = false,
	}
	for key, default in pairs(DEFAULTS) do
		if H[key] == nil then H[key] = default end
	end
	if H.Profiles == nil then
		if HealiumDropDownButton ~= nil and HealiumDropDownButtonIcon ~= nil and H.ButtonCount ~= nil then
			Healium_Print("Importing button profiles.")
			Healium_Print(Healium_AddonColor .. Healium_AddonName .. "|r now has separate button configurations for each talent specialization.")
			Healium_Print("Both " .. Healium_AddonColor .. Healium_AddonName .. "|r button configurations will be set to your current button configuration.")
			H.Profiles = {
				[1] = { ButtonCount = H.ButtonCount, SpellNames = CopyFlatTable(HealiumDropDownButton), SpellIcons = CopyFlatTable(HealiumDropDownButtonIcon), SpellNamesHash = {} },
				[2] = { ButtonCount = H.ButtonCount, SpellNames = CopyFlatTable(HealiumDropDownButton), SpellIcons = CopyFlatTable(HealiumDropDownButtonIcon), SpellNamesHash = {} },
			}
		else
			H.Profiles = {}
		end
	end

	if type(H.Profiles[1]) ~= "table" then H.Profiles[1] = CreateDefaultProfile() end
	if type(H.Profiles[2]) ~= "table" then H.Profiles[2] = CreateDefaultProfile() end
	HealiumDropDownButton    = nil
	HealiumDropDownButtonIcon = nil
end

local EventHandlers = {}
local function ForEachUnitFrame(unitName, callback)
	if Healium_Units[unitName] then
		for frame in pairs(Healium_Units[unitName]) do
			callback(unitName, frame)
		end
	end
end

function EventHandlers.UNIT_HEALTH(_, arg1)
	ForEachUnitFrame(arg1, Healium_UpdateUnitHealth)
end

function EventHandlers.UNIT_MANA(_, arg1)
	ForEachUnitFrame(arg1, Healium_UpdateUnitMana)
end

function EventHandlers.UNIT_AURA(_, arg1)
	ForEachUnitFrame(arg1, Healium_UpdateUnitBuffs)
end

function EventHandlers.SPELL_UPDATE_COOLDOWN(self, ...)
	Healium_UpdateButtonCooldowns()
end

function EventHandlers.PLAYER_REGEN_ENABLED(self, ...)
	if self.pendingTalentUpdate then
		Healium_InvalidateProfileCache()
		Healium_UpdateSpells()
		Healium_UpdateButtons()
		Healium_Update_ConfigPanel()
		self.pendingTalentUpdate = nil
	end

	for _,v in ipairs(Healium_Frames) do
		if v.fixCreateButtons then 
			if (not Healium.ShowPercentage) then v.HPText:Hide() end		
			Healium_CreateButtonsForNameplate(v)
			UpdateButtonVisibility(v)
			v.fixCreateButtons = nil
		end

		if v.fixShowMana then
			Healium_UpdateManaBarVisibility(v)
			v.fixShowMana = nil
		end
	end
end

function EventHandlers.ADDON_LOADED(self, arg1, ...)
	if string.lower(arg1) == string.lower(Healium_AddonName) then
		Healium_DebugPrint("ADDON_LOADED")  	

		InitVariables()
		Healium_InvalidateProfileCache()
		Healium_InitSpells() 		
		Healium_CreateConfigPanel()
		Healium_InitMenu()		
		Healium_CreateUnitFrames()
		Healium_SetScale()		
		Healium_UpdatePercentageVisibility()		
		Healium_UpdateClassColors()
		Healium_ShowHidePartyFrame()
		Healium_UpdateShowMana()
		Healium_UpdateShowBuffs()

		for i = 1, 8 do
			Healium_ShowHideGroupFrame(i)
		end

		Healium_UpdateButtons()		
	end
end

function EventHandlers.UNIT_SPELLCAST_SENT(self, arg1, arg2, ...)
	if (arg2 == ActivatePrimarySpecSpellName) or (arg2 == ActivateSecondarySpecSpellName) then
		self.Respecing = true
	end
end

local function ClearRespecingIfPlayer(self, arg1, arg2)
	if arg1 == "player" and (arg2 == ActivatePrimarySpecSpellName or arg2 == ActivateSecondarySpecSpellName) then
		self.Respecing = nil
	end
end
EventHandlers.UNIT_SPELLCAST_INTERRUPTED = ClearRespecingIfPlayer
EventHandlers.UNIT_SPELLCAST_SUCCEEDED   = ClearRespecingIfPlayer

function EventHandlers.PLAYER_TALENT_UPDATE(self, ...)
	Healium_DebugPrint("PLAYER_TALENT_UPDATE")
	self.Respecing = nil
	Healium_InvalidateProfileCache()

	if InCombatLockdown() then
		self.pendingTalentUpdate = true
		Healium_Warn("Spec change detected in combat. Buttons will update after combat ends.")
	else
		Healium_UpdateSpells()
		Healium_UpdateButtons()
		Healium_Update_ConfigPanel()
	end
end

function EventHandlers.SPELLS_CHANGED(self, ...)
	if not self.Respecing then
		Healium_DebugPrint("SPELLS_CHANGED")
		Healium_UpdateSpells()
	end
end

function EventHandlers.PLAYER_ENTERING_WORLD(self, ...)
	if not self.Respecing then
		Healium_DebugPrint("PLAYER_ENTERING_WORLD")
		Healium_UpdateSpells()
	end
end

function EventHandlers.UNIT_DISPLAYPOWER(_, arg1)
	ForEachUnitFrame(arg1, HealiumUnitFrames_CheckPowerType)
end

function EventHandlers.RAID_TARGET_UPDATE(self, ...)
	for _, k in ipairs(Healium_Frames) do
		local unit = k.TargetUnit
		if unit and UnitExists(unit) then
			local index = GetRaidTargetIndex(unit)
			if index then
				SetRaidTargetIconTexture(k.raidTargetIcon, index)
				k.raidTargetIcon:Show()
			else
				k.raidTargetIcon:Hide()
			end
		end
	end
end

function Healium_OnEvent(self, event, ...)
	if EventHandlers[event] then
		EventHandlers[event](self, ...)
	end
end
local RangeCheckTimer   = 0
local RangeCheckFrames  = nil
local RangeCheckPageIdx = 0
local RangeCheckPageSize = 8

function Healium_OnUpdate(self, elapsed)
	if not Healium then return end
	RangeCheckTimer = RangeCheckTimer + elapsed
	if RangeCheckTimer < 0.5 then return end
	RangeCheckTimer = 0

	local Profile = Healium_GetProfile()
	if not Profile or not Profile.ButtonCount then return end
	local buttonCount = Profile.ButtonCount

	if not RangeCheckFrames or RangeCheckPageIdx >= #RangeCheckFrames then
		RangeCheckFrames = RangeCheckFrames or {}
		wipe(RangeCheckFrames)
		local count = 0
		for frame in pairs(Healium_ShownFrames) do
			count = count + 1
			RangeCheckFrames[count] = frame
		end
		RangeCheckPageIdx = 0
	end

	local last = math_min(RangeCheckPageIdx + RangeCheckPageSize, #RangeCheckFrames)
	for i = RangeCheckPageIdx + 1, last do
		local frame = RangeCheckFrames[i]
		if frame and frame.TargetUnit
			and UnitIsVisible(frame.TargetUnit)
			and not UnitIsDeadOrGhost(frame.TargetUnit) then
			for j = 1, buttonCount do
				local button = frame.buttons[j]
				if button and button:IsShown() then
					Healium_RangeCheckButton(button, frame.TargetUnit)
				end
			end
		end
	end
	RangeCheckPageIdx = last
end
