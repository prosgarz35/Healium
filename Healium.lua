local addonName, addonTable = ...

-- Caching WoW API (Upvalues)
local UnitIsVisible = UnitIsVisible
local IsUsableSpell = IsUsableSpell
local IsSpellInRange = IsSpellInRange
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local InCombatLockdown = InCombatLockdown
local ipairs = ipairs
local pairs = pairs
local GetActiveTalentGroup = GetActiveTalentGroup






Healium_Debug = false
local AddonVersion = "|cFFFFFF00 1.0.2|r"

local LowHP = 0.6
local VeryLowHP = 0.3
local NamePlateWidth = 120
local _, HealiumClass = UnitClass("player")
local _, HealiumRace = UnitRace("player")
local MaxParty = 5
local MinRangeCheckPeriod = .2
local MaxRangeCheckPeriod = 2
local DefaultRangeCheckPeriod = .5
local DefaultButtonCount = 5


local ActivatePrimarySpecSpellName = GetSpellInfo(63645)
local ActivateSecondarySpecSpellName = GetSpellInfo(63644) 


Healium = {
  Scale = 1.0,
  DoRangeChecks = true,
  RangeCheckPeriod = .5,
  EnableCooldowns = true,
  ShowToolTips = true,
  ShowPercentage = true,
  UseClassColors = false,
  ShowDefaultPartyFrames = false,
  ShowPartyFrame = true,
  ShowPetsFrame = true,
  ShowMeFrame = false,
  ShowGroupFrames = { },
  ShowBuffs = true,
  HideCloseButton = false,
  HideCaptions = false,
  LockFrames = false,
  EnableDebufs = true,
  EnableDebufHealthbarHighlighting = true,
  EnableDebufButtonHighlighting = true,
  EnableDebufHealthbarColoring = false,
  ShowMana = true,
}




addonTable.MaxButtons = 15
addonTable.AddonName = "Healium"
addonTable.AddonColor = "|cFF55AAFF"
addonTable.AddonColoredName = addonTable.AddonColor .. addonTable.AddonName .. "|r"
addonTable.MaxClassSpells = 20



addonTable.Units = { }
addonTable.Frames = { }
addonTable.ShownFrames = { }
addonTable.ButtonIDs = { }
addonTable.FixNameplates = { }



addonTable.Spell = {		
  Name = {},
  ID = {}
}

local HealiumFrame = nil

function Healium_Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(addonTable.AddonColor .. addonTable.AddonName .. "|r " .. tostring(msg))		
end

function Healium_DebugPrint(msg)
	if (Healium_Debug) then
		Healium_Print("Debug: " .. tostring(msg))		
	end
end

function Healium_Warn(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|CFFFF0000Warning|r: " .. tostring(msg))		
end

function addonTable.DB.GetProfile()
	return Healium.Profiles[GetActiveTalentGroup()]
end

local RangeCheckTimer = 0
local function Healium_OnUpdate(self, elapsed)
	if not Healium or not Healium.DoRangeChecks then return end
	RangeCheckTimer = RangeCheckTimer + elapsed
	if RangeCheckTimer > Healium.RangeCheckPeriod then
		RangeCheckTimer = 0
		local Profile = addonTable.DB.GetProfile()
		if Profile and Profile.ButtonCount then
			for _, frame in pairs(addonTable.ShownFrames) do
				if frame.TargetUnit and UnitIsVisible(frame.TargetUnit) then
					for i = 1, Profile.ButtonCount do
						local button = frame.buttons[i]
						if button and button:IsShown() then
							Healium_RangeCheckButton(button)
						end
					end
				end
			end
		end
	end
end

-- Create core event frame
HealiumFrame = CreateFrame("Frame", "Healium", UIParent)
HealiumFrame:Hide()
HealiumFrame:SetScript("OnEvent", function(self, event, ...)
	if addonTable.Events[event] then
		addonTable.Events[event](self, select(1, ...), select(2, ...))
	end
end)
HealiumFrame:SetScript("OnUpdate", Healium_OnUpdate)

Healium_Print(AddonVersion.." |cFF00FF00Loaded |rAccess options via Interface -> AddOns.")
HealiumFrame:RegisterEvent("ADDON_LOADED")
HealiumFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
HealiumFrame:RegisterEvent("SPELLS_CHANGED")
HealiumFrame:RegisterEvent("UNIT_HEALTH")
HealiumFrame:RegisterEvent("UNIT_SPELLCAST_SENT")	
HealiumFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
HealiumFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
HealiumFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
HealiumFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
HealiumFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
HealiumFrame:RegisterEvent("RAID_TARGET_UPDATE")

function Healium_UpdatePercentageVisibility()
	for _, k in ipairs(addonTable.Frames) do
		if Healium.ShowPercentage then
			k.HPText:Show()
		else
			k.HPText:Hide()
		end
	end
end


local function UpdateHealthBar(HPPercent, frame)
	if (HPPercent > LowHP) then 
		frame.HealthBar:SetStatusBarColor(0,1,0,1) 
	end
	if (HPPercent < LowHP) then 
		frame.HealthBar:SetStatusBarColor(1,0.9,0,1) 
	end
	if (HPPercent < VeryLowHP) then
		frame.HealthBar:SetStatusBarColor(1,0,0,1) 
	end
end

function Healium_UpdateClassColors()
	for _, k in ipairs(addonTable.Frames) do
		if (k.TargetUnit) then
			if not UnitExists(k.TargetUnit) then return end
			if Healium.UseClassColors then
				local class = select(2, UnitClass(k.TargetUnit)) or "WARRIOR"
				local color = RAID_CLASS_COLORS[class]
				k.HealthBar:SetStatusBarColor(color.r, color.g, color.b)				
			else
				local Health = UnitHealth(k.TargetUnit)
				local MaxHealth = UnitHealthMax(k.TargetUnit)
				local HPPercent =  Health / MaxHealth
				UpdateHealthBar(HPPercent, k)
			end
		end
	end
end

function Healium_UpdateUnitHealth(UnitName, NamePlate)
	if not NamePlate then return end
	if not UnitExists(UnitName) then return end
		
	local Health = UnitHealth(UnitName)
	local MaxHealth = UnitHealthMax(UnitName)
	local isDead 
		
	if UnitIsDeadOrGhost(UnitName) then
		Health = 0
		isDead = 1
	end
	
	local HPPercent =  Health / MaxHealth
	
	if HPPercent > 1 then 
		HPPercent = 1
	end
	
	if HPPercent < 0 then
		HPPercent = 0
	end
	
	if isDead then
		NamePlate.HPText:SetText( "dead" )	
	else
		NamePlate.HPText:SetText( format("%.1i%%", HPPercent*100))
	end
	
	NamePlate.HealthBar:SetMinMaxValues(0,MaxHealth)
	NamePlate.HealthBar:SetValue(Health)
	
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
	if not NamePlate then return end
	if not UnitExists(UnitName) then return end
	
	if NamePlate.showMana == nil then return end
	
	local Mana = UnitPower(UnitName, SPELL_POWER_MANA)
	local MaxMana = UnitPowerMax(UnitName, SPELL_POWER_MANA)

	if UnitIsDeadOrGhost(UnitName) then
		Mana = 0
	end

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

	for _, k in ipairs(addonTable.Frames) do
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
	if Healium.ShowBuffs then 
		HealiumFrame:RegisterEvent("UNIT_AURA")
	else
		HealiumFrame:UnregisterEvent("UNIT_AURA")
	end
	
	for _, k in ipairs(addonTable.ShownFrames) do
		if (k.TargetUnit) then
			Healium_UpdateUnitBuffs(k.TargetUnit, k)
		end
	end	
end

local spellCache = {}

local function PopulateSpellCache()
	table.wipe(spellCache)
	local i = 1
	while true do
		local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL)
		if not spellName then
			break
		end
		spellCache[spellName] = { id = i, rank = spellRank }
		i = i + 1
	end
end

local function GetSpellID(spell)
	if not next(spellCache) then
		PopulateSpellCache()
	end
	local data = spellCache[spell]
	if data then
		return data.id, data.rank
	end
	return nil, nil
end


local function Healium_UpdateSpells()
	table.wipe(spellCache)
	for k, v in ipairs (addonTable.Spell.Name) do
		addonTable.Spell.ID[k] = GetSpellID(addonTable.Spell.Name[k])
	end 
	
	Healium_UpdateButtonSpells()
end



function Healium_UpdateButtonCooldownsByColumn(column)
	local spellName = Healium_GetProfile().SpellNames[column]
	if spellName or addonTable.ButtonIDs[column] then
		local start, duration, enable

		if spellName then
			start, duration, enable = GetSpellCooldown(spellName)
		end

		if not start and addonTable.ButtonIDs[column] then
			start, duration, enable = GetSpellCooldown(addonTable.ButtonIDs[column], BOOKTYPE_SPELL)
		end
		for _,j in pairs(addonTable.Units) do
			for x,y in pairs(j) do
				local button = y.buttons[column]
				if button then 
					if button:IsShown() then 

						if start and duration then
							CooldownFrame_SetTimer(button.cooldown, start, duration, enable)
						end
					end
				end
			end
		end
	end
end

local function Healium_UpdateButtonCooldowns()
	local count = Healium_GetProfile().ButtonCount
	
	for i=1, count, 1 do
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
	for i=1, addonTable.MaxButtons, 1 do
		local texture = Profile.SpellIcons[i]
		
		for _, k in ipairs(addonTable.Frames) do
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
	
	if id then
		button.hasRange = SpellHasRange(id, BOOKTYPE_SPELL)
	else
		button.hasRange = nil
	end
end

function Healium_UpdateButtonSpells()
	local Profile = Healium_GetProfile()
	Profile.SpellSet = {}

	for i=1, addonTable.MaxButtons, 1 do
		local spell = Profile.SpellNames[i]
		if spell then Profile.SpellSet[spell] = true end
		local id
		

		if not id then
			for k=1, addonTable.MaxClassSpells, 1 do
				if (spell == addonTable.Spell.Name[k]) then
					id = addonTable.Spell.ID[k]
					break
				end
			end
		end
		
		if not id then
			id = GetSpellID(spell)
		end
		
		addonTable.ButtonIDs[i] = id		
		
		for _,k in ipairs(addonTable.Frames) do
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


	for i=1, addonTable.MaxButtons, 1 do 
		local button = frame.buttons[i]
		if button then 
			button:Hide()
		end
	end


	local count = Healium_GetProfile().ButtonCount
	
	for i=1, count, 1 do 
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
	
	for _,k in ipairs(addonTable.Frames) do
		UpdateButtonVisibility(k)
	end
end

function Healium_UpdateButtons()
	Healium_UpdateButtonVisibility()
	Healium_UpdateButtonSpells()
	Healium_UpdateButtonIcons()
end

function Healium_RangeCheckButton(button)
    if (button.id) then
        local isUsable, noMana = IsUsableSpell(button.id, BOOKTYPE_SPELL)
          
        if isUsable then
      	 button.icon:SetVertexColor(1.0, 1.0, 1.0)
      	elseif noMana then
      	 button.icon:SetVertexColor(0.5, 0.5, 1.0)
      	else
      	  button.icon:SetVertexColor(0.3, 0.3, 0.3)
      	end
      	
       	local inRange = IsSpellInRange(button.id, BOOKTYPE_SPELL, button:GetParent().TargetUnit)
      		
		if button.hasRange then
			if (inRange == 0) or (inRange == nil) then
				button.icon:SetVertexColor(1.0, 0.3, 0.3)
			end
		end
	end
end

function Healium_DeepCopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end



local function InitVariables()
	if (not Healium.RaidScale) then
		Healium.RaidScale = 1.0
	end
	
	if (not Healium.RangeCheckPeriod) then
		Healium.RangeCheckPeriod = DefaultRangeCheckPeriod
	end
	
	if (Healium.RangeCheckPeriod > MaxRangeCheckPeriod or Healium.RangeCheckPeriod < MinRangeCheckPeriod) then
		Healium.RangeCheckPeriod = DefaultRangeCheckPeriod
	end

	if Healium.ShowGroupFrames == nil then
		Healium.ShowGroupFrames = { }
	end
	
	if Healium.ShowToolTips == nil then 
		Healium.ShowToolTips = true
	end
	
	if Healium.ShowMana == nil then
		Healium.ShowMana = true
	end
	
	if Healium.ShowPercentage == nil then 
		Healium.ShowPercentage = true
	end
	
	if Healium.UseClassColors == nil then 
		Healium.UseClassColors = false
	end

	if Healium.ShowBuffs == nil then 
		Healium.ShowBuffs = true
	end

	if Healium.ShowDefaultPartyFrames == nil then
		Healium.ShowDefaultPartyFrames = false
	end
	
	if Healium.ShowPartyFrame == nil then
		Healium.ShowPartyFrame = true
	end		
	
	if Healium.ShowPetsFrame == nil then
		Healium.ShowPetsFrame = true
	end
	
	if Healium.ShowMeFrame == nil then
		Healium.ShowMeFrame = false
	end
	
	
	if Healium.HideCloseButton == nil then
		Healium.HideCloseButton = false
	end
	
	if Healium.HideCaptions == nil then
		Healium.HideCaptions = false
	end
	
	if Healium.LockFrames == nil then
		Healium.LockFrames = false
	end
	
	if Healium.EnableDebufs == nil then
		Healium.EnableDebufs = true
	end
		
	if Healium.EnableDebufHealthbarHighlighting == nil then
		Healium.EnableDebufHealthbarHighlighting = true
	end
	
	if Healium.EnableDebufButtonHighlighting == nil then 
		Healium.EnableDebufButtonHighlighting = true
	end
	
	if Healium.EnableDebufHealthbarColoring == nil then
		Healium.EnableDebufHealthbarColoring = false
	end
	
	if Healium.Profiles == nil then
		if (HealiumDropDownButton ~= nil) and (HealiumDropDownButtonIcon ~= nil) and (Healium.ButtonCount ~= nil) then

			Healium_Print("Importing button profiles.")
			Healium_Print(addonTable.AddonColor .. addonTable.AddonName .. "|r now has seperate button configurations for each talent specialization.")			
			Healium_Print("Both " .. addonTable.AddonColor .. addonTable.AddonName .. "|r button configurations will be set to your current button configuration.")
			Healium_Print("Any button changes you make will now only be applied to the configuration specific to the talent specialization you are in at the time of the change.")
			local config = { 
				ButtonCount = Healium.ButtonCount,
				SpellNames = Healium_DeepCopy(HealiumDropDownButton),
				SpellIcons = Healium_DeepCopy(HealiumDropDownButtonIcon),
			}
			Healium.Profiles = { 
				[1] = Healium_DeepCopy(config),
				[2] = Healium_DeepCopy(config)
			}
		else
			Healium.Profiles = { }
		end
	end


	local DefaultProfile = { 
		ButtonCount = DefaultButtonCount,
		SpellNames = { },
		SpellIcons = { }
	}
	
	if Healium.Profiles[1] == nil then
		Healium.Profiles[1] = Healium_DeepCopy(DefaultProfile)
	end
	
	if Healium.Profiles[2] == nil then
		Healium.Profiles[2] = Healium_DeepCopy(DefaultProfile)
	end


	HealiumDropDownButton = nil
	HealiumDropDownButtonIcon = nil
end

addonTable.Events = {}
addonTable.DB = {}

function addonTable.DB.GetProfile()
	return Healium.Profiles[GetActiveTalentGroup()]
end

function addonTable.Events.UNIT_AURA(self, arg1, arg2)
	if addonTable.Units[arg1] then
		for _,v  in pairs(addonTable.Units[arg1]) do
			Healium_UpdateUnitBuffs(arg1, v)
		end
	end
end

function addonTable.Events.SPELL_UPDATE_COOLDOWN(self, arg1, arg2)
	if Healium.EnableCooldowns then
		Healium_UpdateButtonCooldowns()
	end
end

function addonTable.Events.PLAYER_REGEN_ENABLED(self, arg1, arg2)
	for _,v in ipairs(addonTable.FixNameplates) do
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
	
	addonTable.FixNameplates = {}
end

function addonTable.Events.ADDON_LOADED(self, arg1, arg2)
	if (string.lower(arg1) == string.lower(addonTable.AddonName)) then
		Healium_DebugPrint("ADDON_LOADED")  	

		InitVariables()
		Healium_InitSpells(HealiumClass, HealiumRace) 		
		Healium_CreateConfigPanel(HealiumClass, AddonVersion)
		Healium_InitMenu()		
		Healium_CreateUnitFrames()
		Healium_SetScale()		
		Healium_UpdatePercentageVisibility()		
		Healium_UpdateClassColors()
		Healium_ShowHidePartyFrame()
		Healium_ShowHidePetsFrame()
		Healium_ShowHideMeFrame()
		Healium_UpdateShowMana()
		Healium_UpdateShowBuffs()
		
		for i=1, 8, 1 do
			Healium_ShowHideGroupFrame(i)
		end
		
		Healium_UpdateButtons()		
	end
end

function addonTable.Events.UNIT_SPELLCAST_SENT(self, arg1, arg2)
	if ( (arg2 == ActivatePrimarySpecSpellName) or (arg2 == ActivateSecondarySpecSpellName) ) then
		self.Respecing = true
	end
end

function addonTable.Events.UNIT_SPELLCAST_INTERRUPTED(self, arg1, arg2)
	if (arg1 == "player") and ( (arg2 == ActivatePrimarySpecSpellName) or (arg2 == ActivateSecondarySpecSpellName)) then
		self.Respecing = nil
	end
end

function addonTable.Events.UNIT_SPELLCAST_SUCCEEDED(self, arg1, arg2)
	addonTable.Events.UNIT_SPELLCAST_INTERRUPTED(self, arg1, arg2)
end

local spellUpdateTimer = nil
local function DoSpellUpdate()
	Healium_UpdateSpells()
	Healium_UpdateButtons()
	Healium_Update_ConfigPanel()
	spellUpdateTimer = nil
end

local function DebounceSpellUpdate()
	if not spellUpdateTimer then
		local C_Timer = _G.C_Timer
		if C_Timer then
			spellUpdateTimer = C_Timer.After(0.5, DoSpellUpdate)
		else
			DoSpellUpdate()
		end
	end
end
function addonTable.Events.PLAYER_TALENT_UPDATE(self, arg1, arg2)
	Healium_DebugPrint('PLAYER_TALENT_UPDATE')
	self.Respecing = nil
	DebounceSpellUpdate()
end

function addonTable.Events.SPELLS_CHANGED(self, arg1, arg2)
	if (not self.Respecing) then
		Healium_DebugPrint('SPELLS_CHANGED')
		DebounceSpellUpdate()
	end
end

function addonTable.Events.PLAYER_ENTERING_WORLD(self, arg1, arg2)
	if (not self.Respecing) then
		Healium_DebugPrint('PLAYER_ENTERING_WORLD')
		DebounceSpellUpdate()
	end
end
end

function addonTable.Events.UNIT_DISPLAYPOWER(self, arg1, arg2)
	if addonTable.Units[arg1] then
		for i,v  in pairs(addonTable.Units[arg1]) do
			HealiumUnitFrames_CheckPowerType(arg1, v)
		end
	end
end

function addonTable.Events.RAID_TARGET_UPDATE(self, arg1, arg2)
	for _, k in ipairs(addonTable.Frames) do
		if (k.TargetUnit) then
			if not UnitExists(k.TargetUnit) then return end
			local index = GetRaidTargetIndex(k.TargetUnit);
			if ( index ) then
				SetRaidTargetIconTexture(k.raidTargetIcon, index);
				k.raidTargetIcon:Show();
			else
				k.raidTargetIcon:Hide();
			end
		end
	end	
end

-- Removed Healium_OnEvent as it is now inlined in SetScript



