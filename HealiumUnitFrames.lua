
local debuffTypesCache = {}

local PartyFrame = nil
local GroupFrames = { }

local PartyFrameWasShown = nil
local GroupFramesWasShown = { }

local MaxBuffs = 6
local xSpacing = 2
local NamePlateHeight = 28
local UnitFrames = { }

local FrameSet = {}

local function initialConfigFunction(frame)

	frame.buttons = { }
	frame:RegisterForClicks("AnyUp")	
	frame:SetAttribute("type1", "target")
	if not FrameSet[frame] then
		FrameSet[frame] = true
		table.insert(Healium_Frames, frame)
	end
	frame.buffs = { }	

	local framename = frame:GetName()
	for i = 1, MaxBuffs do
		local buffFrame = _G[framename.."_Buff"..i]
		local name = buffFrame:GetName()
		buffFrame.icon = _G[name.."Icon"]
		buffFrame.cooldown = _G[name.."Cooldown"]
		buffFrame.count = _G[name.."Count"]
		buffFrame.border = _G[name.."Border"]
		buffFrame.id = i
		frame.buffs[i] = buffFrame
	end

	if InCombatLockdown() then
		frame.fixCreateButtons = true
		table.insert(Healium_FixNameplates, frame)
		Healium_DebugPrint("Unit Frame created during combat. Its buttons will not be available until combat ends.")
	else
		if (not Healium.ShowPercentage) then frame.HPText:Hide() end	
		Healium_CreateButtonsForNameplate(frame)			
	end

end

local function CreateButton(ButtonName,ParentFrame,xoffset)
	local button = CreateFrame("Button", ButtonName, ParentFrame, "HealiumHealButtonTemplate")
	button:SetPoint("LEFT", ParentFrame, "RIGHT", xoffset, 0)
	return button
end
function Healium_CreateButtonsForNameplate(frame)
	local x = xSpacing
	local Profile = Healium_GetProfile()

	for i = 1, Healium_MaxButtons do
		local name = frame:GetName()
		local button = CreateButton(name.."_Heal"..i, frame, x)
		x = x + xSpacing + NamePlateHeight

		button.index = i
		frame.buttons[i] = button

		local spell = Profile.SpellNames[i]
		Healium_UpdateButtonSpell(button, spell, Healium_ButtonIDs[i], false)

		local texture = Profile.SpellIcons[i]
		Healium_UpdateButtonIcon(button, texture)

		if i > Profile.ButtonCount then
			button:Hide()
		else
			button:Show()
		end
	end	
end

local function SetHeaderAttributes(frame)
	frame.initialConfigFunction = initialConfigFunction

	frame:SetAttribute("showPlayer", "true")
	frame:SetAttribute("maxColumns", 1)
	frame:SetAttribute("columnAnchorPoint", "LEFT")
	frame:SetAttribute("point", "TOP")
	frame:SetAttribute("template", "HealiumUnitFrames_ButtonTemplate")
	frame:SetAttribute("templateType", "Button")
	frame:SetAttribute("unitsPerColumn", 5) 
end

local function CreateHeader(TemplateName, FrameName, ParentFrame)
	local f = CreateFrame("Frame", FrameName, ParentFrame, TemplateName)
	ParentFrame.hdr = f
	f:SetPoint("TOPLEFT", ParentFrame, "BOTTOMLEFT")	
	SetHeaderAttributes(f)			
	return f
end

local function UpdateCloseButton(frame)
	if not InCombatLockdown() then
		frame.CaptionBar.CloseButton:SetShown(not Healium.HideCloseButton)
	end
end

local function UpdateHideCaption(frame)
	if Healium.HideCaptions then
		frame.CaptionBar:SetAlpha(0)
	else
		frame.CaptionBar:SetAlpha(1)
	end
end

local function CreateUnitFrame(FrameName, Caption, IsPet, Group)
	local uf = CreateFrame("Frame", FrameName, UIParent, "HealiumUnitFrameTemplate")
	table.insert(UnitFrames, uf) 	
	uf.CaptionBar.Caption:SetText(Caption)
	UpdateCloseButton(uf)	
	UpdateHideCaption(uf)
	return uf
end

local function CreateGroupHeader(FrameName, ParentFrame, Group)
	local h = CreateHeader("SecureGroupHeaderTemplate", FrameName, ParentFrame)
	h:SetAttribute("groupFilter", Group)	
	h:SetAttribute("showRaid", "true")	
	h:Show()
	return h
end

local function CreatePartyHeader(FrameName, ParentFrame)
	local h = CreateHeader("SecureGroupHeaderTemplate", FrameName, ParentFrame)
	h:SetAttribute("showSolo", "true")		
	h:Show()
	return h
end

local function CreateGroupUnitFrame(FrameName, Caption, Group)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreateGroupHeader(FrameName .. "_Header", uf, Group)
	return uf
end

local function CreatePartyUnitFrame(FrameName, Caption)
	local uf = CreateUnitFrame(FrameName, Caption)
	local h = CreatePartyHeader(FrameName .. "_Header", uf)
	return uf
end

function Healium_UpdateCloseButtons()
	for _, j in ipairs(UnitFrames) do
		UpdateCloseButton(j)
	end
end

function Healium_UpdateHideCaptions()
	for _, j in ipairs(UnitFrames) do
		UpdateHideCaption(j)
	end
end

function HealiumUnitFrames_OnEnter(self)
	self:SetAlpha(1)
end

function HealiumUnitFrames_OnLeave(self)
	if Healium.HideCaptions then
		self:SetAlpha(0)
	end
end

function HealiumUnitFrames_OnMouseDown(self, button)
	if button == "LeftButton" and not Healium.LockFrames then
		self:StartMoving()	
	end

	if button == "RightButton" then
		if not InCombatLockdown() then
			ToggleDropDownMenu(1, nil, HealiumMenu, self, 0, 0)	
		else
			Healium_Warn("Меню настроек недоступно в бою.")
		end
	end
end

function HealiumUnitFrames_OnMouseUp(self, button)
	if button == "LeftButton" then
		self:StopMovingOrSizing()
	end
end

function HealiumUnitFrames_ShowHideFrame(self, show)
	if self == PartyFrame then
		Healium.ShowPartyFrame = show
		if Healium_ShowPartyCheck then
			Healium_ShowPartyCheck:SetChecked(Healium.ShowPartyFrame)
		end
		return
	end

	for i, j in ipairs(GroupFrames) do
		if self == j then
			Healium.ShowGroupFrames[i] = show
			local check = _G["Healium_ShowGroup" .. i .. "Check"]
			if check then check:SetChecked(Healium.ShowGroupFrames[i]) end
			return
		end
	end
end

function HealiumUnitFrames_Button_OnLoad(self)
	self:RegisterForDrag("RightButton")
end

function HealiumUnitFrames_CheckPowerType(UnitName, NamePlate)
	local _, powerType = UnitPowerType(UnitName)
	if not Healium.ShowMana or not UnitExists(UnitName) or powerType ~= "MANA" then
		NamePlate.ManaBar:SetStatusBarColor(.5, .5, .5)
		NamePlate.ManaBar:SetMinMaxValues(0, 1)
		NamePlate.ManaBar:SetValue(1)
		NamePlate.showMana = nil
		return
	else
		local powerColor = PowerBarColor[powerType]
		NamePlate.ManaBar:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)
		NamePlate.showMana = true
	end
	return true
end
local function InitUnitFrameForUnit(self, unit)
	self.TargetUnit = unit
	if not Healium_Units[unit] then Healium_Units[unit] = {} end
	Healium_Units[unit][self] = true
	local unitName = UnitName(unit)
	self.name:SetText(unitName and strupper(unitName) or "")
	HealiumUnitFrames_CheckPowerType(unit, self)
	Healium_UpdateUnitHealth(unit, self)
	Healium_UpdateUnitMana(unit, self)
	Healium_UpdateUnitBuffs(unit, self)
end

function HealiumUnitFrames_Button_OnShow(self)
	Healium_ShownFrames[self] = self

	local unit = self:GetAttribute("unit")
	if not unit then return end

	InitUnitFrameForUnit(self, unit)
	local buttonCount = Healium_GetProfile().ButtonCount
	for i = 1, buttonCount do
		local button = self.buttons[i]
		if button then
			local id = Healium_ButtonIDs[i]
			if id then
				local start, duration, enable = GetSpellCooldown(id, BOOKTYPE_SPELL)
				CooldownFrame_SetTimer(button.cooldown, start, duration, enable)
			end
		end
	end
	for i = 1, MaxBuffs do
		self.buffs[i].unit = unit
	end
end

function HealiumUnitFrames_Button_OnHide(self)

	Healium_ShownFrames[self] = nil

	local parent = self:GetParent():GetParent()
	if parent.childismoving then
		parent:StopMovingOrSizing()		
		parent.childismoving = nil
	end
	local unit = self.TargetUnit
	if unit then
		if Healium_Units[unit] then
			Healium_Units[unit][self] = nil
		end
		self.TargetUnit = nil
	end

end	

function HealiumUnitFrames_Button_OnMouseDown(self, button)
	if button == "RightButton" and not Healium.LockFrames then
		local parent = self:GetParent():GetParent()
		parent.childismoving = true
		parent:StartMoving()	
	end
end

function HealiumUnitFrames_Button_OnAttributeChanged(self, name, value)
	if name ~= "unit" or value == self.TargetUnit then return end
	if self.TargetUnit and Healium_Units[self.TargetUnit] then
		Healium_Units[self.TargetUnit][self] = nil
	end

	if self:IsShown() and value then
		InitUnitFrameForUnit(self, value)
	else
		self.TargetUnit = nil
	end
end

function HealiumUnitFrames_Button_OnMouseUp(self, button)
	if button == "RightButton" then
		local parent = self:GetParent():GetParent()
		parent:StopMovingOrSizing()		
		parent.childismoving = nil
	end	
end

function Healium_ToggleAllFrames()
	if InCombatLockdown() then
		Healium_Warn("Can't toggle frames while in combat.")
		return
	end

	local hide = PartyFrame:IsShown()
	if not hide then
		for _, j in ipairs(GroupFrames) do
			if j:IsShown() then hide = true; break end
		end
	end

	if hide then
		PartyFrameWasShown = PartyFrame:IsShown()
		PartyFrame:Hide()
		for i, j in ipairs(GroupFrames) do
			GroupFramesWasShown[i] = j:IsShown()
			j:Hide()
		end
		return
	end

	if PartyFrameWasShown then
		PartyFrame:Show()
	end

	for i, j in ipairs(GroupFramesWasShown) do
		if j then
			GroupFrames[i]:Show()
		end
	end
end

function Healium_ShowHidePartyFrame(show)
	if show ~= nil then Healium.ShowPartyFrame = show end
	PartyFrame:SetShown(Healium.ShowPartyFrame)
end

function Healium_ShowHideGroupFrame(group, show)
	if show ~= nil then Healium.ShowGroupFrames[group] = show end
	GroupFrames[group]:SetShown(Healium.ShowGroupFrames[group])
end

function Healium_HideAllRaidFrames()
	for i,j in ipairs(GroupFrames) do
		j:Hide()
	end
end

function Healium_Show10ManRaidFrames()
	GroupFrames[1]:Show()
	GroupFrames[2]:Show()
end

function Healium_Show25ManRaidFrames()
	for i = 1, 5 do
		GroupFrames[i]:Show()
	end
end

function Healium_Show40ManRaidFrames()
	for i = 1, 8 do
		GroupFrames[i]:Show()
	end
end

function Healium_CreateUnitFrames()
	PartyFrame = CreatePartyUnitFrame("HealiumPartyFrame", "Party")

	if Healium.ShowPartyFrame then
		PartyFrame:Show()
	end

	for i = 1, 8 do
		GroupFrames[i] = CreateGroupUnitFrame("HealiumGroup" .. i .. "Frame", "Group " .. i, tostring(i))
		GroupFramesWasShown[i] = false
	end	

end

function Healium_SetScale()
	local Scale = Healium.Scale

	PartyFrame:SetScale(Scale)

	for i,j in ipairs(GroupFrames) do
		j:SetScale(Scale)
	end	
end

function Healium_UpdateUnitBuffs(unit, frame)
	local buffIndex = 1
	local Profile = Healium_GetProfile()

	if Profile.SpellNamesHash then
		for i = 1, 32 do
			local name, _, icon, count, _, duration, expirationTime = UnitBuff(unit, i, "PLAYER")
			if not name then break end

			if (duration > 0) and Profile.SpellNamesHash[name] then
				local buffFrame = frame.buffs[buffIndex]

				buffFrame:SetID(i)
				buffFrame.icon:SetTexture(icon)

				if count > 1 then
					buffFrame.count:SetText(count)
					buffFrame.count:Show()
				else
					buffFrame.count:Hide()
				end
				local startTime = expirationTime - duration
				buffFrame.cooldown:SetCooldown(startTime, duration)
				buffFrame.cooldown:Show()

				buffFrame:Show()
				buffIndex = buffIndex + 1
				if buffIndex > MaxBuffs then break end
			end
		end
	end
	for i = buffIndex, MaxBuffs do
		frame.buffs[i]:Hide()
	end
	if Healium.EnableDebufs then
		local foundDebuff = false
		table.wipe(debuffTypesCache)
		for i = 1, 40 do
			local name, _, _, _, debuffType = UnitDebuff(unit, i)
			if not name then break end

			if debuffType and Healium_CanCureDebuff(debuffType) then
				foundDebuff = true
				debuffTypesCache[debuffType] = true
				local debuffColor = DebuffTypeColor[debuffType] or DebuffTypeColor["none"]
				frame.hasDebuf = true
				frame.debuffColor = debuffColor

				if Healium.EnableDebufHealthbarHighlighting then
					frame.CurseBar:SetBackdropBorderColor(debuffColor.r, debuffColor.g, debuffColor.b)
					frame.CurseBar:SetAlpha(1)
				end
			end
		end

		local debuffStateChanged = false
		if (not foundDebuff) and frame.hasDebuf then
			frame.CurseBar:SetAlpha(0)
			frame.hasDebuf = nil
			debuffStateChanged = true
		elseif foundDebuff then
			debuffStateChanged = true
		end

		if Healium.EnableDebufButtonHighlighting then 
			Healium_ShowDebuffButtons(Profile, frame, debuffTypesCache)		
		end

		if debuffStateChanged and Healium.EnableDebufHealthbarColoring then
			Healium_UpdateUnitHealth(unit, frame)
		end
	end
end

function Healium_HealthStatusBar_OnLoad(self)
	self:SetFrameLevel(self:GetFrameLevel() - 1)

end

function Healium_ManaStatusBar_OnLoad(self)
	self:SetRotatesTexture(true)
	self:SetOrientation("VERTICAL")
	self:SetFrameLevel(self:GetFrameLevel() - 1)
end

function Healium_ResetAllFramePositions()
	for _, k in ipairs(UnitFrames) do
		k:SetUserPlaced(false)
		k:ClearAllPoints()
		k:SetPoint("CENTER", UIParent, 0, 0)
	end
	Healium_Print("Reset frame positions complete.")
end

