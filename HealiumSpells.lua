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
	table.insert(addonTable.Spell.Name, name)
end

local function Count(tab)
	local cnt = 0
	
	for _, k in pairs(tab) do
		cnt = cnt + 1
	end
	
	return cnt
end



local ClassSpells = {
	["STARCALLER"] = {
		spells = {801990, 503020, 574328, 520869},
		cures = {
			[520869] = { CanCurePoison = true, CanCureDisease = true }
		}
	},
	["DRUID"] = {
		spells = {774, 8936, 33763, 5185, 5375, 50464, 53248, 29166, 20484, 2782, 8946, 2893},
		cures = {
			[2782] = { CanCureCurse = true },
			[2893] = { CanCurePoison = true },
			[8946] = { CanCurePoison = true }
		}
	},
	["PRIEST"] = {
		spells = {139, 2061, 2050, 2054, 2060, 32546, 596, 33076, 34861, 17, 552, 528, 527, 47788, 47540},
		cures = {
			[552] = { CanCureDisease = true },
			[528] = { CanCureDisease = true },
			[527] = { CanCureMagic = true }
		}
	},
	["SHAMAN"] = {
		spells = {8004, 331, 1064, 974, 526, 51886, 61295},
		cures = {
			[526] = { CanCurePoison = true, CanCureDisease = true },
			[51886] = { CanCurePoison = true, CanCureDisease = true, CanCureCurse = true }
		}
	},
	["PALADIN"] = {
		spells = {19750, 635, 20473, 633, 1152, 4987, 1022, 1038, 1044, 53563, 53601},
		cures = {
			[1152] = { CanCurePoison = true, CanCureDisease = true },
			[4987] = { CanCurePoison = true, CanCureDisease = true, CanCureMagic = true }
		}
	},
	["MAGE"] = {
		spells = {475},
		cures = {
			[475] = { CanCureCurse = true }
		}
	}
}

local RaceSpells = {
	["Draenei"] = {59547}
}

function Healium_InitSpells(class, race)
	if ClassSpells[class] then
		for _, spellID in ipairs(ClassSpells[class].spells) do
			AddSpell(spellID)
		end
		if ClassSpells[class].cures then
			for spellID, cureData in pairs(ClassSpells[class].cures) do
				Cures[SpellName(spellID)] = cureData
			end
		end
	end
	
	if RaceSpells[race] then
		for _, spellID in ipairs(RaceSpells[race]) do
			AddSpell(spellID)
		end
	end
	
	CuresCount = Count(Cures)
end

function Healium_UpdateCures()
	local Profile = Healium_GetProfile()
	

	CanCureMagic = false
	CanCureDisease = false
	CanCurePoison = false
	CanCureCurse = false	

	if CuresCount > 0 then
		for i=1, Profile.ButtonCount,1 do
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

	for i=1, Profile.ButtonCount,1 do
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


