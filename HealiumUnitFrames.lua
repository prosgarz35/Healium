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

local PartyFrame = nil
local PetsFrame = nil
local MeFrame = nil
local GroupFrames = { }

local PartyFrameWasShown = nil
local PetsFrameWasShown = nil
local MeFrameWasShown = nil
local GroupFramesWasShown = { }

local MaxBuffs = 6
local xSpacing = 2
local NamePlateHeight = 28
local UnitFrames = { }
local debuffTypesCache = {}

local function initialConfigFunction(frame)
	frame.buttons = {}
	frame:RegisterForClicks('AnyUp')
	table.insert(addonTable.Frames, frame)
	frame.buffs = {}
	for i=1, MaxBuffs, 1 do
		local buffFrame = CreateFrame('Frame', frame:GetName()..'_Buff'..i, frame, 'HealiumBuffTemplate')
		if i == 1 then
			buffFrame:SetPoint('RIGHT', frame, 'LEFT', -2, 0)
		else
			buffFrame:SetPoint('RIGHT', frame.buffs[i-1], 'LEFT', -2, 0)
		end
		local name = buffFrame:GetName()
		buffFrame.icon = _G[name..'Icon']
		buffFrame.cooldown = _G[name..'Cooldown']
		buffFrame.count = _G[name..'Count']
		buffFrame.border = _G[name..'Border']
		buffFrame.id = i
		frame.buffs[i] = buffFrame
	end

	if InCombatLockdown() then
		Healium_Warn("Can't toggle frames while in combat.")
		return
	end
	
	local hide = false

	if PartyFrame:IsShown() then hide = true end
	if PetsFrame:IsShown() then hide = true end
	if MeFrame:IsShown() then hide = true end

	for i,j in ipairs(GroupFrames) do
		if j:IsShown() then
			hide = true
			break
		end
	end
	
	if hide then
		PartyFrameWasShown = PartyFrame:IsShown()
		PetsFrameWasShown = PetsFrame:IsShown()	
		MeFrameWasShown = MeFrame:IsShown()
	
		PartyFrame:Hide()
		PetsFrame:Hide()
		MeFrame:Hide()
		
		for i,j in ipairs(GroupFrames) do
			GroupFramesWasShown[i] = j:IsShown()
			j:Hide()
		end
		
		return
	end
	
	if PartyFrameWasShown then
		PartyFrame:Show()
	end
	
	if PetsFrameWasShown then
		PetsFrame:Show()
	end
	
	if MeFrameWasShown then
		MeFrame:Show()
	end
	
	for i,j in ipairs(GroupFramesWasShown) do
		if j then
			GroupFrames[i]:Show()
		end
	end
end

function Healium_ShowHidePartyFrame(show)
	if InCombatLockdown() then Healium_Warn('Cannot change frame visibility during combat.') return end
	if (show ~= nil) then Healium.ShowPartyFrame = show end
	
	if Healium.ShowPartyFrame then
		PartyFrame:Show()
	else
		PartyFrame:Hide()
	end
end

function Healium_ShowHidePetsFrame(show)
	if InCombatLockdown() then Healium_Warn('Cannot change frame visibility during combat.') return end
	if (show ~= nil) then Healium.ShowPetsFrame = show end
	
	if Healium.ShowPetsFrame then
		PetsFrame:Show()
	else
		PetsFrame:Hide()
	end
end

function Healium_ShowHideMeFrame(show)
	if InCombatLockdown() then Healium_Warn('Cannot change frame visibility during combat.') return end
	if (show ~= nil) then Healium.ShowMeFrame = show end
	
	if Healium.ShowMeFrame then
		MeFrame:Show()
	else
		MeFrame:Hide()
	end
end

function Healium_ShowHideGroupFrame(group, show)
	if InCombatLockdown() then Healium_Warn('Cannot change frame visibility during combat.') return end
	if (show ~= nil) then Healium.ShowGroupFrames[group] = show end
	
	if Healium.ShowGroupFrames[group] then
		GroupFrames[group]:Show()
	else
		GroupFrames[group]:Hide()
	end
end

function Healium_HideAllRaidFrames()
	if InCombatLockdown() then Healium_Warn('Cannot change frame visibility during combat.') return end
	for i,j in ipairs(GroupFrames) do
		Healium.ShowGroupFrames[i] = false
		if _G["Healium_ShowGroup"..i.."Check"] then _G["Healium_ShowGroup"..i.."Check"]:SetChecked(false) end
		j:Hide()
	end
end
		
function Healium_Show10ManRaidFrames()
	if InCombatLockdown() then Healium_Warn('Cannot change frame visibility during combat.') return end
	Healium_HideAllRaidFrames()
	for i=1, 2 do
		Healium.ShowGroupFrames[i] = true
		if _G["Healium_ShowGroup"..i.."Check"] then _G["Healium_ShowGroup"..i.."Check"]:SetChecked(true) end
		GroupFrames[i]:Show()
	end
end

function Healium_Show25ManRaidFrames()
	if InCombatLockdown() then Healium_Warn('Cannot change frame visibility during combat.') return end
	Healium_HideAllRaidFrames()
	for i=1, 5 do
		Healium.ShowGroupFrames[i] = true
		if _G["Healium_ShowGroup"..i.."Check"] then _G["Healium_ShowGroup"..i.."Check"]:SetChecked(true) end
		GroupFrames[i]:Show()
	end
end

function Healium_Show40ManRaidFrames()
	if InCombatLockdown() then Healium_Warn('Cannot change frame visibility during combat.') return end
	for i=1, 8 do
		Healium.ShowGroupFrames[i] = true
		if _G["Healium_ShowGroup"..i.."Check"] then _G["Healium_ShowGroup"..i.."Check"]:SetChecked(true) end
		GroupFrames[i]:Show()
	end
end

function Healium_CreateUnitFrames()
	PartyFrame = CreatePartyUnitFrame("HealiumPartyFrame", "Party")

	if Healium.ShowPartyFrame then
		PartyFrame:Show()
	end
	
	PetsFrame = CreatePetUnitFrame("HealiumPetFrame", "Pets")
	if Healium.ShowPetsFrame then
		PetsFrame:Show()
	end
	
	MeFrame = CreateMeUnitFrame("HealiumMeFrame", "Me")
	if Healium.ShowMeFrame then
		MeFrame:Show()
	end	
	
	for i=1, 8, 1 do
		GroupFrames[i] = CreateGroupUnitFrame("HealiumGroup" .. i .. "Frame", "Group " .. i, tostring(i))
		GroupFramesWasShown[i]  = false
	end	
	
end


function Healium_SetScale()
	local Scale = Healium.Scale
	
	PartyFrame:SetScale(Scale)
	PetsFrame:SetScale(Scale)	
	MeFrame:SetScale(Scale)
	
	for i,j in ipairs(GroupFrames) do
		j:SetScale(Scale)
	end	
end

function Healium_UpdateUnitBuffs(unit, frame)

	local buffIndex = 1
	local Profile = Healium_GetProfile()
	
	if Healium.ShowBuffs then
		for i=1, 100, 1 do
			local name, rank, icon, count, debuffType, duration, expirationTime, source, isStealable = UnitBuff(unit, i, true)
			if name  then 
				if (duration > 0) and (source == "player") then
					
					if Profile.SpellSet and Profile.SpellSet[name] then
						local buffFrame = frame.buffs[buffIndex]

						buffFrame:SetID(i)
						buffFrame.icon:SetTexture(icon)
						
						if count > 1 then
							buffFrame.count:SetText(count)
							buffFrame.count:Show()
						else
							buffFrame.count:Hide()
						end
						
						if duration and duration > 0 then
							local startTime = expirationTime - duration
							buffFrame.cooldown:SetCooldown(startTime, duration)
							buffFrame.cooldown:Show()
						else
							buffFrame.cooldown:Hide()
						end
						
						buffFrame:Show()
						buffIndex = buffIndex + 1					
						if buffIndex > MaxBuffs then
							break
						end			
						
					end
				end
			else
				break
			end
		end
	end

	for i = buffIndex, MaxBuffs, 1 do
		frame.buffs[i]:Hide()
	end

	if Healium.EnableDebufs then
	
		local foundDebuff = false
		table.wipe(debuffTypesCache) 
		
		for i = 1, 40, 1 do
			local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitDebuff(unit, i)
			
			if name == nil then
				break
			end
			
			if debuffType ~= nil then
				if addonTable.CanCureDebuff(debuffType) then
					foundDebuff = true
					debuffTypesCache[debuffType] = true
					local debuffColor = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];					
					frame.hasDebuf = true
					frame.debuffColor = debuffColor
					
					if Healium.EnableDebufHealthbarHighlighting then
						frame.CurseBar:SetBackdropBorderColor(debuffColor.r, debuffColor.g, debuffColor.b)
						frame.CurseBar:SetAlpha(1)
					end	
				end
			end
		end
		
		if (not foundDebuff) and frame.hasDebuf then
			frame.CurseBar:SetAlpha(0)
			frame.hasDebuf = nil
		end
		
		if Healium.EnableDebufButtonHighlighting then 
			Healium_ShowDebuffButtons(Profile, frame, debuffTypesCache)		
		end
		
		Healium_UpdateUnitHealth(unit, frame)
	end
end

function Healium_UpdateEnableDebuffs()
	for _, j in pairs(UnitFrames) do
		if j.hasDebuf then
			j.CurseBar:SetAlpha(0)
			j.hasDebuf = nil
			
			for i=1, addonTable.MaxButtons, 1 do
				local button = j.buttons[i] 
				if button then
					button.curseBar:SetAlpha(0)
					button.curseBar.hasDebuf = nil
				end
			end
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
	for _,k in ipairs(UnitFrames) do
		k:SetUserPlaced(false)
		k:ClearAllPoints()
		k:SetPoint("Center", UIParent, 0,0)
	end
	Healium_Print("Reset frame positions complete.")
end

-- Subscribe to core events directly from this module
function addonTable.Events.UNIT_HEALTH(self, arg1, arg2)
	if addonTable.Units[arg1] then
		for _,v  in pairs(addonTable.Units[arg1]) do
			Healium_UpdateUnitHealth(arg1, v)
		end
	end
end

function addonTable.Events.UNIT_MANA(self, arg1, arg2)
	if addonTable.Units[arg1] then
		for _,v  in pairs(addonTable.Units[arg1]) do
			Healium_UpdateUnitMana(arg1, v)
		end
	end
end



