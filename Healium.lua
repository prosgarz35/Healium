-- Healium
--
-- Programming notes
-- WARNING In LUA all logical operators consider false and nil as false and anything else as true.  This means not 0 is false!!!!!!!!
-- Color control characters |CAARRGGBB  then |r resets to normal, where AA == Alpha, RR = Red, GG = Green, BB = blue

Healium_Debug = false
local AddonVersion = "|cFFFFFF00 1.0.2|r"

-- fast locals for hot paths
local GetSpellCooldown = GetSpellCooldown
local GetSpellTexture  = GetSpellTexture
local GetSpellBookItemName = GetSpellBookItemName
local IsUsableSpell    = IsUsableSpell
local SpellHasRange    = SpellHasRange
local IsSpellInRange   = IsSpellInRange
local GetSpellInfo     = GetSpellInfo
local BOOKTYPE_SPELL   = BOOKTYPE_SPELL

-- Constants
local LowHP = 0.6
local VeryLowHP = 0.3
local _, HealiumClass = UnitClass("player")
local _, HealiumRace = UnitRace("player")

local DefaultButtonCount = 5

-- locale safe versions of respeccing spell names
local ActivatePrimarySpecSpellName = GetSpellInfo(63645)
local ActivateSecondarySpecSpellName = GetSpellInfo(63644) 

-- Healium holds per character settings
Healium = {
  Scale = 1.0,									-- Scale of frames
  ShowToolTips = true,							-- Whether or not to display a tooltip for the spell when hovering over buttons
  ShowPercentage = true,						-- Whether or not to display the health percentage
  UseClassColors = false,						-- Whether or not to color the healthbar the color of the class instead of green/yellow/red
  ShowPartyFrame = true,						-- Whether or not to show the party frame
  ShowGroupFrames = { },  						-- Whether or not to show individual group frame
  HideCloseButton = false,						-- Whether or not to hide the close (X) button, to prevent accidental closing of the Healium Frame
  HideCaptions = false,							-- Whether or not to hide the caption when the mouse leaves the caption area
  LockFrames = false,							-- Whether or not to prevent dragging of the frame
  EnableDebufs = true,							-- Debuff warning system: always enabled
  EnableDebufHealthbarHighlighting = true,		-- Healthbar highlight on debuff: always enabled
  EnableDebufButtonHighlighting = true,			-- Button highlight on debuff: always enabled
  EnableDebufHealthbarColoring = false,			-- Healthbar coloring on debuff: disabled by default
  ShowMana = true,								-- Whether or not to show mana
}

-- HealiumGlobal is the variable that holds all Heliuam settings that are not character specific
HealiumGlobal = {
}

--[[
Healium.Profiles is a table of tables with this signature
{
	ButtonCount -- Current button count (as set by slider)
	SpellNames -- Table of current spell names
	SpellIcons -- Table of current spell IDs
}
]]

-- Global Constants
Healium_MaxButtons = 15		-- Max Possible buttons 
Healium_AddonName = "Healium"
Healium_AddonColor = "|cFF55AAFF"
Healium_AddonColoredName = Healium_AddonColor .. Healium_AddonName .. "|r"


-- NEW FRAMES VARIABLES
Healium_Units = { { } } -- table of tables that maps unit names to their frame, used for efficient handling of UNIT_HEALTH so each button doesn't get a UNIT_HEALTH event for every unit.
Healium_Frames = { } -- table of all created "unit" frames.  Can access buttons from each of these.
Healium_ShownFrames = { } -- table of all shown "unit" frames.
Healium_ButtonIDs = { } -- table of IDs that correspond to the selected spells, not persisted 
Healium_FixNameplates = { } -- nameplates that need various updates when out of combat


--[[
Healium_DefaultButtons = { 
	1 = {}
	2 = {}
	3 = {}
	4 = {}
} 
--]]

--[[
List of spells, icons for the spells, and IDs. 
These only contain specifically selected spells in HealiumSpells.lua
The Name gets filled in in Healium_InitSpells(). Healium_UpdateSpells() will fill in the ID and Icon if
the player actually has the spell.
--]]
Healium_Spell = {		
  Name = {},
  Icon = {},
  ID = {}
}

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

-- Profile cache: indexed by talent group so switching specs is automatic
-- and no explicit invalidation is needed.
local _profileCache = {}

-- Forward-declared so Healium_GetProfile can use it before the main definition block.
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
			-- Profiles not yet initialised (e.g. called before ADDON_LOADED).
			-- Return a safe default so callers never index nil.
			_profileCache[key] = CreateDefaultProfile()
			Healium_DebugPrint("GetProfile: no saved profile for talent group " .. tostring(key) .. ", using default")
		end
	end
	return _profileCache[key]
end

-- Call this whenever Healium.Profiles is re-initialised (e.g. after ADDON_LOADED).
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
--	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("UNIT_SPELLCAST_SENT")	
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
--	self:RegisterEvent("PLAYER_ALIVE")	
	self:RegisterEvent("RAID_TARGET_UPDATE")
end

function Healium_UpdatePercentageVisibility()
	for _, k in ipairs(Healium_Frames) do
		k.HPText:SetShown(Healium.ShowPercentage)
	end
end

-- Sets the health bar color based on the unit's health ONLY
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
		if k.TargetUnit and UnitExists(k.TargetUnit) then  -- fix: was 'return', now skips missing unit
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

	local HPPercent
	if isDead then
		HPPercent = 0
		NamePlate.HPText:SetText("dead")
	else
		HPPercent = math.max(0, math.min(1, Health / MaxHealth))
		NamePlate.HPText:SetText(math.floor(HPPercent * 100) .. "%")
	end

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
	-- Always use BOOKTYPE_SPELL, never SpellBookFrame.bookType (may be 'pet' or nil)
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

-- Reverse-lookup hash: spellName -> ID, rebuilt on SPELLS_CHANGED / PLAYER_ENTERING_WORLD
local Healium_SpellByName = {}

-- Loops through Healium_Spell.Name[] and updates it's corresponding .ID[] and .Icon[]
-- Warning UpdateSpells() is a global function from Blizzard. 
local function Healium_UpdateSpells()
	SpellCache = nil
	Healium_SpellByName = {}
	for k, v in ipairs(Healium_Spell.Name) do
		Healium_Spell.ID[k] = GetSpellID(v)
		if Healium_Spell.ID[k] then
			Healium_Spell.Icon[k] = GetSpellTexture(Healium_Spell.ID[k], BOOKTYPE_SPELL)
			Healium_SpellByName[v] = Healium_Spell.ID[k]  -- O(1) lookup
		else
			Healium_Spell.Icon[k] = nil
		end
	end

	Healium_UpdateButtonSpells()
end


-- Efficient cooldowns
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

	Profile.SpellNamesHash = {}

	for i = 1, Healium_MaxButtons do
		local spell = Profile.SpellNames[i]
		local id

		if spell and spell ~= "" then
			Profile.SpellNamesHash[spell] = true

			-- O(1) hash lookup instead of O(N) inner loop
			id = Healium_SpellByName[spell]

			-- Fallback for drag-and-dropped spells not in Healium_Spell list
			if not id then
				id = GetSpellID(spell)
			end
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

	-- Hide all buttons
	for i = 1, Healium_MaxButtons do
		local button = frame.buttons[i]
		if button then
			button:Hide()
		end
	end

	-- Show buttons. They will not actually show up unless their nameplate is visible.
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

-- Single-pass update: visibility + spell attributes + icons merged into one loop per frame
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

	-- Spell-hash and cures built once outside the per-frame loop
	Healium_UpdateButtonSpells()
end

function Healium_RangeCheckButton(button)
	local id = button.id
	if id then
		local bookType = BOOKTYPE_SPELL  -- localize hot-path constant
		local isUsable, noMana = IsUsableSpell(id, bookType)

		if isUsable then
			button.icon:SetVertexColor(1.0, 1.0, 1.0)
		elseif noMana then
			button.icon:SetVertexColor(0.5, 0.5, 1.0)
		else
			button.icon:SetVertexColor(0.3, 0.3, 0.3)
		end

		if SpellHasRange(id, bookType) then
			local inRange = IsSpellInRange(id, bookType, button:GetParent().TargetUnit)
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

-- Sets persisted variables to their default if they do not exist.
local function InitVariables()
	local H = Healium

	-- ShowGroupFrames must be a dedicated table per character (never share the default)
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


	-- Migrate profiles from the old per-character SavedVariable format.
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

	-- Remove old saved variables from pre-profile era.
	HealiumDropDownButton    = nil
	HealiumDropDownButtonIcon = nil
end

local EventHandlers = {}

-- Shared helper: calls callback(unitName, frame) for every frame tracking unitName
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
	
	for _,v in ipairs(Healium_FixNameplates) do
		if (not Healium.ShowPercentage) then v.HPText:Hide() end		

		if v.fixCreateButtons then 
			Healium_CreateButtonsForNameplate(v)
			UpdateButtonVisibility(v)
			v.fixCreateButtons = nil
		end
		
		if v.fixShowMana then
			Healium_UpdateManaBarVisibility(v)
			v.fixShowMana = nil
		end
	end
	
	Healium_FixNameplates = {}
end

function EventHandlers.ADDON_LOADED(self, arg1, ...)
	if string.lower(arg1) == string.lower(Healium_AddonName) then
		Healium_DebugPrint("ADDON_LOADED")  	

		InitVariables()
		Healium_InvalidateProfileCache()  -- Healium.Profiles was just (re)built
		Healium_InitSpells(HealiumClass, HealiumRace) 		
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

-- Staggered range check: process one "page" of ShownFrames per OnUpdate tick
-- to spread up to 600 API calls (40 frames × 15 buttons) across multiple frames
local RangeCheckTimer   = 0
local RangeCheckFrames  = nil   -- ordered snapshot rebuilt each cycle
local RangeCheckPageIdx = 0     -- current position in snapshot
local RangeCheckPageSize = 8    -- frames processed per tick (tune as needed)

function Healium_OnUpdate(self, elapsed)
	if not Healium then return end
	RangeCheckTimer = RangeCheckTimer + elapsed
	if RangeCheckTimer < 0.5 then return end
	RangeCheckTimer = 0

	local Profile = Healium_GetProfile()
	if not Profile or not Profile.ButtonCount then return end
	local buttonCount = Profile.ButtonCount

	-- Rebuild snapshot when we reach the end of the previous one
	if not RangeCheckFrames or RangeCheckPageIdx >= #RangeCheckFrames then
		RangeCheckFrames  = {}
		for frame in pairs(Healium_ShownFrames) do
			RangeCheckFrames[#RangeCheckFrames + 1] = frame
		end
		RangeCheckPageIdx = 0
	end

	-- Process one page of frames this tick
	local last = math.min(RangeCheckPageIdx + RangeCheckPageSize, #RangeCheckFrames)
	for i = RangeCheckPageIdx + 1, last do
		local frame = RangeCheckFrames[i]
		if frame and frame.TargetUnit
			and UnitIsVisible(frame.TargetUnit)
			and not UnitIsDeadOrGhost(frame.TargetUnit) then
			for j = 1, buttonCount do
				local button = frame.buttons[j]
				if button and button:IsShown() then
					Healium_RangeCheckButton(button)
				end
			end
		end
	end
	RangeCheckPageIdx = last
end


