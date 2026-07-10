-- Unit Frames Code
local debuffTypesCache = {}

local PartyFrame = nil
local GroupFrames = { }

local PartyFrameWasShown = nil
local GroupFramesWasShown = { }

local MaxBuffs = 6
local xSpacing = 2
local NamePlateHeight = 28
local UnitFrames = { } -- table of all unit frames


local FrameSet = {}  -- hash set for O(1) duplicate detection

local function initialConfigFunction(frame)
	-- The only thing you are especially allowed to do in the initialConfigFunction() is to change attributes.  
	-- CreateFrame(), :Show(), :Hide() etc will taint in combat still

	frame.buttons = { }
	frame:RegisterForClicks("AnyUp")	
	frame:SetAttribute("type1", "target")

	-- O(1) duplicate check via hash set instead of linear scan
	if not FrameSet[frame] then
		FrameSet[frame] = true
		table.insert(Healium_Frames, frame)
	end

	-- configure buff frames
	frame.buffs = { }	

	local framename = frame:GetName()	
	for i=1, MaxBuffs, 1 do
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
	
	
--	Healium_DebugPrint("Inital Config")
end

local function CreateButton(ButtonName,ParentFrame,xoffset)
	local button = CreateFrame("Button", ButtonName, ParentFrame, "HealiumHealButtonTemplate")
	button:SetPoint("LEFT", ParentFrame, "RIGHT", xoffset, 0)
	return button
end

-- please make sure we are not in combat before calling this function
function Healium_CreateButtonsForNameplate(frame)
	local x = xSpacing
	local Profile = Healium_GetProfile()
	
	for i=1, Healium_MaxButtons, 1 do
		local name = frame:GetName()
		local button = CreateButton(name.."_Heal"..i, frame, x)
		x = x + xSpacing + NamePlateHeight

		button.index = i -- .index is used by drag operation
		frame.buttons[i] = button

		-- set spell attribute for button
		local spell = Profile.SpellNames[i]
		Healium_UpdateButtonSpell(button, spell, Healium_ButtonIDs[i], false)		
		
		-- set icon for button
		local texture = Profile.SpellIcons[i]	
		Healium_UpdateButtonIcon(button, texture)
	
		if (i > Profile.ButtonCount) then 
			button:Hide()
			
			if button:IsShown() then
				Healium_Warn("Failed to hide heal button")
			end
		else
			button:Show()
			
			if not button:IsShown() then
				Healium_Warn("Failed to show heal button")			
			end
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
	-- Hide close button if set to
	if not InCombatLockdown() then
		if Healium.HideCloseButton then
			frame.CaptionBar.CloseButton:Hide()
		else
			frame.CaptionBar.CloseButton:Show()
		end
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
	for _,j in pairs(UnitFrames) do
		UpdateCloseButton(j)
	end
end

function Healium_UpdateHideCaptions()
	for _,j in pairs(UnitFrames) do
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
		-- Добавлена проверка на бой для предотвращения ошибки UIDropDownMenu Taint
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
	
	if button == "RightButton" then
	
	end	
end

function HealiumUnitFrames_ShowHideFrame(self, show)
	if self == PartyFrame then
		Healium.ShowPartyFrame = show
		Healium_ShowPartyCheck:SetChecked(Healium.ShowPartyFrame)
		return
	end

	for i, j in ipairs(GroupFrames) do
		if self == j then
			Healium.ShowGroupFrames[i] = show
			-- Update only the changed checkbox, not all 8
			local checks = {
				Healium_ShowGroup1Check, Healium_ShowGroup2Check,
				Healium_ShowGroup3Check, Healium_ShowGroup4Check,
				Healium_ShowGroup5Check, Healium_ShowGroup6Check,
				Healium_ShowGroup7Check, Healium_ShowGroup8Check
			}
			if checks[i] then checks[i]:SetChecked(Healium.ShowGroupFrames[i]) end
			return
		end
	end
end

function HealiumUnitFrames_Button_OnLoad(self)
	self:RegisterForDrag("RightButton")
end

function HealiumUnitFrames_CheckPowerType(UnitName, NamePlate)
	local _, powerType = UnitPowerType(UnitName)
	if (Healium.ShowMana == false) or not UnitExists(UnitName) or (powerType ~= "MANA") then
--	if  UnitManaMax(UnitName) == nil then
		NamePlate.ManaBar:SetStatusBarColor( .5, .5, .5 )
		NamePlate.ManaBar:SetMinMaxValues(0,1)
		NamePlate.ManaBar:SetValue(1)
		NamePlate.showMana = nil
		return nil
	else
		local powerColor = PowerBarColor[powerType];
		NamePlate.ManaBar:SetStatusBarColor( powerColor.r, powerColor.g, powerColor.b )
		NamePlate.showMana = true		
	end

	return true
end

function HealiumUnitFrames_Button_OnShow(self)
	Healium_ShownFrames[self] = self
	
	local unit = self:GetAttribute("unit")
	
	if unit then
		self.TargetUnit = unit 

		local buttonCount = Healium_GetProfile().ButtonCount
		for i=1, buttonCount, 1 do		
			local button = self.buttons[i]
			if button then
				-- update cooldowns
				local id = Healium_ButtonIDs[i]
				
				if id then 
					local start, duration, enable = GetSpellCooldown(id, BOOKTYPE_SPELL)
					CooldownFrame_SetTimer(button.cooldown, start, duration, enable)			
				end
			end
		end

	
		local name = UnitName(unit)
		
		if name then 
			self.name:SetText(strupper(name))
		else 
			self.name:SetText("")
		end
		
		if not Healium_Units[unit] then
			Healium_Units[unit] = { }
		end
		
		Healium_Units[unit][self] = true

		for i =1, MaxBuffs, 1 do
			self.buffs[i].unit = unit
		end
		
		HealiumUnitFrames_CheckPowerType(unit, self)
		
		Healium_UpdateUnitHealth(unit, self)
		Healium_UpdateUnitMana(unit, self)
		Healium_UpdateUnitBuffs(unit, self)
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
    if name == "unit" and value ~= self.TargetUnit then
        -- Удаляем старую привязку
        if self.TargetUnit and Healium_Units[self.TargetUnit] then
            Healium_Units[self.TargetUnit][self] = nil
        end
        
        -- Если фрейм видим, переинициализируем его с новым юнитом
        if self:IsShown() and value then
            self.TargetUnit = value
            if not Healium_Units[value] then
                Healium_Units[value] = { }
            end
            Healium_Units[value][self] = true
            
            -- Обновляем визуал (имя, хп, мана)
            local unitName = UnitName(value)
            self.name:SetText(unitName and strupper(unitName) or "")
            HealiumUnitFrames_CheckPowerType(value, self)
            Healium_UpdateUnitHealth(value, self)
            Healium_UpdateUnitMana(value, self)
            Healium_UpdateUnitBuffs(value, self)
        else
            self.TargetUnit = nil
        end
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
	
	local hide = false

	if PartyFrame:IsShown() then hide = true end

	for i,j in ipairs(GroupFrames) do
		if j:IsShown() then
			hide = true
			break
		end
	end
	
	if hide then
		PartyFrameWasShown = PartyFrame:IsShown()
	
		PartyFrame:Hide()
		
		for i,j in ipairs(GroupFrames) do
			GroupFramesWasShown[i] = j:IsShown()
			j:Hide()
		end
		
		return
	end
	
	if PartyFrameWasShown then
		PartyFrame:Show()
	end
	
	for i,j in ipairs(GroupFramesWasShown) do
		if j then
			GroupFrames[i]:Show()
		end
	end
end

function Healium_ShowHidePartyFrame(show)
	if (show ~= nil) then Healium.ShowPartyFrame = show end
	
	if Healium.ShowPartyFrame then
		PartyFrame:Show()
	else
		PartyFrame:Hide()
	end
end

function Healium_ShowHideGroupFrame(group, show)
	if (show ~= nil) then Healium.ShowGroupFrames[group] = show end
	
	if Healium.ShowGroupFrames[group] then
		GroupFrames[group]:Show()
	else
		GroupFrames[group]:Hide()
	end
end

function Healium_HideAllRaidFrames()
	for i,j in ipairs(GroupFrames) do
		j:Hide()
	end
end

-- Removed: Healium_ShowAllRaidFramesWithMembers was an empty stub
		
function Healium_Show10ManRaidFrames()
	GroupFrames[1]:Show()
	GroupFrames[2]:Show()
end

function Healium_Show25ManRaidFrames()
	for i=1, 5, 1 do
		GroupFrames[i]:Show()
	end
end

function Healium_Show40ManRaidFrames()
	for i=1, 8, 1 do
		GroupFrames[i]:Show()
	end
end

function Healium_CreateUnitFrames()
	PartyFrame = CreatePartyUnitFrame("HealiumPartyFrame", "Party")

	if Healium.ShowPartyFrame then
		PartyFrame:Show()
	end
	
	-- Disabled Pets, Me, Friends, and Tanks frame creation
	
	for i=1, 8, 1 do
		GroupFrames[i] = CreateGroupUnitFrame("HealiumGroup" .. i .. "Frame", "Group " .. i, tostring(i))
		GroupFramesWasShown[i]  = false
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
	
	if Healium.ShowBuffs and Profile.SpellNamesHash then
		-- WotLK max player buffs = 32; bounded loop prevents hang on broken API
		for i = 1, 32 do
			-- Фильтр "PLAYER" для игнорирования чужих аур в рейде
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

				-- duration already confirmed > 0 in outer if
				local startTime = expirationTime - duration
				buffFrame.cooldown:SetCooldown(startTime, duration)
				buffFrame.cooldown:Show()

				buffFrame:Show()
				buffIndex = buffIndex + 1
				if buffIndex > MaxBuffs then break end
			end
		end
	end

	-- Скрываем оставшиеся фреймы
	for i = buffIndex, MaxBuffs, 1 do
		frame.buffs[i]:Hide()
	end
	
	-- Обработка дебаффов
	if Healium.EnableDebufs then
		local foundDebuff = false
		table.wipe(debuffTypesCache)

		-- WotLK max debuffs = 40; bounded loop prevents hang on broken API
		for i = 1, 40 do
			-- Убраны неиспользуемые возвращаемые значения (заменены на _)
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

function Healium_UpdateEnableDebuffs()
	for _, j in pairs(UnitFrames) do
		if j.hasDebuf then
			j.CurseBar:SetAlpha(0)
			j.hasDebuf = nil

			for i=1, Healium_MaxButtons, 1 do
				local button = j.buttons[i]
				if button and button.CurseBar then  -- nil guard
					button.CurseBar:SetAlpha(0)
					button.CurseBar.hasDebuf = nil
				end
			end
		end
	end
end

function Healium_HealthStatusBar_OnLoad(self)
	-- This is done to ensure the status bar doesn't block 
	-- the name text
	self:SetFrameLevel(self:GetFrameLevel() - 1)

end

function Healium_ManaStatusBar_OnLoad(self)
--    self:SetStatusBarColor(PowerBarColor["MANA"])
	self:SetRotatesTexture(true)
	self:SetOrientation("VERTICAL")
	self:SetFrameLevel(self:GetFrameLevel() - 1)
--	self:SetBackdropColor(1.0, 0.0, 0.0)	
end


function Healium_ResetAllFramePositions()
	for _,k in ipairs(UnitFrames) do
		k:SetUserPlaced(false)
		k:ClearAllPoints()
		k:SetPoint("CENTER", UIParent, 0,0)
	end
	Healium_Print("Reset frame positions complete.")
end


