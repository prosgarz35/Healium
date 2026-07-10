local addonName, addonTable = ...
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local UnitName = UnitName
local UnitExists = UnitExists
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
local GetSpellCooldown = GetSpellCooldown
local GetSpellInfo = GetSpellInfo
local ipairs = ipairs
local pairs = pairs
local type = type
local tostring = tostring
local tonumber = tonumber

function Healium_HealButton_OnLoad(self)
	self.TimeSinceLastUpdate = 0
	self:RegisterEvent("SPELL_UPDATE_USABLE")
	self:RegisterForDrag("LeftButton")
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	self:SetScript("OnUpdate", nil)
end



function Healium_HealButton_OnEnter(frame, motion)
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT", -30, 5)
    local spellName = frame:GetAttribute("spell")
    if frame.id or spellName then
        if not Healium.ShowToolTips then return end	
        GameTooltip_SetDefaultAnchor(GameTooltip, frame)
        local link = GetSpellLink(spellName)
        if link then 
            GameTooltip:SetHyperlink(link) 
        else 
            GameTooltip:SetText(spellName, 1, 1, 1) 
        end
        local unit = frame:GetParent().TargetUnit
        if unit and UnitExists(unit) then
            local name = UnitName(unit) or "-"
            GameTooltip:AddLine("Target: |cFF00FF00" .. name, 1, 1, 1)
        end
        GameTooltip:Show()
    else
        GameTooltip:SetText("|cFFFFFFFFNo Spell|n|cFF00FF00You may drag-and-drop a spell from your|nspellbook onto this button, or you may go|nto Interface, Addons, " .. addonTable.AddonName .. " and|nselect your spells from the list.")
        GameTooltip:Show()		
    end
end

function Healium_HealButton_OnLeave()
	GameTooltip:Hide()
end

function Healium_HealButton_OnEvent(self, event)
	if (not self.id) then return 0 end   
	
	if event == "SPELL_UPDATE_USABLE" then
		Healium_RangeCheckButton(self)
	end
end

local function Drag(self)
	if CursorHasSpell() then
		local infoType, info1, info2 = GetCursorInfo()
		if InCombatLockdown() then
			Healium_Warn("Can't update button while in combat")
			return
		end
		
		if (self.index > 0) and (self.index <= addonTable.MaxButtons) then
			local spellName = GetSpellName(info1, BOOKTYPE_SPELL )		
			if IsPassiveSpell(info1, BOOKTYPE_SPELL) then
				local link = GetSpellLink(info1, BOOKTYPE_SPELL)
				Healium_Warn(link .. " is a passive spell and cannot be used in " .. addonTable.AddonName)
				return
			end
			local name, rank, icon = GetSpellInfo(spellName)
			local Profile = Healium_GetProfile()
			local OldSpellName = Profile.SpellNames[self.index]
			Profile.SpellNames[self.index] = name
			Profile.SpellIcons[self.index] = icon
			
			Healium_UpdateButtonSpells()
			Healium_UpdateButtonIcons()				
			Healium_UpdateButtonCooldownsByColumn(self.index)	
			
			ClearCursor()

			if IsShiftKeyDown() and (OldSpellName ~= nil) then
				PickupSpell(OldSpellName)
			end
		end
	else
		Healium_DebugPrint("Button received a drag but did not have a spell")
	end
end 

function Healium_HealButton_OnReceiveDrag(self)
	Healium_DebugPrint("Healium_HealButton_OnReceiveDrag() called")
	Drag(self, nil)
end

function Healium_HealButton_OnDragStart(self)
	if IsShiftKeyDown() == nil then return end
	
	local Profile = Healium_GetProfile()
	
	if (self.index > 0) and (self.index <= addonTable.MaxButtons) then	
		PickupSpell(Profile.SpellNames[self.index])
	end
end

function Healium_HealButton_PreClick(self)
	Healium_DebugPrint("Healium_HealButton_PreClick() called")

	if CursorHasSpell() then
		local info, spellid = GetCursorInfo()
		self.dragspellid = spellid
	else
		self.dragspellid = nil
	end
end

function Healium_HealButton_PostClick(self)
	Healium_DebugPrint("Healium_HealButton_PostClick() called")

	if self.dragspellid then
		PickupSpell(self.dragspellid, BOOKTYPE_SPELL)
		Drag(self)
		self.dragspellid = nil
	end
end


