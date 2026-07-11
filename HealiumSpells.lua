local CanCureMagic = false
local CanCureDisease = false
local CanCurePoison = false
local CanCureCurse = false

local Cures = { } 
local CuresCount = 0

local function SpellName(spellID)
	local name = GetSpellInfo(spellID)
	return name
end

local function AddSpell(spellID)
	local name = SpellName(spellID)
	table.insert(Healium_Spell.Name, name)
end

local function Count(tab)
	local cnt = 0
	
	for _, k in pairs(tab) do
		cnt = cnt + 1
	end
	
	return cnt
end

-- These spellIDs are from wowhead

local ClassSpellsMap = {
	DRUID = { 774, 8936, 33763, 5185, 5375, 50464, 53248, 29166, 20484, 2782, 8946, 2893 },
	PRIEST = { 139, 2061, 2050, 2054, 2060, 32546, 596, 33076, 34861, 17, 552, 528, 527, 47788, 47540 },
	SHAMAN = { 8004, 331, 1064, 974, 526, 51886, 61295 },
	PALADIN = { 19750, 635, 20473, 633, 1152, 4987, 1022, 1038, 1044, 53563, 53601 },
	MAGE = { 475 },
}

local CuresConfig = {
	-- Druid
	[2782] = { CanCureCurse = true }, -- Remove Curse (Druid)
	[2893] = { CanCurePoison = true }, -- Abolish Poison
	[8946] = { CanCurePoison = true }, -- Cure Poison
	
	-- Priest
	[552] = { CanCureDisease = true }, -- Abolish Disease
	[528] = { CanCureDisease = true }, -- Cure Disease
	[527] = { CanCureMagic = true },   -- Dispel Magic
	
	-- Shaman
	[526] = { CanCurePoison = true, CanCureDisease = true }, -- Cure Toxins
	[51886] = { CanCurePoison = true, CanCureDisease = true, CanCureCurse = true }, -- Cleanse Spirit
	
	-- Paladin
	[1152] = { CanCurePoison = true, CanCureDisease = true }, -- Purify 
	[4987] = { CanCurePoison = true, CanCureDisease = true, CanCureMagic = true }, -- Cleanse
	
	-- Mage
	[475] = { CanCureCurse = true }, -- Remove Curse (Mage)
}

function Healium_InitSpells(class, race)
	
	-- Init spell list
	local spells = ClassSpellsMap[class]
	if spells then
		for _, spellID in ipairs(spells) do
			AddSpell(spellID)
		end
	end
	
	for spellID, cureData in pairs(CuresConfig) do
		local name = SpellName(spellID)
		if name then
			Cures[name] = cureData
		end
	end
	
	if (race == "Draenei") then
		AddSpell(59547)		-- Gift of the Naaru
	end
	
	CuresCount = Count(Cures)
end

function Healium_UpdateCures()
	local Profile = Healium_GetProfile()
	
	-- Handle Cures
	CanCureMagic = false
	CanCureDisease = false
	CanCurePoison = false
	CanCureCurse = false	

	if CuresCount > 0 then
		for i = 1, Profile.ButtonCount do
			local spell = Profile.SpellNames[i]
			local cure = Cures[spell]
			if cure ~= nil then
				if cure.CanCureMagic then CanCureMagic = true end
				if cure.CanCureDisease then CanCureDisease = true end
				if cure.CanCurePoison then CanCurePoison = true end
				if cure.CanCureCurse then CanCureCurse = true end
			end
		end
	end
	
end

--debuffType is expected to be a return value from the wow api UnitDebuff()
function Healium_CanCureDebuff(debuffType)
	if   ( (debuffType == "Curse") and CanCureCurse) or
	     ( (debuffType == "Disease") and CanCureDisease) or
		 ( (debuffType == "Magic") and CanCureMagic) or
		 ( (debuffType == "Poison") and CanCurePoison) then	
		 return true
	end
	
	return false
end

function Healium_ShowDebuffButtons(Profile, frame, debuffTypes)

	for i = 1, Profile.ButtonCount do
		local button = frame.buttons[i]	
		
		if button then 
			local spell = Profile.SpellNames[i]
			local cure = Cures[spell]
			local flag
			local debuffColor 
			
			if cure ~= nil then
				if debuffTypes["Curse"] and cure.CanCureCurse then
					flag = true
					debuffColor = DebuffTypeColor["Curse"] 
				elseif debuffTypes["Disease"] and cure.CanCureDisease then
					flag = true
					debuffColor = DebuffTypeColor["Disease"]
				elseif debuffTypes["Magic"] and cure.CanCureMagic then
					flag = true
					debuffColor = DebuffTypeColor["Magic"]
				elseif debuffTypes["Poison"] and cure.CanCurePoison then
					flag = true
					debuffColor = DebuffTypeColor["Poison"]
				else 
					flag = false
				end
			end
			
			local curseBar = button.CurseBar
			
			if flag then
				curseBar:SetBackdropBorderColor(debuffColor.r, debuffColor.g, debuffColor.b)
				curseBar:SetAlpha(1)
				curseBar.hasDebuf = true
			else
				if curseBar.hasDebuf then
					curseBar:SetAlpha(0)
					curseBar.hasDebuf = nil
				end
			end
		end
	end
end